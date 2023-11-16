/*-- Last Change Revision: $Rev: 2027182 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hand_off AS

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

    --
    PROCEDURE delete_hand_off_event
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_id_sys_alert   IN NUMBER DEFAULT 32
    ) IS
        l_alert_event sys_alert_event%ROWTYPE;
        l_ret         BOOLEAN;
        l_error       t_error_out;
    BEGIN
        -- elimina o alerta 32 se este existir
        l_alert_event.id_episode   := i_episode;
        l_alert_event.id_record    := i_epis_prof_resp;
        l_alert_event.id_sys_alert := i_id_sys_alert;
        l_ret                      := pk_alerts.delete_sys_alert_event(i_lang, i_prof, l_alert_event, l_error);
    END;
    --

    /********************************************************************************************
    * Get the type of hand-off used in the current market.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   o_hand_off_type        configured hand-off type (N) Normal (M) Multiple
    * @param   o_error                error message
    *                        
    * @return  TRUE if sucess, FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          28-10-2009
    **********************************************************************************************/
    FUNCTION get_hand_off_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_hand_off_type OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET TYPE OF HAND-OFF';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => o_hand_off_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HAND_OFF_TYPE',
                                              o_error);
            RETURN FALSE;
    END get_hand_off_type;
    --
    /********************************************************************************************
    * Gets the professional responsible for the episode
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   i_episode         episode ID
    * @param   i_flg_type        Professional category: D - Doctor; N - Nurse
    * @param   i_hand_off_type   Hand-off mechanism
    * @param   i_flg_profile     Type of profile (S)pecialist (R)esident (I)ntern (N)urse
    * @param   i_id_speciality   Physician speciality (send NULL for nursing professionals)
    * @param   i_flg_resp_type   Type of responsability: (E) Episode - default (O) Overall
    *                        
    * @return  professional ID
    * 
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          21-08-2009
    *
    * @alter                          Jos?Brito
    * @version                        2.5.0.7
    * @since                          21-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_id_speciality IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E'
    ) RETURN NUMBER IS
    
        l_error           t_error_out;
        l_id_professional professional.id_professional%TYPE;
        l_flg_type        category.flg_type%TYPE;
        l_handoff_type    sys_config.value%TYPE := i_hand_off_type;
        l_epis_status     episode.flg_status%TYPE;
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type);
    
        IF i_flg_type IS NULL
        THEN
            l_flg_type := pk_prof_utils.get_category(i_lang, i_prof);
        ELSE
            l_flg_type := i_flg_type;
        END IF;
    
        -- Get responsible for the episode
        g_error := 'CALL TO GET_PROF_RESP_BY_TYPE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name);
        IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_episode    => i_episode,
                                                      i_prof_cat      => l_flg_type,
                                                      i_flg_profile   => i_flg_profile,
                                                      i_hand_off_type => l_handoff_type,
                                                      i_flg_resp_type => i_flg_resp_type,
                                                      i_id_speciality => i_id_speciality,
                                                      o_epis_status   => l_epis_status,
                                                      o_id_prof_resp  => l_id_professional,
                                                      o_error         => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Jos?Brito 31/08/2009 ALERT-40433 Never return NULL
        RETURN nvl(l_id_professional, -1);
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_PROF_RESP',
                                              l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_PROF_RESP',
                                              l_error);
            RETURN NULL;
    END get_prof_resp;

    /********************************************************************************************
    * Set the professional responsasible for the episode on alerts event (consults for approval)
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   i_tot_epis        List of episodes
    *                        
    * @return  professional ID
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          15-04-2010
    *
    **********************************************************************************************/

    FUNCTION set_prof_responsible_alert
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_tot_epis IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_ids table_number := table_number();
    
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        FOR i IN 1 .. i_tot_epis.count
        LOOP
        
            g_error    := 'CALL pk_hand_off_core.get_responsibles_id';
            l_prof_ids := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => i_tot_epis(i),
                                                               i_prof_cat      => pk_alert_constant.g_cat_type_doc,
                                                               i_hand_off_type => l_hand_off_type);
        
            IF l_prof_ids IS NULL
               OR l_prof_ids.first IS NULL
               OR l_prof_ids.count = 0
            THEN
                g_error := 'no responsible exists!';
            ELSE
                g_error := 'CALL pk_alerts.set_alert_professional';
                IF NOT pk_alerts.set_alert_professional(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_sys_alert => pk_opinion.g_alert_needs_approval,
                                                        i_episode      => i_tot_epis(i),
                                                        i_professional => l_prof_ids(1),
                                                        o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_PROF_RESPONSIBLE_ALERT',
                                              o_error);
            RETURN FALSE;
        
    END set_prof_responsible_alert;
    --

    /********************************************************************************************
    * Cancel a responsability record that is in "requested" state.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   i_sysdate                  Record date
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.5
    * @since                          02-02-2011
    **********************************************************************************************/
    FUNCTION call_cancel_request_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CALL_CANCEL_REQUEST_RESP';
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
        l_can_refresh_mview_str   VARCHAR2(1 CHAR);
        l_epis_flg_status         episode.flg_status%TYPE;
        l_epr                     epis_prof_resp%ROWTYPE;
        l_empr                    epis_multi_prof_resp%ROWTYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_hand_off_type           sys_config.value%TYPE;
    
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        xepr  epis_prof_resp%rowtype;
    BEGIN
        -- Get type of hand-off
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_sysdate_tstz := nvl(i_sysdate, current_timestamp);
    
        g_error := 'CHECK RECORD STATUS';
        pk_alertlog.log_debug(g_error);
        SELECT epr.*
          INTO l_epr
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp = i_epis_prof_resp;
    
        -- Cancel method changes according to the responsability status:
    
        IF l_epr.flg_status = g_hand_off_r
        THEN
            -- Cancel a hand-off request, still not accepted. Call the generic hand-off method, used to change the status of a request.
            g_error := 'CANCEL REQUEST RESP';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off.call_set_epis_prof_resp(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_tot_epis         => table_number(1),
                                                       i_epis_prof_resp   => table_varchar(i_epis_prof_resp),
                                                       i_flg_status       => pk_hand_off.g_hand_off_c,
                                                       i_flg_type         => i_flg_type,
                                                       i_notes            => i_notes,
                                                       i_sysdate          => l_sysdate_tstz,
                                                       i_hand_off_type    => NULL,
                                                       i_one_step_process => 'N',
                                                       i_id_cancel_reason => i_id_cancel_reason,
                                                       o_refresh_mview    => l_can_refresh_mview_str,
                                                       o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        ELSIF l_epr.flg_status = g_hand_off_f
              AND l_hand_off_type = g_handoff_multiple -- Only supported in MULTIPLE hand-off
        THEN
            -- Cancel a finalized hand-off request. This is used for requests that are automatically accepted, for instance,
            -- requests to specialist physicians in multiple hand-off mechanism.
        
            g_error := 'CHECK EPISODE STATUS';
            pk_alertlog.log_debug(g_error);
            SELECT epis.flg_status
              INTO l_epis_flg_status
              FROM episode epis
             WHERE epis.id_episode = l_epr.id_episode;
        
            g_error := 'GET MULTIPLE RESPONSABILITY DATA';
            pk_alertlog.log_debug(g_error);
            SELECT empr.*
              INTO l_empr
              FROM epis_multi_prof_resp empr
             WHERE empr.id_epis_prof_resp = i_epis_prof_resp;
        
            IF i_prof.id <> l_epr.id_prof_req
            THEN
                -- Only the professional that made the request should be able to cancel a finalized hand-off request.
                g_error := 'INVALID PROF ID';
                RAISE l_param_error;
            
            ELSIF l_epis_flg_status <> pk_alert_constant.g_active
            THEN
                -- Episode must be active in order to cancel a responsability record.
                g_error := 'INVALID EPISODE STATUS';
                RAISE l_param_error;
            
            ELSIF l_empr.flg_profile <> pk_hand_off_core.g_specialist
            THEN
                -- Only requests to specialists are supported.
                g_error := 'INVALID PROFILE';
                RAISE l_param_error;
            
            ELSIF l_empr.flg_main_responsible = pk_alert_constant.g_yes
            THEN
                -- If professional is a main responsible, raise an error. User must first assign another main responsible,
                -- and only then it should be possible to cancel this responsability record.
                g_error := 'PROFESSIONAL IS MAIN RESPONSIBLE';
                RAISE l_param_error;
            
            END IF;
        
            g_error := 'UPDATE EPIS_PROF_RESP';
            pk_alertlog.log_debug(g_error);
      
       xepr := pk_hand_off_core.set_epis_prof_resp_h( i_epis_prof_resp );
       xepr.id_epis_prof_resp:= i_epis_prof_resp;
       xepr.dt_cancel_tstz   := l_sysdate_tstz;
       xepr.flg_status       := pk_hand_off.g_hand_off_c;
           xepr.id_prof_cancel   := i_prof.id;
           xepr.notes_cancel     := i_notes;
           xepr.id_cancel_reason := i_id_cancel_reason;
      
            UPDATE epis_prof_resp
               SET dt_cancel_tstz   = l_sysdate_tstz,
                   flg_status       = pk_hand_off.g_hand_off_c,
                   id_prof_cancel   = i_prof.id,
                   notes_cancel     = i_notes,
                   id_cancel_reason = i_id_cancel_reason
             WHERE id_epis_prof_resp = i_epis_prof_resp;
        
      pk_hand_off_core.ins_epis_prof_resp_h( xepr );
        
            g_error := 'MANAGE MULTI HAND-OFF MECHANISM';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.set_multi_prof_resp(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_id_episode              => l_epr.id_episode,
                                                        i_id_prof_resp            => l_empr.id_professional,
                                                        i_flg_profile             => l_empr.flg_profile,
                                                        i_id_epis_prof_resp       => i_epis_prof_resp,
                                                        i_flg_status              => pk_hand_off.g_hand_off_c,
                                                        i_sysdate                 => l_sysdate_tstz,
                                                        i_hand_off_type           => l_hand_off_type,
                                                        i_flg_main_responsible    => l_empr.flg_main_responsible,
                                                        i_id_speciality           => l_empr.id_speciality,
                                                        i_flg_resp_type           => l_empr.flg_resp_type,
                                                        o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                        o_error                   => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        ELSE
            g_error := 'UNSUPPORTED STATUS';
            RAISE l_param_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              g_error,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_cancel_request_resp;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * IMPORTANT: Database internal function.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tot_epis               Array com o número total de episódios de transferência de responsabilidade,que o profissional vai aceitar, cancelar ou rejeitar
    * @param i_epis_prof_resp         Array com os IDs dos episódios de transferência de responsabilidade
    * @param i_flg_status             Status da Transferência de responsabilidade:  C - Cancelado;
                                                                                    F- Final;
                                                                                    D- Rejeitado        
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_notes                  Notes
    * @param i_sysdate                Current date
    * @param i_hand_off_type          Hand-off mechanism (N) Normal (M) Multiple
    * @param i_one_step_process       One step process (simulating acceptance)? (Y) Yes (N) No - default
    * @param o_refresh_mview          Update grids? (Y) Yes (N) No
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito (Based on SET_EPIS_PROF_RESP by Emília Taborda)
    * @version                        2.5.0.7 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION call_set_epis_prof_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_tot_epis         IN table_number,
        i_epis_prof_resp   IN table_varchar,
        i_flg_status       IN epis_prof_resp.flg_status%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_hand_off_type    IN sys_config.value%TYPE,
        i_one_step_process IN VARCHAR2 DEFAULT 'N',
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_refresh_mview    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name               VARCHAR2(200 CHAR) := 'CALL_SET_EPIS_PROF_RESP';
        l_episode                 episode.id_episode%TYPE;
        l_handoff_type            sys_config.value%TYPE := i_hand_off_type;
        l_flg_profile             profile_template.flg_profile%TYPE;
        l_can_refresh_mview       BOOLEAN := FALSE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_update_multi_resp       BOOLEAN := FALSE;
        l_id_prof_request_to      professional.id_professional%TYPE;
        l_sysdate_tstz            TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_transf_type         epis_prof_resp.flg_transf_type%TYPE;
        l_flg_resp_type           epis_multi_prof_resp.flg_resp_type%TYPE;
        l_id_speciality           epis_multi_prof_resp.id_speciality%TYPE;
        l_set_main_responsible    epis_multi_prof_resp.flg_main_responsible%TYPE;
        l_id_prof_responsible     epis_info.id_professional%TYPE;
        l_flg_status              episode.flg_status%TYPE;
        l_prof_name               professional.name%TYPE;
        l_internal_error EXCEPTION;
        l_value_error    EXCEPTION;
    
        l_config_create_note   sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'HANDOFF_CREATE_SHIFT_SUMMARY_NOTE',
                                                                                i_prof    => i_prof);
        l_sp_id_prof           profissional;
        l_id_epis_pn           epis_pn.id_epis_pn%TYPE;
        l_pn_datetime          VARCHAR2(40 CHAR);
        l_id_prof_req          epis_prof_resp.id_prof_req%TYPE;
        l_epis_prof_resp_notes epis_prof_resp.notes_clob%TYPE;
        l_prof_cat             category.flg_type%TYPE;
        
        xepr                   epis_prof_resp%rowtype;
    BEGIN
        g_error        := 'GET CONFIGURATIONS';
        l_sysdate_tstz := nvl(i_sysdate, current_timestamp);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type); -- Get the type of hand-off
    
        FOR i IN 1 .. i_tot_epis.count
        LOOP
            IF l_handoff_type = g_handoff_multiple
            THEN
                -- We have to obtain the FLG_PROFILE of the request, because a professional with a different profile
                -- can CANCEL the request (e.g. the professional who made the request).
                g_error := 'GET MULTIPLE HAND-OFF DATA';
                pk_alertlog.log_debug(g_error);
                SELECT empr.flg_profile,
                       empr.id_professional,
                       empr.flg_resp_type,
                       empr.id_speciality,
                       epr.flg_transf_type
                  INTO l_flg_profile, l_id_prof_request_to, l_flg_resp_type, l_id_speciality, l_flg_transf_type
                  FROM epis_multi_prof_resp empr
                  JOIN epis_prof_resp epr
                    ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
                 WHERE empr.id_epis_prof_resp = i_epis_prof_resp(i);
            
            ELSE
                l_flg_transf_type := g_flg_transf_i;
                l_flg_resp_type   := pk_hand_off_core.g_resp_episode;
            END IF;
        
            IF i_flg_status IN (g_hand_off_t, g_hand_off_c)
            THEN
                -- If we're terminating a responsability, get the episode ID from throught the request ID,
                -- since there is no transfer in the 'requested' state.
                --
                -- ALERT-156810 - Ability to cancel/remove the doctor taking responsibility so that the field can return to being blank
                g_error := 'GET EPISODE FROM TRANSFER ID';
                pk_alertlog.log_debug(g_error);
                SELECT epr.id_episode
                  INTO l_episode
                  FROM epis_prof_resp epr
                 WHERE epr.id_epis_prof_resp = i_epis_prof_resp(i);
            
            ELSE
                -- Verificar se o episódio de transferência de respons.est?requisitado
                g_error := 'GET EPISODE OF REQUESTED TRANSFER';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.get_existing_handoff_req_by_id(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_id_epis_prof_resp => i_epis_prof_resp(i),
                                                                       i_hand_off_type     => l_handoff_type,
                                                                       i_flg_profile       => l_flg_profile,
                                                                       i_flg_transf_type   => l_flg_transf_type,
                                                                       o_id_episode        => l_episode,
                                                                       o_error             => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            IF l_episode IS NOT NULL
            THEN
                -- Check if already exists a main overall responsible
                g_error := 'CHECK MAIN RESPONSIBLE';
                IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_id_episode        => l_episode,
                                                              i_prof_cat          => i_flg_type,
                                                              i_flg_profile       => l_flg_profile,
                                                              i_hand_off_type     => l_handoff_type,
                                                              i_flg_resp_type     => l_flg_resp_type,
                                                              i_id_speciality     => l_id_speciality,
                                                              i_only_main_overall => 'Y',
                                                              o_epis_status       => l_flg_status,
                                                              o_id_prof_resp      => l_id_prof_responsible,
                                                              o_prof_name         => l_prof_name,
                                                              o_error             => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF l_handoff_type = g_handoff_multiple
                   AND l_flg_resp_type = pk_hand_off_core.g_resp_overall
                   AND l_id_prof_responsible IS NULL
                THEN
                    l_set_main_responsible := 'Y';
                ELSE
                    l_set_main_responsible := 'N';
                END IF;
            
                IF i_flg_status = g_hand_off_c
                THEN
                  
                   xepr := pk_hand_off_core.set_epis_prof_resp_h( i_epis_prof_resp(i) );
                   xepr.id_epis_prof_resp   := i_epis_prof_resp(i);
                   xepr.dt_cancel_tstz   := l_sysdate_tstz;
                   xepr.flg_status   := i_flg_status;
                   xepr.id_prof_cancel   := i_prof.id;
                   xepr.notes_cancel   := i_notes;
                   xepr.id_cancel_reason   := i_id_cancel_reason;
                
                    -- cancelar pedido de transferência
                    g_error := 'UPDATE EPIS_PROF_RESP - C';
                    UPDATE epis_prof_resp
                       SET dt_cancel_tstz   = l_sysdate_tstz,
                           flg_status       = i_flg_status,
                           id_prof_cancel   = i_prof.id,
                           notes_cancel     = i_notes,
                           id_cancel_reason = i_id_cancel_reason
                     WHERE id_epis_prof_resp = i_epis_prof_resp(i);
                
                     pk_hand_off_core.ins_epis_prof_resp_h( xepr );
                
                    -- elimina o alerta 32 se este existir
                    delete_hand_off_event(i_lang, i_prof, l_episode, i_epis_prof_resp(i));
                
                    l_update_multi_resp := TRUE;
                
                ELSIF i_flg_status = g_hand_off_f
                THEN
                    -- aceitar pedido de transferência
                    g_error := 'UPDATE EPIS_PROF_RESP - F';
                   xepr := pk_hand_off_core.set_epis_prof_resp_h( i_epis_prof_resp(i) );
                   xepr.id_epis_prof_resp   := i_epis_prof_resp(i);
                   xepr.flg_status   := i_flg_status;
                   xepr.id_prof_comp   := i_prof.id;
                   xepr.dt_comp_tstz   := l_sysdate_tstz;

                    UPDATE epis_prof_resp
                       SET flg_status = i_flg_status, id_prof_comp = i_prof.id, dt_comp_tstz = l_sysdate_tstz
                     WHERE id_epis_prof_resp = i_epis_prof_resp(i);
                
                     pk_hand_off_core.ins_epis_prof_resp_h( xepr );
                
                    -- elimina o alerta 32 se este existir
                    delete_hand_off_event(i_lang, i_prof, l_episode, i_epis_prof_resp(i));
                
                    g_error := 'SET PERMISSION TO UPDATE EPIS_INFO';
                    pk_alertlog.log_debug(g_error);
                    IF (l_handoff_type = g_handoff_multiple AND
                       ((l_flg_profile = pk_hand_off_core.g_specialist AND
                       l_flg_resp_type = pk_hand_off_core.g_resp_overall AND l_set_main_responsible = 'Y') OR
                       (l_flg_profile = pk_hand_off_core.g_nurse AND
                       l_flg_resp_type = pk_hand_off_core.g_resp_episode)))
                       OR l_handoff_type = g_handoff_normal
                    THEN
                        g_error := 'UPDATE EPIS_INFO - RESPONSIBLE PROFS.';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_hand_off_core.call_set_epis_info_resp_all(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_id_episode          => l_episode,
                                                                            i_id_professional     => CASE i_flg_type
                                                                                                         WHEN g_flg_type_d THEN
                                                                                                          i_prof.id
                                                                                                         ELSE
                                                                                                          NULL
                                                                                                     END,
                                                                            i_id_professional_nin => TRUE,
                                                                            i_prof_cat            => g_flg_type_d,
                                                                            i_id_prof_nurse       => CASE i_flg_type
                                                                                                         WHEN g_flg_type_n THEN
                                                                                                          i_prof.id
                                                                                                         ELSE
                                                                                                          NULL
                                                                                                     END,
                                                                            i_id_prof_nurse_nin   => TRUE,
                                                                            i_flg_resp_type       => l_flg_resp_type,
                                                                            o_error               => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    END IF;
                
                    l_can_refresh_mview := TRUE;
                    l_update_multi_resp := TRUE;
                
                    --Create shift summary note
                    pk_alertlog.log_debug('l_config_create_note:' || l_config_create_note ||
                                          ' l_epis_prof_resp_notes:' || l_epis_prof_resp_notes);
                    IF i_prof.software = pk_alert_constant.g_soft_inpatient
                       AND l_config_create_note = g_yes
                    THEN
                    
                        BEGIN
                            SELECT epr.id_prof_req, epr.notes_clob
                              INTO l_id_prof_req, l_epis_prof_resp_notes
                              FROM epis_prof_resp epr
                             WHERE epr.id_epis_prof_resp = i_epis_prof_resp(i);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_prof_req          := NULL;
                                l_epis_prof_resp_notes := NULL;
                        END;
                    
                        IF l_id_prof_req IS NOT NULL
                           AND l_epis_prof_resp_notes IS NOT NULL
                        THEN
                            l_prof_cat    := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                            l_sp_id_prof  := profissional(l_id_prof_req, i_prof.institution, i_prof.software);
                            l_pn_datetime := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                         i_date => l_sysdate_tstz,
                                                                         i_inst => i_prof.institution,
                                                                         i_soft => i_prof.software);
                        
                            pk_alertlog.log_debug('set_pn_free_text l_sp_id_prof:' || l_sp_id_prof.id || 'EPIS_' ||
                                                  l_episode || ' l_prof_cat:' || l_prof_cat);
                            IF NOT
                                pk_prog_notes_core.set_pn_free_text(i_lang       => i_lang,
                                                                    i_prof       => l_sp_id_prof,
                                                                    i_episode    => l_episode,
                                                                    i_dt_pn_date => table_varchar(pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                              i_date => l_sysdate_tstz,
                                                                                                                              i_prof => i_prof),
                                                                                                  NULL),
                                                                    i_note_type  => CASE l_prof_cat
                                                                                        WHEN pk_alert_constant.g_cat_type_nurse THEN
                                                                                         pk_prog_notes_constants.g_note_type_shif_summary_51
                                                                                        WHEN pk_alert_constant.g_cat_type_doc THEN
                                                                                         pk_prog_notes_constants.g_note_type_shif_summary_52
                                                                                    END,
                                                                    i_pn_note    => table_clob(to_clob(l_pn_datetime),
                                                                                               to_clob(l_epis_prof_resp_notes)),
                                                                    o_id_epis_pn => l_id_epis_pn,
                                                                    o_error      => o_error)
                            THEN
                                RAISE l_internal_error;
                            END IF;
                        
                        END IF;
                    
                    END IF;
                
                ELSIF i_flg_status = g_hand_off_d
                THEN
                    -- rejeitar pedido de transferência
                    g_error := 'UPDATE EPIS_PROF_RESP - D';
                   xepr := pk_hand_off_core.set_epis_prof_resp_h( i_epis_prof_resp(i) );
                   xepr.dt_decline_tstz   := l_sysdate_tstz;
                   xepr.flg_status   := i_flg_status;
                   xepr.id_prof_decline   := i_prof.id;
                   xepr.id_epis_prof_resp := i_epis_prof_resp(i);
                   
                    UPDATE epis_prof_resp
                       SET dt_decline_tstz = l_sysdate_tstz, flg_status = i_flg_status, id_prof_decline = i_prof.id
                     WHERE id_epis_prof_resp = i_epis_prof_resp(i);
                
                     pk_hand_off_core.ins_epis_prof_resp_h( xepr );
                
                    -- elimina o alerta 32 se este existir
                    delete_hand_off_event(i_lang, i_prof, l_episode, i_epis_prof_resp(i));
                
                    l_update_multi_resp := TRUE;
                
                ELSIF i_flg_status = g_hand_off_t
                THEN
                    -- Terminate (end) responsability over episode
                    g_error := 'UPDATE EPIS_PROF_RESP - T';
                   xepr := pk_hand_off_core.set_epis_prof_resp_h( i_epis_prof_resp(i) );
                   xepr.dt_end_transfer_tstz   := l_sysdate_tstz;
                   xepr.flg_status             := i_flg_status;
                   xepr.id_epis_prof_resp      := i_epis_prof_resp(i);

                    UPDATE epis_prof_resp epr
                       SET epr.dt_end_transfer_tstz = l_sysdate_tstz, flg_status = i_flg_status
                     WHERE id_epis_prof_resp = i_epis_prof_resp(i);
                
                     pk_hand_off_core.ins_epis_prof_resp_h( xepr );
                
                    -- Remove responsability from EPIS_INFO
                    IF l_id_prof_responsible = i_prof.id
                       AND i_flg_type = g_flg_type_d
                    THEN
                        g_error := 'UPDATE EPIS_INFO - RESPONSIBLE PROFS. DOC. (1)';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_hand_off_core.call_set_epis_info_resp(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_id_episode          => l_episode,
                                                                        i_id_professional     => NULL,
                                                                        i_id_professional_nin => FALSE,
                                                                        i_prof_cat            => g_flg_type_d,
                                                                        i_flg_resp_type       => l_flg_resp_type,
                                                                        o_error               => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                    ELSIF l_id_prof_responsible = i_prof.id
                          AND i_flg_type = g_flg_type_n
                    THEN
                        g_error := 'UPDATE EPIS_INFO - RESPONSIBLE PROFS. NURSE (1)';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_hand_off_core.call_set_epis_info_resp(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_id_episode          => l_episode,
                                                                        i_id_professional     => NULL,
                                                                        i_id_professional_nin => FALSE,
                                                                        i_prof_cat            => g_flg_type_n,
                                                                        i_flg_resp_type       => l_flg_resp_type,
                                                                        o_error               => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    END IF;
                
                    l_can_refresh_mview := TRUE;
                    l_update_multi_resp := TRUE;
                
                END IF;
            
                IF l_update_multi_resp
                THEN
                    g_error := 'MANAGE MULTI HAND-OFF MECHANISM';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_hand_off_core.set_multi_prof_resp(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_episode => l_episode,
                                                                -- If it is a cancellation, keep the ID_PROFESSIONAL for whom the request was made,
                                                                -- since the professional who cancels, can be of a different profile.
                                                                -- If it is denied or accepted, use the current I_PROF.ID.
                                                                i_id_prof_resp            => CASE i_flg_status --
                                                                                                 WHEN g_hand_off_c THEN
                                                                                                  l_id_prof_request_to --
                                                                                                 ELSE
                                                                                                  i_prof.id
                                                                                             END,
                                                                i_flg_profile             => l_flg_profile,
                                                                i_id_epis_prof_resp       => i_epis_prof_resp(i),
                                                                i_flg_status              => i_flg_status,
                                                                i_sysdate                 => l_sysdate_tstz,
                                                                i_hand_off_type           => l_handoff_type,
                                                                i_flg_main_responsible    => l_set_main_responsible,
                                                                i_id_speciality           => l_id_speciality,
                                                                i_flg_resp_type           => l_flg_resp_type,
                                                                o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                o_error                   => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                    l_update_multi_resp := FALSE; -- Reset variable
                
                    -- Set end date of previous responsability, if a new responsability is being accepted.
                    IF i_flg_status = g_hand_off_f
                    THEN
                        g_error := 'SET END DATE';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_hand_off_core.call_set_end_responsability(i_lang                    => i_lang,
                                                                            i_prof                    => i_prof,
                                                                            i_id_epis_prof_resp       => i_epis_prof_resp(i),
                                                                            i_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                            i_hand_off_type           => l_handoff_type,
                                                                            i_dt_end_transfer         => l_sysdate_tstz,
                                                                            o_error                   => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
            IF i_one_step_process = 'N'
            THEN
                g_error := 'CALL TO SET_FIRST_OBS';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => l_episode,
                                              i_pat                 => NULL,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => i_flg_type,
                                              i_dt_last_interaction => l_sysdate_tstz,
                                              i_dt_first_obs        => l_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        END LOOP;
    
        o_refresh_mview := 'Y';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_value_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'VALUE ERROR',
                                              'INVALID VALUE FOUND',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END call_set_epis_prof_resp;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * Function called by the Flash layer.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tot_epis               Array com o número total de episódios de transferência de responsabilidade,que o profissional vai aceitar, cancelar ou rejeitar
    * @param i_epis_prof_resp         Array com os IDs dos episódios de transferência de responsabilidade
    * @param i_flg_status             Status da Transferência de responsabilidade:  C - Cancelado;
                                                                                    F- Final;
                                                                                    D- Rejeitado        
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_notes                  Notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/08/11
    *
    * @alter                          Jos?Brito
    * @version                        2.5.0.7 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION set_epis_prof_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tot_epis       IN table_number,
        i_epis_prof_resp IN table_varchar,
        i_flg_status     IN epis_prof_resp.flg_status%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(200) := 'SET_EPIS_PROF_RESP';
        l_can_refresh_mview_str VARCHAR2(1) := 'N';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO SET_EPIS_PROF_RESP';
        pk_alertlog.log_debug(g_error);
        IF NOT call_set_epis_prof_resp(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_tot_epis         => i_tot_epis,
                                       i_epis_prof_resp   => i_epis_prof_resp,
                                       i_flg_status       => i_flg_status,
                                       i_flg_type         => i_flg_type,
                                       i_notes            => i_notes,
                                       i_sysdate          => NULL,
                                       i_hand_off_type    => NULL,
                                       i_one_step_process => 'N',
                                       i_id_cancel_reason => NULL,
                                       o_refresh_mview    => l_can_refresh_mview_str,
                                       o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL TO SET_PROF_RESPONSIBLE_ALERT';
        IF NOT
            set_prof_responsible_alert(i_lang => i_lang, i_prof => i_prof, i_tot_epis => i_tot_epis, o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        g_error := 'UPDATE MVIEW';
        IF l_can_refresh_mview_str = 'Y'
        THEN
            pk_episode.update_mv_episodes();
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_prof_resp;

    /**********************************************************************************************
    * Registar os pedidos de transferência de responsabilidade
    *  A transferência de responsabilidade poder?ser efectuada sobre vários episódios.
    *  Ser?possivél efectuar a transf. de responsabilidade para um ou vários profissionais.
    *  O mesmo poder?acontecer com as especialidades, uma ou várias especialidades.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array dos profissionais a quem foi pedido a transferência de responsabilidade   
    * @param i_tot_epis               Array com o número total de episódios para os quais foi pedido transferência de responsabilidade
    * @param i_epis_pat               Array com os IDs episódios / pacientes para os quais foi pedido transferência de responsabilidade
    * @param i_cs_or_dept             Array dos serviços clinicos ou departamentos onde foi efectuado o pedido a transferência de responsabilidade.        
    * @param i_notes                  Array de Notas
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_flg_resp               Pode assumir 2 valores: G -  Assumir responsabilidade do paciente nas grelhas de entrada
                                                              H -  Hand- Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Current date
    * @param i_id_speciality          Responsability request speciality
    * @param o_epis_prof_resp         List of created id's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/08/11
    *
    * @alter                          Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/02
    **********************************************************************************************/
    FUNCTION create_epis_prof_resp_int
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_to               IN table_varchar,
        i_tot_epis              IN table_number,
        i_epis_pat              IN table_number,
        i_cs_or_dept            IN table_number,
        i_notes                 IN table_varchar,
        i_flg_type              IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp              IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality         IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        i_priority              IN NUMBER DEFAULT NULL,
        i_sbar_note             IN CLOB DEFAULT NULL,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg_body              OUT VARCHAR2,
        o_epis_prof_resp        OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                VARCHAR2(32) := 'CREATE_EPIS_PROF_RESP';
        l_next                     epis_prof_resp.id_epis_prof_resp%TYPE;
        l_requested_epis_prof_resp epis_prof_resp.id_epis_prof_resp%TYPE;
        l_movement                 movement.id_movement%TYPE;
        l_id_current_prof_resp     professional.id_professional%TYPE;
        l_prof_cat                 category.flg_type%TYPE;
        l_prof_dest                epis_prof_resp.id_prof_to%TYPE;
        l_epis_flg_status          episode.flg_status%TYPE;
        l_handoff_nurse            sys_config.value%TYPE;
        l_handoff_type             sys_config.value%TYPE;
        l_flg_transf_type          epis_prof_resp.flg_transf_type%TYPE;
        l_flg_main_responsible     epis_multi_prof_resp.flg_main_responsible%TYPE := 'N';
        l_id_prof_req              epis_prof_resp.id_prof_req%TYPE;
        l_epis_prof_resp_notes     epis_prof_resp.notes_clob%TYPE;
    
        l_prof_to    table_varchar;
        l_prof_2     table_varchar := table_varchar();
        l_rows_updei table_varchar;
        l_ids        table_number := table_number();
        l_prof_name  professional.name%TYPE;
        l_prof       profissional;
    
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_epis_prof_resp_req      epis_prof_resp%ROWTYPE;
        l_id_clinical_service     clinical_service.id_clinical_service%TYPE;
        l_id_cs_dest              epis_prof_resp.id_clinical_service_dest%TYPE;
        l_id_dpt_dest             epis_prof_resp.id_department_dest%TYPE;
        l_flg_profile             profile_template.flg_profile%TYPE := i_flg_profile; -- Load flg_profile
        l_id_speciality           epis_multi_prof_resp.id_speciality%TYPE;
        l_id_dcs                  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_new_id_cs               dep_clin_serv.id_clinical_service%TYPE;
        l_new_id_dpt              dep_clin_serv.id_department%TYPE;
        l_new_flg_status          epis_prof_resp.flg_status%TYPE;
        l_epis_software           epis_info.id_software%TYPE;
    
        l_can_update_epis_info    BOOLEAN := FALSE;
        l_can_refresh_mview_str   VARCHAR2(1) := 'N';
        l_can_refresh_mview       BOOLEAN := FALSE;
        l_register_epis_prof_resp NUMBER(6) := 0;
    
        l_invalid_parameter EXCEPTION;
        l_invalid_config    EXCEPTION;
        l_internal_error    EXCEPTION;
        l_no_dcs_defined    EXCEPTION;
    
        l_hand_off_alert CONSTANT sys_alert.id_sys_alert%TYPE := 32;
    
        l_error_message sys_message.desc_message%TYPE;
    
        l_config_create_note       sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'HANDOFF_CREATE_SHIFT_SUMMARY_NOTE',
                                                                                    i_prof    => i_prof);
        l_sp_id_prof               profissional;
        l_id_epis_pn               epis_pn.id_epis_pn%TYPE;
        l_pn_datetime              VARCHAR2(40 CHAR);
        l_id_prof_resp             table_number;
        l_prof_name_list           table_varchar;
        l_pos                      NUMBER := 0;
        l_handoff_multi_spec       sys_config.id_sys_config%TYPE := 'MULTIPLE_HAND_OFF_MULTI_SPEC';
        l_handoff_multi_spec_value sys_config.value%TYPE;
    
        l_profile_template profile_template.id_profile_template%TYPE;
    
        xepr    epis_prof_resp%ROWTYPE;
        l_value VARCHAR2(4000);
    
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        IF i_sysdate IS NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        ELSE
            g_sysdate_tstz := i_sysdate;
        END IF;
    
        IF i_flg_resp = g_flg_resp_g
           AND i_flg_assign_supervisor = g_yes
        THEN
            l_prof := profissional(i_prof_to(1), i_prof.institution, i_prof.software);
        ELSE
            l_prof := i_prof;
        END IF;
    
        ----------------------------------------------------------------------------
        IF nvl(cardinality(i_prof_to), 0) < nvl(cardinality(i_tot_epis), 0)
           AND i_prof_to.exists(1)
        THEN
            FOR i IN i_tot_epis.first .. i_tot_epis.last
            LOOP
                l_prof_2.extend;
                l_prof_2(l_prof_2.last) := i_prof_to(1);
            END LOOP;
            NULL;
        ELSIF NOT i_prof_to.exists(1)
        THEN
            l_prof_2.extend(i_tot_epis.count);
        ELSE
            l_prof_2 := i_prof_to;
        END IF;
    
        l_handoff_nurse := pk_sysconfig.get_config('HANDOFF_NURSE', i_prof.institution, i_prof.software);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_handoff_type); -- Type of hand-off: (N) Normal (M) Multiple
    
        -- Validate parameters and configurations
        IF l_handoff_nurse IS NULL
           OR l_handoff_type IS NULL
           OR l_handoff_type NOT IN (g_handoff_normal, g_handoff_multiple)
        THEN
            g_error := 'CONFIGURATION IS INVALID';
            pk_alertlog.log_debug(g_error);
            RAISE l_invalid_config;
        END IF;
    
        -- Get professional category
        g_error := 'GET PROF NAME/CATEGORY';
        pk_alertlog.log_debug(g_error);
        IF i_flg_resp = g_flg_resp_g
           AND i_flg_assign_supervisor = g_yes
        THEN
            l_prof_name := pk_prof_utils.get_name_signature(i_lang, l_prof, l_prof.id);
            l_prof_cat  := pk_prof_utils.get_category(i_lang => i_lang, i_prof => l_prof);
        ELSE
            l_prof_name := pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id);
            l_prof_cat  := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        END IF;
        l_handoff_multi_spec_value := pk_sysconfig.get_config(l_handoff_multi_spec, l_prof);
        ----------------------------------------------------------------------------------------------------------------
        -- IMPORTANT!!
        -- OUTPATIENT, SOCIAL_ASSIST, DIETITIAN, CARE and PRIVATE PRACTICE handles episode responsability differently
        -- from other softwares:
        --  1) Responsability IS NOT registered in EPIS_PROF_RESP;
        --     1.1) From Nov/2011, OUTP/CARE/PP also register responsability in EPIS_PROF_RESP.
        --  2) Responsability IS registered ONLY in EPIS_INFO;
        ----------------------------------------------------------------------------------------------------------------
        IF i_prof.software IN (pk_alert_constant.g_soft_primary_care,
                               pk_alert_constant.g_soft_private_practice,
                               pk_alert_constant.g_soft_social,
                               pk_alert_constant.g_soft_nutritionist,
                               pk_alert_constant.g_soft_psychologist,
                               pk_alert_constant.g_soft_case_manager,
                               pk_alert_constant.g_soft_rehab,
                               pk_alert_constant.g_soft_resptherap)
        THEN
        
            -- Check if current software can register responsability in EPIS_PROF_RESP
            l_register_epis_prof_resp := pk_hand_off_core.is_ambulatory_product(i_prof.software);
        
            FOR i IN 1 .. i_tot_epis.count
            LOOP
                g_error := 'GET EPISODE STATUS AND CURRENT RESPONSBILE (AMB)';
                pk_alertlog.log_debug(g_error);
                -- Check if episode is active / Current responsible for the patient
                IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                              i_prof          => l_prof,
                                                              i_id_episode    => i_epis_pat(i),
                                                              i_prof_cat      => i_flg_type,
                                                              i_flg_profile   => NULL,
                                                              i_hand_off_type => l_handoff_type,
                                                              i_flg_resp_type => pk_hand_off_core.g_resp_episode,
                                                              i_id_speciality => NULL,
                                                              o_epis_status   => l_epis_flg_status,
                                                              o_id_prof_resp  => l_id_current_prof_resp,
                                                              o_error         => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF i_prof.id != l_prof_2(i)
                THEN
                    --get_profile_template
                    l_profile_template := pk_prof_utils.get_prof_profile_template(profissional(l_prof_2(i),
                                                                                               i_prof.institution,
                                                                                               i_prof.software));
                ELSE
                    l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
                END IF;
            
                IF l_epis_flg_status = g_epis_active
                THEN
                    IF i_flg_resp = g_flg_resp_g -- Accept EPISODE responsability in the hand-off popup OR Self-request in the hand-off screen
                    THEN
                        IF l_register_epis_prof_resp > 0
                        THEN
                            g_error := 'CALL TO GET_PREFERRED_PROF_DCS (1)';
                            pk_alertlog.log_debug(g_error);
                            IF NOT get_preferred_prof_dcs(i_lang                 => i_lang,
                                                          i_prof                 => l_prof,
                                                          i_episode              => i_epis_pat(i),
                                                          i_dest_professional    => l_prof_2(i),
                                                          i_flg_type             => i_flg_type,
                                                          i_handoff_type         => l_handoff_type,
                                                          i_handoff_nurse_config => l_handoff_nurse,
                                                          o_id_clinical_service  => l_new_id_cs,
                                                          o_id_department        => l_new_id_dpt,
                                                          o_error_message        => l_error_message,
                                                          o_error                => o_error)
                            THEN
                                IF l_error_message IS NOT NULL
                                THEN
                                    RAISE l_no_dcs_defined;
                                ELSE
                                    RAISE l_internal_error;
                                END IF;
                            END IF;
                        
                            g_error := 'INSERT EPIS_PROF_RESP (AMB1)';
                            pk_alertlog.log_debug(g_error);
                        
                            xepr                          := NULL;
                            xepr.id_epis_prof_resp        := seq_epis_prof_resp.nextval;
                            xepr.id_episode               := i_epis_pat(i);
                            xepr.dt_request_tstz          := g_sysdate_tstz;
                            xepr.id_prof_req              := i_prof.id;
                            xepr.id_prof_to               := iif(l_prof_2(i) = -1, NULL, l_prof_2(i));
                            xepr.id_prof_comp             := l_prof.id;
                            xepr.id_prof_prev             := NULL;
                            xepr.id_speciality            := NULL;
                            xepr.id_movement              := NULL;
                            xepr.notes_clob               := i_notes(i);
                            xepr.dt_comp_tstz             := g_sysdate_tstz;
                            xepr.flg_type                 := i_flg_type;
                            xepr.flg_transfer             := g_transfer_n;
                            xepr.flg_status               := g_hand_off_f;
                            xepr.flg_transf_type          := g_flg_transf_i;
                            xepr.id_department_dest       := l_new_id_dpt;
                            xepr.id_department_orig       := l_new_id_dpt;
                            xepr.id_clinical_service_dest := l_new_id_cs;
                            xepr.id_clinical_service_orig := l_new_id_cs;
                            xepr.sbar_notes               := i_sbar_note;
                            xepr.id_epis_pn               := i_id_epis_pn;
                            xepr.id_profile_template      := l_profile_template;
                        
                            INSERT INTO epis_prof_resp
                                (id_epis_prof_resp,
                                 id_episode,
                                 dt_request_tstz,
                                 id_prof_req,
                                 id_prof_to,
                                 id_prof_comp,
                                 id_prof_prev,
                                 id_speciality,
                                 id_movement,
                                 notes_clob,
                                 dt_comp_tstz,
                                 flg_type,
                                 flg_transfer,
                                 flg_status,
                                 flg_transf_type,
                                 id_department_dest,
                                 id_department_orig,
                                 id_clinical_service_dest,
                                 id_clinical_service_orig,
                                 sbar_notes,
                                 id_epis_pn,
                                 id_profile_template)
                            VALUES
                                (xepr.id_epis_prof_resp,
                                 xepr.id_episode,
                                 xepr.dt_request_tstz,
                                 xepr.id_prof_req,
                                 xepr.id_prof_to,
                                 xepr.id_prof_comp,
                                 xepr.id_prof_prev,
                                 xepr.id_speciality,
                                 xepr.id_movement,
                                 xepr.notes_clob,
                                 xepr.dt_comp_tstz,
                                 xepr.flg_type,
                                 xepr.flg_transfer,
                                 xepr.flg_status,
                                 xepr.flg_transf_type,
                                 xepr.id_department_dest,
                                 xepr.id_department_orig,
                                 xepr.id_clinical_service_dest,
                                 xepr.id_clinical_service_orig,
                                 xepr.sbar_notes,
                                 xepr.id_epis_pn,
                                 xepr.id_profile_template)
                            RETURNING id_epis_prof_resp INTO l_next;
                        
                            -- cmf
                            pk_hand_off_core.ins_epis_prof_resp_h(i_row => xepr);
                        
                        END IF;
                    
                        g_error := 'UPDATE EPIS_INFO - RESPONSIBLE PROFS. [OUTP]';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_hand_off_core.call_set_epis_info_resp_all(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_id_episode          => i_epis_pat(i),
                                                                       i_id_professional     => CASE
                                                                                                    WHEN i_flg_type != g_flg_type_n THEN
                                                                                                     l_prof.id
                                                                                                    ELSE
                                                                                                     NULL
                                                                                                END,
                                                                       i_id_professional_nin => TRUE, -- Ignore NULL values, i.e. do NOT update if NULL value is found.
                                                                       i_prof_cat            => l_prof_cat,
                                                                       i_id_prof_nurse       => CASE i_flg_type
                                                                                                    WHEN g_flg_type_n THEN
                                                                                                     l_prof.id
                                                                                                    ELSE
                                                                                                     NULL
                                                                                                END,
                                                                       i_id_prof_nurse_nin   => TRUE,
                                                                       i_flg_resp_type       => pk_hand_off_core.g_resp_episode, -- This function is ALWAYS used only for episode responsability
                                                                       o_error               => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                        -- Remove alert event
                        g_error := 'REMOVE HAND-OFF ALERT (AMB)';
                        pk_alertlog.log_debug(text => g_error);
                        delete_hand_off_event(i_lang, l_prof, i_epis_pat(i), l_next);
                    
                    ELSIF i_flg_resp = g_flg_resp_h -- Request EPISODE responsability in the hand-off screen
                    THEN
                        IF l_register_epis_prof_resp > 0
                        THEN
                            g_error := 'INSERT EPIS_PROF_RESP (AMB1)';
                            pk_alertlog.log_debug(g_error);
                        
                            xepr                          := NULL;
                            xepr.id_epis_prof_resp        := seq_epis_prof_resp.nextval;
                            xepr.id_episode               := i_epis_pat(i);
                            xepr.dt_request_tstz          := g_sysdate_tstz;
                            xepr.id_prof_req              := i_prof.id;
                            xepr.id_prof_to               := iif((l_prof_2(i) = -1), NULL, l_prof_2(i));
                            xepr.id_prof_prev             := l_id_current_prof_resp; -- Previous responsible
                            xepr.id_department_dest       := NULL;
                            xepr.id_clinical_service_dest := NULL;
                            IF i_flg_type = g_flg_type_n
                            THEN
                                IF l_handoff_nurse = g_handoff_nurse_department
                                THEN
                                    xepr.id_department_dest := i_cs_or_dept(i);
                                END IF;
                            END IF;
                        
                            CASE i_flg_type
                                WHEN g_flg_type_d THEN
                                    IF l_handoff_type = g_handoff_normal
                                    THEN
                                        xepr.id_clinical_service_dest := i_cs_or_dept(i);
                                    END IF;
                                WHEN g_flg_type_n THEN
                                
                                    IF l_handoff_type = g_handoff_nurse_clin_serv
                                    THEN
                                        xepr.id_clinical_service_dest := i_cs_or_dept(i);
                                    END IF;
                            END CASE;
                        
                            xepr.id_movement         := NULL;
                            xepr.notes_clob          := i_notes(i);
                            xepr.flg_type            := i_flg_type;
                            xepr.flg_transfer        := g_transfer_y;
                            xepr.flg_status          := iif((i_prof.id = to_number(l_prof_2(i))),
                                                            g_hand_off_f,
                                                            g_hand_off_r);
                            xepr.flg_transf_type     := g_flg_transf_i;
                            xepr.sbar_notes          := i_sbar_note;
                            xepr.id_epis_pn          := i_id_epis_pn;
                            xepr.id_profile_template := l_profile_template;
                        
                            INSERT INTO epis_prof_resp
                                (id_epis_prof_resp,
                                 id_episode,
                                 dt_request_tstz,
                                 id_prof_req,
                                 id_prof_to,
                                 id_prof_prev,
                                 id_department_dest,
                                 id_clinical_service_dest,
                                 id_movement,
                                 notes_clob,
                                 flg_type,
                                 flg_transfer,
                                 flg_status,
                                 flg_transf_type,
                                 sbar_notes,
                                 id_epis_pn,
                                 id_profile_template)
                            VALUES
                                (xepr.id_epis_prof_resp,
                                 xepr.id_episode,
                                 xepr.dt_request_tstz,
                                 xepr.id_prof_req,
                                 xepr.id_prof_to,
                                 xepr.id_prof_prev,
                                 xepr.id_department_dest,
                                 xepr.id_clinical_service_dest,
                                 xepr.id_movement,
                                 xepr.notes_clob,
                                 xepr.flg_type,
                                 xepr.flg_transfer,
                                 xepr.flg_status,
                                 xepr.flg_transf_type,
                                 xepr.sbar_notes,
                                 xepr.id_epis_pn,
                                 xepr.id_profile_template)
                            RETURNING id_epis_prof_resp INTO l_next;
                        
                            pk_hand_off_core.ins_epis_prof_resp_h(i_row => xepr);
                        
                            g_error := 'INSERT ALERT EVENT (AMB)';
                            pk_alertlog.log_debug(g_error);
                            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_sys_alert           => l_hand_off_alert,
                                                                    i_id_episode          => i_epis_pat(i),
                                                                    i_id_record           => l_next,
                                                                    i_dt_record           => g_sysdate_tstz,
                                                                    i_id_professional     => l_prof_2(i),
                                                                    i_id_room             => NULL,
                                                                    i_id_clinical_service => CASE i_flg_type
                                                                                                 WHEN g_flg_type_d THEN
                                                                                                  CASE l_handoff_type
                                                                                                      WHEN g_handoff_normal THEN
                                                                                                       i_cs_or_dept(i)
                                                                                                      ELSE
                                                                                                       NULL
                                                                                                  END
                                                                                                 WHEN g_flg_type_n THEN
                                                                                                  CASE l_handoff_nurse
                                                                                                      WHEN
                                                                                                       g_handoff_nurse_clin_serv THEN
                                                                                                       i_cs_or_dept(i)
                                                                                                      ELSE
                                                                                                       NULL
                                                                                                  END
                                                                                                 ELSE
                                                                                                  NULL
                                                                                             END,
                                                                    i_flg_type_dest       => NULL,
                                                                    i_replace1            => NULL,
                                                                    i_replace2            => l_prof_name,
                                                                    o_error               => o_error)
                            THEN
                                RAISE l_internal_error;
                            END IF;
                        
                        END IF;
                    
                    ELSE
                        g_error := 'INVALID PARAMETER(S) FOUND - I_FLG_RESP';
                        pk_alertlog.log_debug(g_error);
                        RAISE l_invalid_parameter;
                    END IF;
                
                END IF;
            END LOOP;
        
            RETURN TRUE;
        END IF;
    
        ---------------------------------------------------------------------------------------------------------------------
        -- END: Ambulatory products hand-off logic
        ---------------------------------------------------------------------------------------------------------------------
    
        IF l_flg_profile IS NULL -- For example, this happens in the external hand-off screens
           AND l_handoff_type = g_handoff_multiple
        THEN
            -- Request to the same type of profile as the current professional
            g_error := 'GET KIND OF PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => l_prof,
                                                    i_profile_template => NULL,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF i_flg_type NOT IN (g_flg_type_d, g_flg_type_n)
           OR i_flg_resp NOT IN (g_flg_resp_g, g_flg_resp_h)
          -- Type of profile is MANDATORY in multiple hand-off type.
           OR (l_handoff_type = g_handoff_multiple AND l_flg_profile IS NULL)
        THEN
            g_error := 'INVALID PARAMETER(S) FOUND';
            pk_alertlog.log_debug(g_error);
            RAISE l_invalid_parameter;
        END IF;
    
        -- Get transfer speciality
        IF ((l_flg_profile = pk_hand_off_core.g_nurse AND l_handoff_type = pk_hand_off.g_handoff_multiple) OR
           l_handoff_type = pk_hand_off.g_handoff_normal)
        THEN
            l_id_speciality := NULL;
        
        ELSIF l_handoff_type = pk_hand_off.g_handoff_multiple
        THEN
            IF i_flg_resp = g_flg_resp_g
            THEN
                -- Professional is taking over responsability in the grids. Get his/her speciality.
                l_id_speciality := nvl(pk_prof_utils.get_prof_speciality_id(i_lang, l_prof), i_id_speciality);
            
            ELSIF i_flg_resp = g_flg_resp_h
            THEN
                -- Professional is requesting responsability in the hand-off screen. Use speciality send in the parameters.
                l_id_speciality := i_id_speciality;
            
            END IF;
        
            IF l_id_speciality IS NULL
            THEN
                -- After this point, in MULTIPLE hand-off, speciality cannot be null.
                g_error := 'SPECIALITY NOT SPECIFIED';
                pk_alertlog.log_debug(g_error);
                RAISE l_invalid_parameter;
            END IF;
        END IF;
    
        -- Start processing the hand-off for all patients
        FOR i IN 1 .. i_tot_epis.count
        LOOP
            g_error := 'GET EPISODE STATUS AND CURRENT RESPONSBILE';
            pk_alertlog.log_debug(g_error);
            -- Check if episode is active / Current responsible for the patient
            IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                          i_prof          => l_prof,
                                                          i_id_episode    => i_epis_pat(i),
                                                          i_prof_cat      => i_flg_type,
                                                          i_flg_profile   => l_flg_profile,
                                                          i_hand_off_type => l_handoff_type,
                                                          i_flg_resp_type => pk_hand_off_core.g_resp_episode,
                                                          i_id_speciality => l_id_speciality,
                                                          o_epis_status   => l_epis_flg_status,
                                                          o_id_prof_resp  => l_id_prof_resp,
                                                          o_prof_name     => l_prof_name_list,
                                                          o_error         => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
            IF i_prof.id != l_prof_2(i)
            THEN
                --get_profile_template
                l_profile_template := pk_prof_utils.get_prof_profile_template(profissional(l_prof_2(i),
                                                                                           i_prof.institution,
                                                                                           i_prof.software));
            ELSE
                l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
            END IF;
            IF l_id_prof_resp IS NOT NULL
            THEN
                l_pos := pk_utils.search_table_number(l_id_prof_resp, l_prof.id);
                IF l_pos = -1
                THEN
                    l_id_current_prof_resp := l_id_prof_resp(1);
                ELSE
                    l_id_current_prof_resp := l_prof.id;
                END IF;
            END IF;
            ------------------------------------------------------------------------------------
            -- (A) Take over responsability in patient grids (e.g. when accessing patient's EHR)
            ------------------------------------------------------------------------------------
            IF i_flg_resp = g_flg_resp_g
               AND l_epis_flg_status = g_epis_active
            THEN
            
                g_error := 'CALL TO GET_PREFERRED_PROF_DCS (2)';
                pk_alertlog.log_debug(g_error);
                IF NOT get_preferred_prof_dcs(i_lang                 => i_lang,
                                              i_prof                 => l_prof,
                                              i_episode              => i_epis_pat(i),
                                              i_dest_professional    => l_prof_2(i),
                                              i_flg_type             => i_flg_type,
                                              i_handoff_type         => l_handoff_type,
                                              i_handoff_nurse_config => l_handoff_nurse,
                                              o_id_clinical_service  => l_new_id_cs,
                                              o_id_department        => l_new_id_dpt,
                                              o_error_message        => l_error_message,
                                              o_error                => o_error)
                THEN
                    IF l_error_message IS NOT NULL
                    THEN
                        RAISE l_no_dcs_defined;
                    ELSE
                        RAISE l_internal_error;
                    END IF;
                END IF;
            
                -- Check if already exists any pending request for the current profile/speciality
                g_error := 'GET EXISTING REQUESTED TRANSFER';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.get_existing_handoff_req(i_lang           => i_lang,
                                                                 i_prof           => l_prof,
                                                                 i_id_episode     => i_epis_pat(i),
                                                                 i_req_status     => g_hand_off_r, -- Requested transfer
                                                                 i_transf_type    => g_flg_transf_i, -- Individual transfer
                                                                 i_flg_type       => i_flg_type, -- Physician or nurse hand-off
                                                                 i_flg_profile    => l_flg_profile,
                                                                 i_hand_off_type  => l_handoff_type,
                                                                 i_id_speciality  => l_id_speciality,
                                                                 o_epis_prof_resp => l_epis_prof_resp_req,
                                                                 o_error          => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF l_epis_prof_resp_req.id_epis_prof_resp IS NULL
                   AND l_handoff_multi_spec_value = pk_alert_constant.g_yes
                THEN
                    IF NOT pk_hand_off_core.get_existing_handoff_req(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_id_episode      => i_epis_pat(i),
                                                                     i_req_status      => pk_hand_off_core.g_active, -- Requested transfer
                                                                     i_transf_type     => g_flg_transf_i, -- OVERALL responsability
                                                                     i_flg_type        => i_flg_type, -- Physician hand-off
                                                                     i_flg_profile     => l_flg_profile,
                                                                     i_hand_off_type   => l_handoff_type,
                                                                     i_id_speciality   => l_id_speciality,
                                                                     i_id_professional => l_prof.id,
                                                                     o_epis_prof_resp  => l_epis_prof_resp_req,
                                                                     o_error           => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                END IF;
            
                l_requested_epis_prof_resp := l_epis_prof_resp_req.id_epis_prof_resp;
                l_prof_dest                := l_epis_prof_resp_req.id_prof_to;
                l_id_cs_dest               := l_epis_prof_resp_req.id_clinical_service_dest;
                l_id_dpt_dest              := l_epis_prof_resp_req.id_department_dest;
                l_id_prof_req              := l_epis_prof_resp_req.id_prof_req;
                l_epis_prof_resp_notes     := l_epis_prof_resp_req.notes_clob;
            
                IF l_id_current_prof_resp IS NULL -- NO RESPONSIBLE for the patient
                THEN
                    IF l_requested_epis_prof_resp IS NOT NULL
                       AND l_prof_dest = l_prof.id -- Requested for "Me"
                    THEN
                        g_error := 'UPDATE EPIS_PROF_RESP - REQUESTED FOR CURRENT PROF.';
                        pk_alertlog.log_debug(g_error);
            
             xepr := pk_hand_off_core.set_epis_prof_resp_h( l_requested_epis_prof_resp );
             xepr.id_epis_prof_resp := l_requested_epis_prof_resp;
             xepr.flg_status      := g_hand_off_f;
             xepr.id_prof_comp    := l_prof.id;
             xepr.dt_comp_tstz    := g_sysdate_tstz;
            
                        UPDATE epis_prof_resp
                           SET flg_status   = g_hand_off_f,
                               id_prof_comp = l_prof.id, -- Exists one request for "me", so confirm it.
                               dt_comp_tstz = g_sysdate_tstz
                         WHERE id_epis_prof_resp = l_requested_epis_prof_resp
                        RETURNING id_epis_prof_resp INTO l_next;
                    
            pk_hand_off_core.ins_epis_prof_resp_h( xepr );
                    
                        delete_hand_off_event(i_lang, l_prof, i_epis_pat(i), l_requested_epis_prof_resp);
                    
                    ELSE
                        IF l_requested_epis_prof_resp IS NOT NULL
                           AND l_prof_dest IS NULL -- Requested for "Any" professional
                        THEN
                            -- If the request is destinated to the current department,
                            -- cancel the request for "Any" professional, and create a new one.    
                            g_error := 'CANCEL HAND-OFF REQUEST (1)';
                            pk_alertlog.log_debug(g_error);
                            IF NOT pk_hand_off_core.cancel_dpt_hand_off_request(i_lang              => i_lang,
                                                                                i_prof              => l_prof,
                                                                                i_cs_dest           => l_id_cs_dest,
                                                                                i_dpt_dest          => l_id_dpt_dest,
                                                                                i_id_epis_prof_resp => l_requested_epis_prof_resp,
                                                                                i_sysdate           => g_sysdate_tstz,
                                                                                i_flg_profile       => l_flg_profile,
                                                                                i_hand_off_type     => l_handoff_type,
                                                                                i_id_speciality     => l_id_speciality,
                                                                                i_flg_resp_type     => pk_hand_off_core.g_resp_episode,
                                                                                o_error             => o_error)
                            THEN
                                RAISE l_internal_error;
                            END IF;
                        
                            -- elimina o alerta 32 se este existir
                            delete_hand_off_event(i_lang, l_prof, i_epis_pat(i), l_requested_epis_prof_resp);
                        END IF;
                    
                        -- Criar novo registo com o STATUS=F
                        g_error := 'INSERT EPIS_PROF_RESP (G1)';
                    
                        xepr                          := NULL;
                        xepr.id_epis_prof_resp        := seq_epis_prof_resp.nextval;
                        xepr.id_episode               := i_epis_pat(i);
                        xepr.dt_request_tstz          := g_sysdate_tstz;
                        xepr.id_prof_req              := i_prof.id;
                        xepr.id_prof_to               := iif((l_prof_2(i) = -1), NULL, l_prof_2(i));
                        xepr.id_prof_comp             := l_prof.id;
                        xepr.id_prof_prev             := NULL;
                        xepr.id_speciality            := NULL;
                        xepr.id_movement              := l_movement;
                        xepr.notes_clob               := i_notes(i);
                        xepr.dt_comp_tstz             := g_sysdate_tstz;
                        xepr.flg_type                 := i_flg_type;
                        xepr.flg_transfer             := g_transfer_n; -- 1;
                        xepr.flg_status               := g_hand_off_f;
                        xepr.flg_transf_type          := g_flg_transf_a;
                        xepr.id_department_dest       := l_new_id_dpt;
                        xepr.id_department_orig       := l_new_id_dpt;
                        xepr.id_clinical_service_dest := l_new_id_cs;
                        xepr.id_clinical_service_orig := l_new_id_cs;
                        xepr.sbar_notes               := i_sbar_note;
                        xepr.id_epis_pn               := i_id_epis_pn;
                        xepr.id_profile_template      := l_profile_template;
                    
                        pk_alertlog.log_debug(g_error);
                        INSERT INTO epis_prof_resp
                            (id_epis_prof_resp,
                             id_episode,
                             dt_request_tstz,
                             id_prof_req,
                             id_prof_to,
                             id_prof_comp,
                             id_prof_prev,
                             id_speciality,
                             id_movement,
                             notes_clob,
                             dt_comp_tstz,
                             flg_type,
                             flg_transfer,
                             flg_status,
                             flg_transf_type,
                             id_department_dest,
                             id_department_orig,
                             id_clinical_service_dest,
                             id_clinical_service_orig,
                             sbar_notes,
                             id_epis_pn,
                             id_profile_template)
                        VALUES
                            (xepr.id_epis_prof_resp,
                             xepr.id_episode,
                             xepr.dt_request_tstz,
                             xepr.id_prof_req,
                             xepr.id_prof_to,
                             xepr.id_prof_comp,
                             xepr.id_prof_prev,
                             xepr.id_speciality,
                             xepr.id_movement,
                             xepr.notes_clob,
                             xepr.dt_comp_tstz,
                             xepr.flg_type,
                             xepr.flg_transfer,
                             xepr.flg_status,
                             xepr.flg_transf_type,
                             xepr.id_department_dest,
                             xepr.id_department_orig,
                             xepr.id_clinical_service_dest,
                             xepr.id_clinical_service_orig,
                             xepr.sbar_notes,
                             xepr.id_epis_pn,
                             xepr.id_profile_template)
                        RETURNING id_epis_prof_resp INTO l_next;
                    
                        pk_hand_off_core.ins_epis_prof_resp_h(xepr);
                    
                    END IF;
                
                ELSIF l_id_current_prof_resp IS NOT NULL
                -- O paciente j?tem um responsável
                THEN
                
                    IF l_requested_epis_prof_resp IS NULL -- Não existe nenhuma transferência REQUISITADA
                       AND l_prof.id <> l_id_current_prof_resp
                    THEN
                        -- Jos?Brito 26/08/2008 [WO17016] Se o actual profissional j?fôr responsável por este episódio,
                        -- não deve ser feito novo registo na EPIS_PROF_RESP.
                        g_error := 'INSERT EPIS_PROF_RESP (G2)';
                    
                        xepr                          := NULL;
                        xepr.id_epis_prof_resp        := seq_epis_prof_resp.nextval;
                        xepr.id_episode               := i_epis_pat(i);
                        xepr.dt_request_tstz          := g_sysdate_tstz;
                        xepr.id_prof_req              := i_prof.id;
                        xepr.id_prof_to               := iif(l_prof_2(i) = -1, NULL, l_prof_2(i));
                        xepr.id_prof_comp             := l_prof.id;
                        xepr.id_prof_prev             := l_id_current_prof_resp; -- Antigo responsavél pelo paciente ;
                        xepr.id_speciality            := NULL;
                        xepr.id_movement              := l_movement;
                        xepr.notes_clob               := i_notes(i);
                        xepr.dt_comp_tstz             := g_sysdate_tstz;
                        xepr.flg_type                 := i_flg_type;
                        xepr.flg_transfer             := g_transfer_n; -- "Desvio" da responsabilidade;
                        xepr.flg_status               := g_hand_off_f;
                        xepr.flg_transf_type          := g_flg_transf_a;
                        xepr.id_department_dest       := l_new_id_dpt;
                        xepr.id_department_orig       := l_new_id_dpt;
                        xepr.id_clinical_service_dest := l_new_id_cs;
                        xepr.id_clinical_service_orig := l_new_id_cs;
                        xepr.sbar_notes               := i_sbar_note;
                        xepr.id_epis_pn               := i_id_epis_pn;
                        xepr.id_profile_template      := l_profile_template;
                    
                        pk_alertlog.log_debug(g_error);
                        INSERT INTO epis_prof_resp
                            (id_epis_prof_resp,
                             id_episode,
                             dt_request_tstz,
                             id_prof_req,
                             id_prof_to,
                             id_prof_comp,
                             id_prof_prev,
                             id_speciality,
                             id_movement,
                             notes_clob,
                             dt_comp_tstz,
                             flg_type,
                             flg_transfer,
                             flg_status,
                             flg_transf_type,
                             id_department_dest,
                             id_department_orig,
                             id_clinical_service_dest,
                             id_clinical_service_orig,
                             sbar_notes,
                             id_epis_pn,
                             id_profile_template)
                        VALUES
                            (xepr.id_epis_prof_resp,
                             xepr.id_episode,
                             xepr.dt_request_tstz,
                             xepr.id_prof_req,
                             xepr.id_prof_to,
                             xepr.id_prof_comp,
                             xepr.id_prof_prev,
                             xepr.id_speciality,
                             xepr.id_movement,
                             xepr.notes_clob,
                             xepr.dt_comp_tstz,
                             xepr.flg_type,
                             xepr.flg_transfer,
                             xepr.flg_status,
                             xepr.flg_transf_type,
                             xepr.id_department_dest,
                             xepr.id_department_orig,
                             xepr.id_clinical_service_dest,
                             xepr.id_clinical_service_orig,
                             xepr.sbar_notes,
                             xepr.id_epis_pn,
                             xepr.id_profile_template)
                        RETURNING id_epis_prof_resp INTO l_next;
                    
                        pk_hand_off_core.ins_epis_prof_resp_h(xepr);
                    
                    ELSIF l_prof_dest = l_prof.id -- A transferência foi pedida para "mim"
                    THEN
                        -- Finalizar transferência:
                        --  Quando ?feito um pedido do prof_A para o prof_B e este assume a resp. apenas ?feito o UPD.
                        g_error := 'UPDATE EPIS_PROF_RESP - G3';
                        pk_alertlog.log_debug(g_error);
            
             xepr := pk_hand_off_core.set_epis_prof_resp_h( l_requested_epis_prof_resp );
             xepr.id_epis_prof_resp := l_requested_epis_prof_resp;
             xepr.flg_status   := g_hand_off_f;
             xepr.id_prof_comp := l_prof.id;
             xepr.dt_comp_tstz := g_sysdate_tstz;
            
                        UPDATE epis_prof_resp
                           SET flg_status   = g_hand_off_f,
                               id_prof_comp = l_prof.id, -- O Profissional que confirmou a transferência de responsabilidade ?quem est?a chamar a função
                               dt_comp_tstz = g_sysdate_tstz
                         WHERE id_epis_prof_resp = l_requested_epis_prof_resp
                        RETURNING id_epis_prof_resp INTO l_next;
                    
            pk_hand_off_core.ins_epis_prof_resp_h( xepr );
                    
                        -- elimina o alerta 32 se este existir
                        delete_hand_off_event(i_lang, l_prof, i_epis_pat(i), l_requested_epis_prof_resp);
                    
                    ELSE
                        -- Finalizar transferência:
                        --  Quando ?feito um pedido do prof_A para o prof_B e o prof_C assume a responsabilidade ?cancelado o anterior e 
                        --  criado um novo.
                        IF l_requested_epis_prof_resp IS NOT NULL
                        THEN
                            g_error := 'CANCEL HAND-OFF REQUEST (2)';
                            pk_alertlog.log_debug(g_error);
                            IF NOT pk_hand_off_core.cancel_dpt_hand_off_request(i_lang              => i_lang,
                                                                                i_prof              => l_prof,
                                                                                i_cs_dest           => l_id_cs_dest,
                                                                                i_dpt_dest          => l_id_dpt_dest,
                                                                                i_id_epis_prof_resp => l_requested_epis_prof_resp,
                                                                                i_sysdate           => g_sysdate_tstz,
                                                                                i_flg_profile       => l_flg_profile,
                                                                                i_hand_off_type     => l_handoff_type,
                                                                                i_id_speciality     => l_id_speciality,
                                                                                i_flg_resp_type     => pk_hand_off_core.g_resp_episode,
                                                                                o_error             => o_error)
                            THEN
                                RAISE l_internal_error;
                            END IF;
                        END IF;
                    
                        -- elimina o alerta 32 se este existir
                        delete_hand_off_event(i_lang, l_prof, i_epis_pat(i), l_requested_epis_prof_resp);
                    
                        IF l_prof.id <> l_id_current_prof_resp
                        THEN
                            -- Inserir uma nova transferência
                            g_error := 'INSERT EPIS_PROF_RESP (G3)';
                        
                            xepr                          := NULL;
                            xepr.id_epis_prof_resp        := seq_epis_prof_resp.nextval;
                            xepr.id_episode               := i_epis_pat(i);
                            xepr.dt_request_tstz          := g_sysdate_tstz;
                            xepr.id_prof_req              := i_prof.id;
                            xepr.id_prof_to               := iif(l_prof_2(i) = -1, NULL, l_prof_2(i));
                            xepr.id_prof_comp             := l_prof.id;
                            xepr.id_prof_prev             := l_id_current_prof_resp; -- Antigo responsavél pelo paciente ;
                            xepr.id_speciality            := NULL;
                            xepr.id_movement              := l_movement;
                            xepr.notes_clob               := i_notes(i);
                            xepr.dt_comp_tstz             := g_sysdate_tstz;
                            xepr.flg_type                 := i_flg_type;
                            xepr.flg_transfer             := g_transfer_n; -- "Desvio" da responsabilidade;
                            xepr.flg_status               := g_hand_off_f;
                            xepr.flg_transf_type          := g_flg_transf_i;
                            xepr.id_department_dest       := l_new_id_dpt;
                            xepr.id_department_orig       := l_new_id_dpt;
                            xepr.id_clinical_service_dest := l_new_id_cs;
                            xepr.id_clinical_service_orig := l_new_id_cs;
                            xepr.sbar_notes               := i_sbar_note;
                            xepr.id_epis_pn               := i_id_epis_pn;
                            xepr.id_profile_template      := l_profile_template;
                        
                            pk_alertlog.log_debug(g_error);
                            INSERT INTO epis_prof_resp
                                (id_epis_prof_resp,
                                 id_episode,
                                 dt_request_tstz,
                                 id_prof_req,
                                 id_prof_to,
                                 id_prof_comp,
                                 id_prof_prev,
                                 id_speciality,
                                 id_movement,
                                 notes_clob,
                                 dt_comp_tstz,
                                 flg_type,
                                 flg_transfer,
                                 flg_status,
                                 flg_transf_type,
                                 id_department_dest,
                                 id_department_orig,
                                 id_clinical_service_dest,
                                 id_clinical_service_orig,
                                 sbar_notes,
                                 id_epis_pn,
                                 id_profile_template)
                            VALUES
                                (xepr.id_epis_prof_resp,
                                 xepr.id_episode,
                                 xepr.dt_request_tstz,
                                 xepr.id_prof_req,
                                 xepr.id_prof_to,
                                 xepr.id_prof_comp,
                                 xepr.id_prof_prev,
                                 xepr.id_speciality,
                                 xepr.id_movement,
                                 xepr.notes_clob,
                                 xepr.dt_comp_tstz,
                                 xepr.flg_type,
                                 xepr.flg_transfer,
                                 xepr.flg_status,
                                 xepr.flg_transf_type,
                                 xepr.id_department_dest,
                                 xepr.id_department_orig,
                                 xepr.id_clinical_service_dest,
                                 xepr.id_clinical_service_orig,
                                 xepr.sbar_notes,
                                 xepr.id_epis_pn,
                                 xepr.id_profile_template)
                            RETURNING id_epis_prof_resp INTO l_next;
                        
                            pk_hand_off_core.ins_epis_prof_resp_h(xepr);
                        
                        END IF;
                    END IF;
                END IF;
            
                g_error := 'SET PERMISSION TO UPDATE EPIS_INFO/MVIEWS';
                IF (l_handoff_type = g_handoff_multiple AND l_flg_profile = pk_hand_off_core.g_nurse)
                   OR l_handoff_type = g_handoff_normal
                   OR (i_prof.software IN ( --pk_alert_constant.g_soft_outpatient,
                                           pk_alert_constant.g_soft_social,
                                           pk_alert_constant.g_soft_nutritionist,
                                           pk_alert_constant.g_soft_psychologist,
                                           pk_alert_constant.g_soft_primary_care) AND
                   i_flg_resp = pk_hand_off.g_flg_resp_g)
                THEN
                    -- EPIS_INFO should only be updated in normal hand-off mechanism, 
                    -- or for the nurse in the case of the multiple hand-off mechanism.
                    -- or in case of outpatient responsible confirmation popup
                    l_can_update_epis_info := TRUE;
                END IF;
            
                IF l_next IS NOT NULL
                   AND l_handoff_type = g_handoff_multiple
                THEN
                    -- Transfer was accepted by current professional
                    g_error := 'MANAGE MULTI HAND-OFF MECHANISM';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_hand_off_core.set_multi_prof_resp(i_lang                    => i_lang,
                                                                i_prof                    => l_prof,
                                                                i_id_episode              => i_epis_pat(i),
                                                                i_id_prof_resp            => l_prof.id,
                                                                i_flg_profile             => l_flg_profile,
                                                                i_id_epis_prof_resp       => l_next,
                                                                i_flg_status              => g_hand_off_f,
                                                                i_sysdate                 => g_sysdate_tstz,
                                                                i_hand_off_type           => l_handoff_type,
                                                                i_flg_main_responsible    => pk_alert_constant.g_no,
                                                                i_id_speciality           => l_id_speciality,
                                                                i_flg_resp_type           => pk_hand_off_core.g_resp_episode,
                                                                i_priority                => i_priority,
                                                                o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                o_error                   => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                END IF;
            
                IF l_next IS NOT NULL
                   AND l_id_epis_multi_prof_resp IS NOT NULL
                THEN
                    -- Set end date of previous responsability (if it's the first responsible, does nothing).
                    g_error := 'SET END DATE';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_hand_off_core.call_set_end_responsability(i_lang                    => i_lang,
                                                                        i_prof                    => l_prof,
                                                                        i_id_epis_prof_resp       => l_next,
                                                                        i_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                        i_hand_off_type           => l_handoff_type,
                                                                        i_dt_end_transfer         => g_sysdate_tstz,
                                                                        o_error                   => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                END IF;
                l_can_refresh_mview := TRUE;
            
                --Create shift summary note
                pk_alertlog.log_debug('l_config_create_note:' || l_config_create_note ||
                                      ' l_requested_epis_prof_resp:' || l_requested_epis_prof_resp ||
                                      ' l_epis_prof_resp_notes:' || l_epis_prof_resp_notes);
                IF i_prof.software = pk_alert_constant.g_soft_inpatient
                   AND l_config_create_note = g_yes
                   AND l_requested_epis_prof_resp IS NOT NULL
                   AND l_epis_prof_resp_notes IS NOT NULL
                THEN
                    l_sp_id_prof  := profissional(l_id_prof_req, i_prof.institution, i_prof.software);
                    l_pn_datetime := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                 i_date => g_sysdate_tstz,
                                                                 i_inst => i_prof.institution,
                                                                 i_soft => i_prof.software);
                
                    pk_alertlog.log_debug('set_pn_free_text l_sp_id_prof:' || l_sp_id_prof.id || 'EPIS_' ||
                                          i_epis_pat(i) || ' l_prof_cat:' || l_prof_cat);
                    IF NOT pk_prog_notes_core.set_pn_free_text(i_lang       => i_lang,
                                                               i_prof       => l_sp_id_prof,
                                                               i_episode    => i_epis_pat(i),
                                                               i_dt_pn_date => table_varchar(pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                         i_date => g_sysdate_tstz,
                                                                                                                         i_prof => i_prof),
                                                                                             NULL),
                                                               i_note_type  => CASE l_prof_cat
                                                                                   WHEN pk_alert_constant.g_cat_type_nurse THEN
                                                                                    pk_prog_notes_constants.g_note_type_shif_summary_51
                                                                                   WHEN pk_alert_constant.g_cat_type_doc THEN
                                                                                    pk_prog_notes_constants.g_note_type_shif_summary_52
                                                                               END,
                                                               i_pn_note    => table_clob(to_clob(l_pn_datetime),
                                                                                          to_clob(l_epis_prof_resp_notes)),
                                                               o_id_epis_pn => l_id_epis_pn,
                                                               o_error      => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                END IF;
            
            ELSIF i_flg_resp = g_flg_resp_h
                  AND l_epis_flg_status = g_epis_active
            -------------------------------------------------------------------------------------------------------
            -- (B) Hand-off request in external "hand-off" button / Create responsability through patient admission 
            -------------------------------------------------------------------------------------------------------
            THEN
            
                IF i_prof_to IS NULL
                   OR i_prof_to.count = 0
                   OR (i_prof_to.count = 1 AND i_prof_to(1) = -1)
                THEN
                    --transferencia por CS ou D
                    --array com casas vazias, ou seja sem ids de profissionais
                    l_prof_to := table_varchar();
                    l_prof_to.extend(i_cs_or_dept.count);
                ELSE
                    --array preenchido transferencia por profissional(ais)
                    l_prof_to := i_prof_to;
                    IF i_cs_or_dept.count != i_prof_to.count
                    THEN
                        g_error := 'INVALID ARRAY SIZE (I_CS_OR_DEPT/I_PROF_TO)';
                        pk_alertlog.log_debug(g_error);
                        RAISE l_invalid_parameter;
                    END IF;
                END IF;
            
                g_error := 'INSERT EPIS_PROF_RESP - LOOP (G4)';
                pk_alertlog.log_debug(g_error);
                <<lup_ins_prof_resp>>
                FOR j IN 1 .. i_cs_or_dept.count
                LOOP
                
                    xepr                   := NULL;
                    xepr.id_epis_prof_resp := seq_epis_prof_resp.nextval;
                    xepr.id_episode        := i_epis_pat(i);
                    xepr.dt_request_tstz   := g_sysdate_tstz;
                    xepr.id_prof_req       := i_prof.id;
                    xepr.id_prof_to        := l_prof_to(j);
                    xepr.id_prof_prev      := l_id_current_prof_resp; -- Antigo responsável pelo paciente;
                
                    IF i_flg_type = g_flg_type_n
                    THEN
                    
                        xepr.id_department_dest := iif(l_handoff_nurse = g_handoff_nurse_department,
                                                       i_cs_or_dept(j),
                                                       NULL);
                    
                    END IF;
                
                    l_value := NULL;
                    CASE i_flg_type
                        WHEN g_flg_type_d THEN
                            l_value := iif(l_handoff_type = g_handoff_normal, i_cs_or_dept(j), NULL);
                        WHEN g_flg_type_n THEN
                            l_value := iif(l_handoff_nurse = g_handoff_nurse_clin_serv, i_cs_or_dept(j), NULL);
                        ELSE
                            l_value := NULL;
                    END CASE;
                
                    xepr.id_clinical_service_dest := l_value;
                    xepr.id_movement              := l_movement;
                    xepr.notes_clob               := i_notes(i);
                    xepr.flg_type                 := i_flg_type;
                    xepr.flg_transfer             := g_transfer_y;
                
                    xepr.flg_status          := iif(l_prof.id = to_number(l_prof_to(j)), g_hand_off_f, g_hand_off_r);
                    xepr.flg_transf_type     := g_flg_transf_i;
                    xepr.sbar_notes          := i_sbar_note;
                    xepr.id_epis_pn          := i_id_epis_pn;
                    xepr.id_profile_template := l_profile_template;
                
                    INSERT INTO epis_prof_resp
                        (id_epis_prof_resp,
                         id_episode,
                         dt_request_tstz,
                         id_prof_req,
                         id_prof_to,
                         id_prof_prev,
                         id_department_dest,
                         id_clinical_service_dest,
                         id_movement,
                         notes_clob,
                         flg_type,
                         flg_transfer,
                         flg_status,
                         flg_transf_type,
                         sbar_notes,
                         id_epis_pn,
                         id_profile_template)
                    VALUES
                        (xepr.id_epis_prof_resp,
                         xepr.id_episode,
                         xepr.dt_request_tstz,
                         xepr.id_prof_req,
                         xepr.id_prof_to,
                         xepr.id_prof_prev,
                         xepr.id_department_dest,
                         xepr.id_clinical_service_dest,
                         xepr.id_movement,
                         xepr.notes_clob,
                         xepr.flg_type,
                         xepr.flg_transfer,
                         xepr.flg_status,
                         xepr.flg_transf_type,
                         xepr.sbar_notes,
                         xepr.id_epis_pn,
                         xepr.id_profile_template)
                    RETURNING id_epis_prof_resp INTO l_next;
                
                    pk_hand_off_core.ins_epis_prof_resp_h(xepr);
                
                    l_ids := l_ids MULTISET UNION table_number(l_next);
                
                END LOOP lup_ins_prof_resp;
            
                -- Episode is Active or Pending? Set hand-off alert and manage multi hand-off.
                IF l_epis_flg_status IN
                   (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)
                THEN
                    FOR j IN l_ids.first .. l_ids.last
                    LOOP
                        IF l_prof.id <> nvl(to_number(l_prof_to(j)), -1)
                        THEN
                            g_error := 'SET CLINICAL SERVICE FOR HAND-OFF ALERT';
                            pk_alertlog.log_debug(g_error);
                            CASE i_flg_type
                                WHEN g_flg_type_d THEN
                                    -- Physician "multiple" hand-off relies on speciality rather than the clinical service.
                                    l_id_clinical_service := CASE l_handoff_type
                                                                 WHEN g_handoff_normal THEN
                                                                  i_cs_or_dept(j)
                                                                 ELSE
                                                                  NULL
                                                             END;
                                WHEN g_flg_type_n THEN
                                    CASE l_handoff_nurse
                                        WHEN g_handoff_nurse_clin_serv THEN
                                            l_id_clinical_service := i_cs_or_dept(j);
                                        ELSE
                                            l_id_clinical_service := NULL;
                                    END CASE;
                                ELSE
                                    l_id_clinical_service := NULL;
                            END CASE;
                        
                            g_error := 'CALL INSERT_SYS_ALERT_EVENT';
                            pk_alertlog.log_debug(g_error);
                            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                                    i_prof                => l_prof,
                                                                    i_sys_alert           => 32,
                                                                    i_id_episode          => i_epis_pat(i),
                                                                    i_id_record           => l_ids(j),
                                                                    i_dt_record           => g_sysdate_tstz,
                                                                    i_id_professional     => l_prof_to(j),
                                                                    i_id_room             => NULL,
                                                                    i_id_clinical_service => l_id_clinical_service,
                                                                    i_flg_type_dest       => NULL,
                                                                    i_replace1            => NULL,
                                                                    i_replace2            => l_prof_name,
                                                                    o_error               => o_error)
                            THEN
                                RAISE l_internal_error;
                            END IF;
                        
                            g_error := 'MANAGE MULTI HAND-OFF MECHANISM - (' || j || ')';
                            pk_alertlog.log_debug(g_error);
                            IF NOT pk_hand_off_core.set_multi_prof_resp(i_lang                    => i_lang,
                                                                        i_prof                    => l_prof,
                                                                        i_id_episode              => i_epis_pat(i),
                                                                        i_id_prof_resp            => l_prof_to(j),
                                                                        i_flg_profile             => l_flg_profile,
                                                                        i_id_epis_prof_resp       => l_ids(j),
                                                                        i_flg_status              => g_hand_off_r, -- Transfer requested
                                                                        i_sysdate                 => g_sysdate_tstz,
                                                                        i_hand_off_type           => l_handoff_type,
                                                                        i_id_speciality           => l_id_speciality,
                                                                        i_flg_resp_type           => pk_hand_off_core.g_resp_episode,
                                                                        o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                        o_error                   => o_error)
                            THEN
                                RAISE l_internal_error;
                            END IF;
                        
                            -- ONE STEP PROCESS -------------------------------
                            -- When a request is made to a specific specialist,
                            -- the request should be automatically accepted.
                            IF l_handoff_type = g_handoff_multiple
                               AND l_flg_profile = pk_hand_off_core.g_specialist
                               AND l_prof_to(j) IS NOT NULL
                            THEN
                                g_error := 'CALL TO SET_EPIS_PROF_RESP';
                                pk_alertlog.log_debug(g_error);
                                IF NOT call_set_epis_prof_resp(i_lang => i_lang,
                                                               -- "Simulate" the acceptance by the specialist
                                                               i_prof           => profissional(l_prof_to(j),
                                                                                                i_prof.institution,
                                                                                                i_prof.software),
                                                               i_tot_epis       => table_number(0),
                                                               i_epis_prof_resp => table_varchar(l_ids(j)),
                                                               -- Automatically finalize (accept) the request
                                                               i_flg_status => g_hand_off_f,
                                                               i_flg_type   => i_flg_type,
                                                               -- This is used for cancellation notes, so send as NULL!
                                                               i_notes            => NULL,
                                                               i_sysdate          => g_sysdate_tstz,
                                                               i_hand_off_type    => l_handoff_type,
                                                               i_one_step_process => 'Y',
                                                               i_id_cancel_reason => NULL,
                                                               o_refresh_mview    => l_can_refresh_mview_str,
                                                               o_error            => o_error)
                                THEN
                                    RAISE l_internal_error;
                                END IF;
                            
                                IF l_can_refresh_mview_str = 'Y'
                                THEN
                                    l_can_refresh_mview := TRUE;
                                END IF;
                            END IF;
                        
                        ELSIF l_prof.id = nvl(to_number(l_prof_to(j)), -1)
                              AND l_handoff_type = pk_hand_off.g_handoff_normal
                        THEN
                            g_error := 'GET CURRENT STATUS';
                            pk_alertlog.log_debug(g_error);
                            SELECT epr.flg_status
                              INTO l_new_flg_status
                              FROM epis_prof_resp epr
                             WHERE epr.id_epis_prof_resp = l_ids(j);
                        
                            -- If professional making the request is also the destination professional, update EPIS_INFO data.
                            IF l_new_flg_status = g_hand_off_f
                            THEN
                                l_can_update_epis_info := TRUE;
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            
            END IF;
        
            -- Finally, update EPIS_INFO with the responsible professional(s)
            IF l_can_update_epis_info
            THEN
                g_error := 'UPDATE EPIS_INFO - RESPONSIBLE PROFS.';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.call_set_epis_info_resp_all(i_lang                => i_lang,
                                                                    i_prof                => l_prof,
                                                                    i_id_episode          => i_epis_pat(i),
                                                                    i_id_professional     => CASE i_flg_type
                                                                                                 WHEN g_flg_type_d THEN
                                                                                                  l_prof_2(i)
                                                                                                 ELSE
                                                                                                  NULL
                                                                                             END,
                                                                    i_id_professional_nin => TRUE, -- Ignore NULL values, i.e. do NOT update if NULL value is found.
                                                                    i_prof_cat            => g_flg_type_d,
                                                                    i_id_prof_nurse       => CASE i_flg_type
                                                                                                 WHEN g_flg_type_n THEN
                                                                                                  l_prof.id
                                                                                                 ELSE
                                                                                                  NULL
                                                                                             END,
                                                                    i_id_prof_nurse_nin   => TRUE,
                                                                    i_flg_resp_type       => pk_hand_off_core.g_resp_episode, -- This function is ALWAYS used only for episode responsability
                                                                    o_error               => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                -- Set as FALSE for the next patient
                l_can_update_epis_info := FALSE;
            END IF;
        
        END LOOP;
    
        g_error := 'UPDATE MVIEW';
        IF l_can_refresh_mview
        THEN
            pk_episode.update_mv_episodes();
        END IF;
    
        g_error := '';
        IF l_ids IS NOT NULL
           AND l_ids.count > 0
        THEN
            o_epis_prof_resp := l_ids;
        ELSIF l_next IS NOT NULL
        THEN
            o_epis_prof_resp := table_number(l_next);
        ELSE
            o_epis_prof_resp := table_number(NULL);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_dcs_defined THEN
        
                pk_utils.undo_changes;
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M080');
            o_msg_body  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_M085');
            RETURN TRUE;
        
        WHEN l_invalid_parameter THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM_ERROR',
                                              'INVALID PARAMETER FOUND',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN l_invalid_config THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM_ERROR',
                                              'INVALID CONFIGURATION',
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_epis_prof_resp_int;
    --
    /**********************************************************************************************
    * Registar os pedidos de transferência de responsabilidade
    *  A transferência de responsabilidade poder?ser efectuada sobre vários episódios.
    *  Ser?possivél efectuar a transf. de responsabilidade para um ou vários profissionais.
    *  O mesmo poder?acontecer com as especialidades, uma ou várias especialidades.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array dos profissionais a quem foi pedido a transferência de responsabilidade   
    * @param i_tot_epis               Array com o número total de episódios para os quais foi pedido transferência de responsabilidade
    * @param i_epis_pat               Array com os IDs episódios / pacientes para os quais foi pedido transferência de responsabilidade
    * @param i_cs_or_dept             Array dos serviços clinicos ou departamentos onde foi efectuado o pedido a transferência de responsabilidade.        
    * @param i_notes                  Array de Notas
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_flg_resp               Pode assumir 2 valores: G -  Assumir responsabilidade do paciente nas grelhas de entrada
                                                              H -  Hand- Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Current date
    * @param i_id_speciality          Responsability request speciality
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/08/11
    *
    * @alter                          Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/02
    **********************************************************************************************/
    FUNCTION create_epis_prof_resp
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_to               IN table_varchar,
        i_tot_epis              IN table_number,
        i_epis_pat              IN table_number,
        i_cs_or_dept            IN table_number,
        i_notes                 IN table_varchar,
        i_flg_type              IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp              IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality         IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        i_priority              IN NUMBER DEFAULT NULL,
        i_sbar_note             IN CLOB DEFAULT NULL,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg_body              OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_EPIS_PROF_RESP';
        --
        l_epis_prof_resp table_number;
    
    BEGIN
        g_error := 'CALL CREATE_EPIS_PROF_RESP_INT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT create_epis_prof_resp_int(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_prof_to               => i_prof_to,
                                         i_tot_epis              => i_tot_epis,
                                         i_epis_pat              => i_epis_pat,
                                         i_cs_or_dept            => i_cs_or_dept,
                                         i_notes                 => i_notes,
                                         i_flg_type              => i_flg_type,
                                         i_flg_resp              => i_flg_resp,
                                         i_flg_profile           => i_flg_profile,
                                         i_sysdate               => i_sysdate,
                                         i_id_speciality         => i_id_speciality,
                                         i_flg_assign_supervisor => i_flg_assign_supervisor,
                                         i_priority              => i_priority,
                                         i_sbar_note             => i_sbar_note,
                                         i_id_epis_pn            => i_id_epis_pn,
                                         o_flg_show              => o_flg_show,
                                         o_msg_title             => o_msg_title,
                                         o_msg_body              => o_msg_body,
                                         o_epis_prof_resp        => l_epis_prof_resp,
                                         o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END create_epis_prof_resp;
    --
    /**********************************************************************************************
    * Registar os pedidos de transferência de responsabilidade
    *  A transferência de responsabilidade poder?ser efectuada sobre vários episódios.
    *  Ser?possivél efectuar a transf. de responsabilidade para um ou vários profissionais.
    *  O mesmo poder?acontecer com as especialidades, uma ou várias especialidades.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array dos profissionais a quem foi pedido a transferência de responsabilidade   
    * @param i_tot_epis               Array com o número total de episódios para os quais foi pedido transferência de responsabilidade
    * @param i_epis_pat               Array com os IDs episódios / pacientes para os quais foi pedido transferência de responsabilidade
    * @param i_cs_or_dept             Array dos serviços clinicos ou departamentos onde foi efectuado o pedido a transferência de responsabilidade.        
    * @param i_notes                  Array de Notas
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_flg_resp               Pode assumir 2 valores: G -  Assumir responsabilidade do paciente nas grelhas de entrada
                                                              H -  Hand- Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Current date
    * @param i_id_speciality          Responsability request speciality
    * @param o_epis_prof_resp         List of created id's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/08/11
    *
    * @alter                          Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/02
    **********************************************************************************************/
    FUNCTION create_epis_prof_resp_api
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_to        IN table_varchar,
        i_tot_epis       IN table_number,
        i_epis_pat       IN table_number,
        i_cs_or_dept     IN table_number,
        i_notes          IN table_varchar,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp       IN VARCHAR2,
        i_flg_profile    IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality  IN epis_multi_prof_resp.id_speciality%TYPE,
        i_sbar_note      IN CLOB DEFAULT NULL,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_epis_prof_resp OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_EPIS_PROF_RESP_API';
        l_flg_show  VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_msg_body  VARCHAR2(4000);
    
    BEGIN
        g_error := 'CALL CREATE_EPIS_PROF_RESP_INT';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT create_epis_prof_resp_int(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_prof_to        => i_prof_to,
                                         i_tot_epis       => i_tot_epis,
                                         i_epis_pat       => i_epis_pat,
                                         i_cs_or_dept     => i_cs_or_dept,
                                         i_notes          => i_notes,
                                         i_flg_type       => i_flg_type,
                                         i_flg_resp       => i_flg_resp,
                                         i_flg_profile    => i_flg_profile,
                                         i_sysdate        => i_sysdate,
                                         i_id_speciality  => i_id_speciality,
                                         i_sbar_note      => i_sbar_note,
                                         i_id_epis_pn     => i_id_epis_pn,
                                         o_flg_show       => l_flg_show,
                                         o_msg_title      => l_msg_title,
                                         o_msg_body       => l_msg_body,
                                         o_epis_prof_resp => o_epis_prof_resp,
                                         o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END create_epis_prof_resp_api;
    --
    /**********************************************************************************************
    * Listar os pedidos de transferência de responsabilidade para o profissional
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_epis_presp             Todos os pedidos de transf. de responsabilidade efectuados ao profissional
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/08/11
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_epis_presp OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_EPIS_PROF_RESP';
        --
        l_const_cs                CONSTANT VARCHAR2(2) := 'CS';
        l_const_d                 CONSTANT VARCHAR2(1) := 'D';
        l_cfg_handoff_nurse       CONSTANT sys_config.id_sys_config%TYPE := 'HANDOFF_NURSE';
        l_code_msg_edis_grid_t025 CONSTANT sys_message.code_message%TYPE := 'EDIS_GRID_T025';
        l_sys_dom_pt_flg_profile  CONSTANT sys_domain.code_domain%TYPE := 'PROFILE_TEMPLATE.FLG_PROFILE';
        l_code_department         CONSTANT department.code_department%TYPE := 'DEPARTMENT.CODE_DEPARTMENT.';
        l_diag_sep                CONSTANT VARCHAR2(3) := ' / ';
        l_exists                  CONSTANT VARCHAR2(1) := '0';
    
        l_transfer_cs CONSTANT VARCHAR2(2 CHAR) := l_const_cs;
        l_transfer_d  CONSTANT VARCHAR2(1 CHAR) := l_const_d;
        l_transfer_s  CONSTANT VARCHAR2(1 CHAR) := 'S';
    
        --
        l_handoff_nurse      sys_config.value%TYPE;
        l_prof_cat           category.flg_type%TYPE;
        l_msg_edis_grid_t025 sys_message.desc_message%TYPE;
        l_cs_or_dept         VARCHAR2(2);
        l_hand_off_type      sys_config.value%TYPE;
        l_flg_profile        profile_template.flg_profile%TYPE;
        l_id_speciality      epis_multi_prof_resp.id_speciality%TYPE;
        --
        l_sbar_title sys_message.desc_message%TYPE;
        --
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'GET CONFIGURATIONS AND MSG''s';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_handoff_nurse      := pk_sysconfig.get_config(l_cfg_handoff_nurse, i_prof.institution, i_prof.software);
        l_msg_edis_grid_t025 := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_edis_grid_t025);
        --
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_hand_off_type);
        --
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        --
        g_error := 'SET CS OR DEPT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_cs_or_dept := CASE l_prof_cat
                            WHEN g_prof_cat_doc THEN
                             l_const_cs
                            WHEN g_prof_cat_nrs THEN
                             (CASE l_handoff_nurse
                                 WHEN g_handoff_nurse_clin_serv THEN
                                  l_const_cs
                                 WHEN g_handoff_nurse_department THEN
                                  l_const_d
                                 ELSE
                                  NULL
                             END)
                            ELSE
                             NULL
                        END;
        --    
        g_error := 'GET SPECIALITY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_id_speciality := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof);
        --
        l_sbar_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'TITLE_SBAR_NOTE');
        --
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the type of profile. Show only the requests made to my profile.
            g_error := 'GET FLG_PROFILE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => NULL,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            g_error := 'SET FLG_PROFILE TO NULL (Normal Hand Off)';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            l_flg_profile := NULL;
        END IF;
        --
        IF i_prof.software IN (pk_alert_constant.g_soft_edis,
                               pk_alert_constant.g_soft_ubu,
                               pk_alert_constant.g_soft_outpatient,
                               pk_alert_constant.g_soft_oris)
        THEN
            g_error := 'OPEN O_EPIS_PRESP E/U';
            OPEN o_epis_presp FOR
                SELECT epis.triage_acuity acuity,
                       epis.triage_color_text color_text,
                       epis.id_episode,
                       pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz_e, g_date_mask) dt_begin,
                       (SELECT nvl(nvl(ro.desc_room_abbreviation,
                                       pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                                   nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)))
                          FROM room ro
                         WHERE ro.id_room = epis.id_room) desc_room,
                       epis.id_patient,
                       pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                       decode(pk_patphoto.check_blob(epis.id_patient),
                              pk_alert_constant.g_no,
                              NULL,
                              pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)) patphoto,
                       (SELECT pk_patient.get_gender(i_lang, gender)
                          FROM patient
                         WHERE id_patient = epis.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof.institution, i_prof.software) pat_age,
                       pk_edis_grid.get_complaint_grid(i_lang, i_prof.institution, i_prof.software, epis.id_episode) desc_epis_anamnesis,
                       epr.flg_status,
                       epr.flg_transf_type,
                       epr.id_epis_prof_resp,
                       epr.id_prof_to,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to) name_prof_to,
                       epr.notes_clob notes_hand_off,
                       l_msg_edis_grid_t025 diag_title,
                       l_sbar_title sbar_title,
                       CAST(MULTISET (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                               i_id_diagnosis        => d.id_diagnosis,
                                                               i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                               i_code                => d.code_icd,
                                                               i_flg_other           => d.flg_other,
                                                               i_flg_std_diag        => pk_alert_constant.g_yes,
                                                               i_epis_diag           => ed.id_epis_diagnosis) ||
                                    l_diag_sep desc_diagnosis
                               FROM epis_diagnosis ed
                               JOIN diagnosis d
                                 ON d.id_diagnosis = ed.id_diagnosis
                              WHERE ed.id_episode = epis.id_episode
                                AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                AND ed.flg_type = g_diag_flg_type) AS table_varchar) diags,
                       -- Multiple hand-off support
                       empr.flg_profile flg_profile,
                       decode(l_hand_off_type,
                              g_handoff_multiple,
                              pk_sysdomain.get_domain(l_sys_dom_pt_flg_profile, empr.flg_profile, i_lang),
                              NULL) flg_profile_desc,
                       empr.flg_resp_type flg_resp_type,
                       pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                             i_prof,
                                                             epr.id_clinical_service_dest,
                                                             epr.id_department_dest,
                                                             empr.id_speciality) desc_spec,
                       -- Used by UX to apply the correct labels in the acceptance/rejection message boxes
                       coalesce(decode(epr.id_clinical_service_dest, NULL, NULL, l_transfer_cs),
                                decode(epr.id_department_dest, NULL, NULL, l_transfer_d),
                                decode(empr.id_speciality, NULL, NULL, l_transfer_s)) flg_spec_type,
                       CASE
                            WHEN epis.id_software IN (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_ubu) THEN
                             pk_edis_grid.get_complaint_grid(i_lang, i_prof, epis.id_episode)
                            WHEN epis.id_software = pk_alert_constant.g_soft_oris THEN
                             pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof)
                            WHEN epis.id_software = pk_alert_constant.g_soft_outpatient THEN
                             pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                         i_prof,
                                                                                                         epis.id_episode,
                                                                                                         NULL),
                                                              4000)
                            ELSE
                             NULL
                        END notes,
                       pk_date_utils.dt_chr(i_lang, p.dt_birth, i_prof) pat_dt_birth
                  FROM v_episode_act epis
                  JOIN patient p
                    ON p.id_patient = epis.id_patient
                  JOIN epis_prof_resp epr
                    ON epr.id_episode = epis.id_episode
                -- Jos?Brito 27/10/2009 ALERT-39320 Support for multiple hand-off mechanism  
                  LEFT JOIN epis_multi_prof_resp empr
                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                   AND empr.flg_profile = l_flg_profile -- Requests to "my" profile...
                   AND (empr.id_speciality = l_id_speciality OR
                       empr.id_speciality IS NULL AND l_flg_profile = pk_hand_off_core.g_nurse) -- ... and to my speciality
                 WHERE epis.id_software = i_prof.software
                   AND epis.id_institution = i_prof.institution
                   AND epis.flg_ehr IN (g_flg_ehr_normal, g_flg_ehr_schedule)
                   AND epr.flg_status = g_hand_off_r
                   AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a, g_flg_transf_o)
                      -- Jos?Brito 18/11/2008 ALERT-9943 Não mostrar as requisições emitidas pelo profissional actual, ...
                      -- ... que podiam aparecer no caso de transferências requisitadas para qualquer profissional.
                   AND i_prof.id NOT IN (epr.id_prof_req,
                                         get_prof_resp(i_lang,
                                                       i_prof,
                                                       epr.id_episode,
                                                       NULL,
                                                       l_hand_off_type,
                                                       empr.flg_profile,
                                                       empr.id_speciality))
                      --transf pessoal
                   AND (epr.id_prof_to = i_prof.id OR EXISTS
                        (SELECT l_exists
                         --transf CS/D         
                           FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                          WHERE pdcs.id_professional = i_prof.id
                            AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                            AND decode(l_cs_or_dept,
                                       l_const_cs,
                                       -- Jos?Brito 27/10/2009 ALERT-39320 Comparison was being made with ID_DEP_CLIN_SERV
                                       (SELECT d.id_clinical_service
                                          FROM dep_clin_serv d
                                         WHERE d.id_dep_clin_serv = dcs.id_dep_clin_serv),
                                       l_const_d,
                                       dcs.id_department) = decode(l_cs_or_dept,
                                                                   l_const_cs,
                                                                   epr.id_clinical_service_dest,
                                                                   l_const_d,
                                                                   epr.id_department_dest)
                            AND epr.id_prof_to IS NULL
                            AND pdcs.id_institution = i_prof.institution) OR EXISTS
                        (SELECT l_exists
                         --trans especialidade
                           FROM professional p, speciality s
                          WHERE p.id_professional = i_prof.id
                            AND p.id_speciality = s.id_speciality
                            AND (l_hand_off_type = pk_hand_off.g_handoff_multiple AND
                                s.id_speciality = empr.id_speciality OR s.id_speciality = epr.id_speciality)
                            AND epr.id_prof_to IS NULL))
                 ORDER BY epis.dt_begin_tstz_e;
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_inpatient
        THEN
            g_error := 'OPEN O_EPIS_PRESP INP';
            OPEN o_epis_presp FOR
                SELECT g_no_triage acuity,
                       g_no_triage_color_text color_text,
                       epis.id_episode,
                       pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz_e, g_date_mask) dt_begin,
                       pk_translation.get_translation(i_lang, l_code_department || dcs.id_department) desc_room,
                       pat.id_patient,
                       pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL) patphoto,
                       pk_patient.get_gender(i_lang, pat.gender) gender,
                       pk_patient.get_pat_age(i_lang,
                                              pat.dt_birth,
                                              pat.dt_deceased,
                                              pat.age,
                                              i_prof.institution,
                                              i_prof.software) pat_age,
                       pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_epis_anamnesis,
                       epr.flg_status,
                       epr.flg_transf_type,
                       epr.id_epis_prof_resp,
                       epr.id_prof_to,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to) name_prof_to,
                       epr.notes_clob notes_hand_off,
                       l_msg_edis_grid_t025 diag_title,
                       l_sbar_title sbar_title,
                       CAST(MULTISET (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                               i_id_diagnosis        => d.id_diagnosis,
                                                               i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                               i_code                => d.code_icd,
                                                               i_flg_other           => d.flg_other,
                                                               i_flg_std_diag        => pk_alert_constant.g_yes,
                                                               i_epis_diag           => ed.id_epis_diagnosis) ||
                                    l_diag_sep desc_diagnosis
                               FROM epis_diagnosis ed
                               JOIN diagnosis d
                                 ON d.id_diagnosis = ed.id_diagnosis
                              WHERE ed.id_episode = epis.id_episode
                                AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                AND ed.flg_type = g_diag_flg_type) AS table_varchar) diags,
                       -- Multiple hand-off support
                       empr.flg_profile flg_profile,
                       decode(l_hand_off_type,
                              g_handoff_multiple,
                              pk_sysdomain.get_domain(l_sys_dom_pt_flg_profile, empr.flg_profile, i_lang),
                              NULL) flg_profile_desc,
                       empr.flg_resp_type flg_resp_type,
                       coalesce(decode(epr.id_clinical_service_dest,
                                       NULL,
                                       NULL,
                                       (SELECT pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                                          FROM clinical_service cs1
                                         WHERE cs1.id_clinical_service = epr.id_clinical_service_dest)),
                                decode(epr.id_department_dest,
                                       NULL,
                                       NULL,
                                       (SELECT pk_translation.get_translation(i_lang, d1.code_department)
                                          FROM department d1
                                         WHERE d1.id_department = epr.id_department_dest)),
                                decode(empr.id_speciality,
                                       NULL,
                                       NULL,
                                       (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                          FROM speciality s
                                         WHERE s.id_speciality = empr.id_speciality))) desc_spec,
                       -- Used by UX to apply the correct labels in the acceptance/rejection message boxes
                       coalesce(decode(epr.id_clinical_service_dest, NULL, NULL, l_transfer_cs),
                                decode(epr.id_department_dest, NULL, NULL, l_transfer_d),
                                decode(empr.id_speciality, NULL, NULL, l_transfer_s)) flg_spec_type,
                       CASE
                            WHEN epis.id_software = pk_alert_constant.g_soft_inpatient THEN
                             decode(ea.flg_type,
                                    g_flg_anamnesis_c,
                                    pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis),
                                    NULL)
                            ELSE
                             NULL
                        END notes,
                       pk_date_utils.dt_chr(i_lang, p.dt_birth, i_prof) pat_dt_birth
                  FROM v_episode_act epis
                  JOIN patient p
                    ON p.id_patient = epis.id_patient
                  JOIN patient pat
                    ON pat.id_patient = epis.id_patient
                  JOIN epis_prof_resp epr
                    ON epr.id_episode = epis.id_episode
                  JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = epis.id_dep_clin_serv
                  LEFT JOIN epis_anamnesis ea
                    ON ea.id_episode = epis.id_episode
                -- Jos?Brito 18/11/2008 ALERT-9943 Não mostrar as requisições emitidas pelo profissional actual, ...
                -- ... que podiam aparecer no caso de transferências requisitadas para qualquer profissional.
                  LEFT JOIN epis_multi_prof_resp empr
                    ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                   AND empr.flg_profile = l_flg_profile -- Requests to "my" profile...
                   AND (empr.id_speciality = l_id_speciality OR
                       empr.id_speciality IS NULL AND l_flg_profile = pk_hand_off_core.g_nurse) -- ... and to my speciality
                 WHERE epis.id_software = i_prof.software
                   AND epis.id_institution = i_prof.institution
                      --LMAIA 09-04-2009 Schedule episodes should have same permissions that normal episodes have
                   AND epis.flg_ehr IN (g_flg_ehr_normal, g_flg_ehr_schedule)
                   AND epr.flg_status = g_hand_off_r
                   AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a, g_flg_transf_o)
                   AND i_prof.id NOT IN (epr.id_prof_req,
                                         get_prof_resp(i_lang,
                                                       i_prof,
                                                       epr.id_episode,
                                                       NULL,
                                                       l_hand_off_type,
                                                       empr.flg_profile,
                                                       l_id_speciality))
                   AND (ea.dt_epis_anamnesis_tstz =
                       (SELECT MAX(ea2.dt_epis_anamnesis_tstz)
                           FROM epis_anamnesis ea2
                          WHERE ea2.id_episode = ea.id_episode
                            AND ea2.flg_type = g_flg_anamnesis_c) OR ea.dt_epis_anamnesis_tstz IS NULL OR
                       (ea.flg_type != g_flg_anamnesis_c AND NOT EXISTS
                        (SELECT l_exists
                            FROM epis_anamnesis ea3
                           WHERE ea3.id_episode = ea.id_episode
                             AND ea3.flg_type = g_flg_anamnesis_c)))
                      --ALERT-287243 - Inpatient patient grid: Transfer button - Hand off menu: the screen is not displaying information
                   AND (epr.id_prof_to = i_prof.id OR EXISTS
                        (SELECT l_exists
                         --transf CS/D         
                           FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                          WHERE pdcs.id_professional = i_prof.id
                            AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                            AND decode(l_cs_or_dept,
                                       l_const_cs,
                                       -- Jos?Brito 27/10/2009 ALERT-39320 Comparison was being made with ID_DEP_CLIN_SERV
                                       (SELECT d.id_clinical_service
                                          FROM dep_clin_serv d
                                         WHERE d.id_dep_clin_serv = dcs.id_dep_clin_serv),
                                       l_const_d,
                                       dcs.id_department) = decode(l_cs_or_dept,
                                                                   l_const_cs,
                                                                   epr.id_clinical_service_dest,
                                                                   l_const_d,
                                                                   epr.id_department_dest)
                            AND epr.id_prof_to IS NULL
                            AND pdcs.id_institution = i_prof.institution) OR EXISTS
                        (SELECT l_exists
                         --trans especialidade
                           FROM professional p, speciality s
                          WHERE p.id_professional = i_prof.id
                            AND p.id_speciality = s.id_speciality
                            AND (l_hand_off_type = pk_hand_off.g_handoff_multiple AND
                                s.id_speciality = empr.id_speciality OR s.id_speciality = epr.id_speciality)
                            AND epr.id_prof_to IS NULL))
                 ORDER BY epis.dt_begin_tstz_e;
        ELSE
            g_error := 'SOFTWARE NOT SUPPORTED';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_epis_presp);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_epis_presp);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_prof_resp;

    FUNCTION get_epis_nursing_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_icnp_diag OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_icnp_diag      pk_types.cursor_type;
        l_desc_icnp_diag CLOB;
        l_status         VARCHAR2(200 CHAR);
        l_func_name      VARCHAR2(200 CHAR) := 'GET_EPIS_NURSING_DIAG';
    BEGIN
        IF NOT pk_icnp.get_icnp_by_status(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_episode   => i_episode,
                                          o_icnp_diag => l_icnp_diag,
                                          o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_icnp_diag';
        FETCH l_icnp_diag
            INTO l_desc_icnp_diag, l_status;
    
        CLOSE l_icnp_diag;
    
        g_error := 'OPEN o_icnp_diag';
        OPEN o_icnp_diag FOR
            SELECT nvl2(l_desc_icnp_diag,
                        upper(pk_message.get_message(i_lang => i_lang, i_code_mess => 'EDIS_HAND_OFF_T068') || ':'),
                        '') title,
                   l_desc_icnp_diag VALUE
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_icnp_diag);
            RETURN FALSE;
        
    END;
    /*
    get_sbar_note(i_lang, i_prof, i_episode, o_sbar_note, o_error)
    */
    FUNCTION get_sbar_note
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_sbar_note         OUT CLOB,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        SELECT epr.sbar_notes
          INTO o_sbar_note
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_sbar_note := NULL;
            RETURN FALSE;
        
    END get_sbar_note;
    --
    /**********************************************************************************************
    * Listagem de todas os pacientes sobre os quais o profissional ?responsavél (da urgência)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_type               type of hand-off: (D) Physician (N) Nurse
    * @param i_flg_show_only_resp     Show only episodes whose current professional is responsible?
    * @param o_patient                Todos os pacientes e sua informação adicional
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/16
    *                        
    * @changed by                     Alexandre Santos
    * @version                        2.6.0.3.4 
    * @since                          2010/11/26
    **********************************************************************************************/
    FUNCTION get_grid_hand_off_cab
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN VARCHAR2,
        i_flg_show_only_resp IN VARCHAR2,
        o_patient            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_GRID_HAND_OFF_CAB';
        l_prof_cat      category.flg_type%TYPE;
        l_hand_off_type sys_config.value%TYPE;
        l_flg_profile   profile_template.flg_profile%TYPE;
        l_sbar_title    sys_message.desc_message%TYPE;
        l_internal_error EXCEPTION;
    BEGIN
        g_error         := 'GET Configurations';
        g_software_inp  := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof);
        g_software_edis := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof);
        g_software_ubu  := pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error    := 'GET PROF CAT';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        l_sbar_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'TITLE_SBAR_NOTE');
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
           AND i_flg_type = l_prof_cat
        THEN
            -- Get the type of profile. Show only the requests made to my profile.
            g_error := 'GET FLG_PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => NULL,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        ELSE
            l_flg_profile := NULL;
        END IF;
    
        IF i_prof.software != g_software_inp
        THEN
            --
            g_error := 'OPEN O_PATIENT E/U ' || i_episode;
            OPEN o_patient FOR
                SELECT epis.triage_acuity acuity,
                       epis.triage_color_text color_text,
                       epis.id_episode,
                       pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz_e, g_date_mask) dt_begin,
                       nvl(nvl(r.desc_room_abbreviation,
                               pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION.' || epis.id_room)),
                           nvl(r.desc_room, pk_translation.get_translation_dtchk(i_lang, r.code_room))) desc_room,
                       epis.id_patient,
                       pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                       decode(pk_patphoto.check_blob(epis.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)) patphoto,
                       (SELECT pk_patient.get_gender(i_lang, gender)
                          FROM patient
                         WHERE id_patient = epis.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof.institution, i_prof.software) pat_age,
                       pk_edis_grid.get_complaint_grid(i_lang, i_prof.institution, i_prof.software, epis.id_episode) desc_epis_anamnesis,
                       decode(epr.flg_status, 'C', NULL, epr.flg_status) flg_status,
                       epr.flg_transf_type,
                       epr.id_epis_prof_resp,
                       epr.id_prof_req,
                       epr.id_prof_to,
                       decode(epr.id_prof_to,
                              NULL,
                              decode(epr.id_department_dest,
                                     NULL,
                                     pk_translation.get_translation(i_lang,
                                                                    'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                    epr.id_clinical_service_dest) || ' / ' ||
                                     pk_message.get_message(i_lang, 'OPINION_M001'),
                                     pk_translation.get_translation(i_lang,
                                                                    'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                    epr.id_department_dest) || ' / ' ||
                                     pk_message.get_message(i_lang, 'OPINION_M001')),
                              pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to)) name_prof_to,
                       -- Jos?Brito 21/08/2008 Mostrar as notas apenas se estiver no estado "Requisitado" 
                       -- (as restantes aparecem no histórico - a implementar na versão 2.4.4.)
                       decode(epr.flg_status, 'R', epr.notes_clob, NULL) notes_hand_off,
                       pk_message.get_message(i_lang, 'EDIS_GRID_T025') diag_title,
                       l_sbar_title sbar_title,
                       CAST(MULTISET
                            (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                               i_id_diagnosis        => d.id_diagnosis,
                                                               i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                               i_code                => d.code_icd,
                                                               i_flg_other           => d.flg_other,
                                                               i_flg_std_diag        => pk_alert_constant.g_yes,
                                                               i_epis_diag           => ed.id_epis_diagnosis) || ' / ' desc_diagnosis
                               FROM epis_diagnosis ed
                               JOIN diagnosis d
                                 ON d.id_diagnosis = ed.id_diagnosis
                              WHERE ed.id_episode = epis.id_episode
                                AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                AND ed.flg_type = g_diag_flg_type) AS table_varchar) diags,
                       pk_date_utils.dt_chr(i_lang, p.dt_birth, i_prof) pat_dt_birth
                  FROM v_episode_act epis
                  JOIN patient p
                    ON p.id_patient = epis.id_patient
                  LEFT JOIN epis_prof_resp epr
                    ON epr.id_episode = epis.id_episode
                   AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
                  LEFT JOIN room r
                    ON r.id_room = epis.id_room
                 WHERE (i_episode IS NULL OR epis.id_episode = i_episode)
                   AND epis.id_software = i_prof.software
                   AND epis.id_institution = i_prof.institution
                      --LMAIA 09-04-2009 Schedule episodes should have same permissions that normal episodes have
                   AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
                      -- Jos?Brito 19/10/2009 ALERT-39320 Responsible physicians not registered in EPIS_INFO must
                      --                                   have the patient available in the main grid.
                   AND ((i_prof.id IN
                       (SELECT column_value
                            FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                            i_prof,
                                                                            epis.id_episode,
                                                                            l_prof_cat,
                                                                            l_hand_off_type)))
                       -- Jos?Brito 31/08/2009 ALERT-40433
                       -- Added conditions to show the patient summary in the inner hand-off button, in nurse - physician transfers.
                       AND i_episode IS NULL) OR epis.id_episode = i_episode)
                   AND (i_flg_show_only_resp = pk_alert_constant.g_no OR
                       (i_flg_show_only_resp = pk_alert_constant.g_yes AND
                       epr.dt_request_tstz = (SELECT pk_hand_off_core.get_max_dt_request(i_lang,
                                                                                           i_prof,
                                                                                           epis.id_episode,
                                                                                           nvl(i_flg_type, l_prof_cat),
                                                                                           l_flg_profile,
                                                                                           l_hand_off_type)
                                                  FROM dual) OR epr.dt_request_tstz IS NULL))
                -- query to include announced arrivals episodes that haven't arrived yet
                UNION ALL
                SELECT ei.triage_acuity acuity,
                       ei.triage_color_text color_text,
                       epis.id_episode,
                       pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz, g_date_mask) dt_begin,
                       nvl(nvl(r.desc_room_abbreviation,
                               pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION.' || ei.id_room)),
                           nvl(r.desc_room, pk_translation.get_translation_dtchk(i_lang, r.code_room))) desc_room,
                       epis.id_patient,
                       pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                       decode(pk_patphoto.check_blob(epis.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, NULL)) patphoto,
                       (SELECT pk_patient.get_gender(i_lang, gender)
                          FROM patient
                         WHERE id_patient = epis.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof.institution, i_prof.software) pat_age,
                       pk_edis_grid.get_complaint_grid(i_lang, i_prof.institution, i_prof.software, epis.id_episode) desc_epis_anamnesis,
                       decode(epr.flg_status, 'C', NULL, epr.flg_status) flg_status,
                       epr.flg_transf_type,
                       epr.id_epis_prof_resp,
                       epr.id_prof_req,
                       epr.id_prof_to,
                       decode(epr.id_prof_to,
                              NULL,
                              decode(epr.id_department_dest,
                                     NULL,
                                     pk_translation.get_translation(i_lang,
                                                                    'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                    epr.id_clinical_service_dest) || ' / ' ||
                                     pk_message.get_message(i_lang, 'OPINION_M001'),
                                     pk_translation.get_translation(i_lang,
                                                                    'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                    epr.id_department_dest) || ' / ' ||
                                     pk_message.get_message(i_lang, 'OPINION_M001')),
                              pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to)) name_prof_to,
                       -- Jos?Brito 21/08/2008 Mostrar as notas apenas se estiver no estado "Requisitado" 
                       -- (as restantes aparecem no histórico - a implementar na versão 2.4.4.)
                       decode(epr.flg_status, 'R', epr.notes_clob, NULL) notes_hand_off,
                       pk_message.get_message(i_lang, 'EDIS_GRID_T025') diag_title,
                       l_sbar_title sbar_title,
                       CAST(MULTISET
                            (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                               i_id_diagnosis        => d.id_diagnosis,
                                                               i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                               i_code                => d.code_icd,
                                                               i_flg_other           => d.flg_other,
                                                               i_flg_std_diag        => pk_alert_constant.g_yes,
                                                               i_epis_diag           => ed.id_epis_diagnosis) || ' / ' desc_diagnosis
                               FROM epis_diagnosis ed
                               JOIN diagnosis d
                                 ON d.id_diagnosis = ed.id_diagnosis
                              WHERE ed.id_episode = epis.id_episode
                                AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                AND ed.flg_type = g_diag_flg_type) AS table_varchar) diags,
                       pk_date_utils.dt_chr(i_lang, p.dt_birth, i_prof) pat_dt_birth
                  FROM episode epis
                  JOIN patient p
                    ON p.id_patient = epis.id_patient
                  JOIN epis_info ei
                    ON epis.id_episode = ei.id_episode
                  JOIN announced_arrival aa
                    ON aa.id_episode = epis.id_episode
                   AND aa.flg_status != pk_announced_arrival.g_aa_arrival_status_a
                  LEFT JOIN epis_prof_resp epr
                    ON epr.id_episode = epis.id_episode
                   AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
                  LEFT JOIN room r
                    ON r.id_room = ei.id_room
                 WHERE (i_episode IS NULL OR epis.id_episode = i_episode)
                   AND epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
                   AND ei.id_software = i_prof.software
                   AND epis.id_institution = i_prof.institution
                      --LMAIA 09-04-2009 Schedule episodes should have same permissions that normal episodes have
                   AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
                      -- Jos?Brito 19/10/2009 ALERT-39320 Responsible physicians not registered in EPIS_INFO must
                      --                                   have the patient available in the main grid.
                   AND ((i_prof.id IN
                       (SELECT column_value
                            FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                            i_prof,
                                                                            epis.id_episode,
                                                                            l_prof_cat,
                                                                            l_hand_off_type)))
                       -- Jos?Brito 31/08/2009 ALERT-40433
                       -- Added conditions to show the patient summary in the inner hand-off button, in nurse - physician transfers.
                       AND i_episode IS NULL) OR epis.id_episode = i_episode)
                   AND (i_flg_show_only_resp = pk_alert_constant.g_no OR
                       (i_flg_show_only_resp = pk_alert_constant.g_yes AND
                       epr.dt_request_tstz = (SELECT pk_hand_off_core.get_max_dt_request(i_lang,
                                                                                           i_prof,
                                                                                           epis.id_episode,
                                                                                           nvl(i_flg_type, l_prof_cat),
                                                                                           l_flg_profile,
                                                                                           l_hand_off_type)
                                                  FROM dual) OR epr.dt_request_tstz IS NULL))
                 ORDER BY acuity, dt_begin;
            RETURN TRUE;
        
        ELSIF i_prof.software = g_software_inp
        THEN
            g_error := 'OPEN O_PATIENT INP ' || i_episode;
            OPEN o_patient FOR
                SELECT g_no_triage acuity,
                       g_no_triage_color_text color_text,
                       t.id_episode,
                       pk_date_utils.to_char_insttimezone(i_prof, t.dt_begin_tstz_e, g_date_mask) dt_begin,
                       t.id_patient,
                       pk_patient.get_pat_name(i_lang, i_prof, t.id_patient, t.id_episode) name_pat,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, t.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, t.id_patient) pat_nd_icon,
                       decode(pk_patphoto.check_blob(t.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_photo(i_lang, i_prof, t.id_patient, t.id_episode, NULL)) patphoto,
                       (SELECT pk_patient.get_gender(i_lang, gender)
                          FROM patient
                         WHERE id_patient = t.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, t.id_patient, i_prof.institution, i_prof.software) pat_age,
                       decode(t.epr_flg_status, 'C', NULL, 'X', NULL, t.epr_flg_status) flg_status,
                       t.epr_flg_transf_type flg_transf_type,
                       t.epr_id_prof_req id_prof_req,
                       t.epr_id_epis_prof_resp id_epis_prof_resp,
                       t.epr_id_prof_to id_prof_to,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.epr_id_prof_to) name_prof_to,
                       decode(t.epr_flg_status, 'R', t.epr_notes_clob, NULL) notes_hand_off,
                       decode(t.ea_flg_type,
                              g_flg_anamnesis_c,
                              pk_string_utils.clob_to_sqlvarchar2(t.ea_desc_epis_anamnesis),
                              NULL) desc_epis_anamnesis,
                       pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || t.dcs_id_department) desc_room,
                       pk_message.get_message(i_lang, 'EDIS_GRID_T025') diag_title,
                       l_sbar_title sbar_title,
                       CAST(MULTISET
                            (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                               i_id_diagnosis        => d.id_diagnosis,
                                                               i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                               i_code                => d.code_icd,
                                                               i_flg_other           => d.flg_other,
                                                               i_flg_std_diag        => pk_alert_constant.g_yes,
                                                               i_epis_diag           => ed.id_epis_diagnosis) || ' / ' desc_diagnosis
                               FROM epis_diagnosis ed
                               JOIN diagnosis d
                                 ON d.id_diagnosis = ed.id_diagnosis
                              WHERE ed.id_episode = t.id_episode
                                AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                AND ed.flg_type = g_diag_flg_type) AS table_varchar) diags,
                       pk_date_utils.dt_chr(i_lang, t.p_dt_birth, i_prof) pat_dt_birth
                  FROM (SELECT epis.id_episode,
                               epis.dt_begin_tstz_e,
                               epis.id_patient,
                               epr.dt_request_tstz    epr_dt_request_tstz,
                               epr.flg_status         epr_flg_status,
                               epr.flg_transf_type    epr_flg_transf_type,
                               epr.id_prof_req        epr_id_prof_req,
                               epr.id_epis_prof_resp  epr_id_epis_prof_resp,
                               epr.id_prof_to         epr_id_prof_to,
                               epr.notes_clob         epr_notes_clob,
                               ea.flg_type            ea_flg_type,
                               ea.desc_epis_anamnesis ea_desc_epis_anamnesis,
                               dcs.id_department      dcs_id_department,
                               p.dt_birth             p_dt_birth
                          FROM v_episode_act epis, epis_prof_resp epr, dep_clin_serv dcs, epis_anamnesis ea, patient p
                         WHERE (i_episode IS NULL OR epis.id_episode = i_episode) --(NULL IS NULL OR epis.id_episode = NULL)
                           AND epis.id_software = i_prof.software
                           AND epis.id_institution = i_prof.institution
                           AND epis.flg_ehr = g_flg_ehr_normal
                           AND epis.id_patient = p.id_patient
                           AND ((i_prof.id IN
                               (SELECT column_value
                                    FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    epis.id_episode,
                                                                                    l_prof_cat,
                                                                                    l_hand_off_type))) AND
                               i_episode IS NULL) OR epis.id_episode = i_episode)
                           AND epr.id_episode(+) = epis.id_episode
                           AND epr.flg_transf_type(+) IN (g_flg_transf_i, g_flg_transf_a)
                           AND epis.id_episode = ea.id_episode(+)
                           AND (ea.dt_epis_anamnesis_tstz =
                               (SELECT MAX(ea2.dt_epis_anamnesis_tstz)
                                   FROM epis_anamnesis ea2
                                  WHERE ea2.id_episode = ea.id_episode
                                    AND ea2.flg_type = g_flg_anamnesis_c) OR ea.dt_epis_anamnesis_tstz IS NULL OR
                               (ea.flg_type != g_flg_anamnesis_c AND NOT EXISTS
                                (SELECT 0
                                    FROM epis_anamnesis ea3
                                   WHERE ea3.id_episode = ea.id_episode
                                     AND ea3.flg_type = g_flg_anamnesis_c) AND
                                ea.dt_epis_anamnesis_tstz =
                                (SELECT MAX(ea2.dt_epis_anamnesis_tstz)
                                    FROM epis_anamnesis ea2
                                   WHERE ea2.id_episode = ea.id_episode)))
                           AND epis.id_dep_clin_serv = dcs.id_dep_clin_serv
                           AND rownum > 0) t
                 WHERE (i_flg_show_only_resp = pk_alert_constant.g_no OR
                       (i_flg_show_only_resp = pk_alert_constant.g_yes AND
                       t.epr_dt_request_tstz = ( select
                       pk_hand_off_core.get_max_dt_request(i_lang,
                                                             i_prof,
                                                             t.id_episode,
                                                             nvl(i_flg_type, l_prof_cat),
                                                             l_flg_profile,
                                                             l_hand_off_type) from dual ) OR t.epr_dt_request_tstz IS NULL))
                 ORDER BY t.dt_begin_tstz_e;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END get_grid_hand_off_cab;
    --
    /**********************************************************************************************
    * Gets the list of all patients whose responsible is the current user
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_type               type of hand-off: (D) Physician (N) Nurse
    * @param o_patient                All patients list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.0.3.4 
    * @since                          2010/11/26
    **********************************************************************************************/
    FUNCTION get_grid_hand_off_cab
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT NULL,
        o_patient  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_GRID_HAND_OFF_CAB';
    BEGIN
        RETURN pk_hand_off.get_grid_hand_off_cab(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_episode  => i_episode,
                                                 i_flg_type => i_flg_type,
                                                 --This function is only called in external hand-off
                                                 i_flg_show_only_resp => pk_alert_constant.g_yes,
                                                 o_patient            => o_patient,
                                                 o_error              => o_error);
    END get_grid_hand_off_cab;
    --
    /**********************************************************************************************
    * Listagem de toda a informação associada a cada episódio:
                             - Sinais Vitais
                             - Diagnósticos
                             - Intervenções
                             - Analises
                             - Exames de imagens
                             - Medicação
                             - Notas de passagem de turno
    *                                                          
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_diag                   Todos os diagnóstico do episódio
    * @param o_sign_v                 Todos os sinais vitais do episódio
    * @param o_title_analy            Lista dos títulos com as descrições dos status de cada análise
    * @param o_analysis               Todas as análises do episódio
    * @param o_title_ex_imag          Lista dos títulos com as descrições dos status de cada exame de imagem               
    * @param o_exam_imag              Todos os exames do episódio
    * @param o_title_analy            Lista dos títulos com as descrições dos status de cada análise
    * @param o_title_drug             Lista dos títulos com as descrições dos status de cada prescrição
    * @param o_drug                   Todos os medicamentos do episódio
    * @param o_title_interv           Lista dos títulos com as descrições dos status de cada intervenção
    * @param o_intervention           Todas as intervenções do episódio
    * @param o_title_handoff          Título das notas de passagem de turno
    * @param o_handoff                Todas as notas de passagem de turno
    * @param o_patient                patient id
    * @param o_episode                episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/20
    *
    * @alter                          Jos?Brito
    * @version                        1.1
    * @since                          2008/08/21
    **********************************************************************************************/
     FUNCTION get_grid_hand_off_det
    (
        i_lang          	IN language.id_language%TYPE,
        i_prof          	IN profissional,
        i_episode       	IN episode.id_episode%TYPE,
        i_patient       	IN patient.id_patient%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_diag          	OUT pk_types.cursor_type,
        o_sign_v        	OUT pk_types.cursor_type,
        o_title_analy   	OUT table_clob,
        o_analysis      	OUT table_clob,
        o_title_ex_imag 	OUT table_clob,
        o_exam_imag     	OUT table_clob,
        o_title_exams   	OUT table_clob,
        o_exams         	OUT table_clob,
        o_title_drug    	OUT table_clob,
        o_drug          	OUT table_clob,
        o_title_interv  	OUT table_clob,
        o_intervention  	OUT table_clob,
        o_hidrics       	OUT pk_types.cursor_type,
        o_allergies     	OUT pk_types.cursor_type,
        o_diets         	OUT pk_types.cursor_type,
        o_precautions   	OUT pk_types.cursor_type,
        o_icnp_diag     	OUT pk_types.cursor_type,
        --
        o_title_handoff OUT VARCHAR2,
        o_handoff       OUT pk_types.cursor_type,
        --
        o_patient    OUT patient.id_patient%TYPE,
        o_episode    OUT episode.id_episode%TYPE,
        o_sbar_note  OUT CLOB,
        o_title_sbar OUT VARCHAR2,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_pn_det
        (
            i_prof_software i_prof.software%TYPE,
            i_id_pn_note    pn_note_type.id_pn_note_type%TYPE,
            i_id_market     market.id_market%TYPE,
            i_id_epis_pn    epis_pn.id_epis_pn%TYPE
        ) IS
        
            SELECT t.id_epis_pn_det,
                   pk_message.get_message(i_lang, t.code_message_dn) soap_block,
                   t.id_pn_soap_block,
                   t.id_pn_data_block,
                   pk_message.get_message(i_lang, t.code_pn_data_block) data_block,
                   sbar_note
            
              FROM (SELECT xsql.id_epis_pn_det,
                           xsql.id_pn_soap_block,
                           pnsb.code_message_dn,
                           pnsbm.rank              sb_rank,
                           xsql.id_pn_data_block,
                           pndb.code_pn_data_block,
                           pndbm.rank              db_rank,
                           sbar_note
                      FROM (SELECT epnd.id_epis_pn_det   id_epis_pn_det,
                                   epnd.id_pn_soap_block,
                                   epnd.id_pn_data_block,
                   epnd.pn_note sbar_note
              FROM epis_pn_det epnd
                              JOIN epis_pn epn
                                ON epn.id_epis_pn = epnd.id_epis_pn
                             WHERE epnd.id_epis_pn = i_id_epis_pn
                               AND epnd.flg_status = pk_alert_constant.g_active
                               AND epn.id_pn_note_type = i_id_pn_note
                               AND epnd.pn_note IS NOT NULL
                            UNION ALL
                            SELECT epnd.id_epis_pn_det   id_epis_pn_det,
                                   epnd.id_pn_soap_block,
                                   epnd.id_pn_data_block,
                                   epndt.pn_note         sbar_note
                              FROM epis_pn_det epnd
                              JOIN epis_pn_det_task epndt
                                ON epndt.id_epis_pn_det = epnd.id_epis_pn_det
                              JOIN epis_pn epn
                                ON epn.id_epis_pn = epnd.id_epis_pn
                             WHERE epnd.id_epis_pn = i_id_epis_pn
                               AND epnd.flg_status = pk_alert_constant.g_active
                               AND epn.id_pn_note_type = i_id_pn_note
                               AND epnd.pn_note IS NULL) xsql
              JOIN pn_soap_block pnsb
                        ON pnsb.id_pn_soap_block = xsql.id_pn_soap_block
              JOIN pn_sblock_mkt pnsbm
                ON (pnsbm.id_pn_soap_block = pnsb.id_pn_soap_block AND pnsbm.id_pn_note_type = i_id_pn_note AND
                   pnsbm.id_software = i_prof_software AND pnsbm.id_market = i_id_market)
              JOIN pn_data_block pndb
                        ON xsql.id_pn_data_block = pndb.id_pn_data_block
              JOIN pn_dblock_mkt pndbm
                        ON (pndbm.id_pn_data_block = xsql.id_pn_data_block AND pndbm.id_pn_note_type = i_id_pn_note AND
                   pndbm.id_software = i_prof_software AND pndbm.id_market = i_id_market AND
                           pndbm.id_pn_soap_block = xsql.id_pn_soap_block)
            
                    ) t
             ORDER BY t.sb_rank, t.db_rank;
    
        l_func_name  VARCHAR2(32) := 'GET_GRID_HAND_OFF_DET';
        l_flg_view   VARCHAR2(1) := 'H';
        l_prof_cat   category.flg_type%TYPE;
        l_cs_or_dept VARCHAR2(2);
        err_exception EXCEPTION;
    
        l_hand_off_type sys_config.value%TYPE;
        l_flg_profile   profile_template.flg_profile%TYPE;
    
        l_flg_show_sbar sys_config.value%TYPE;
    
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
    
        l_id_epis_pn     epis_pn.id_epis_pn%TYPE;
        l_old_soap_block pn_soap_block.id_pn_soap_block%TYPE := 0;
        l_old_data_block pn_data_block.id_pn_data_block%TYPE := 0;
        l_data_block     sys_message.desc_message%TYPE;
        l_text_aux       CLOB;
        l_text           CLOB;
        l_market         market.id_market%TYPE;
        l_id_pn_note_type pn_note_type.id_pn_note_type%TYPE;
        l_tbl_pn_note_type table_varchar;
        has_epis_pn       table_number;
    BEGIN
        o_patient := i_patient;
        o_episode := i_episode;
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'GET PROF_CAT AND CS OR DEPT';
        SELECT c.flg_type,
               decode(c.flg_type,
                      g_prof_cat_doc,
                      'CS',
                      g_prof_cat_nrs,
                      decode(pk_sysconfig.get_config('HANDOFF_NURSE', i_prof.institution, i_prof.software),
                             g_handoff_nurse_clin_serv,
                             'CS',
                             g_handoff_nurse_department,
                             'D'))
          INTO l_prof_cat, l_cs_or_dept
          FROM category c
         INNER JOIN prof_cat pc
            ON c.id_category = pc.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        g_error := 'get sys config NURSE_SBAR_SUMMARY';
        IF l_prof_cat = pk_alert_constant.g_cat_type_nurse
        THEN
            l_flg_show_sbar := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
        ELSE
            l_flg_show_sbar := pk_alert_constant.g_no;
        END IF;
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the type of profile. Show only the requests made to my profile.
            g_error := 'GET FLG_PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => NULL,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
        ELSE
            l_flg_profile := NULL;
        END IF;
    
        --
        IF l_flg_show_sbar = pk_alert_constant.g_no
        THEN
            --
            g_error := 'CALL pk_hand_off.get_epis_analy_det_stat';
            IF NOT pk_hand_off.get_epis_analy_det_stat(i_lang     => i_lang,
                                                       i_epis     => i_episode,
                                                       i_patient  => i_patient,
                                                       i_prof     => i_prof,
                                                       o_title    => o_title_analy,
                                                       o_analysis => o_analysis,
                                                       o_error    => o_error)
            THEN
                -- Jos?Brito 21/08/2008 Reutilização de código
                RAISE err_exception;
            END IF;
            --
            -- Diagnósticos diferenciais
            g_error := 'OPEN O_DIAG';
            OPEN o_diag FOR
                SELECT pk_message.get_message(i_lang, 'EDIS_GRID_T025') title
                  FROM dual
                UNION ALL
                SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                  i_id_diagnosis        => d.id_diagnosis,
                                                  i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                  i_code                => d.code_icd,
                                                  i_flg_other           => d.flg_other,
                                                  i_flg_std_diag        => pk_alert_constant.g_yes,
                                                  i_epis_diag           => ed.id_epis_diagnosis) || '/' desc_diagnosis
                  FROM epis_diagnosis ed
                  JOIN diagnosis d
                    ON d.id_diagnosis = ed.id_diagnosis
                 WHERE ed.id_episode = i_episode
                   AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                   AND ed.flg_type = g_diag_flg_type;
            --
            g_error := 'OPEN INTERV';
            -- INTERVENTION
            IF NOT pk_hand_off.get_interv_presc_status(i_lang   => i_lang,
                                                       i_epis   => i_episode,
                                                       i_prof   => i_prof,
                                                       o_title  => o_title_interv,
                                                       o_interv => o_intervention,
                                                       o_error  => o_error)
            THEN
                -- Jos?Brito 21/08/2008 Reutilização de código
                RAISE err_exception;
            END IF;
            --
            /*        g_error := 'OPEN PRESCRIPTION';
            -- MEDICATION
            IF NOT pk_api_pfh_clindoc_in.get_hand_off_presc_status(i_lang  => i_lang,
                                                                   i_epis  => i_episode,
                                                                   i_prof  => i_prof,
                                                                   o_title => o_title_drug,
                                                                   o_drug  => o_drug,
                                                                   o_error => o_error)
            THEN
                -- Jos?Brito 21/08/2008 Reutilização de código
                RAISE err_exception;
            END IF;*/
            o_title_drug := NULL;
            o_drug       := NULL;
            --
            g_error := 'OPEN IMAGES';
            -- IMAGENS
            IF NOT pk_hand_off.get_epis_exam_images_status(i_lang    => i_lang,
                                                           i_epis    => i_episode,
                                                           i_patient => i_patient,
                                                           i_prof    => i_prof,
                                                           o_title   => o_title_ex_imag,
                                                           o_exam    => o_exam_imag,
                                                           o_error   => o_error)
            THEN
                -- Jos?Brito 21/08/2008 Reutilização de código
                RAISE err_exception;
            END IF;
        
            --
            g_error := 'OPEN EXAM';
            -- EXAMES
            IF NOT pk_hand_off.get_epis_exam_status(i_lang    => i_lang,
                                                    i_epis    => i_episode,
                                                    i_patient => i_patient,
                                                    i_prof    => i_prof,
                                                    o_title   => o_title_exams,
                                                    o_exam    => o_exams,
                                                    o_error   => o_error)
            THEN
                -- Jos?Brito 21/08/2008 Reutilização de código
                RAISE err_exception;
            END IF;
        
            -- Jos?Brito 22/08/2008 Mostrar histórico das transferências de responsabilidade
            -- NOTA -------------------------------------------------------------------------
            -- S?ser?apresentado na aplicação na a versão 2.4.4.
            -- Serão necessários dois cursores: um para as transferências de responsabilidade
            -- de enfermagem, e outro para as transferências entre médicos. Naturalmente também
            -- serão necessárias duas variáveis para os títulos das respectivas secções.
            o_title_handoff := pk_message.get_message(i_lang, 'EDIS_GRID_T029');
            --OPEN o_handoff FOR
            --    SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) name_prof_req,
            --           coalesce(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
            --                    pk_message.get_message(i_lang, 'OPINION_M001')) name_prof_to,
            --           pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
            --           epr.flg_status,
            --           decode(epr.flg_status,
            --                  'F',
            --                  (SELECT pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M004')
            --                     FROM dual),
            --                  (SELECT pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M005')
            --                     FROM dual)) desc_status,
            --           pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
            --           pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
            --           epr.notes
            --      FROM epis_prof_resp epr
            --     WHERE epr.id_episode = i_episode
            --       AND epr.id_prof_req <> epr.id_prof_to
            --       AND epr.flg_status NOT IN ('R', 'C') -- para o histórico não interessa mostrar as transferências em curso e as canceladas
            --     ORDER BY epr.dt_request_tstz DESC;
            --
        
            -- Intake & Output
            g_error := 'OPEN O_HIDRICS';
            IF NOT pk_inp_hidrics.get_io_last_auto_balance(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_episode => i_episode,
                                                           o_value   => o_hidrics,
                                                           o_error   => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
            g_error := 'OPEN O_ALLERGIES';
            IF NOT pk_allergy.get_pat_allergies(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_patient   => i_patient,
                                                o_allergies => o_allergies,
                                                o_error     => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
            g_error := 'OPEN O_ALLERGIES';
            IF NOT pk_problems.get_problems_precautions(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_patient     => i_patient,
                                                        o_precautions => o_precautions,
                                                        o_error       => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
            g_error := 'OPEN O_DIET';
            IF NOT pk_api_diet.get_active_diets_desc(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_diets   => o_diets,
                                                     o_error   => o_error)
            THEN
                RAISE err_exception;
            END IF;
            g_error := 'OPEN O_ICNP_DIAG';
            IF NOT get_epis_nursing_diag(i_lang      => i_lang,
                                         i_prof      => i_prof,
                                         i_episode   => i_episode,
                                         o_icnp_diag => o_icnp_diag,
                                         o_error     => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
        l_visit   := pk_episode.get_id_visit(i_episode => i_episode);
    
        g_error := 'CALL pk_vital_sign.get_epis_vs_grid';
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
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  vsr.id_prof_cancel,
                                                  vsr.dt_cancel_tstz,
                                                  vsr.id_episode) desc_speciality_cancel
              FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, l_patient, l_visit, l_flg_view)) vs
              LEFT JOIN vital_sign_read vsr
                ON vsr.id_vital_sign_read = vs.id_vital_sign_read
              LEFT JOIN institution i
                ON i.id_institution = vsr.id_institution_read
             ORDER BY vs.rank, vs.name_vs;
        ELSE
        
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_hidrics);
            pk_types.open_my_cursor(o_allergies);
            pk_types.open_my_cursor(o_diets);
            pk_types.open_my_cursor(o_icnp_diag);
            pk_types.open_my_cursor(o_precautions);
            o_title_ex_imag := table_clob();
            o_exam_imag     := table_clob();
            o_title_drug    := table_clob();
            o_drug          := table_clob();
            o_title_interv  := table_clob();
            o_intervention  := table_clob();
            o_title_analy   := table_clob();
            o_analysis      := table_clob();
        END IF;
        --
               g_error := 'GET NOTES';
            OPEN o_handoff FOR
            --ASANTOS 30-04-2009 Notas do profissional que requereu o handoff
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) name_prof_req,
                       coalesce(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                                pk_message.get_message(i_lang, 'OPINION_M001')) name_prof_to,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
                       epr.flg_status,
                       pk_sysdomain.get_domain('EPIS_PROF_RESP.FLG_STATUS', epr.flg_status, i_lang) desc_status,
                       pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                       epr.notes_clob notes,
                       -- Multiple hand-off support
                       empr.flg_profile flg_profile,
                       decode(l_hand_off_type,
                              g_handoff_multiple,
                              pk_sysdomain.get_domain('PROFILE_TEMPLATE.FLG_PROFILE', empr.flg_profile, i_lang),
                              NULL) flg_profile_desc
                  FROM v_episode_act epis, epis_prof_resp epr, epis_multi_prof_resp empr
                 WHERE epis.id_episode = i_episode
                   AND epis.id_software = i_prof.software
                   AND epis.id_institution = i_prof.institution
                   AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
                   AND i_prof.id IN (SELECT column_value
                                       FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                       i_prof,
                                                                                       epis.id_episode,
                                                                                       l_prof_cat,
                                                                                       l_hand_off_type)))
                   AND epr.id_episode(+) = epis.id_episode
                   AND (epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a) OR epr.flg_transf_type IS NULL)
                   AND epr.id_epis_prof_resp = empr.id_epis_prof_resp(+)
               AND (epr.dt_request_tstz = pk_hand_off_core.get_max_dt_request(i_lang,
                                                            i_prof,
                                                            epis.id_episode,
                                                            l_prof_cat,
                                                            l_flg_profile,
                                                            l_hand_off_type) OR
                       --
                       epr.dt_request_tstz IS NULL)
                   AND epr.flg_status = g_hand_off_r
                UNION ALL
                --ASANTOS 30-04-2009 Notas para o profissional destino
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) name_prof_req,
                       coalesce(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                                pk_message.get_message(i_lang, 'OPINION_M001')) name_prof_to,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
                       epr.flg_status,
                       pk_sysdomain.get_domain('EPIS_PROF_RESP.FLG_STATUS', epr.flg_status, i_lang) desc_status,
                       pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                       epr.notes_clob notes,
                       -- Multiple hand-off support
                       empr.flg_profile flg_profile,
                       decode(l_hand_off_type,
                              g_handoff_multiple,
                              pk_sysdomain.get_domain('PROFILE_TEMPLATE.FLG_PROFILE', empr.flg_profile, i_lang),
                              NULL) flg_profile_desc
                  FROM v_episode_act epis, epis_prof_resp epr, epis_multi_prof_resp empr
                 WHERE epis.id_episode = i_episode
                   AND epis.id_software = i_prof.software
                   AND epis.id_institution = i_prof.institution
                   AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
                   AND epr.id_episode = epis.id_episode
                   AND epr.flg_status = g_hand_off_r
                   AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
                      -- Jos?Brito 18/11/2008 ALERT-9943 Não mostrar as requisições emitidas pelo profissional actual, ...
                      -- ... que podiam aparecer no caso de transferências requisitadas para qualquer profissional.
                   AND epr.id_epis_prof_resp = empr.id_epis_prof_resp(+)
                   AND i_prof.id NOT IN (epr.id_prof_req,
                                         get_prof_resp(i_lang,
                                                       i_prof,
                                                       epr.id_episode,
                                                       NULL,
                                                       l_hand_off_type,
                                                       empr.flg_profile,
                                                       empr.id_speciality))
                      --transf pessoal
                   AND (epr.id_prof_to = i_prof.id OR EXISTS
                        (SELECT 0
                         --transf CS/D
                           FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                          WHERE pdcs.id_professional = i_prof.id
                            AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                            AND decode(l_cs_or_dept, 'CS', dcs.id_dep_clin_serv, 'D', dcs.id_department) =
                                decode(l_cs_or_dept, 'CS', epr.id_clinical_service_dest, 'D', epr.id_department_dest)
                            AND epr.id_prof_to IS NULL
                            AND pdcs.id_institution = i_prof.institution) OR EXISTS
                        (SELECT 0
                         --trans especialidade
                           FROM professional p, speciality s
                          WHERE p.id_professional = i_prof.id
                            AND p.id_speciality = s.id_speciality
                            AND s.id_speciality = epr.id_speciality
                            AND epr.id_prof_to IS NULL))
                --ORDER BY triage_rank_acuity, dt_begin_tstz_e
                ;

        --
        IF pk_edis_grid.get_prof_cat(i_prof => i_prof) = pk_alert_constant.g_cat_type_nurse
        THEN
            BEGIN
                IF i_id_epis_prof_resp IS NOT NULL
                THEN
                    SELECT epr.id_epis_pn
                      BULK COLLECT
                      INTO has_epis_pn
                      FROM epis_prof_resp epr
                     WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp;
                
                    IF has_epis_pn(1) IS NOT NULL
                    THEN
                        --get IF exist sbar note ON epis_prof_resp
                IF NOT get_sbar_note(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                         i_id_epis_prof_resp => i_id_epis_prof_resp,
                                     o_sbar_note => l_text_aux,
                                     o_error     => o_error)
                THEN
                        RAISE err_exception;
                    END IF;
                ELSE
                    
                    --get configured pn_note_type by market
                        l_tbl_pn_note_type := pk_string_utils.str_split(pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_PN_NOTE_TYPE',
                                                                                                i_prof    => i_prof),
                                                                        '|');
                    --get the last epis_pn from episode
                        IF NOT pk_prog_notes_core.get_id_epis_pn(i_lang             => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_id_episode      => i_episode,
                                                                 i_tbl_pn_note_type => l_tbl_pn_note_type,
                                                                 o_id_epis_pn       => l_id_epis_pn,
                                                                 o_id_pn_note_type  => l_id_pn_note_type)
                        THEN
                            l_id_epis_pn      := NULL;
                            l_id_pn_note_type := NULL;
                        END IF;
                
                    IF l_id_epis_pn IS NOT NULL
                    THEN
                    l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
                
                        FOR r IN c_epis_pn_det(i_prof.software, l_id_pn_note_type, l_market, l_id_epis_pn)
                    LOOP
                        IF l_old_soap_block != r.id_pn_soap_block
                        THEN
                            l_text_aux := l_text_aux || '<br/>';
                                    l_text_aux := l_text_aux || pk_prog_notes_constants.g_open_bold_html ||
                                                  r.soap_block || pk_prog_notes_constants.g_close_bold_html || '<br/>';
                        END IF;
                    
                        IF r.data_block IS NOT NULL
                           AND l_old_data_block != r.id_pn_data_block
                        THEN
                            l_text_aux := l_text_aux || '<br/>';
                                    l_text_aux := l_text_aux || pk_prog_notes_constants.g_open_bold_html ||
                                                  r.data_block || pk_prog_notes_constants.g_close_bold_html || '<br/>';
                        
                        END IF;
                    
                        DECLARE
                            l_offset NUMBER := 1;
                            l_amount NUMBER := 32767;
                            l_len    NUMBER := dbms_lob.getlength(r.sbar_note);
                            l_buffer VARCHAR2(32767);
                        
                        BEGIN
                            l_amount := instr(r.sbar_note, '<br/>', l_offset);
                        
                            IF l_amount > 0
                            THEN
                                WHILE (l_offset < l_len)
                                LOOP
                                    dbms_lob.read(r.sbar_note, l_amount, l_offset, l_buffer);
                                    l_text_aux := l_text_aux || l_buffer;
                                    l_offset   := l_offset + l_amount;
                                END LOOP;
                            
                            ELSE
                                l_text_aux := l_text_aux || r.sbar_note;
                            END IF;
                        END;
                    
                        l_old_soap_block := r.id_pn_soap_block;
                        l_old_data_block := r.id_pn_data_block;
                        l_text_aux       := l_text_aux || '<br/>';
                    
                    END LOOP;
					o_sbar_note  := l_text_aux;
                    o_id_epis_pn := l_id_epis_pn;
                    END IF;
                END IF;
				o_sbar_note := l_text_aux;
				o_title_sbar := pk_message.get_message(i_lang => i_lang, i_code_mess => 'TITLE_SBAR_NOTE');
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    o_title_sbar := NULL;
                
            END;
        END IF;
        RETURN TRUE;
    EXCEPTION
        -- Jos?Brito 21/08/2008 Reutilização de código
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_handoff);
            pk_types.open_my_cursor(o_hidrics);
            pk_types.open_my_cursor(o_allergies);
            pk_types.open_my_cursor(o_diets);
            pk_types.open_my_cursor(o_icnp_diag);
            pk_types.open_my_cursor(o_precautions);
            o_title_ex_imag := table_clob();
            o_exam_imag     := table_clob();
            o_title_drug    := table_clob();
            o_drug          := table_clob();
            o_title_interv  := table_clob();
            o_intervention  := table_clob();
            o_title_analy   := table_clob();
            o_analysis      := table_clob();
            o_sbar_note     := NULL;
            o_title_sbar := NULL;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;


    FUNCTION get_hand_off_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        o_patient            OUT pk_types.cursor_type,
        o_sign_v             OUT pk_types.cursor_type,
        o_opinion            OUT pk_types.cursor_type,
        o_treatments         OUT pk_types.cursor_type,
        o_handoff            OUT pk_types.cursor_type,
        o_doctor_notes       OUT pk_types.cursor_type,
        o_nursing_notes      OUT pk_types.cursor_type,
        o_hist_ilness        OUT pk_types.cursor_type,
        o_hidrics            OUT pk_types.cursor_type,
        o_mcdt               OUT pk_types.cursor_type,
        o_mcdt_progress      OUT pk_types.cursor_type,
        o_mcdt_pending       OUT pk_types.cursor_type,
        o_nursing_assessment OUT pk_types.cursor_type,
        o_diet               OUT pk_types.cursor_type,
        o_adm_notes          OUT pk_types.cursor_type,
        o_doc_notes          OUT pk_types.cursor_type,
        o_nrs_notes          OUT pk_types.cursor_type,
        o_surgery_rqt        OUT pk_types.cursor_type,
        o_positioning        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name           VARCHAR2(32) := 'GET_HAND_OFF_REPORT';
        l_flg_view            VARCHAR2(1) := 'H'; -- hand off
        l_presc_plan_stat_adm VARCHAR2(1) := 'A';
        l_treat_type_drug     VARCHAR2(1) := 'D';
        l_interv_status_final VARCHAR2(1) := 'F';
        l_interv_status_curso VARCHAR2(1) := 'E';
        l_interv_status_inter VARCHAR2(1) := 'I';
        l_treat_type_interv   VARCHAR2(1) := 'I';
        l_prof_cat            category.flg_type%TYPE;
        l_cs_or_dept          VARCHAR2(2);
        l_doc_area            NUMBER := 21;
        l_o_dummy             pk_types.cursor_type;
        err_exception EXCEPTION;
    
        l_hand_off_type sys_config.value%TYPE;
        l_flg_profile   profile_template.flg_profile%TYPE;
        l_patient       patient.id_patient%TYPE;
        l_visit         visit.id_visit%TYPE;
    BEGIN
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the type of profile. Show only the requests made to my profile.
            g_error := 'GET FLG_PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => NULL,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
        ELSE
            l_flg_profile := NULL;
        END IF;
    
        g_error := 'GET PROF_CAT AND CS OR DEPT';
        SELECT c.flg_type,
               decode(c.flg_type,
                      g_prof_cat_doc,
                      'CS',
                      g_prof_cat_nrs,
                      decode(pk_sysconfig.get_config('HANDOFF_NURSE', i_prof.institution, i_prof.software),
                             g_handoff_nurse_clin_serv,
                             'CS',
                             g_handoff_nurse_department,
                             'D'))
          INTO l_prof_cat, l_cs_or_dept
          FROM category c
         INNER JOIN prof_cat pc
            ON c.id_category = pc.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        --cabeçalho 
        g_error := 'CALL PK_HAND_OFF.GET_GRID_HAND_OFF_CAB';
        IF NOT pk_hand_off.get_grid_hand_off_cab(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 o_patient => o_patient,
                                                 o_error   => o_error)
        THEN
            RAISE err_exception;
        END IF;
    
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
        l_visit   := pk_episode.get_id_visit(i_episode => i_episode);
    
        --sinais vitais
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
              FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, l_patient, l_visit, l_flg_view)) vs
              LEFT JOIN vital_sign_read vsr
                ON vsr.id_vital_sign_read = vs.id_vital_sign_read
              LEFT JOIN institution i
                ON i.id_institution = vsr.id_institution_read
             ORDER BY vs.rank, vs.name_vs;
    
        RETURN TRUE;
    
        --pareceres  
        IF l_prof_cat = g_prof_cat_doc --doctor 
        THEN
        
            OPEN o_opinion FOR
                SELECT 'Pede-se parecer por AVC isquémico e orientação' AS opinion
                  FROM dual;
        END IF;
    
        --resposta ao tratamento
        IF l_prof_cat = g_prof_cat_doc
           AND i_prof.software = g_software_edis
        THEN
            g_error := 'OPEN CURSOR';
            OPEN o_treatments FOR
                SELECT desc_treat_manag,
                       (SELECT tm.desc_treatment_management
                          FROM treatment_management tm
                         WHERE tm.id_treatment = hf_med.id_drug_presc_det
                           AND tm.flg_type = l_treat_type_drug
                           AND tm.dt_creation_tstz = (SELECT MAX(tm1.dt_creation_tstz)
                                                        FROM treatment_management tm1
                                                       WHERE tm1.id_treatment = hf_med.id_drug_presc_det
                                                         AND tm1.flg_type = l_treat_type_drug)) desc_treatment_management
                  FROM TABLE(pk_api_pfh_clindoc_in.get_hand_off_treatment(i_lang, i_prof, i_episode)) hf_med
                UNION ALL
                SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'INTERVENTION.CODE_INTERVENTION.' ||
                                                                  pea.id_intervention,
                                                                  NULL) || ' (' ||
                       pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_STATUS', pea.flg_status_det, i_lang) || ') ' desc_treat_manag,
                       (SELECT tm.desc_treatment_management
                          FROM treatment_management tm
                         WHERE tm.id_treatment = pea.id_interv_presc_det
                           AND tm.flg_type = l_treat_type_interv
                           AND tm.dt_creation_tstz = (SELECT MAX(tm1.dt_creation_tstz)
                                                        FROM treatment_management tm1
                                                       WHERE tm1.id_treatment = pea.id_interv_presc_det
                                                         AND tm1.flg_type = l_treat_type_interv)) desc_treatment_management
                  FROM procedures_ea pea,
                       (SELECT id_episode, flg_status
                          FROM episode
                         WHERE id_episode = i_episode
                        UNION ALL
                        SELECT id_episode, flg_status
                          FROM episode
                         WHERE id_prev_episode = i_episode) epis
                 WHERE pea.flg_status_det IN (l_interv_status_final, l_interv_status_curso, l_interv_status_inter)
                   AND epis.id_episode = pea.id_episode;
        
        END IF;
    
        --notas passagem de turno
        g_error := 'GET NOTES';
        OPEN o_handoff FOR
        --ASANTOS 30-04-2009 Notas do profissional que requereu o handoff
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) name_prof_req,
                   coalesce(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                            pk_message.get_message(i_lang, 'OPINION_M001')) name_prof_to,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
                   epr.flg_status,
                   pk_sysdomain.get_domain('EPIS_PROF_RESP.FLG_STATUS', epr.flg_status, i_lang) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                   epr.notes_clob notes
              FROM v_episode_act epis, epis_prof_resp epr
             WHERE (i_episode IS NULL OR epis.id_episode = i_episode)
               AND epis.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
                  --LMAIA 09-04-2009 Schedule episodes should have same permissions that normal episodes have
               AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                  --AND epis.flg_ehr = g_flg_ehr_normal
                  --END
               AND decode(l_prof_cat, g_prof_cat_doc, epis.id_professional, g_prof_cat_nrs, epis.id_first_nurse_resp) =
                   i_prof.id
               AND epr.id_episode(+) = epis.id_episode
               AND (epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a) OR epr.flg_transf_type IS NULL)
               AND (epr.dt_request_tstz = pk_hand_off_core.get_max_dt_request(i_lang,
                                                                              i_prof,
                                                                              epis.id_episode,
                                                                              l_prof_cat,
                                                                              l_flg_profile,
                                                                              l_hand_off_type) OR
                   --
                   epr.dt_request_tstz IS NULL)
               AND epr.flg_status = g_hand_off_r
            UNION
            --ASANTOS 30-04-2009 Notas para o profissional destino
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req) name_prof_req,
                   coalesce(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                            pk_message.get_message(i_lang, 'OPINION_M001')) name_prof_to,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
                   epr.flg_status,
                   pk_sysdomain.get_domain('EPIS_PROF_RESP.FLG_STATUS', epr.flg_status, i_lang) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                   epr.notes_clob notes
              FROM v_episode_act epis, epis_prof_resp epr
             WHERE (i_episode IS NULL OR epis.id_episode = i_episode)
               AND epis.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
                  --LMAIA 09-04-2009 Schedule episodes should have same permissions that normal episodes have
               AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                  --AND epis.flg_ehr = g_flg_ehr_normal
                  --END
               AND epr.id_episode = epis.id_episode
               AND epr.flg_status = g_hand_off_r
               AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
                  -- Jos?Brito 18/11/2008 ALERT-9943 Não mostrar as requisições emitidas pelo profissional actual, ...
                  -- ... que podiam aparecer no caso de transferências requisitadas para qualquer profissional.
               AND epr.id_prof_req <> i_prof.id
                  --transf pessoal
               AND (epr.id_prof_to = i_prof.id OR EXISTS
                    (SELECT 0
                     --transf CS/D
                       FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                      WHERE pdcs.id_professional = i_prof.id
                        AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                        AND decode(l_cs_or_dept, 'CS', dcs.id_dep_clin_serv, 'D', dcs.id_department) =
                            decode(l_cs_or_dept, 'CS', epr.id_clinical_service_dest, 'D', epr.id_department_dest)
                        AND epr.id_prof_to IS NULL
                        AND pdcs.id_institution = i_prof.institution) OR EXISTS
                    (SELECT 0
                     --trans especialidade
                       FROM professional p, speciality s
                      WHERE p.id_professional = i_prof.id
                        AND p.id_speciality = s.id_speciality
                        AND s.id_speciality = epr.id_speciality
                        AND epr.id_prof_to IS NULL))
            --ORDER BY triage_rank_acuity, dt_begin_tstz_e
            ;
    
        --evolução do episódio
        IF l_prof_cat = g_prof_cat_doc
           AND i_prof.software = g_software_edis
        THEN
            IF NOT pk_medical_decision.get_epis_last_doctor_notes(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_epis         => i_episode,
                                                                  i_prof_cat     => l_prof_cat,
                                                                  o_doctor_notes => o_doctor_notes,
                                                                  o_error        => o_error)
            THEN
                RAISE err_exception;
            END IF;
        END IF;
    
        IF l_prof_cat = g_prof_cat_nrs
           AND i_prof.software = g_software_edis
        THEN
            IF NOT pk_medical_decision.get_epis_last_doctor_notes(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_epis         => i_episode,
                                                                  i_prof_cat     => l_prof_cat,
                                                                  o_doctor_notes => o_doctor_notes,
                                                                  o_error        => o_error)
            
            THEN
                RAISE err_exception;
            END IF;
        
            IF NOT pk_medical_decision.get_epis_last_nurse_notes(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_epis          => i_episode,
                                                                 i_prof_cat      => l_prof_cat,
                                                                 o_nursing_notes => o_nursing_notes,
                                                                 o_error         => o_error)
            
            THEN
                RAISE err_exception;
            END IF;
        END IF;
    
        --historia da doença actual
        IF i_prof.software = g_software_edis
        THEN
            g_error := 'OPEN CURSOR O_HIST_ILNESS';
        
            OPEN o_hist_ilness FOR
                SELECT 'Paciente deu entrada com dores de peito' AS hist_ilness
                  FROM dual;
        END IF;
    
        --registos hidricos   
        g_error := 'OPEN CURSOR O_HIDRICS';
    
        OPEN o_hidrics FOR
            SELECT '24 horas' AS bal_interval,
                   '26-Mar-2009 / 09:32' AS time_finish,
                   '260 ml' AS adm_total,
                   '150 ml' AS elim_total,
                   '110 ml (parcial)' AS results
              FROM dual;
    
        --mcdt last 24 hours ( dps restringir o medicos INP)  
    
        IF NOT (i_prof.software = g_software_inp AND l_prof_cat = g_prof_cat_doc)
        THEN
            g_error := 'OPEN CURSOR O_MCDT';
            OPEN o_mcdt FOR
                SELECT 'Soros construidos' AS medication,
                       'Pensos MSD' AS procedures,
                       'Hematologia: Hemograma' AS analysis,
                       'Ecografia Ginecologoca' AS exams,
                       'ECG simples' AS exams_others
                  FROM dual;
        END IF;
    
        g_error := 'OPEN CURSOR O_MCDT_PROGRESS';
    
        OPEN o_mcdt_progress FOR
            SELECT 'Adrelina (1mg/1ml)' AS medication, 'Administração de soros (inclui vigilância)' AS procedures
              FROM dual;
    
        g_error := 'OPEN CURSOR O_MCDT_PENDING';
    
        IF i_prof.software = g_software_inp
        THEN
            OPEN o_mcdt_pending FOR
                SELECT 'Omeprazol' AS medication,
                       'Avaliação de tensão arterial' AS procedures,
                       'Creatina quinase' AS analysis,
                       'Abdomen simples' AS images_exams,
                       'Gasometria' AS other_exams,
                       'Pulso,dor' AS monitoration
                  FROM dual;
        END IF;
    
        --Nursing assessment
        IF l_prof_cat = g_prof_cat_nrs
        THEN
        
            OPEN o_nursing_assessment FOR
            
                SELECT 'Ulcera de pressão (Activo)' AS diag_desc,
                       'Adequar posicionamento (Em curso)' AS interv,
                       'Aconselhar vigilância médica (Em curso)' AS freq
                  FROM dual;
        
        END IF;
    
        --diet
        IF i_prof.software = g_software_inp
        THEN
            OPEN o_diet FOR
                SELECT 'Dieta cozidos e Grelhados - Meio sal' AS diet
                  FROM dual;
        END IF;
    
        -- admission notes
    
        IF i_prof.software = g_software_inp
        THEN
            OPEN o_adm_notes FOR
                SELECT 'O doente deu entrada com dores no sistema urinário' AS admission_notes
                  FROM dual;
        END IF;
    
        --notes
        IF i_prof.software = g_software_inp
           AND l_prof_cat = g_prof_cat_doc
        THEN
            OPEN o_doc_notes FOR
                SELECT 'Diário médico' AS doc_notes
                  FROM dual;
        END IF;
    
        IF i_prof.software = g_software_inp
           AND l_prof_cat = g_prof_cat_nrs
        THEN
            OPEN o_nrs_notes FOR
                SELECT 'Diário enfermagem' AS nrs_notes
                  FROM dual;
        END IF;
    
        --surgery request
        IF i_prof.software = g_software_inp
        THEN
            OPEN o_surgery_rqt FOR
                SELECT 'Limpeza cirúrgica de ferida (01-ago-2008)'
                  FROM dual;
        END IF;
        RETURN TRUE;
    
        --Positioning
        IF i_prof.software = g_software_inp
           AND l_prof_cat = g_prof_cat_nrs
        THEN
            OPEN o_positioning FOR
                SELECT 'Colocar o paciente nas seguintes posições' AS positioning
                  FROM dual;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_patient);
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_opinion);
            pk_types.open_my_cursor(o_treatments);
            pk_types.open_my_cursor(o_handoff);
            pk_types.open_my_cursor(o_doctor_notes);
            pk_types.open_my_cursor(o_nursing_notes);
            pk_types.open_my_cursor(o_hist_ilness);
            pk_types.open_my_cursor(o_hidrics);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_mcdt_progress);
            pk_types.open_my_cursor(o_mcdt_pending);
            pk_types.open_my_cursor(o_nursing_assessment);
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_adm_notes);
            pk_types.open_my_cursor(o_doc_notes);
            pk_types.open_my_cursor(o_nrs_notes);
            pk_types.open_my_cursor(o_surgery_rqt);
            pk_types.open_my_cursor(o_positioning);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_hand_off_report;

    /**********************************************************************************************
    * Obter o detalhe de uma transferência de responsabilidade
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_prof_resp         ID do prof q acede
    * @param o_epis_presp             Todos as transferências de responsabilidade do episódio (paciente)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/09/04
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_epis_presp     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_EPIS_PROF_RESP_DET';
    
        l_id_episode  episode.id_episode%TYPE;
        l_dt_comp     epis_prof_resp.dt_comp_tstz%TYPE;
        l_flg_type    epis_prof_resp.flg_type%TYPE;
        l_flg_profile profile_template.flg_profile%TYPE;
    
        l_hand_off_type sys_config.value%TYPE;
        --
        l_sbar_note sys_config.value%TYPE;
        --
        l_code_dom_cat_flg_type   CONSTANT sys_domain.code_domain%TYPE := 'CATEGORY.FLG_TYPE';
        l_code_dom_pt_flg_profile CONSTANT sys_domain.code_domain%TYPE := 'PROFILE_TEMPLATE.FLG_PROFILE';
        --
        l_prof_cat_desc sys_domain.desc_val%TYPE;
    BEGIN
        g_error     := 'GET SBAR CONFIG';
        l_sbar_note := pk_sysconfig.get_config(i_code_cf => 'NURSE_SBAR_SUMMARY', i_prof => i_prof);
    
        g_error := 'GET CONFIG';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'GET EPISODE ID';
        SELECT ep.id_episode, ep.dt_comp_tstz, ep.flg_type, empr.flg_profile
          INTO l_id_episode, l_dt_comp, l_flg_type, l_flg_profile
          FROM epis_prof_resp ep, epis_multi_prof_resp empr
         WHERE ep.id_epis_prof_resp = i_epis_prof_resp
           AND ep.id_epis_prof_resp = empr.id_epis_prof_resp(+);
    
        g_error         := 'GET PROF_CAT_DESC';
        l_prof_cat_desc := pk_sysdomain.get_domain(i_code_dom => l_code_dom_cat_flg_type,
                                                   i_val      => l_flg_type, -- The category of the transfer!!
                                                   i_lang     => i_lang);
    
        g_error := 'OPEN o_epis_presp';
        OPEN o_epis_presp FOR
            SELECT epr.id_epis_prof_resp,
                   decode(epr.id_prof_req, epr.id_prof_to, '', epr.id_prof_req) id_prof_req,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          ' ',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_req)) name_prof_req,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          '',
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           epr.id_prof_req,
                                                           epr.dt_request_tstz,
                                                           epr.id_episode)) desc_spec_r,
                   decode(epr.id_prof_req,
                          epr.id_prof_to,
                          '',
                          pk_translation.get_translation_dtchk(i_lang,
                                                               'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                               epr.id_clinical_service_orig)) desc_clinsrv_r,
                   decode(epr.id_prof_prev, -- Jos?Brito 26/10/2009 ALERT-39320 Changed this condition.
                           NULL, -- The previous condition wasn't true when the hand-off request was made by a nurse.
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, epis_pr.id_prof)
                             FROM (SELECT ep.id_epis_prof_resp,
                                          ep.id_prof_to id_prof,
                                          row_number() over(ORDER BY ep.dt_comp_tstz DESC) rn
                                     FROM epis_prof_resp ep
                                    WHERE ep.id_episode = l_id_episode
                                      AND ep.id_epis_prof_resp <> i_epis_prof_resp
                                      AND ep.dt_comp_tstz < l_dt_comp
                                      AND ep.flg_status = g_hand_off_f
                                      AND ep.flg_type = l_flg_type
                                      AND ep.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
                                         -- Jos?Brito 26/10/2009 ALERT-39320 Support for multiple hand-off mechanism
                                      AND ((l_hand_off_type = g_handoff_multiple AND
                                          ep.id_epis_prof_resp IN
                                          (SELECT empr.id_epis_prof_resp
                                               FROM epis_multi_prof_resp empr
                                              WHERE empr.id_episode = ep.id_episode
                                                AND empr.flg_profile = l_flg_profile)) OR
                                          l_hand_off_type = g_handoff_normal)) epis_pr
                            WHERE rn <= 1),
                          pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_prev)) name_prof_prev,
                   decode(epr.id_prof_prev, -- Jos?Brito 26/10/2009 ALERT-39320 Changed this condition.
                           NULL, -- The previous condition wasn't true when the hand-off request was made by a nurse.
                          (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   epis_pr.id_prof,
                                                                   epis_pr.dt_request_tstz,
                                                                   epis_pr.id_episode)
                             FROM (SELECT ep.id_epis_prof_resp,
                                          ep.id_prof_to id_prof,
                                          ep.dt_request_tstz,
                                          ep.id_episode,
                                          row_number() over(ORDER BY ep.dt_comp_tstz DESC) rn
                                     FROM epis_prof_resp ep
                                    WHERE id_episode = l_id_episode
                                      AND ep.id_epis_prof_resp <> i_epis_prof_resp
                                      AND ep.dt_comp_tstz < l_dt_comp
                                      AND ep.flg_status = g_hand_off_f
                                      AND ep.flg_type = l_flg_type
                                      AND ep.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
                                         -- Jos?Brito 26/10/2009 ALERT-39320 Support for multiple hand-off mechanism
                                      AND ((l_hand_off_type = g_handoff_multiple AND
                                          ep.id_epis_prof_resp IN
                                          (SELECT empr.id_epis_prof_resp
                                               FROM epis_multi_prof_resp empr
                                              WHERE empr.id_episode = ep.id_episode
                                                AND empr.flg_profile = l_flg_profile)) OR
                                          l_hand_off_type = g_handoff_normal)) epis_pr
                            WHERE rn <= 1),
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           epr.id_prof_prev,
                                                           epr.dt_request_tstz,
                                                           epr.id_episode)) desc_spec_prev,
                   pk_hand_off_core.get_cs_dep_spec_label(i_lang,
                                                          i_prof,
                                                          epr.id_clinical_service_orig,
                                                          epr.id_department_orig,
                                                          pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                                               profissional(epr.id_prof_req,
                                                                                                            i_prof.institution,
                                                                                                            i_prof.software))) label_orig,
                   pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                         i_prof,
                                                         epr.id_clinical_service_orig,
                                                         epr.id_department_orig,
                                                         pk_prof_utils.get_prof_speciality_id(i_lang,
                                                                                              profissional(epr.id_prof_req,
                                                                                                           i_prof.institution,
                                                                                                           i_prof.software))) desc_orig,
                   epr.id_prof_to,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_to),
                       pk_message.get_message(i_lang, 'OPINION_M001')) name_prof_to,
                   pk_hand_off_core.get_cs_dep_spec_label(i_lang,
                                                          i_prof,
                                                          epr.id_clinical_service_dest,
                                                          epr.id_department_dest,
                                                          empr.id_speciality) label_dest_t,
                   pk_hand_off_core.get_cs_dep_spec_desc(i_lang,
                                                         i_prof,
                                                         epr.id_clinical_service_dest,
                                                         epr.id_department_dest,
                                                         empr.id_speciality) desc_dest_t,
                   epr.id_clinical_service_dest,
                   epr.id_department_dest,
                   epr.id_prof_comp,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_comp) name_prof_comp,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, epr.id_prof_comp, epr.dt_comp_tstz, epr.id_episode) desc_spec_comp,
                   epr.flg_status,
                   decode(epr.flg_status,
                          'R',
                          pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M003'),
                          'F',
                          pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M004'),
                          'D',
                          pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M005'),
                          pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M006')) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_request_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_request_tstz, i_prof.institution, i_prof.software) hour_target_r,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_decline_tstz, i_prof) date_target_d,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_decline_tstz, i_prof.institution, i_prof.software) hour_target_d,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_cancel_tstz, i_prof) date_target_c,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_c,
                   pk_date_utils.dt_chr_tsz(i_lang, epr.dt_comp_tstz, i_prof) date_target_comp,
                   pk_date_utils.date_char_hour_tsz(i_lang, epr.dt_comp_tstz, i_prof.institution, i_prof.software) hour_target_comp,
                   epr.notes_clob notes,
                   epr.notes_cancel,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, epr.id_cancel_reason) desc_cancel_reason,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_cancel) name_prof_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, epr.id_prof_decline) name_prof_decline,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(epr.id_prof_comp, epr.id_prof_to),
                                                    decode(epr.id_prof_comp, NULL, epr.dt_request_tstz, epr.dt_comp_tstz),
                                                    epr.id_episode) desc_spec_to,
                   pk_hand_off_core.get_profile_template_desc(i_lang,
                                                              pk_prof_utils.get_prof_profile_template(profissional(nvl(epr.id_prof_comp,
                                                                                                                       epr.id_prof_to),
                                                                                                                   i_prof.institution,
                                                                                                                   i_prof.software))) desc_cat_to,
                   pk_hand_off_core.get_profile_template_desc(i_lang,
                                                              pk_prof_utils.get_prof_profile_template(profissional(epr.id_prof_req,
                                                                                                                   i_prof.institution,
                                                                                                                   i_prof.software))) desc_cat_req,
                   pk_prof_utils.get_desc_category(i_lang, i_prof, epr.id_prof_comp, i_prof.institution) desc_cat_comp,
                   empr.flg_resp_type,
                   decode(empr.flg_resp_type,
                          NULL,
                          NULL,
                          pk_hand_off_core.get_resp_type_desc(i_lang, i_prof, empr.id_epis_prof_resp, l_hand_off_type)) desc_resp_type,
                   
                   decode(l_hand_off_type,
                           pk_hand_off.g_handoff_multiple,
                           CASE
                               WHEN epr.id_profile_template IS NOT NULL THEN
                                pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                               ELSE
                                pk_sysdomain.get_domain(l_code_dom_pt_flg_profile, empr.flg_profile, i_lang)
                           END,
                           CASE
                               WHEN epr.id_profile_template IS NOT NULL THEN
                                pk_hand_off_core.get_profile_template_desc(i_lang, epr.id_profile_template)
                               ELSE
                                l_prof_cat_desc
                           END) flg_profile_desc,
                   epr.flg_transf_type,
                   CASE l_sbar_note
                       WHEN pk_alert_constant.g_yes THEN
                        epr.sbar_notes
                       ELSE
                        NULL
                   END sbar_note
              FROM epis_prof_resp epr
              LEFT JOIN epis_multi_prof_resp empr
                ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
             WHERE epr.id_epis_prof_resp = i_epis_prof_resp
               AND epr.flg_status <> g_hand_off_x
               AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_o, g_flg_transf_a);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_epis_presp);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Hand off information for reports
    *                                                          
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_title_handoff          Hand off title
    * @param o_handoff                Hand off notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Spratley
    * @version                        2.6.0.3 
    * @since                          2010/08/04
    **********************************************************************************************/

    FUNCTION get_grid_hand_off_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        o_title_handoff OUT VARCHAR2,
        o_handoff       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_GRID_HAND_OFF_REPORT';
        l_prof_cat      category.flg_type%TYPE;
        l_cs_or_dept    VARCHAR2(2);
        l_hand_off_type sys_config.value%TYPE;
        l_flg_profile   profile_template.flg_profile%TYPE;
        err_exception EXCEPTION;
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
            -- Get the type of profile. Show only the requests made to my profile.
            g_error := 'GET FLG_PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => NULL,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE err_exception;
            END IF;
        
        ELSE
            l_flg_profile := NULL;
        END IF;
    
        --
        o_title_handoff := pk_message.get_message(i_lang, 'EDIS_GRID_T029');
    
        g_error := 'GET PROF_CAT AND CS OR DEPT';
        SELECT c.flg_type,
               decode(c.flg_type,
                      g_prof_cat_doc,
                      g_cons_cs,
                      g_prof_cat_nrs,
                      decode(pk_sysconfig.get_config('HANDOFF_NURSE', i_prof.institution, i_prof.software),
                             g_handoff_nurse_clin_serv,
                             g_cons_cs,
                             g_handoff_nurse_department,
                             g_prof_cat_doc))
          INTO l_prof_cat, l_cs_or_dept
          FROM category c
         INNER JOIN prof_cat pc
            ON c.id_category = pc.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        g_error := 'GET NOTES';
        OPEN o_handoff FOR
            SELECT epis.id_episode, epis.id_patient, epr.notes_clob notes
              FROM v_episode_act epis, epis_prof_resp epr
             WHERE epis.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
               AND epis.id_episode = i_epis
               AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
               AND i_prof.id IN (SELECT column_value
                                   FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                   i_prof,
                                                                                   epis.id_episode,
                                                                                   l_prof_cat,
                                                                                   l_hand_off_type)))
               AND epr.id_episode(+) = epis.id_episode
               AND (epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a) OR epr.flg_transf_type IS NULL)
               AND (epr.dt_request_tstz = pk_hand_off_core.get_max_dt_request(i_lang,
                                                                              i_prof,
                                                                              epis.id_episode,
                                                                              l_prof_cat,
                                                                              l_flg_profile,
                                                                              l_hand_off_type) OR
                   --
                   epr.dt_request_tstz IS NULL)
               AND epr.flg_status = g_hand_off_r
            UNION
            SELECT epis.id_episode, epis.id_patient, epr.notes_clob notes
              FROM v_episode_act epis, epis_prof_resp epr
             WHERE epis.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
               AND epis.id_episode = i_epis
               AND (epis.flg_ehr = g_flg_ehr_normal OR epis.flg_ehr = g_flg_ehr_schedule)
               AND epr.id_episode = epis.id_episode
               AND epr.flg_status = g_hand_off_r
               AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
               AND (epr.id_prof_to = i_prof.id OR EXISTS
                    (SELECT 0
                     --transf CS/D         
                       FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                      WHERE pdcs.id_professional = i_prof.id
                        AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                        AND decode(l_cs_or_dept, g_cons_cs, dcs.id_dep_clin_serv, g_prof_cat_doc, dcs.id_department) =
                            decode(l_cs_or_dept,
                                   g_cons_cs,
                                   epr.id_clinical_service_dest,
                                   g_prof_cat_doc,
                                   epr.id_department_dest)
                        AND epr.id_prof_to IS NULL
                        AND pdcs.id_institution = i_prof.institution) OR EXISTS
                    (SELECT 0
                     --trans especialidade
                       FROM professional p, speciality s
                      WHERE p.id_professional = i_prof.id
                        AND p.id_speciality = s.id_speciality
                        AND s.id_speciality = epr.id_speciality
                        AND epr.id_prof_to IS NULL));
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_handoff);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    --
    /**********************************************************************************************
    * Listagem das análises de um episódio por status(estado)
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_patient                patient id
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Títulos associados ?descrição do estado da análise
    * @param o_analysis               Listas das análises
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/18
    **********************************************************************************************/
    FUNCTION get_epis_analy_det_stat
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN analysis_req.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_title    OUT table_clob,
        o_analysis OUT table_clob,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_EPIS_ANALY_DET_STAT';
    
        l_analysis      pk_types.cursor_type;
        l_desc_analysis CLOB;
        l_status        VARCHAR2(2 CHAR);
    BEGIN
    
        IF NOT pk_lab_tests_external_api_db.get_lab_tests_by_status(i_lang     => i_lang,
                                                                    i_prof     => i_prof,
                                                                    i_episode  => i_epis,
                                                                    o_analysis => l_analysis,
                                                                    o_error    => o_error)
        THEN
            o_title    := table_clob();
            o_analysis := table_clob();
            RETURN FALSE;
        END IF;
        g_error := 'FETCH L_ANALYSIS';
        FETCH l_analysis
            INTO l_desc_analysis, l_status;
    
        CLOSE l_analysis;
        g_error := 'SELECT FROM DUAL';
        SELECT nvl2(l_desc_analysis,
                    upper(pk_message.get_message(i_lang, 'EDIS_GRID_T026')) || ' ' ||
                    pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M009'),
                    ''),
               l_desc_analysis
          BULK COLLECT
          INTO o_title, o_analysis
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            o_title    := table_clob();
            o_analysis := table_clob();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter as intervenções de um episódio por STATUS
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Lista dos títulos com as descrições dos status de cada intervenção
    * @param o_interv                 Listas dos procedimentos
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/17  
    **********************************************************************************************/
    FUNCTION get_interv_presc_status
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN interv_prescription.id_episode%TYPE,
        i_prof   IN profissional,
        o_title  OUT table_clob,
        o_interv OUT table_clob,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_interv       pk_types.cursor_type;
        l_func_name    VARCHAR2(32) := 'GET_INTERV_PRESC_STATUS';
        l_status       VARCHAR2(2 CHAR);
        l_intervention CLOB;
    
    BEGIN
        IF NOT pk_procedures_external_api_db.get_procedure_by_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_epis,
                                                                     o_interv  => l_interv,
                                                                     o_error   => o_error)
        THEN
            o_title  := table_clob();
            o_interv := table_clob();
            RETURN FALSE;
        END IF;
        g_error := 'FETCH l_interv';
        FETCH l_interv
            INTO l_intervention, l_status;
    
        CLOSE l_interv;
        g_error := 'SELECT FROM DUAL';
        SELECT nvl2(l_intervention,
                    upper(pk_message.get_message(i_lang, 'EDIS_GRID_T045')) || ' ' ||
                    pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M014'),
                    ''),
               l_intervention
          BULK COLLECT
          INTO o_title, o_interv
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            o_title  := table_clob();
            o_interv := table_clob();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Listagem dos exames de um episódio por status
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_patient                patient id    
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Lista dos títulos com as descrições dos status de cada exame de imagem
    * @param o_exam                   Lista dos exames de imagens
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/18  
    **********************************************************************************************/
    FUNCTION get_epis_exam_status
    (
        i_lang    IN language.id_language%TYPE,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_title   OUT table_clob,
        o_exam    OUT table_clob,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_EPIS_EXAM_STATUS';
    
        l_exams      pk_types.cursor_type;
        l_desc_exams table_clob;
        l_status     table_varchar;
    
    BEGIN
    
        IF NOT pk_exams_external_api_db.get_exam_by_status(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_episode  => i_epis,
                                                           i_flg_type => g_exam_type,
                                                           o_exam     => l_exams,
                                                           o_error    => o_error)
        THEN
            o_title := table_clob();
            o_exam  := table_clob();
            RETURN FALSE;
        END IF;
        g_error := 'FETCH L_ANALYSIS';
        FETCH l_exams BULK COLLECT
            INTO l_desc_exams, l_status;
    
        CLOSE l_exams;
        g_error := 'SELECT FROM DUAL';
        SELECT upper(pk_message.get_message(i_lang, 'EDIS_GRID_T127')) || ' ' ||
               decode(flg_status,
                      g_exam_det_req,
                      pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M014'),
                      pk_sysdomain.get_domain(i_code_dom => g_exam_req_det_status, i_val => flg_status, i_lang => i_lang)),
               exam_description
          BULK COLLECT
          INTO o_title, o_exam
          FROM (SELECT r11.flg_status, r22.exam_description
                  FROM (SELECT /*+ opt_estimate( table r1 rows=1) */
                         rownum rn, column_value flg_status
                          FROM TABLE(l_status) r1) r11
                  JOIN (SELECT /*+ opt_estimate( table r2 rows=1) */
                        rownum rn, column_value exam_description
                         FROM TABLE(l_desc_exams) r2) r22
                    ON r11.rn = r22.rn) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            o_title := table_clob();
            o_exam  := table_clob();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Listagem dos exames de IMAGEM de um episódio por status
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_patient                patient id    
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Lista dos títulos com as descrições dos status de cada exame de imagem
    * @param o_exam                   Lista dos exames de imagens
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @version                        1.0 
    * @since                          2008/06/04  
    **********************************************************************************************/
    FUNCTION get_epis_exam_images_status
    (
        i_lang    IN language.id_language%TYPE,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_title   OUT table_clob,
        o_exam    OUT table_clob,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_EPIS_EXAM_IMAGES_STATUS';
    
        l_exams      pk_types.cursor_type;
        l_desc_exams table_clob;
        l_status     table_varchar;
    
    BEGIN
    
        IF NOT pk_exams_external_api_db.get_exam_by_status(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_episode  => i_epis,
                                                           i_flg_type => g_image_exam_type,
                                                           o_exam     => l_exams,
                                                           o_error    => o_error)
        THEN
            o_title := table_clob();
            o_exam  := table_clob();
            RETURN FALSE;
        END IF;
        g_error := 'FETCH L_ANALYSIS';
        FETCH l_exams BULK COLLECT
            INTO l_desc_exams, l_status;
    
        CLOSE l_exams;
        g_error := 'SELECT FROM DUAL';
        SELECT upper(pk_message.get_message(i_lang, 'EDIS_GRID_T027')) || ' ' ||
               decode(flg_status,
                      g_exam_det_req,
                      pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M009'),
                      pk_sysdomain.get_domain(i_code_dom => g_exam_req_det_status, i_val => flg_status, i_lang => i_lang)),
               exam_description
          BULK COLLECT
          INTO o_title, o_exam
          FROM (SELECT r11.flg_status, r22.exam_description
                  FROM (SELECT /*+ opt_estimate( table r1 rows=1) */
                         rownum rn, column_value flg_status
                          FROM TABLE(l_status) r1) r11
                  JOIN (SELECT /*+ opt_estimate( table r2 rows=1) */
                        rownum rn, column_value exam_description
                         FROM TABLE(l_desc_exams) r2) r22
                    ON r11.rn = r22.rn) t;
    
        RETURN TRUE;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            o_title := table_clob();
            o_exam  := table_clob();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    -- #############################################################################
    -- #############################################################################
    /******************************************************************************
    NAME: INSERT_TRANSFER
    CREATION INFO: CARLOS FERREIRA 2007/01/27
    GOAL: INSERTS A TRANSFER BETWEEN TWO SERVICES
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    
    *********************************************************************************/

    PROCEDURE set_transfer_alert
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE
    ) IS
        l_flg_status            epis_prof_resp.flg_status%TYPE;
        l_flg_aceite            VARCHAR2(050) := 'F';
        l_flg_decline           VARCHAR2(050) := 'D';
        l_flg_cancel            VARCHAR2(050) := 'C';
        l_flg_requested         VARCHAR2(050) := 'R';
        l_flg_executed          VARCHAR2(050) := 'X';
        l_clinical_service_orig epis_prof_resp.id_clinical_service_orig%TYPE;
        l_clinical_service_dest epis_prof_resp.id_clinical_service_dest%TYPE;
        l_clinical_service      clinical_service.id_clinical_service%TYPE;
        l_sys_alert             sys_alert.id_sys_alert%TYPE;
        l_func_name             VARCHAR2(32) := 'SET_TRANSFER_ALERT';
        l_error                 t_error_out;
    BEGIN
        SELECT flg_status, epr.id_clinical_service_orig, epr.id_clinical_service_dest
          INTO l_flg_status, l_clinical_service_orig, l_clinical_service_dest
          FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
           AND epr.flg_transf_type = 'S';
    
        IF l_flg_status IN (l_flg_aceite, l_flg_decline, l_flg_cancel, l_flg_executed)
        THEN
            delete_hand_off_event(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_episode        => i_id_episode,
                                  i_epis_prof_resp => i_id_epis_prof_resp,
                                  i_id_sys_alert   => 27);
            delete_hand_off_event(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_episode        => i_id_episode,
                                  i_epis_prof_resp => i_id_epis_prof_resp,
                                  i_id_sys_alert   => 29);
        END IF;
        IF l_flg_status = l_flg_aceite
        THEN
            l_clinical_service := l_clinical_service_orig;
            l_sys_alert        := 29;
        ELSIF l_flg_status = l_flg_decline
        THEN
            l_clinical_service := l_clinical_service_orig;
            l_sys_alert        := 28;
        ELSIF l_flg_status = l_flg_requested
        THEN
            l_clinical_service := l_clinical_service_dest;
            l_sys_alert        := 27;
        END IF;
    
        IF l_sys_alert IS NOT NULL
        THEN
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => l_sys_alert,
                                                    i_id_episode          => i_id_episode,
                                                    i_id_record           => i_id_epis_prof_resp,
                                                    i_dt_record           => g_sysdate_tstz,
                                                    i_id_professional     => NULL,
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => l_clinical_service,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => NULL,
                                                    i_replace2            => NULL,
                                                    o_error               => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END set_transfer_alert;

    FUNCTION insert_transfer
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_requested   IN VARCHAR2,
        i_trf_reason         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_clinical_service   IN NUMBER,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INSERT_TRANSFER';
    
        l_ret BOOLEAN;
    
    BEGIN
    
        l_ret := insert_transfer_no_commit(i_lang,
                                           i_id_episode,
                                           i_id_patient,
                                           i_prof,
                                           i_id_department_orig,
                                           i_id_department_dest,
                                           i_id_prof_dest,
                                           i_dt_trf_requested,
                                           i_trf_reason,
                                           i_notes,
                                           i_clinical_service,
                                           i_flg_patient_consent,
                                           o_id_epis_prof_resp,
                                           o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END insert_transfer;

    --  
    FUNCTION check_presc_cancel
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER
    ) RETURN VARCHAR2 IS
        l_flg_type_origin department.flg_type%TYPE;
        l_flg_type_dest   department.flg_type%TYPE;
        l_id_market       market.id_market%TYPE;
        l_return          VARCHAR2(1char);
    
    BEGIN
        -- por omissão vai a N
        l_return := pk_alert_constant.g_no;
    
        -- get the flag_type of origin department
        l_flg_type_origin := pk_backoffice.get_department_type(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_department => i_id_department_orig);
    
        -- get the flag_type of origin department
        l_flg_type_dest := pk_backoffice.get_department_type(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_department => i_id_department_dest);
    
        IF (l_flg_type_dest IS NOT NULL AND l_flg_type_dest IS NOT NULL)
        THEN
            BEGIN
                SELECT pisi.flg_available
                  INTO l_return
                  FROM presc_interrupt_soft_inst pisi
                 WHERE pisi.flg_type_origin = l_flg_type_origin
                   AND pisi.flg_type_dest = l_flg_type_dest
                   AND pisi.flg_available = pk_alert_constant.g_yes
                   AND pisi.id_software = i_prof.software
                   AND pisi.id_institution = i_prof.institution;
            EXCEPTION
                WHEN no_data_found THEN
                    l_return := pk_alert_constant.g_no;
                
            END;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_return;
    END check_presc_cancel;

    FUNCTION insert_transfer_no_commit
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_requested   IN VARCHAR2,
        i_trf_reason         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_clinical_service   IN NUMBER,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INSERT_TRANSFER_NO_COMMIT';
        --
        l_epr                 epis_prof_resp%ROWTYPE;
        l_id_clinical_service NUMBER;
        --l_dt_trf_requested      DATE;
        l_dt_trf_requested_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        --
        CURSOR c_cat IS
            SELECT cat.flg_type
              FROM prof_cat pct, category cat
             WHERE pct.id_professional = i_prof.id
               AND pct.id_institution = i_prof.institution
               AND cat.id_category = pct.id_category;
        --
        l_desc_orig VARCHAR2(0100);
        l_desc_dest VARCHAR2(0100);
    BEGIN
    
        --l_dt_trf_requested      := nvl(to_char(i_dt_trf_requested, g_date_mask), SYSDATE);
        l_dt_trf_requested_tstz := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_trf_requested, NULL),
                                       current_timestamp);
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET NEXT IDS';
        SELECT seq_epis_prof_resp.nextval
          INTO l_epr.id_epis_prof_resp
          FROM dual;
        --
    
        SELECT dcs.id_clinical_service
          INTO l_id_clinical_service
          FROM epis_info ei, dep_clin_serv dcs
         WHERE ei.id_episode = i_id_episode
           AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv;
    
        g_error := 'GET FLG_TYPE';
        FOR cat IN c_cat
        LOOP
            l_epr.flg_type := cat.flg_type;
        END LOOP;
        --
        g_error                        := 'INIT. VARIABLES FOR INSERT';
        l_epr.id_episode               := i_id_episode;
        l_epr.dt_request_tstz          := current_timestamp;
        l_epr.id_prof_req              := i_prof.id;
        l_epr.id_prof_to               := i_id_prof_dest;
        l_epr.id_prof_comp             := NULL;
        l_epr.id_speciality            := NULL;
        l_epr.id_movement              := NULL;
        l_epr.notes_clob               := i_notes;
        l_epr.flg_status               := g_trf_requested;
        l_epr.id_prof_decline          := NULL;
        l_epr.dt_cancel_tstz           := NULL;
        l_epr.dt_decline_tstz          := NULL;
        l_epr.id_prof_cancel           := NULL;
        l_epr.notes_cancel             := NULL;
        l_epr.dt_comp_tstz             := NULL;
        l_epr.dt_trf_requested_tstz    := nvl(l_dt_trf_requested_tstz, current_timestamp);
        l_epr.dt_trf_accepted_tstz     := nvl(l_dt_trf_requested_tstz, current_timestamp);
        l_epr.trf_reason               := i_trf_reason;
        l_epr.trf_answer               := NULL;
        l_epr.id_room                  := NULL;
        l_epr.id_bed                   := NULL;
        l_epr.id_department_orig       := i_id_department_orig;
        l_epr.id_department_dest       := i_id_department_dest;
        l_epr.id_room_execute          := NULL;
        l_epr.id_bed_execute           := NULL;
        l_epr.flg_escort               := NULL;
        l_epr.flg_transf_type          := g_flg_transf_s;
        l_epr.id_clinical_service_orig := l_id_clinical_service;
        l_epr.id_clinical_service_dest := i_clinical_service;
        l_epr.flg_patient_consent      := i_flg_patient_consent;
        --
        o_id_epis_prof_resp := l_epr.id_epis_prof_resp;
        --    
        g_error := 'INSERTING DATA';
        INSERT INTO epis_prof_resp
            (id_epis_prof_resp,
             id_episode,
             dt_request_tstz,
             id_prof_req,
             id_prof_to,
             id_prof_comp,
             id_speciality,
             id_movement,
             notes_clob,
             flg_type,
             flg_status,
             id_prof_decline,
             dt_cancel_tstz,
             dt_decline_tstz,
             id_prof_cancel,
             notes_cancel,
             dt_comp_tstz,
             id_department_orig,
             id_department_dest,
             dt_trf_requested_tstz,
             dt_trf_accepted_tstz,
             trf_reason,
             trf_answer,
             id_room,
             id_bed,
             id_room_execute,
             id_bed_execute,
             flg_escort,
             flg_transf_type,
             id_clinical_service_orig,
             id_clinical_service_dest,
             flg_patient_consent)
        VALUES
            (l_epr.id_epis_prof_resp,
             l_epr.id_episode,
             l_epr.dt_request_tstz,
             l_epr.id_prof_req,
             l_epr.id_prof_to,
             l_epr.id_prof_comp,
             l_epr.id_speciality,
             l_epr.id_movement,
             l_epr.notes_clob,
             l_epr.flg_type,
             l_epr.flg_status,
             l_epr.id_prof_decline,
             l_epr.dt_cancel_tstz,
             l_epr.dt_decline_tstz,
             l_epr.id_prof_cancel,
             l_epr.notes_cancel,
             l_epr.dt_comp_tstz,
             l_epr.id_department_orig,
             l_epr.id_department_dest,
             l_epr.dt_trf_requested_tstz,
             l_epr.dt_trf_accepted_tstz,
             l_epr.trf_reason,
             l_epr.trf_answer,
             l_epr.id_room,
             l_epr.id_bed,
             l_epr.id_room_execute,
             l_epr.id_bed_execute,
             l_epr.flg_escort,
             l_epr.flg_transf_type,
             l_epr.id_clinical_service_orig,
             l_epr.id_clinical_service_dest,
             l_epr.flg_patient_consent);
        --
        SELECT pk_translation.get_translation(i_lang, code_department) x
          INTO l_desc_orig
          FROM department
         WHERE id_department = i_id_department_orig;
    
        g_error := 'GET DESC_DEST';
        SELECT pk_translation.get_translation(i_lang, code_department) x
          INTO l_desc_dest
          FROM department
         WHERE id_department = i_id_department_dest;
    
        g_error := 'CALL INSERT_SYS_ALERT_EVENT';
        pk_alertlog.log_debug(g_error);
        set_transfer_alert(i_lang, i_prof, i_id_episode, l_epr.id_epis_prof_resp);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => l_epr.flg_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END insert_transfer_no_commit;

    -- ##########################################################################################

    /******************************************************************************
    NAME: UPDATE_TRANSFER
    CREATION INFO: CARLOS FERREIRA 2007/01/27
    GOAL: UPDATES A TRANSFER BETWEEN TWO SERVICES
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    
    *********************************************************************************/
    FUNCTION update_transfer
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_id_epis_prof_resp  IN NUMBER,
        i_prof               IN profissional,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_accepted    IN VARCHAR2,
        i_trf_answer         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_cancel_notes       IN VARCHAR2,
        i_flg_status         IN VARCHAR2,
        i_id_room            IN NUMBER, -- ID DA SALA SUGERIDA
        i_id_bed             IN NUMBER, -- ID DA CAMA SUGERIDA
        i_flg_movement       IN VARCHAR2, -- QUER TRANSPORTE? Y/N
        i_type_mov           IN NUMBER, -- MACA, CADEIRA DE WHEELS, ...
        i_escort             IN VARCHAR2, -- ACOMPANHANTE
        i_id_dep_clin_serv   IN NUMBER, -- especialidade destino  
        i_id_cancel_reason   IN epis_prof_resp.id_cancel_reason%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'UPDATE_TRANSFER';
        l_transfer_exception EXCEPTION;
        l_ret BOOLEAN;
    
    BEGIN
    
        l_ret := update_transfer_no_commit(i_lang,
                                           i_id_episode,
                                           i_id_patient,
                                           i_id_epis_prof_resp,
                                           i_prof,
                                           i_id_department_dest,
                                           i_id_prof_dest,
                                           i_dt_trf_accepted,
                                           i_trf_answer,
                                           i_notes,
                                           i_cancel_notes,
                                           i_flg_status,
                                           i_id_room,
                                           i_id_bed,
                                           i_flg_movement,
                                           i_type_mov,
                                           i_escort,
                                           i_id_dep_clin_serv,
                                           i_id_cancel_reason,
                                           NULL,
                                           o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE l_transfer_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_transfer_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_transfer;

    FUNCTION update_transfer_no_commit
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_id_epis_prof_resp  IN NUMBER,
        i_prof               IN profissional,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_accepted    IN VARCHAR2,
        i_trf_answer         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_cancel_notes       IN VARCHAR2,
        i_flg_status         IN VARCHAR2,
        i_id_room            IN NUMBER, -- ID DA SALA SUGERIDA
        i_id_bed             IN NUMBER, -- ID DA CAMA SUGERIDA
        i_flg_movement       IN VARCHAR2, -- QUER TRANSPORTE? Y/N
        i_type_mov           IN NUMBER, -- MACA, CADEIRA DE WHEELS, ...
        i_escort             IN VARCHAR2, -- ACOMPANHANTE
        i_id_dep_clin_serv   IN NUMBER, -- especialidade destino  
        i_id_cancel_reason   IN epis_prof_resp.id_cancel_reason%TYPE,
        i_dt_trf_end         IN VARCHAR2 DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'UPDATE_TRANSFER_NO_COMMIT';
        --
        l_error     t_error_out;
        l_error_msg VARCHAR2(4000);
        l_ret       BOOLEAN;
        --jsilva 30-03-2007 novas variaveis locais
        l_id_movement       NUMBER;
        l_mov_flg_status    movement.flg_status%TYPE;
        l_flg_prof_cat_type category.flg_type%TYPE;
        l_count_movement    NUMBER;
        l_flg_aceite        VARCHAR2(0050);
        l_flg_decline       VARCHAR2(0050);
        l_flg_cancel        VARCHAR2(0050);
        l_flg_executed      VARCHAR2(0050);
        l_cat_type          VARCHAR2(0050);
        l_clinical_service  NUMBER;
        --l_dt_trf_accepted      DATE;
        l_dt_trf_accepted_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_trf_end_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_trf_executed_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        o_id_mov               NUMBER;
        o_flg_show             VARCHAR2(4000);
        o_msg                  VARCHAR2(4000);
        o_msg_title            VARCHAR2(4000);
        o_button               VARCHAR2(4000);
        error_set_end_transfer EXCEPTION;
        error_movement         EXCEPTION;
        error_movement_task    EXCEPTION;
        --
    
        CURSOR c_cat(i_flag IN NUMBER) IS
            SELECT cat.*
              FROM prof_cat pct, category cat
             WHERE i_flag = 0
               AND pct.id_professional = i_prof.id
               AND pct.id_category = cat.id_category;
        error_cancel_mov        EXCEPTION;
        error_transfer_movement EXCEPTION;
        l_auto_presc_cancel     VARCHAR2(1 CHAR);
        l_auto_presc_cancel_msg VARCHAR2(4000);
        l_id_department_orig    department.id_department%TYPE;
    xepr  epis_prof_resp%rowtype;
    BEGIN
        l_flg_aceite   := 'F';
        l_flg_decline  := 'D';
        l_flg_cancel   := 'C';
        l_flg_executed := 'X';
        o_id_mov       := NULL;
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --l_dt_trf_accepted      := to_date(i_dt_trf_accepted, g_date_mask);
        l_dt_trf_accepted_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_trf_accepted, NULL);
        l_dt_trf_end_tstz      := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_trf_end, NULL);
        l_dt_trf_executed_tstz := g_sysdate_tstz;
        --l_dt_trf_accepted_tstz := nvl(l_dt_trf_accepted_tstz, current_timestamp);
    
        IF i_id_dep_clin_serv IS NOT NULL
        THEN
            SELECT id_clinical_service
              INTO l_clinical_service
              FROM dep_clin_serv
             WHERE id_dep_clin_serv = i_id_dep_clin_serv;
        END IF;
        l_auto_presc_cancel_msg := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => 'COMMON_T033');
    
        IF i_flg_status = l_flg_executed
        THEN
            FOR cat IN c_cat(0)
            LOOP
                l_cat_type := cat.flg_type;
            END LOOP;
            IF i_flg_movement = 'Y'
            THEN
                l_ret := pk_movement.create_movement_no_commit(i_lang,
                                                               i_id_episode,
                                                               i_prof,
                                                               i_id_room,
                                                               i_type_mov,
                                                               i_dt_trf_accepted,
                                                               l_cat_type,
                                                               o_id_mov,
                                                               o_flg_show,
                                                               o_msg,
                                                               o_msg_title,
                                                               o_button,
                                                               l_error);
                IF l_ret = FALSE
                THEN
                    l_error_msg := pk_message.get_message(i_lang, 'TRANSFER_M001');
                    RAISE error_movement;
                END IF;
                l_ret := pk_movement.insert_movement_task(i_lang, i_id_episode, i_prof, l_cat_type, l_error);
                IF l_ret = FALSE
                THEN
                    RAISE error_movement_task;
                END IF;
            END IF;
        END IF;
    
        IF i_flg_status = l_flg_executed
           AND i_flg_movement <> 'Y'
        THEN
            IF NOT pk_hand_off.set_end_transfer(i_lang,
                                                i_prof,
                                                i_id_episode,
                                                o_id_mov,
                                                i_id_dep_clin_serv,
                                                i_flg_movement,
                                                i_id_bed,
                                                l_dt_trf_end_tstz,
                                                l_error)
            THEN
                RAISE error_set_end_transfer;
            END IF;
        
            l_dt_trf_executed_tstz := l_dt_trf_end_tstz;
        
            SELECT epr.id_department_orig
              INTO l_id_department_orig
              FROM epis_prof_resp epr
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp;
        
            --Validate if have to cancel medication prescrition
            l_auto_presc_cancel := check_presc_cancel(i_lang               => i_lang,
                                                      i_id_episode         => i_id_episode,
                                                      i_id_patient         => i_id_patient,
                                                      i_prof               => i_prof,
                                                      i_id_department_orig => l_id_department_orig,
                                                      i_id_department_dest => i_id_department_dest);
        
            IF (l_auto_presc_cancel = pk_alert_constant.g_yes)
            THEN
                --cancel/discontinue medication 
                IF NOT pk_api_pfh_in.set_cancel_presc(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_episode => i_id_episode,
                                                      i_notes      => l_auto_presc_cancel_msg,
                                                      o_error      => o_error)
                
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
     xepr := pk_hand_off_core.set_epis_prof_resp_h( i_id_epis_prof_resp );
     xepr.id_epis_prof_resp := i_id_epis_prof_resp;
     xepr.id_episode      := i_id_episode;
     xepr.id_prof_comp    := iif(i_flg_status = l_flg_aceite, i_prof.id, xepr.id_prof_comp);
     xepr.id_speciality   := NULL;
     xepr.id_movement     := nvl(o_id_mov, xepr.id_movement);
     xepr.transport_notes := iif(i_flg_status = l_flg_executed, i_notes, xepr.transport_notes);
     
        IF i_flg_status = l_flg_executed
           AND i_flg_movement = pk_alert_constant.g_yes
        THEN
        xepr.flg_status := g_hand_off_i;
     ELSE
          xepr.flg_status := i_flg_status;
     end if;
     
     xepr.id_prof_decline      := iif(i_flg_status= l_flg_decline , i_prof.id             , xepr.id_prof_decline);
     xepr.dt_cancel_tstz       := iif(i_flg_status= l_flg_cancel  , g_sysdate_tstz        , xepr.dt_cancel_tstz);
     xepr.dt_decline_tstz      := iif(i_flg_status= l_flg_decline , g_sysdate_tstz        , xepr.dt_decline_tstz);
     xepr.id_prof_execute      := iif(i_flg_status= l_flg_executed, i_prof.id             , xepr.id_prof_execute);
     xepr.dt_execute_tstz      := iif(i_flg_status= l_flg_executed, l_dt_trf_executed_tstz, xepr.dt_execute_tstz);
     xepr.id_prof_cancel       := iif(i_flg_status= l_flg_cancel  , i_prof.id             , xepr.id_prof_cancel);
     xepr.notes_cancel         := iif(i_flg_status= l_flg_cancel  , i_cancel_notes        , xepr.notes_cancel);
     xepr.dt_trf_accepted_tstz := iif(i_flg_status= l_flg_aceite  , l_dt_trf_accepted_tstz, xepr.dt_trf_accepted_tstz);
     xepr.dt_comp_tstz         := iif(i_flg_status= l_flg_aceite  , l_dt_trf_accepted_tstz, xepr.dt_comp_tstz);
     
     case i_flg_status
       when l_flg_aceite then
      xepr.trf_answer := i_trf_answer;
    when l_flg_decline then
      xepr.trf_answer := i_trf_answer;
    ELSE
      xepr.trf_answer := xepr.trf_answer;
    end case;
     
     xepr.id_room                  := iif(i_flg_status = l_flg_aceite, i_id_room, xepr.id_room );
     xepr.id_bed                   := iif(i_flg_status = l_flg_aceite, i_id_bed , xepr.id_bed );
     xepr.id_department_dest       := nvl( xepr.id_department_dest, i_id_department_dest );
     xepr.id_bed_execute           := iif(i_flg_status = l_flg_executed, i_id_bed , NULL );
     xepr.id_room_execute          := iif(i_flg_status = l_flg_executed, i_id_room, NULL );
     xepr.flg_escort               := i_escort;
     xepr.id_clinical_service_dest := nvl(l_clinical_service, xepr.id_clinical_service_dest);
     xepr.id_cancel_reason         := i_id_cancel_reason;
  
        UPDATE epis_prof_resp
           SET id_episode               = xepr.id_episode,
               id_prof_comp             = xepr.id_prof_comp,
               id_speciality            = xepr.id_speciality,
               id_movement              = xepr.id_movement,
               transport_notes          = xepr.transport_notes,
               flg_status               = xepr.flg_status,
               id_prof_decline          = xepr.id_prof_decline,
               dt_cancel_tstz           = xepr.dt_cancel_tstz,
               dt_decline_tstz          = xepr.dt_decline_tstz,
               id_prof_execute          = xepr.id_prof_execute,
               dt_execute_tstz          = xepr.dt_execute_tstz,
               id_prof_cancel           = xepr.id_prof_cancel,
               notes_cancel             = xepr.notes_cancel,
               dt_trf_accepted_tstz     = xepr.dt_trf_accepted_tstz,
               dt_comp_tstz             = xepr.dt_comp_tstz,
               trf_answer               = xepr.trf_answer,
               id_room                  = xepr.id_room,
               id_bed                   = xepr.id_bed,
               id_department_dest       = xepr.id_department_dest,
               id_bed_execute           = xepr.id_bed_execute,
               id_room_execute          = xepr.id_room_execute,
               flg_escort               = xepr.flg_escort,
               id_clinical_service_dest = xepr.id_clinical_service_dest,
               id_cancel_reason         = xepr.id_cancel_reason
         WHERE id_epis_prof_resp = i_id_epis_prof_resp;
    
     pk_hand_off_core.ins_epis_prof_resp_h( xepr );
    
        -- elimina o alerta 32 se este existir
        delete_hand_off_event(i_lang, i_prof, i_id_episode, i_id_epis_prof_resp);
    
        IF i_flg_status IN (l_flg_decline, l_flg_cancel, l_flg_executed, l_flg_aceite)
        THEN
            set_transfer_alert(i_lang, i_prof, i_id_episode, i_id_epis_prof_resp);
        END IF;
    
        -- VERIFICAR CRIAÇÃO DOS TRANSPORTES
        --jsilva 30-03-2007 cancelar o transporte quando se cancela a transferência
        IF i_flg_status = l_flg_cancel
        THEN
            SELECT COUNT(*)
              INTO l_count_movement
              FROM epis_prof_resp epr, movement m
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_movement = m.id_movement;
            IF l_count_movement > 0
            THEN
                SELECT m.flg_status, m.id_movement
                  INTO l_mov_flg_status, l_id_movement
                  FROM epis_prof_resp epr, movement m
                 WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
                   AND epr.id_movement = m.id_movement;
                SELECT c.flg_type
                  INTO l_flg_prof_cat_type
                  FROM prof_cat pc, category c
                 WHERE pc.id_category = c.id_category
                   AND pc.id_professional = i_prof.id
                   AND pc.id_institution IN (0, i_prof.institution);
                IF l_mov_flg_status != g_mov_status_transp
                THEN
                    l_ret := pk_movement.cancel_mov(i_lang, l_id_movement, i_prof, '', l_flg_prof_cat_type, o_error);
                    IF l_ret = FALSE
                    THEN
                        RAISE error_cancel_mov;
                    END IF;
                ELSE
                    l_error_msg := pk_message.get_message(i_lang, 'TRANSFER_M001');
                    RAISE error_transfer_movement;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN error_cancel_mov THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN error_transfer_movement THEN
        
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'TRANSFER_M001',
                                   l_error_msg,
                                   g_error,
                                   g_owner,
                                   g_package_name,
                                   l_func_name,
                                   'TRANSFER_M001',
                                   'U');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes quando aplicável-> s?faz ROLLBACK 
                pk_utils.undo_changes;
                -- return failure of function_dummy 
                RETURN l_ret;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_transfer_no_commit;
    -- ##########################################################################################

    /******************************************************************************
    NAME: GET_TRANSFER_STATUS_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF STATUS
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_transfer_status_list
    (
        i_lang              IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER,
        i_id_epis_prof_resp IN NUMBER,
        i_prof              IN profissional,
        i_flg_status        IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_screen            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_TRANSFER_STATUS_LIST';
        l_trf_domain   VARCHAR2(0500);
        l_scr_domain   VARCHAR2(0500);
        l_flg_request  VARCHAR2(0050);
        l_flg_accept   VARCHAR2(0050);
        l_flg_decline  VARCHAR2(0050);
        l_flg_cancel   VARCHAR2(0050);
        l_flg_executed VARCHAR2(0050);
        --
        CURSOR c_epr IS
            SELECT *
              FROM epis_prof_resp
             WHERE id_epis_prof_resp = i_id_epis_prof_resp;
    
        CURSOR c_dpt(i_id_department IN NUMBER) IS
            SELECT dpt.id_department, dcs.id_dep_clin_serv
              FROM department dpt, dep_clin_serv dcs, prof_dep_clin_serv pdc
             WHERE pdc.flg_status = 'S'
               AND pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dpt.id_department = dcs.id_department
               AND pdc.id_professional = i_prof.id
               AND dpt.id_institution = i_prof.institution
               AND dpt.id_department = i_id_department
               AND instr(dpt.flg_type, 'I') > 0;
        --
        --l_pat_my_service BOOLEAN;
        l_1 NUMBER;
        l_2 NUMBER;
    BEGIN
        l_1            := 0;
        l_2            := 0;
        l_flg_decline  := 'D';
        l_flg_request  := 'R';
        l_flg_accept   := 'F';
        l_flg_cancel   := 'C';
        l_flg_executed := 'X';
        --l_pat_my_service := FALSE;
        l_trf_domain := 'EPIS_PROF_RESP.TRANSFER_STATUS';
        l_scr_domain := 'EPIS_PROF_RESP.TRANSFER_STATUS_FILE';
    
        pk_types.open_my_cursor(o_screen);
    
        FOR epr IN c_epr
        LOOP
            FOR dpt1 IN c_dpt(epr.id_department_orig)
            LOOP
                l_1 := 1;
            END LOOP;
            FOR dpt1 IN c_dpt(epr.id_department_dest)
            LOOP
                l_2 := 1;
            END LOOP;
            IF l_1 = 1
               AND l_2 = 0
            THEN
                IF i_flg_status IN (l_flg_request, l_flg_cancel, l_flg_decline, l_flg_executed)
                THEN
                    pk_types.open_my_cursor(o_list);
                ELSIF i_flg_status = l_flg_accept
                THEN
                    NULL;
                    OPEN o_list FOR
                        SELECT sta.desc_val label, sta.val data, sta.img_name icon, fil.desc_val file_name, fil.val
                          FROM sys_domain sta, sys_domain fil
                         WHERE sta.id_language = i_lang
                           AND sta.code_domain = l_trf_domain
                           AND sta.domain_owner = pk_sysdomain.k_default_schema
                           AND sta.val = l_flg_executed
                           AND fil.id_language = i_lang
                           AND sta.val = fil.val
                           AND fil.code_domain = l_scr_domain
                           AND fil.domain_owner = pk_sysdomain.k_default_schema
                           AND fil.val = l_flg_executed;
                END IF;
            ELSIF l_1 = 0
                  AND l_2 = 1
            THEN
                IF i_flg_status IN (l_flg_accept, l_flg_decline, l_flg_executed, l_flg_cancel)
                THEN
                    pk_types.open_my_cursor(o_list);
                ELSIF i_flg_status = l_flg_request
                THEN
                    OPEN o_list FOR
                        SELECT sta.desc_val label, sta.val data, sta.img_name icon, fil.desc_val file_name, fil.val
                          FROM sys_domain sta, sys_domain fil
                         WHERE sta.id_language = i_lang
                           AND sta.code_domain = l_trf_domain
                           AND sta.domain_owner = pk_sysdomain.k_default_schema
                           AND sta.val IN (l_flg_accept, l_flg_decline)
                           AND fil.id_language = i_lang
                           AND sta.val = fil.val
                           AND fil.code_domain = l_scr_domain
                           AND fil.domain_owner = pk_sysdomain.k_default_schema
                           AND fil.val IN (l_flg_accept, l_flg_decline);
                END IF;
            ELSIF l_1 = 1
                  AND l_2 = 1
            THEN
                IF i_flg_status IN (l_flg_decline, l_flg_executed, l_flg_cancel)
                THEN
                    pk_types.open_my_cursor(o_list);
                ELSIF i_flg_status = l_flg_request
                THEN
                    OPEN o_list FOR
                        SELECT sta.desc_val label, sta.val data, sta.img_name icon, fil.desc_val file_name, fil.val
                          FROM sys_domain sta, sys_domain fil
                         WHERE sta.id_language = i_lang
                           AND sta.code_domain = l_trf_domain
                           AND sta.domain_owner = pk_sysdomain.k_default_schema
                           AND sta.val IN (l_flg_executed, l_flg_decline, l_flg_accept)
                           AND fil.id_language = i_lang
                           AND sta.val = fil.val
                           AND fil.code_domain = l_scr_domain
                           AND fil.domain_owner = pk_sysdomain.k_default_schema
                           AND fil.val IN (l_flg_executed, l_flg_decline, l_flg_accept);
                ELSIF i_flg_status = l_flg_accept
                THEN
                    OPEN o_list FOR
                        SELECT sta.desc_val label, sta.val data, sta.img_name icon, fil.desc_val file_name, fil.val
                          FROM sys_domain sta, sys_domain fil
                         WHERE sta.id_language = i_lang
                           AND sta.code_domain = l_trf_domain
                           AND sta.domain_owner = pk_sysdomain.k_default_schema
                           AND sta.val IN (l_flg_executed)
                           AND fil.id_language = i_lang
                           AND sta.val = fil.val
                           AND fil.code_domain = l_scr_domain
                           AND fil.domain_owner = pk_sysdomain.k_default_schema
                           AND fil.val IN (l_flg_executed);
                END IF;
            ELSIF l_1 = 0
                  AND l_2 = 0
            THEN
                pk_types.open_my_cursor(o_list);
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_transfer_status_list;

    -- #################################################################################
    /******************************************************************************
    NAME: SET_END_TRANSFER(
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF TRANSFERS FOR DESTINATION SERVICE
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION set_end_transfer
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        i_id_movement       IN NUMBER,
        i_id_dep_clin_serv  IN NUMBER,
        i_transfer_movement IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_bed            IN bed.id_bed%TYPE DEFAULT NULL,
        i_dt_end_transfer   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'SET_END_TRANSFER';
        l_count            NUMBER;
        l_ret              BOOLEAN;
        l_id_dep_clin_serv NUMBER;
        l_count_bed        NUMBER;
        l_dt_end_transfer  TIMESTAMP WITH LOCAL TIME ZONE;
        l_cur_id_bed       bed.id_bed%TYPE;
    
        epr epis_prof_resp%ROWTYPE;
        CURSOR c_spc(i_id_epis_prof_resp IN NUMBER) IS
            SELECT dcs.id_dep_clin_serv, epr.dt_end_transfer_tstz
              FROM dep_clin_serv dcs
             INNER JOIN epis_prof_resp epr
                ON (dcs.id_clinical_service = epr.id_clinical_service_dest)
             WHERE rownum < 2
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND dcs.id_department = epr.id_department_dest
               AND epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_episode = i_id_episode
             ORDER BY epr.id_epis_prof_resp DESC;
        --
        l_flg_status_bed bed.flg_status%TYPE;
        l_flg_bed_vacant bed.flg_status%TYPE;
        l_bed_allocation VARCHAR2(1);
        l_exception_info VARCHAR2(4000);
        l_rowids_ei      table_varchar;
        l_transaction_id VARCHAR2(4000);
        --
        no_transfer_found           EXCEPTION;
        too_many_transfer_found     EXCEPTION;
        error_set_bed_status_vacant EXCEPTION;
        error_allocate_bed          EXCEPTION;
        err_set_alert               EXCEPTION;
    
        l_id_department_orig epis_prof_resp.id_department_orig%TYPE;
    
        err_not_have_dept EXCEPTION;
        xepr epis_prof_resp%rowtype;
        l_id_department_dest dep_clin_serv.id_department%TYPE;
        l_id_bed_department  room.id_department%TYPE;
    
        l_deallocate_bed_department VARCHAR2(1 CHAR) := pk_sysconfig.get_config('TRANSFER_DEALLOCATE_BED_SAME_SERVICE',
                                                                                i_prof);
        --Get the Origin Institution
        FUNCTION get_origin_institution(i_id_department_orig IN epis_prof_resp.id_department_orig%TYPE
                                        
                                        ) RETURN institution.id_institution%TYPE IS
            l_institution institution.id_institution%TYPE;
        BEGIN
        
            g_error := 'GET ORIGIN INSTITUTION BY DEPARTMENT';
            pk_alertlog.log_debug(g_error);
        
            SELECT dp.id_institution
              INTO l_institution
              FROM department dp
             WHERE dp.id_department = i_id_department_orig;
        
            RETURN l_institution;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_origin_institution;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        l_flg_bed_vacant := 'V';
    
        IF i_id_movement IS NOT NULL
        THEN
            g_error := 'FIND IF EXIST SERVICE TRANSFER';
            SELECT COUNT(*)
              INTO l_count
              FROM epis_prof_resp
             WHERE id_episode = i_id_episode
               AND id_movement = nvl(i_id_movement, id_movement)
               AND flg_status NOT IN ('D', 'C', 'X')
               AND id_clinical_service_orig IS NOT NULL
               AND flg_transf_type = g_flg_transf_s;
        ELSE
            g_error := 'FIND IF EXIST SERVICE TRANSFER';
            SELECT COUNT(*)
              INTO l_count
              FROM epis_prof_resp
             WHERE id_episode = i_id_episode
               AND flg_status NOT IN ('D', 'C', 'X')
               AND id_clinical_service_orig IS NOT NULL
               AND flg_transf_type = g_flg_transf_s;
        END IF;
        g_error := 'NO TRANSFER FOUND SO GET OUT OF HERE';
        IF l_count = 0
           AND i_transfer_movement = pk_alert_constant.g_yes
        THEN
            RAISE no_transfer_found;
        END IF;
        g_error := 'NO TRANSFER FOUND SO GET OUT OF HERE';
        IF l_count > 1
        THEN
            RAISE too_many_transfer_found;
        END IF;
        IF i_id_movement IS NOT NULL
        THEN
            g_error := 'FIND RECORD';
            SELECT id_epis_prof_resp, id_department_orig
              INTO epr.id_epis_prof_resp, l_id_department_orig
              FROM epis_prof_resp
             WHERE id_episode = i_id_episode
               AND id_movement = nvl(i_id_movement, id_movement)
               AND flg_status NOT IN ('D', 'C', 'X')
               AND id_clinical_service_orig IS NOT NULL
               AND flg_transf_type = g_flg_transf_s;
        ELSE
            g_error := 'FIND RECORD';
            SELECT id_epis_prof_resp, id_department_orig
              INTO epr.id_epis_prof_resp, l_id_department_orig
              FROM epis_prof_resp
             WHERE id_episode = i_id_episode
               AND flg_status NOT IN ('D', 'C', 'X')
               AND id_clinical_service_orig IS NOT NULL
               AND flg_transf_type = g_flg_transf_s;
        END IF;
        g_error := 'FIND DEPARTMENT DEST';
        IF i_id_dep_clin_serv IS NULL
        THEN
            FOR spc IN c_spc(epr.id_epis_prof_resp)
            LOOP
                l_id_dep_clin_serv := spc.id_dep_clin_serv;
                l_dt_end_transfer  := spc.dt_end_transfer_tstz;
            END LOOP;
        ELSE
            l_id_dep_clin_serv := i_id_dep_clin_serv;
        END IF;
    
    SELECT id_department
      INTO l_id_department_dest
      FROM dep_clin_serv dcs
     WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv;

        IF l_dt_end_transfer IS NULL
        THEN
            ts_epis_info.upd(id_episode_in        => i_id_episode,
                             id_dep_clin_serv_in  => l_id_dep_clin_serv,
                             id_dep_clin_serv_nin => FALSE,
                             rows_out             => l_rowids_ei);
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_INFO',
                                          l_rowids_ei,
                                          o_error,
                                          table_varchar('ID_DEP_CLIN_SERV'));
        
            IF (i_transfer_movement = pk_alert_constant.g_no)
            THEN
                l_dt_end_transfer := nvl(i_dt_end_transfer, g_sysdate_tstz);
            ELSE
                l_dt_end_transfer := g_sysdate_tstz;
            END IF;
        
       xepr := pk_hand_off_core.set_epis_prof_resp_h( epr.id_epis_prof_resp );
       xepr.dt_end_transfer_tstz   := l_dt_end_transfer;
       xepr.flg_status             := 'X';
       xepr.id_epis_prof_resp      := epr.id_epis_prof_resp;
    
            UPDATE epis_prof_resp
               SET dt_end_transfer_tstz = l_dt_end_transfer, flg_status = 'X'
             WHERE id_epis_prof_resp = epr.id_epis_prof_resp;
        
       pk_hand_off_core.ins_epis_prof_resp_h( xepr);
        
            l_ret := set_alert(i_lang, i_prof, epr.id_epis_prof_resp, o_error);
            IF l_ret = FALSE
            THEN
                RAISE err_set_alert;
            END IF;
        
            IF l_id_department_orig IS NOT NULL
            THEN
                pk_alertlog.log_debug('patient_transfer_an');
                pk_ia_event_common.patient_transfer(i_id_epis_prof_resp => epr.id_epis_prof_resp,
                                                    i_id_episode        => i_id_episode,
                                                    i_id_institution    => get_origin_institution(l_id_department_orig));
            ELSE
            
                RAISE err_not_have_dept;
            END IF;
        
            SELECT ei.id_bed
              INTO l_cur_id_bed
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
        IF l_cur_id_bed IS NOT NULL -- departamento da cama em que o paciente se encontra
           AND l_cur_id_bed <> -1
        THEN
            SELECT r.id_department
              INTO l_id_bed_department
              FROM bed b
              JOIN room r
                ON b.id_room = r.id_room
             WHERE b.id_bed= l_cur_id_bed;
        
        END IF;
    
            IF nvl(l_cur_id_bed, -1) <> nvl(i_id_bed, -1)
           AND ((l_id_bed_department <> l_id_department_dest AND i_id_bed <> -1 AND
                l_deallocate_bed_department = pk_alert_constant.g_no) OR
                l_deallocate_bed_department = pk_alert_constant.g_yes)
            THEN
            
                IF NOT pk_bmng_pbl.set_episode_bed_status_vacant(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_episode     => i_id_episode,
                                                                 i_transaction_id => l_transaction_id,
                                                                 o_error          => o_error)
                
                THEN
                    RAISE error_set_bed_status_vacant;
                END IF;
            END IF;
        
            -- jsilva 30-03-2007 alocar a cama pedida (s?se esta estiver livre)
            SELECT COUNT(ep.id_bed_execute), b.flg_status
              INTO l_count_bed, l_flg_status_bed
              FROM epis_prof_resp ep, bed b
             WHERE ep.id_epis_prof_resp = epr.id_epis_prof_resp
               AND ep.id_bed_execute = b.id_bed(+)
             GROUP BY b.flg_status;
        
            --because of the case when there is no movement in the service transfer
            --this function is executed before the insertion of the id_bed_execute be filled
        
            IF (l_count_bed = 0 AND i_id_bed IS NOT NULL)
            THEN
                l_count_bed := 1;
            
                SELECT b.flg_status
                  INTO l_flg_status_bed
                  FROM bed b
                 WHERE b.id_bed = i_id_bed;
            END IF;
        
            IF l_count_bed > 0
               AND l_flg_status_bed = l_flg_bed_vacant
           AND (l_id_bed_department <> l_id_department_dest OR
           (l_deallocate_bed_department = pk_alert_constant.g_yes AND l_id_bed_department = l_id_department_dest))
            THEN
            
                SELECT nvl(id_bed_execute, i_id_bed)
                  INTO epr.id_bed_execute
                  FROM epis_prof_resp
                 WHERE id_epis_prof_resp = epr.id_epis_prof_resp;
            
                l_ret := pk_bed.allocate_bed(i_lang,
                                             i_prof,
                                             i_id_episode,
                                             epr.id_bed_execute,
                                             l_bed_allocation,
                                             l_exception_info,
                                             o_error);
                IF l_ret = FALSE
                THEN
                    RAISE error_allocate_bed;
                END IF;
            END IF;
        
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_transfer_found THEN
            -- se nao houver transferencia associada, nao ?erro.Sai com sucesso, sem erros           
            RETURN TRUE;
        WHEN too_many_transfer_found THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_end_transfer;
    -- ########################################################################################

    /**********************************************************************************************
    * EXECUTE_TRANSFER_INT
    * 
    * @param i_lang                   the id language
    * @param i_id_episode             Episode Id
    * @param i_id_patient             Patient Id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department_orig     Id department origin   
    * @param i_id_department_dest     Id department destiny
    * @param i_id_dep_clin_serv       Id dep_clin_serv
    * @param i_trf_reason             Id reason for transfer
    * @param i_id_bed                 Bed ID
    * 
    * @param i_id_epis_prof_resp      Epis_prof_resp ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @version                        2.5.0.7.8
    * @since                          2010/Mar/15
    **********************************************************************************************/
    FUNCTION execute_transfer_int
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_dep_clin_serv   IN NUMBER,
        i_trf_reason         IN VARCHAR2,
        i_id_bed             IN bed.id_bed%TYPE,
        i_dt_transfer        IN VARCHAR2,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'EXECUTE_TRANSFER_INT';
        --
        l_ret               BOOLEAN;
        l_id_epis_prof_resp NUMBER;
        l_id_movement       NUMBER;
        l_flg_executed      VARCHAR2(0050) := 'X';
        l_tranfer_movement  VARCHAR2(0050);
        l_id_room           NUMBER;
        l_id_epis_type_inp  NUMBER;
        l_count             NUMBER;
        l_dt_trf_end        VARCHAR2(100 CHAR);
        --
    BEGIN
    
        l_id_epis_type_inp := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_prof);
    
        l_ret := insert_transfer_no_commit(i_lang,
                                           i_id_episode,
                                           i_id_patient,
                                           i_prof,
                                           i_id_department_orig,
                                           i_id_department_dest,
                                           NULL,
                                           i_dt_transfer,
                                           i_trf_reason,
                                           NULL,
                                           NULL,
                                           i_flg_patient_consent,
                                           l_id_epis_prof_resp,
                                           o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE g_exception;
        END IF;
    
        l_tranfer_movement := pk_sysconfig.get_config('TRANSFER_MOVEMENT', i_prof);
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_type_room
         WHERE id_epis_type = l_id_epis_type_inp
           AND id_institution = i_prof.institution
           AND id_dep_clin_serv = i_id_dep_clin_serv;
    
        IF 1 = 0
        THEN
            NULL;
        ELSIF l_count = 1
        THEN
        
            -- Find room by default of specialty
            SELECT id_room
              INTO l_id_room
              FROM epis_type_room
             WHERE id_epis_type = l_id_epis_type_inp
               AND id_institution = i_prof.institution
               AND id_dep_clin_serv = i_id_dep_clin_serv;
        
        ELSIF l_count = 0
        THEN
        
            -- get room by default for hospital
            SELECT id_room
              INTO l_id_room
              FROM epis_type_room
             WHERE id_epis_type = l_id_epis_type_inp
               AND id_institution = i_prof.institution
               AND id_dep_clin_serv IS NULL;
        
        END IF;
    
        IF (l_tranfer_movement = pk_alert_constant.g_no)
        THEN
            l_dt_trf_end := i_dt_transfer;
        END IF;
    
        l_ret := update_transfer_no_commit(i_lang,
                                           i_id_episode,
                                           i_id_patient,
                                           l_id_epis_prof_resp,
                                           i_prof,
                                           i_id_department_dest,
                                           NULL,
                                           i_dt_transfer,
                                           NULL,
                                           NULL,
                                           NULL,
                                           l_flg_executed,
                                           l_id_room,
                                           i_id_bed,
                                           l_tranfer_movement,
                                           NULL,
                                           NULL,
                                           i_id_dep_clin_serv,
                                           NULL,
                                           l_dt_trf_end,
                                           o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_tranfer_movement = 'Y'
        THEN
        
            SELECT id_movement
              INTO l_id_movement
              FROM epis_prof_resp
             WHERE id_epis_prof_resp = l_id_epis_prof_resp;
        
            -- SE O MOVIMENTO TERMINADO EST?ASSOCIADO A UMA TRANSFERÊNCIA DE SERVIÇO, ACTUALIZA  O RESPECTIVO EPISODIO
            -- CARLOS FERREIRA 04-02-2007
            IF NOT pk_hand_off.set_end_transfer(i_lang,
                                                i_prof,
                                                i_id_episode,
                                                l_id_movement,
                                                i_id_dep_clin_serv,
                                                l_tranfer_movement,
                                                i_id_bed,
                                                NULL,
                                                o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        o_id_epis_prof_resp := l_id_epis_prof_resp;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END execute_transfer_int;

    /**********************************************************************************************
    * EXECUTE_TRANSFER_INT
    * 
    * @param i_lang                   the id language
    * @param i_id_episode             Episode Id
    * @param i_id_patient             Patient Id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department_orig     Id department origin   
    * @param i_id_department_dest     Id department destiny
    * @param i_id_dep_clin_serv       Id dep_clin_serv
    * @param i_trf_reason             Id reason for transfer
    *
    * @param  o_id_epis_prof_resp     ID epis_prof_resp
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          02-05-2007
    **********************************************************************************************/
    FUNCTION execute_transfer
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_dep_clin_serv   IN NUMBER,
        i_trf_reason         IN VARCHAR2,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'EXECUTE_TRANSFER';
        --
    BEGIN
    
        IF NOT execute_transfer_int(i_lang               => i_lang,
                                    i_id_episode         => i_id_episode,
                                    i_id_patient         => i_id_patient,
                                    i_prof               => i_prof,
                                    i_id_department_orig => i_id_department_orig,
                                    i_id_department_dest => i_id_department_dest,
                                    i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                    i_trf_reason         => i_trf_reason,
                                    i_id_bed             => NULL,
                                    i_dt_transfer        => NULL,
                                    i_flg_patient_consent => i_flg_patient_consent,
                                    o_id_epis_prof_resp  => o_id_epis_prof_resp,
                                    o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END execute_transfer;
    -- ########################################################################################

    /******************************************************************************
    NAME: GET_TRANSFER_DETAIL_EXEC
    CREATION INFO: JSILVA 03-05-2007
    GOAL: RETURNS THE RESUMED DETAIL OF A TRANSFER
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_transfer_detail_exec
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN NUMBER,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_TRANSFER_DETAIL_EXEC';
    BEGIN
        g_error := 'OPEN O_DATA';
        OPEN o_data FOR
            SELECT pk_translation.get_translation(i_lang, dpo.code_department) service_orig, -- serviço de origem
                   pk_translation.get_translation(i_lang, dpd.code_department) service_dest, -- serviço de destino
                   epr.trf_reason reason, -- motivo
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                  epr.id_clinical_service_orig) clinical_service_orig,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                  epr.id_clinical_service_dest) clinical_service_dest
              FROM department dpo, department dpd, epis_prof_resp epr
             WHERE epr.id_epis_prof_resp = i_id_epis_prof_resp
               AND epr.id_department_orig = dpo.id_department
               AND epr.id_department_dest = dpd.id_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_transfer_detail_exec;

    FUNCTION set_alert
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_ALERT';
    
        l_id_department_orig epis_prof_resp.id_department_orig%TYPE;
        l_id_department_dest epis_prof_resp.id_department_dest%TYPE;
    
        l_desc_orig  VARCHAR2(0100);
        l_desc_dest  VARCHAR2(0100);
        l_id_episode episode.id_episode%TYPE;
        --l_not_read            VARCHAR2(0001);
        --l_delete              VARCHAR2(0001);
        l_id_sys_alert        NUMBER;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
        l_id_epis_prof_resp NUMBER;
    
        -- JS, 2008-03-11: Reformulacao alertas. sys_alert_config substitui sys_alert_profile    
        --        CURSOR c_ppt(i_sys_alert IN NUMBER, i_profile_template IN NUMBER, i_dept_orig IN NUMBER, i_dept_dest IN NUMBER) IS
        --            SELECT a.*
        --              FROM sys_alert_prof a, sys_alert_profile b
        --             WHERE a.id_sys_alert = i_sys_alert
        --               AND a.id_institution = i_prof.institution
        --               AND b.id_profile_template = i_profile_template
        --               AND a.id_software = i_prof.software
        --               AND a.id_sys_alert = b.id_sys_alert
        --               AND b.id_institution = i_prof.institution
        --               AND a.id_professional IN
        --                   (SELECT DISTINCT pdcs.id_professional
        --                      FROM department dpt, dep_clin_serv dcs, prof_dep_clin_serv pdcs, prof_profile_template ppt
        --                     WHERE dpt.id_department IN (i_dept_orig, i_dept_dest)
        --                       AND dpt.id_institution = i_prof.institution
        --                       AND dpt.id_department = dcs.id_department
        --                       AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
        --                       AND ppt.id_professional = pdcs.id_professional
        --                       AND ppt.id_profile_template = i_profile_template
        --                       AND pdcs.flg_status = 'S');
    
        CURSOR c_ppt
        (
            i_sys_alert        IN NUMBER,
            i_profile_template IN NUMBER,
            i_dept_orig        IN NUMBER,
            i_dept_dest        IN NUMBER
        ) IS
            SELECT DISTINCT a.*
              FROM sys_alert_prof a, sys_alert_config b
             WHERE a.id_sys_alert = i_sys_alert
               AND a.id_software = i_prof.software
               AND a.id_institution = i_prof.institution
                  -- A proxima linha deve ser descomentada logo que esteja garantido que id_profile_template e sempre preenchido em sys_alert_prof               
                  --               AND a.i_profile_template = i_profile_template
               AND a.id_sys_alert = b.id_sys_alert
               AND b.id_software IN (i_prof.software, 0)
               AND b.id_institution IN (i_prof.institution, 0)
               AND b.id_profile_template IN (i_profile_template, 0)
               AND a.id_professional IN (SELECT DISTINCT pdcs.id_professional
                                           FROM dep_clin_serv dcs, prof_dep_clin_serv pdcs, prof_profile_template ppt
                                          WHERE dcs.id_department IN (i_dept_orig, i_dept_dest)
                                            AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                            AND ppt.id_professional = pdcs.id_professional
                                            AND ppt.id_profile_template = i_profile_template
                                            AND pdcs.flg_status = 'S'
                                            AND pdcs.id_institution = i_prof.institution);
    
        l_rowids_1           table_varchar;
        l_error              t_error_out;
        l_next_sys_alert_det sys_alert_det.id_sys_alert_det%TYPE;
    
    BEGIN
    
        g_error := 'INIT VAR';
        --l_not_read := 'N';
        --l_delete   := 'D';
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_epis_prof_resp IS NOT NULL
        THEN
        
            g_error               := 'INIT CONFIG VAR';
            l_id_profile_template := pk_sysconfig.get_config('ALERT_INP_TRANSFER_PROFILE', i_prof);
            l_id_sys_alert        := pk_sysconfig.get_config('ALERT_INP_TRANSFER', i_prof);
        
            g_error := 'GET DEPT ORIG AND DEST';
            SELECT id_department_orig, id_department_dest, id_episode
              INTO l_id_department_orig, l_id_department_dest, l_id_episode
              FROM epis_prof_resp
             WHERE id_epis_prof_resp = i_id_epis_prof_resp;
        
            g_error := 'GET DESC_ORIG';
            SELECT pk_translation.get_translation(i_lang, code_department) x
              INTO l_desc_orig
              FROM department
             WHERE id_department = l_id_department_orig;
        
            g_error := 'GET DESC_DEST';
            SELECT pk_translation.get_translation(i_lang, code_department) x
              INTO l_desc_dest
              FROM department
             WHERE id_department = l_id_department_dest;
        
            g_error := 'DO LOOP ALERT_PROFILE';
            FOR c IN c_ppt(l_id_sys_alert, l_id_profile_template, l_id_department_orig, l_id_department_dest)
            LOOP
            
                g_error := 'GET ID_REG_DET';
                SELECT seq_epis_prof_resp.nextval
                  INTO l_id_epis_prof_resp
                  FROM dual;
            
                -- *********************************
                -- PT 15/01/2009 2.4.3.d
                SELECT seq_sys_alert_det.nextval
                  INTO l_next_sys_alert_det
                  FROM dual;
            
                ts_sys_alert_det.ins(id_sys_alert_det_in => l_next_sys_alert_det,
                                     id_reg_in           => l_id_episode,
                                     id_episode_in       => l_id_episode,
                                     id_institution_in   => i_prof.institution,
                                     id_prof_in          => c.id_professional,
                                     dt_req_tstz_in      => g_sysdate_tstz,
                                     replace1_in         => l_desc_orig,
                                     replace2_in         => l_desc_dest,
                                     id_schedule_in      => NULL,
                                     id_sys_alert_in     => l_id_sys_alert,
                                     id_reg_det_in       => l_id_epis_prof_resp,
                                     rows_out            => l_rowids_1);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SYS_ALERT_DET',
                                              i_rowids     => l_rowids_1,
                                              o_error      => l_error);
                -- *********************************
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_alert;
    --

    /**
    * Returns the indo of the service and speciality responsible for the provided episode.
    *
    * @param      i_lang             Language
    * @param      i_prof             ID of professional
    * @param      i_epis              ID of the episode to check responsabilities
    * @param      o_data                 Cursor with all configurations requested
    * @param      o_error                t_error_out
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION get_epis_resp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE,
        o_data OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'QUERY VARIABLES';
        OPEN o_data FOR
            SELECT d.id_department dep_resp,
                   pk_translation.get_translation(i_lang, d.code_department) desc_dep_resp,
                   cs.id_clinical_service cs_resp,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_cs_resp,
                   dcs.id_dep_clin_serv dcs_resp,
                   ei.id_professional prof_resp,
                   prof.nick_name prof_resp_nick
              FROM epis_info ei
              LEFT JOIN professional prof
                ON prof.id_professional = ei.id_professional
              LEFT JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
              LEFT JOIN department d
                ON d.id_department = dcs.id_department
              LEFT JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
             WHERE ei.id_episode = i_epis;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_EPIS_RESP',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_epis_resp;
    --END RNA

    /********************************************************************************************
    * Checks if the professional has permission to request a physician hand off.
    * Only applies to the CREATE button. The permission for other buttons (Ok/Cancel)
    * is returned in GET_EPIS_PROF_RESP_ALL.
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional, institution and software ids
    * @param   i_episode            Episode ID
    * @param   i_flg_type           Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param   o_flg_create         Request permission: Y - yes, N - No
    * @param   o_create_actions     Options to display in the CREATE button
    * @param   o_error              Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          18-08-2009
    *
    * @alter                          Jos?Brito
    * @version                        2.5.0.7
    * @since                          23-10-2009
    **********************************************************************************************/
    FUNCTION get_hand_off_req_permission
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN category.flg_type%TYPE,
        o_flg_create     OUT VARCHAR2,
        o_create_actions OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cat                  category.flg_type%TYPE;
        l_id_profile_template  profile_template.id_profile_template%TYPE;
        l_id_professional_resp professional.id_professional%TYPE;
        l_flg_status           epis_prof_resp.flg_status%TYPE;
        l_prof_req             epis_prof_resp.id_prof_req%TYPE;
        l_hand_off_type        sys_config.value%TYPE;
        l_flg_profile          profile_template.flg_profile%TYPE;
        l_flg_status_epis      episode.flg_status%TYPE;
        l_prof_name            professional.name%TYPE;
        l_tab_id_profiles      table_number;
        l_tab_flg_profiles     table_varchar;
        l_id_speciality        epis_multi_prof_resp.id_speciality%TYPE;
    
        l_count NUMBER(6);
        l_ret   VARCHAR2(1 CHAR) := g_no;
    
        l_req_epis_self  VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_req_epis_other VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_req_overall_self  VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_req_overall_other VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_has_permission_epis    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_has_permission_overall VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_no_results CONSTANT NUMBER(6) := 0;
    
        l_tab_actions table_number;
    
        l_handoff_no_permission sys_config.value%TYPE;
        l_tab_handoff_no_perm   table_number;
    
        l_internal_error EXCEPTION;
    
    BEGIN
        g_error := 'GET_CONFIG';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type); -- Get type of hand-off
    
        g_error := 'GET PROF_CAT';
        l_cat   := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error               := 'GET PROF PROFILE_TEMPLATE';
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error         := 'GET PROF SPECIALITY';
        l_id_speciality := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof);
    
        g_error                 := 'GET HANDOFF NO PERMISSION PROFILES';
        l_handoff_no_permission := TRIM('|' FROM pk_sysconfig.get_config('PROFILE_TEMPLATE_HANDOFF_PERMISSION',
                                                                i_prof.institution,
                                                                i_prof.software));
        l_tab_handoff_no_perm   := pk_utils.str_split_n(i_list => l_handoff_no_permission, i_delim => '|');
    
        -- Jos?Brito 20/10/2009 ALERT-39320 Support for multiple hand-off mechanism
        IF l_hand_off_type = g_handoff_multiple
        THEN
            g_error := 'GET TYPE OF PROFILE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_profile_template => l_id_profile_template,
                                                    o_flg_profile      => l_flg_profile,
                                                    o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            l_flg_profile := NULL;
        END IF;
    
        IF l_hand_off_type = g_handoff_multiple
        THEN
            -- Check the permissions (EPISODE AND OVERALL) to make hand-off requests for the current professional
            IF i_prof.software NOT IN (pk_alert_constant.g_soft_oris)
            THEN
                g_error := 'CHECK REQUEST PERMISSION (EPISODE)';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.check_request_permission(i_lang                 => i_lang,
                                                                 i_prof                 => i_prof,
                                                                 i_id_episode           => i_episode,
                                                                 i_id_profile_templ_req => l_id_profile_template,
                                                                 i_prof_cat_req         => l_cat,
                                                                 i_flg_type             => i_flg_type,
                                                                 i_flg_resp_type        => pk_hand_off_core.g_resp_episode,
                                                                 i_flg_profile          => l_flg_profile,
                                                                 i_hand_off_type        => l_hand_off_type,
                                                                 i_id_speciality        => l_id_speciality,
                                                                 o_full_permission      => l_has_permission_epis,
                                                                 o_req_to_self          => l_req_epis_self,
                                                                 o_req_to_other         => l_req_epis_other,
                                                                 o_error                => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            g_error := 'CHECK REQUEST PERMISSION (OVERALL)';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.check_request_permission(i_lang                 => i_lang,
                                                             i_prof                 => i_prof,
                                                             i_id_episode           => i_episode,
                                                             i_id_profile_templ_req => l_id_profile_template,
                                                             i_prof_cat_req         => l_cat,
                                                             i_flg_type             => i_flg_type,
                                                             i_flg_resp_type        => pk_hand_off_core.g_resp_overall,
                                                             i_flg_profile          => l_flg_profile,
                                                             i_hand_off_type        => l_hand_off_type,
                                                             i_id_speciality        => l_id_speciality,
                                                             o_full_permission      => l_has_permission_overall,
                                                             o_req_to_self          => l_req_overall_self,
                                                             o_req_to_other         => l_req_overall_other,
                                                             o_error                => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'GET MULTIPLE HAND-OFF CREATE ACTIONS';
            pk_alertlog.log_debug(g_error);
            SELECT a.id_action
              BULK COLLECT
              INTO l_tab_actions
              FROM action a
             WHERE (a.subject = 'HANDOFF_CREATE_RESP_EPISODE' AND
                   i_prof.software NOT IN (pk_alert_constant.g_soft_oris))
                OR (a.subject = 'HANDOFF_CREATE_RESP_OVERALL' AND i_flg_type = pk_alert_constant.g_cat_type_doc)
                OR (a.subject = 'HANDOFF_ASSIGN_RESPONSIBILITY' AND
                   l_id_profile_template IN (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
                                               column_value
                                                FROM TABLE(l_tab_handoff_no_perm) t));
        
            IF l_tab_actions.exists(1)
            THEN
                -- If there are actions available, ENABLE button CREATE...
                o_flg_create := pk_alert_constant.g_yes;
            
                g_error := 'OPEN O_CREATE_ACTIONS (M)';
                pk_alertlog.log_debug(g_error);
                OPEN o_create_actions FOR
                    SELECT a.id_action,
                           a.id_parent,
                           a.to_state,
                           (SELECT pk_message.get_message(i_lang, i_prof, code_action)
                              FROM dual) desc_action,
                           a.icon,
                           a.flg_default,
                           decode(l_has_permission_epis,
                                  pk_alert_constant.g_yes,
                                  decode(a.to_state, 'S', l_req_epis_self, 'O', l_req_epis_other, pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) flg_active,
                           a.internal_name action,
                           a.rank
                      FROM action a
                     WHERE a.subject = 'HANDOFF_CREATE_RESP_EPISODE'
                       AND a.id_action IN (SELECT t.column_value
                                             FROM TABLE(l_tab_actions) t)
                    UNION ALL
                    SELECT a.id_action,
                           a.id_parent,
                           a.to_state,
                           (SELECT pk_message.get_message(i_lang, i_prof, code_action)
                              FROM dual) desc_action,
                           a.icon,
                           a.flg_default,
                           decode(l_has_permission_overall,
                                  pk_alert_constant.g_yes,
                                  decode(a.to_state,
                                         'S',
                                         decode(l_flg_profile,
                                                pk_hand_off_core.g_specialist,
                                                l_req_overall_self,
                                                pk_alert_constant.g_no),
                                         'O',
                                         l_req_overall_other,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) flg_active,
                           a.internal_name action,
                           a.rank
                      FROM action a
                     WHERE a.subject = 'HANDOFF_CREATE_RESP_OVERALL'
                       AND a.id_action IN (SELECT t.column_value
                                             FROM TABLE(l_tab_actions) t)
                    UNION ALL
                    SELECT a.id_action,
                           a.id_parent,
                           a.to_state,
                           (SELECT pk_message.get_message(i_lang, i_prof, code_action)
                              FROM dual) desc_action,
                           a.icon,
                           a.flg_default,
                           g_yes flg_active,
                           a.internal_name action,
                           a.rank
                      FROM action a
                     WHERE a.subject = 'HANDOFF_ASSIGN_RESPONSIBILITY'
                       AND a.id_action IN (SELECT t.column_value
                                             FROM TABLE(l_tab_actions) t)
                     ORDER BY rank;
            
            ELSE
                -- ... and DISABLE if user has no actions available.
                o_flg_create := pk_alert_constant.g_no;
                pk_types.open_my_cursor(o_create_actions);
            
            END IF;
        
        ELSE
            ------------------
            -- NORMAL hand-off
            ------------------
            g_error := 'CHECK HAND-OFF REQUEST COUNT (N)';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(*)
              INTO l_count
              FROM epis_prof_resp epr
             WHERE epr.id_episode = i_episode
               AND epr.flg_type = i_flg_type
               AND epr.flg_transf_type IN (g_flg_transf_i, g_flg_transf_a)
               AND epr.flg_status = g_hand_off_r;
        
            g_error := 'GET RESPONSIBLE PROFESSIONAL';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_episode    => i_episode,
                                                          i_prof_cat      => i_flg_type,
                                                          i_flg_profile   => NULL,
                                                          i_hand_off_type => l_hand_off_type,
                                                          i_flg_resp_type => NULL,
                                                          i_id_speciality => NULL,
                                                          o_epis_status   => l_flg_status_epis,
                                                          o_id_prof_resp  => l_id_professional_resp,
                                                          o_prof_name     => l_prof_name,
                                                          o_error         => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_count = 0 -- There are no requests for this category.
            THEN
                IF l_cat = i_flg_type
                   AND l_id_professional_resp = i_prof.id
                THEN
                    -- If i'm responsible for the episode, I can make requests to
                    -- to professionals of the same category as mine.
                    l_req_epis_self  := g_no;
                    l_req_epis_other := g_yes;
                
                ELSIF l_cat = i_flg_type
                      AND nvl(l_id_professional_resp, -1) <> i_prof.id
                THEN
                    -- If i'm not responsible and can set myself as responsible, but cannot make requests.
                
                    IF pk_utils.search_table_number(i_table => l_tab_handoff_no_perm, i_search => l_id_profile_template) > 0
                    THEN
                        l_req_epis_self := g_no;
                    ELSE
                        l_req_epis_self := g_yes;
                    END IF;
                
                    l_req_epis_other := g_no;
                
                ELSIF l_cat <> i_flg_type
                THEN
                    -- If i'm of a different category, check the profiles for who I can request hand-off
                    g_error := 'GET PERMISSIONS';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_hand_off_core.get_allowed_profiles(i_lang                 => i_lang,
                                                                 i_prof                 => i_prof,
                                                                 i_id_profile_templ_req => l_id_profile_template,
                                                                 i_flg_type             => i_flg_type,
                                                                 o_profiles             => l_tab_id_profiles,
                                                                 o_error                => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                    IF l_tab_id_profiles.exists(1)
                    THEN
                        IF l_tab_id_profiles.count > 0
                        THEN
                            -- I have permissions to make requests for profiles of the current I_FLG_TYPE
                            l_ret := g_yes;
                        ELSE
                            l_ret := g_no;
                        END IF;
                    ELSE
                        l_ret := g_no; -- If I don't have azny permissions, then I can't make hand-off requests.
                    END IF;
                
                    l_req_epis_self  := g_no; -- If i'm of a different category, i can never set myself as responsible.
                    l_req_epis_other := l_ret; -- But i can or not make requests according to my permissions.
                
                END IF;
            
            ELSE
                -- Already exists a request for this category. It's not possible to make another request,
                -- regardless of the permissions.
                l_req_epis_self  := g_no;
                l_req_epis_other := g_no;
            END IF;
        
            g_error := 'GET NORMAL HAND-OFF CREATE ACTIONS';
            pk_alertlog.log_debug(g_error);
            OPEN o_create_actions FOR
                SELECT a.id_action,
                       a.id_parent,
                       a.to_state,
                       (SELECT pk_message.get_message(i_lang, i_prof, code_action)
                          FROM dual) desc_action,
                       a.icon,
                       a.flg_default,
                       decode(a.to_state,
                              'S',
                              l_req_epis_self,
                              'O',
                              l_req_epis_other,
                              'F',
                              g_yes,
                              pk_alert_constant.g_no) flg_active,
                       a.internal_name action,
                       a.rank
                  FROM action a
                 WHERE a.subject = 'HANDOFF_CREATE_RESP_EPISODE'
                   AND i_prof.software NOT IN (pk_alert_constant.g_soft_oris)
                    OR (a.subject = 'HANDOFF_ASSIGN_RESPONSIBILITY' AND
                       l_id_profile_template IN (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
                                                   column_value
                                                    FROM TABLE(l_tab_handoff_no_perm) t))
                 ORDER BY rank;
        
            o_flg_create := CASE i_prof.software
                                WHEN pk_alert_constant.g_soft_oris THEN
                                 pk_alert_constant.g_no
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HAND_OFF_REQ_PERMISSION',
                                              o_error);
            pk_types.open_my_cursor(o_create_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HAND_OFF_REQ_PERMISSION',
                                              o_error);
            pk_types.open_my_cursor(o_create_actions);
            RETURN FALSE;
    END get_hand_off_req_permission;

    /********************************************************************************************
    * Gets the professional's preferred department / clinical service.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_episode                 Episode ID
    * @param i_dest_professional       Destination professional ID
    * @param i_flg_type                Type of transfer
    * @param i_handoff_type            Type of hand-off
    * @param i_handoff_nurse_config    Nurse hand-off configuration (department/clinical service)
    * @param o_id_clinical_service     Clinical service ID
    * @param o_id_department           Department ID
    * @param o_error_message           User error message to display
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           14-Nov-2011
    *
    **********************************************************************************************/
    FUNCTION get_preferred_prof_dcs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_dest_professional    IN professional.id_professional%TYPE,
        i_flg_type             IN epis_prof_resp.flg_type%TYPE,
        i_handoff_type         IN VARCHAR2,
        i_handoff_nurse_config IN VARCHAR2,
        o_id_clinical_service  OUT clinical_service.id_clinical_service%TYPE,
        o_id_department        OUT department.id_department%TYPE,
        o_error_message        OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_PREFERRED_PROF_DCS';
    
        l_epis_software epis_info.id_software%TYPE;
        l_id_dcs        dep_clin_serv.id_dep_clin_serv%TYPE;
        l_new_id_cs     clinical_service.id_clinical_service%TYPE;
        l_new_id_dpt    department.id_department%TYPE;
    
        FUNCTION check_pref_dcs(i_dcs IN NUMBER) RETURN BOOLEAN IS
            l_id_dcs NUMBER;
            l_bool   BOOLEAN := TRUE;
            l_return BOOLEAN := TRUE;
        BEGIN
        
            l_id_dcs := pk_prof_utils.get_prof_dcs(profissional(i_dest_professional,
                                                                i_prof.institution,
                                                                nvl(l_epis_software, i_prof.software)));
        
            IF l_id_dcs IS NULL
            THEN
            
                l_bool := coalesce(alert_context('ADMISSION_ADT_YN'), 'N') = 'Y';
                IF l_bool
                THEN
                    l_id_dcs := i_dcs;
                END IF;
                l_return := l_bool;
            
            END IF;
        
            IF l_return
            THEN
            
                g_error := 'GET ID_DEP_CLIN_SERV';
                pk_alertlog.log_debug(g_error);
                SELECT dcs.id_clinical_service, dcs.id_department
                  INTO l_new_id_cs, l_new_id_dpt
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = l_id_dcs;
            
            END IF;
        
            RETURN l_return;
        
        END check_pref_dcs;
    
    BEGIN
    
        -- Get preferred specialty/department
        IF i_handoff_type = g_handoff_normal
           OR i_flg_type = g_flg_type_n
        THEN
            g_error := 'GET EPIS SOFTWARE';
            SELECT ei.id_software, ei.id_dep_clin_serv
              INTO l_epis_software, l_id_dcs
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        
            /*
            l_id_dcs := pk_prof_utils.get_prof_dcs(profissional(i_dest_professional,
                                                                i_prof.institution,
                                                                nvl(l_epis_software, i_prof.software)));
            */
            IF NOT check_pref_dcs(l_id_dcs)
            THEN
                    o_error_message := pk_message.get_message(i_lang, 'EDIS_HAND_OFF_M085');
                    RETURN FALSE;
            END IF;
        
            -- Update value of ID_DEPARTMENT
            CASE i_flg_type
                WHEN g_flg_type_d THEN
                    l_new_id_dpt := NULL;
                WHEN g_flg_type_n THEN
                    CASE i_handoff_nurse_config
                        WHEN g_handoff_nurse_department THEN
                            l_new_id_dpt := l_new_id_dpt;
                        ELSE
                            l_new_id_dpt := NULL;
                    END CASE;
                ELSE
                    l_new_id_dpt := NULL;
            END CASE;
        
            -- Update value of ID_CLINICAL_SERVICE
            CASE i_flg_type
                WHEN g_flg_type_d THEN
                    l_new_id_cs := l_new_id_cs;
                WHEN g_flg_type_n THEN
                    CASE i_handoff_nurse_config
                        WHEN g_handoff_nurse_clin_serv THEN
                            l_new_id_cs := l_new_id_cs;
                        ELSE
                            l_new_id_cs := NULL;
                    END CASE;
                ELSE
                    l_new_id_cs := NULL;
            END CASE;
        
        ELSIF i_handoff_type = g_handoff_multiple
          --    AND i_flg_type = g_flg_type_d
        THEN
            l_new_id_cs  := NULL;
            l_new_id_dpt := NULL;
        END IF;
    
        o_id_clinical_service := l_new_id_cs;
        o_id_department       := l_new_id_dpt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_preferred_prof_dcs;

    /*
    * Get episode dep_clin_serv based on a specific time
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_EPISODE            Episode ID
    * @param   I_DT_TARGET          Date that we want to check 
    * @param   I_DT_TARGET_TSTZ     Date that we want to check in TSTZ (optional)
    *
    * @RETURN  episode id_dep_clin_serv
    *
    * @author  Sérgio Santos
    * @version 2.6.1
    * @since   18-05-2012
    *
    */
    FUNCTION get_epis_dcs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN movement.id_episode%TYPE,
        i_dt_target      IN VARCHAR2,
        i_dt_target_tstz IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE IS
        -- target date    
        l_dt_target TIMESTAMP WITH LOCAL TIME ZONE;
    
        -- transf info
        l_trf_ids   table_number;
        l_trf_times table_varchar;
        l_trf_res   movement.id_movement%TYPE;
    
        --temp values
        l_department      department.id_department%TYPE;
        l_clincal_service clinical_service.id_clinical_service%TYPE;
    
        --return value
        l_dcs dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
    
        IF i_dt_target_tstz IS NULL
        THEN
            l_dt_target := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_dt_target,
                                                         i_timezone  => NULL);
        ELSE
            l_dt_target := i_dt_target_tstz;
        END IF;
    
        -- Obter transferencias de serciço
        g_error := 'GET FINISHED TRANSFERS';
        SELECT epr.id_epis_prof_resp, epr.dt_end_transfer_tstz
          BULK COLLECT
          INTO l_trf_ids, l_trf_times
          FROM epis_prof_resp epr
         WHERE epr.id_department_dest IS NOT NULL
           AND epr.flg_status = 'X'
           AND epr.id_episode = i_episode
         ORDER BY epr.dt_execute_tstz ASC;
    
        -- Se não existam transferencias, a localização do paciente ?dada pela epis_info
        -- caso contrário verificamos as transferencias.
        -- Se a data inserida for superior aos das transferencias também usa a epis_info
        IF (l_trf_ids IS NULL OR l_trf_ids.count = 0)
           OR l_dt_target IS NULL
           OR l_dt_target > l_trf_times(l_trf_times.count)
        THEN
            g_error := 'GET DCS BASED ON EPIS_INFO';
            SELECT ei.id_dep_clin_serv
              INTO l_dcs
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        ELSE
            g_error := 'GET TIME MOVEMENT';
            FOR i IN 1 .. l_trf_ids.count
            LOOP
                IF l_dt_target < l_trf_times(i)
                THEN
                    l_trf_res := l_trf_ids(i);
                    EXIT;
                END IF;
            END LOOP;
        
            g_error := 'GET DCS BASED ON TRANSFERS';
            IF l_trf_res IS NOT NULL
            THEN
                SELECT epr.id_department_orig, epr.id_clinical_service_orig
                  INTO l_department, l_clincal_service
                  FROM epis_prof_resp epr
                 WHERE epr.id_epis_prof_resp = l_trf_res;
            
                SELECT id_dep_clin_serv
                  INTO l_dcs
                  FROM (SELECT dcs.id_dep_clin_serv, decode(dcs.flg_available, pk_alert_constant.g_yes, 0, 1) rank
                          FROM dep_clin_serv dcs
                         WHERE dcs.id_department = l_department
                           AND dcs.id_clinical_service = l_clincal_service
                         ORDER BY rank ASC)
                 WHERE rownum <= 1;
            END IF;
        END IF;
    
        RETURN l_dcs;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_dcs;
    --
    /********************************************************************************************
    * Returns the overall responsible for a patient
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    *
    * @param   o_id_prof_resp             ID of the responsible professional
    * @param   o_prof_resp_name           Name of the overall responsible professional
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Sergio Dias
    * @version                        2.6.3.7.1
    * @since                          23-Aug-2013
    **********************************************************************************************/
    FUNCTION get_overall_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_id_prof_resp   OUT professional.id_professional%TYPE,
        o_prof_resp_name OUT professional.name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_PROF_RESP_BY_TYPE';
    BEGIN
        g_error := 'GET_OVERALL_RESPONSIBLE';
        pk_alertlog.log_debug(g_error);
    
        SELECT t.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
          INTO o_id_prof_resp, o_prof_resp_name
          FROM (SELECT empr.id_professional,
                       row_number() over(ORDER BY decode(empr.flg_main_responsible, pk_alert_constant.g_yes, 1, 2) ASC, empr.dt_create DESC) rn
                  FROM episode e
                  JOIN epis_multi_prof_resp empr
                    ON empr.id_episode = e.id_episode
                 WHERE e.id_episode = i_id_episode
                   AND empr.flg_status = pk_alert_constant.g_active
                   AND empr.flg_profile = pk_hand_off_core.g_specialist
                   AND empr.flg_resp_type = pk_hand_off_core.g_resp_overall
                 ORDER BY empr.dt_create DESC) t
         WHERE t.rn = 1; -- to prevent conflict with main responsible which may not be the overall responsible anymore
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_overall_responsible;
    --
    /********************************************************************************************
    * Returns the episode responsible
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    *
    * @param   o_error                    Error message
    *                        
    * @return  Episode responsible ID
    * 
    * @author                         Sergio Dias
    * @version                        2.6.3.8.1
    * @since                          20-Sept-2013
    **********************************************************************************************/
    FUNCTION get_episode_responsible
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(200) := 'GET_EPISODE_RESPONSIBLE';
        l_return    NUMBER;
    BEGIN
    
        BEGIN
            SELECT t.id_prof_to
              INTO l_return
              FROM (SELECT epr.id_epis_prof_resp,
                           epr.id_prof_to,
                           epr.id_episode,
                           row_number() over(PARTITION BY epr.id_episode ORDER BY epr.dt_comp_tstz DESC) row_number
                      FROM epis_prof_resp epr
                     WHERE epr.flg_status = pk_hand_off.g_hand_off_f
                       AND epr.id_prof_comp IS NOT NULL
                       AND epr.dt_end_transfer_tstz IS NULL) t
             WHERE t.id_episode = i_id_episode
               AND t.row_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_return := 0;
        END;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN NULL;
    END get_episode_responsible;

    /********************************************************************************************
    * Returns professional responsible for patient
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_scope                    Scope - 'P'
    * @param   i_id_scope                 id - patient_id
    *
    *                        
    * @return  Episode responsible ID
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0
    * @since                          05-May-2014
    **********************************************************************************************/
    FUNCTION get_prof_resp_cda
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_scope    IN VARCHAR2,
        i_id_scope IN patient.id_patient%TYPE
        
    ) RETURN t_resp_professional_cda IS
    
        l_episodes   table_number := table_number();
        l_epis_profs t_resp_professional_cda;
        l_error      t_error_out;
        l_exception EXCEPTION;
        --
        l_inst institution.id_institution%TYPE;
        l_soft software.id_software%TYPE;
    BEGIN
        IF (i_scope IS NULL OR i_id_scope IS NULL)
        THEN
            g_error := ' SCOPE FLAG/ID IS NULL';
            RAISE g_exception;
        
        ELSIF i_scope NOT IN (g_episode_scope, g_visit_scope, g_patient_scope)
        THEN
            g_error := 'i_scope MUST BE E,V or P (EPISODE SCOPE, VISIT SCOPE OR PATIENT SCOPE)';
            RAISE l_exception;
        END IF;
    
        g_error := 'FIND PATIENT EPISODES - BASED ON SCOPE PASSED';
        IF i_scope = g_patient_scope
        THEN
            g_error    := 'CALL PK_PATIENT.GET_EPISODE_LIST - USING PATIENT SCOPE';
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_id_scope,
                                                      i_id_episode        => NULL,
                                                      i_id_visit          => NULL,
                                                      i_flg_visit_or_epis => i_scope);
        ELSIF i_scope = g_visit_scope
        THEN
            g_error    := 'CALL PK_PATIENT.GET_EPISODE_LIST - USING VISIT SCOPE';
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => NULL,
                                                      i_id_episode        => NULL,
                                                      i_id_visit          => i_id_scope,
                                                      i_flg_visit_or_epis => i_scope);
        ELSIF i_scope = g_episode_scope
        THEN
            g_error    := 'CALL PK_PATIENT.GET_EPISODE_LIST - USING EPISODE SCOPE';
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => NULL,
                                                      i_id_episode        => i_id_scope,
                                                      i_id_visit          => NULL,
                                                      i_flg_visit_or_epis => i_scope);
        END IF;
    
        IF l_episodes.exists(1)
        THEN
            g_error      := 'GET PROF RESP EPISODES';
            l_epis_profs := pk_hand_off_core.get_all_responsibles_id(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_id_episode_table => l_episodes);
        ELSE
            l_epis_profs := NULL;
        END IF;
    
        RETURN l_epis_profs;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_PROF_RESP_CDA',
                                              l_error);
            RETURN NULL;
    END get_prof_resp_cda;

    /********************************************************************************************
    * Gets all professionals reponsibles by scope - 'P'- patient, 'E'- episode, 'V'- visit
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_scope                    Scope - 'P'- patient, 'E'- episode, 'V'- visit
    * @param   i_id_scope                 Scope identifier
    * @param   o_prof_resp                Information about professional responsibles
    * @param   o_error                    Error message
    *                        
    * @return  Cursor that contains professional name, id, institution and software 
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.2.1
    * @since                          16-OCT-2014
    **********************************************************************************************/
    FUNCTION get_prof_responsibles
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_scope     IN VARCHAR2,
        i_id_scope  IN patient.id_patient%TYPE,
        o_prof_resp OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_PROF_RESPONSIBLES';
    
    BEGIN
        g_error := 'GET PROFESSIONAL RESPONSIBLES BY SCOPE';
    
        OPEN o_prof_resp FOR
            SELECT t.id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id) name,
                   --pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => t.id) name, 
                   t.institution,
                   t.software
              FROM TABLE(pk_hand_off.get_prof_resp_cda(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_scope    => i_scope,
                                                       i_id_scope => i_id_scope)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_responsibles;

    FUNCTION check_cur_service_resp
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_department_dest       IN epis_prof_resp.id_department_dest%TYPE,
        i_id_clinical_service_dest IN epis_prof_resp.id_clinical_service_dest%TYPE
    ) RETURN BOOLEAN IS
        l_id_department_dest       epis_prof_resp.id_department_dest%TYPE;
        l_id_clinical_service_dest epis_prof_resp.id_clinical_service_dest%TYPE;
    BEGIN
        BEGIN
            SELECT id_department_dest, id_clinical_service_dest
              INTO l_id_department_dest, l_id_clinical_service_dest
              FROM (SELECT epr.id_epis_prof_resp,
                           epr.id_department_dest,
                           epr.id_clinical_service_dest,
                           row_number() over(ORDER BY epr.dt_execute_tstz DESC) rn
                      FROM epis_prof_resp epr
                     WHERE epr.id_department_dest IS NOT NULL
                       AND epr.flg_status = 'X'
                       AND epr.id_episode = i_id_episode
                       AND epr.flg_transf_type = g_flg_transf_s)
             WHERE rn <= 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_department_dest       := NULL;
                l_id_clinical_service_dest := NULL;
        END;
    
        IF l_id_department_dest IS NULL
           AND l_id_clinical_service_dest IS NULL
        THEN
            SELECT d.id_department, d.id_clinical_service
              INTO l_id_department_dest, l_id_clinical_service_dest
              FROM epis_info e
              JOIN dep_clin_serv d
                ON d.id_dep_clin_serv = e.id_first_dep_clin_serv
             WHERE e.id_episode = i_id_episode;
        END IF;
    
        IF l_id_department_dest = i_id_department_dest
           AND (l_id_clinical_service_dest IS NOT NULL AND l_id_clinical_service_dest = i_id_clinical_service_dest)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END check_cur_service_resp;

    /********************************************************************************************
    * Get all transfer responsability in a episode (attending/ resident)
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_id_episode episode idenfier
    *
    * @return             Type with the transfer responsability information (attending/ resident)
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01
    **********************************************************************************************/
    FUNCTION get_prof_resp_list_by_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_resp    IN epis_multi_prof_resp.dt_update%TYPE,
        i_admission  IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_prof_name table_varchar;
        l_resp_type table_varchar;
        l_resp      VARCHAR2(4000 CHAR);
        l_res_num   NUMBER := 0;
        l_sep       VARCHAR2(10 CHAR);
    
        PROCEDURE prof_list_to_str
        (
            i_list IN table_varchar,
            i_type IN table_varchar
        ) IS
        BEGIN
            FOR i IN i_list.first .. i_list.last
            LOOP
                IF i_type(i) = pk_hand_off_core.g_resp_episode
                   AND l_res_num = 0
                THEN
                    l_res_num := 1;
                    l_sep     := ' // ';
                ELSE
                    l_sep := ', ';
                END IF;
                IF l_resp IS NOT NULL
                THEN
                    l_resp := l_resp || l_sep;
                END IF;
                l_resp := l_resp || i_list(i);
            END LOOP;
        END prof_list_to_str;
    
    BEGIN
        SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional), flg_resp_type
          BULK COLLECT
          INTO l_prof_name, l_resp_type
          FROM (SELECT DISTINCT emph.id_professional, emph.flg_resp_type, emph.priority
                  FROM epis_multi_profresp_hist emph
                 WHERE emph.dt_update = i_dt_resp
                   AND emph.flg_status <> pk_hand_off_core.g_outdated
                   AND emph.id_episode = i_id_episode)
         ORDER BY flg_resp_type DESC, priority;
    
        IF l_prof_name.exists(1)
        THEN
            prof_list_to_str(l_prof_name, l_resp_type);
        ELSE
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional), flg_resp_type
              BULK COLLECT
              INTO l_prof_name, l_resp_type
              FROM (SELECT DISTINCT emph.id_professional,
                                     dt_update,
                                     emph.flg_resp_type,
                                     emph.priority,
                                     dense_rank() over(PARTITION BY emph.id_episode ORDER BY emph.dt_update DESC) rn,
                                     dense_rank() over(PARTITION BY emph.id_episode ORDER BY emph.dt_update ASC) rna
                       FROM epis_multi_profresp_hist emph
                      WHERE --emph.dt_update <= i_dt_resp
                      ((pk_date_utils.compare_dates_tsz(i_prof, emph.dt_update, i_dt_resp) IN
                      (pk_alert_constant.g_date_lower, pk_alert_constant.g_date_equal) AND
                      i_admission = pk_alert_constant.g_no) OR
                      ((pk_date_utils.compare_dates_tsz(i_prof, emph.dt_update, i_dt_resp) IN
                      (pk_alert_constant.g_date_equal) AND i_admission = pk_alert_constant.g_yes)))
                   AND emph.flg_status <> pk_hand_off_core.g_outdated
                   AND emph.id_episode = i_id_episode
                   AND emph.priority IS NOT NULL
                      ORDER BY emph.flg_resp_type DESC, emph.priority)
             WHERE (rn = 1 AND i_admission = pk_alert_constant.g_no)
                OR (rna = 1 AND i_admission = pk_alert_constant.g_yes);
        
            IF l_prof_name.exists(1)
            THEN
                prof_list_to_str(l_prof_name, l_resp_type);
            END IF;
        
        END IF;
    
        RETURN l_resp;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_resp_list_by_date;

    /********************************************************************************************
    * Gets the transfer responsability  location in a date(attending/ resident)
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_dt_transf  date
    * @param i_admission  in on admission (Y/N) 
    *
    * @return             Attending and Resident on that time
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01
    **********************************************************************************************/
    FUNCTION tf_get_responsability_transf
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf IS
        l_func_name       VARCHAR2(30) := 'TF_GET_RESPONSABILITY_TRANSF';
        l_error           t_error_out;
        l_tbl_resp_transf t_table_epis_transf;
        l_transf_resp     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'EDIS_HAND_OFF_T069');
        l_transf_service  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'EDIS_HAND_OFF_T070');
        l_id_type_serv_trans CONSTANT NUMBER(24) := 3;
        l_id_type_prof_resp  CONSTANT NUMBER(24) := 4;
    BEGIN
        SELECT t_rec_epis_transf(id_episode,
                                 decode(flg_resp_type,
                                        pk_hand_off_core.g_trans_type_s,
                                        l_id_type_serv_trans,
                                        l_id_type_prof_resp),
                                 dt_record => dt_update,
                                 decode(flg_resp_type, pk_hand_off_core.g_trans_type_s, l_transf_service, l_transf_resp),
                                 decode(flg_resp_type,
                                        pk_hand_off_core.g_trans_type_s,
                                        '',
                                        pk_hand_off.get_prof_resp_list_by_date(i_lang, i_prof, id_episode, dt_update)))
        
          BULK COLLECT
          INTO l_tbl_resp_transf
          FROM (SELECT dt_update, flg_resp_type, id_episode
                  FROM (SELECT emph.dt_update,
                               emph.flg_resp_type,
                               emph.priority,
                               emph.id_episode,
                               row_number() over(PARTITION BY emph.dt_update ORDER BY emph.dt_update, emph.dt_create, emph.flg_resp_type, emph.priority) rn
                          FROM epis_multi_profresp_hist emph
                          JOIN epis_multi_prof_resp empr
                            ON emph.id_epis_multi_prof_resp = empr.id_epis_multi_prof_resp
                          JOIN epis_prof_resp epr
                            ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                         WHERE epr.id_episode = i_id_episode
                           AND emph.flg_status <> pk_hand_off_core.g_outdated
                           AND emph.priority IS NOT NULL) t
                 WHERE rn = 1
                UNION
                SELECT epr.dt_end_transfer_tstz, epr.flg_transf_type, epr.id_episode
                  FROM epis_prof_resp epr
                 WHERE epr.id_episode = i_id_episode
                   AND epr.flg_transf_type = pk_hand_off_core.g_trans_type_s
                   AND epr.flg_status <> g_hand_off_c);
    
        RETURN l_tbl_resp_transf;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
    END tf_get_responsability_transf;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package_name);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package_name);

    g_yes := 'Y';
    g_no  := 'N';
    --
    g_epis_active   := 'A';
    g_epis_inactive := 'I';
    g_hand_off_r    := 'R'; -- Requisitado
    g_hand_off_c    := 'C'; -- Cancelado
    g_hand_off_d    := 'D'; -- Rejeitado
    g_hand_off_f    := 'F'; -- Final
    g_hand_off_x    := 'X'; -- Executada
    g_hand_off_t    := 'T'; -- Executada
    g_hand_off_i    := 'I'; -- In transit
    --
    g_no_triage            := '0x787864';
    g_no_triage_color_text := '0xFFFFFF';
    g_color_rank           := 999;
    --
    g_epis_type     := 2;
    g_epis_diag_act := 'A';
    --
    g_diag_flg_type := 'P';
    g_flg_resp_g    := 'G';
    g_flg_resp_h    := 'H';
    --
    g_flg_type_s := 'S';
    g_flg_type_d := 'D';
    g_flg_type_n := 'N';
    g_flg_type_q := 'Q';
    --
    g_analy_req_det_status := 'ANALYSIS_REQ_DET.FLG_STATUS';
    g_interv_det_status    := 'INTERV_PRESC_DET.FLG_STATUS';
    g_exam_req_det_status  := 'EXAM_REQ_DET.FLG_STATUS';
    --
    g_interv_plan_pend  := 'D';
    g_interv_plan_final := 'F';
    g_interv_plan_req   := 'R';
    g_interv_plan_canc  := 'C';
    g_interv_plan_ext   := 'X';
    --    
    g_exam_type       := 'E';
    g_image_exam_type := 'I';
    g_exam_type_ortho := 'O';
    g_exam_type_aud   := 'A';
    g_exam_type_pf    := 'F';
    g_exam_type_gas   := 'G';
    g_exam_det_read   := 'L';
    g_exam_det_pend   := 'D';
    g_exam_det_req    := 'R';
    g_exam_det_exec   := 'E';
    g_exam_stat_canc  := 'C';
    --
    g_analy_req_det_canc  := 'C';
    g_analy_req_det_req   := 'R';
    g_analy_req_det_pend  := 'D';
    g_analy_req_det_read  := 'L';
    g_analy_req_det_exec  := 'E';
    g_analy_req_det_final := 'F';
    --
    g_drug_stat_canc := 'C';
    --
    g_ed_flg_status_co := 'F'; --confirmar
    g_ed_flg_status_d  := 'D'; --declinar(-)
    --
    g_transfer_n        := 'N'; -- Desvio ("Roubar o paciente a um outro profissional) ou 1?responsavél pelo paciente
    g_transfer_y        := 'Y'; -- Pedido de transferência de responsabilidade
    g_mov_status_transp := 'T';

    g_flg_transf_i    := 'I';
    g_flg_transf_s    := 'S';
    g_flg_transf_o    := 'O';
    g_flg_transf_a    := 'A';
    g_flg_anamnesis_c := 'C';
    g_trf_requested   := 'R';
    g_flg_unknown_y   := 'Y';
    --
    g_handoff_nurse_clin_serv  := 'CS';
    g_handoff_nurse_department := 'D';
    --
    g_prof_cat_doc := 'D';
    g_prof_cat_nrs := 'N';
    --
    g_software_inp  := 11;
    g_software_edis := 8;

END pk_hand_off;
/
