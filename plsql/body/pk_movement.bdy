/*-- Last Change Revision: $Rev: 2045707 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-09-20 17:19:31 +0100 (ter, 20 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_movement IS

    FUNCTION set_new_location
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message    debug_msg;
        l_epis_type  episode.id_epis_type%TYPE;
        l_id_episode episode.id_episode%TYPE := i_episode;
    BEGIN
        l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        IF (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            l_id_episode := pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_episode);
        END IF;
    
        IF NOT set_new_location_no_commit(i_lang          => i_lang,
                                          i_episode       => l_id_episode,
                                          i_prof          => i_prof,
                                          i_room          => i_room,
                                          i_prof_cat_type => i_prof_cat_type,
                                          o_flg_show      => o_flg_show,
                                          o_msg           => o_msg,
                                          o_msg_title     => o_msg_title,
                                          o_button        => o_button,
                                          o_error         => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        IF NOT set_location_visit(i_lang    => i_lang,
                                  i_prof    => i_prof,
                                  i_episode => l_id_episode,
                                  i_room    => i_room,
                                  o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_NEW_LOCATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_new_location;

    FUNCTION set_new_location_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Criar movimento e actualizar info do utente, no caso dos desvios 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                       I_PROF - ID do profissional 
                     I_ROOM - sala de destino 
                     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida:   O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe  
                     O_MSG - mensagem  
                     O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                             O_FLG_SHOW = Y 
                     O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                            Tb pode mostrar combinações destes, qd é p/ mostrar 
                          + do q 1 botão 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/01 
          NOTAS: 
        *********************************************************************************/
        l_seq                 movement.id_movement%TYPE;
        l_id_mov_transp       movement.id_movement%TYPE;
        l_room                movement.id_room_to%TYPE;
        l_prof_req            profissional;
        l_dt_req_tstz         TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof_move           profissional;
        l_id_new_mov          movement.id_movement%TYPE;
        l_exist_request       VARCHAR2(1);
        l_flg_show            VARCHAR2(1);
        l_msg_title           VARCHAR2(2000);
        l_button              VARCHAR2(6);
        l_id_mov              movement.id_movement%TYPE;
        l_flg_type            episode.id_epis_type%TYPE;
        l_flg_status          episode.flg_status%TYPE;
        l_id_room             epis_info.id_room%TYPE;
        l_desc_room           VARCHAR2(200);
        l_dt_entrance_room    VARCHAR2(50);
        l_dt_last_interaction VARCHAR2(50);
        l_dt_movement         VARCHAR2(50);
        l_count_oris          NUMBER;
        l_flg_recovery        room.flg_recovery%TYPE;
        l_action              VARCHAR2(1);
    
        l_sys_alert_event_row sys_alert_event%ROWTYPE;
    
        l_rows table_varchar;
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
        l_sysdate_char CONSTANT VARCHAR2(14) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                            i_date => l_sysdate_tstz,
                                                                            i_prof => i_prof);
    
    BEGIN
        -- Verificar se é possível criar o movimento pretendido 
        l_message := 'CALL TO CHECK_MOV';
        IF NOT check_mov(i_lang        => i_lang,
                         i_episode     => i_episode,
                         i_room        => i_room,
                         i_prof        => i_prof,
                         o_id_movement => l_id_mov,
                         o_flg_show    => o_flg_show,
                         o_msg_text    => o_msg,
                         o_msg_title   => o_msg_title,
                         o_button      => o_button,
                         o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF o_flg_show = pk_alert_constant.g_no
        THEN
            -- Movimento válido 
            -- Localização actual do doente 
            l_message := 'CALL TO PK_VISIT.GET_EPIS_INFO';
            IF NOT pk_visit.get_epis_info(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_prof                => i_prof,
                                          o_flg_type            => l_flg_type,
                                          o_flg_status          => l_flg_status,
                                          o_id_room             => l_id_room,
                                          o_desc_room           => l_desc_room,
                                          o_dt_entrance_room    => l_dt_entrance_room,
                                          o_dt_last_interaction => l_dt_last_interaction,
                                          o_dt_movement         => l_dt_movement,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- Criar mov de desvio 
            l_message := 'GET SEQUENCE NEXTVAL';
        
            l_seq := ts_movement.next_key();
        
            /* <DENORM Fábio> */
            ts_movement.ins(id_episode_in      => i_episode,
                            id_room_from_in    => nvl(l_id_room, -1),
                            id_room_to_in      => i_room,
                            id_prof_request_in => i_prof.id,
                            dt_req_tstz_in     => l_sysdate_tstz,
                            flg_status_in      => pk_alert_constant.g_mov_status_finish,
                            id_prof_move_in    => i_prof.id,
                            dt_begin_tstz_in   => l_sysdate_tstz,
                            id_prof_receive_in => i_prof.id,
                            dt_end_tstz_in     => l_sysdate_tstz,
                            id_movement_out    => l_seq,
                            rows_out           => l_rows);
        
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'MOVEMENT', l_rows, o_error => o_error);
        
            l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
            IF NOT pk_visit.update_epis_info_no_obs(i_lang         => i_lang,
                                                    i_id_episode   => i_episode,
                                                    i_id_room      => i_room,
                                                    i_bed          => NULL,
                                                    i_norton       => NULL,
                                                    i_professional => NULL,
                                                    i_flg_hydric   => NULL,
                                                    i_flg_wound    => NULL,
                                                    i_companion    => NULL,
                                                    i_flg_unknown  => NULL,
                                                    i_desc_info    => NULL,
                                                    i_prof         => i_prof,
                                                    o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
            IF NOT pk_visit.update_epis_info_no_obs(i_lang                 => i_lang,
                                                    i_id_episode           => i_episode,
                                                    i_id_prof              => i_prof,
                                                    i_dt_entrance_room     => l_sysdate_char,
                                                    i_dt_last_interaction  => l_sysdate_char,
                                                    i_dt_movement          => l_sysdate_char,
                                                    i_dt_harvest           => NULL,
                                                    i_dt_next_drug         => NULL,
                                                    i_dt_first_obs         => NULL, -- AS: 2009-06-02: ALERT-31077; l_sysdate_char,
                                                    i_dt_next_intervention => NULL,
                                                    i_dt_next_vital_sign   => NULL,
                                                    i_dt_next_position     => NULL,
                                                    i_dt_harvest_mov       => NULL,
                                                    i_dt_first_nurse_obs   => NULL,
                                                    i_prof_cat_type        => i_prof_cat_type,
                                                    o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- Verificar o doente está actualmente a ser transportado 
            l_message := 'CALL TO GET_TRANSP_MOV';
            IF NOT get_transp_mov(i_lang     => i_lang,
                                  i_episode  => i_episode,
                                  o_movement => l_id_mov_transp,
                                  o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF nvl(l_id_mov_transp, 0) != 0
            THEN
                -- Existe mov "em transporte" 
                -- Se existe pedido "em transporte", fica "interrompido"  
                l_message := 'UPDATE MOVEMENT(1)';
                /* <DENORM Fábio> */
                l_rows := table_varchar();
                ts_movement.upd(id_movement_in     => l_id_mov_transp,
                                flg_status_in      => pk_alert_constant.g_mov_status_interr,
                                dt_cancel_tstz_in  => l_sysdate_tstz,
                                id_prof_cancel_in  => i_prof.id,
                                dt_cancel_tstz_nin => FALSE,
                                id_prof_cancel_nin => FALSE,
                                rows_out           => l_rows);
            
                t_data_gov_mnt.process_update(i_lang, i_prof, 'MOVEMENT', l_rows, o_error => o_error);
            
                SELECT profissional(id_prof_move, i_prof.institution, i_prof.software),
                       profissional(id_prof_request, i_prof.institution, i_prof.software),
                       id_room_to,
                       dt_req_tstz
                  INTO l_prof_move, l_prof_req, l_room, l_dt_req_tstz
                  FROM movement
                 WHERE ROWID IN (SELECT r.column_value
                                   FROM TABLE(l_rows) r);
            
                -- JS: 2008-03-28: Delete alerts for "PATIENT_MOV" (Alert id 9)
                l_message                          := 'DELETE ALERTS(PATIENT_MOV)';
                l_sys_alert_event_row.id_sys_alert := 9;
                l_sys_alert_event_row.id_episode   := i_episode;
                l_sys_alert_event_row.id_record    := l_id_mov_transp;
            
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        o_error           => o_error)
                THEN
                    pk_alertlog.log_error('Error deleting alerts');
                    pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                          l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                          l_sys_alert_event_row.id_record);
                    --pk_alertlog.log_error(l_error);
                    RETURN FALSE;
                END IF;
            
                -- Se havia movimento em transporte, o prof. de transporte do desvio criado é o mesmo q 
                -- estava já a transportar o doente 
                l_message := 'UPDATE MOVEMENT(2)';
                /* <DENORM Fábio> */
                l_rows := table_varchar();
                ts_movement.upd(id_prof_move_in  => l_prof_move.id,
                                id_movement_in   => l_seq,
                                id_prof_move_nin => FALSE,
                                rows_out         => l_rows);
            
                t_data_gov_mnt.process_update(i_lang, i_prof, 'MOVEMENT', l_rows, o_error => o_error);
            
                -- Actualiza todos os movimentos que estejam "pendentes" para "requisitados" 
                l_message := 'UPDATE MOVEMENT(3)';
                /* <DENORM Fábio> */
                l_rows := table_varchar();
                ts_movement.upd(flg_status_in => pk_alert_constant.g_mov_status_req,
                                where_in      => 'flg_status = ''' || pk_alert_constant.g_mov_status_pend ||
                                                 ''' AND id_episode = ' || i_episode,
                                rows_out      => l_rows);
            
                t_data_gov_mnt.process_update(i_lang, i_prof, 'MOVEMENT', l_rows, o_error => o_error);
            
                -- JS: 2008-03-28: Insert alert event for "PATIENT_MOV" (Alert id 9)
                l_message                          := 'INSERT ALERT(PATIENT_MOV)';
                l_sys_alert_event_row.id_sys_alert := 9;
                l_sys_alert_event_row.id_episode   := i_episode;
                l_sys_alert_event_row.id_record    := l_seq;
                l_sys_alert_event_row.dt_record    := l_sysdate_tstz;
                l_sys_alert_event_row.replace1     := pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                              i_prof.institution,
                                                                              i_prof.software);
            
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        i_flg_type_dest   => NULL,
                                                        o_error           => o_error)
                THEN
                    pk_alertlog.log_error('Error inserting alert');
                    pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                          l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                          l_sys_alert_event_row.id_record);
                    --pk_alertlog.log_error(l_error);
                    RETURN FALSE;
                END IF;
            
                -- Criar movimento correspondente ao q foi "interrompido" 
                l_message := 'CALL TO CREATE_MOVEMENT';
                IF NOT create_movement(i_lang          => i_lang,
                                       i_episode       => i_episode,
                                       i_prof          => l_prof_req,
                                       i_room          => l_room,
                                       i_necessity     => NULL,
                                       i_dt_req_str    => pk_date_utils.date_send_tsz(i_lang, l_dt_req_tstz, i_prof),
                                       i_prof_cat_type => i_prof_cat_type,
                                       o_id_mov        => l_id_new_mov,
                                       o_flg_show      => l_flg_show,
                                       o_msg           => o_msg,
                                       o_msg_title     => l_msg_title,
                                       o_button        => l_button,
                                       o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                -- NOTA: não se testa O_FLG_SHOW, pq as situações q interrompem a criação deste mov. já 
                -- foram verificadas para a criação do desvio 
            
                -- Se o movimento interrompido está associado a requisições de exame/análise, 
                -- estas passam a estar associadas ao novo mov 
                l_message := 'CALL TO CHECK_MOV_REQUEST';
                IF NOT check_mov_request(i_lang      => i_lang,
                                         i_movement  => l_id_mov_transp,
                                         o_flg_exist => l_exist_request,
                                         o_error     => o_error)
                THEN
                    RETURN FALSE;
                ELSE
                    l_message := 'CHECK_MOV_REQUEST TRUE';
                    IF l_exist_request = 'A'
                    THEN
                        l_message := 'UPDATE ANALYSIS_REQ_DET';
                        /* <DENORM Fábio> */
                        l_rows := table_varchar();
                        ts_analysis_req_det.upd(id_movement_in  => l_id_new_mov,
                                                id_movement_nin => FALSE,
                                                where_in        => 'id_movement = ' || l_id_mov_transp,
                                                rows_out        => l_rows);
                    
                        t_data_gov_mnt.process_update(i_lang, i_prof, 'ANALYSIS_REQ_DET', l_rows, o_error => o_error);
                    END IF;
                
                    IF l_exist_request = 'E'
                    THEN
                        l_message := 'UPDATE EXAM_REQ_DET';
                        /* <DENORM Fábio> */
                        l_rows := table_varchar();
                        ts_exam_req_det.upd(id_movement_in  => l_id_new_mov,
                                            id_movement_nin => FALSE,
                                            where_in        => 'id_movement = ' || l_id_mov_transp,
                                            rows_out        => l_rows);
                    
                        t_data_gov_mnt.process_update(i_lang, i_prof, 'EXAM_REQ_DET', l_rows, o_error => o_error);
                    
                    END IF;
                
                    IF l_exist_request = 'I'
                    THEN
                        l_message := 'UPDATE INTERV_PRESC_DET';
                        /* <DENORM Fábio> */
                        l_rows := table_varchar();
                        ts_interv_presc_det.upd(id_movement_in     => l_id_new_mov,
                                                id_movement_nin    => FALSE,
                                                flg_status_in      => l_flg_status,
                                                flg_status_nin     => FALSE,
                                                dt_cancel_tstz_in  => CASE l_flg_status
                                                                          WHEN pk_interv_mfr.g_flg_status_c THEN
                                                                           l_sysdate_tstz
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                                dt_cancel_tstz_nin => TRUE,
                                                id_prof_cancel_in  => CASE l_flg_status
                                                                          WHEN pk_interv_mfr.g_flg_status_c THEN
                                                                           i_prof.id
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                                id_prof_cancel_nin => TRUE,
                                                where_in           => 'id_movement = ' || l_id_mov_transp,
                                                rows_out           => l_rows);
                    
                        t_data_gov_mnt.process_update(i_lang, i_prof, 'INTERV_PRESC_DET', l_rows, o_error => o_error);
                    END IF;
                END IF;
            
                -- não é preciso actualizar as tarefas de análises, exames e procedimentos pq o seu estado não é alterado.
            
                FOR rec IN (SELECT erd.id_exam_req_det, erd.id_exam_req, erd.id_exam
                              FROM exam_req_det erd, exam_req er
                             WHERE erd.id_movement = l_id_mov_transp
                               AND erd.id_exam_req = er.id_exam_req)
                LOOP
                
                    l_message := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
                    IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => NULL,
                                                              i_episode      => i_episode,
                                                              i_exam_req     => rec.id_exam_req,
                                                              i_exam_req_det => rec.id_exam_req_det,
                                                              o_error        => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END LOOP;
            
            END IF;
        
            --verifica se a sala de destino é uma sala do bloco operatório de recobro
            -- Alterado por: Rui Campos 2006/11/09
            l_message := 'CHECK SR TRANSPORT';
            SELECT COUNT(*)
              INTO l_count_oris
              FROM department d, room r, software_dept sd
             WHERE sd.id_software = pk_alert_constant.g_soft_oris
               AND d.id_dept = sd.id_dept
               AND d.id_institution = i_prof.institution
               AND r.id_department = d.id_department
               AND r.id_room = i_room;
        
            IF nvl(l_count_oris, 0) > 0
            THEN
                --Actualiza estado do doente no ORIS
                l_message := 'GET ROOM INFO';
                BEGIN
                    SELECT flg_recovery
                      INTO l_flg_recovery
                      FROM room
                     WHERE id_room = i_room;
                    l_message := 'UPDATE ORIS PATIENT STATUS';
                    IF l_flg_recovery = pk_alert_constant.g_yes
                    THEN
                        l_action := 'F'; -- Transporte para o recobro
                    ELSE
                        l_action := 'B'; -- Transporte para o bloco
                    END IF;
                    IF NOT pk_sr_output.set_patient_status(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_episode    => i_episode,
                                                           i_room       => l_room,
                                                           i_dt_mov_str => pk_date_utils.date_send_tsz(i_lang,
                                                                                                       l_sysdate_tstz,
                                                                                                       i_prof),
                                                           i_action     => l_action,
                                                           o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
            END IF;
        
        END IF; -- O_FLG_SHOW 
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_NEW_LOCATION_NO_COMMIT',
                                              o_error);
            RETURN FALSE;
    END set_new_location_no_commit;

    /** @headcom
    * Public Function. Criar movimento, no caso de requisição de transportes.   
    *
    * @param    i_lang           língua registada como preferência do profissional.
    * @param    i_episode        ID do episódio
    * @param    i_prof           object (ID do profissional, ID da instituição, ID do software).
    * @param    i_room           sala de destino
    * @param    i_necessity      necessidade
    * @param    i_dt_req         Data de requisição; ñ precisa de ser preenchido
    * @param    i_prof_cat_type  Tipo de categoria do profissional, tal 
                                 como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param    o_id_mov         ID do movimento 
    * @param    o_flg_show       Y - existe msg para mostrar; N - ñ existe 
    * @param    o_msg            mensagem
    * @param    o_msg_title      Título da msg a mostrar ao utilizador, caso 
                                 O_FLG_SHOW = Y 
    * @param    o_button         Botões a mostrar: N - não, R - lido, C - confirmado 
                                 Tb pode mostrar combinações destes, qd é p/ mostrar 
                                 + do q 1 botão 
    * @param    o_error          erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     CRS 
    * @version    0.1
    * @since      2005/02/28
    */

    FUNCTION call_create_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req_str    IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_seq                 movement.id_movement%TYPE;
        l_id_mov_transp       movement.id_movement%TYPE;
        l_flg_status          movement.flg_status%TYPE;
        l_dt_req              TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_mov              movement.id_movement%TYPE;
        l_flg_type            episode.id_epis_type%TYPE;
        l_status              episode.flg_status%TYPE;
        l_id_room             epis_info.id_room%TYPE;
        l_desc_room           VARCHAR2(200);
        l_dt_entrance_room    VARCHAR2(50);
        l_dt_last_interaction VARCHAR2(50);
        l_dt_movement         VARCHAR2(50);
        l_count_oris          PLS_INTEGER;
        l_oris_episode        episode.id_episode%TYPE;
        l_ret                 BOOLEAN;
        l_error_in            t_error_in := t_error_in();
    
        l_sys_alert_event_row sys_alert_event%ROWTYPE;
    
        l_rows table_varchar;
    
        l_epis_type episode.id_epis_type%TYPE;
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
        l_sysdate_char CONSTANT VARCHAR2(14) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                            i_date => l_sysdate_tstz,
                                                                            i_prof => i_prof);
    
    BEGIN
        IF i_room IS NULL
        THEN
            l_error_in.set_all(i_lang,
                               'MOVEMENT_M002',
                               pk_message.get_message(i_lang, 'MOVEMENT_M002'),
                               l_message,
                               g_package_owner,
                               g_package_name,
                               'CALL_CREATE_MOVEMENT',
                               pk_message.get_message(i_lang, 'MOVEMENT_M002'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            RETURN l_ret;
        END IF;
    
        -- Verificar se é possível criar o movimento pretendido 
        l_message := 'CALL TO CHECK_MOV';
        IF NOT check_mov(i_lang        => i_lang,
                         i_episode     => i_episode,
                         i_room        => i_room,
                         i_prof        => i_prof,
                         o_id_movement => l_id_mov,
                         o_flg_show    => o_flg_show,
                         o_msg_text    => o_msg,
                         o_msg_title   => o_msg_title,
                         o_button      => o_button,
                         o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        o_id_mov := l_id_mov;
    
        IF o_flg_show = pk_alert_constant.g_no
        THEN
            -- Movimento válido 
        
            -- Verificar o doente está actualmente a ser transportado 
            l_message := 'CALL TO GET_TRANSP_MOV';
            IF NOT get_transp_mov(i_lang     => i_lang,
                                  i_episode  => i_episode,
                                  o_movement => l_id_mov_transp,
                                  o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
            l_message := 'GET L_FLG_STATUS';
            IF nvl(l_id_mov_transp, 0) != 0
            THEN
                l_flg_status := pk_alert_constant.g_mov_status_pend;
            ELSE
                l_flg_status := pk_alert_constant.g_mov_status_req;
            END IF;
        
            l_message := 'GET L_DT_REQ';
            l_dt_req  := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_req_str, NULL), l_sysdate_tstz);
        
            -- Localização actual do doente 
            l_message := 'CALL TO PK_VISIT.GET_EPIS_INFO';
            IF NOT pk_visit.get_epis_info(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_prof                => i_prof,
                                          o_flg_type            => l_flg_type,
                                          o_flg_status          => l_status,
                                          o_id_room             => l_id_room,
                                          o_desc_room           => l_desc_room,
                                          o_dt_entrance_room    => l_dt_entrance_room,
                                          o_dt_last_interaction => l_dt_last_interaction,
                                          o_dt_movement         => l_dt_movement,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_message := 'INSERT';
            /* <DENORM Fábio> */
            ts_movement.ins(id_episode_in      => i_episode,
                            id_room_from_in    => l_id_room,
                            id_room_to_in      => i_room,
                            id_prof_request_in => i_prof.id,
                            dt_req_tstz_in     => l_dt_req,
                            flg_status_in      => l_flg_status,
                            id_necessity_in    => i_necessity,
                            id_movement_out    => l_seq,
                            rows_out           => l_rows);
        
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'MOVEMENT', l_rows, o_error => o_error);
        
            -- JS: 2008-03-28: Process alerts for "PATIENT_MOV" (Alert id 9)            
            l_sys_alert_event_row.id_sys_alert := 9;
            l_sys_alert_event_row.id_episode   := i_episode;
            l_sys_alert_event_row.id_record    := l_seq;
            l_sys_alert_event_row.dt_record    := l_dt_req;
            l_sys_alert_event_row.replace1     := pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                          i_prof.institution,
                                                                          i_prof.software);
            -- JS: 2008-03-28: Delete if pending    
            IF l_flg_status = pk_alert_constant.g_mov_status_pend
            THEN
                l_message := 'DELETE ALERTS(PATIENT_MOV)';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        o_error           => o_error)
                THEN
                    pk_alertlog.log_error('Error deleting alerts');
                    pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                          l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                          l_sys_alert_event_row.id_record);
                    --pk_alertlog.log_error(l_error);
                    RETURN FALSE;
                END IF;
                -- JS: 2008-03-28: Insert if requested
            ELSIF l_flg_status = pk_alert_constant.g_mov_status_req
            THEN
                l_message := 'INSERT ALERT(PATIENT_MOV)';
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        i_flg_type_dest   => NULL,
                                                        o_error           => o_error)
                THEN
                    pk_alertlog.log_error('Error inserting alert');
                    pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                          l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                          l_sys_alert_event_row.id_record);
                    --pk_alertlog.log_error(l_error);
                    RETURN FALSE;
                END IF;
            
            END IF;
        
            --RS 20080602
            --We allways want this functions to be called
            --IF i_dt_req_str IS NULL
            --THEN
            l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
            IF NOT pk_visit.update_epis_info_no_obs(i_lang         => i_lang,
                                                    i_id_episode   => i_episode,
                                                    i_id_room      => NULL,
                                                    i_bed          => NULL,
                                                    i_norton       => NULL,
                                                    i_professional => NULL,
                                                    i_flg_hydric   => NULL,
                                                    i_flg_wound    => NULL,
                                                    i_companion    => NULL,
                                                    i_flg_unknown  => NULL,
                                                    i_desc_info    => NULL,
                                                    i_prof         => i_prof,
                                                    o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
            IF NOT pk_visit.update_epis_info_no_obs(i_lang                 => i_lang,
                                                    i_id_episode           => i_episode,
                                                    i_id_prof              => i_prof,
                                                    i_dt_entrance_room     => NULL,
                                                    i_dt_last_interaction  => l_sysdate_char,
                                                    i_dt_movement          => l_sysdate_char,
                                                    i_dt_harvest           => NULL,
                                                    i_dt_next_drug         => NULL,
                                                    i_dt_first_obs         => l_sysdate_char,
                                                    i_dt_next_intervention => NULL,
                                                    i_dt_next_vital_sign   => NULL,
                                                    i_dt_next_position     => NULL,
                                                    i_dt_harvest_mov       => NULL,
                                                    i_dt_first_nurse_obs   => NULL,
                                                    i_prof_cat_type        => i_prof_cat_type,
                                                    o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            --l_message := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            --IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
            --                              i_id_episode          => i_episode,
            --                              i_pat                 => NULL,
            --                              i_prof                => i_prof,
            --                              i_prof_cat_type       => i_prof_cat_type,
            --                              i_dt_last_interaction => l_sysdate_tstz,
            --                              i_dt_first_obs        => l_sysdate_tstz,
            --                              o_error               => o_error)
            --THEN
            --    RETURN FALSE;
            --END IF;
        
            --verifica se a sala de destino é uma sala do bloco operatório (que não seja recobro)
            l_message := 'CHECK SR TRANSPORT';
            SELECT COUNT(*)
              INTO l_count_oris
              FROM department d, room r, software_dept sd
             WHERE sd.id_software = pk_alert_constant.g_soft_oris
               AND d.id_dept = sd.id_dept
               AND d.id_institution = i_prof.institution
               AND r.id_department = d.id_department
               AND r.id_room = i_room
               AND flg_recovery = pk_alert_constant.g_no;
        
            IF nvl(l_count_oris, 0) > 0
            THEN
            
                --Determina o episódio de bloco. Só actualiza o estado do paciente se só existir um episódio de bloco
                --  activo e agendado para este paciente
                -- If exists more the one active ORIS episode, get the closer ORIS episode when I make a request of patient transport. 
                --With this logic, I have only one ORIS episode
                BEGIN
                    SELECT e.id_epis_type
                      INTO l_epis_type
                      FROM episode e
                     WHERE id_episode = i_episode;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_epis_type := NULL;
                    
                END;
            
                IF l_epis_type = pk_alert_constant.g_epis_type_operating
                THEN
                    l_oris_episode := i_episode;
                ELSE
                
                    BEGIN
                        SELECT ep.id_episode
                          INTO l_oris_episode
                          FROM (SELECT pk_date_utils.get_timestamp_diff(current_timestamp, s.dt_target_tstz) time_diff,
                                       e1.id_episode
                                  FROM episode e, visit v, visit v1, episode e1, schedule_sr s
                                 WHERE e.id_episode = i_episode
                                   AND v.id_visit = e.id_visit
                                   AND v1.id_patient = v.id_patient
                                   AND v1.id_institution = v.id_institution
                                   AND e1.id_visit = v1.id_visit
                                   AND e1.id_epis_type = pk_alert_constant.g_epis_type_operating
                                   AND e1.flg_status = pk_alert_constant.g_epis_status_active
                                   AND s.id_episode = e1.id_episode
                                   AND s.dt_interv_preview_tstz IS NOT NULL
                                 ORDER BY time_diff) ep
                         WHERE ep.time_diff > 0
                           AND rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_oris_episode := NULL;
                        WHEN too_many_rows THEN
                            l_oris_episode := NULL;
                    END;
                
                END IF;
            
                IF l_oris_episode IS NOT NULL
                THEN
                    --Actualiza estado do doente no ORIS
                    l_message := 'UPDATE ORIS PATIENT STATUS';
                    IF NOT pk_sr_output.set_patient_status(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_episode    => l_oris_episode,
                                                           i_room       => i_room,
                                                           i_dt_mov_str => pk_date_utils.date_send_tsz(i_lang,
                                                                                                       l_sysdate_tstz,
                                                                                                       i_prof),
                                                           i_action     => 'R',
                                                           o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
            o_id_mov := l_seq;
        END IF;
    
        --END IF; -- O_FLG_SHOW 
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_CREATE_MOVEMENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION create_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req_str    IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /** @headcom
        * Public Function. Criar movimento, no caso de requisição de transportes.   
        *
        * Note: Esta é a função chamada pelo Flash.
        *
        * @param    i_lang           língua registada como preferência do profissional.
        * @param    i_episode        ID do episódio
        * @param    i_prof           object (ID do profissional, ID da instituição, ID do software).
        * @param    i_room           sala de destino
        * @param    i_necessity      necessidade
        * @param    i_dt_req         Data de requisição; ñ precisa de ser preenchido
        * @param    i_prof_cat_type  Tipo de categoria do profissional, tal 
                                     como é retornada em PK_LOGIN.GET_PROF_PREF 
        * @param    o_id_mov         ID do movimento 
        * @param    o_flg_show       Y - existe msg para mostrar; N - ñ existe 
        * @param    o_msg            mensagem
        * @param    o_msg_title      Título da msg a mostrar ao utilizador, caso 
                                     O_FLG_SHOW = Y 
        * @param    o_button         Botões a mostrar: N - não, R - lido, C - confirmado 
                                     Tb pode mostrar combinações destes, qd é p/ mostrar 
                                     + do q 1 botão 
        * @param    o_error          erro
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     ASM 
        * @version    0.1
        * @since      2007/07/26
        */
        l_message    debug_msg;
        l_epis_type  episode.id_epis_type%TYPE;
        l_id_episode episode.id_episode%TYPE := i_episode;
    BEGIN
        l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        IF (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            l_id_episode := pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_episode);
        END IF;
    
        l_message := 'PK_MOVEMENT.CALL_CREATE_MOVEMENT';
        IF NOT call_create_movement(i_lang          => i_lang,
                                    i_episode       => l_id_episode,
                                    i_prof          => i_prof,
                                    i_room          => i_room,
                                    i_necessity     => i_necessity,
                                    i_dt_req_str    => i_dt_req_str,
                                    i_prof_cat_type => i_prof_cat_type,
                                    o_id_mov        => o_id_mov,
                                    o_flg_show      => o_flg_show,
                                    o_msg           => o_msg,
                                    o_msg_title     => o_msg_title,
                                    o_button        => o_button,
                                    o_error         => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_MOVEMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_movement;

    FUNCTION create_movement_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN movement.id_episode%TYPE,
        i_prof          IN profissional,
        i_room          IN movement.id_room_to%TYPE,
        i_necessity     IN movement.id_necessity%TYPE,
        i_dt_req_str    IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_id_mov        OUT movement.id_movement%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /** @headcom
        * Public Function. Criar movimento, no caso de requisição de transportes.   
        *
        * Note: Esta é a função chamada pelo Flash.
        *
        * @param    i_lang           língua registada como preferência do profissional.
        * @param    i_episode        ID do episódio
        * @param    i_prof           object (ID do profissional, ID da instituição, ID do software).
        * @param    i_room           sala de destino
        * @param    i_necessity      necessidade
        * @param    i_dt_req         Data de requisição; ñ precisa de ser preenchido
        * @param    i_prof_cat_type  Tipo de categoria do profissional, tal 
                                     como é retornada em PK_LOGIN.GET_PROF_PREF 
        * @param    o_id_mov         ID do movimento 
        * @param    o_flg_show       Y - existe msg para mostrar; N - ñ existe 
        * @param    o_msg            mensagem
        * @param    o_msg_title      Título da msg a mostrar ao utilizador, caso 
                                     O_FLG_SHOW = Y 
        * @param    o_button         Botões a mostrar: N - não, R - lido, C - confirmado 
                                     Tb pode mostrar combinações destes, qd é p/ mostrar 
                                     + do q 1 botão 
        * @param    o_error          erro
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     ASM 
        * @version    0.1
        * @since      2007/07/26
        */
        l_message debug_msg;
    
    BEGIN
        l_message := 'PK_MOVEMENT.CALL_CREATE_MOVEMENT';
        IF NOT call_create_movement(i_lang          => i_lang,
                                    i_episode       => i_episode,
                                    i_prof          => i_prof,
                                    i_room          => i_room,
                                    i_necessity     => i_necessity,
                                    i_dt_req_str    => i_dt_req_str,
                                    i_prof_cat_type => i_prof_cat_type,
                                    o_id_mov        => o_id_mov,
                                    o_flg_show      => o_flg_show,
                                    o_msg           => o_msg,
                                    o_msg_title     => o_msg_title,
                                    o_button        => o_button,
                                    o_error         => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_MOVEMENT_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_movement_no_commit;

    FUNCTION set_movement
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Função que determina se o movimento deve ser iniciado ou terminado  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_MOVEMENT - ID do movimento
                       I_PROF - ID do profissional  
                     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/08/06 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_mov IS
            SELECT flg_status, id_episode
              FROM movement
             WHERE id_movement = i_movement;
    
        l_status  movement.flg_status%TYPE;
        l_episode movement.id_episode%TYPE;
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
    
    BEGIN
        l_message := 'OPEN C_MOV';
        OPEN c_mov;
        FETCH c_mov
            INTO l_status, l_episode;
        CLOSE c_mov;
    
        IF l_status = pk_alert_constant.g_mov_status_req
        THEN
            IF NOT set_mov_begin(i_lang => i_lang, i_movement => i_movement, i_prof => i_prof, o_error => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
        ELSIF l_status = pk_alert_constant.g_mov_status_transp
        THEN
            IF NOT set_mov_end(i_lang          => i_lang,
                               i_movement      => i_movement,
                               i_prof          => i_prof,
                               i_prof_cat_type => i_prof_cat_type,
                               o_error         => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        l_message := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        -- não actualiza a tarefa pq isso é feito nas funções q são chamadas nesta.
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MOVEMENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION check_mov_request
    (
        i_lang      IN language.id_language%TYPE,
        i_movement  movement.id_movement%TYPE,
        o_flg_exist OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verificar se existe requisição de exame/análise associada a um movimento 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                       I_MOVEMENT - ID do movimento 
                  Saida:   O_FLG_EXIST - indicador se existe req. análise / exame 
                             associada ao movimento:
                             E - existe req exame 
                             A - existe req análise 
                             I - existe req intervenção 
                             N - não existe req 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/01 
          NOTAS: 
        *********************************************************************************/
    
        CURSOR c_exist_exam IS
            SELECT 'E'
              FROM exam_req_det
             WHERE id_movement = i_movement
               AND flg_status NOT IN (pk_alert_constant.g_exam_det_exec, pk_alert_constant.g_exam_det_canc);
    
        CURSOR c_exist_analysis IS
            SELECT 'A'
              FROM analysis_req_det
             WHERE id_movement = i_movement
               AND flg_status NOT IN (pk_alert_constant.g_analysis_det_exec, pk_alert_constant.g_analysis_det_canc);
    
        CURSOR c_exist_interv IS
            SELECT 'I'
              FROM interv_presc_det
             WHERE id_movement = i_movement;
    
        l_found   BOOLEAN;
        l_message debug_msg;
    
    BEGIN
        o_flg_exist := 'N';
    
        l_message := 'GET CURSOR C_EXIST_EXAM';
        OPEN c_exist_exam;
        FETCH c_exist_exam
            INTO o_flg_exist;
        l_found := c_exist_exam%NOTFOUND;
        CLOSE c_exist_exam;
    
        IF l_found
        THEN
            l_message := 'GET CURSOR C_EXIST_ANALYSIS';
            OPEN c_exist_analysis;
            FETCH c_exist_analysis
                INTO o_flg_exist;
            l_found := c_exist_analysis%NOTFOUND;
            CLOSE c_exist_analysis;
        
            IF l_found
            THEN
                l_message := 'GET CURSOR C_EXIST_INTERV';
                OPEN c_exist_interv;
                FETCH c_exist_interv
                    INTO o_flg_exist;
                CLOSE c_exist_interv;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_MOV_REQUEST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_mov_begin
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar movimento, no caso dos transportes (início do movimento) 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                       I_PROF - ID do profissional que inicia movimento 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/02/28 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_epis IS
            SELECT id_episode
              FROM movement
             WHERE id_movement = i_movement;
    
        CURSOR c_req IS
            SELECT erd.id_exam_req_det, erd.id_exam_req, erd.id_exam, erd.flg_status
              FROM exam_req_det erd, exam_req er
             WHERE erd.id_movement = i_movement
               AND erd.id_exam_req = er.id_exam_req;
    
        CURSOR c_other_mov(x_epis episode.id_episode%TYPE) IS
            SELECT id_movement
              FROM movement
             WHERE id_movement != i_movement
               AND flg_status = pk_alert_constant.g_mov_status_req
               AND id_episode = x_epis;
    
        l_episode      movement.id_episode%TYPE;
        l_count_oris   PLS_INTEGER;
        l_id_room      room.id_room%TYPE;
        l_id_room_from room.id_room%TYPE;
        l_oris_episode episode.id_episode%TYPE;
        l_req          c_req%ROWTYPE;
        l_ret          BOOLEAN;
        l_found        BOOLEAN;
        l_error_in     t_error_in := t_error_in();
    
        l_sys_alert_event_row sys_alert_event%ROWTYPE;
    
        l_rows table_varchar;
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
    
    BEGIN
        l_message := 'GET ROOM OF ORIGIN';
        /* cmf 28-02-2008 no inicio de um transporte, actualizar a sala de origem para a sala onde está o doente */
        SELECT id_room
          INTO l_id_room_from
          FROM epis_info
         WHERE id_episode = (SELECT id_episode
                               FROM movement
                              WHERE id_movement = i_movement);
    
        l_message := 'UPDATE TO TRANSPORT';
        /* <DENORM Fábio> */
        ts_movement.upd(id_movement_in    => i_movement,
                        flg_status_in     => pk_alert_constant.g_mov_status_transp,
                        id_room_from_in   => l_id_room_from,
                        id_prof_move_in   => i_prof.id,
                        dt_begin_tstz_in  => l_sysdate_tstz,
                        id_room_from_nin  => FALSE,
                        id_prof_move_nin  => FALSE,
                        dt_begin_tstz_nin => FALSE,
                        rows_out          => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MOVEMENT',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS',
                                                                      'ID_ROOM_FROM',
                                                                      'ID_PROF_MOVE',
                                                                      'DT_BEGIN_TSTZ'));
    
        l_message := 'GET CURSOR C_EPIS';
        OPEN c_epis;
        FETCH c_epis
            INTO l_episode;
        CLOSE c_epis;
    
        IF SQL%ROWCOUNT = 1
        THEN
        
            -- JS: 2008-03-28: Delete alerts for "PATIENT_MOV" (Alert id 9) - For i_movement
            l_message                          := 'DELETE ALERTS(PATIENT_MOV)';
            l_sys_alert_event_row.id_sys_alert := 9;
            l_sys_alert_event_row.id_episode   := l_episode;
            l_sys_alert_event_row.id_record    := i_movement;
        
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event_row,
                                                    o_error           => o_error)
            THEN
                pk_alertlog.log_error('Error deleting alerts');
                pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                      l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                      l_sys_alert_event_row.id_record);
                --pk_alertlog.log_error(l_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
            -- JS: 2008-03-28: Passa para loop para invocar funcao que apaga alertas para cada movimento alterado        
            -- Coloca como "pendente" todos os restantes movimentos requisitados 
            --            l_message := 'UPDATE MOVEMENT';
            --            UPDATE movement
            --               SET flg_status = g_mov_status_pend
            --             WHERE id_movement != i_movement
            --               AND flg_status = g_mov_status_req
            --               AND id_episode = l_episode;
        
            -- Coloca como "pendente" todos os restantes movimentos requisitados.
            l_rows := table_varchar();
            FOR m IN c_other_mov(l_episode)
            LOOP
            
                /* <DENORM Fábio> */
                ts_movement.upd(flg_status_in  => pk_alert_constant.g_mov_status_pend,
                                id_movement_in => m.id_movement,
                                rows_out       => l_rows);
            
                -- JS: 2008-03-28: Delete alerts for "PATIENT_MOV" (Alert id 9)
                l_message                          := 'DELETE ALERTS(PATIENT_MOV)';
                l_sys_alert_event_row.id_sys_alert := 9;
                l_sys_alert_event_row.id_episode   := l_episode;
                l_sys_alert_event_row.id_record    := m.id_movement;
            
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        o_error           => o_error)
                THEN
                    pk_alertlog.log_error('Error deleting alerts');
                    pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                          l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                          l_sys_alert_event_row.id_record);
                    --pk_alertlog.log_error(l_error);
                    pk_alert_exceptions.reset_error_state;
                    RETURN FALSE;
                END IF;
            END LOOP;
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'MOVEMENT',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        ELSE
            l_error_in.set_all(i_lang,
                               'MOVEMENT_M001',
                               pk_message.get_message(i_lang, 'MOVEMENT_M001'),
                               l_message,
                               g_package_owner,
                               g_package_name,
                               'CALL_CREATE_MOVEMENT',
                               pk_message.get_message(i_lang, 'MOVEMENT_M001'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        END IF;
    
        l_message := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        l_message := 'GET CURSOR C_EPIS';
        OPEN c_req;
        FETCH c_req
            INTO l_req;
        l_found := c_req%FOUND;
        CLOSE c_req;
    
        IF l_found
        THEN
            l_message := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
            IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_patient      => NULL,
                                                      i_episode      => l_episode,
                                                      i_exam_req     => l_req.id_exam_req,
                                                      i_exam_req_det => l_req.id_exam_req_det,
                                                      o_error        => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            pk_ia_event_image.exam_request_in_transport(i_id_exam_req_det => l_req.id_exam_req_det,
                                                        i_id_institution  => i_prof.institution,
                                                        i_flg_old_status  => l_req.flg_status);
        END IF;
    
        --verifica se a sala de destino é uma sala do bloco operatório ( Que não seja a sala de recobro)
        l_message := 'CHECK SR TRANSPORT';
        SELECT COUNT(*)
          INTO l_count_oris
          FROM movement m, department d, room r, software_dept sd
         WHERE m.id_movement = i_movement
           AND sd.id_software = pk_alert_constant.g_soft_oris
           AND d.id_dept = sd.id_dept
           AND d.id_institution = i_prof.institution
           AND r.id_department = d.id_department
           AND r.id_room = m.id_room_to
           AND r.flg_recovery = pk_alert_constant.g_no;
    
        IF nvl(l_count_oris, 0) > 0
        THEN
        
            --Determina o episódio de bloco. Só actualiza o estado do paciente se só existir um episódio de bloco
            --  activo e agendado para este paciente
        
            IF NOT pk_sr_output.get_oris_episode(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_movement     => i_movement,
                                                 o_oris_episode => l_oris_episode,
                                                 o_id_room      => l_id_room,
                                                 o_error        => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            IF l_oris_episode IS NOT NULL
            THEN
                --Actualiza estado do doente no ORIS
                --        l_message := 'GET ID_ROOM';
                --        select id_room_to, id_episode 
                --        into l_id_room, l_episode
                --        from movement 
                --        where id_movement = I_MOVEMENT;
            
                l_message := 'UPDATE ORIS PATIENT STATUS';
                IF NOT pk_sr_output.set_patient_status(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_episode    => l_oris_episode,
                                                       i_room       => l_id_room,
                                                       i_dt_mov_str => pk_date_utils.date_send_tsz(i_lang,
                                                                                                   l_sysdate_tstz,
                                                                                                   i_prof),
                                                       i_action     => 'B',
                                                       o_error      => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MOV_BEGIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_mov_end
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar movimento, no caso dos transportes (fim do movimento) 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_MOVEMENT - ID do movimento 
                       I_PROF - ID do profissional que termina movimento (recebe doente) 
                     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/02/28 
          NOTAS: 
        *********************************************************************************/
        l_exist_request   VARCHAR2(1);
        l_epis            movement.id_episode%TYPE;
        l_room            movement.id_room_to%TYPE;
        l_count_oris      PLS_INTEGER;
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_ret             BOOLEAN;
        l_error_in        t_error_in := t_error_in();
    
        CURSOR c_epis IS
            SELECT id_episode, id_room_to
              FROM movement
             WHERE id_movement = i_movement;
    
        CURSOR c_other_mov(x_epis episode.id_episode%TYPE) IS
            SELECT id_movement, dt_req_tstz
              FROM movement m
             WHERE id_movement != i_movement
               AND flg_status = pk_alert_constant.g_mov_status_pend
               AND id_episode = x_epis;
    
        l_sys_alert_event_row sys_alert_event%ROWTYPE;
    
        l_rows table_varchar;
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
        l_sysdate_char CONSTANT VARCHAR2(14) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                            i_date => l_sysdate_tstz,
                                                                            i_prof => i_prof);
    
        l_exception EXCEPTION;
    BEGIN
        -- Actualiza o movimento dando-o como finalizado 
        l_message := 'UPDATE TO FINISHED';
        /* <DENORM Fábio> */
        ts_movement.upd(id_prof_receive_in  => i_prof.id,
                        id_prof_receive_nin => FALSE,
                        dt_end_tstz_in      => l_sysdate_tstz,
                        dt_end_tstz_nin     => FALSE,
                        flg_status_in       => pk_alert_constant.g_mov_status_finish,
                        where_in            => 'id_movement = ' || i_movement || ' AND flg_status = ''' ||
                                               pk_alert_constant.g_mov_status_transp || '''',
                        rows_out            => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MOVEMENT',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PROF_RECEIVE', 'DT_END_TSTZ', 'FLG_STATUS'));
    
        l_message := 'GET CURSOR';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis, l_room;
        CLOSE c_epis;
    
        IF SQL%ROWCOUNT = 1
        THEN
        
            -- JS: 2008-03-28: Delete alerts for "PATIENT_MOV" (Alert id 9) - For i_movement
            l_message                          := 'DELETE ALERTS(PATIENT_MOV)';
            l_sys_alert_event_row.id_sys_alert := 9;
            l_sys_alert_event_row.id_episode   := l_epis;
            l_sys_alert_event_row.id_record    := i_movement;
        
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event_row,
                                                    o_error           => o_error)
            THEN
                pk_alertlog.log_error('Error deleting alerts');
                pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                      l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                      l_sys_alert_event_row.id_record);
                --pk_alertlog.log_error(l_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
            -- JS: 2008-03-28: Passa para loop para invocar funcao que apaga alertas para cada movimento alterado
            -- Actualiza todos os movimentos que estejam "pendentes" para "requisitados" 
            --            l_message := 'UPDATE TO REQUESTED';
            --            UPDATE movement
            --               SET flg_status = g_mov_status_req
            --             WHERE id_movement != i_movement
            --               AND flg_status = g_mov_status_pend
            --               AND id_episode = l_epis;
        
            -- Actualiza todos os movimentos que estejam "pendentes" para "requisitados"    
            l_rows := table_varchar();
            FOR m IN c_other_mov(l_epis)
            LOOP
                /* <DENORM Fábio> */
                ts_movement.upd(flg_status_in  => pk_alert_constant.g_mov_status_req,
                                id_movement_in => m.id_movement,
                                rows_out       => l_rows);
            
                -- JS: 2008-03-28: Insert alert event for "PATIENT_MOV" (Alert id 9)
                l_message                          := 'INSERT ALERT(PATIENT_MOV)';
                l_sys_alert_event_row.id_sys_alert := 9;
                l_sys_alert_event_row.id_episode   := l_epis;
                l_sys_alert_event_row.id_record    := m.id_movement;
                l_sys_alert_event_row.dt_record    := m.dt_req_tstz;
                l_sys_alert_event_row.replace1     := pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                              i_prof.institution,
                                                                              i_prof.software);
            
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event_row,
                                                        i_flg_type_dest   => NULL,
                                                        o_error           => o_error)
                THEN
                    pk_alertlog.log_error('Error inserting alert');
                    pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                          l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                          l_sys_alert_event_row.id_record);
                    --pk_alertlog.log_error(l_error);
                    pk_alert_exceptions.reset_error_state;
                    RETURN FALSE;
                END IF;
            
            END LOOP;
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'MOVEMENT',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        
            l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
            IF NOT pk_visit.update_epis_info(i_lang         => i_lang,
                                             i_id_episode   => l_epis,
                                             i_id_room      => l_room,
                                             i_bed          => NULL,
                                             i_norton       => NULL,
                                             i_professional => NULL,
                                             i_flg_hydric   => NULL,
                                             i_flg_wound    => NULL,
                                             i_companion    => NULL,
                                             i_flg_unknown  => NULL,
                                             i_desc_info    => NULL,
                                             i_prof         => i_prof,
                                             o_error        => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
            IF NOT pk_visit.update_epis_info(i_lang                 => i_lang,
                                             i_id_episode           => l_epis,
                                             i_id_prof              => i_prof,
                                             i_dt_entrance_room     => l_sysdate_char,
                                             i_dt_last_interaction  => l_sysdate_char,
                                             i_dt_movement          => l_sysdate_char,
                                             i_dt_harvest           => NULL,
                                             i_dt_next_drug         => NULL,
                                             i_dt_first_obs         => l_sysdate_char,
                                             i_dt_next_intervention => NULL,
                                             i_dt_next_vital_sign   => NULL,
                                             i_dt_next_position     => NULL,
                                             i_dt_harvest_mov       => NULL,
                                             i_dt_first_nurse_obs   => NULL,
                                             i_prof_cat_type        => i_prof_cat_type,
                                             o_error                => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            -- SE O MOVIMENTO TERMINADO ESTÁ ASSOCIADO A UMA TRANSFERÊNCIA DE SERVIÇO, ACTUALIZA  O RESPECTIVO EPISODIO
            -- CARLOS FERREIRA 04-02-2007
            IF NOT pk_hand_off.set_end_transfer(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_episode       => l_epis,
                                                i_id_movement      => i_movement,
                                                i_id_dep_clin_serv => NULL,
                                                o_error            => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            -- Se o movimento terminado está associado a uma requisição de exame/análise, actualiza-se 
            -- o estado da req para "em execução" 
            l_message := 'CALL TO CHECK_MOV_REQUEST';
            IF NOT check_mov_request(i_lang      => i_lang,
                                     i_movement  => i_movement,
                                     o_flg_exist => l_exist_request,
                                     o_error     => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                l_message := 'CHECK L_EXIST_REQUEST';
                IF l_exist_request = 'A'
                   AND pk_sysconfig.get_config('TRANSP_PAT_REQ_EXEC', i_prof) = pk_alert_constant.g_yes
                THEN
                
                    l_message := 'INSERT ANALYSIS LOG';
                    FOR r_analysis IN (SELECT ard.id_analysis_req_det, ard.id_analysis_req
                                         FROM analysis_req_det ard
                                        WHERE ard.id_movement = i_movement
                                          AND ard.flg_status NOT IN
                                              (pk_alert_constant.g_analysis_det_exec,
                                               pk_alert_constant.g_analysis_det_canc,
                                               pk_alert_constant.g_analysis_det_result,
                                               pk_alert_constant.g_analysis_det_read))
                    LOOP
                        -- inserir em log de estados
                        IF t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            l_epis,
                                            pk_alert_constant.g_analysis_det_exec,
                                            r_analysis.id_analysis_req,
                                            pk_alert_constant.g_analysis_type_req,
                                            o_error) = FALSE
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    
                        IF t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            l_epis,
                                            pk_alert_constant.g_analysis_det_exec,
                                            r_analysis.id_analysis_req_det,
                                            pk_alert_constant.g_analysis_type_req_det,
                                            o_error) = FALSE
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    END LOOP;
                
                    l_message := 'UPDATE ANALYSIS_REQ_DET';
                    /* <DENORM Fábio> */
                    l_rows := table_varchar();
                    ts_analysis_req_det.upd(flg_status_in => pk_alert_constant.g_analysis_det_exec,
                                            where_in      => 'id_movement = ' || i_movement ||
                                                             ' AND flg_status NOT IN (''' ||
                                                             pk_alert_constant.g_analysis_det_exec || ''', ''' ||
                                                             pk_alert_constant.g_analysis_det_canc || ''', ''' ||
                                                             pk_alert_constant.g_analysis_det_result || ''', ''' ||
                                                             pk_alert_constant.g_analysis_det_read || ''')',
                                            rows_out      => l_rows);
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'ANALYSIS_REQ_DET',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_STATUS'));
                
                    FOR rec IN (SELECT ard.id_analysis_req_det
                                  FROM analysis_req_det ard
                                 WHERE ard.rowid IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                                       FROM TABLE(l_rows) t)
                                   AND ard.id_task_dependency IS NOT NULL)
                    LOOP
                        g_error := 'Call pk_lab_tests_external_api_db.update_tde_task_state';
                        IF NOT pk_lab_tests_external_api_db.update_tde_task_state(i_lang         => i_lang,
                                                                                  i_prof         => i_prof,
                                                                                  i_lab_test_req => rec.id_analysis_req_det,
                                                                                  i_flg_action   => pk_alert_constant.g_analysis_det_exec,
                                                                                  o_error        => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END LOOP;
                
                    /* <DENORM Fábio> */
                    l_rows := table_varchar();
                    ts_analysis_req.upd(flg_status_in => pk_alert_constant.g_analysis_det_exec,
                                        where_in      => 'id_analysis_req = (SELECT DISTINCT id_analysis_req
                                                FROM analysis_req_det
                                               WHERE id_movement = ' ||
                                                         i_movement || ')
                       AND flg_status NOT IN (''' ||
                                                         pk_alert_constant.g_analysis_det_exec || ''', ''' ||
                                                         pk_alert_constant.g_analysis_det_canc || ''', ''' ||
                                                         pk_alert_constant.g_analysis_det_result || ''', ''' ||
                                                         pk_alert_constant.g_analysis_det_read || ''')',
                                        rows_out      => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'ANALYSIS_REQ',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_STATUS'));
                
                    FOR rec IN (SELECT ard.id_analysis_req_det, ard.id_analysis_req, ar.id_episode, ar.id_patient
                                  FROM analysis_req_det ard, analysis_req ar
                                 WHERE ard.id_movement = i_movement
                                   AND ard.id_analysis_req = ar.id_analysis_req)
                    LOOP
                        l_message := 'PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK';
                        IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_patient          => rec.id_patient,
                                                                          i_episode          => rec.id_episode,
                                                                          i_analysis_req     => rec.id_analysis_req,
                                                                          i_analysis_req_det => rec.id_analysis_req_det,
                                                                          o_error            => o_error)
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            RETURN FALSE;
                        END IF;
                    END LOOP;
                
                    l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
                    IF NOT pk_visit.upd_epis_info_analysis(i_lang                   => i_lang,
                                                           i_id_episode             => l_epis,
                                                           i_id_prof                => i_prof,
                                                           i_dt_first_analysis_exec => l_sysdate_char,
                                                           i_dt_first_analysis_req  => NULL,
                                                           i_prof_cat_type          => i_prof_cat_type,
                                                           o_error                  => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                        pk_utils.undo_changes;
                        RETURN FALSE;
                    END IF;
                END IF;
            
                IF l_exist_request = 'E'
                THEN
                
                    l_message := 'INSERT EXAM LOG';
                    FOR r_exam IN (SELECT erd.id_exam_req_det, erd.id_exam_req, erd.flg_status
                                     FROM exam_req_det erd
                                    WHERE erd.id_movement = i_movement
                                      AND flg_status NOT IN (pk_alert_constant.g_exam_det_exec,
                                                             pk_alert_constant.g_exam_det_canc,
                                                             pk_alert_constant.g_exam_det_result,
                                                             pk_alert_constant.g_exam_det_read))
                    /*<DENORM Sérgio Monteiro  14-10-08>*/
                    LOOP
                        -- inserir em log de estados
                        IF t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            l_epis,
                                            pk_alert_constant.g_exam_req_exec,
                                            r_exam.id_exam_req,
                                            pk_alert_constant.g_exam_type_req,
                                            o_error) = FALSE
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    
                        IF t_ti_log.ins_log(i_lang,
                                            i_prof,
                                            l_epis,
                                            pk_alert_constant.g_exam_det_exec,
                                            r_exam.id_exam_req_det,
                                            pk_alert_constant.g_exam_type_det,
                                            o_error) = FALSE
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    
                        pk_ia_event_image.exam_request_end_transport(i_id_exam_req_det => r_exam.id_exam_req_det,
                                                                     i_id_institution  => i_prof.institution,
                                                                     i_flg_old_status  => r_exam.flg_status);
                    END LOOP;
                
                    l_message := 'UPDATE EXAM_REQ_DET';
                    /* <DENORM Fábio> */
                    l_rows := table_varchar();
                    ts_exam_req_det.upd(flg_status_in => pk_alert_constant.g_exam_det_exec,
                                        where_in      => 'id_movement = ' || i_movement || 'AND flg_status NOT IN (''' ||
                                                         pk_alert_constant.g_exam_det_exec || ''', ''' ||
                                                         pk_alert_constant.g_exam_det_canc || ''', ''' ||
                                                         pk_alert_constant.g_exam_det_result || ''', ''' ||
                                                         pk_alert_constant.g_exam_det_read || ''')',
                                        rows_out      => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EXAM_REQ_DET',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_STATUS'));
                
                    FOR rec IN (SELECT erd.id_exam_req_det
                                  FROM exam_req_det erd
                                 WHERE erd.rowid IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                                       FROM TABLE(l_rows) t)
                                   AND erd.id_task_dependency IS NOT NULL)
                    LOOP
                    
                        g_error := 'Call PK_EXAMS_EXTERNAL_API_DB.update_tde_task_state';
                        IF NOT pk_exams_external_api_db.update_tde_task_state(i_lang         => i_lang,
                                                                              i_prof         => i_prof,
                                                                              i_exam_req_det => rec.id_exam_req_det,
                                                                              i_flg_action   => pk_alert_constant.g_exam_det_exec,
                                                                              o_error        => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END LOOP;
                
                    l_message := 'UPDATE EXAM_REQ';
                    /* <DENORM Fábio> */
                    l_rows := table_varchar();
                    ts_exam_req.upd(flg_status_in => pk_alert_constant.g_exam_req_exec,
                                    where_in      => 'id_exam_req IN (SELECT id_exam_req
                                             FROM exam_req_det
                                            WHERE id_movement = ' ||
                                                     i_movement || ')
                       AND flg_status NOT IN (''' ||
                                                     pk_alert_constant.g_exam_det_exec || ''', ''' ||
                                                     pk_alert_constant.g_exam_det_canc || ''', ''' ||
                                                     pk_alert_constant.g_exam_det_result || ''', ''' ||
                                                     pk_alert_constant.g_exam_det_read || ''')',
                                    rows_out      => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EXAM_REQ',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_STATUS'));
                
                    FOR rec IN (
                                /*<DENORM Sérgio Monteiro  14-10-08>*/
                                SELECT eea.id_exam_req_det, eea.id_exam_req, eea.id_exam, eea.id_episode
                                  FROM exams_ea eea
                                 WHERE eea.id_movement = i_movement)
                    /*<DENORM Sérgio Monteiro  14-10-08>*/
                    LOOP
                    
                        l_alert_event_row.id_sys_alert := 33;
                        l_alert_event_row.id_episode   := rec.id_episode;
                        l_alert_event_row.id_record    := rec.id_exam_req_det;
                    
                        IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_sys_alert_event => l_alert_event_row,
                                                                o_error           => o_error)
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    
                        l_message := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
                        IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_patient      => NULL,
                                                                  i_episode      => l_epis,
                                                                  i_exam_req     => rec.id_exam_req,
                                                                  i_exam_req_det => rec.id_exam_req_det,
                                                                  o_error        => o_error)
                        THEN
                            pk_alert_exceptions.reset_error_state;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    END LOOP;
                
                    l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
                    IF NOT pk_visit.upd_epis_info_exam(i_lang                => i_lang,
                                                       i_id_episode          => l_epis,
                                                       i_id_prof             => i_prof,
                                                       i_dt_first_image_exec => l_sysdate_char,
                                                       i_dt_first_image_req  => NULL,
                                                       i_prof_cat_type       => i_prof_cat_type,
                                                       o_error               => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                        pk_utils.undo_changes;
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        
        ELSE
            l_error_in.set_all(i_lang,
                               'MOVEMENT_M001',
                               pk_message.get_message(i_lang, 'MOVEMENT_M001'),
                               l_message,
                               g_package_owner,
                               g_package_name,
                               'SET_MOV_END',
                               pk_message.get_message(i_lang, 'MOVEMENT_M001'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN l_ret;
        END IF;
    
        l_message := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --verifica se a sala de destino é uma sala do bloco operatório de recobro
        -- Alterado por: Rui Campos 2006/11/09
        l_message := 'CHECK SR TRANSPORT';
        SELECT COUNT(*)
          INTO l_count_oris
          FROM movement m, department d, room r, software_dept sd
         WHERE m.id_movement = i_movement
           AND sd.id_software = pk_alert_constant.g_soft_oris
           AND d.id_dept = sd.id_dept
           AND d.id_institution = i_prof.institution
           AND r.id_department = d.id_department
           AND r.id_room = m.id_room_to
           AND r.flg_recovery = pk_alert_constant.g_yes;
    
        IF nvl(l_count_oris, 0) > 0
        THEN
            --Actualiza estado do doente no ORIS      
            l_message := 'UPDATE ORIS PATIENT STATUS';
            IF NOT
                pk_sr_output.set_patient_status(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_episode    => l_epis,
                                                i_room       => l_room,
                                                i_dt_mov_str => pk_date_utils.date_send_tsz(i_lang, l_sysdate_tstz, i_prof),
                                                i_action     => 'F',
                                                o_error      => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        COMMIT;
    
        -- refresh materialized view
        pk_episode.update_mv_episodes();
    
        IF NOT set_location_visit(i_lang    => i_lang,
                                  i_prof    => i_prof,
                                  i_episode => l_epis,
                                  i_room    => l_room,
                                  o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MOV_END',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MOV_END',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION cancel_mov
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_notes         IN movement.notes_cancel%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar movimento 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_MOVEMENT - ID do movimento a cancelar 
                 I_PROF - ID do profissional responsável pelo cancelamento 
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                         como é retornada em PK_LOGIN.GET_PROF_PREF 
                                 I_NOTES - Notas de cancelamento 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/01 
          NOTAS: 
        *********************************************************************************/
        l_message debug_msg;
    
    BEGIN
        IF NOT cancel_mov_no_commit(i_lang, i_movement, i_prof, i_notes, i_prof_cat_type, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_MOV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_mov;

    FUNCTION cancel_mov_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_movement      IN movement.id_movement%TYPE,
        i_prof          IN profissional,
        i_notes         IN movement.notes_cancel%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar movimento 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_MOVEMENT - ID do movimento a cancelar 
                 I_PROF - ID do profissional responsável pelo cancelamento 
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                         como é retornada em PK_LOGIN.GET_PROF_PREF 
                                 I_NOTES - Notas de cancelamento 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/01 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_mov IS
            SELECT flg_status, id_episode
              FROM movement
             WHERE id_movement = i_movement;
        r_mov c_mov%ROWTYPE;
    
        CURSOR c_req_exam IS
            SELECT 'X'
              FROM exam_req_det r, movement m
             WHERE m.id_movement = i_movement
               AND m.id_movement = r.id_movement
               AND r.flg_status IN ('R', 'P', 'T');
    
        CURSOR c_req_analysis IS
            SELECT 'X'
              FROM movement m, analysis_req_det a
             WHERE m.id_movement = i_movement
               AND m.id_movement = a.id_movement
               AND a.flg_status IN ('R', 'P', 'T');
    
        CURSOR c_upd_mov(l_id_episode IN movement.id_episode%TYPE) IS
            SELECT dt_req_tstz, id_movement
              FROM movement
             WHERE id_movement != i_movement
               AND flg_status = pk_alert_constant.g_mov_status_pend
               AND id_episode = l_id_episode;
    
        l_status_epis_prof_resp VARCHAR2(0050);
        l_char                  VARCHAR2(1);
        l_count_oris            PLS_INTEGER;
        l_id_room               room.id_room%TYPE;
        l_oris_episode          episode.id_episode%TYPE;
        l_count_epis_prof_resp  NUMBER;
        l_ret                   BOOLEAN;
        l_found                 BOOLEAN;
        l_error_in              t_error_in := t_error_in();
    
        l_sys_alert_event_row sys_alert_event%ROWTYPE;
    
        l_rows table_varchar;
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
        l_sysdate_char CONSTANT VARCHAR2(14) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                            i_date => l_sysdate_tstz,
                                                                            i_prof => i_prof);
    
    BEGIN
        l_message := 'GET CURSOR C_MOV';
        OPEN c_mov;
        FETCH c_mov
            INTO r_mov;
        IF r_mov.flg_status IN (pk_alert_constant.g_mov_status_finish,
                                pk_alert_constant.g_mov_status_interr,
                                pk_alert_constant.g_mov_status_cancel)
        THEN
            l_error_in.set_all(i_lang,
                               'TRANSPORT_M004',
                               pk_message.get_message(i_lang, 'TRANSPORT_M004'),
                               l_message,
                               g_package_owner,
                               g_package_name,
                               'CANCEL_MOV_NO_COMMIT',
                               pk_message.get_message(i_lang, 'TRANSPORT_M004'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            RETURN l_ret;
        END IF;
        CLOSE c_mov;
    
        --jsilva 30-03-2007 não é possivel cancelar transportes associados a transferências de serviço
        SELECT COUNT(*)
          INTO l_count_epis_prof_resp
          FROM epis_prof_resp
         WHERE id_movement = i_movement;
        IF l_count_epis_prof_resp > 0
        THEN
            SELECT flg_status
              INTO l_status_epis_prof_resp
              FROM epis_prof_resp
             WHERE id_movement = i_movement;
            IF l_status_epis_prof_resp != pk_alert_constant.g_cancelled
            THEN
                l_error_in.set_all(i_lang,
                                   'TRANSPORT_M006',
                                   pk_message.get_message(i_lang, 'TRANSPORT_M004'),
                                   l_message,
                                   g_package_owner,
                                   g_package_name,
                                   'CANCEL_MOV_NO_COMMIT',
                                   pk_message.get_message(i_lang, 'TRANSPORT_M006'),
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN l_ret;
            END IF;
        END IF;
    
        -- Verificar se existem requisições associadas ao mov a cancelar 
        l_message := 'GET CURSOR C_REQ_EXAM';
        OPEN c_req_exam;
        FETCH c_req_exam
            INTO l_char;
        l_found := c_req_exam%NOTFOUND;
        CLOSE c_req_exam;
        IF l_found
        THEN
            l_message := 'GET CURSOR C_REQ_ANALYSIS';
            OPEN c_req_analysis;
            FETCH c_req_analysis
                INTO l_char;
            l_found := c_req_analysis%FOUND;
            CLOSE c_req_analysis;
            IF l_found
            THEN
                l_error_in.set_all(i_lang,
                                   'TRANSPORT_M003',
                                   pk_message.get_message(i_lang, 'TRANSPORT_M004'),
                                   l_message,
                                   g_package_owner,
                                   g_package_name,
                                   'CANCEL_MOV_NO_COMMIT',
                                   pk_message.get_message(i_lang, 'TRANSPORT_M003'),
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN l_ret;
            END IF;
        
        ELSE
            l_error_in.set_all(i_lang,
                               'TRANSPORT_M003',
                               pk_message.get_message(i_lang, 'TRANSPORT_M004'),
                               l_message,
                               g_package_owner,
                               g_package_name,
                               'CANCEL_MOV_NO_COMMIT',
                               pk_message.get_message(i_lang, 'TRANSPORT_M003'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            RETURN l_ret;
        END IF;
    
        l_message := 'CANCEL MOVEMENT';
        /* <DENORM Fábio> */
        ts_movement.upd(id_movement_in     => i_movement,
                        id_prof_cancel_in  => i_prof.id,
                        dt_cancel_tstz_in  => l_sysdate_tstz,
                        flg_status_in      => pk_alert_constant.g_mov_status_cancel,
                        notes_cancel_in    => i_notes,
                        id_prof_cancel_nin => FALSE,
                        dt_cancel_tstz_nin => FALSE,
                        notes_cancel_nin   => FALSE,
                        rows_out           => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MOVEMENT',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PROF_CANCEL',
                                                                      'DT_CANCEL_TSTZ',
                                                                      'FLG_STATUS',
                                                                      'NOTES_CANCEL'));
    
        IF SQL%ROWCOUNT = 1
        THEN
        
            -- JS: 2008-03-28: Delete alerts for "PATIENT_MOV" (Alert id 9)
            l_message                          := 'DELETE ALERTS(PATIENT_MOV)';
            l_sys_alert_event_row.id_sys_alert := 9;
            l_sys_alert_event_row.id_episode   := r_mov.id_episode;
            l_sys_alert_event_row.id_record    := i_movement;
        
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event_row,
                                                    o_error           => o_error)
            THEN
                pk_alertlog.log_error('Error deleting alerts');
                pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                      l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                      l_sys_alert_event_row.id_record);
                --pk_alertlog.log_error(l_error);
                RETURN FALSE;
            END IF;
        
            -- Se o mov a cancelar estava "em transporte", os mov "pendentes" do mm episódio 
            -- passam a "requisitados" 
            IF r_mov.flg_status = pk_alert_constant.g_mov_status_transp
            THEN
                l_message := 'LOOP';
                l_rows    := table_varchar();
                FOR r_upd_mov IN c_upd_mov(r_mov.id_episode)
                LOOP
                    l_message := 'UPDATE MOVEMENT';
                    /* <DENORM Fábio> */
                    ts_movement.upd(flg_status_in  => pk_alert_constant.g_mov_status_req,
                                    id_movement_in => r_upd_mov.id_movement,
                                    rows_out       => l_rows);
                
                    -- JS: 2008-03-28: Insert alert event for "PATIENT_MOV" (Alert id 9)
                    l_message                          := 'INSERT ALERT(PATIENT_MOV)';
                    l_sys_alert_event_row.id_sys_alert := 9;
                    l_sys_alert_event_row.id_episode   := r_mov.id_episode;
                    l_sys_alert_event_row.id_record    := r_upd_mov.id_movement;
                    l_sys_alert_event_row.dt_record    := r_upd_mov.dt_req_tstz;
                    l_sys_alert_event_row.replace1     := pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                                  i_prof.institution,
                                                                                  i_prof.software);
                
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event_row,
                                                            i_flg_type_dest   => NULL,
                                                            o_error           => o_error)
                    THEN
                        pk_alertlog.log_error('Error inserting alert');
                        pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert ||
                                              '; id_episode: ' || l_sys_alert_event_row.id_episode ||
                                              '; id_record(id_movement): ' || l_sys_alert_event_row.id_record);
                        --pk_alertlog.log_error(l_error);
                        RETURN FALSE;
                    END IF;
                
                    l_message := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
                    IF NOT pk_visit.update_epis_info(i_lang                 => i_lang,
                                                     i_id_episode           => r_mov.id_episode,
                                                     i_id_prof              => i_prof,
                                                     i_dt_entrance_room     => NULL,
                                                     i_dt_last_interaction  => l_sysdate_char,
                                                     i_dt_movement          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                           r_upd_mov.dt_req_tstz,
                                                                                                           i_prof),
                                                     i_dt_harvest           => NULL,
                                                     i_dt_next_drug         => NULL,
                                                     i_dt_first_obs         => l_sysdate_char,
                                                     i_dt_next_intervention => NULL,
                                                     i_dt_next_vital_sign   => NULL,
                                                     i_dt_next_position     => NULL,
                                                     i_dt_harvest_mov       => NULL,
                                                     i_dt_first_nurse_obs   => NULL,
                                                     i_prof_cat_type        => i_prof_cat_type,
                                                     o_error                => o_error)
                    
                    THEN
                        RETURN FALSE;
                    END IF;
                END LOOP;
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'MOVEMENT',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
        ELSE
            l_error_in.set_all(i_lang,
                               'MOVEMENT_M001',
                               pk_message.get_message(i_lang, 'MOVEMENT_M001'),
                               l_message,
                               g_package_owner,
                               g_package_name,
                               'CANCEL_MOV_NO_COMMIT',
                               pk_message.get_message(i_lang, 'MOVEMENT_M001'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            RETURN l_ret;
        END IF;
    
        l_message := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => r_mov.id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --verifica se a sala de destino é uma sala do bloco operatório
        l_message := 'CHECK SR TRANSPORT';
        SELECT COUNT(*)
          INTO l_count_oris
          FROM movement m, department d, room r, software_dept sd
         WHERE m.id_movement = i_movement
           AND sd.id_software = pk_alert_constant.g_soft_oris
           AND d.id_dept = sd.id_dept
           AND d.id_institution = i_prof.institution
           AND r.id_department = d.id_department
           AND r.id_room = m.id_room_to;
    
        IF nvl(l_count_oris, 0) > 0
        THEN
            --Determina o episódio de bloco. Só actualiza o estado do paciente se só existir um episódio de bloco
            --  activo e agendado para este paciente
        
            IF NOT pk_sr_output.get_oris_episode(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_movement     => i_movement,
                                                 o_oris_episode => l_oris_episode,
                                                 o_id_room      => l_id_room,
                                                 o_error        => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            IF l_oris_episode IS NOT NULL
            THEN
                --Actualiza estado do doente no ORIS      
                --       l_message := 'GET ID_ROOM';
                --       select id_room_to, id_episode 
                --       into l_id_room, l_episode
                --       from movement 
                --       where id_movement = I_MOVEMENT;   
            
                l_message := 'UPDATE ORIS PATIENT STATUS';
                IF NOT pk_sr_output.set_patient_status(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_episode    => l_oris_episode,
                                                       i_room       => l_id_room,
                                                       i_dt_mov_str => pk_date_utils.date_send_tsz(i_lang,
                                                                                                   l_sysdate_tstz,
                                                                                                   i_prof),
                                                       i_action     => 'C',
                                                       o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_MOV_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION cancel_movement_request
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_movement IN movement.id_movement%TYPE,
        i_notes    IN movement.notes_cancel%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_mov IS
            SELECT m.flg_status, m.id_episode
              FROM movement m
             WHERE m.id_movement = i_movement;
    
        CURSOR c_upd_mov(l_id_episode IN movement.id_episode%TYPE) IS
            SELECT dt_req_tstz, id_movement
              FROM movement
             WHERE id_movement != i_movement
               AND flg_status = pk_alert_constant.g_mov_status_pend
               AND id_episode = l_id_episode;
    
        r_mov c_mov%ROWTYPE;
    
        l_found NUMBER := 0;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
        l_sysdate_char CONSTANT VARCHAR2(14) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                            i_date => l_sysdate_tstz,
                                                                            i_prof => i_prof);
    
        l_rows table_varchar;
    
    BEGIN
    
        g_error := 'GET CURSOR C_MOV';
        OPEN c_mov;
        FETCH c_mov
            INTO r_mov;
        CLOSE c_mov;
    
        IF r_mov.flg_status IN (pk_alert_constant.g_mov_status_finish,
                                pk_alert_constant.g_mov_status_interr,
                                pk_alert_constant.g_mov_status_cancel)
        THEN
            RETURN TRUE;
        END IF;
    
        -- Verificar se existem requisições associadas ao mov a cancelar 
        g_error := 'GET CURSOR C_REQ_EXAM';
        BEGIN
            SELECT 1
              INTO l_found
              FROM exam_req_det erd
             WHERE erd.id_movement = i_movement
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    SELECT 1
                      INTO l_found
                      FROM analysis_req_det ard
                     WHERE ard.id_movement = i_movement
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_found := 0;
                END;
        END;
    
        IF l_found = 1
        THEN
            g_error := 'CANCEL MOVEMENT';
            ts_movement.upd(id_movement_in     => i_movement,
                            id_prof_cancel_in  => i_prof.id,
                            dt_cancel_tstz_in  => l_sysdate_tstz,
                            flg_status_in      => pk_alert_constant.g_mov_status_cancel,
                            notes_cancel_in    => i_notes,
                            id_prof_cancel_nin => FALSE,
                            dt_cancel_tstz_nin => FALSE,
                            notes_cancel_nin   => FALSE,
                            rows_out           => l_rows);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'MOVEMENT',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_PROF_CANCEL',
                                                                          'DT_CANCEL_TSTZ',
                                                                          'FLG_STATUS',
                                                                          'NOTES_CANCEL'));
        
            -- JS: 2008-03-28: Delete alerts for "PATIENT_MOV" (Alert id 9)
            g_error := 'DELETE ALERTS(PATIENT_MOV)';
        
            l_sys_alert_event.id_sys_alert := 9;
            l_sys_alert_event.id_episode   := r_mov.id_episode;
            l_sys_alert_event.id_record    := i_movement;
        
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                pk_alertlog.log_error('Error deleting alerts');
                pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event.id_sys_alert || '; id_episode: ' ||
                                      l_sys_alert_event.id_episode || '; id_record(id_movement): ' ||
                                      l_sys_alert_event.id_record);
                RETURN FALSE;
            END IF;
        
            -- Se o mov a cancelar estava "em transporte", os mov "pendentes" do mm episódio 
            -- passam a "requisitados" 
            IF r_mov.flg_status = pk_alert_constant.g_mov_status_transp
            THEN
                g_error := 'LOOP';
                l_rows  := table_varchar();
            
                FOR r_upd_mov IN c_upd_mov(r_mov.id_episode)
                LOOP
                    g_error := 'UPDATE MOVEMENT';
                    ts_movement.upd(flg_status_in  => pk_alert_constant.g_mov_status_req,
                                    id_movement_in => r_upd_mov.id_movement,
                                    rows_out       => l_rows);
                
                    -- JS: 2008-03-28: Insert alert event for "PATIENT_MOV" (Alert id 9)
                    g_error := 'INSERT ALERT(PATIENT_MOV)';
                
                    l_sys_alert_event.id_sys_alert := 9;
                    l_sys_alert_event.id_episode   := r_mov.id_episode;
                    l_sys_alert_event.id_record    := r_upd_mov.id_movement;
                    l_sys_alert_event.dt_record    := r_upd_mov.dt_req_tstz;
                    l_sys_alert_event.replace1     := pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                              i_prof.institution,
                                                                              i_prof.software);
                
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            i_flg_type_dest   => NULL,
                                                            o_error           => o_error)
                    THEN
                        pk_alertlog.log_error('Error inserting alert');
                        pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event.id_sys_alert || '; id_episode: ' ||
                                              l_sys_alert_event.id_episode || '; id_record(id_movement): ' ||
                                              l_sys_alert_event.id_record);
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
                    IF NOT pk_visit.update_epis_info(i_lang                 => i_lang,
                                                     i_id_episode           => r_mov.id_episode,
                                                     i_id_prof              => i_prof,
                                                     i_dt_entrance_room     => NULL,
                                                     i_dt_last_interaction  => l_sysdate_char,
                                                     i_dt_movement          => pk_date_utils.date_send_tsz(i_lang,
                                                                                                           r_upd_mov.dt_req_tstz,
                                                                                                           i_prof),
                                                     i_dt_harvest           => NULL,
                                                     i_dt_next_drug         => NULL,
                                                     i_dt_first_obs         => l_sysdate_char,
                                                     i_dt_next_intervention => NULL,
                                                     i_dt_next_vital_sign   => NULL,
                                                     i_dt_next_position     => NULL,
                                                     i_dt_harvest_mov       => NULL,
                                                     i_dt_first_nurse_obs   => NULL,
                                                     i_prof_cat_type        => pk_prof_utils.get_category(i_lang, i_prof),
                                                     o_error                => o_error)
                    
                    THEN
                        RETURN FALSE;
                    END IF;
                END LOOP;
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'MOVEMENT',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
        
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => r_mov.id_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => l_sysdate_tstz,
                                          i_dt_first_obs        => l_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
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
                                              'CANCEL_MOVEMENT_REQUEST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_movement_request;

    FUNCTION check_mov
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN movement.id_episode%TYPE,
        i_room        IN movement.id_room_to%TYPE,
        i_prof        IN profissional,
        o_id_movement OUT movement.id_movement%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verificar se movimento pode ser efectuado 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio  
                     I_ROOM - ID da sala do movimento requisitado ou em curso 
                          para a sala pretendida, caso exista  
                  Saida:   O_ID_MOVEMENT - ID do movimento encontrado 
                     O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe  
                     O_MSG_TEXT - mensagem  
                     O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                             O_FLG_SHOW = Y 
                     O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                            Tb pode mostrar combinações destes, qd é p/ mostrar 
                          + do q 1 botão 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/01 
          NOTAS: 
        *********************************************************************************/
        l_flg_type            episode.id_epis_type%TYPE;
        l_flg_status          episode.flg_status%TYPE;
        l_id_room             epis_info.id_room%TYPE;
        l_dt_entrance_room    VARCHAR2(200); --EPIS_INFO.DT_ENTRANCE_ROOM%TYPE;
        l_dt_last_interaction VARCHAR2(200); --EPIS_INFO.DT_LAST_INTERACTION%TYPE;
        l_dt_movement         VARCHAR2(200); --EPIS_INFO.DT_MOVEMENT%TYPE; 
        l_desc_room           VARCHAR2(200);
        l_id_mov              movement.id_movement%TYPE;
        l_found               BOOLEAN;
    
        l_message debug_msg;
    
        CURSOR c_movement IS
            SELECT id_movement
              FROM movement
             WHERE id_episode = i_episode
               AND id_room_to = i_room
               AND flg_status IN (pk_alert_constant.g_mov_status_req,
                                  pk_alert_constant.g_mov_status_transp,
                                  pk_alert_constant.g_mov_status_pend);
    
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
    
        l_message := 'CALL TO PK_VISIT.GET_EPIS_INFO';
        IF NOT pk_visit.get_epis_info(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_prof                => i_prof,
                                      o_flg_type            => l_flg_type,
                                      o_flg_status          => l_flg_status,
                                      o_id_room             => l_id_room,
                                      o_desc_room           => l_desc_room,
                                      o_dt_entrance_room    => l_dt_entrance_room,
                                      o_dt_last_interaction => l_dt_last_interaction,
                                      o_dt_movement         => l_dt_movement,
                                      o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_message := 'COMPARE ROOMS';
        IF l_id_room = i_room
        THEN
            -- Localização actual do doente é o destino do movimento 
            o_msg_title := pk_message.get_message(i_lang, 'TRANSPORT_M005');
            o_msg_text  := pk_message.get_message(i_lang, 'TRANSPORT_M001');
            o_flg_show  := pk_alert_constant.g_yes;
            o_button    := 'R';
        
        ELSE
            l_message := 'GET CURSOR C_MOVEMENT';
            OPEN c_movement;
            FETCH c_movement
                INTO l_id_mov;
            l_found := c_movement%FOUND;
            CLOSE c_movement;
            IF l_found
            THEN
                -- Já existe movimento requisitado ou em curso para a sala pretendida 
                o_id_movement := l_id_mov;
                o_msg_title   := pk_message.get_message(i_lang, 'TRANSPORT_M005');
                o_msg_text    := pk_message.get_message(i_lang, 'TRANSPORT_M002');
                o_flg_show    := pk_alert_constant.g_yes;
                o_button      := 'R';
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_MOV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_transp_mov
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN movement.id_episode%TYPE,
        o_movement OUT movement.id_movement%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verificar a existência de movimentos "em transporte" para o episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio  
                  Saida:   O_MOVEMENT - ID do movimento "em transporte" 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/01 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_exist IS
            SELECT id_movement
              FROM movement
             WHERE id_episode = i_episode
               AND flg_status = pk_alert_constant.g_mov_status_transp;
        l_id      movement.id_movement%TYPE;
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR C_EXIST';
        OPEN c_exist;
        FETCH c_exist
            INTO l_id;
        CLOSE c_exist;
        o_movement := l_id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TRANSP_MOV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_mov_info
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional,
        o_mov      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter info detalhe de um movimento 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_MOVEMENT - ID do movimento cuja info se pretende 
                  Saida:   O_MOV - array com a info do movimento  
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/04/31 
          NOTAS: 
        *********************************************************************************/
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR C_MOV';
        OPEN o_mov FOR
            SELECT m.flg_status,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_destination,
                   pk_translation.get_translation(i_lang, dep.code_department) dep_destination,
                   nvl(nvl(r1.desc_room, pk_translation.get_translation(i_lang, r1.code_room)),
                       pk_message.get_message(i_lang, 'N/A')) room_origin,
                   pk_translation.get_translation(i_lang, dep1.code_department) dep_origin,
                   pk_sysdomain.get_domain('MOVEMENT.FLG_STATUS', m.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_req_tstz, i_prof.institution, i_prof.software) dt_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, preq.id_professional) prof_req,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_end_tstz, i_prof.institution, i_prof.software) dt_end,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pmov.id_professional) prof_mov,
                   pk_date_utils.dt_chr_tsz(i_lang, m.dt_end_tstz, i_prof) date_end,
                   pk_date_utils.date_char_hour_tsz(i_lang, m.dt_end_tstz, i_prof.institution, i_prof.software) hour_end,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prcv.id_professional) prof_receive,
                   pk_date_utils.dt_chr_tsz(i_lang, m.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, m.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pcanc.id_professional) prof_cancel,
                   m.notes_cancel,
                   pk_translation.get_translation(i_lang, nec.code_necessity) transp
              FROM movement     m,
                   room         r,
                   professional preq,
                   professional pmov,
                   professional prcv,
                   professional pcanc,
                   necessity    nec,
                   department   dep,
                   room         r1,
                   department   dep1
             WHERE id_movement = i_movement
               AND preq.id_professional = m.id_prof_request
               AND pmov.id_professional(+) = m.id_prof_move
               AND prcv.id_professional(+) = m.id_prof_receive
               AND pcanc.id_professional(+) = m.id_prof_cancel
               AND nec.id_necessity(+) = m.id_necessity
               AND r.id_room = m.id_room_to
               AND dep.id_department = r.id_department
               AND r1.id_room = m.id_room_from
               AND dep1.id_department = r1.id_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOV_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_mov);
            RETURN FALSE;
    END;

    FUNCTION get_from_location
    (
        i_lang        IN language.id_language%TYPE,
        i_movement    IN movement.id_movement%TYPE,
        i_prof        IN profissional,
        o_movement    OUT movement.id_movement%TYPE,
        o_id_location OUT movement.id_room_to%TYPE,
        o_location    OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter o destino do último mov (anterior ao indicado como par entrada) 
                  para saber a origem do mov actual 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_MOVEMENT - ID do movimento actual   
                  Saida:   O_LOCATION - Destino do mov anterior = origem do mov actual 
                     O_ID_LOCATION - ID da sala de destino do mov anterior 
                     O_MOVEMENT - ID do mov anterior 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/02 
          NOTAS: 
        *********************************************************************************/
        l_dt                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_type            episode.id_epis_type%TYPE;
        l_flg_status          episode.flg_status%TYPE;
        l_id_room             epis_info.id_room%TYPE;
        l_dt_entrance_room    VARCHAR2(50);
        l_dt_last_interaction VARCHAR2(50);
        l_dt_movement         VARCHAR2(50);
        l_desc_room           VARCHAR2(200);
    
        CURSOR c_mov IS
            SELECT flg_status, dt_begin_tstz, dt_end_tstz, dt_cancel_tstz, id_episode
              FROM movement
             WHERE id_movement = i_movement;
        r_mov c_mov%ROWTYPE;
    
        CURSOR c_id_mov IS
            SELECT m.id_movement, m.id_room_to, nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
              FROM movement m, room r
             WHERE m.id_episode = r_mov.id_episode
               AND m.flg_status = pk_alert_constant.g_mov_status_finish
               AND m.dt_end_tstz = (SELECT MAX(m1.dt_end_tstz)
                                      FROM movement m1
                                     WHERE m1.id_episode = r_mov.id_episode
                                       AND m1.flg_status = pk_alert_constant.g_mov_status_finish
                                       AND m1.dt_end_tstz < l_dt)
               AND r.id_room = m.id_room_to;
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR C_MOV';
        OPEN c_mov;
        FETCH c_mov
            INTO r_mov;
        CLOSE c_mov;
    
        l_message := 'GET L_DT';
        IF r_mov.flg_status = pk_alert_constant.g_mov_status_finish
        THEN
            l_dt := r_mov.dt_end_tstz;
        
        ELSIF r_mov.flg_status = pk_alert_constant.g_mov_status_interr
        THEN
            l_dt := r_mov.dt_begin_tstz;
        
        ELSIF r_mov.flg_status = pk_alert_constant.g_mov_status_cancel
        THEN
            l_dt := r_mov.dt_cancel_tstz;
        
        ELSE
            l_message := 'CALL TO PK_VISIT.GET_EPIS_INFO ';
            IF NOT pk_visit.get_epis_info(i_lang                => i_lang,
                                          i_id_episode          => r_mov.id_episode,
                                          i_prof                => i_prof,
                                          o_flg_type            => l_flg_type,
                                          o_flg_status          => l_flg_status,
                                          o_id_room             => l_id_room,
                                          o_desc_room           => l_desc_room,
                                          o_dt_entrance_room    => l_dt_entrance_room,
                                          o_dt_last_interaction => l_dt_last_interaction,
                                          o_dt_movement         => l_dt_movement,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
            o_id_location := l_id_room;
        END IF;
    
        l_message := 'CHECK R_MOV.FLG_STATUS';
        IF r_mov.flg_status IN (pk_alert_constant.g_mov_status_finish,
                                pk_alert_constant.g_mov_status_interr,
                                pk_alert_constant.g_mov_status_cancel)
        THEN
            l_message := 'GET CURSOR C_ID_MOV';
            OPEN c_id_mov;
            FETCH c_id_mov
                INTO o_movement, o_id_location, o_location;
            CLOSE c_id_mov;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FROM_LOCATION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_from_location_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter o destino do último mov (anterior ao indicado como par entrada) 
                  para saber a origem do mov actual. Retorna VARCHAR2 para poder ser 
                usado num Cursor (ver PK_GRID)  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_MOVEMENT - ID do movimento actual   
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/02 
          NOTAS: 
        *********************************************************************************/
        l_movement    movement.id_movement%TYPE;
        l_id_location movement.id_room_to%TYPE;
        l_location    VARCHAR2(200);
        l_error       t_error_out;
    
    BEGIN
        IF NOT get_from_location(i_lang        => i_lang,
                                 i_movement    => i_movement,
                                 i_prof        => i_prof,
                                 o_movement    => l_movement,
                                 o_id_location => l_id_location,
                                 o_location    => l_location,
                                 o_error       => l_error)
        THEN
            pk_utils.undo_changes;
            RETURN NULL;
        END IF;
    
        RETURN l_location;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN NULL;
    END;

    FUNCTION get_mov_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE,
        i_prof    IN profissional,
        o_mov     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os movimentos de um episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/02 
          NOTAS: 
        *********************************************************************************/
        l_message    debug_msg;
        l_epis_type  episode.id_epis_type%TYPE;
        l_id_episode episode.id_episode%TYPE := i_episode;
    BEGIN
        l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        IF (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            l_id_episode := pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_episode);
        END IF;
        --        IF NOT
        --            pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => o_error)
        --        THEN
        --            RETURN FALSE;
        --        END IF;
        l_message := 'GET L_AUX';
        OPEN o_mov FOR
            SELECT m.id_movement,
                   m.flg_status,
                   r.id_room,
                   preq.id_professional id_prof_req,
                   pk_translation.get_translation(i_lang, nec.code_necessity) transport,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_to,
                   pk_translation.get_translation(i_lang, dep.code_department) dep_to,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, preq.id_professional) prof_req,
                   pk_date_utils.dt_chr_tsz(i_lang, m.dt_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, m.dt_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pmov.id_professional) prof_mov,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_begin_tstz, i_prof.institution, i_prof.software) dt_mov,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, precv.id_professional) prof_rec,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_end_tstz, i_prof.institution, i_prof.software) dt_rec,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pcanc.id_professional) prof_canc,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   decode(m.flg_status,
                          pk_alert_constant.g_mov_status_req,
                          pk_date_utils.get_elapsed_sysdate_tsz(i_lang, m.dt_req_tstz),
                          pk_alert_constant.g_mov_status_pend,
                          pk_date_utils.get_elapsed_sysdate_tsz(i_lang, m.dt_req_tstz),
                          pk_alert_constant.g_mov_status_transp,
                          pk_date_utils.get_elapsed_sysdate_tsz(i_lang, m.dt_begin_tstz),
                          pk_alert_constant.g_mov_status_finish,
                          pk_date_utils.date_char_tsz(i_lang, m.dt_end_tstz, i_prof.institution, i_prof.software),
                          pk_alert_constant.g_mov_status_cancel,
                          pk_date_utils.date_char_tsz(i_lang, m.dt_cancel_tstz, i_prof.institution, i_prof.software),
                          pk_alert_constant.g_mov_status_interr,
                          pk_date_utils.date_char_tsz(i_lang, m.dt_cancel_tstz, i_prof.institution, i_prof.software),
                          '') dt,
                   pk_sysdomain.get_domain('MOVEMENT.FLG_STATUS', m.flg_status, i_lang) state,
                   pk_sysdomain.get_img(i_lang, 'MOVEMENT.FLG_STATUS', m.flg_status) img,
                   decode(m.flg_status,
                          pk_alert_constant.g_mov_status_cancel,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_mov_status_interr,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, m.dt_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   decode(m.notes_cancel, '', '', pk_message.get_message(i_lang, 'COMMON_M008')) title_notes
              FROM movement     m,
                   episode      e,
                   room         r,
                   professional preq,
                   professional pmov,
                   professional precv,
                   professional pcanc,
                   department   dep,
                   necessity    nec
             WHERE m.id_episode = e.id_episode
               AND r.id_room = m.id_room_to
               AND dep.id_department = r.id_department
               AND (m.id_episode = l_id_episode OR m.id_episode_write = l_id_episode) --ET 2007/02/24
               AND preq.id_professional = m.id_prof_request
               AND pmov.id_professional(+) = m.id_prof_move
               AND precv.id_professional(+) = m.id_prof_receive
               AND pcanc.id_professional(+) = m.id_prof_cancel
               AND nec.id_necessity(+) = m.id_necessity
             ORDER BY pk_sysdomain.get_rank(i_lang, 'MOVEMENT.FLG_STATUS', m.flg_status), m.dt_req_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOV_EPISODE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_mov);
            RETURN FALSE;
    END;

    FUNCTION insert_movement_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar a coluna de transportes da tabela GRID_TASK  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio
                  Saida: O_ERROR - erro 
          CRIAÇÃO: SS 2006/01/23  
          NOTAS:
        *********************************************************************************/
    
        l_status_str grid_task.movement%TYPE;
        l_exception EXCEPTION;
    BEGIN
        l_status_str := pk_logic_movements.get_movement_status_str(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_episode => i_episode);
    
        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK';
        --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
        IF NOT pk_grid.update_grid_task(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_episode    => i_episode,
                                        movement_in  => l_status_str,
                                        movement_nin => FALSE,
                                        o_error      => o_error)
        THEN
            g_error := 'ERROR UPDATE_GRID_TASK';
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'INSERT_MOVEMENT_TASK',
                                                     o_error);
    END;

    FUNCTION update_movement_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar a coluna de transportes da tabela GRID_TASK  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio
                  Saida: O_ERROR - erro 
          CRIAÇÃO: SS 2006/01/30  
          NOTAS:
        *********************************************************************************/
        CURSOR c_mov IS
            SELECT s.rank, mov.dt_req_tstz dt_req, mov.flg_status, nvl(mov.dt_begin_tstz, mov.dt_req_tstz) dt_begin
              FROM movement mov, sys_domain s
             WHERE mov.id_episode = i_episode
               AND mov.flg_status NOT IN (pk_alert_constant.g_mov_status_cancel,
                                          pk_alert_constant.g_mov_status_finish,
                                          pk_alert_constant.g_mov_status_interr)
               AND mov.flg_status = s.val
               AND s.code_domain = 'MOVEMENT.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
             ORDER BY dt_begin, rank;
    
        -- Obter ID do atalho
        CURSOR c_short_transp IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = 'GRID_TRANSPORT'
               AND id_software = i_prof.software
               AND id_institution IN (0, i_prof.institution)
               AND id_parent IS NULL
             ORDER BY id_institution DESC;
    
        l_short_transp sys_shortcut.id_sys_shortcut%TYPE;
        l_rank         sys_domain.rank%TYPE;
        l_dt_req       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin     TIMESTAMP WITH LOCAL TIME ZONE;
        l_status       movement.flg_status%TYPE;
        l_out          VARCHAR2(100);
        l_found        BOOLEAN;
        l_message      debug_msg;
    
    BEGIN
        l_message := 'OPEN C_SHORT_TRANSP';
        OPEN c_short_transp;
        FETCH c_short_transp
            INTO l_short_transp;
        CLOSE c_short_transp;
    
        l_message := 'OPEN C_MOV';
        OPEN c_mov;
        FETCH c_mov
            INTO l_rank, l_dt_req, l_status, l_dt_begin;
        l_found := c_mov%FOUND;
        CLOSE c_mov;
    
        l_message := 'GET L_OUT';
        IF l_found
        THEN
            IF l_status = pk_alert_constant.g_mov_status_transp
            THEN
                l_out := 'xxxxxxxxxxxxxx|' || pk_alert_constant.g_display_type_icon || '|X|' ||
                         pk_sysdomain.get_img(i_lang, 'MOVEMENT.FLG_STATUS', pk_alert_constant.g_mov_status_transp);
            ELSE
                l_out := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' ||
                         pk_alert_constant.g_display_type_date || '|X';
            END IF;
        END IF;
    
        l_message := 'GET SHORTCUT';
        IF l_out IS NOT NULL
        THEN
            l_out := l_short_transp || '|' || l_out;
        END IF;
    
        --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
        l_message := 'UPDATE GRID_TASK';
        UPDATE grid_task
           SET movement = l_out
         WHERE id_episode = i_episode;
    
        IF SQL%ROWCOUNT = 0
           AND l_out IS NOT NULL
        THEN
            l_message := 'INSERT GRID_TASK';
            INSERT INTO grid_task
                (id_grid_task, id_episode, movement)
            VALUES
                (seq_grid_task.nextval, i_episode, l_out);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_MOVEMENT_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_rooms_assig
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_room  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listagem de todas as salas para atribuição.
                        As salas lotadas serão representadas com um STATUS=S 
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                 I_PROF - ID do prof q acede 
         
                        SAIDA:   O_ROOM - array com todas as salas e respectivo status
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/08/21 
        *********************************************************************************/
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET CURSOR O_ROOM';
        OPEN o_room FOR
            SELECT id_room, desc_room, status
              FROM (SELECT ro.id_room,
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                           ro.capacity room_capacity,
                           pk_movement.get_status_room(ro.id_room, ro.capacity) status
                      FROM room ro, department dp, software_dept sd
                     WHERE ro.id_department = dp.id_department
                       AND sd.id_software = i_prof.software
                       AND dp.id_dept = sd.id_dept
                       AND dp.id_institution = i_prof.institution
                       AND ro.flg_available = pk_alert_constant.g_yes)
             ORDER BY id_room ASC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOMS_ASSIG',
                                              o_error);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END;

    FUNCTION get_status_room
    (
        i_room     IN room.id_room%TYPE,
        i_capacity IN room.capacity%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Devolve o status associada a cada sala tendo em conta: 
                         - Nº de pacientes > = Capacidade da sala - Status = S (sombreado)
                         - Nº de pacientes < Capacidade da sala - Status = B (Bold) 
           
           PARAMETROS:  ENTRADA: I_ROOM     - ID da Sala 
                                 I_CAPACITY - Capacidade da sala
          
          CRIAÇÃO: ET 2006/08/21  
        *********************************************************************************/
        l_cont_pat NUMBER(5) := 0;
        --
        CURSOR c_pat_cont IS
            SELECT COUNT(DISTINCT epis.id_episode)
              FROM episode epis, epis_info ei
             WHERE epis.flg_status = pk_alert_constant.g_epis_status_active
               AND epis.id_epis_type = pk_alert_constant.g_epis_type_emergency
               AND ei.id_room = i_room
               AND epis.id_episode = ei.id_episode;
    
    BEGIN
        OPEN c_pat_cont;
        FETCH c_pat_cont
            INTO l_cont_pat;
        CLOSE c_pat_cont;
    
        IF l_cont_pat > i_capacity
        THEN
            RETURN 'S';
        ELSIF l_cont_pat <= i_capacity
        THEN
            RETURN 'B';
        END IF;
        --  
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'B';
    END;

    --
    FUNCTION get_curr_local_type
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE
    ) RETURN department.flg_type%TYPE IS
        l_function_name CONSTANT obj_name := 'GET_CURR_LOCAL_TYPE';
        l_message debug_msg;
        l_error   t_error_out;
    
        l_curr_local_type department.flg_type%TYPE;
    
    BEGIN
        l_message := 'GET CURRENT LOCAL TYPE';
        SELECT d.flg_type
          INTO l_curr_local_type
          FROM epis_info ei
         INNER JOIN room r
            ON ei.id_room = r.id_room
         INNER JOIN department d
            ON r.id_department = d.id_department
         WHERE ei.id_episode = i_episode;
    
        RETURN l_curr_local_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_curr_local_type;
    --
    FUNCTION get_next_dest_type
    (
        i_lang           IN language.id_language%TYPE,
        i_mov_dest_types IN sys_config.value%TYPE,
        i_pos            IN PLS_INTEGER
    ) RETURN department.flg_type%TYPE IS
        l_function_name CONSTANT obj_name := 'GET_NEXT_DEST_TYPE';
        l_message debug_msg;
        l_error   t_error_out;
    
    BEGIN
        l_message := 'GET NEXT DESTINATION TYPE';
        RETURN substr(str1 => i_mov_dest_types, pos => i_pos, len => 1);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_next_dest_type;
    --
    FUNCTION get_prev_local
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE,
        i_type    IN department.flg_type%TYPE
    ) RETURN prev_local IS
        l_function_name CONSTANT obj_name := 'GET_PREV_LOCAL';
        l_message debug_msg;
        l_error   t_error_out;
    
        l_prev_local prev_local;
    
    BEGIN
        l_message := 'GET PREVIOUS LOCAL';
        SELECT dt.id_dept, d.id_department, r.id_room
          INTO l_prev_local.id_dept, l_prev_local.id_department, l_prev_local.id_room
          FROM movement m
         INNER JOIN room r
            ON m.id_room_from = r.id_room
         INNER JOIN department d
            ON r.id_department = d.id_department
         INNER JOIN dept dt
            ON d.id_dept = dt.id_dept
         WHERE m.id_episode = i_episode
           AND m.flg_status = pk_alert_constant.g_mov_status_finish
           AND d.flg_type = i_type
           AND m.dt_end_tstz = (SELECT MAX(mo.dt_end_tstz)
                                  FROM movement mo
                                 INNER JOIN room ro
                                    ON mo.id_room_from = ro.id_room
                                 INNER JOIN department de
                                    ON ro.id_department = de.id_department
                                 WHERE m.id_episode = mo.id_episode
                                   AND m.flg_status = mo.flg_status
                                   AND d.flg_type = de.flg_type);
        RETURN l_prev_local;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_prev_local;
    --
    FUNCTION get_default_destination
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN movement.id_episode%TYPE,
        o_dept       OUT dept.id_dept%TYPE,
        o_department OUT department.id_department%TYPE,
        o_room       OUT room.id_room%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_DEFAULT_DESTINATION';
        l_message debug_msg;
    
        l_mov_dest_types  sys_config.value%TYPE;
        l_curr_local_type department.flg_type%TYPE;
        l_next_dest_type  department.flg_type%TYPE;
        l_prev_local      prev_local;
        l_epis_type       episode.id_epis_type%TYPE;
        l_id_episode      episode.id_episode%TYPE := i_episode;
    BEGIN
        l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        IF (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            l_id_episode := pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_episode);
        END IF;
        l_message        := 'GET MOVEMENT DEFAULT DESTINATION TYPES';
        l_mov_dest_types := REPLACE(srcstr => pk_sysconfig.get_config(i_code_cf   => 'MOVEMENT_DEFAULT_DEST_TYPE',
                                                                      i_prof_inst => i_prof.institution,
                                                                      i_prof_soft => i_prof.software),
                                    oldsub => ' ',
                                    newsub => NULL);
    
        l_message         := 'GET CURRENT LOCAL TYPE';
        l_curr_local_type := pk_movement.get_curr_local_type(i_lang => i_lang, i_episode => l_id_episode);
    
        IF l_mov_dest_types IS NOT NULL
           AND l_curr_local_type IS NOT NULL
        THEN
            FOR i IN 1 .. length(ch => l_mov_dest_types)
            LOOP
                l_message        := 'GET NEXT DESTINATION TYPE (' || i || ')';
                l_next_dest_type := pk_movement.get_next_dest_type(i_lang           => i_lang,
                                                                   i_mov_dest_types => l_mov_dest_types,
                                                                   i_pos            => i);
            
                EXIT WHEN l_next_dest_type IS NULL OR l_next_dest_type = l_curr_local_type;
            
                l_message    := 'GET PREVIOUS LOCAL (' || i || ')';
                l_prev_local := get_prev_local(i_lang => i_lang, i_episode => l_id_episode, i_type => l_next_dest_type);
            
                EXIT WHEN l_prev_local.id_room IS NOT NULL;
            
            END LOOP;
        END IF;
    
        o_dept       := l_prev_local.id_dept;
        o_department := l_prev_local.id_department;
        o_room       := l_prev_local.id_room;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            o_dept       := NULL;
            o_department := NULL;
            o_room       := NULL;
            RETURN FALSE;
    END get_default_destination;

    FUNCTION set_location_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN movement.id_episode%TYPE,
        i_room    IN movement.id_room_to%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           PURPOSE:   Set the location in all episodes that belong to same visit
                         
           
           PARAMETERS:  IN: 
              i_lang    language id
              i_prof    profissional(id, institution, software)
              i_episode id episode
              i_room    id room
              
             OUT: o_error - error
          
          CREATION: FM 2009/09/25
        *********************************************************************************/
    
        l_message debug_msg;
        l_function_name CONSTANT obj_name := 'SET_LOCATION_VISIT';
        l_rows table_varchar;
    
    BEGIN
    
        l_message := 'GET MOVEMENT SET LOCATION VISIT';
    
        ts_epis_info.upd(id_room_in  => i_room,
                         id_room_nin => FALSE,
                         where_in    => 'id_episode IN
               (SELECT e.id_episode
                  FROM episode e
                 WHERE e.flg_status = ''' || pk_alert_constant.g_active || '''
                   AND e.id_visit IN (SELECT id_visit
                                        FROM epis_info ei
                                        JOIN episode e ON ei.id_episode = e.id_episode
                                       WHERE e.id_episode = ' || i_episode || '
                                         AND e.flg_status = ''' ||
                                        pk_alert_constant.g_active || '''))',
                         rows_out    => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_ROOM'));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_location_visit;

    --
    FUNCTION get_necess_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_mov     IN necessity.flg_mov%TYPE,
        o_necess  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_NECESS_LIST';
        l_message debug_msg;
    
        l_department department.id_department%TYPE;
        l_flg_type   department.flg_type%TYPE;
    
        l_necessity necessity.id_necessity%TYPE;
    
    BEGIN
        BEGIN
            l_message := 'GET CURRENT DEPARTMENT AND DEPARTMENT TYPE';
            SELECT d.id_department, d.flg_type
              INTO l_department, l_flg_type
              FROM epis_info ei
             INNER JOIN room r
                ON ei.id_room = r.id_room
             INNER JOIN department d
                ON r.id_department = d.id_department
             WHERE ei.id_episode = i_episode;
        
            l_message := 'GET DEFAULT MEAN OF TRANSPORT';
            SELECT id_necessity
              INTO l_necessity
              FROM (SELECT *
                      FROM (SELECT id_necessity, id_department, flg_type, id_institution, id_software, query_order
                              FROM (SELECT ndis.id_necessity,
                                           ndis.id_department,
                                           ndis.flg_type,
                                           ndis.id_institution,
                                           ndis.id_software,
                                           1 query_order
                                      FROM necessity_dept_inst_soft ndis
                                     WHERE ndis.id_department = l_department
                                       AND ndis.flg_area = pk_alert_constant.g_nece_dept_inst_soft_movement
                                       AND ndis.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                       AND ndis.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                     ORDER BY id_department NULLS LAST, id_institution DESC, id_software DESC)
                            UNION ALL
                            SELECT id_necessity, id_department, flg_type, id_institution, id_software, query_order
                              FROM (SELECT ndis.id_necessity,
                                           ndis.id_department,
                                           ndis.flg_type,
                                           ndis.id_institution,
                                           ndis.id_software,
                                           2 query_order
                                      FROM necessity_dept_inst_soft ndis
                                     WHERE ndis.flg_type = l_flg_type
                                       AND ndis.flg_area = pk_alert_constant.g_nece_dept_inst_soft_movement
                                       AND ndis.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                       AND ndis.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                     ORDER BY flg_type NULLS LAST, id_institution DESC, id_software DESC)) n
                     ORDER BY query_order ASC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_department := NULL;
                l_flg_type   := NULL;
                l_necessity  := NULL;
        END;
    
        l_message := 'OPEN CURSOR O_NECESS';
        OPEN o_necess FOR
            SELECT t.id_necessity, t.rank, t.necessity, t.flg_default
              FROM (SELECT n.id_necessity,
                           n.rank,
                           pk_translation.get_translation(i_lang, n.code_necessity) necessity,
                           decode(l_necessity, n.id_necessity, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                      FROM necessity_dept_inst_soft ndis
                      JOIN necessity n
                        ON ndis.id_necessity = n.id_necessity
                     WHERE n.flg_available = pk_alert_constant.g_yes
                       AND ndis.flg_area = pk_alert_constant.g_nece_dept_inst_soft_config
                       AND ndis.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND ndis.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                       AND (i_mov IS NULL OR n.flg_mov = i_mov)) t
             WHERE t.necessity IS NOT NULL
             ORDER BY t.rank, t.necessity;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_necess);
            RETURN FALSE;
    END;

    /*
    * Provide list of ongoing MOVEMENT tasks for the patient death feature. All the transports in this list must be possible to cancel.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_PATIENT         Patient ID
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   11-MAY-2010
    *
    */
    FUNCTION get_ongoing_tasks_transp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_ongoing_tasks_transp';
    
        t         tf_tasks_list;
        l_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WORKFLOW_WARNING_M024');
    
    BEGIN
    
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_list(id_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT m.id_movement id_task,
                       pk_translation.get_translation(i_lang, d.code_dept) || l_message ||
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_task,
                       pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, m.dt_req_tstz, i_prof) dt_task
                  FROM movement m
                 INNER JOIN episode e
                    ON e.id_episode = m.id_episode
                 INNER JOIN room r
                    ON r.id_room = m.id_room_to
                 INNER JOIN department dep
                    ON dep.id_department = r.id_department
                 INNER JOIN dept d
                    ON d.id_dept = dep.id_dept
                 INNER JOIN epis_type et
                    ON et.id_epis_type = e.id_epis_type
                 WHERE e.id_patient = i_id_patient
                   AND m.flg_status NOT IN (pk_alert_constant.g_monitor_vs_canc, pk_alert_constant.g_monitor_vs_fini)
                 ORDER BY dt_task DESC);
    
        RETURN t;
    
    END get_ongoing_tasks_transp;

    /*
    * Provide list of reactivatable MOVEMENT tasks for the patient death feature. All the monits must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_transp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
    
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_wfstatus_tasks_transp';
    
        t         tf_tasks_react_list;
        l_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WORKFLOW_WARNING_M024');
    
    BEGIN
        g_error := 'SELECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT stm.id_movement id_task,
                       st.id_susp_task id_susp_task,
                       pk_translation.get_translation(i_lang, d.code_dept) || l_message ||
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_task,
                       pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, m.dt_req_tstz, i_prof) dt_task
                  FROM susp_task st
                 INNER JOIN susp_task_movements stm
                    ON stm.id_susp_task = st.id_susp_task
                 INNER JOIN movement m
                    ON m.id_movement = stm.id_movement
                 INNER JOIN episode e
                    ON e.id_episode = m.id_episode
                 INNER JOIN room r
                    ON r.id_room = m.id_room_to
                 INNER JOIN department dep
                    ON dep.id_department = r.id_department
                 INNER JOIN dept d
                    ON d.id_dept = dep.id_dept
                 INNER JOIN epis_type et
                    ON et.id_epis_type = e.id_epis_type
                 WHERE st.id_susp_action = i_id_susp_action
                   AND st.flg_status = i_wfstatus
                 ORDER BY dt_task DESC);
    
        RETURN t;
    
    END get_wfstatus_tasks_transp;

    /*
    * Suspend the ongoing tasks - Movements
    * This function MUST not commit/rollback
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK               ID from the corresponding task
    * @param   I_FLG_REASON         Reason for the WF suspension: 'D' (Death)
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   13-MAY-2010
    *
    */
    FUNCTION suspend_task_transp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task       IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'suspend_task_transp';
    
        l_mess_error CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'MOVEMENT_M003');
    
        l_mess_reason   sys_message.desc_message%TYPE;
        l_prof_cat_type category.flg_type%TYPE;
        l_flg_status    movement.flg_status%TYPE;
        l_desc_movement VARCHAR2(4000 CHAR);
        l_char          VARCHAR2(1 CHAR);
        l_found         BOOLEAN;
        l_rows          table_varchar := table_varchar();
    
        CURSOR c_mov(pin_id_movement movement.id_movement%TYPE) IS
            SELECT m.flg_status
              FROM movement m
             WHERE m.id_movement = pin_id_movement;
        CURSOR c_mov_desc(pin_id_movement movement.id_movement%TYPE) IS
            SELECT pk_translation.get_translation(i_lang, d.code_dept) || ' - ' ||
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_task
              FROM movement m
             INNER JOIN room r
                ON r.id_room = m.id_room_to
             INNER JOIN department dep
                ON dep.id_department = r.id_department
             INNER JOIN dept d
                ON d.id_dept = dep.id_dept
             WHERE m.id_movement = pin_id_movement;
        -- Similar to pk_movement.cancel_mov_no_commit except for flg_status 'P' and 'T', that don't exist
        CURSOR c_req_exam(pin_id_movement movement.id_movement%TYPE) IS
            SELECT 'X'
              FROM exam_req_det r, movement m
             WHERE m.id_movement = pin_id_movement
               AND m.id_movement = r.id_movement
               AND r.flg_status = pk_alert_constant.g_exam_det_req;
    
    BEGIN
    
        g_error := 'CASE i_flg_reason';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        CASE i_flg_reason
            WHEN 'D' THEN
                -- in case of death
                g_error := 'CASE i_flg_reason = D';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                l_mess_reason := pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => pk_death_registry.c_code_msg_death);
        END CASE;
    
        g_error := 'OPEN c_mov';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN c_mov(i_task);
        FETCH c_mov
            INTO l_flg_status;
        CLOSE c_mov;
    
        -- checks if movement was previously cancelled. It if was associated to a lab exam that was suspended, it also may have been suspended.       
        IF l_flg_status = pk_alert_constant.g_monitor_vs_canc
        THEN
            g_error := 'WAS ALREADY SUSPENDED. NO NEED TO GO ON. RETURNING TRUE';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            -- so, there is no need to continue suspending since it was already suspended.
            RETURN TRUE;
        END IF;
    
        -- Checks if the movement can be cancelled. It can only be cancelled if it has no lab/exam orders associated.
        OPEN c_req_exam(i_task);
        FETCH c_req_exam
            INTO l_char;
        l_found := c_req_exam%FOUND;
        CLOSE c_req_exam;
        IF l_found
        THEN
            g_error := 'RETURNING FALSE. GET DESCRIPTION.';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            OPEN c_mov_desc(i_task);
            FETCH c_mov_desc
                INTO l_desc_movement;
            CLOSE c_mov_desc;
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement) || ' ' ||
                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'TRANSPORT_M003');
            g_error     := 'RETURNING FALSE. O_MSG_ERROR: ' || o_msg_error;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            RETURN FALSE;
        END IF;
    
        -- Saves last FLG_STATUS on FLG_STATUS_PREV before cancelling the event on the MOVEMENT table.
        g_error := 'UPD FLG_STATUS_PREV MOV (before canceling)';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_movement.upd(id_movement_in => i_task, flg_status_prev_in => l_flg_status, rows_out => l_rows);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MOVEMENT',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- get category
        g_error := 'GET CATEGORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- cancel movement
        g_error := 'CANCEL MOV' || l_mess_reason;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_movement.cancel_mov_no_commit(i_lang          => i_lang,
                                                i_movement      => i_task,
                                                i_prof          => i_prof,
                                                i_notes         => '',
                                                i_prof_cat_type => l_prof_cat_type,
                                                o_error         => o_error)
        THEN
            g_error := 'RETURNING FALSE. GET DESCRIPTION.';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            OPEN c_mov_desc(i_task);
            FETCH c_mov_desc
                INTO l_desc_movement;
            CLOSE c_mov_desc;
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
            g_error     := 'RETURNING FALSE. O_MSG_ERROR: ' || o_msg_error;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END suspend_task_transp;

    /*
    * Reactivate the ongoing tasks - Movements
    * This function MUST not commit/rollback
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK               ID from the corresponding task
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   21-MAY-2010
    *
    */
    FUNCTION reactivate_task_transp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task      IN NUMBER,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'reactivate_task_transp';
    
        l_mess_error CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'MOVEMENT_M004');
        l_mess_notes CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'WORKFLOW_WARNING_M026');
    
        l_prof_cat_type       category.flg_type%TYPE;
        l_flg_status          movement.flg_status%TYPE;
        l_rows                table_varchar := table_varchar();
        l_desc_movement       VARCHAR2(4000);
        l_sys_alert_event_row sys_alert_event%ROWTYPE;
        l_count_oris          PLS_INTEGER;
        l_oris_episode        episode.id_episode%TYPE;
        l_flg_show            VARCHAR2(4000);
        l_msg_text            VARCHAR2(4000);
        l_msg_title           VARCHAR2(4000);
        l_button              VARCHAR2(4000);
        l_error               t_error_out;
        l_id_mov_transp       movement.id_movement%TYPE;
    
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp();
        l_sysdate_char CONSTANT VARCHAR2(14) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                            i_date => current_timestamp,
                                                                            i_prof => i_prof);
    
        CURSOR c_mov(pin_id_movement movement.id_movement%TYPE) IS
            SELECT m.flg_status, m.id_episode, m.dt_req_tstz, m.flg_status_prev, m.id_room_to
              FROM movement m
             WHERE m.id_movement = pin_id_movement;
        CURSOR c_mov_desc(pin_id_movement movement.id_movement%TYPE) IS
            SELECT pk_translation.get_translation(i_lang, d.code_dept) || ' - ' ||
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_task
              FROM movement m
             INNER JOIN room r
                ON r.id_room = m.id_room_to
             INNER JOIN department dep
                ON dep.id_department = r.id_department
             INNER JOIN dept d
                ON d.id_dept = dep.id_dept
             WHERE m.id_movement = pin_id_movement;
    
        r_mov c_mov%ROWTYPE;
    
    BEGIN
    
        -- Gets more information about the movement
        g_error := 'OPEN c_monit';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN c_mov(i_task);
        FETCH c_mov
            INTO r_mov;
        CLOSE c_mov;
    
        -- Check if it is possible to reactivate the movement
        -- Similar to pk_movement.call_create_movement
        g_error := 'CALL TO CHECK_MOV';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_movement.check_mov(i_lang        => i_lang,
                                     i_episode     => r_mov.id_episode,
                                     i_room        => r_mov.id_room_to,
                                     i_prof        => i_prof,
                                     o_id_movement => l_id_mov_transp,
                                     o_flg_show    => l_flg_show,
                                     o_msg_text    => l_msg_text,
                                     o_msg_title   => l_msg_title,
                                     o_button      => l_button,
                                     o_error       => l_error)
        THEN
            OPEN c_mov_desc(i_task);
            FETCH c_mov_desc
                INTO l_desc_movement;
            CLOSE c_mov_desc;
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
            g_error     := o_msg_error;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            RETURN FALSE;
        END IF;
    
        -- If movement is invalid, returns error message
        g_error := 'CHECK IF MOVEMENT IS INVALID';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF l_flg_show <> pk_alert_constant.g_no
        THEN
            g_error := 'INVALID MOVEMENT';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            OPEN c_mov_desc(i_task);
            FETCH c_mov_desc
                INTO l_desc_movement;
            CLOSE c_mov_desc;
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement) || l_msg_text;
            g_error     := o_msg_error;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            RETURN FALSE;
        
        END IF;
    
        -- If movement is valid, proceeds
        g_error := 'VALID MOVEMENT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        -- If there is no movement in transit, puts flg_status_prev as flg_status on the MOVEMENT table.
        -- If there is a movement in transit, puts movement as pending. 
        g_error := 'r_mov.flg_status_prev' || r_mov.flg_status_prev;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF r_mov.flg_status_prev = pk_alert_constant.g_mov_status_transp
        THEN
        
            -- Similar to pk_movement.call_create_movement
            g_error := 'CALL TO GET_TRANSP_MOV';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            IF NOT pk_movement.get_transp_mov(i_lang     => i_lang,
                                              i_episode  => r_mov.id_episode,
                                              o_movement => l_id_mov_transp,
                                              o_error    => o_error)
            THEN
            
                g_error := 'CALL TO GET_TRANSP_MOV NOT SUCCESSFUL';
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                OPEN c_mov_desc(i_task);
                FETCH c_mov_desc
                    INTO l_desc_movement;
                CLOSE c_mov_desc;
            
                o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
                g_error     := o_msg_error;
                alertlog.pk_alertlog.log_error(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                RETURN FALSE;
            END IF;
        
            g_error := 'IF l_id_mov_transp IS NULL. ID_MOV_TRANSP: ' || l_id_mov_transp;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            IF l_id_mov_transp IS NULL -- no transport in progress
            THEN
            
                -- if puts in transit, has to put all the other pending, calling set_mov_begin
                g_error := 'NO MOVEMENT IN PROGRESS. BEFORE SET_MOV_BEGIN';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                IF NOT pk_movement.set_mov_begin(i_lang     => i_lang,
                                                 i_movement => i_task,
                                                 i_prof     => i_prof,
                                                 o_error    => l_error)
                THEN
                    g_error := 'SET_MOV_BEGIN - ERROR IN FUNCTION';
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    OPEN c_mov_desc(i_task);
                    FETCH c_mov_desc
                        INTO l_desc_movement;
                    CLOSE c_mov_desc;
                
                    o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
                    g_error     := o_msg_error;
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    RETURN FALSE;
                END IF;
            
                -- updates cancel notes
                g_error := 'UPD NOTES_CANCEL Mov';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                ts_movement.upd(id_movement_in => i_task,
                                --flg_status_in   => l_flg_status,
                                -- notes_cancel_in    => l_mess_notes,
                                id_prof_cancel_in  => NULL,
                                id_prof_cancel_nin => FALSE,
                                dt_cancel_tstz_in  => NULL,
                                dt_cancel_tstz_nin => FALSE,
                                rows_out           => l_rows);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'MOVEMENT',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                g_error := 'RETURN TRUE';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                -- It can return since this function calls alerts and the other functions to update
                RETURN TRUE;
            
            ELSE
                g_error := 'L_FLG_STATUS TO BET SET: ' || pk_alert_constant.g_mov_status_pend;
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                -- If there is a movement in transit
                l_flg_status := pk_alert_constant.g_mov_status_pend;
            END IF;
        
        ELSE
            g_error := 'L_FLG_STATUS TO BET SET: ' || r_mov.flg_status_prev;
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            -- If movement was on a status different from in transit, reactivates on that status freely
            l_flg_status := r_mov.flg_status_prev;
        
        END IF;
    
        -- updates cancel notes
        g_error := 'UPD NOTES_CANCEL Mov';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_movement.upd(id_movement_in => i_task,
                        flg_status_in  => l_flg_status,
                        --                        notes_cancel_in => l_mess_notes,
                        id_prof_cancel_in  => NULL,
                        id_prof_cancel_nin => FALSE,
                        dt_cancel_tstz_in  => NULL,
                        dt_cancel_tstz_nin => FALSE,
                        rows_out           => l_rows);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MOVEMENT',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- ALERTS: Delete if reactivates as pending, inserts if reactivates as requested
        g_error := 'INSERT ALERT(PATIENT_MOV)';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        -- JS: 2008-03-28: Process alerts for "PATIENT_MOV" (Alert id 9)            
        l_sys_alert_event_row.id_sys_alert := 9;
        l_sys_alert_event_row.id_episode   := r_mov.id_episode;
        l_sys_alert_event_row.id_record    := i_task;
        l_sys_alert_event_row.dt_record    := r_mov.dt_req_tstz;
        l_sys_alert_event_row.replace1     := pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                      i_prof.institution,
                                                                      i_prof.software);
    
        -- JS: 2008-03-28: Delete if pending    
        IF l_flg_status = pk_alert_constant.g_mov_status_pend
        THEN
            g_error := 'DELETE ALERTS(PATIENT_MOV)';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event_row,
                                                    o_error           => o_error)
            THEN
                pk_alertlog.log_error('Error deleting alerts');
                pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                      l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                      l_sys_alert_event_row.id_record);
                OPEN c_mov_desc(i_task);
                FETCH c_mov_desc
                    INTO l_desc_movement;
                CLOSE c_mov_desc;
            
                o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
                g_error     := o_msg_error;
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                RETURN FALSE;
            END IF;
            -- JS: 2008-03-28: Insert if requested
        ELSIF l_flg_status = pk_alert_constant.g_mov_status_req
        THEN
            g_error := 'INSERT ALERT(PATIENT_MOV)';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event_row,
                                                    i_flg_type_dest   => NULL,
                                                    o_error           => o_error)
            THEN
                pk_alertlog.log_error('Error inserting alert');
                pk_alertlog.log_error('id_sys_alert: ' || l_sys_alert_event_row.id_sys_alert || '; id_episode: ' ||
                                      l_sys_alert_event_row.id_episode || '; id_record(id_movement): ' ||
                                      l_sys_alert_event_row.id_record);
            
                OPEN c_mov_desc(i_task);
                FETCH c_mov_desc
                    INTO l_desc_movement;
                CLOSE c_mov_desc;
            
                o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
                g_error     := o_msg_error;
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
                RETURN FALSE;
            END IF;
        
        END IF;
    
        -- get category
        g_error := 'GET CATEGORY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- update episode info
        g_error := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_visit.update_epis_info_no_obs(i_lang         => i_lang,
                                                i_id_episode   => r_mov.id_episode,
                                                i_id_room      => NULL,
                                                i_bed          => NULL,
                                                i_norton       => NULL,
                                                i_professional => NULL,
                                                i_flg_hydric   => NULL,
                                                i_flg_wound    => NULL,
                                                i_companion    => NULL,
                                                i_flg_unknown  => NULL,
                                                i_desc_info    => NULL,
                                                i_prof         => i_prof,
                                                o_error        => o_error)
        THEN
            OPEN c_mov_desc(i_task);
            FETCH c_mov_desc
                INTO l_desc_movement;
            CLOSE c_mov_desc;
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
            g_error     := 'ERROR ON CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS1. O_MSG_ERROR: ' || o_msg_error;
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RETURN FALSE;
        END IF;
    
        -- UPDATE_EPIS_INFO_NO_OBS, once again similar to pk_movement.call_create_movement
        g_error := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_visit.update_epis_info_no_obs(i_lang                 => i_lang,
                                                i_id_episode           => r_mov.id_episode,
                                                i_id_prof              => i_prof,
                                                i_dt_entrance_room     => NULL,
                                                i_dt_last_interaction  => l_sysdate_char,
                                                i_dt_movement          => l_sysdate_char,
                                                i_dt_harvest           => NULL,
                                                i_dt_next_drug         => NULL,
                                                i_dt_first_obs         => l_sysdate_char,
                                                i_dt_next_intervention => NULL,
                                                i_dt_next_vital_sign   => NULL,
                                                i_dt_next_position     => NULL,
                                                i_dt_harvest_mov       => NULL,
                                                i_dt_first_nurse_obs   => NULL,
                                                i_prof_cat_type        => l_prof_cat_type,
                                                o_error                => o_error)
        THEN
            OPEN c_mov_desc(i_task);
            FETCH c_mov_desc
                INTO l_desc_movement;
            CLOSE c_mov_desc;
        
            o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
            g_error     := 'ERROR ON CALL TO PK_VISIT.UPDATE_EPIS_INFO_NO_OBS2. O_MSG_ERROR: ' || o_msg_error;
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_func_name);
            RETURN FALSE;
        END IF;
    
        --
        -- Code extracted from pk_movement.call_create_movement to update the room status in ORIS
        -- To be reviewed by the ORIS team
        --
        g_error := 'CHECK SR TRANSPORT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT COUNT(sd.id_software_dept)
          INTO l_count_oris
          FROM department d, room r, software_dept sd
         WHERE sd.id_software = pk_alert_constant.g_soft_oris
           AND d.id_dept = sd.id_dept
           AND d.id_institution = i_prof.institution
           AND r.id_department = d.id_department
           AND r.id_room = r_mov.id_room_to
           AND flg_recovery = pk_alert_constant.g_no;
    
        g_error := 'IF nvl(l_count_oris, 0)';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF nvl(l_count_oris, 0) > 0
        THEN
        
            -- The following comment was extracted from pk_movement.call_create_movement:
            -- "If exists more the one active ORIS episode, get the closer ORIS episode when I make a request of patient transport. 
            -- With this logic, I have only one ORIS episode"
            BEGIN
                g_error := 'SELECT';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
            
                SELECT ep.id_episode
                  INTO l_oris_episode
                  FROM (SELECT pk_date_utils.get_timestamp_diff(s.dt_target_tstz, current_timestamp) time_diff,
                               e1.id_episode
                          FROM episode e, visit v, visit v1, episode e1, schedule_sr s
                         WHERE e.id_episode = r_mov.id_episode
                           AND v.id_visit = e.id_visit
                           AND v1.id_patient = v.id_patient
                           AND v1.id_institution = v.id_institution
                           AND e1.id_visit = v1.id_visit
                           AND e1.id_epis_type = pk_alert_constant.g_epis_type_operating
                           AND e1.flg_status = pk_alert_constant.g_epis_status_active
                           AND s.id_episode = e1.id_episode
                           AND s.dt_interv_preview_tstz IS NOT NULL
                         ORDER BY time_diff) ep
                 WHERE ep.time_diff > 0
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'NO_DATA_FOUND';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_oris_episode := NULL;
                WHEN too_many_rows THEN
                    g_error := 'TOO_MANY_ROWS';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package_name,
                                                  sub_object_name => l_func_name);
                    l_oris_episode := NULL;
            END;
        
            g_error := 'CHECK IF l_oris_episode IS NOT NULL';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            IF l_oris_episode IS NOT NULL
            THEN
                -- update ORIS patient status
                g_error := 'UPDATE ORIS PATIENT STATUS';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => l_func_name);
            
                IF NOT pk_sr_output.set_patient_status(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_episode    => l_oris_episode,
                                                       i_room       => r_mov.id_room_to,
                                                       i_dt_mov_str => pk_date_utils.date_send_tsz(i_lang,
                                                                                                   l_sysdate_tstz,
                                                                                                   i_prof),
                                                       i_action     => 'R',
                                                       o_error      => o_error)
                THEN
                    g_error := 'ERROR UPDATING ORIS PATIENT STATUS';
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                
                    OPEN c_mov_desc(i_task);
                    FETCH c_mov_desc
                        INTO l_desc_movement;
                    CLOSE c_mov_desc;
                
                    o_msg_error := REPLACE(l_mess_error, '@1', l_desc_movement);
                    g_error     := 'ERROR ON CALL TO pk_sr_output.set_patient_status. O_MSG_ERROR: ' || o_msg_error;
                    alertlog.pk_alertlog.log_error(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        g_error := 'RETURN TRUE. O_MSG_ERROR: ' || o_msg_error;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN TRUE;
    
    END reactivate_task_transp;

    /*
    * Get episode moments (used by reports and contains specific information for report generation)
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_EPISODE            Episode ID
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui Duarte
    * @version 2.6.0.4
    * @since   30-AUG-2010
    *
    */
    FUNCTION get_mov_epis_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN movement.id_episode%TYPE,
        i_prof    IN profissional,
        o_mov     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET ALL MOVEMENT REPORTS';
        OPEN o_mov FOR
            SELECT m.id_movement,
                   m.flg_status,
                   m.flg_mov_type,
                   pk_sysdomain.get_domain('MOVEMENT.FLG_MOV_TYPE', m.flg_mov_type, i_lang) desc_mov_type,
                   nvl(rd.desc_room, pk_translation.get_translation(i_lang, rd.code_room)) room_destination,
                   pk_translation.get_translation(i_lang, dd.code_department) dep_destination,
                   nvl(nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)),
                       pk_message.get_message(i_lang, 'N/A')) room_origin,
                   pk_translation.get_translation(i_lang, do.code_department) dep_origin,
                   pk_sysdomain.get_domain('MOVEMENT.FLG_STATUS', m.flg_status, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, m.dt_req_tstz, i_prof.institution, i_prof.software) dt_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, m.id_prof_request) prof_req,
                   decode(m.flg_mov_type,
                          g_mov_type_detour,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, m.dt_begin_tstz, i_prof.institution, i_prof.software)) dt_begin,
                   decode(m.flg_mov_type,
                          g_mov_type_detour,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, m.dt_end_tstz, i_prof.institution, i_prof.software)) dt_end,
                   decode(m.flg_mov_type,
                          g_mov_type_detour,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, m.id_prof_move)) prof_mov,
                   decode(m.flg_mov_type,
                          g_mov_type_detour,
                          NULL,
                          pk_date_utils.dt_chr_tsz(i_lang, m.dt_end_tstz, i_prof)) date_end,
                   decode(m.flg_mov_type,
                          g_mov_type_detour,
                          NULL,
                          pk_date_utils.date_char_hour_tsz(i_lang, m.dt_end_tstz, i_prof.institution, i_prof.software)) hour_end,
                   decode(m.flg_mov_type,
                          g_mov_type_detour,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, m.id_prof_receive)) prof_receive,
                   pk_date_utils.dt_chr_tsz(i_lang, m.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, m.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, m.id_prof_cancel) prof_cancel,
                   m.notes_cancel,
                   pk_translation.get_translation(i_lang, n.code_necessity) transp
              FROM movement m
              JOIN room rd
                ON rd.id_room = m.id_room_to
              JOIN room ro
                ON ro.id_room = m.id_room_from
              JOIN department do
                ON do.id_department = ro.id_department
              JOIN department dd
                ON dd.id_department = rd.id_department
              LEFT JOIN necessity n
                ON n.id_necessity = m.id_necessity
             WHERE m.id_episode = i_episode
             ORDER BY pk_sysdomain.get_rank(i_lang, 'MOVEMENT.FLG_STATUS', m.flg_status), m.dt_req_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOV_EPIS_REP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_mov);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Gets the next movement dbegin date
    *
    * @param i_episode               Episode ID
    * @param i_movement              actual Movement ID 
    * @param i_dt                    Actulament movement end date
    *
    * @return                        Begin date of next movement or the episode end_date
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.7.1.0
    * @since                         03-05-2017
    **********************************************************************************************/
    FUNCTION get_next_mov_date
    (
        i_episode  IN episode.id_episode%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_dt       IN movement.dt_end_tstz%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        SELECT dt_begin_tstz
          INTO l_timestamp
          FROM (SELECT m.dt_begin_tstz, row_number() over(ORDER BY m.dt_begin_tstz ASC) rn
                  FROM movement m
                 WHERE m.id_episode = i_episode
                   AND m.dt_begin_tstz > i_dt
                   AND m.id_movement <> i_movement
                   AND m.flg_status IN (pk_alert_constant.g_mov_status_transp, pk_alert_constant.g_mov_status_finish)) t
         WHERE rn = 1;
    
        -- gets episode end date
        IF l_timestamp IS NULL
        THEN
            SELECT e.dt_end_tstz
              INTO l_timestamp
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
    
        IF l_timestamp IS NULL
        THEN
            RETURN current_timestamp;
        END IF;
        RETURN l_timestamp;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN current_timestamp;
        
    END get_next_mov_date;

    FUNCTION get_time_in_room
    (
        i_episode   IN episode.id_episode%TYPE,
        i_room_type IN room_type.id_room_type%TYPE DEFAULT NULL,
        i_room      IN room.id_room%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
        l_time         NUMBER;
        l_id_room      table_number;
        l_id_room_type room.id_room_type%TYPE;
        l_diff         TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        -- validate the existence of at least one parammeter
        IF i_room_type IS NULL
           AND i_room IS NULL
        THEN
            RETURN NULL;
        END IF;
        IF i_room_type IS NOT NULL
        THEN
            -- get list of rooms
            SELECT id_room
              BULK COLLECT
              INTO l_id_room
              FROM room r
             WHERE id_room_type = i_room_type
               AND r.flg_available = pk_alert_constant.g_yes;
        ELSE
            l_id_room.extend;
            l_id_room(l_id_room.last) := i_room;
        END IF;
    
        SELECT SUM(extract(hour FROM(dt_end - dt_begin))) room_time, id_room_type
          INTO l_time, l_id_room_type
          FROM (SELECT m.id_room_to,
                       r.id_room_type,
                       m.dt_end_tstz dt_begin,
                       get_next_mov_date(i_episode, m.id_movement, m.dt_end_tstz) dt_end
                  FROM movement m
                  JOIN room r
                    ON m.id_room_to = r.id_room
                 WHERE m.id_episode = i_episode
                   AND m.flg_status = pk_alert_constant.g_mov_status_finish
                   AND r.id_room IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                      t.column_value
                                       FROM TABLE(l_id_room) t))
         GROUP BY id_room_type;
    
        RETURN l_time;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_time_in_room;
    -- CONSTRUCTOR 
BEGIN
    pk_alertlog.log_init(object_name => g_package_name);
END;
/
