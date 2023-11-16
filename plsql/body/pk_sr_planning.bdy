/*-- Last Change Revision: $Rev: 2053266 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-15 16:10:41 +0000 (qui, 15 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_planning AS

    /********************************************************************************************
    * Obter as opções disponíveis no multichoice da Cirurgia Proposta.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             IDs referring to professional, institution and software
    * @param i_origin           origin of the call
    * @param o_options          Cursor com as opções
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/12/12
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION get_surg_procedures_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_origin  IN VARCHAR2,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_value       sys_config.value%TYPE;
        l_code_domain sys_domain.code_domain%TYPE;
    BEGIN
    
        g_error := 'OPEN O_OPTIONS';
        pk_alertlog.log_debug(g_error);
        l_value := pk_sysconfig.get_config(i_code_cf => 'SR_UNCODED_PROCEDURES', i_prof => i_prof);
    
        CASE i_origin
        -- asked from summary page
            WHEN 'G' THEN
                l_code_domain := 'SR_SURG_PROCEDURES.SUMMARY';
                -- asked from section block
            WHEN 'B' THEN
                l_code_domain := 'SR_SURG_PROCEDURES.BLOCK';
                -- asked from selected coded field
            WHEN 'CF' THEN
                l_code_domain := 'SR_SURG_PROCEDURES.OPTIONS';
                -- asked from selected uncoded field
            WHEN 'UF' THEN
                l_code_domain := 'SR_SURG_PROCEDURES.FIELD_UNC';
        END CASE;
    
        g_error := 'OPEN O_OPTIONS';
        pk_alertlog.log_debug(g_error);
        IF l_value = 'N'
        THEN
            -- displays all the available options (from the Multichoice)
            -- but the ones which refer with the uncoded procedures
            OPEN o_options FOR
                SELECT val data, desc_val label
                  FROM sys_domain
                 WHERE code_domain = l_code_domain
                   AND id_language = i_lang
                   AND flg_available = g_value_y
                   AND val NOT IN (g_value_u, g_value_c)
                 ORDER BY rank;
        ELSE
            -- displays all the available options on the Multichoice
            OPEN o_options FOR
                SELECT val data, desc_val label
                  FROM sys_domain
                 WHERE code_domain = l_code_domain
                   AND id_language = i_lang
                   AND flg_available = g_value_y
                 ORDER BY rank;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURG_PROCEDURES_OPTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
        
    END get_surg_procedures_options;

    /********************************************************************************************
    * Activa permanentemente as intervenções cirúrgicas activas temporariamente.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_sr_epis_interv   Id do procedimento cirúrgico
    * @param i_sr_intervention  Id do procedimento cirúrgico codificado
    * @param i_prof             Professional ID
    * @param i_id_cdr_call      Rule event identifier.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/09
    *     
    * @author    Pedro Santos
    * @version   2.5 SP3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION set_conf_epis_surg_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_prof            IN profissional,
        i_id_cdr_call     IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num            PLS_INTEGER;
        l_interv_status  sr_epis_interv.flg_status%TYPE;
        l_flg_status     sr_epis_interv.flg_status%TYPE;
        l_flg_code_type  sr_epis_interv.flg_code_type%TYPE;
        l_rowids         table_varchar;
        l_flg_status_old sr_epis_interv.flg_status%TYPE;
        l_exception      EXCEPTION;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_num          := 0;
    
        --Get the surgical procedure's state
        g_error := 'Get the surgical procedure''s state for id_sr_epis_interv : ' || i_sr_epis_interv;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT sei.flg_status, sei.flg_code_type
              INTO l_flg_status, l_flg_code_type
              FROM sr_epis_interv sei
             WHERE sei.id_sr_epis_interv = i_sr_epis_interv
               AND sei.id_episode_context = i_episode
               AND sei.flg_status != g_cancel;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status    := NULL;
                l_flg_code_type := NULL;
        END;
    
        -- Check the surgical's state
        -- Check if there're an end of surgery time
        g_error := 'GET END OF SURGERY TIME FOR ID_EPISODE : ' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_num
          FROM sr_surgery_time_det d, sr_surgery_time t
         WHERE d.id_episode = i_episode
           AND d.flg_status = g_active
           AND t.id_sr_surgery_time = d.id_sr_surgery_time
           AND t.flg_type = g_surg_time_fc;
    
        IF l_flg_status = g_sei_flg_status_n
        THEN
            l_interv_status := g_sei_flg_status_n;
        ELSIF nvl(l_num, 0) > 0
        THEN
            --if there're an end of surgery time, then the surgical procedure will be complete state
            l_interv_status := g_interv_exec;
        ELSE
            --Check if the surgical procedure has been "in progress"
            g_error := 'CHECK IF THE SURGICAL PROCEDURE HAS BEEN IN PROGRESS FOR ID_EPISODE: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(*)
              INTO l_num
              FROM sr_surgery_time_det d, sr_surgery_time t
             WHERE d.id_episode = i_episode
               AND d.flg_status = g_active
               AND t.id_sr_surgery_time = d.id_sr_surgery_time
               AND t.flg_type = g_surg_time_ic;
        
            IF nvl(l_num, 0) > 0
            THEN
                l_interv_status := g_interv_part;
            ELSE
                l_interv_status := g_interv_req;
            END IF;
        END IF;
    
        --updated the surgical procedure's state
        -- if the id_sr_intervention is not null and the surgical procedure is uncoded so 
        -- is necessary the code this one
        IF (i_sr_intervention IS NOT NULL AND l_flg_code_type = g_flg_code_type_u)
        THEN
            g_error := 'call ts_sr_epis_interv.upd TO CODED SURGICAL PROCEDURE FOR ID_EPISODE: ' || i_episode;
            pk_alertlog.log_debug(g_error);
        
            g_error := 'get l_flg_status_old';
            BEGIN
                SELECT sei.flg_status
                  INTO l_flg_status_old
                  FROM sr_epis_interv sei
                 WHERE sei.id_sr_epis_interv = i_sr_epis_interv;
            EXCEPTION
                WHEN dup_val_on_index THEN
                    l_flg_status_old := NULL;
            END;
        
            g_error := 'call ts_sr_epis_interv.upd';
            ts_sr_epis_interv.upd(id_sr_intervention_in  => i_sr_intervention,
                                  id_sr_intervention_nin => FALSE,
                                  dt_req_tstz_in         => g_sysdate_tstz,
                                  dt_req_tstz_nin        => FALSE,
                                  id_prof_req_in         => i_prof.id,
                                  id_prof_req_nin        => FALSE,
                                  flg_status_in          => l_interv_status,
                                  flg_status_nin         => FALSE,
                                  flg_code_type_in       => g_flg_code_type_c,
                                  flg_code_type_nin      => FALSE,
                                  id_cdr_call_in         => i_id_cdr_call,
                                  id_cdr_call_nin        => FALSE,
                                  where_in               => 'id_sr_epis_interv = ' || i_sr_epis_interv,
                                  rows_out               => l_rowids);
        
            g_error := 'call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_EPIS_INTERV',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'call pk_sr_output.set_ia_event_prescription';
            IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_flg_action        => 'U',
                                                          i_id_sr_epis_interv => i_sr_epis_interv,
                                                          i_flg_status_new    => l_interv_status,
                                                          i_flg_status_old    => l_flg_status_old,
                                                          o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSE
            -- in case if the flg_status is different the other status calculated by the surgery time
            IF l_flg_status != l_interv_status
            THEN
            
                g_error := 'call ts_sr_epis_interv.upd TO CHANGE THE FLG_STATUS FOR ID_EPISODE: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                ts_sr_epis_interv.upd(flg_status_in   => l_interv_status,
                                      flg_status_nin  => FALSE,
                                      dt_req_tstz_in  => g_sysdate_tstz,
                                      dt_req_tstz_nin => FALSE,
                                      where_in        => 'id_sr_epis_interv = ' || i_sr_epis_interv,
                                      rows_out        => l_rowids);
            
                g_error := 'call t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SR_EPIS_INTERV',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call pk_sr_output.set_ia_event_prescription';
                IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_flg_action        => 'U',
                                                              i_id_sr_epis_interv => i_sr_epis_interv,
                                                              i_flg_status_new    => l_interv_status,
                                                              i_flg_status_old    => l_flg_status,
                                                              o_error             => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CONF_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_conf_epis_surg_interv;

    /********************************************************************************************
    * Cancela a prescrição de um procedimento cirurgico para um episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_sr_epis_interv   Procedure's id, which may refer to an (un)coded one
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sr_cancel_reason ID do motivo de cancelamento do procedimento cirúrgico.
    * @param i_notes            Notas de cancelamento
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2005/10/27
    * 
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/15
    * reason     ALERT-16467  inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION cancel_epis_surg_proc
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_sr_epis_interv   IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_prof             IN profissional,
        i_sr_cancel_reason IN sr_epis_interv.id_sr_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_epis_interv_desc sr_epis_interv_desc%ROWTYPE;
        l_sr_epis_interv      sr_epis_interv%ROWTYPE;
    
        internal_error_exception EXCEPTION;
    
        CURSOR c_desc IS
            SELECT seid.id_sr_epis_interv_desc, sei.id_sr_epis_interv, sei.id_sr_intervention
              FROM sr_epis_interv_desc seid, sr_epis_interv sei
             WHERE sei.id_episode_context = i_episode
               AND sei.flg_status != g_interv_can
               AND sei.id_sr_epis_interv = i_sr_epis_interv
               AND seid.flg_status(+) = g_active
               AND seid.id_sr_epis_interv(+) = sei.id_sr_epis_interv
               AND (sei.flg_surg_request IS NULL OR sei.flg_surg_request = pk_alert_constant.g_no);
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --Abre cursor para obter o detalhe da intervenção
        g_error := 'OPEN C_DESC CURSOR';
        pk_alertlog.log_debug(g_error);
        FOR i IN c_desc
        LOOP
            l_sr_epis_interv_desc.id_sr_epis_interv_desc := i.id_sr_epis_interv_desc;
        
            g_error := 'CANCEL INTERV PRESC';
            pk_alertlog.log_debug(g_error);
            --cancela a prescrição da intervenção
            l_sr_epis_interv                     := NULL;
            l_sr_epis_interv.id_sr_epis_interv   := i.id_sr_epis_interv;
            l_sr_epis_interv.flg_status          := g_interv_can;
            l_sr_epis_interv.dt_cancel_tstz      := g_sysdate_tstz;
            l_sr_epis_interv.dt_req_tstz         := g_sysdate_tstz;
            l_sr_epis_interv.id_prof_cancel      := i_prof.id;
            l_sr_epis_interv.id_sr_cancel_reason := i_sr_cancel_reason;
            l_sr_epis_interv.notes_cancel        := i_notes;
            l_sr_epis_interv.id_sr_intervention  := i.id_sr_intervention;
        
            g_error := 'call pk_sr_output.update_sr_epis_interv for id_sr_epis_interv: ' ||
                       l_sr_epis_interv.id_sr_epis_interv;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.update_sr_epis_interv(i_lang, i_prof, l_sr_epis_interv, o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CANCEL_EPIS_SURG_PROC',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            g_error := 'Cancel pending nursing suggestions';
            IF i.id_sr_intervention IS NOT NULL
            THEN
                IF NOT cancel_assoc_icnp_interv(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_sr_epis_interv => i.id_sr_epis_interv,
                                                o_error             => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'CANCEL_EPIS_SURG_PROC',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        
            --Elimina a descrição da intervenção da descrição da Cirurgia Proposta
            g_error := 'DELETE INTERV DESCRIPTION';
            pk_alertlog.log_debug(g_error);
            l_sr_epis_interv_desc.flg_status     := g_cancel;
            l_sr_epis_interv_desc.dt_cancel_tstz := g_sysdate_tstz;
            l_sr_epis_interv_desc.id_prof_cancel := i_prof.id;
        
            g_error := 'call pk_sr_output.cancel_interv_description';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.cancel_interv_description(i_lang, l_sr_epis_interv_desc, o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CANCEL_EPIS_SURG_PROC',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END LOOP;
    
        -- Cancelar a equipa associada ao procedimento
        IF NOT pk_sr_tools.cancel_sr_prof_team(i_lang, i_prof, i_episode, i_sr_epis_interv, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_SURG_PROC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_SURG_PROC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CANCEL_EPIS_SURG_PROC',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_SURG_PROC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'call pk_sr_approval.check_status_for_approval for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_approval.check_status_for_approval(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode,
                                                        o_error   => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_SURG_PROC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_epis_surg_proc;

    /********************************************************************************************
    * Lista todas as requisições de posicionamentos
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    *
    * @param o_posit            Lista de requisições de posicionamentos
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/10
       ********************************************************************************************/

    FUNCTION get_posit_list
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_status IN table_varchar DEFAULT NULL,
        o_posit      OUT pk_types.cursor_type,
        o_status     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sr_time_margin   NUMBER;
        l_flg_status       table_varchar;
        l_flg_status_count NUMBER := -1;
    
    BEGIN
        -- Obter prazo limite antes da cirurgia para terminar posicionamentos e reservas.
        g_error := 'GET PROC TME LIMIT';
        pk_alertlog.log_debug(g_error);
        l_sr_time_margin := to_number(nvl(pk_sysconfig.get_config('SR_TIME_MARGIN_POS', i_prof), 0));
        l_sr_time_margin := -l_sr_time_margin;
    
        IF i_flg_status IS NULL
        THEN
            l_flg_status_count := 0;
            l_flg_status       := table_varchar();
        ELSE
            l_flg_status_count := i_flg_status.count;
            l_flg_status       := i_flg_status;
        END IF;
    
        --Abre cursor com os icons dos vários estados
        g_error := 'GET STATUS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_status FOR
            SELECT val, img_name
              FROM sys_domain
             WHERE code_domain = 'SR_POSIT_DET.FLG_STATUS'
               AND flg_available = 'Y'
               AND id_language = i_lang;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_posit FOR
            SELECT r.id_sr_posit_req,
                   r.id_sr_posit,
                   pk_translation.get_translation(i_lang, p.code_sr_posit) desc_posit,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, f.id_professional) nick_name,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(r.flg_status,
                                                      g_posit_req,
                                                      r.dt_posit_req_tstz,
                                                      g_posit_part,
                                                      r.dt_exec_tstz,
                                                      g_posit_exec,
                                                      r.dt_verify_tstz,
                                                      g_posit_canc,
                                                      r.dt_cancel_tstz,
                                                      r.dt_posit_req_tstz),
                                               i_prof.institution,
                                               i_prof.software) desc_dt,
                   r.flg_status, --r.flg_verify,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(r.flg_status,
                                                      g_posit_req,
                                                      r.dt_posit_req_tstz,
                                                      g_posit_part,
                                                      r.dt_exec_tstz,
                                                      g_posit_exec,
                                                      r.dt_verify_tstz,
                                                      g_posit_canc,
                                                      r.dt_cancel_tstz,
                                                      r.dt_posit_req_tstz),
                                               i_prof) dt_ord,
                   --                   decode(s.dt_interv_preview_tstz,
                   --                          NULL,
                   --                          NULL, --pk_sysdomain.get_img(i_lang, 'SR_POSIT_DET.FLG_STATUS', r.flg_status),
                   
                   '|' || decode(pk_date_utils.compare_dates_tsz(i_prof, current_timestamp, s.dt_interv_preview_tstz),
                                 g_flg_time_g,
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --Enquanto cellrender não for actualizado.
                                                                     r.flg_status,
                                                                     'E',
                                                                     r.flg_status,
                                                                     r.dt_posit_req_tstz,
                                                                     r.dt_posit_req_tstz,
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          r.flg_status)),
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --Enquanto cellrender não for actualizado.
                                                                     r.flg_status,
                                                                     'E',
                                                                     r.flg_status,
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          r.flg_status))) img_name,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   r.id_episode,
                   r.id_episode_context,
                   decode(r.flg_status,
                          g_posit_canc,
                          decode(r.notes_cancel, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                          pk_alert_constant.g_no) flg_cancel_notes,
                   pk_sysdomain.get_domain('SR_POSIT_REQ.FLG_STATUS', r.flg_status, i_lang) desc_status
              FROM sr_posit p, sr_posit_req r, professional f, schedule_sr s
             WHERE r.id_episode_context = i_episode
               AND p.id_sr_posit = r.id_sr_posit
               AND s.id_episode(+) = r.id_episode_context
               AND (r.flg_status IN (SELECT t1.column_value
                                       FROM TABLE(l_flg_status) t1) OR l_flg_status_count = 0)
               AND ((nvl(r.flg_verify, g_value_n) = g_posit_verif_y AND f.id_professional = r.id_prof_verify) OR
                   (r.flg_status = g_posit_req AND nvl(r.flg_verify, g_value_n) != g_posit_verif_y AND
                   f.id_professional = r.id_prof_req) OR
                   (r.flg_status = g_posit_exec AND nvl(r.flg_verify, g_value_n) != g_posit_verif_y AND
                   f.id_professional = r.id_prof_exec) OR
                   (r.flg_status = g_posit_canc AND nvl(r.flg_verify, g_value_n) != g_posit_verif_y AND
                   f.id_professional = r.id_prof_cancel) OR
                   ((r.flg_status NOT IN (g_posit_req, g_posit_exec, g_posit_canc) AND
                   nvl(r.flg_verify, g_value_n) != g_posit_verif_y) AND f.id_professional = r.id_prof_req))
             ORDER BY decode(r.flg_status, g_posit_canc, 10, g_posit_exec, 5, 1), 8 DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POSIT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_posit);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Lista todos os posicionamentos para efectuar as requisições
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    *
    * @param o_posit            Lista de requisições de posicionamentos
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/14
       ********************************************************************************************/

    FUNCTION get_posit_list_det
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_prof      IN profissional,
        o_posit     OUT pk_types.cursor_type,
        o_status    OUT pk_types.cursor_type,
        o_posit_rel OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sr_time_margin NUMBER;
    
    BEGIN
        -- Obter prazo limite antes da cirurgia para terminar posicionamentos e reservas.
        g_error := 'GET PROC TME LIMIT';
        pk_alertlog.log_debug(g_error);
        l_sr_time_margin := to_number(nvl(pk_sysconfig.get_config('SR_TIME_MARGIN_POS', i_prof), 0));
        l_sr_time_margin := -l_sr_time_margin;
    
        --Abre cursor com os icons dos vários estados
        g_error := 'GET STATUS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_status FOR
            SELECT val, img_name
              FROM sys_domain
             WHERE code_domain = 'SR_POSIT_DET.FLG_STATUS'
               AND flg_available = 'Y'
               AND id_language = i_lang;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_posit FOR
            SELECT n.cont_reg,
                   t1.id_sr_posit id_sr_posit1,
                   t1.id_sr_posit_req id_sr_posit_req1,
                   pk_date_utils.date_send_tsz(i_lang, t1.dt_posit_req_tstz, i_prof) dt_posit_req1,
                   t1.desc_posit desc_posit1,
                   t1.flg_status flg_status1,
                   --t1.flg_exclusive flg_exclusive1,
                   --                   decode(s.dt_interv_preview,
                   --                          NULL,
                   --                          NULL, --pk_sysdomain.get_img(I_LANG, 'SR_POSIT_DET.FLG_STATUS', t1.flg_status),
                   
                   '|' ||
                   decode(t1.flg_status,
                          'R',
                          decode(pk_date_utils.compare_dates_tsz(i_prof, current_timestamp, s.dt_interv_preview_tstz),
                                 g_flg_time_g,
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --até que o cellrender seja actualizado
                                                                     t1.flg_status,
                                                                     'E',
                                                                     t1.flg_status,
                                                                     t1.dt_posit_req_tstz,
                                                                     t1.dt_posit_req_tstz,
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          t1.flg_status)),
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --até que o cellrender seja actualizado
                                                                     t1.flg_status,
                                                                     'E',
                                                                     t1.flg_status,
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          t1.flg_status))),
                          pk_sr_clinical_info.get_string_task(i_lang,
                                                              i_prof,
                                                              g_flg_type_o,
                                                              t1.flg_status,
                                                              'E',
                                                              t1.flg_status,
                                                              greatest(t1.dt_posit_req_tstz, s.dt_interv_preview_tstz),
                                                              greatest(t1.dt_posit_req_tstz, s.dt_interv_preview_tstz),
                                                              pk_sysdomain.get_img(i_lang,
                                                                                   'SR_POSIT_DET.FLG_STATUS',
                                                                                   t1.flg_status))) img_name1,
                   t2.id_sr_posit id_sr_posit2,
                   t2.id_sr_posit_req id_sr_posit_req2,
                   pk_date_utils.date_send_tsz(i_lang, t2.dt_posit_req_tstz, i_prof) dt_posit_req2,
                   t2.desc_posit desc_posit2,
                   t2.flg_status flg_status2,
                   --t2.flg_exclusive flg_exclusive2,
                   --                   decode(s.dt_interv_preview,
                   --                          NULL,
                   --                          NULL, --pk_sysdomain.get_img(I_LANG, 'SR_POSIT_DET.FLG_STATUS', t2.flg_status),
                   '|' ||
                   decode(t2.flg_status,
                          'R',
                          decode(pk_date_utils.compare_dates_tsz(i_prof, current_timestamp, s.dt_interv_preview_tstz),
                                 g_flg_time_g,
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --até que o cellrender seja actualizado
                                                                     t2.flg_status,
                                                                     'E',
                                                                     t2.flg_status,
                                                                     t2.dt_posit_req_tstz,
                                                                     t2.dt_posit_req_tstz,
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          t2.flg_status)),
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --até que o cellrender seja actualizado
                                                                     t2.flg_status,
                                                                     'E',
                                                                     t2.flg_status,
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          t2.flg_status))),
                          pk_sr_clinical_info.get_string_task(i_lang,
                                                              i_prof,
                                                              g_flg_type_o,
                                                              t2.flg_status,
                                                              'E',
                                                              t2.flg_status,
                                                              greatest(t2.dt_posit_req_tstz, s.dt_interv_preview_tstz),
                                                              greatest(t2.dt_posit_req_tstz, s.dt_interv_preview_tstz),
                                                              pk_sysdomain.get_img(i_lang,
                                                                                   'SR_POSIT_DET.FLG_STATUS',
                                                                                   t2.flg_status))) img_name2,
                   t3.id_sr_posit id_sr_posit3,
                   t3.id_sr_posit_req id_sr_posit_req3,
                   pk_date_utils.date_send_tsz(i_lang, t3.dt_posit_req_tstz, i_prof) dt_posit_req3,
                   t3.desc_posit desc_posit3,
                   t3.flg_status flg_status3,
                   --t3.flg_exclusive flg_exclusive3,
                   --                   decode(s.dt_interv_preview,
                   --                          NULL,
                   --                          NULL, --pk_sysdomain.get_img(I_LANG, 'SR_POSIT_DET.FLG_STATUS', t3.flg_status),
                   '|' ||
                   decode(t3.flg_status,
                          'R',
                          decode(pk_date_utils.compare_dates_tsz(i_prof, current_timestamp, s.dt_interv_preview_tstz),
                                 g_flg_time_g,
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --até que o cellrender seja actualizado
                                                                     t3.flg_status,
                                                                     'E',
                                                                     t3.flg_status,
                                                                     t3.dt_posit_req_tstz,
                                                                     t3.dt_posit_req_tstz,
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          t3.flg_status)),
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_o, --até que o cellrender seja actualizado
                                                                     t3.flg_status,
                                                                     'E',
                                                                     t3.flg_status,
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_date_utils.add_to_ltstz(s.dt_interv_preview_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_POSIT_DET.FLG_STATUS',
                                                                                          t3.flg_status))),
                          pk_sr_clinical_info.get_string_task(i_lang,
                                                              i_prof,
                                                              g_flg_type_o,
                                                              t3.flg_status,
                                                              'E',
                                                              t3.flg_status,
                                                              greatest(t3.dt_posit_req_tstz, s.dt_interv_preview_tstz),
                                                              greatest(t3.dt_posit_req_tstz, s.dt_interv_preview_tstz),
                                                              pk_sysdomain.get_img(i_lang,
                                                                                   'SR_POSIT_DET.FLG_STATUS',
                                                                                   t3.flg_status))) img_name3,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server
              FROM schedule_sr s,
                   (SELECT rownum num_reg,
                           s1.id_sr_posit,
                           s1.id_sr_posit_req,
                           s1.dt_posit_req_tstz,
                           s1.desc_posit,
                           s1.flg_status
                      FROM (SELECT rownum num_reg,
                                   p.id_sr_posit,
                                   r.id_sr_posit_req,
                                   r.dt_posit_req_tstz,
                                   pk_translation.get_translation(i_lang, p.code_sr_posit) desc_posit,
                                   r.flg_status,
                                   rank() over(ORDER BY spis.id_institution DESC, spis.id_software DESC) origin_rank
                              FROM sr_posit p, sr_posit_req r, sr_posit_instit_soft spis
                             WHERE spis.id_sr_parent = 1
                               AND r.id_episode_context(+) = i_episode
                               AND r.id_sr_posit(+) = p.id_sr_posit
                               AND r.flg_status(+) != g_posit_canc
                               AND p.flg_available = pk_alert_constant.g_yes
                               AND spis.id_sr_posit = p.id_sr_posit
                               AND spis.id_institution IN (0, i_prof.institution)
                               AND spis.id_software IN (0, i_prof.software)
                               AND spis.flg_available = pk_alert_constant.g_available
                             ORDER BY pk_translation.get_translation(i_lang, p.code_sr_posit)) s1
                     WHERE s1.desc_posit IS NOT NULL
                       AND s1.origin_rank = 1) t1,
                   (SELECT rownum num_reg,
                           s1.id_sr_posit,
                           s1.id_sr_posit_req,
                           s1.dt_posit_req_tstz,
                           s1.desc_posit,
                           s1.flg_status
                      FROM (SELECT rownum num_reg,
                                   p.id_sr_posit,
                                   r.id_sr_posit_req,
                                   r.dt_posit_req_tstz,
                                   pk_translation.get_translation(i_lang, p.code_sr_posit) desc_posit,
                                   r.flg_status,
                                   rank() over(ORDER BY spis.id_institution DESC, spis.id_software DESC) origin_rank
                              FROM sr_posit p, sr_posit_req r, sr_posit_instit_soft spis
                             WHERE spis.id_sr_parent = 2
                               AND r.id_episode_context(+) = i_episode
                               AND r.id_sr_posit(+) = p.id_sr_posit
                               AND r.flg_status(+) != g_posit_canc
                               AND p.flg_available = pk_alert_constant.g_yes
                               AND spis.id_sr_posit = p.id_sr_posit
                               AND spis.id_institution IN (0, i_prof.institution)
                               AND spis.id_software IN (0, i_prof.software)
                               AND spis.flg_available = pk_alert_constant.g_available
                             ORDER BY pk_translation.get_translation(i_lang, p.code_sr_posit)) s1
                     WHERE s1.desc_posit IS NOT NULL
                       AND s1.origin_rank = 1) t2,
                   (SELECT rownum num_reg,
                           s1.id_sr_posit,
                           s1.id_sr_posit_req,
                           s1.dt_posit_req_tstz,
                           s1.desc_posit,
                           s1.flg_status
                      FROM (SELECT rownum num_reg,
                                   p.id_sr_posit,
                                   r.id_sr_posit_req,
                                   r.dt_posit_req_tstz,
                                   pk_translation.get_translation(i_lang, p.code_sr_posit) desc_posit,
                                   r.flg_status,
                                   rank() over(ORDER BY spis.id_institution DESC, spis.id_software DESC) origin_rank
                              FROM sr_posit p, sr_posit_req r, sr_posit_instit_soft spis
                             WHERE spis.id_sr_parent = 3
                               AND r.id_episode_context(+) = i_episode
                               AND r.id_sr_posit(+) = p.id_sr_posit
                               AND r.flg_status(+) != g_posit_canc
                               AND p.flg_available = pk_alert_constant.g_yes
                               AND spis.id_sr_posit = p.id_sr_posit
                               AND spis.id_institution IN (0, i_prof.institution)
                               AND spis.id_software IN (0, i_prof.software)
                               AND spis.flg_available = pk_alert_constant.g_available
                             ORDER BY pk_translation.get_translation(i_lang, p.code_sr_posit)) s1
                     WHERE s1.desc_posit IS NOT NULL
                       AND s1.origin_rank = 1) t3,
                   (SELECT rownum cont_reg
                      FROM sr_posit
                     WHERE rownum <= (SELECT MAX(num)
                                        FROM (SELECT s1.id_sr_parent, COUNT(*) num
                                                FROM (SELECT p.id_sr_parent, /*, COUNT(*) num*/
                                                             pk_translation.get_translation(i_lang, sp.code_sr_posit) desc_posit,
                                                             rank() over(PARTITION BY p.id_sr_parent ORDER BY p.id_institution DESC, p.id_software DESC) origin_rank
                                                        FROM sr_posit_instit_soft p, sr_posit sp
                                                       WHERE sp.id_sr_posit = p.id_sr_posit
                                                         AND p.id_sr_parent IS NOT NULL
                                                         AND p.flg_available = pk_alert_constant.g_yes
                                                         AND p.id_institution IN (0, i_prof.institution)
                                                         AND p.id_software IN (0, i_prof.software)) s1
                                               WHERE s1.desc_posit IS NOT NULL
                                                 AND s1.origin_rank = 1
                                               GROUP BY s1.id_sr_parent))) n
             WHERE t1.num_reg(+) = n.cont_reg
               AND t2.num_reg(+) = n.cont_reg
               AND t3.num_reg(+) = n.cont_reg
               AND s.id_episode(+) = i_episode
             ORDER BY n.cont_reg;
    
        g_error := 'OPEN CURSOR O_POSIT_REL';
        pk_alertlog.log_debug(g_error);
        OPEN o_posit_rel FOR
            SELECT spr.id_sr_posit, spr.id_sr_posit_relation, spr.flg_type
              FROM sr_posit_rel spr
             WHERE spr.flg_type = g_flg_type_e
               AND spr.flg_available = pk_alert_constant.g_available;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POSIT_LIST_DET',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_posit);
            pk_types.open_my_cursor(o_status);
            pk_types.open_my_cursor(o_posit_rel);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Lista todos os tipo de reservas
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sr_equip         Tipo de reserva (vem a nulo no 1º nivel do tipo)
    * @param i_type             Tipo de registo: R- Reserva, C- Consumos
    * @param i_search           Texto a pesquisar
    *
    * @param o_reserv           Lista de tipos de reservas
    * @param o_icon_y           Nome do icone a mostrar nas intervenções seleccionadas
    * @param o_icon_pesquisa    Nome do icone a mostrar para limpar o campo da pesquisa
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/16
       ********************************************************************************************/

    FUNCTION get_reserv_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_sr_equip      IN sr_equip.id_sr_equip%TYPE,
        i_type          IN sr_equip.flg_type%TYPE DEFAULT 'R',
        i_search        IN VARCHAR2,
        o_reserv        OUT pk_types.cursor_type,
        o_icon_y        OUT VARCHAR2,
        o_icon_pesquisa OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT pk_sysdomain.get_img(i_lang, 'SR_RESERV.ICON_YN', g_value_y)
          INTO o_icon_y
          FROM dual;
        SELECT pk_sysdomain.get_img(i_lang, 'SR_RESERV.ICON_YN', g_value_c)
          INTO o_icon_pesquisa
          FROM dual;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_reserv FOR
            SELECT p.id_sr_equip,
                   pk_translation.get_translation(i_lang, p.code_equip) desc_equip,
                   decode((SELECT COUNT(*)
                            FROM sr_equip_kit
                           WHERE id_sr_equip_parent = p.id_sr_equip),
                          0,
                          'N',
                          'Y') flg_detail
              FROM sr_equip p
             WHERE p.flg_available = g_available
               AND p.flg_hemo_yn = pk_alert_constant.g_yes
               AND p.flg_type IN (g_equip_flg_type_all, i_type)
               AND ((nvl(p.id_sr_equip_parent, 0) = nvl(i_sr_equip, 0) --and I_SR_EQUIP is null
                   AND
                   translate(upper(pk_translation.get_translation(i_lang, p.code_equip)),
                               'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                               'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%') OR
                   (i_sr_equip IS NOT NULL AND nvl(p.id_sr_equip_parent, 0) != 0 AND i_search IS NOT NULL AND
                   translate(upper(pk_translation.get_translation(i_lang, p.code_equip)),
                               'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                               'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'))
             ORDER BY pk_translation.get_translation(i_lang, p.code_equip);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RESERV_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_reserv);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Lista os periodos operatórios disponíveis para a reserva do equipamento ou material. A
    *   disponibilidade do material ou equipamento para um determinado período operatório é
    *   parametrizada na tabela SR_EQUIP_PERIOD.
    *
    * @param i_lang             Id do idioma
    * @param i_id_equip         ID do equipamento ou material
    *
    * @param o_period           Descrição dos procedimentos
    * @param o_error            Lista de períodos operatórios
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/16
       ********************************************************************************************/

    FUNCTION get_period_list
    (
        i_lang     IN language.id_language%TYPE,
        i_id_equip IN sr_equip.id_sr_equip%TYPE,
        o_period   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_period FOR
            SELECT p.id_surg_period data,
                   pk_translation.get_translation(i_lang, p.code_surg_period) label,
                   ep.flg_default
              FROM sr_surg_period p, sr_equip_period ep
             WHERE ep.id_sr_equip = i_id_equip
               AND p.id_surg_period = ep.id_surg_period
               AND ep.flg_available = g_available
             ORDER BY p.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PERIOD_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_period);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Lista todos os tipo de reservas
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          Id do episódio
    * @param i_type             Tipo de registo: R- Reserva, C- Consumos
    *
    * @param o_req              Lista de reservas
    * @param o_icon_y           Nome do icone a mostrar nas requisições Concluídas
    * @param o_icon_n           Nome do icone a mostrar nas requisições Em Execução
    * @param o_icon_c           Nome do icone a mostrar nas requisições Canceladas
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/16
       ********************************************************************************************/

    FUNCTION get_reserv_req_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN sr_reserv_req.flg_type%TYPE DEFAULT 'R',
        o_req     OUT pk_types.cursor_type,
        o_icon_y  OUT VARCHAR2,
        o_icon_n  OUT VARCHAR2,
        o_icon_c  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sr_time_margin NUMBER;
    
    BEGIN
        -- Obter prazo limite antes da cirurgia para terminar posicionamentos e reservas.
        g_error := 'GET PROC TME LIMIT';
        pk_alertlog.log_debug(g_error);
        l_sr_time_margin := to_number(nvl(pk_sysconfig.get_config('SR_TIME_MARGIN_RES', i_prof), 0));
        l_sr_time_margin := -l_sr_time_margin;
    
        SELECT pk_sysdomain.get_img(i_lang, 'SR_RESERV.FLG_STATUS', g_reserv_exec)
          INTO o_icon_y
          FROM dual;
        SELECT pk_sysdomain.get_img(i_lang, 'SR_RESERV.FLG_STATUS', g_reserv_req)
          INTO o_icon_n
          FROM dual;
        SELECT pk_sysdomain.get_img(i_lang, 'SR_RESERV.FLG_STATUS', g_reserv_canc)
          INTO o_icon_c
          FROM dual;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_req FOR
            SELECT r.id_sr_reserv_req,
                   (SELECT pk_translation.get_translation(i_lang, eq.code_equip)
                      FROM sr_equip eq
                     WHERE eq.id_sr_equip = v.id_sr_equip_parent
                       AND v.id_sr_equip_parent = g_material_kit) desc_reserv_parent,
                   pk_translation.get_translation(i_lang, v.code_equip) desc_reserv,
                   r.qty_req,
                   pk_translation.get_translation(i_lang, p.code_surg_period) desc_period,
                   decode(r.flg_status, g_reserv_req, g_value_n, g_reserv_canc, g_value_c, g_value_y) flg_status,
                   r.flg_status flg_status_ord,
                   r.id_episode,
                   r.id_episode_context,
                   decode(r.flg_status,
                          g_reserv_req,
                          decode(pk_date_utils.compare_dates_tsz(i_prof, current_timestamp, sr.dt_interv_preview_tstz),
                                 g_flg_time_g,
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_p,
                                                                     r.flg_status,
                                                                     pk_sr_clinical_info.g_flg_time_e,
                                                                     r.flg_status,
                                                                     r.dt_req_tstz,
                                                                     r.dt_req_tstz,
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_RESERV.FLG_STATUS',
                                                                                          r.flg_status)),
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_p,
                                                                     r.flg_status,
                                                                     'E',
                                                                     r.flg_status,
                                                                     pk_date_utils.add_to_ltstz(sr.dt_target_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_date_utils.add_to_ltstz(sr.dt_target_tstz,
                                                                                                l_sr_time_margin,
                                                                                                'MINUTE'),
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_RESERV.FLG_STATUS',
                                                                                          r.flg_status))),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     '|I|||#|||||&',
                                                     '',
                                                     'SR_RESERV.FLG_STATUS',
                                                     r.flg_status)) icon,
                   pk_sysdomain.get_domain('SR_RESERV_REQ.FLG_STATUS', r.flg_status, i_lang) desc_status
              FROM sr_reserv_req r, sr_equip v, sr_surg_period p, schedule_sr sr
             WHERE (r.id_episode = i_episode OR r.id_episode_context = i_episode)
               AND v.flg_hemo_yn = pk_alert_constant.g_yes
               AND r.flg_type = i_type
               AND r.id_episode_context = sr.id_episode
               AND v.id_sr_equip = r.id_sr_equip
               AND v.flg_type IN (g_equip_flg_type_all, i_type)
               AND p.id_surg_period(+) = r.id_surg_period
             ORDER BY decode(p.code_surg_period, 'P', 1, 'I', 2, 3),
                      decode(r.flg_status, g_reserv_canc, 10, 1),
                      r.dt_req_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RESERV_REQ_DET',
                                              o_error);
            pk_types.open_my_cursor(o_req);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Actualiza o estado das reservas de R-Requisitado para F-Executado
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_reserv_req       Array de ID de reservas
    * @param i_flg_status_new   Array de novos valores de requisição
    * @param i_flg_status_old   Array de valores antigos de requisição
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/16
       ********************************************************************************************/

    FUNCTION set_reserv_req_status
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_reserv_req     IN table_number,
        i_flg_status_new IN table_varchar,
        i_flg_status_old IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sr_reserv_req sr_reserv_req%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_reserv_req.count
        LOOP
            IF nvl(i_flg_status_new(i), g_reserv_req) != nvl(i_flg_status_old(i), g_reserv_req)
            THEN
                --actualiza o estado da requisição de Requisitado para Executado ou vice_versa
                l_id_sr_reserv_req.id_sr_reserv_req := i_reserv_req(i);
                l_id_sr_reserv_req.id_episode       := i_episode;
                --
                IF nvl(i_flg_status_new(i), g_value_n) = g_value_n
                THEN
                    l_id_sr_reserv_req.flg_status := g_reserv_req;
                ELSE
                    l_id_sr_reserv_req.flg_status := g_reserv_exec;
                END IF;
            
                --Se o novo estado for Executado, preenche o profissional e a data, senão limpa-os
                IF l_id_sr_reserv_req.flg_status = g_reserv_exec
                THEN
                    l_id_sr_reserv_req.id_prof_exec := i_prof.id;
                    l_id_sr_reserv_req.dt_exec_tstz := g_sysdate_tstz;
                ELSE
                    l_id_sr_reserv_req.dt_req_tstz  := g_sysdate_tstz;
                    l_id_sr_reserv_req.id_prof_req  := i_prof.id;
                    l_id_sr_reserv_req.id_prof_exec := NULL;
                    l_id_sr_reserv_req.dt_exec_tstz := NULL;
                END IF;
            
                --Actualiza a requisição
                g_error := 'UPDATE REQ STATUS';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_output.update_sr_reserv_req_status(i_lang       => i_lang,
                                                                i_reserv_req => l_id_sr_reserv_req,
                                                                i_prof       => i_prof,
                                                                o_error      => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_RESERV_REQ_STATUS',
                                                      o_error);
                    pk_utils.undo_changes;
                
                    RETURN FALSE;
                END IF;
            
                --Actualiza a tabela GRID_TASK
                g_error := 'UPDATE GRID_TASK';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_planning.update_reserve_grid_task(i_lang       => i_lang,
                                                               i_reserv_req => l_id_sr_reserv_req,
                                                               i_prof       => i_prof,
                                                               o_error      => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_RESERV_REQ_STATUS',
                                                      o_error);
                    pk_utils.undo_changes;
                
                    RETURN FALSE;
                END IF;
            
            END IF;
        
        END LOOP;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_RESERV_REQ_STATUS',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_RESERV_REQ_STATUS',
                                                  o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_RESERV_REQ_STATUS',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Guarda valores e sai
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_RESERV_REQ_STATUS',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Guarda as reservas/consumos efectuados
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_episode          Id do episódio de destino onde o registo poderá ser consultado
    * @param i_protocols        ID do protocolo
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sr_intervention  ID da intervenção
    * @param i_reserv           Array de ID de reservas
    * @param i_flg_status_new   Array de novos estados de reservas
    * @param i_flg_status_old   Array de novos estados de reservas
    * @param i_surg_period      ID do período operatório
    * @param i_qty_req          Quantidade reservada
    * @param i_type             Tipo de registo: R- Reserva, C- Consumos
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/14
       ********************************************************************************************/

    FUNCTION set_reserv_req_det
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_protocols       IN protocols.id_protocols%TYPE,
        i_prof            IN profissional,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_reserv          IN table_number,
        i_flg_status_new  IN table_varchar,
        i_flg_status_old  IN table_varchar,
        i_surg_period     IN table_number,
        i_qty_req         IN table_number,
        i_type            IN sr_reserv_req.flg_type%TYPE DEFAULT 'R',
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_reserv_req   sr_reserv_req%ROWTYPE;
        l_flg_schedule_yn sr_equip.flg_schedule_yn%TYPE;
        l_flg_hemo_yn     sr_equip.flg_hemo_yn%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_reserv.count
        LOOP
            --para cada reserva, compara se o valor de requisição mudou
            IF nvl(i_flg_status_new(i), g_inactive) != nvl(i_flg_status_old(i), g_inactive)
            THEN
                l_sr_reserv_req                    := NULL;
                l_sr_reserv_req.id_episode         := i_episode;
                l_sr_reserv_req.id_episode_context := nvl(i_episode_context, i_episode);
                l_sr_reserv_req.id_sr_intervention := i_sr_intervention;
                l_sr_reserv_req.dt_req_tstz        := g_sysdate_tstz;
                l_sr_reserv_req.id_prof_req        := i_prof.id;
                l_sr_reserv_req.id_sr_equip        := i_reserv(i);
                l_sr_reserv_req.id_surg_period     := i_surg_period(i);
                l_sr_reserv_req.qty_req            := i_qty_req(i);
                l_sr_reserv_req.id_protocols       := i_protocols;
                l_sr_reserv_req.flg_type           := i_type;
            
                --Cria um novo rowtype com o id_episode do epiódio ORIS para actualizar a grid_task
                --do episódio do ORIS também, com as reservas efectuadas noutro produto aparecerem
                --com o estado correcto na grelha do ORIS.
                --                l_sr_reserv_req_context                    := NULL;
                --                l_sr_reserv_req_context.id_episode         := i_episode_context;
                --                l_sr_reserv_req_context.id_episode_context := nvl(i_episode_context, i_episode);
                --                l_sr_reserv_req_context.id_sr_intervention := i_sr_intervention;
                --                l_sr_reserv_req_context.dt_req             := g_sysdate;
                --                l_sr_reserv_req_context.dt_req_tstz        := g_sysdate_tstz;
                --                l_sr_reserv_req_context.id_prof_req        := i_prof.id;
                --                l_sr_reserv_req_context.id_sr_equip        := i_reserv(i);
                --                l_sr_reserv_req_context.id_surg_period     := i_surg_period(i);
                --                l_sr_reserv_req_context.qty_req            := i_qty_req(i);
                --                l_sr_reserv_req_context.id_protocols       := i_protocols;
                --                l_sr_reserv_req_context.flg_type           := i_type;
            
                --Verifica se é para efectuar uma nova requisição
                IF nvl(i_flg_status_new(i), g_inactive) IN (g_active, g_value_y)
                THEN
                    --Insere a requisição
                    SELECT seq_sr_reserv_req.nextval
                      INTO l_sr_reserv_req.id_sr_reserv_req
                      FROM dual;
                    l_sr_reserv_req.flg_status := g_reserv_req;
                    --
                    g_error := 'INSERT SR_RESERV_REQ';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_output.insert_sr_reserv_req(i_lang       => i_lang,
                                                             i_reserv_req => l_sr_reserv_req,
                                                             o_error      => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'SET_RESERV_REQ_DET',
                                                          o_error);
                        pk_utils.undo_changes;
                    
                        RETURN FALSE;
                    END IF;
                
                    --Verfica se é uma reserva ou um consumo. Os consumos não são visualizados nas grelhas.
                    IF i_type = g_equip_flg_type_r
                    THEN
                        --verifica se a reserva é de um equipamento "agendável" ou de um hemoderivado, pois só estes
                        -- têm workflows visíveis nas grelhas
                        l_flg_schedule_yn := NULL;
                        l_flg_hemo_yn     := NULL;
                        --
                        g_error := 'GET FLG_SCHEDULE AND FLG_HEMO';
                        BEGIN
                            SELECT flg_schedule_yn, flg_hemo_yn
                              INTO l_flg_schedule_yn, l_flg_hemo_yn
                              FROM sr_equip
                             WHERE id_sr_equip = l_sr_reserv_req.id_sr_equip;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_flg_schedule_yn := NULL;
                                l_flg_hemo_yn     := NULL;
                        END;
                    
                        IF l_flg_schedule_yn = 'Y'
                           OR l_flg_hemo_yn = 'Y'
                        THEN
                            --Actualiza a tabela GRID_TASK do episódio onde foi feita a requisição
                            g_error := 'UPDATE GRID_TASK';
                            pk_alertlog.log_debug(g_error);
                            IF NOT pk_sr_planning.update_reserve_grid_task(i_lang       => i_lang,
                                                                           i_reserv_req => l_sr_reserv_req,
                                                                           i_prof       => i_prof,
                                                                           o_error      => o_error)
                            THEN
                                pk_alert_exceptions.reset_error_state;
                                pk_alert_exceptions.process_error(i_lang,
                                                                  SQLCODE,
                                                                  SQLERRM,
                                                                  g_error,
                                                                  g_package_owner,
                                                                  g_package_name,
                                                                  'SET_RESERV_REQ_DET',
                                                                  o_error);
                                pk_utils.undo_changes;
                            
                                RETURN FALSE;
                            END IF;
                        
                        END IF;
                    
                    END IF;
                
                ELSE
                
                    --Cancela a requisição
                    --Obtem ID do detalhe da requisição a cancelar
                    g_error := 'GET ID_SR_RESERV_REQ';
                    pk_alertlog.log_debug(g_error);
                    BEGIN
                        SELECT id_sr_reserv_req
                          INTO l_sr_reserv_req.id_sr_reserv_req
                          FROM sr_reserv_req
                         WHERE id_episode = l_sr_reserv_req.id_episode
                           AND id_sr_equip = l_sr_reserv_req.id_sr_equip
                           AND flg_type = i_type
                           AND qty_req = l_sr_reserv_req.qty_req;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_sr_reserv_req.id_sr_reserv_req := NULL;
                    END;
                    l_sr_reserv_req.flg_status     := g_reserv_canc;
                    l_sr_reserv_req.id_prof_cancel := i_prof.id;
                    l_sr_reserv_req.dt_cancel_tstz := g_sysdate_tstz;
                
                    g_error := 'CANCEL RESERV REQ';
                    pk_alertlog.log_debug(g_error);
                    --Cancela a requisição
                    IF l_sr_reserv_req.id_sr_reserv_req IS NOT NULL
                       AND NOT pk_sr_output.cancel_sr_reserv_req(i_lang       => i_lang,
                                                                 i_reserv_req => l_sr_reserv_req,
                                                                 o_error      => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'SET_RESERV_REQ_DET',
                                                          o_error);
                        pk_utils.undo_changes;
                    
                        RETURN FALSE;
                    END IF;
                
                    --Actualiza a tabela GRID_TASK
                    g_error := 'UPDATE GRID_TASK';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_planning.update_reserve_grid_task(i_lang       => i_lang,
                                                                   i_reserv_req => l_sr_reserv_req,
                                                                   i_prof       => i_prof,
                                                                   o_error      => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'SET_RESERV_REQ_DET',
                                                          o_error);
                        pk_utils.undo_changes;
                    
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        
        END LOOP;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_RESERV_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_RESERV_REQ_DET',
                                                  o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_RESERV_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Guarda valores e sai
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_RESERV_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Cancela as requisições de posicionamentos efectuadas
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_sr_reserv_req    ID da reserva a cancelar
    * @param i_prof             ID do profissional, instituição e software
    * @param i_notes_cancel     Notas de cancelamento
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/04/27
       ********************************************************************************************/

    FUNCTION cancel_reserv_req
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_sr_reserv_req IN sr_reserv_req.id_sr_reserv_req%TYPE,
        i_prof          IN profissional,
        i_notes_cancel  IN sr_reserv_req.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_reserv_req sr_reserv_req%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --Verifica se o item já tinha sido cancelado anteriormente
        g_error                          := 'INIT VARIABLES';
        l_sr_reserv_req.id_sr_reserv_req := i_sr_reserv_req;
        l_sr_reserv_req.id_episode       := i_episode;
        l_sr_reserv_req.flg_status       := g_reserv_canc;
        l_sr_reserv_req.dt_cancel_tstz   := g_sysdate_tstz;
        l_sr_reserv_req.id_prof_cancel   := i_prof.id;
        l_sr_reserv_req.notes_cancel     := i_notes_cancel;
    
        --Cancela a requisição
        g_error := 'CANCEL RESERV REQ';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.cancel_sr_reserv_req(i_lang, l_sr_reserv_req, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_RESERV_REQ',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela GRID_TASK
        g_error := 'UPDATE GRID_TASK';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.update_reserve_grid_task(i_lang       => i_lang,
                                                       i_reserv_req => l_sr_reserv_req,
                                                       i_prof       => i_prof,
                                                       o_error      => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_RESERV_REQ',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_RESERV_REQ',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CANCEL_RESERV_REQ',
                                                  o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_RESERV_REQ',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_RESERV_REQ',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Cancela as requisições de materiais e equipamentes efectuadas por um protocolo
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_protocols        ID do protocolo
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sr_intervention  ID da intervenção
    * @param i_reserv           Array de ID de detalhes de reservas a cancelar
    * @param i_flg_status_new   Array de novos estados de reservas
    * @param i_flg_status_old   Array de antigos estados de reservas
    * @param i_surg_period      ID do período operatório
    * @param i_qty_req          Quantidade reservada
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/03/14
       ********************************************************************************************/

    FUNCTION set_cancel_reserv_req_det
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_protocols       IN protocols.id_protocols%TYPE,
        i_prof            IN profissional,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_reserv          IN table_number,
        i_flg_status_new  IN table_varchar,
        i_flg_status_old  IN table_varchar,
        i_surg_period     IN table_number,
        i_qty_req         IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_reserv_req sr_reserv_req%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_reserv.count
        LOOP
            --para cada reserva, compara se o valor de requisição mudou
            IF nvl(i_flg_status_new(i), g_inactive) != nvl(i_flg_status_old(i), g_inactive)
            THEN
                l_sr_reserv_req                    := NULL;
                l_sr_reserv_req.id_episode         := i_episode;
                l_sr_reserv_req.id_sr_reserv_req   := i_reserv(i);
                l_sr_reserv_req.id_sr_intervention := i_sr_intervention;
                l_sr_reserv_req.dt_req_tstz        := g_sysdate_tstz;
                l_sr_reserv_req.id_prof_req        := i_prof.id;
                l_sr_reserv_req.id_surg_period     := i_surg_period(i);
                l_sr_reserv_req.qty_req            := i_qty_req(i);
                l_sr_reserv_req.id_protocols       := i_protocols;
                l_sr_reserv_req.flg_status         := g_reserv_canc;
                l_sr_reserv_req.id_prof_cancel     := i_prof.id;
                l_sr_reserv_req.dt_cancel_tstz     := g_sysdate_tstz;
            
                g_error := 'CANCEL RESERV REQ';
                pk_alertlog.log_debug(g_error);
                --Cancela a requisição
                IF NOT pk_sr_output.cancel_sr_reserv_req(i_lang       => i_lang,
                                                         i_reserv_req => l_sr_reserv_req,
                                                         o_error      => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_CANCEL_RESERV_REQ_DET',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                --Actualiza a tabela GRID_TASK
                g_error := 'UPDATE GRID_TASK';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_planning.update_reserve_grid_task(i_lang       => i_lang,
                                                               i_reserv_req => l_sr_reserv_req,
                                                               i_prof       => i_prof,
                                                               o_error      => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_CANCEL_RESERV_REQ',
                                                      o_error);
                    pk_utils.undo_changes;
                
                    RETURN FALSE;
                END IF;
            
            END IF;
        
        END LOOP;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CANCEL_RESERVE_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_CANCEL_RESERV_REQ_DET',
                                                  o_error);
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CANCEL_RESERV_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        END IF;
    
        --Guarda valores e sai
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CANCEL_RESERV_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Compare if the timestamp is more recent of the surgical date. In case the timestamp is more recent
    * then the requisition date is used else is the surgical date minus the time margin (defined in sys_config)
    *
    * @param i_lang             id_language
    * @param i_prof             ID professional, institution e software
    * @param i_episode          id_episode
    * @param i_dt_req_tstz      requisition's date
    *
    * @param o_surg_date_is_null return (Y) if the surgery_date is null otherwise (N) 
    *
    * @return                   TIMESTAMP
    *
    * @author                   Filipe Silva
    * @Version                  2.6.0.4
    * @since                    2010/11/18
       ********************************************************************************************/

    FUNCTION get_surg_dt_margin
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_dt_req_tstz IN sr_reserv_req.dt_req_tstz%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_surgery_with_margin schedule_sr.dt_interv_preview_tstz%TYPE;
        l_error               t_error_out;
        l_dt_surg             VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'CALL GET_SURG_DT_MARGIN FOR ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_surgery_with_margin := get_surg_dt_margin(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_episode           => i_episode,
                                                    i_dt_req_tstz       => i_dt_req_tstz,
                                                    o_surg_date_is_null => l_dt_surg);
    
        RETURN l_surgery_with_margin;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURG_DT_MARGIN',
                                              l_error);
            RETURN NULL;
        
    END get_surg_dt_margin;

    /********************************************************************************************
    * Compare if the timestamp is more recent of the surgical date. In case the timestamp is more recent
    * then the requisition date is used else is the surgical date minus the time margin (defined in sys_config)
    *
    * @param i_lang             id_language
    * @param i_prof             ID professional, institution e software
    * @param i_episode          id_episode
    * @param i_dt_req_tstz      requisition's date
    *
    * @param o_surg_date_is_null return (Y) if the surgery_date is null otherwise (N) 
    *
    * @return                   TIMESTAMP
    *
    * @author                   Filipe Silva
    * @Version                  2.5.0.7.7
    * @since                    2010/03/01
       ********************************************************************************************/

    FUNCTION get_surg_dt_margin
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_dt_req_tstz       IN sr_reserv_req.dt_req_tstz%TYPE,
        o_surg_date_is_null OUT VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_sr_time_margin      NUMBER;
        l_surgery_date        schedule_sr.dt_interv_preview_tstz%TYPE;
        l_compare_date        VARCHAR2(1);
        l_surgery_with_margin schedule_sr.dt_interv_preview_tstz%TYPE;
        l_error               t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET PROC TME LIMIT';
        pk_alertlog.log_debug(g_error);
        l_sr_time_margin := to_number(nvl(pk_sysconfig.get_config('SR_TIME_MARGIN_RES', i_prof), 0));
        l_sr_time_margin := -l_sr_time_margin;
    
        g_error := 'GET SURGERY DATE';
        pk_alertlog.log_debug(g_error);
        SELECT sr.dt_target_tstz
          INTO l_surgery_date
          FROM schedule_sr sr
         WHERE sr.id_episode = i_episode;
    
        IF l_surgery_date IS NULL
        THEN
            l_surgery_with_margin := i_dt_req_tstz;
            o_surg_date_is_null   := pk_alert_constant.g_yes;
        
        ELSE
            g_error := 'COMPARE SURGERY DATE WITH TIMESTAMP';
            pk_alertlog.log_debug(g_error);
            l_compare_date := pk_date_utils.compare_dates_tsz(i_prof, g_sysdate_tstz, l_surgery_date);
        
            IF l_compare_date != g_flg_time_g
            THEN
                l_surgery_with_margin := pk_date_utils.add_to_ltstz(l_surgery_date, l_sr_time_margin, 'MINUTE');
            ELSE
                l_surgery_with_margin := i_dt_req_tstz;
            END IF;
            o_surg_date_is_null := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_surgery_with_margin;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURG_DT_MARGIN',
                                              l_error);
            RETURN NULL;
        
    END get_surg_dt_margin;

    /********************************************************************************************
    * Actualiza o estado de uma reserva na tabela GRID_TASK
    *
    * @param i_lang             Id do idioma
    * @param i_reserv_req       Registo a actualizar
    * @param i_prof             ID do profissional, instituição e software
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/04
       ********************************************************************************************/

    FUNCTION update_reserve_grid_task
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_img_name           sys_domain.img_name%TYPE;
        l_id_sys_shortcut    sys_shortcut.id_sys_shortcut%TYPE;
        l_id_episode_context episode.id_episode%TYPE;
        l_flg_hemo_yn        sr_equip.flg_hemo_yn%TYPE;
        l_dt_req_tstz        sr_reserv_req.dt_req_tstz%TYPE;
        l_flg_status         sr_reserv_req.flg_status%TYPE;
        l_mess               VARCHAR2(100);
        l_grid_task          grid_task%ROWTYPE;
        l_found              BOOLEAN := FALSE;
        l_surgery_date       schedule_sr.dt_interv_preview_tstz%TYPE;
        l_check_surgery_date VARCHAR2(1 CHAR);
    
        --Os dois próximos cursores foram alterados para fixar o software ORIS. Se a requisição é
        --feita num produto diferente do ORIS, não faz sentido na string guardar o shortcut desse
        --produto mas sim o do ORIS, já que este workflow só vai poder executar shortcuts no ORIS.
        -- the id_sys_shortcut for the physician is diferent the anesthesist one because the id_sys_application_area 
        --is diferents for both, so is necessary get the id_sys_shortcut parent 
        CURSOR c_get_shortcut IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = 'SR_RESERVE'
               AND id_software = g_software_oris
               AND id_institution IN (0, i_prof.institution)
               AND id_parent IS NULL
             ORDER BY id_institution DESC;
    
        CURSOR c_mat_hemo IS
            SELECT pk_sysdomain.get_img(i_lang, 'MATERIAL_REQ.FLG_STATE', r.flg_status) img_name,
                   r.id_episode_context,
                   r.dt_req_tstz,
                   r.flg_status
              FROM sr_reserv_req r, sr_equip e
             WHERE (r.id_episode = i_reserv_req.id_episode OR r.id_episode_context = i_reserv_req.id_episode)
               AND r.flg_status != g_cancel
               AND e.id_sr_equip = r.id_sr_equip
               AND e.flg_hemo_yn = 'Y'
             ORDER BY decode(r.flg_status, g_reserv_flg_status_r, 1, g_reserv_flg_status_f, 2, 3), dt_req_tstz;
    
    BEGIN
    
        --PROC_WRITE_LOG ( 'log.txt',null, 'entrou', l_error);
        --Verifica se é uma requisição de mteriais agendáveis ou de hemoderivados
        --Caso não seja nem uma nem outra não faz nada já que só estas têm workflows
        BEGIN
            g_error := 'GET EQUIP FLAGS';
            pk_alertlog.log_debug(g_error);
            SELECT flg_hemo_yn
              INTO l_flg_hemo_yn
              FROM sr_equip e, sr_reserv_req r
             WHERE r.id_sr_reserv_req = i_reserv_req.id_sr_reserv_req
               AND e.id_sr_equip = r.id_sr_equip;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_hemo_yn := NULL;
        END;
    
        --Preenche dados a actualiza da reserva na tabela GRID_TASK
        l_grid_task.id_episode := i_reserv_req.id_episode;
        l_mess                 := NULL;
    
        OPEN c_get_shortcut;
        FETCH c_get_shortcut
            INTO l_id_sys_shortcut;
        CLOSE c_get_shortcut;
    
        IF l_flg_hemo_yn = 'Y'
        THEN
            --Sangue e hemoderivados
            g_error := 'GET HEMO GRID_TASK';
            pk_alertlog.log_debug(g_error);
            OPEN c_mat_hemo;
            FETCH c_mat_hemo
                INTO l_img_name, l_id_episode_context, l_dt_req_tstz, l_flg_status;
            l_found := c_mat_hemo%FOUND;
            CLOSE c_mat_hemo;
            IF l_found
            THEN
            
                g_error := 'GET THE SURGICAL DATE WITH MARGIN';
                pk_alertlog.log_debug(g_error);
                l_surgery_date := pk_sr_planning.get_surg_dt_margin(i_lang,
                                                                    i_prof,
                                                                    l_id_episode_context,
                                                                    l_dt_req_tstz,
                                                                    l_check_surgery_date);
            
                l_mess := l_id_sys_shortcut || '|' ||
                          pk_sr_clinical_info.get_string_task(i_lang,
                                                              i_prof,
                                                              g_flg_type_o,
                                                              l_flg_status,
                                                              'E',
                                                              l_flg_status,
                                                              l_surgery_date,
                                                              l_surgery_date,
                                                              l_img_name);
            
                l_grid_task.hemo_req := l_mess;
            ELSE
                l_mess               := NULL;
                l_grid_task.hemo_req := NULL;
            END IF;
        ELSE
            --Não é equipamento agendável nem hemoderivado por isso não actualiza a GRID_TASK
            RETURN TRUE;
        END IF;
    
        --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
        g_error := 'UPDATE GRID_TASK';
        pk_alertlog.log_debug(g_error);
    
        -- insert into grid_task the oris episode
        l_grid_task.id_episode := nvl(l_id_episode_context, i_reserv_req.id_episode); --nvl(i_reserv_req.id_episode, l_id_episode) 
    
        IF l_mess IS NOT NULL
        THEN
            --Actualiza a GRID_TASK com a informação da reserva actual
            g_error := 'CALL TO PK_GRID.UPDATE_GRID_TASK';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_grid.update_grid_task(i_lang => i_lang, i_grid_task => l_grid_task, o_error => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'UPDATE_RESERVE_GRID_TASK',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        ELSE
            IF l_flg_hemo_yn = 'Y'
            THEN
                --Limpa a coluna de hemoderivados da GRID_TASK
                g_error := 'UPDATE HEMO_REQ';
                pk_alertlog.log_debug(g_error);
                UPDATE grid_task
                   SET hemo_req = NULL
                 WHERE id_episode = l_grid_task.id_episode;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_RESERVE_GRID_TASK',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter as intervenções cirurgicas mais frequentes para um departamento clínico
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          Id do episódio
    * @param i_patient          ID do paciente
    * @param i_dep_clin_serv    ID do departamento clínico
    * @param i_search           Texto a pesquisar
    * @param i_flg_freq         Y - more frequent texts; N - otherwise
    *
    * @param o_list             Lista das intervenções mais frequentes
    * @param o_list_sel         Lista das intervenções cirúrgicas seleccionadas
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/09
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    /********************************************************************************************
    * Obter as intervenções cirurgicas mais frequentes para um departamento clínico
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          Id do episódio
    * @param i_patient          ID do paciente
    * @param i_dep_clin_serv    ID do departamento clínico
    * @param i_search           Texto a pesquisar
    * @param i_flg_freq         Y - more frequent texts; N - otherwise
    *
    * @param o_list             Lista das intervenções mais frequentes
    * @param o_list_sel         Lista das intervenções cirúrgicas seleccionadas
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/09
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION get_freq_interv_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_search        IN VARCHAR2,
        i_flg_freq      IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_list_sel      OUT pk_types.cursor_type,
        o_status        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        r_pat    c_pat%ROWTYPE;
        l_coding sys_config.value%TYPE;
    
        l_id_dep_clin_serv     dep_clin_serv.id_dep_clin_serv%TYPE;
        l_sr_code_intervention translation.code_translation%TYPE := 'INTERVENTION.CODE_INTERVENTION';
        l_id_institution       institution.id_institution%TYPE;
    BEGIN
    
        IF (i_dep_clin_serv IS NOT NULL)
        THEN
        
            IF (i_dep_clin_serv <> -1)
            THEN
                l_id_dep_clin_serv := i_dep_clin_serv;
            ELSE
                l_id_dep_clin_serv := NULL;
            END IF;
        
            BEGIN
                SELECT b.id_institution
                  INTO l_id_institution
                  FROM dep_clin_serv a
                 INNER JOIN department b
                    ON a.id_department = b.id_department
                 WHERE a.id_dep_clin_serv = i_dep_clin_serv;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_institution := i_prof.institution;
            END;
        
        ELSE
            --
            IF (i_episode IS NOT NULL)
            THEN
                g_error := 'CALL pk_episode.get_dep_clin_serv. i_episode: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                l_id_dep_clin_serv := pk_episode.get_dep_clin_serv(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_episode => i_episode);
            
            END IF;
        
            l_id_institution := i_prof.institution;
        
        END IF;
    
        --obtém o valor da codificação a utilizar
        g_error  := 'GET SURG CODIFICATION';
        l_coding := pk_sysconfig.get_config(i_code_cf => pk_alert_constant.g_sys_config_surg_coding, i_prof => i_prof);
    
        --Obtém dados do doente para possibilitar validação por sexo
        g_error := 'OPEN C_PAT';
        pk_alertlog.log_debug(g_error);
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        --Obtem lista de estados possíveis
        g_error := 'GET STATUS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_status FOR
            SELECT val, img_name
              FROM sys_domain
             WHERE code_domain = 'SR_EPIS_INTERV.FLG_STATUS'
               AND flg_available = 'Y'
               AND id_language = i_lang;
    
        --Abre cursor com as intervenções cirúrgicas mais frequentes disponíveis
        g_error := 'OPEN LIST CURSOR. l_id_dep_clin_serv: ' || l_id_dep_clin_serv;
        pk_alertlog.log_debug(g_error);
    
        OPEN o_list FOR
            SELECT id_sr_intervention,
                   pk_translation.get_translation(i_lang, code_sr_intervention) || ' / ' || to_char(icd) desc_interv,
                   id_sr_epis_interv,
                   flg_status,
                   rank
              FROM (SELECT DISTINCT i.id_intervention id_sr_intervention,
                                    i.code_intervention code_sr_intervention,
                                    to_char(ic.standard_code) icd,
                                    NULL id_sr_epis_interv,
                                    g_inactive flg_status,
                                    ds.rank rank
                      FROM interv_dep_clin_serv ds
                      JOIN intervention i
                        ON i.id_intervention = ds.id_intervention
                    --AND i.flg_coding = l_coding
                      JOIN interv_codification ic
                        ON ic.id_intervention = i.id_intervention
                     WHERE ds.id_institution = l_id_institution
                       AND ds.id_software = g_software_oris
                       AND instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                       AND (ds.flg_type = g_freq_interv OR i_flg_freq = pk_alert_constant.g_no)
                       AND (((EXISTS (SELECT 1
                                        FROM prof_dep_clin_serv pdcs
                                       WHERE pdcs.id_professional = i_prof.id
                                         AND pdcs.id_institution = i_prof.institution
                                         AND pdcs.flg_status = pk_alert_constant.g_status_selected
                                         AND pdcs.id_dep_clin_serv = ds.id_dep_clin_serv) OR
                            ds.id_dep_clin_serv = l_id_dep_clin_serv) AND i_flg_freq = pk_alert_constant.g_yes) OR
                           (i_flg_freq = pk_alert_constant.g_no))
                       AND i.flg_status = pk_alert_constant.g_active
                       AND NOT EXISTS (SELECT 1
                              FROM sr_epis_interv e
                             WHERE e.id_episode_context = i_episode
                               AND e.id_sr_intervention = i.id_intervention
                               AND e.flg_status != g_interv_can)
                       AND i_search IS NULL
                       AND ((r_pat.gender IS NOT NULL AND nvl(i.gender, 'I') IN ('I', r_pat.gender)) OR
                           r_pat.gender IS NULL OR r_pat.gender = 'I')
                       AND (nvl(r_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                           nvl(i.age_max, nvl(r_pat.age, 0)) OR nvl(r_pat.age, 0) = 0)
                    UNION
                    SELECT /*+ opt_estimate(table t rows=1)*/
                    DISTINCT i.id_intervention id_sr_intervention,
                             i.code_intervention code_sr_intervention,
                             to_char(ic.standard_code) icd,
                             NULL id_sr_epis_interv,
                             g_inactive flg_status,
                             100 rank
                      FROM intervention i,
                           TABLE(pk_translation.get_search_translation(i_lang, i_search, l_sr_code_intervention)) t,
                           interv_dep_clin_serv ds,
                           interv_codification ic
                     WHERE i.code_intervention = t.code_translation
                       AND ds.id_intervention = i.id_intervention
                       AND ic.id_intervention = i.id_intervention
                          --AND i.flg_coding = l_coding
                       AND i.flg_status = pk_alert_constant.g_active
                       AND ds.id_institution = l_id_institution
                       AND ds.id_software = g_software_oris
                       AND instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                       AND (ds.flg_type = g_freq_interv OR i_flg_freq = pk_alert_constant.g_no)
                       AND (((EXISTS (SELECT 1
                                        FROM prof_dep_clin_serv pdcs
                                       WHERE pdcs.id_professional = i_prof.id
                                         AND pdcs.id_institution = i_prof.institution
                                         AND pdcs.flg_status = pk_alert_constant.g_status_selected
                                         AND pdcs.id_dep_clin_serv = ds.id_dep_clin_serv) OR
                            ds.id_dep_clin_serv = l_id_dep_clin_serv) AND i_flg_freq = pk_alert_constant.g_yes) OR
                           (i_flg_freq = pk_alert_constant.g_no))
                       AND NOT EXISTS (SELECT 1
                              FROM sr_epis_interv e
                             WHERE e.id_episode_context = i_episode
                               AND e.id_sr_intervention = i.id_intervention
                               AND e.flg_status != g_interv_can)
                       AND i_search IS NOT NULL
                       AND ((r_pat.gender IS NOT NULL AND nvl(i.gender, 'I') IN ('I', r_pat.gender)) OR
                           r_pat.gender IS NULL OR r_pat.gender = 'I')
                       AND (nvl(r_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                           nvl(i.age_max, nvl(r_pat.age, 0)) OR nvl(r_pat.age, 0) = 0)
                     ORDER BY rank, 2) common_procedures;
    
        --Abre cursor com as intervenções cirúrgicas mais frequentes seleccionadas
        g_error := 'OPEN LIST_SEL CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list_sel FOR
            SELECT e.id_sr_intervention,
                   pk_translation.get_translation(i_lang, i.code_intervention) || ' / ' || to_char(ic.standard_code) desc_interv,
                   e.id_sr_epis_interv,
                   g_active flg_status,
                   decode(e.flg_status, g_interv_tmp, g_interv_tmp, g_interv_req) flg_tmp
              FROM sr_epis_interv e, intervention i, interv_codification ic
             WHERE e.id_episode_context = i_episode
               AND i.id_intervention = e.id_sr_intervention
               AND i.id_intervention = ic.id_intervention
               AND e.flg_status = g_interv_tmp
             ORDER BY 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FREQ_INTERV_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_list_sel);
            pk_types.open_my_cursor(o_status);
        
            RETURN FALSE;
        
    END get_freq_interv_epis;

    /********************************************************************************************
    * Obter as intervenções cirurgicas mais frequentes para um departamento clínico
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          Id do episódio
    * @param i_patient          ID do paciente
    * @param i_dep_clin_serv    ID do departamento clínico
    * @param i_search           Texto a pesquisar    
    *
    * @param o_list             Lista das intervenções mais frequentes
    * @param o_list_sel         Lista das intervenções cirúrgicas seleccionadas
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *     
    * @author    Sofia Mendes
    * @version   2.6.1
    * @since     19-Mai-2011   
    *********************************************************************************************/
    FUNCTION get_freq_interv_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_search        IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_list_sel      OUT pk_types.cursor_type,
        o_status        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_freq_interv_epis';
        pk_alertlog.log_debug(g_error);
        IF NOT get_freq_interv_epis(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_episode       => i_episode,
                                    i_patient       => i_patient,
                                    i_dep_clin_serv => i_dep_clin_serv,
                                    i_search        => i_search,
                                    i_flg_freq      => pk_alert_constant.g_no,
                                    o_list          => o_list,
                                    o_list_sel      => o_list_sel,
                                    o_status        => o_status,
                                    o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FREQ_INTERV_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_list_sel);
            pk_types.open_my_cursor(o_status);
        
            RETURN FALSE;
        
    END get_freq_interv_epis;

    /********************************************************************************************
    * Prescrever temporariamente as intervenções cirúrgicas para um episódio. Só ao fazer OK no
    *   ecrã é que elas ficarão activas permanentemente.
    *
    * @param i_lang                 Id do idioma
    * @param i_episode              Id do episódio
    * @param i_episode_context      ID do episódio de contexto, onde a informação poderá ser visível
    * @param i_sr_intervention      ID da intervenção
    * @param i_prof                 ID do profissional, instituição e software
    * @param o_error                Mensagem de erro
    *
    * @return                       TRUE/FALSE
    *
    * @author                       Rui Batista
    * @since                        2006/10/10
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION call_set_epis_surg_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_sr_intervention   IN intervention.id_intervention%TYPE,
        i_prof              IN profissional,
        o_id_sr_epis_interv OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_epis_interv         sr_epis_interv%ROWTYPE;
        internal_error_exception EXCEPTION;
    BEGIN
    
        g_sysdate_tstz   := current_timestamp;
        l_sr_epis_interv := NULL;
    
        l_sr_epis_interv.dt_req_tstz        := g_sysdate_tstz;
        l_sr_epis_interv.id_prof_req        := i_prof.id;
        l_sr_epis_interv.id_sr_intervention := i_sr_intervention;
        l_sr_epis_interv.flg_code_type      := g_flg_code_type_c;
        l_sr_epis_interv.id_episode         := i_episode;
        l_sr_epis_interv.flg_type           := g_epis_interv_type_s;
        l_sr_epis_interv.flg_status         := g_interv_tmp;
        l_sr_epis_interv.id_episode_context := nvl(i_episode_context, i_episode);
    
        -- a temporary uncoded surgical procedure will be inserted 
        -- later, with the "ok button" its status will be updated
    
        IF i_sr_intervention IS NOT NULL
        THEN
            g_error := 'GET seq_sr_epis_interv.nextval';
            pk_alertlog.log_debug(g_error);
            SELECT seq_sr_epis_interv.nextval
              INTO l_sr_epis_interv.id_sr_epis_interv
              FROM dual;
        
            o_id_sr_epis_interv := l_sr_epis_interv.id_sr_epis_interv;
        
            g_error := 'PK_SR_OUTPUT.INSERT_SR_EPIS_INTERV';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.insert_sr_epis_interv(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_sr_epis_interv => l_sr_epis_interv,
                                                      o_error          => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            g_error := 'Create suggestions for nursing interventions';
            IF NOT create_assoc_icnp_interv(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_episode         => i_episode_context,
                                            i_id_sr_epis_interv  => l_sr_epis_interv.id_sr_epis_interv,
                                            i_id_sr_intervention => i_sr_intervention,
                                            o_error              => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_SET_EPIS_SURG_INTERV',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_SET_EPIS_SURG_INTERV',
                                              o_error);
        
            RETURN FALSE;
    END call_set_epis_surg_interv;

    /********************************************************************************************
    * Prescrever temporariamente as intervenções cirúrgicas para um episódio. Só ao fazer OK no
    *   ecrã é que elas ficarão activas permanentemente.
    *
    * @param i_lang                 Id do idioma
    * @param i_episode              Id do episódio
    * @param i_episode_context      ID do episódio de contexto, onde a informação poderá ser visível
    * @param i_sr_intervention      Lista de id's da intervenção
    * @param i_prof                 ID do profissional, instituição e software
    * @param o_error                Mensagem de erro
    *
    * @return                       boolean
    *
    * @author                       Gustavo Serrano
    * @since                        2009/09/28
    *
    *********************************************************************************************/

    FUNCTION set_epis_surg_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_prof            IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        internal_error_exception EXCEPTION;
        l_id_sr_epis_interv      sr_epis_interv.id_sr_epis_interv%TYPE;
    
    BEGIN
    
        g_error := 'CALL_SET_EPIS_SURG_INTERV';
        pk_alertlog.log_debug(g_error);
        IF NOT call_set_epis_surg_interv(i_lang              => i_lang,
                                         i_episode           => i_episode,
                                         i_episode_context   => i_episode_context,
                                         i_sr_intervention   => i_sr_intervention,
                                         i_prof              => i_prof,
                                         o_id_sr_epis_interv => l_id_sr_epis_interv,
                                         o_error             => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        g_error := 'CALL CHECK STATUS FOR APPROVAL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_approval.check_status_for_approval(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode_context,
                                                        o_error   => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_surg_interv;

    /********************************************************************************************
    * Prescrever temporariamente as intervenções cirúrgicas para um episódio. Só ao fazer OK no
    *   ecrã é que elas ficarão activas permanentemente.
    *
    * @param i_lang                 Id do idioma
    * @param i_episode              Id do episódio
    * @param i_episode_context      ID do episódio de contexto, onde a informação poderá ser visível
    * @param i_sr_intervention      Lista de id's da intervenção
    * @param i_prof                 ID do profissional, instituição e software
    * @param o_error                Mensagem de erro
    *
    * @return                       boolean
    *
    * @author                       Gustavo Serrano
    * @since                        2009/09/28
    *
    *********************************************************************************************/

    FUNCTION set_epis_surg_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_sr_intervention IN table_number,
        i_prof            IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        internal_error_exception EXCEPTION;
        l_id_sr_epis_interv      sr_epis_interv.id_sr_epis_interv%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN i_sr_intervention.first .. i_sr_intervention.last
        LOOP
            g_error := 'CALL_SET_EPIS_SURG_INTERV - iteration: ' || i;
            pk_alertlog.log_debug(g_error);
            IF NOT call_set_epis_surg_interv(i_lang              => i_lang,
                                             i_episode           => i_episode,
                                             i_episode_context   => i_episode_context,
                                             i_sr_intervention   => i_sr_intervention(i),
                                             i_prof              => i_prof,
                                             o_id_sr_epis_interv => l_id_sr_epis_interv,
                                             o_error             => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
        END LOOP;
    
        g_error := 'CALL set_conf_epis_surg_interv';
        pk_alertlog.log_debug(g_error);
        IF NOT set_conf_epis_surg_interv(i_lang            => i_lang,
                                         i_episode         => i_episode_context,
                                         i_sr_epis_interv  => NULL,
                                         i_sr_intervention => NULL,
                                         i_prof            => i_prof,
                                         o_error           => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        g_error := 'CALL pk_sr_approval.check_status_for_approval';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_approval.check_status_for_approval(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode_context,
                                                        o_error   => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_surg_interv;

    FUNCTION get_first_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN sr_reserv_req%ROWTYPE,
        i_flg_screen IN VARCHAR2,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar
    ) RETURN BOOLEAN IS
        l_reserve_type  VARCHAR2(4000 CHAR);
        l_reserve_equip VARCHAR2(4000 CHAR);
        l_surg_period   VARCHAR2(4000 CHAR);
        l_qty_req       NUMBER(24);
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        SELECT pk_translation.get_translation(i_lang, e.code_equip),
               r.qty_req,
               pk_translation.get_translation(i_lang, sre.code_equip) reserve_type,
               pk_translation.get_translation(i_lang, ssp.code_surg_period) surg_period
          INTO l_reserve_equip, l_qty_req, l_reserve_type, l_surg_period
          FROM sr_reserv_req r, sr_equip e, sr_equip sre, sr_surg_period ssp
         WHERE r.id_sr_reserv_req = i_actual_row.id_sr_reserv_req
           AND e.id_sr_equip = r.id_sr_equip
           AND e.id_sr_equip_parent = sre.id_sr_equip
           AND r.id_surg_period = ssp.id_surg_period;
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status_aux,
                                                                         i_val      => CASE
                                                                                           WHEN i_flg_screen = pk_inp_detail.g_history_h THEN
                                                                                            g_reserv_flg_status_r
                                                                                           ELSE
                                                                                            i_actual_row.flg_status
                                                                                       
                                                                                       END,
                                                                         i_lang     => i_lang),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        --profissional que requisitou
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T004'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                  i_prof,
                                                                                  i_actual_row.id_prof_req),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Request Date
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T005'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                             i_actual_row.dt_req_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Type of Reserve
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T006'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_reserve_type,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Reservation of
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T007'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_reserve_equip,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Qt
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T008'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_qty_req,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Period
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T009'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_surg_period,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Status
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T010'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                         i_val      => CASE
                                                                                           WHEN i_flg_screen = pk_inp_detail.g_history_h THEN
                                                                                            g_reserv_flg_status_r
                                                                                           ELSE
                                                                                            i_actual_row.flg_status
                                                                                       
                                                                                       END,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => i_actual_row.id_episode,
                                                                             i_date                => CASE
                                                                                                          WHEN i_flg_screen = pk_inp_detail.g_detail_d THEN
                                                                                                           coalesce(i_actual_row.dt_exec_tstz,
                                                                                                                    i_actual_row.dt_cancel_tstz,
                                                                                                                    i_actual_row.dt_req_tstz)
                                                                                                          ELSE
                                                                                                           i_actual_row.dt_req_tstz
                                                                                                      END,
                                                                             i_id_prof_last_change => CASE
                                                                                                          WHEN i_flg_screen = pk_inp_detail.g_detail_d THEN
                                                                                                           coalesce(i_actual_row.id_prof_exec,
                                                                                                                    i_actual_row.id_prof_cancel,
                                                                                                                    i_actual_row.id_prof_req
                                                                                                                    
                                                                                                                    )
                                                                                                          ELSE
                                                                                                           i_actual_row.id_prof_req
                                                                                                      END),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        RETURN TRUE;
    END get_first_values;

    FUNCTION get_canceled
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN sr_reserv_req%ROWTYPE,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar
    ) RETURN BOOLEAN IS
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status_aux,
                                                                         i_val      => g_reserv_flg_status_c,
                                                                         i_lang     => i_lang),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        --New state
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T011'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                         i_val      => g_reserv_flg_status_c,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_new_content_n);
    
        --Old state
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T012'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                         i_val      => CASE
                                                                                           WHEN i_actual_row.dt_exec_tstz IS NOT NULL THEN
                                                                                            g_reserv_flg_status_f
                                                                                           ELSE
                                                                                            g_reserv_flg_status_r
                                                                                       END,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        --Canceling Notes
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T013'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => i_actual_row.notes_cancel,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_new_content_n);
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => i_actual_row.id_episode,
                                                                             i_date                => i_actual_row.dt_cancel_tstz,
                                                                             i_id_prof_last_change => i_actual_row.id_prof_cancel),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        RETURN TRUE;
    END get_canceled;

    FUNCTION get_executed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN sr_reserv_req%ROWTYPE,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar
    ) RETURN BOOLEAN IS
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        IF i_actual_row.dt_exec_tstz IS NOT NULL
        THEN
            --title
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status_aux,
                                                                             i_val      => g_reserv_flg_status_f,
                                                                             i_lang     => i_lang),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => NULL,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_title_t);
        
            --New state
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T011'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                             i_val      => g_reserv_flg_status_f,
                                                                             i_lang     => i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            --Old state
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'SR_RESERV_REQ_T012'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                             i_val      => g_reserv_flg_status_r,
                                                                             i_lang     => i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                                 i_prof                => i_prof,
                                                                                 i_id_episode          => i_actual_row.id_episode,
                                                                                 i_date                => i_actual_row.dt_exec_tstz,
                                                                                 i_id_prof_last_change => i_actual_row.id_prof_exec),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_signature_s);
        END IF;
    
        RETURN TRUE;
    END get_executed;

    /********************************************************************************************
    * Shows Reserve Detail
    *
    * @param i_lang             Id of language
    * @param i_prof             ID of professional, institution and software
    * @param i_id_sr_reserv_req ID of reserve
    * @param i_flg_screen       Flag of Detail type (D-detail; H-history)
    * @param o_reserv_req       Cursor with the data
    * @param o_error            Error Message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   António Neto
    * @since                    2011/05/11
    **********************************************************************************************/
    FUNCTION get_reserv_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sr_reserv_req IN sr_reserv_req.id_sr_reserv_req%TYPE,
        i_flg_screen       IN VARCHAR2,
        o_reserv_req       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_reserve_req_data sr_reserv_req%ROWTYPE;
        l_tab_hist         t_table_history_data := t_table_history_data();
    
        l_tbl_labels table_varchar := table_varchar();
        l_tbl_values table_varchar := table_varchar();
        l_tbl_types  table_varchar := table_varchar();
    
        l_info_labels table_varchar;
        l_info_values table_varchar;
    
    BEGIN
    
        g_error := 'GET DATA FROM RESERVE REQ';
        SELECT *
          INTO l_reserve_req_data
          FROM sr_reserv_req srr
         WHERE srr.id_sr_reserv_req = i_id_sr_reserv_req;
    
        l_info_labels := pk_inp_detail.get_info_labels();
        l_info_values := pk_inp_detail.get_info_values(l_reserve_req_data.flg_status);
    
        IF (i_flg_screen = pk_inp_detail.g_history_h)
        THEN
        
            IF l_reserve_req_data.dt_cancel_tstz IS NOT NULL
            THEN
                g_error := 'CALL get_canceled';
                IF NOT get_canceled(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_actual_row => l_reserve_req_data,
                                    o_tbl_labels => l_tbl_labels,
                                    o_tbl_values => l_tbl_values,
                                    o_tbl_types  => l_tbl_types)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_tbl_labels.count > 0
                THEN
                    l_tab_hist.extend;
                    l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_reserve_req_data.id_sr_reserv_req,
                                                                       flg_status      => g_reserv_flg_status_c,
                                                                       date_rec        => NULL,
                                                                       tbl_labels      => l_tbl_labels,
                                                                       tbl_values      => l_tbl_values,
                                                                       tbl_types       => l_tbl_types,
                                                                       tbl_info_labels => l_info_labels,
                                                                       tbl_info_values => l_info_values,
                                                                       table_origin    => NULL);
                END IF;
            END IF;
        
            IF l_reserve_req_data.dt_exec_tstz IS NOT NULL
            THEN
                g_error := 'CALL get_executed';
                pk_alertlog.log_debug(g_error);
                IF NOT get_executed(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_actual_row => l_reserve_req_data,
                                    o_tbl_labels => l_tbl_labels,
                                    o_tbl_values => l_tbl_values,
                                    o_tbl_types  => l_tbl_types)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_tbl_labels.count > 0
                THEN
                    l_tab_hist.extend;
                    l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_reserve_req_data.id_sr_reserv_req,
                                                                       flg_status      => g_reserv_flg_status_f,
                                                                       date_rec        => NULL,
                                                                       tbl_labels      => l_tbl_labels,
                                                                       tbl_values      => l_tbl_values,
                                                                       tbl_types       => l_tbl_types,
                                                                       tbl_info_labels => l_info_labels,
                                                                       tbl_info_values => l_info_values,
                                                                       table_origin    => NULL);
                END IF;
            END IF;
        
        END IF;
    
        g_error := 'CALL get_first_values';
        pk_alertlog.log_debug(g_error);
        IF NOT get_first_values(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_actual_row => l_reserve_req_data,
                                i_flg_screen => i_flg_screen,
                                o_tbl_labels => l_tbl_labels,
                                o_tbl_values => l_tbl_values,
                                o_tbl_types  => l_tbl_types)
        THEN
            RETURN FALSE;
        ELSE
            l_info_labels := pk_inp_detail.get_info_labels();
            l_info_values := table_varchar(CASE
                                               WHEN i_flg_screen = pk_inp_detail.g_history_h THEN
                                                pk_inp_detail.g_det_active_a
                                               ELSE
                                                l_reserve_req_data.flg_status
                                           END);
        END IF;
    
        l_tab_hist.extend;
        l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_reserve_req_data.id_sr_reserv_req,
                                                           flg_status      => CASE
                                                                                  WHEN i_flg_screen = pk_inp_detail.g_history_h THEN
                                                                                   g_reserv_flg_status_r
                                                                                  ELSE
                                                                                   l_reserve_req_data.flg_status
                                                                              END,
                                                           date_rec        => NULL,
                                                           tbl_labels      => l_tbl_labels,
                                                           tbl_values      => l_tbl_values,
                                                           tbl_types       => l_tbl_types,
                                                           tbl_info_labels => l_info_labels,
                                                           tbl_info_values => l_info_values,
                                                           table_origin    => NULL);
    
        g_error := 'OPEN o_data';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'GET_RESERV_DET');
        OPEN o_reserv_req FOR
            SELECT t.id_rec          id_epis_prof_resp,
                   t.tbl_labels      tbl_labels,
                   t.tbl_values      tbl_values,
                   t.tbl_types       tbl_types,
                   t.tbl_info_labels info_labels,
                   t.tbl_info_values info_values
              FROM TABLE(l_tab_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RESERV_DET',
                                              o_error);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Mostra detalhe de cancelamento de uma reserva
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_reserv_req       ID da reserva
    *
    * @param o_reserv           Descrição da reserva cancelada
    * @param o_notes            Notas de cancelamento
    * @param o_prof_cancel      ID do profissional que cancelou
    * @param o_dt_cancel        Data de cancelamento
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/24
    **********************************************************************************************/
    FUNCTION get_reserv_cancel_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_reserv_req  IN sr_reserv_req.id_sr_reserv_req%TYPE,
        o_reserv      OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_prof_cancel OUT VARCHAR2,
        o_dt_cancel   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, e.code_equip),
               r.notes_cancel,
               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) || CASE
                    WHEN pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) IS NOT NULL THEN
                     ' (' || pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ')'
                    ELSE
                     NULL
                END nick_name,
               pk_date_utils.date_char_tsz(i_lang, r.dt_cancel_tstz, i_prof.institution, i_prof.software)
          INTO o_reserv, o_notes, o_prof_cancel, o_dt_cancel
          FROM sr_reserv_req r, sr_equip e, professional p
         WHERE r.id_sr_reserv_req = i_reserv_req
           AND e.id_sr_equip = r.id_sr_equip
           AND p.id_professional = r.id_prof_cancel;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_reserv      := NULL;
            o_notes       := NULL;
            o_prof_cancel := NULL;
            o_dt_cancel   := NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RESERV_CANCEL_DET',
                                              o_error);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Mostra detalhe de cancelamento de um posicionamento
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_posit_req        ID da requisição do posicionamento
    *
    * @param o_posit            Descrição do posicionamento cancelado
    * @param o_notes            Notas de cancelamento
    * @param o_prof_cancel      ID do profissional que cancelou
    * @param o_dt_cancel        Data de cancelamento
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/24
       ********************************************************************************************/

    FUNCTION get_posit_cancel_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_posit_req   IN sr_posit_req.id_sr_posit_req%TYPE,
        o_posit       OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_prof_cancel OUT VARCHAR2,
        o_dt_cancel   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, e.code_sr_posit),
               r.notes_cancel,
               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
               pk_date_utils.date_char_tsz(i_lang, r.dt_cancel_tstz, i_prof.institution, i_prof.software)
          INTO o_posit, o_notes, o_prof_cancel, o_dt_cancel
          FROM sr_posit_req r, sr_posit e, professional p
         WHERE r.id_sr_posit_req = i_posit_req
           AND e.id_sr_posit = r.id_sr_posit
           AND p.id_professional = r.id_prof_cancel;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_posit       := NULL;
            o_notes       := NULL;
            o_prof_cancel := NULL;
            o_dt_cancel   := NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POSIT_CANCEL_DET',
                                              o_error);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Get surgical procedures summary page
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_episode          Id Episode
    *
    * @param o_interv           Data cursor
    * @param o_labels           Labels cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/27
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION get_summ_interv
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        o_interv                    OUT NOCOPY pk_types.cursor_type,
        o_labels                    OUT NOCOPY pk_types.cursor_type,
        o_interv_supplies           OUT NOCOPY pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_call_summ_interv EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL GET_SUMM_INTERV_API';
        pk_alertlog.log_debug(g_error);
        IF NOT get_summ_interv_api(i_lang                      => i_lang,
                                   i_prof                      => i_prof,
                                   i_id_context                => i_episode,
                                   i_flg_type_context          => pk_sr_planning.g_flg_type_context_epis_e,
                                   o_interv                    => o_interv,
                                   o_labels                    => o_labels,
                                   o_interv_supplies           => o_interv_supplies,
                                   o_interv_clinical_questions => o_interv_clinical_questions,
                                   o_error                     => o_error)
        THEN
            RAISE l_call_summ_interv;
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
                                              'GET_SUMM_INTERV',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_labels);
        
            RETURN FALSE;
    END get_summ_interv;

    /**************************************************************************
    * Returns the consent information for a specific ORIS episode             *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *
    *                                                                         *
    * @return                         Returns consent info cursor             *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/08/28                              *
    **************************************************************************/
    FUNCTION get_epis_consent
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_consent       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(200) INDEX BY sys_message.code_message%TYPE;
    
        sr_code_messages t_code_messages;
    
        va_code_messages table_varchar2 := table_varchar2('SR_CONSENT_M001',
                                                          'SR_CONSENT_M002',
                                                          'SR_CONSENT_M003',
                                                          'SR_CONSENT_M004',
                                                          'SR_CONSENT_M005',
                                                          'SR_CONSENT_M006',
                                                          'SR_CONSENT_M008');
    
    BEGIN
        -- get all messages
        pk_alertlog.log_debug(text            => 'Fetching all labels',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_EPIS_CONSENT');
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            sr_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        pk_alertlog.log_debug(text            => 'Fetching cursor o_consent for id_episode: ' || i_episode,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_EPIS_CONSENT');
        g_error := 'OPEN CURSOR';
        OPEN o_consent FOR
            SELECT sr_code_messages('SR_CONSENT_M008') lbl_prof_action,
                   sc.flg_status,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'SR_CONSENT.FLG_STATUS', sc.flg_status, i_dep_clin_serv) desc_flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sc.id_prof_reg) desc_prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, sc.id_prof_reg, sc.dt_reg, ss.id_episode) desc_prof_sig,
                   pk_date_utils.date_char_tsz(i_lang, sc.dt_reg, i_prof.institution, i_prof.software) action_date,
                   sr_code_messages('SR_CONSENT_M001') lbl_physician_sign,
                   sc.flg_physician_sign,
                   pk_sysdomain.get_domain(i_lang,
                                           i_prof,
                                           'SR_CONSENT.FLG_PHYSICIAN_SIGN',
                                           sc.flg_physician_sign,
                                           i_dep_clin_serv) desc_flg_physician_sign,
                   sr_code_messages('SR_CONSENT_M002') lbl_prof_resp,
                   sc.id_prof_resp,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sc.id_prof_resp) desc_prof_resp,
                   sr_code_messages('SR_CONSENT_M003') lbl_patient_sign,
                   sc.flg_patient_sign,
                   pk_sysdomain.get_domain(i_lang,
                                           i_prof,
                                           'SR_CONSENT.FLG_PATIENT_SIGN',
                                           sc.flg_patient_sign,
                                           i_dep_clin_serv) desc_flg_patient_sign,
                   sr_code_messages('SR_CONSENT_M004') lbl_patient_rep_name,
                   sc.patient_rep_name,
                   sr_code_messages('SR_CONSENT_M005') lbl_family_relationship,
                   sc.id_family_relationship,
                   pk_translation.get_translation(i_lang,
                                                  'FAMILY_RELATIONSHIP.CODE_FAMILY_RELATIONSHIP.' ||
                                                  sc.id_family_relationship) desc_family_relationship,
                   sr_code_messages('SR_CONSENT_M006') lbl_consent_dest,
                   sc.flg_consent_dest,
                   pk_sysdomain.get_domain(i_lang,
                                           i_prof,
                                           'SR_CONSENT.FLG_CONSENT_DEST',
                                           sc.flg_consent_dest,
                                           i_dep_clin_serv) desc_flg_consent_dest
              FROM sr_consent sc
              JOIN schedule_sr ss
                ON ss.id_schedule_sr = sc.id_schedule_sr
             WHERE ss.id_episode = i_episode
             ORDER BY sc.id_sr_consent DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_CONSENT',
                                              o_error);
            pk_types.open_my_cursor(o_consent);
        
            RETURN FALSE;
    END get_epis_consent;

    /******************************************************************************
    * Returns the consent options to fill questions                               *
    *                                                                             *
    * @param i_lang                   Language ID                                 *
    * @param i_prof                   Profissional ID                             *
    * @param i_patient                Patient Id                                  *
    * @param i_dep_clin_serv          Dep_clin_serv ID                            *
    *                                                                             *
    * @return o_doctor_sign_cst       Returns doctor sign options cursor          *
    * @return o_doctor_cst_list       Returns doctor list for sign cursor         *
    * @return o_pat_sign_cst          Returns patient sign options cursor         *
    * @return o_pat_family_rel        Returns family relation cursor              *
    * @return o_cst_dest              Returns consent destination options cursor  *
    *                                                                             *
    * @author                         Gustavo Serrano                             *
    * @version                        1.0                                         *
    * @since                          2009/08/28                                  *
    ******************************************************************************/
    FUNCTION get_consent_input_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_doctor_sign_cst OUT pk_types.cursor_type,
        o_doctor_cst_list OUT pk_types.cursor_type,
        o_pat_sign_cst    OUT pk_types.cursor_type,
        o_pat_family_rel  OUT pk_types.cursor_type,
        o_cst_dest        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug(text            => 'Fetch cursor o_doctor_sign_cst',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_CONSENT_INPUT_DATA');
        g_error := 'OPEN o_doctor_sign_cst';
        IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_code_dom      => 'SR_CONSENT.FLG_PHYSICIAN_SIGN',
                                              i_dep_clin_serv => i_dep_clin_serv,
                                              o_data_mkt      => o_doctor_sign_cst,
                                              o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        pk_alertlog.log_debug(text            => 'Fetch cursor o_doctor_cst_list',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_CONSENT_INPUT_DATA');
        g_error := 'OPEN o_doctor_cst_list';
        IF NOT pk_surgery_request.get_surgeons_by_dep_clin_serv(i_lang     => i_lang,
                                                                i_prof     => i_prof,
                                                                i_inst     => i_prof.institution,
                                                                i_id_dcs   => NULL,
                                                                o_surgeons => o_doctor_cst_list,
                                                                o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        pk_alertlog.log_debug(text            => 'Fetch cursor o_pat_sign_cst',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_CONSENT_INPUT_DATA');
        g_error := 'OPEN o_pat_sign_cst';
        IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_code_dom      => 'SR_CONSENT.FLG_PATIENT_SIGN',
                                              i_dep_clin_serv => i_dep_clin_serv,
                                              o_data_mkt      => o_pat_sign_cst,
                                              o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        pk_alertlog.log_debug(text            => 'Fetch cursor o_pat_family_rel',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_CONSENT_INPUT_DATA');
    
        --Removed pk_family.get_family_relationships
        g_error := 'OPEN o_pat_family_rel';
        OPEN o_pat_family_rel FOR
            SELECT *
              FROM (SELECT fr.id_family_relationship id_fr,
                           pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_fr
                      FROM family_relationship fr
                     WHERE fr.flg_available = pk_alert_constant.g_available)
             WHERE desc_fr IS NOT NULL
             ORDER BY desc_fr;
    
        pk_alertlog.log_debug(text            => 'Fetch cursor o_cst_dest',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_CONSENT_INPUT_DATA');
        g_error := 'OPEN o_cst_dest';
        IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_code_dom      => 'SR_CONSENT.FLG_CONSENT_DEST',
                                              i_dep_clin_serv => i_dep_clin_serv,
                                              o_data_mkt      => o_cst_dest,
                                              o_error         => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_CONSENT_INPUT_DATA',
                                              o_error);
        
            pk_types.open_my_cursor(o_doctor_sign_cst);
            pk_types.open_my_cursor(o_doctor_cst_list);
            pk_types.open_my_cursor(o_pat_sign_cst);
            pk_types.open_my_cursor(o_pat_family_rel);
            pk_types.open_my_cursor(o_cst_dest);
        
            RETURN FALSE;
    END get_consent_input_data;

    /**************************************************************************
    * Saves the consent information for a specific ORIS episode               *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    * @param i_flg_physician_sign     Flag physician sign                     *
    * @param i_id_prof_resp           Professional responsible                *
    * @param i_flg_patient_sign       Flag patient sign                       *
    * @param i_patient_rep_name       Patient's representative person name    *
    * @param i_id_family_rel          Patient's representative person relation*
    * @param i_flg_consent_dest       Destination of consent                  *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/08/28                              *
    **************************************************************************/
    FUNCTION set_epis_consent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_physician_sign IN sr_consent.flg_physician_sign%TYPE,
        i_id_prof_resp       IN sr_consent.id_prof_resp%TYPE,
        i_flg_patient_sign   IN sr_consent.flg_patient_sign%TYPE,
        i_patient_rep_name   IN sr_consent.patient_rep_name%TYPE,
        i_id_family_rel      IN sr_consent.id_family_relationship%TYPE,
        i_flg_consent_dest   IN sr_consent.flg_consent_dest%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sr_consent  sr_consent.id_sr_consent%TYPE;
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_alertlog.log_debug(text            => 'Fetching id_schedule_sr for id_episode: ' || i_episode,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'SET_EPIS_CONSENT');
        g_error := 'FETCH id_schedule_sr';
        SELECT id_schedule_sr
          INTO l_id_schedule_sr
          FROM (SELECT ss.id_schedule_sr, rank() over(ORDER BY ss.id_schedule_sr DESC) rank
                  FROM schedule_sr ss
                 WHERE ss.id_episode = i_episode
                   AND ss.flg_status IN ('A', 'I'))
         WHERE rank = 1;
    
        pk_alertlog.log_debug(text            => 'Set sr_consent obsolete for id_schedule_sr: ' || l_id_schedule_sr,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'SET_EPIS_CONSENT');
        g_error := 'SET id_schedule_sr inactive';
        UPDATE sr_consent sc
           SET sc.flg_status = 'O'
         WHERE sc.id_schedule_sr = l_id_schedule_sr;
    
        pk_alertlog.log_debug(text            => 'Insert data into SR_CONSENT',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'SET_EPIS_CONSENT');
        g_error := 'INSERT data into SR_CONSENT';
        INSERT INTO sr_consent
            (id_sr_consent,
             id_schedule_sr,
             flg_physician_sign,
             id_prof_resp,
             flg_patient_sign,
             patient_rep_name,
             id_family_relationship,
             flg_consent_dest,
             flg_status,
             id_prof_reg,
             dt_reg)
        VALUES
            (seq_sr_consent.nextval,
             l_id_schedule_sr,
             i_flg_physician_sign,
             i_id_prof_resp,
             i_flg_patient_sign,
             i_patient_rep_name,
             i_id_family_rel,
             i_flg_consent_dest,
             'A',
             i_prof.id,
             g_sysdate_tstz)
        RETURNING id_sr_consent INTO l_id_sr_consent;
    
        pk_alertlog.log_debug(text            => 'Inserted data into SR_CONSENT with id_sr_consent: ' ||
                                                 l_id_sr_consent,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'SET_EPIS_CONSENT');
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_CONSENT',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_consent;

    /**************************************************************************
    * Get surgery detail for a specific episode                               *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    * @param o_epis_doc_register      array with the detail info register     *
    * @param o_epis_document_val      array with detail of documentation      *
    * @param o_surgical_episode       cursor with information of cancel       *
    *                                 surgical episode                        *
    * @param o_error                  Error message                           *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @since                          2009/09/14                              *
    **************************************************************************/

    FUNCTION get_surgery_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_cancel_surg_epis  OUT pk_types.cursor_type,
        o_null_surg_epis    OUT pk_types.cursor_type,
        o_surg_epis         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        err_exception EXCEPTION;
    
        l_epis_documentation table_number;
    
        CURSOR c_get_recs IS
            SELECT CAST(COLLECT(to_number(p.id_epis_documentation)) AS table_number)
              FROM (SELECT ep.id_doc_area, ep.dt_creation_tstz, ep.id_epis_documentation
                      FROM epis_documentation ep
                     WHERE ep.id_episode_context = i_episode
                       AND ep.flg_status = g_active
                       AND ep.id_doc_area IN
                           (SELECT *
                              FROM TABLE(pk_utils.str_split_c(pk_sysconfig.get_config('SR_DOC_AREA_LIST', 0, 0), ',')))
                     ORDER BY id_doc_area DESC, ep.dt_creation_tstz DESC) p;
    
    BEGIN
    
        pk_alertlog.log_debug(text            => 'Open cursor c_get_recs',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_SURGERY_DETAIL');
    
        g_error := 'OPEN C_GET_RECS';
        OPEN c_get_recs;
        FETCH c_get_recs
            INTO l_epis_documentation;
        CLOSE c_get_recs;
    
        pk_alertlog.log_debug(text            => 'Call to pk_touch_option.get_epis_documentation_det',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_SURGERY_DETAIL');
    
        IF NOT pk_touch_option.get_epis_documentation_det(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_epis_document     => l_epis_documentation,
                                                          o_epis_doc_register => o_epis_doc_register,
                                                          o_epis_document_val => o_epis_document_val,
                                                          o_error             => o_error)
        THEN
            RAISE err_exception;
        END IF;
    
        pk_alertlog.log_debug(text            => 'Open cursor o_surgical_episode',
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'GET_SURGERY_DETAIL');
    
        g_error := 'OPEN O_SURGICAL_EPISODE';
        OPEN o_cancel_surg_epis FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) || --
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, ss.create_time, ss.id_episode) prof_desc,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ss.id_episode, i_prof, pk_alert_constant.g_no) desc_interv,
                   pk_message.get_message(i_lang, 'SR_LABEL_T360') desc_interv_new,
                   pk_date_utils.date_char_tsz(i_lang, ss.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   pk_message.get_message(i_lang, 'SR_SPCANCEL_M002') cancel_reason_title,
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason_desc,
                   pk_message.get_message(i_lang, 'SR_SPCANCEL_M003') notes_cancel_title,
                   ss.notes_cancel notes_cancel,
                   pk_message.get_message(i_lang,
                                          decode(ss.flg_status,
                                                 g_active,
                                                 'SR_LABEL_T054',
                                                 decode(ss.flg_status, g_cancel, 'SR_LABEL_T345', NULL))) status_desc
              FROM schedule_sr ss, professional p, episode e, cancel_reason cr
             WHERE ss.id_episode = i_episode
               AND p.id_professional = ss.id_prof_cancel
               AND ss.flg_status = g_cancel
               AND e.id_episode = ss.id_episode
               AND e.flg_status = ss.flg_status
               AND ss.id_sr_cancel_reason = cr.id_cancel_reason;
    
        g_error := 'Call pk_sr_approval.get_approval_process_resume';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_approval.get_approval_proc_resume_det(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_epis            => i_episode,
                                                           i_approval_type   => pk_sr_approval.g_appr_type_oris,
                                                           o_approval_resume => o_surg_epis,
                                                           o_error           => o_error)
        THEN
            RAISE err_exception;
        END IF;
    
        g_error := 'open cursor o_null_surg_epis';
        pk_alertlog.log_debug(g_error);
        OPEN o_null_surg_epis FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ss.id_prof_reg) prof_name,
                   pk_date_utils.date_char_tsz(i_lang, e.dt_creation, i_prof.institution, i_prof.software) dt_action,
                   pk_message.get_message(i_lang, 'SR_LABEL_T215') desc_action
              FROM sr_surgery_record ssr
              JOIN schedule_sr ss
                ON ssr.id_schedule_sr = ss.id_schedule_sr
              JOIN episode e
                ON e.id_episode = ss.id_episode
             WHERE ssr.id_episode = i_episode;
    
        pk_types.open_cursor_if_closed(o_epis_doc_register);
        pk_types.open_cursor_if_closed(o_epis_document_val);
        pk_types.open_cursor_if_closed(o_cancel_surg_epis);
        pk_types.open_cursor_if_closed(o_null_surg_epis);
        pk_types.open_cursor_if_closed(o_surg_epis);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURGERY_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_epis_doc_register);
            pk_types.open_my_cursor(o_epis_document_val);
            pk_types.open_my_cursor(o_cancel_surg_epis);
            pk_types.open_my_cursor(o_null_surg_epis);
            pk_types.open_my_cursor(o_surg_epis);
        
            RETURN FALSE;
        
    END get_surgery_detail;

    /*********************************************************************************
    * check if the data record meet or not the requirements for the                  *
    * surgical procedures                                                            *
    *                                                                                *
    * @param i_lang                   Language ID                                    *
    * @param i_prof                   Profissional ID                                *
    * @param i_list_in                Internals names list                           *
    * @param i_episode                ORIS episode                                   *
    *                                                                                * 
    * @param o_flg_show              (Y) return alert message/(N)no return alert msg *                                      
    * @param o_msg                    message                                        *
    * @param o_msg_title              message title                                  *
    * @param o_button                                                                *
    * @param o_error                  error message                                  *
    *                                                                                *               
    * @return                         Returns boolean                                *
    *                                                                                *
    * @author                         Filipe Silva                                   *
    * @version                        1.0                                            *
    * @since                          2009/09/09                                     *
    *********************************************************************************/
    FUNCTION check_surgery_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_group      IN sr_surgery_validation.flg_group%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_internal_names OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_element_values       pk_types.cursor_type;
        l_final_element_values table_varchar := table_varchar();
        l_final_list           table_varchar := table_varchar();
        l_last_epis_doc        epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc   epis_documentation.dt_creation_tstz%TYPE;
    
        r_doc pk_touch_option.t_coll_last_elem_val;
    
        l_counter           NUMBER := 1;
        l_cont_final_values NUMBER;
        l_cont_final_list   NUMBER;
    
        err_exception EXCEPTION;
    
        CURSOR c_get_flg_group IS
            SELECT id_doc_area, CAST(COLLECT(internal_name) AS table_varchar) list_in
              FROM (SELECT sv.internal_name,
                           sv.value,
                           sv.target_table,
                           sv.target_column,
                           sv.where_clause,
                           sv.flg_type,
                           sv.id_doc_area,
                           rank() over(PARTITION BY sv.internal_name ORDER BY sv.id_institution DESC, sv.id_software DESC) origin_rank
                      FROM sr_surgery_validation sv
                     WHERE sv.flg_group = i_flg_group
                       AND sv.flg_available = pk_alert_constant.g_yes
                       AND sv.id_institution IN (0, i_prof.institution)
                       AND sv.id_software IN (0, i_prof.software)
                       AND instr(sv.flg_type, pk_sr_documentation.g_flg_type_val) > 0)
             WHERE origin_rank = 1
             GROUP BY id_doc_area;
    
    BEGIN
    
        pk_alertlog.log_debug(text            => 'Get the last elements values for i_episode: ' || i_episode,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'CHECK_SURGERY_TYPE');
    
        DELETE FROM tbl_temp;
    
        g_error := 'LOOP C_GET_FLG_GROUP';
        pk_alertlog.log_debug(g_error);
        FOR c IN c_get_flg_group
        LOOP
            g_error := 'pk_touch_option.get_last_doc_area_elem_values';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.get_last_doc_area_elem_values(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_episode            => i_episode,
                                                                 i_doc_area           => c.id_doc_area,
                                                                 i_doc_template       => NULL,
                                                                 i_table_element_keys => c.list_in,
                                                                 i_key_type           => 'N',
                                                                 o_last_epis_doc      => l_last_epis_doc,
                                                                 o_last_date_epis_doc => l_last_date_epis_doc,
                                                                 o_element_values     => l_element_values,
                                                                 o_error              => o_error)
            
            THEN
                RAISE err_exception;
            END IF;
        
            g_error := 'Insert into tbl_temp';
            pk_alertlog.log_debug(g_error);
            insert_tbl_temp(i_num_1 => table_number(l_last_epis_doc));
        
            pk_alertlog.log_debug(text            => 'pk_touch_option.get_last_doc_area_elem_values returned last id_epis_documentation: ' ||
                                                     l_last_epis_doc,
                                  object_name     => 'PK_SR_PLANNING',
                                  sub_object_name => 'CHECK_SURGERY_TYPE');
            IF l_last_epis_doc IS NULL
            THEN
                o_flg_show := pk_alert_constant.g_no;
                RETURN TRUE;
            END IF;
        
            SELECT CAST(COLLECT(column_value) AS table_varchar)
              INTO l_final_list
              FROM (SELECT column_value
                      FROM TABLE(l_final_list)
                    UNION ALL
                    SELECT column_value
                      FROM TABLE(c.list_in));
        
            g_error := 'Fetch l_element_values';
            pk_alertlog.log_debug(g_error);
            FETCH l_element_values BULK COLLECT
                INTO r_doc;
            CLOSE l_element_values;
        
            g_error := 'Process l_element_values';
            pk_alertlog.log_debug(g_error);
            LOOP
                EXIT WHEN NOT r_doc.exists(l_counter);
                l_final_element_values.extend;
                l_final_element_values(l_counter) := r_doc(l_counter).internal_name;
                l_counter := l_counter + 1;
            
            END LOOP;
        END LOOP;
    
        -- 
        l_cont_final_values := l_final_element_values.count;
        l_cont_final_list   := l_final_list.count;
    
        IF l_cont_final_values = l_cont_final_list
        THEN
            o_flg_show := pk_alert_constant.g_no;
        ELSE
            pk_alertlog.log_debug(text            => 'Get the internal names : ' || chr(10) || 'l_final_list: ' ||
                                                     pk_utils.to_string(l_final_list) || chr(10) ||
                                                     'l_final_element_values: ' ||
                                                     pk_utils.to_string(l_final_element_values),
                                  object_name     => 'PK_SR_PLANNING',
                                  sub_object_name => 'CHECK_SURGERY_TYPE');
            g_error := 'OPEN o_internal_names';
            pk_alertlog.log_debug(g_error);
            OPEN o_internal_names FOR
            --                SELECT doc_template || ' - ' || questions || ': ' || internal_names
                SELECT decode(origin_rank, 1, chr(10) || '<B>' || doc_template || ':</B>' || chr(10), '') ||
                       answer_given
                  FROM (SELECT pk_translation.get_translation(i_lang,
                                                              'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || ed.id_doc_template) doc_template,
                               pk_translation.get_translation(i_lang,
                                                              'DOC_COMPONENT.CODE_DOC_COMPONENT.' || d.id_doc_component) questions,
                               pk_translation.get_translation(i_lang, decr.code_element_close) internal_names,
                               pk_touch_option.get_epis_doc_component_desc(i_lang,
                                                                           i_prof,
                                                                           ed.id_epis_documentation,
                                                                           d.id_doc_component) answer_given,
                               rank() over(PARTITION BY dtad.id_doc_template ORDER BY dtad.rank) origin_rank
                          FROM doc_element de
                         INNER JOIN doc_element_crit decr
                            ON decr.id_doc_element = de.id_doc_element
                         INNER JOIN documentation d
                            ON d.id_documentation = de.id_documentation
                         INNER JOIN doc_template_area_doc dtad
                            ON dtad.id_documentation = d.id_documentation
                         INNER JOIN epis_documentation ed
                            ON ed.id_doc_template = dtad.id_doc_template
                           AND ed.id_doc_area = dtad.id_doc_area
                         WHERE de.internal_name IN (SELECT /*+ opt_estimate(table t rows=20)*/
                                                     t.column_value
                                                      FROM TABLE(l_final_list) t
                                                    MINUS
                                                    SELECT /*+ opt_estimate(table t rows=20)*/
                                                     t.column_value
                                                      FROM TABLE(l_final_element_values) t)
                           AND ed.id_epis_documentation IN (SELECT num_1
                                                              FROM tbl_temp)
                         ORDER BY dtad.id_doc_template, dtad.rank)
                 WHERE internal_names IS NOT NULL;
        
            o_flg_show := pk_alert_constant.g_yes;
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
                                              'CHECK_SURGERY_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_internal_names);
            RETURN FALSE;
    END check_surgery_type;

    /**************************************************************************
    * Cancels the consent information for a specific ORIS episode             *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/21                              *
    **************************************************************************/
    FUNCTION cancel_consent_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_alertlog.log_debug(text            => 'Fetching id_schedule_sr for id_episode: ' || i_episode,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'CANCEL_CONSENT_INFO');
        g_error := 'FETCH id_schedule_sr';
        SELECT id_schedule_sr
          INTO l_id_schedule_sr
          FROM (SELECT ss.id_schedule_sr, rank() over(ORDER BY ss.id_schedule_sr DESC) rank
                  FROM schedule_sr ss
                 WHERE ss.id_episode = i_episode
                   AND ss.flg_status IN
                       (pk_alert_constant.g_schedule_sr_status_a, pk_alert_constant.g_schedule_sr_status_i))
         WHERE rank = 1;
    
        pk_alertlog.log_debug(text            => 'Set sr_consent cancelled for id_schedule_sr: ' || l_id_schedule_sr,
                              object_name     => 'PK_SR_PLANNING',
                              sub_object_name => 'CANCEL_CONSENT_INFO');
        g_error := 'SET id_sr_consent inactive';
        UPDATE sr_consent sc
           SET sc.flg_status = g_sr_consent_status_i
         WHERE sc.id_schedule_sr = l_id_schedule_sr;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_CONSENT_INFO',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_consent_info;

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status Y/N  N: not proceed with nursing intervention
    *                        
    * @author                        António Neto
    * @version                       v2.6.0.5
    * @since                         03-Mar-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    ) IS
    
    BEGIN
    
        g_error := 'i_id_request:' || i_id_request;
        SELECT pk_translation.get_translation(i_lang, si.code_intervention) || ' / ' || to_char(ic.standard_code) ||
               decode(sei.laterality,
                      NULL,
                      '',
                      ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) || ')'),
               NULL,
               decode(sei.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO o_description, o_instructions, o_flg_status
          FROM sr_epis_interv sei
         INNER JOIN intervention si
            ON si.id_intervention = sei.id_sr_intervention
         INNER JOIN interv_codification ic
            ON ic.id_intervention = si.id_intervention
         WHERE sei.id_sr_epis_interv = i_id_request;
    
    END get_therapeutic_status;

    /********************************************************************************************
    * Saves an interventiont description without committing
    *
    * @param i_lang                     Language ID
    * @param i_episode                  Episode ID
    * @param i_episode_context          Context episode ID
    * @param i_sr_epis_interv           Refers to the surgical procedure it can thus refer to either an coded or uncoded one
    * @param i_prof                     Professional object
    * @param i_notes                    Intervention notes
    *
    * @param o_id_sr_epis_interv_desc   Created record ID
    * @param o_error                    Returned error
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sergio Dias
    * @since                    2010/09/14
    *********************************************************************************************/

    FUNCTION set_surg_proc_desc_no_commit
    (
        i_lang                   IN language.id_language%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_episode_context        IN episode.id_episode%TYPE,
        i_sr_epis_interv         IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_prof                   IN profissional,
        i_notes                  IN VARCHAR2,
        i_dt_interv_desc         IN VARCHAR2 DEFAULT NULL,
        o_id_sr_epis_interv_desc OUT sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_interv_desc sr_epis_interv_desc%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SET REG DATA';
        pk_alertlog.log_debug(g_error);
        --Preenche dados do registo a inserir
        l_epis_interv_desc             := NULL;
        l_epis_interv_desc.desc_interv := i_notes;
        l_epis_interv_desc.id_episode  := i_episode;
        --l_epis_interv_desc.id_sr_intervention  := i_sr_intervention;
        l_epis_interv_desc.id_sr_epis_interv   := i_sr_epis_interv;
        l_epis_interv_desc.flg_status          := g_active;
        l_epis_interv_desc.dt_interv_desc_tstz := nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                    i_prof,
                                                                                    i_dt_interv_desc,
                                                                                    NULL),
                                                      g_sysdate_tstz);
        l_epis_interv_desc.id_professional     := i_prof.id;
        l_epis_interv_desc.flg_type            := g_surg_flg_type;
        l_epis_interv_desc.id_episode_context  := nvl(i_episode_context, i_episode);
    
        --Insere notas
        g_error := 'INSERT SR_EPIS_INTERV_DESC';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.insert_sr_epis_interv_desc(i_lang                   => i_lang,
                                                       i_epis_interv_desc       => l_epis_interv_desc,
                                                       o_id_sr_epis_interv_desc => o_id_sr_epis_interv_desc,
                                                       o_error                  => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURG_PROC_DESC_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        END IF;
    
        --Actualiza data da última interacção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURG_PROC_DESC_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_SURG_PROC_DESC_NO_COMMIT',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURG_PROC_DESC_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END set_surg_proc_desc_no_commit;

    /********************************************************************************************
    * Register one or more uncoded surgical procedures inserted through text field without committing
    *
    * @param i_lang                Language ID
    * @param i_id_episode          Episode ID
    * @param i_id_episode_context  Episode ID Context where data may be available
    * @param i_name_interv         Array with all the uncoded surgical procedures to be inserted
    * @param i_prof                Professional ID, Institution ID AND Software ID
    * @param i_id_patient          Patient ID
    * @param i_notes               Notes
    * @param i_dt_interv_start     Intervention start date
    * @param i_dt_interv_end       Intervention end date
    * @param i_dt_req              Intervention request date
    * @param i_id_epis_diagnosis   Epis diagnosis ID
    * @param o_id_sr_epis_interv   Created record ID
    * @param o_error            Error Message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Pedro Santos
    * @version                  2.5 sp3
    * @since                    2009/03/03
    ********************************************************************************************/

    FUNCTION set_epis_surg_unc_no_commit
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_episode_context      IN episode.id_episode%TYPE,
        i_name_interv             IN table_varchar,
        i_prof                    IN profissional,
        i_id_patient              IN patient.id_patient%TYPE,
        i_notes                   IN VARCHAR2,
        i_dt_interv_start         IN VARCHAR2 DEFAULT NULL,
        i_dt_interv_end           IN VARCHAR2 DEFAULT NULL,
        i_dt_req                  IN VARCHAR2,
        i_id_epis_diagnosis       IN sr_epis_interv.id_epis_diagnosis%TYPE,
        i_flg_type                IN sr_epis_interv.flg_type%TYPE,
        i_laterality              IN sr_epis_interv.laterality%TYPE,
        i_surgical_site           IN sr_epis_interv.surgical_site%TYPE,
        i_id_not_order_reason     IN not_order_reason.id_not_order_reason%TYPE,
        i_clinical_question       IN table_number DEFAULT NULL,
        i_response                IN table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_clob DEFAULT NULL,
        o_id_sr_epis_interv       OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_epis_interv         sr_epis_interv%ROWTYPE;
        internal_error_exception EXCEPTION;
        l_dt_interv_start        sr_epis_interv.dt_interv_start_tstz%TYPE;
        l_dt_interv_end          sr_epis_interv.dt_interv_end_tstz %TYPE;
        l_dt_req                 sr_epis_interv.dt_req_tstz%TYPE;
    
    BEGIN
    
        g_sysdate_tstz    := current_timestamp;
        l_dt_interv_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_interv_start, NULL);
        l_dt_interv_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_interv_end, NULL);
        l_dt_req          := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_req, NULL);
    
        FOR i IN 1 .. i_name_interv.count
        LOOP
            --Insertion of uncoded procedures
            g_error          := 'INSERT UNCODED INTO SR_EPIS_INTERV';
            l_sr_epis_interv := NULL;
        
            SELECT seq_sr_epis_interv.nextval
              INTO l_sr_epis_interv.id_sr_epis_interv
              FROM dual;
        
            o_id_sr_epis_interv := l_sr_epis_interv.id_sr_epis_interv;
        
            l_sr_epis_interv.id_episode           := i_id_episode;
            l_sr_epis_interv.id_prof_req          := i_prof.id;
            l_sr_epis_interv.flg_type             := i_flg_type;
            l_sr_epis_interv.flg_status := CASE
                                               WHEN i_id_not_order_reason IS NOT NULL THEN
                                                g_sei_flg_status_n
                                               ELSE
                                                g_interv_req -- procedimentos não codificados inseridos como 'R'
                                           END;
            l_sr_epis_interv.dt_req_tstz          := nvl(l_dt_req, g_sysdate_tstz);
            l_sr_epis_interv.id_episode_context   := nvl(i_id_episode_context, i_id_episode);
            l_sr_epis_interv.name_interv          := i_name_interv(i);
            l_sr_epis_interv.id_prof_req_unc      := i_prof.id;
            l_sr_epis_interv.dt_req_unc_tstz      := g_sysdate_tstz;
            l_sr_epis_interv.flg_code_type        := g_flg_code_type_u;
            l_sr_epis_interv.dt_interv_start_tstz := l_dt_interv_start;
            l_sr_epis_interv.dt_interv_end_tstz   := l_dt_interv_end;
            l_sr_epis_interv.notes                := i_notes;
            l_sr_epis_interv.id_epis_diagnosis    := i_id_epis_diagnosis;
            l_sr_epis_interv.laterality           := i_laterality;
            l_sr_epis_interv.surgical_site        := i_surgical_site;
            l_sr_epis_interv.id_not_order_reason  := i_id_not_order_reason;
        
            g_error := 'call pk_sr_output.insert_sr_epis_interv for id_episode: ' ||
                       l_sr_epis_interv.id_episode_context;
            IF NOT pk_sr_output.insert_sr_epis_interv(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_sr_epis_interv => l_sr_epis_interv,
                                                      o_error          => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            g_error := 'CALL set_conf_epis_surg_interv';
            IF NOT set_conf_epis_surg_interv(i_lang            => i_lang,
                                             i_episode         => nvl(i_id_episode_context, i_id_episode),
                                             i_sr_epis_interv  => o_id_sr_epis_interv,
                                             i_sr_intervention => NULL,
                                             i_prof            => i_prof,
                                             o_error           => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            IF i_clinical_question.count != 0
            THEN
                FOR i IN 1 .. i_clinical_question.count
                LOOP
                    IF i_clinical_question(i) IS NOT NULL
                    THEN
                        g_error := 'INSERT INTO INTERV_QUESTION_RESPONSE';
                        INSERT INTO sr_interv_quest_response
                            (id_sr_interv_quest_response,
                             id_episode,
                             id_sr_epis_interv,
                             flg_time,
                             id_questionnaire,
                             id_response,
                             notes,
                             id_prof_last_update,
                             dt_last_update_tstz)
                        VALUES
                            (seq_interv_question_response.nextval,
                             i_id_episode,
                             o_id_sr_epis_interv,
                             pk_procedures_constant.g_interv_cq_on_order,
                             i_clinical_question(i),
                             i_response(i),
                             i_clinical_question_notes(i),
                             i_prof.id,
                             g_sysdate_tstz);
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        g_error := 'CALL PK_SR_APPROVAL.CHECK_STATUS_FOR_APPROVAL FOR ID_EPISODE: ' || i_id_episode_context;
        IF NOT pk_sr_approval.check_status_for_approval(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_id_episode_context,
                                                        o_error   => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_SURG_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_surg_unc_no_commit;

    /**************************************************************************
    * Returns list of surgical procedures for an ORIS episode                 
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             ORIS episode                            
    * @param i_id_sr_intervention     Table number with interventions ids     
    * @param i_flg_uncoded            flag to show coded and uncoded surgical procedure
    *
    * @param o_epis_surg_proc         Cursor with surgical procedures info
    * @param o_supplies_surg_proc     Cursor with default supplies 
    * @param o_error                  Error
    *                                                                        
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/20                              
    **************************************************************************/
    FUNCTION get_grid_epis_surg_proc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_sr_intervention IN table_number,
        i_flg_uncoded        IN VARCHAR2,
        o_epis_surg_proc     OUT pk_types.cursor_type,
        o_supplies_surg_proc OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_GRID_EPIS_SURG_PROC';
        l_excep     EXCEPTION;
    
        l_id_context table_varchar;
    
    BEGIN
    
        g_error := 'OPEN O_EPIS_SURG_PROC';
        pk_alertlog.log_debug(g_error);
        OPEN o_epis_surg_proc FOR
            SELECT sei.id_sr_epis_interv id_sr_epis_interv,
                   sei.id_sr_intervention id_sr_intervention,
                   sei.flg_type,
                   pk_sysdomain.get_domain('SR_EPIS_INTERV.FLG_TYPE', sei.flg_type, i_lang) desc_type,
                   CASE
                        WHEN sei.flg_code_type = g_flg_code_type_u THEN
                         sei.name_interv
                        ELSE
                         pk_translation.get_translation(i_lang,
                                                        'INTERVENTION.CODE_INTERVENTION.' || sei.id_sr_intervention)
                    END desc_intervention,
                   ed.id_diagnosis id_diag,
                   pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_diagnosis       => d.id_diagnosis,
                                              i_id_alert_diagnosis => ed.id_alert_diagnosis,
                                              i_code_diagnosis     => ad.code_alert_diagnosis,
                                              i_id_task_type       => pk_alert_constant.g_task_surgical_history,
                                              i_code               => d.code_icd,
                                              i_flg_other          => d.flg_other,
                                              i_flg_std_diag       => pk_alert_constant.g_yes) desc_diag,
                   sei.laterality,
                   pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) desc_lat,
                   pk_supplies_external_api_db.get_context_supplies_str(i_lang,
                                                                        i_prof,
                                                                        sei.id_sr_epis_interv,
                                                                        pk_supplies_constant.g_context_surgery,
                                                                        pk_supplies_constant.g_cancel_sup_status) desc_supplies,
                   sei.notes notes,
                   (SELECT desc_interv
                      FROM sr_epis_interv_desc seid
                     WHERE seid.flg_type = pk_sr_planning.g_surg_interv
                       AND seid.flg_status != pk_sr_planning.g_interv_can
                       AND seid.id_sr_epis_interv_desc =
                           (SELECT MAX(seid2.id_sr_epis_interv_desc)
                              FROM sr_epis_interv_desc seid2
                             WHERE seid2.id_episode = sei.id_episode
                               AND seid2.id_sr_epis_interv = sei.id_sr_epis_interv)) desc_notes,
                   1 rank,
                   pk_sr_tools.get_sr_interv_team(i_lang, i_prof, sei.id_episode_context, sei.id_sr_epis_interv) team,
                   pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, sei.id_sr_epis_interv) desc_team,
                   ed.id_alert_diagnosis,
                   ed.id_epis_diagnosis,
                   pk_not_order_reason_db.get_not_order_reason_id(i_lang                => i_lang,
                                                                  i_id_not_order_reason => sei.id_not_order_reason) id_not_order_reason,
                   pk_not_order_reason_db.get_not_order_reason_desc(i_lang             => i_lang,
                                                                    i_not_order_reason => sei.id_not_order_reason) desc_not_order_reason
              FROM sr_epis_interv sei
              LEFT JOIN epis_diagnosis ed
                ON sei.id_epis_diagnosis = ed.id_epis_diagnosis
              LEFT JOIN diagnosis d
                ON d.id_diagnosis = ed.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON ad.id_diagnosis = ed.id_diagnosis
               AND ad.id_alert_diagnosis = ed.id_alert_diagnosis
             WHERE sei.id_episode_context = i_id_episode
               AND sei.flg_status <> pk_sr_planning.g_cancel
               AND (i_flg_uncoded = pk_alert_constant.g_yes AND
                   sei.flg_code_type IN (g_flg_code_type_c, g_flg_code_type_u))
            UNION ALL
            SELECT NULL id_sr_epis_interv,
                   t.id_sr_intervention id_sr_intervention,
                   NULL flg_type,
                   NULL desc_type,
                   pk_translation.get_translation(i_lang,
                                                  'SR_INTERVENTION.CODE_SR_INTERVENTION.' || t.id_sr_intervention) desc_intervention,
                   NULL id_diag,
                   NULL desc_diag,
                   NULL laterality,
                   NULL desc_lat,
                   NULL desc_supplies,
                   NULL notes,
                   NULL desc_notes,
                   0 rank,
                   NULL team,
                   NULL desc_team,
                   NULL id_alert_diagnosis,
                   NULL id_epis_diagnosis,
                   NULL id_not_order_reason,
                   NULL desc_not_order_reason
              FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                     column_value AS id_sr_intervention
                      FROM TABLE(i_id_sr_intervention)) t
             ORDER BY rank, desc_intervention;
    
        SELECT CAST(t.column_value AS VARCHAR2(100))
          BULK COLLECT
          INTO l_id_context
          FROM TABLE(i_id_sr_intervention) t;
    
        g_error := 'CALL PK_SUPPLIES_API_DB.GET_SUPPLIES_BY_CONTEXT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_supplies_api_db.get_supplies_by_context(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_id_context  => l_id_context,
                                                          i_flg_context => pk_supplies_constant.g_context_surgery,
                                                          o_supplies    => o_supplies_surg_proc,
                                                          o_error       => o_error)
        THEN
            RAISE l_excep;
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
            pk_types.open_my_cursor(o_epis_surg_proc);
            pk_types.open_my_cursor(o_supplies_surg_proc);
            RETURN FALSE;
        
    END get_grid_epis_surg_proc;

    /**************************************************************************
    * Save or update information of surgical procedures (coded and uncoded),  
    * supplies and diagnoses associated with this surgical procedure          
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID                              
    * @param i_id_episode context     ORIS episode ID                         
    * @param i_id_sr_epis_interv      Table number with id_sr_epis_interv     
    * @param i_id_sr_intervention     Table number with interventions ID      
    * @param i_name_interv            Table varchar with names of uncoded surgical procedures
    * @param i_notes_sp               Table varchar with surgical procedures' notes
    * @param i_description_sp         Table varchar with surgical procedures' description
    * @param i_laterality             Table varchar with laterality code
    * @param i_id_diagnosis           Table number with diagnosis id
    * @param i_sp_diag_status         Table varchar of diagnosis status
    * @param i_sp_spec_notes          Table varchar of diagnosis specific notes
    * @param i_sp_diag_notes          Table varchar of diagnosis general notes
    * @param i_supply                 Supply ID
    * @param i_supply_set             Parent supply set (if applicable)
    * @param i_supply_qty             Supply quantity
    * @param i_supply_loc             Supply location
    * @param i_dt_return              Estimated date of of return
    * @param i_supply_soft_inst       list
    * @param i_flg_cons_type          flag of consumption type
    * @param i_id_req_reason          Reasons for each supply
    * @param i_notes                  Request notes
    * @param i_flg_add_problem        The surgical procedure's diagnosis should be associated with problems list?
    * @param i_diagnosis_surg_proc    Diagnosis information in from the diagnosis of the surgical procedures
    * @param i_id_cdr_call           Rule event identifier.
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/23                              
    **************************************************************************/

    FUNCTION set_epis_surgical_procedures
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_episode_context IN episode.id_episode%TYPE,
        --surgical procedures 
        i_id_sr_epis_interv  IN table_number, --5
        i_id_sr_intervention IN table_number,
        i_name_interv        IN table_varchar,
        i_notes_sp           IN table_varchar,
        i_description_sp     IN table_varchar,
        i_flg_type           IN table_varchar, --10
        i_codification       IN table_number,
        i_laterality         IN table_varchar,
        i_surgical_site      IN table_varchar,
        --supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number, --15
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar, --20
        i_id_req_reason    IN table_table_number,
        i_notes            IN table_table_varchar,
        -- team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number,
        i_tbl_prof       IN table_table_number, --25
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar,
        i_test           IN VARCHAR2,
        -- diagnoses
        i_diagnosis_surg_proc IN table_clob,
        -- clinical decision rules
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE,
        i_id_not_order_reason_ea  IN table_number, --30
        i_id_ct_io                IN table_table_varchar,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_clob,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'SET_EPIS_SURGICAL_PROCEDURES';
        l_rowids    table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL PK_SR_PLANNING.SET_EPIS_SURG_PROC_NOCOMMIT ';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.set_epis_surg_proc_nocommit(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_id_episode              => i_id_episode,
                                                          i_id_episode_context      => i_id_episode_context,
                                                          i_id_sr_epis_interv       => i_id_sr_epis_interv,
                                                          i_id_sr_intervention      => i_id_sr_intervention,
                                                          i_name_interv             => i_name_interv,
                                                          i_notes_sp                => i_notes_sp,
                                                          i_description_sp          => i_description_sp,
                                                          i_flg_type                => i_flg_type,
                                                          i_codification            => i_codification,
                                                          i_laterality              => i_laterality,
                                                          i_surgical_site           => i_surgical_site,
                                                          i_supply                  => i_supply,
                                                          i_supply_set              => i_supply_set,
                                                          i_supply_qty              => i_supply_qty,
                                                          i_supply_loc              => i_supply_loc,
                                                          i_dt_return               => i_dt_return,
                                                          i_supply_soft_inst        => i_supply_soft_inst,
                                                          i_flg_cons_type           => i_flg_cons_type,
                                                          i_id_req_reason           => i_id_req_reason,
                                                          i_notes                   => i_notes,
                                                          i_surgery_record          => i_surgery_record,
                                                          i_prof_team               => i_prof_team,
                                                          i_tbl_prof                => i_tbl_prof,
                                                          i_tbl_catg                => i_tbl_catg,
                                                          i_tbl_status              => i_tbl_status,
                                                          i_test                    => i_test,
                                                          i_id_cdr_call             => i_id_cdr_call,
                                                          i_diagnosis_surg_proc     => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                                 i_prof   => i_prof,
                                                                                                                 i_params => i_diagnosis_surg_proc),
                                                          i_id_not_order_reason_ea  => i_id_not_order_reason_ea,
                                                          i_id_ct_io                => i_id_ct_io,
                                                          i_clinical_question       => i_clinical_question,
                                                          i_response                => i_response,
                                                          i_clinical_question_notes => i_clinical_question_notes,
                                                          o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        SELECT sr.rowid
          BULK COLLECT
          INTO l_rowids
          FROM schedule_sr sr
         WHERE sr.id_episode = i_id_episode_context;
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
    
        COMMIT;
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
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_surgical_procedures;
    --
    /**************************************************************************
    * Save or update information of surgical procedures (coded and uncoded),  
    * supplies and diagnoses associated with this surgical procedure          
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID                              
    * @param i_id_episode context     ORIS episode ID                         
    * @param i_id_sr_epis_interv      Table number with id_sr_epis_interv     
    * @param i_id_sr_intervention     Table number with interventions ID      
    * @param i_name_interv            Table varchar with names of uncoded surgical procedures
    * @param i_notes_sp               Table varchar with surgical procedures' notes
    * @param i_description_sp         Table varchar with surgical procedures' description
    * @param i_laterality             Table varchar with laterality code
    * @param i_id_diagnosis           Table number with diagnosis id
    * @param i_sp_diag_status         Table varchar of diagnosis status
    * @param i_sp_spec_notes          Table varchar of diagnosis specific notes
    * @param i_sp_diag_notes          Table varchar of diagnosis general notes
    * @param i_supply                 Supply ID
    * @param i_supply_set             Parent supply set (if applicable)
    * @param i_supply_qty             Supply quantity
    * @param i_supply_loc             Supply location
    * @param i_dt_return              Estimated date of of return
    * @param i_supply_soft_inst       list
    * @param i_flg_cons_type          flag of consumption type
    * @param i_id_req_reason          Reasons for each supply
    * @param i_notes                  Request notes
    * @param i_flg_add_problem        The surgical procedure's diagnosis should be associated with problems list?
    * @param i_diag_desc_sp               Desc diagnosis from the diagnosis of the surgical procedures
    * @param i_id_cdr_call           Rule event identifier.
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/23                              
    **************************************************************************/

    FUNCTION set_epis_surg_proc_nocommit
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_episode_context IN episode.id_episode%TYPE,
        --surgical procedures 
        i_id_sr_epis_interv  IN table_number, --5
        i_id_sr_intervention IN table_number,
        i_name_interv        IN table_varchar,
        i_notes_sp           IN table_varchar,
        i_description_sp     IN table_varchar,
        i_flg_type           IN table_varchar, --10
        i_codification       IN table_number,
        i_laterality         IN table_varchar,
        i_surgical_site      IN table_varchar,
        --supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number, --15
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar, --20
        i_id_req_reason    IN table_table_number,
        i_notes            IN table_table_varchar,
        -- team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number, --25
        i_tbl_prof       IN table_table_number,
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar,
        i_test           IN VARCHAR2,
        -- diagnoses
        i_diagnosis_surg_proc IN pk_edis_types.table_in_epis_diagnosis, --30
        -- clinical decision rules
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE,
        i_id_not_order_reason_ea  IN table_number,
        i_id_ct_io                IN table_table_varchar DEFAULT NULL,
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_varchar DEFAULT NULL, --35
        i_clinical_question_notes IN table_table_clob DEFAULT NULL,
        i_id_inst_dest            IN institution.id_institution%TYPE DEFAULT NULL,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_ct_io  table_table_varchar;
        l_func_name VARCHAR2(30) := 'SET_EPIS_SURG_PROC_NOCOMMIT';
    
        l_id_patient                 patient.id_patient%TYPE;
        l_id_sr_epis_interv          sr_epis_interv.id_sr_epis_interv%TYPE;
        l_id_sr_epis_interv_desc     sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE;
        l_has_changes_sr_epis_interv VARCHAR2(1 CHAR);
        l_has_changes_interv_desc    VARCHAR2(1 CHAR);
        l_id_sr_epis_interv_tn       table_number := table_number();
        l_excep                      EXCEPTION;
    
        l_flg_show  VARCHAR2(1);
        l_msg_title sys_message.desc_message%TYPE;
        l_msg_text  sys_message.desc_message%TYPE;
        l_button    VARCHAR2(1);
    
        l_id_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_created_id_diag   pk_edis_types.table_out_epis_diags;
    
        l_id_epis_diag        sr_epis_interv.id_epis_diagnosis%TYPE;
        l_diagnosis_surg_proc pk_edis_types.rec_in_epis_diagnosis;
        l_rowids              table_varchar;
        l_flg_status_old      sr_epis_interv.flg_status%TYPE;
        l_exception           EXCEPTION;
        l_id_not_order_reason table_number := table_number();
    
        l_interv_codification interv_codification.id_interv_codification%TYPE;
    
        l_clinical_question       table_number := table_number();
        l_response                table_varchar := table_varchar();
        l_clinical_question_notes table_clob := table_clob();
    
        l_count                PLS_INTEGER := 0;
        l_sr_question_response sr_interv_quest_response%ROWTYPE;
        l_aux                  table_varchar2;
    
        l_supply_request table_number;
    
        l_supply              table_table_number := table_table_number();
        l_supply_set          table_table_number := table_table_number();
        l_supply_qty          table_table_number := table_table_number();
        l_supply_loc          table_table_number := table_table_number();
        l_dt_return           table_table_varchar := table_table_varchar();
        l_supply_soft_inst    table_table_number := table_table_number();
        l_flg_cons_type       table_table_varchar := table_table_varchar();
        l_id_req_reason       table_table_number := table_table_number();
        l_notes               table_table_varchar := table_table_varchar();
        l_distinct_supply_set table_number;
    
    BEGIN
    
        l_id_ct_io := i_id_ct_io;
    
        IF l_id_ct_io IS NULL
        THEN
            l_id_ct_io := table_table_varchar(table_varchar());
        END IF;
    
        IF NOT l_id_ct_io.exists(1)
        THEN
            l_id_ct_io := table_table_varchar(table_varchar());
        END IF;
    
        g_sysdate_tstz        := current_timestamp;
        l_id_epis_diagnoses   := NULL;
        l_id_epis_diag        := NULL;
        l_diagnosis_surg_proc := NULL;
    
        g_error := 'GET ID_PATIENT for id_episode : ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'Ciclo for i_id_epis_interv';
        pk_alertlog.log_debug(g_error);
    
        FOR i IN 1 .. i_id_sr_epis_interv.count
        LOOP
        
            l_clinical_question := table_number();
            IF i_clinical_question IS NOT NULL
               AND i_clinical_question.count > 0
               AND i <= i_clinical_question.count
            THEN
            
                IF i_clinical_question(i).count > 0
                THEN
                    FOR j IN 1 .. i_clinical_question(i).count
                    LOOP
                        l_clinical_question.extend;
                        l_clinical_question(j) := i_clinical_question(i) (j);
                    END LOOP;
                END IF;
            
            END IF;
        
            l_response := table_varchar();
            IF i_response IS NOT NULL
               AND i_response.count > 0
               AND i <= i_response.count
            THEN
            
                IF i_response(i).count > 0
                THEN
                    FOR j IN 1 .. i_response(i).count
                    LOOP
                        l_response.extend;
                        l_response(j) := i_response(i) (j);
                    END LOOP;
                END IF;
            
            END IF;
        
            l_clinical_question_notes := table_clob();
            IF i_clinical_question_notes IS NOT NULL
               AND i_clinical_question_notes.count > 0
               AND i <= i_clinical_question_notes.count
            THEN
                IF i_clinical_question_notes(i).count > 0
                THEN
                    FOR j IN 1 .. i_clinical_question_notes(i).count
                    LOOP
                        l_clinical_question_notes.extend;
                        l_clinical_question_notes(j) := i_clinical_question_notes(i) (j);
                    END LOOP;
                END IF;
            END IF;
        
            --raise_application_error(-20001,'teste3 - ' || i_id_sr_epis_interv.count);
            l_id_not_order_reason.extend;
            IF i_id_not_order_reason_ea.exists(i)
            THEN
                IF i_id_not_order_reason_ea(i) IS NOT NULL
                THEN
                    g_error := 'CALL pk_not_order_reason_db.set_not_order_reason';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_not_order_reason_ea => i_id_not_order_reason_ea(i),
                                                                       o_id_not_order_reason => l_id_not_order_reason(i),
                                                                       o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    l_id_not_order_reason(i) := NULL;
                END IF;
            ELSE
                l_id_not_order_reason(i) := NULL;
            END IF;
            --
        
            l_created_id_diag := NULL;
            g_error           := 'Se ainda n existe registo';
            --if not exist an id_sr_epis_interv then is necessary create the surgery request
            IF i_id_sr_epis_interv(i) IS NULL
            THEN
                g_error := 'IF id_intervention is null';
                --if id_sr_intervention is null, then is an uncoded surgical procedure
                IF i_id_sr_intervention(i) IS NULL
                THEN
                    IF i_diagnosis_surg_proc IS NOT NULL
                       AND i_diagnosis_surg_proc.count > 0
                       AND i_diagnosis_surg_proc(i).tbl_diagnosis IS NOT NULL
                    THEN
                        IF i_diagnosis_surg_proc(i).tbl_diagnosis.count > 0
                        THEN
                            l_id_epis_diagnoses.epis_diagnosis := i_diagnosis_surg_proc(i);
                            -- tbl_diagnosis(1) -> All interventions have only one diagnosis
                            l_id_epis_diagnoses.epis_diagnosis.tbl_diagnosis(1).flg_status := pk_diagnosis.g_ed_flg_status_d;
                        
                            IF i_diagnosis_surg_proc(i).flg_type IS NULL
                            THEN
                                l_id_epis_diagnoses.epis_diagnosis.flg_type := pk_diagnosis.g_flg_final_type_p;
                            ELSE
                                l_id_epis_diagnoses.epis_diagnosis.flg_type := i_diagnosis_surg_proc(i).flg_type;
                            END IF;
                        
                            g_error := 'CALL PK_DIAGNOSIS.SET_EPIS_DIAGNOSIS FOR ID_EPISODE ORIS ' ||
                                       i_id_episode_context;
                            pk_alertlog.log_debug(g_error);
                        
                            IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_epis_diagnoses => l_id_epis_diagnoses,
                                                                   o_params         => l_created_id_diag,
                                                                   o_error          => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        END IF;
                    END IF;
                
                    g_error := 'CALL PK_SR_PLANNING.SET_EPIS_SURG_UNC_NO_COMMIT FOR ID_EPISODE ORIS  ' ||
                               i_id_episode_context;
                    pk_alertlog.log_debug(g_error);
                
                    --- call function to create uncoded surgical procedure
                    IF NOT pk_sr_planning.set_epis_surg_unc_no_commit(i_lang                    => i_lang,
                                                                 i_id_episode              => i_id_episode,
                                                                 i_id_episode_context      => i_id_episode_context,
                                                                 i_name_interv             => table_varchar(i_name_interv(i)),
                                                                 i_prof                    => i_prof,
                                                                 i_id_patient              => l_id_patient,
                                                                 i_notes                   => i_notes_sp(i),
                                                                 i_dt_req                  => NULL,
                                                                 i_id_epis_diagnosis       => CASE
                                                                                                  WHEN l_created_id_diag IS NOT NULL
                                                                                                       AND l_created_id_diag.exists(1) THEN
                                                                                                   l_created_id_diag(1).id_epis_diagnosis
                                                                                                  ELSE
                                                                                                   NULL
                                                                                              END,
                                                                 i_flg_type                => i_flg_type(i),
                                                                 i_laterality              => i_laterality(i),
                                                                 i_surgical_site           => i_surgical_site(i),
                                                                 i_id_not_order_reason     => l_id_not_order_reason(i),
                                                                 i_clinical_question       => l_clinical_question,
                                                                 i_response                => l_response,
                                                                 i_clinical_question_notes => l_clinical_question_notes,
                                                                 o_id_sr_epis_interv       => l_id_sr_epis_interv,
                                                                 o_error                   => o_error)
                    
                    THEN
                        RAISE l_excep;
                    END IF;
                
                    IF l_id_not_order_reason(i) IS NULL
                    THEN
                        g_error := 'CALL PK_SR_TOOLS.SET_SR_PROF_TEAM_DET FOR ID_EPISODE ORIS  ' ||
                                   i_id_episode_context;
                    
                        IF i_tbl_prof.count > 0
                        THEN
                            IF NOT pk_sr_tools.set_sr_prof_team_det_no_commit(i_lang              => i_lang,
                                                                              i_prof              => i_prof,
                                                                              i_surgery_record    => i_surgery_record(i),
                                                                              i_episode           => i_id_episode,
                                                                              i_episode_context   => i_id_episode_context,
                                                                              i_prof_team         => i_prof_team(i),
                                                                              i_tbl_prof          => i_tbl_prof(i),
                                                                              i_tbl_catg          => i_tbl_catg(i),
                                                                              i_tbl_status        => i_tbl_status(i),
                                                                              i_test              => i_test,
                                                                              i_id_sr_epis_interv => l_id_sr_epis_interv,
                                                                              o_flg_show          => l_flg_show,
                                                                              o_msg_title         => l_msg_title,
                                                                              o_msg_text          => l_msg_text,
                                                                              o_button            => l_button,
                                                                              o_error             => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        END IF;
                    END IF;
                
                ELSE
                    IF i_diagnosis_surg_proc IS NOT NULL
                       AND i_diagnosis_surg_proc(i).tbl_diagnosis IS NOT NULL
                    THEN
                        l_diagnosis_surg_proc := i_diagnosis_surg_proc(i);
                    END IF;
                
                    g_error := 'CALL PK_SURGERY_REQUEST.SET_EPIS_SURG_INTERV FOR ID_EPISODE ORIS ' ||
                               i_id_episode_context;
                
                    pk_alertlog.log_debug(g_error);
                
                    -- call function to create coded surgical procedure
                    IF NOT pk_surgery_request.set_epis_surg_interv_no_commit(i_lang                    => i_lang,
                                                                             i_episode                 => i_id_episode,
                                                                             i_episode_context         => i_id_episode_context,
                                                                             i_sr_intervention         => table_number(i_id_sr_intervention(i)),
                                                                             i_codification            => table_number(i_codification(i)),
                                                                             i_laterality              => table_varchar(i_laterality(i)),
                                                                             i_surgical_site           => table_varchar(i_surgical_site(i)),
                                                                             i_prof                    => i_prof,
                                                                             i_sp_notes                => table_varchar(i_notes_sp(i)),
                                                                             i_flg_type                => table_varchar(i_flg_type(i)),
                                                                             i_surgery_record          => table_number(i_surgery_record(i)),
                                                                             i_prof_team               => table_number(i_prof_team(i)),
                                                                             i_tbl_prof                => table_table_number(i_tbl_prof(i)),
                                                                             i_tbl_catg                => table_table_number(i_tbl_catg(i)),
                                                                             i_tbl_status              => table_table_varchar(i_tbl_status(i)),
                                                                             i_test                    => i_test,
                                                                             i_diagnosis_surg_proc     => l_diagnosis_surg_proc,
                                                                             i_id_cdr_call             => i_id_cdr_call,
                                                                             i_id_not_order_reason     => l_id_not_order_reason(i),
                                                                             i_id_ct_io                => table_table_varchar(l_id_ct_io(i)),
                                                                             i_clinical_question       => l_clinical_question,
                                                                             i_response                => l_response,
                                                                             i_clinical_question_notes => l_clinical_question_notes,
                                                                             o_id_sr_epis_interv       => l_id_sr_epis_interv,
                                                                             o_error                   => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                g_error := 'CALL PK_SR_PLANNING.SET_CONF_EPIS_SURG_INTERV FOR ID_EPISODE ORIS  ' ||
                           i_id_episode_context;
                pk_alertlog.log_debug(g_error);
                --  Calculate the state of the surgical procedure 
                IF NOT set_conf_epis_surg_interv(i_lang            => i_lang,
                                                 i_episode         => i_id_episode_context,
                                                 i_sr_epis_interv  => l_id_sr_epis_interv,
                                                 i_sr_intervention => i_id_sr_intervention(i),
                                                 i_prof            => i_prof,
                                                 i_id_cdr_call     => i_id_cdr_call,
                                                 o_error           => o_error)
                THEN
                    RAISE l_excep;
                END IF;
            
                IF i_description_sp(i) IS NOT NULL
                THEN
                    g_error := 'CALL PK_SR_PLANNING.SET_SURG_PROC_DESC_NO_COMMIT FOR ID_EPISODE ORIS  ' ||
                               i_id_episode_context;
                    pk_alertlog.log_debug(g_error);
                    -- Put intervention's description to a surgical procedure
                    IF NOT pk_sr_planning.set_surg_proc_desc_no_commit(i_lang                   => i_lang,
                                                                       i_episode                => i_id_episode,
                                                                       i_episode_context        => i_id_episode_context,
                                                                       i_sr_epis_interv         => l_id_sr_epis_interv,
                                                                       i_prof                   => i_prof,
                                                                       i_notes                  => i_description_sp(i),
                                                                       o_id_sr_epis_interv_desc => l_id_sr_epis_interv_desc,
                                                                       o_error                  => o_error)
                    THEN
                        RAISE l_excep;
                    END IF;
                END IF;
            
                l_id_sr_epis_interv_tn.extend;
                l_id_sr_epis_interv_tn(i) := l_id_sr_epis_interv;
            
            ELSE
                --edit
                IF i_diagnosis_surg_proc IS NOT NULL
                   AND i_diagnosis_surg_proc.count > 0
                   AND i_diagnosis_surg_proc(i).tbl_diagnosis IS NOT NULL
                THEN
                    IF i_diagnosis_surg_proc(i).tbl_diagnosis.count > 0
                    THEN
                        l_id_epis_diagnoses.epis_diagnosis := i_diagnosis_surg_proc(i);
                        -- tbl_diagnosis(1) -> All interventions have only one diagnosis
                        l_id_epis_diagnoses.epis_diagnosis.tbl_diagnosis(1).flg_status := pk_diagnosis.g_ed_flg_status_d;
                    
                        IF i_diagnosis_surg_proc(i).flg_type IS NULL
                        THEN
                            l_id_epis_diagnoses.epis_diagnosis.flg_type := pk_diagnosis.g_flg_final_type_p;
                        ELSE
                            l_id_epis_diagnoses.epis_diagnosis.flg_type := i_diagnosis_surg_proc(i).flg_type;
                        END IF;
                    
                        l_id_epis_diagnoses.epis_diagnosis            := i_diagnosis_surg_proc(i);
                        l_id_epis_diagnoses.epis_diagnosis.id_episode := i_id_episode_context;
                        g_error                                       := 'CALL PK_DIAGNOSIS.SET_EPIS_DIAGNOSIS FOR ID_EPISODE ORIS  ' ||
                                                                         i_id_episode_context;
                        pk_alertlog.log_debug(g_error);
                    
                        IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_epis_diagnoses => l_id_epis_diagnoses,
                                                               o_params         => l_created_id_diag,
                                                               o_error          => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                END IF;
            
                l_id_epis_diag := CASE
                                      WHEN l_created_id_diag IS NOT NULL
                                           AND l_created_id_diag.exists(1) THEN
                                       l_created_id_diag(1).id_epis_diagnosis
                                      ELSE
                                       NULL
                                  END;
            
                BEGIN
                    SELECT ic.id_interv_codification
                      INTO l_interv_codification
                      FROM interv_codification ic
                     WHERE ic.id_codification = i_codification(i)
                       AND ic.id_intervention = i_id_sr_intervention(i)
                       AND ic.flg_available = pk_alert_constant.g_available;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_interv_codification := NULL;
                END;
            
                --exist an id_sr_epis_interv so is necessary update information of the surgery request
                g_error := 'Call check_changes_surg_procedures';
                pk_alertlog.log_debug(g_error);
            
                BEGIN
                    IF i_flg_type.count > 0
                       OR i_codification.count > 0
                       OR i_laterality.count > 0
                       OR i_description_sp.count > 0
                       OR i_notes_sp.count > 0
                    THEN
                        -- check if there are changes to process for the sr_epis_interv and sr_epis_interv_desc tables
                        IF NOT pk_sr_planning.check_changes_surg_procedures(i_lang                       => i_lang,
                                                                            i_prof                       => i_prof,
                                                                            i_id_sr_epis_interv          => i_id_sr_epis_interv(i),
                                                                            i_flg_type                   => i_flg_type(i),
                                                                            i_interv_codification        => l_interv_codification,
                                                                            i_laterality                 => i_laterality(i),
                                                                            i_id_epis_diagnosis          => l_id_epis_diag,
                                                                            i_notes                      => i_notes_sp(i),
                                                                            i_desc_interv                => i_description_sp(i),
                                                                            o_has_changes_sr_epis_interv => l_has_changes_sr_epis_interv,
                                                                            o_has_changes_interv_desc    => l_has_changes_interv_desc,
                                                                            o_error                      => o_error)
                        THEN
                            RAISE l_excep;
                        END IF;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_has_changes_sr_epis_interv := pk_alert_constant.g_no;
                        l_has_changes_interv_desc    := NULL;
                    
                END;
            
                g_error := 'call ts_sr_epis_interv.upd for id_sr_epis_interv : ' || i_id_sr_epis_interv(i);
                pk_alertlog.log_debug(g_error);
                --update table with new information                            
                IF l_has_changes_sr_epis_interv = pk_alert_constant.g_yes
                THEN
                    g_error := 'get l_flg_status_old';
                    BEGIN
                        SELECT sei.flg_status
                          INTO l_flg_status_old
                          FROM sr_epis_interv sei
                         WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv(i);
                    EXCEPTION
                        WHEN dup_val_on_index THEN
                            l_flg_status_old := NULL;
                    END;
                
                    g_error := 'call ts_sr_epis_interv.upd';
                    ts_sr_epis_interv.upd(laterality_in              => i_laterality(i),
                                          laterality_nin             => FALSE,
                                          surgical_site_in           => i_surgical_site(i),
                                          surgical_site_nin          => FALSE,
                                          id_epis_diagnosis_in       => l_id_epis_diag,
                                          notes_in                   => i_notes_sp(i),
                                          notes_nin                  => FALSE,
                                          flg_type_in                => i_flg_type(i),
                                          flg_type_nin               => FALSE,
                                          id_not_order_reason_in     => l_id_not_order_reason(i),
                                          id_not_order_reason_nin    => FALSE,
                                          dt_req_tstz_in             => g_sysdate_tstz,
                                          dt_req_tstz_nin            => FALSE,
                                          id_interv_codification_in  => l_interv_codification,
                                          id_interv_codification_nin => FALSE,
                                          where_in                   => 'id_sr_epis_interv = ' || i_id_sr_epis_interv(i),
                                          rows_out                   => l_rowids);
                
                    g_error := 'call t_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SR_EPIS_INTERV',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    g_error := 'call pk_sr_output.set_ia_event_prescription';
                    IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_flg_action        => 'U',
                                                                  i_id_sr_epis_interv => i_id_sr_epis_interv(i),
                                                                  i_flg_status_new    => l_flg_status_old,
                                                                  i_flg_status_old    => l_flg_status_old,
                                                                  o_error             => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    IF NOT pk_sr_output.insert_sr_epis_interv_hist(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_id_sr_epis_interv => i_id_sr_epis_interv(i),
                                                                   i_id_ct_io          => l_id_ct_io(i),
                                                                   o_error             => o_error)
                    THEN
                        RAISE l_excep;
                    END IF;
                
                    g_error := 'call pk_sr_planning.set_conf_epis_surg_interv for id_episode : ' ||
                               i_id_episode_context;
                    pk_alertlog.log_debug(g_error);
                    --  Calculate the state of the surgical procedure
                    IF NOT pk_sr_planning.set_conf_epis_surg_interv(i_lang            => i_lang,
                                                                    i_episode         => i_id_episode_context,
                                                                    i_sr_epis_interv  => i_id_sr_epis_interv(i),
                                                                    i_sr_intervention => i_id_sr_intervention(i),
                                                                    i_prof            => i_prof,
                                                                    i_id_cdr_call     => i_id_cdr_call,
                                                                    o_error           => o_error)
                    THEN
                        RAISE l_excep;
                    END IF;
                
                    g_error := 'Check changes for sr_epis_interv_desc table ' || l_has_changes_interv_desc;
                    pk_alertlog.log_debug(g_error);
                    IF l_has_changes_interv_desc = pk_alert_constant.g_yes
                    THEN
                        g_error := 'CALL PK_SR_PLANNING.SET_SURG_PROC_DESC_NO_COMMIT FOR ID_EPISODE ORIS  ' ||
                                   i_id_episode_context;
                        pk_alertlog.log_debug(g_error);
                        -- Put intervention's description to a surgical procedure 
                        IF NOT pk_sr_planning.set_surg_proc_desc_no_commit(i_lang                   => i_lang,
                                                                           i_episode                => i_id_episode,
                                                                           i_episode_context        => i_id_episode_context,
                                                                           i_sr_epis_interv         => i_id_sr_epis_interv(i),
                                                                           i_prof                   => i_prof,
                                                                           i_notes                  => i_description_sp(i),
                                                                           o_id_sr_epis_interv_desc => l_id_sr_epis_interv_desc,
                                                                           o_error                  => o_error)
                        THEN
                            RAISE l_excep;
                        END IF;
                    
                    END IF;
                
                    g_error := 'CALL PK_SR_TOOLS.SET_SR_PROF_TEAM_DET FOR ID_EPISODE ORIS  ' || i_id_episode_context;
                    pk_alertlog.log_debug(g_error);
                
                    IF i_tbl_prof.count > 0
                    THEN
                        IF NOT pk_sr_tools.set_sr_prof_team_det_no_commit(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_surgery_record    => i_surgery_record(i),
                                                                     i_episode           => i_id_episode,
                                                                     i_episode_context   => i_id_episode_context,
                                                                     i_prof_team         => i_prof_team(i),
                                                                     i_tbl_prof          => CASE
                                                                                                WHEN i_tbl_prof.exists(i) THEN
                                                                                                 i_tbl_prof(i)
                                                                                                ELSE
                                                                                                 table_number()
                                                                                            END,
                                                                     i_tbl_catg          => CASE
                                                                                                WHEN i_tbl_catg.exists(i) THEN
                                                                                                 i_tbl_catg(i)
                                                                                                ELSE
                                                                                                 table_number()
                                                                                            END,
                                                                     i_tbl_status        => CASE
                                                                                                WHEN i_tbl_status.exists(i) THEN
                                                                                                 i_tbl_status(i)
                                                                                                ELSE
                                                                                                 table_varchar()
                                                                                            END,
                                                                     i_test              => i_test,
                                                                     i_id_sr_epis_interv => i_id_sr_epis_interv(i),
                                                                     o_flg_show          => l_flg_show,
                                                                     o_msg_title         => l_msg_title,
                                                                     o_msg_text          => l_msg_text,
                                                                     o_button            => l_button,
                                                                     o_error             => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                
                    l_id_sr_epis_interv_tn.extend;
                    l_id_sr_epis_interv_tn(i) := i_id_sr_epis_interv(i);
                    -- not necessary update surgical supplies because we can't change surgical supplies in edition mode
                ELSE
                
                    IF i_tbl_prof.count > 0
                    THEN
                        IF NOT pk_sr_tools.set_sr_prof_team_det_no_commit(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_surgery_record    => i_surgery_record(i),
                                                                     i_episode           => i_id_episode,
                                                                     i_episode_context   => i_id_episode_context,
                                                                     i_prof_team         => i_prof_team(i),
                                                                     i_tbl_prof          => CASE
                                                                                                WHEN i_tbl_prof.exists(i) THEN
                                                                                                 i_tbl_prof(i)
                                                                                                ELSE
                                                                                                 table_number()
                                                                                            END,
                                                                     i_tbl_catg          => CASE
                                                                                                WHEN i_tbl_catg.exists(i) THEN
                                                                                                 i_tbl_catg(i)
                                                                                                ELSE
                                                                                                 table_number()
                                                                                            END,
                                                                     i_tbl_status        => CASE
                                                                                                WHEN i_tbl_status.exists(i) THEN
                                                                                                 i_tbl_status(i)
                                                                                                ELSE
                                                                                                 table_varchar()
                                                                                            END,
                                                                     i_test              => i_test,
                                                                     i_id_sr_epis_interv => i_id_sr_epis_interv(i),
                                                                     o_flg_show          => l_flg_show,
                                                                     o_msg_title         => l_msg_title,
                                                                     o_msg_text          => l_msg_text,
                                                                     o_button            => l_button,
                                                                     o_error             => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                
                    IF l_clinical_question IS NOT NULL
                       AND l_clinical_question.count > 0
                    THEN
                        FOR k IN 1 .. l_clinical_question.count
                        LOOP
                            IF l_clinical_question(k) IS NOT NULL
                            THEN
                            
                                SELECT COUNT(*)
                                  INTO l_count
                                  FROM (SELECT eqr.*,
                                               row_number() over(PARTITION BY eqr.id_questionnaire ORDER BY eqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                          FROM sr_interv_quest_response eqr
                                         WHERE eqr.id_sr_epis_interv = i_id_sr_epis_interv(i)
                                           AND eqr.id_questionnaire = l_clinical_question(k)
                                           AND eqr.id_response = l_response(k))
                                 WHERE rn = 1;
                            
                                IF l_count = 0
                                THEN
                                    g_error := 'INSERT INTO SR_INTERV_QUEST_RESPONSE';
                                    INSERT INTO sr_interv_quest_response
                                        (id_sr_interv_quest_response,
                                         id_episode,
                                         id_sr_epis_interv,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (seq_interv_question_response.nextval,
                                         i_id_episode,
                                         i_id_sr_epis_interv(i),
                                         pk_exam_constant.g_exam_cq_on_order,
                                         l_clinical_question(k),
                                         l_response(k),
                                         l_clinical_question_notes(k),
                                         i_prof.id,
                                         g_sysdate_tstz);
                                ELSE
                                    SELECT id_sr_interv_quest_response,
                                           id_episode,
                                           id_sr_epis_interv,
                                           flg_time,
                                           id_questionnaire,
                                           id_response,
                                           notes,
                                           id_prof_last_update,
                                           dt_last_update_tstz,
                                           create_user,
                                           create_time,
                                           create_institution,
                                           update_user,
                                           update_time,
                                           update_institution
                                      INTO l_sr_question_response
                                      FROM (SELECT eqr.*,
                                                   row_number() over(PARTITION BY eqr.id_questionnaire ORDER BY eqr.dt_last_update_tstz DESC NULLS FIRST) rn
                                              FROM sr_interv_quest_response eqr
                                             WHERE eqr.id_sr_epis_interv = i_id_sr_epis_interv(i)
                                               AND eqr.id_questionnaire = l_clinical_question(k)
                                               AND eqr.id_response = l_response(k))
                                     WHERE rn = 1;
                                
                                    g_error := 'INSERT INTO SR_INTERV_QUEST_RESPONSE';
                                    INSERT INTO sr_interv_quest_response_hist
                                        (dt_interv_question_resp_hist,
                                         id_sr_interv_quest_response,
                                         id_episode,
                                         id_sr_epis_interv,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (g_sysdate_tstz,
                                         l_sr_question_response.id_sr_interv_quest_response,
                                         l_sr_question_response.id_episode,
                                         l_sr_question_response.id_sr_epis_interv,
                                         l_sr_question_response.flg_time,
                                         l_sr_question_response.id_questionnaire,
                                         l_sr_question_response.id_response,
                                         l_sr_question_response.notes,
                                         l_sr_question_response.id_prof_last_update,
                                         l_sr_question_response.dt_last_update_tstz);
                                
                                    g_error := 'INSERT INTO SR_INTERV_QUEST_RESPONSE';
                                    INSERT INTO sr_interv_quest_response
                                        (id_sr_interv_quest_response,
                                         id_episode,
                                         id_sr_epis_interv,
                                         flg_time,
                                         id_questionnaire,
                                         id_response,
                                         notes,
                                         id_prof_last_update,
                                         dt_last_update_tstz)
                                    VALUES
                                        (seq_interv_question_response.nextval,
                                         i_id_episode,
                                         i_id_sr_epis_interv(i),
                                         pk_exam_constant.g_exam_cq_on_order,
                                         l_clinical_question(k),
                                         l_response(k),
                                         l_clinical_question_notes(k),
                                         i_prof.id,
                                         g_sysdate_tstz);
                                END IF;
                            END IF;
                        END LOOP;
                    END IF;
                
                    l_id_sr_epis_interv_tn.extend;
                    l_id_sr_epis_interv_tn(i) := i_id_sr_epis_interv(i);
                
                END IF;
            END IF;
        
            l_id_sr_epis_interv      := NULL; -- reset variable
            l_id_sr_epis_interv_desc := NULL; -- reset variable
        END LOOP;
    
        g_error := 'CALL PK_SUPPLIES_API_DB.SET_SUPPLIES_SURG_PROC FOR ID_EPISODE ORIS  ' || i_id_episode_context;
        pk_alertlog.log_debug(g_error);
        FOR i IN 1 .. i_id_sr_epis_interv.count
        LOOP
            SELECT sw.id_supply_request
              BULK COLLECT
              INTO l_supply_request
              FROM supply_workflow sw
             INNER JOIN sr_epis_interv sei
                ON sei.id_episode_context = sw.id_episode
               AND sei.flg_status != pk_alert_constant.g_cancelled
               AND sei.id_sr_epis_interv = i_id_sr_epis_interv(i)
               AND sei.id_sr_epis_interv = sw.id_context
             WHERE sei.id_episode_context = i_id_episode_context;
        
            FOR i IN 1 .. l_supply_request.count
            LOOP
                IF NOT pk_supplies_api_db.cancel_request(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_supply_request   => l_supply_request(i),
                                                         i_notes            => NULL,
                                                         i_id_cancel_reason => NULL,
                                                         o_error            => o_error)
                THEN
                    RAISE l_excep;
                END IF;
            END LOOP;
        END LOOP;
    
        -- Associate surgical supplies to a surgical procedure 
        IF NOT pk_supplies_external_api_db.set_supplies_surg_proc(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_id_sr_epis_interv => l_id_sr_epis_interv_tn,
                                                                  i_id_episode        => i_id_episode_context,
                                                                  i_supply            => i_supply,
                                                                  i_supply_set        => i_supply_set,
                                                                  i_supply_qty        => i_supply_qty,
                                                                  i_supply_loc        => i_supply_loc,
                                                                  i_dt_return         => i_dt_return,
                                                                  i_supply_soft_inst  => i_supply_soft_inst,
                                                                  i_flg_cons_type     => i_flg_cons_type,
                                                                  i_id_req_reason     => i_id_req_reason,
                                                                  i_notes             => i_notes,
                                                                  i_id_inst_dest      => i_id_inst_dest,
                                                                  o_error             => o_error)
        THEN
            RAISE l_excep;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_excep THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
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
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_surg_proc_nocommit;

    /**************************************************************************
    * Check if has changes for surgical procedures tables         
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                                              
    * @param i_id_sr_epis_interv      Primary key of sr_epis_interv table  
    * @param i_laterality             Laterality code    
    * @param i_id_epis_diagnosis      Epis Diagnosis id
    * @param i_notes                  Surgical procedure notes
    * @param i_desc_interv            Surgical procedure description
    *
    * @param o_has_changes_sr_epis_interv  has changes (Y) or not (N) for the sr_epis_interv table                                                                         
    * @param o_has_changes_interv_desc  has changes (Y) or not (N) for the sr_epis_interv_desc table
    * @param o_error                   error description
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/23                              
    **************************************************************************/

    FUNCTION check_changes_surg_procedures
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_sr_epis_interv          IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_flg_type                   IN sr_epis_interv.flg_type%TYPE,
        i_interv_codification        IN sr_epis_interv.id_interv_codification%TYPE,
        i_laterality                 IN sr_epis_interv.laterality%TYPE,
        i_id_epis_diagnosis          IN sr_epis_interv.id_epis_diagnosis%TYPE,
        i_notes                      IN sr_epis_interv.notes%TYPE,
        i_desc_interv                IN sr_epis_interv_desc.desc_interv%TYPE,
        o_has_changes_sr_epis_interv OUT VARCHAR2,
        o_has_changes_interv_desc    OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name           VARCHAR2(30) := 'CHECK_CHANGES_SURG_PROCEDURES';
        l_flg_type            sr_epis_interv.flg_type%TYPE;
        l_interv_codification sr_epis_interv.id_interv_codification%TYPE;
        l_laterality          sr_epis_interv.laterality%TYPE;
        l_id_epis_diagnosis   sr_epis_interv.id_epis_diagnosis%TYPE;
        l_notes               sr_epis_interv.notes%TYPE;
        l_desc_interv         sr_epis_interv_desc.desc_interv%TYPE;
    
    BEGIN
    
        g_error := 'Get information about surgical procedure of id_sr_epis_interv ' || i_id_sr_epis_interv;
        pk_alertlog.log_debug(g_error);
    
        --get information about the surgical procedure 
        SELECT flg_type, id_interv_codification, laterality, notes, id_epis_diagnosis, desc_interv
          INTO l_flg_type, l_interv_codification, l_laterality, l_notes, l_id_epis_diagnosis, l_desc_interv
          FROM (SELECT sei.id_sr_epis_interv,
                       seid.id_sr_epis_interv_desc,
                       sei.flg_type,
                       sei.id_interv_codification,
                       sei.laterality,
                       sei.notes,
                       sei.id_epis_diagnosis,
                       seid.desc_interv,
                       row_number() over(PARTITION BY sei.id_sr_epis_interv ORDER BY seid.id_sr_epis_interv_desc DESC) rn
                  FROM sr_epis_interv sei
                  LEFT JOIN sr_epis_interv_desc seid
                    ON seid.id_sr_epis_interv = sei.id_sr_epis_interv
                   AND seid.flg_status = g_active
                  LEFT JOIN epis_diagnosis ed
                    ON ed.id_epis_diagnosis = sei.id_epis_diagnosis
                 WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv)
         WHERE rn = 1;
    
        --Check if is necessary update data about sr_epis_interv table 
        g_error := 'Check data: laterality : ' || l_laterality || ' ' || i_laterality || ' notes : ' || l_notes || ' ' ||
                   i_notes || ' id_diagnosis : ' || l_id_epis_diagnosis || ' ' || i_id_epis_diagnosis || ';';
        pk_alertlog.log_debug(g_error);
        IF nvl(to_char(l_flg_type), 'null') = nvl(to_char(i_flg_type), 'null')
           AND nvl(to_char(l_interv_codification), 'null') = nvl(to_char(i_interv_codification), 'null')
           AND nvl(to_char(l_laterality), 'null') = nvl(to_char(i_laterality), 'null')
           AND nvl(to_char(l_notes), 'null') = nvl(to_char(i_notes), 'null')
           AND nvl(to_char(l_id_epis_diagnosis), 'null') = nvl(to_char(i_id_epis_diagnosis), 'null')
        
        THEN
            o_has_changes_sr_epis_interv := pk_alert_constant.g_no;
        ELSE
            o_has_changes_sr_epis_interv := pk_alert_constant.g_yes;
        END IF;
    
        --Check if is necessary update data about sr_epis_interv_desc table
        g_error := 'check if is necessary to update the sr_epis_interv_desc table';
        pk_alertlog.log_debug(g_error);
        IF nvl(to_char(l_desc_interv), 'null') = nvl(to_char(i_desc_interv), 'null')
        THEN
            o_has_changes_interv_desc := pk_alert_constant.g_no;
        ELSE
            o_has_changes_interv_desc := pk_alert_constant.g_yes;
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
            RETURN FALSE;
    END check_changes_surg_procedures;

    /**************************************************************************
    * Check last surgical procedures update
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                                              
    * @param i_id_episode             Episode ID    
    *
    * @param o_dt_last_upd            Last update date                                                                         
    * @param o_error                  Error data
    *
    * @author                         Jorge Canossa                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/27                              
    **************************************************************************/

    FUNCTION get_last_surg_proc_upd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN sr_epis_interv.id_episode_context%TYPE,
        o_dt_last_upd OUT sr_epis_interv.dt_req_unc_tstz%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_LAST_SURG_PROC_UPD';
    BEGIN
        g_error := 'i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        SELECT MAX(dt)
          INTO o_dt_last_upd
          FROM (SELECT MAX(sei.dt_req_tstz) dt
                  FROM sr_epis_interv sei
                 WHERE sei.id_episode_context = i_id_episode
                UNION ALL
                SELECT MAX(sei.dt_req_unc_tstz) dt
                  FROM sr_epis_interv sei
                 WHERE sei.id_episode_context = i_id_episode
                UNION ALL
                SELECT MAX(sei.dt_cancel_tstz) dt
                  FROM sr_epis_interv sei
                 WHERE sei.id_episode_context = i_id_episode
                UNION ALL
                SELECT MAX(seid.dt_interv_desc_tstz) dt
                  FROM sr_epis_interv_desc seid
                 WHERE seid.id_episode_context = i_id_episode);
    
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
            RETURN FALSE;
    END get_last_surg_proc_upd;

    /**************************************************************************
    * Get the reasons cancels and the supplies associated with the surgical procedure
    *  to be cancelled       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_area                   The cancel reason area
    * @param i_id_sr_epis_interv      Primary key sr_epis_interv table    
    *
    * @param o_reasons                Cursor with cancel reasons
    * @param o_supplies_to_remove     Cursor with supplies to be cancelled
    * @param o_labels                 Cursor with labels 
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/29                                 
    **************************************************************************/

    FUNCTION get_cancel_reasons_surg_proc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_area               IN cancel_rea_area.intern_name%TYPE,
        i_id_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_reasons            OUT pk_types.cursor_type,
        o_supplies_to_remove OUT pk_types.cursor_type,
        o_labels             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(30 CHAR) := 'GET_CANCEL_REASONS_SURG_PROC';
        l_internal_exception EXCEPTION;
        l_found              VARCHAR2(1 CHAR);
        l_id_supply_workflow table_number;
        l_id_supply          table_number;
        l_empty_array_number table_number := table_number();
    
        l_title_cancel_with_sup  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SPCANCEL_T002');
        l_title_canc_without_sup sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SPCANCEL_T003');
        l_message                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SPCANCEL_M009');
        l_reason_cancel          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SPCANCEL_M011');
        l_supplies_remove        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SPCANCEL_M010');
        l_surg_proc              sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_SPCANCEL_M012');
    
    BEGIN
    
        g_error := 'CALL PK_CANCEL_REASON.GET_CANCEL_REASON_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_cancel_reason.get_cancel_reason_list(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_area    => i_area,
                                                       o_reasons => o_reasons,
                                                       o_error   => o_error)
        THEN
            RAISE l_internal_exception;
        END IF;
    
        g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.GET_INF_SUPPLY_WORKFLOW';
        pk_alertlog.log_debug(g_error);
        --check if there are supplies to be cancelled and get the id_supply_workflow
        IF NOT pk_supplies_external_api_db.get_inf_supply_workflow(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_context         => i_id_sr_epis_interv,
                                                                   i_flg_context        => pk_supplies_constant.g_context_surgery,
                                                                   i_id_supply          => l_empty_array_number,
                                                                   i_flg_status         => pk_supplies_constant.g_flg_status_can_cancel,
                                                                   o_has_supplies       => l_found,
                                                                   o_id_supply_workflow => l_id_supply_workflow,
                                                                   o_id_supply          => l_id_supply,
                                                                   o_error              => o_error)
        THEN
            RAISE l_internal_exception;
        END IF;
    
        --in case there're supplies
        IF l_found = pk_alert_constant.g_yes
        THEN
            g_error := 'OPEN CURSOR O_SUPPLIES_TO_REMOVE';
            pk_alertlog.log_debug(g_error);
            OPEN o_supplies_to_remove FOR
                SELECT pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || id_supply) || ' (' ||
                       pk_utils.to_str(quantity) || ')' description,
                       id_supply
                  FROM (SELECT SUM(sw.quantity) quantity, sw.id_supply
                          FROM supply_workflow sw
                         WHERE sw.id_supply_workflow IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                                          t.column_value
                                                           FROM TABLE(l_id_supply_workflow) t)
                         GROUP BY sw.id_supply)
                 ORDER BY description;
        
        END IF;
    
        g_error := 'OPEN CURSOR O_LABELS';
        pk_alertlog.log_debug(g_error);
        OPEN o_labels FOR
            SELECT CASE
                        WHEN l_found = pk_alert_constant.g_yes THEN
                         l_title_cancel_with_sup
                        ELSE
                         l_title_canc_without_sup
                    END screen_title,
                   l_surg_proc surg_proc_title,
                   CASE
                        WHEN t.id_sr_intervention IS NOT NULL THEN
                         pk_translation.get_translation(i_lang,
                                                        'SR_INTERVENTION.CODE_SR_INTERVENTION.' || t.id_sr_intervention)
                        ELSE
                         t.name_interv
                    END desc_intervention,
                   CASE
                        WHEN l_found = pk_alert_constant.g_yes THEN
                         l_message
                        ELSE
                         NULL
                    END title_supplies,
                   CASE
                        WHEN l_found = pk_alert_constant.g_yes THEN
                         l_supplies_remove
                        ELSE
                         NULL
                    END sup_to_remove,
                   l_reason_cancel canc_reason
              FROM (SELECT sei.id_sr_intervention, sei.name_interv
                      FROM sr_epis_interv sei
                     WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv) t;
    
        pk_types.open_cursor_if_closed(o_supplies_to_remove);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_supplies_to_remove);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_cancel_reasons_surg_proc;

    /**************************************************************************
    * Cancel the surgical procedures and the supplies were chosen by the professional.
    * For the other supplies, will be deleted the association of the surgical procedure.     
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             ORIS episode ID
    * @param i_id_sr_epis_interv      Primary key sr_epis_interv table    
    * @param i_sup_to_be_cancelled    table number with supplies id to be cancelled
    * @param i_sr_cancel_reason       Cancel reason surgical procedure
    * @param i_notes                  Cancel notes
    *
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/30                                 
    **************************************************************************/

    FUNCTION set_cancel_epis_surg_proc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_epis_interv   IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_sup_to_be_cancelled IN table_number,
        i_sr_cancel_reason    IN sr_epis_interv.id_sr_cancel_reason%TYPE,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(30 CHAR) := 'SET_CANCEL_EPIS_SURG_PROC';
        l_id_supply_workflow table_number;
        l_id_supply          table_number;
        l_found              VARCHAR2(1 CHAR);
        l_empty_array_number table_number := table_number();
    
        l_excep  EXCEPTION;
        l_rowids table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL PK_SR_PLANNING.CANCEL_EPIS_SURG_PROC FOR ID_EPISODE : ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        --cancel surgical procedure and surgical procedure descriptions
        IF NOT pk_sr_planning.cancel_epis_surg_proc(i_lang             => i_lang,
                                                    i_episode          => i_id_episode,
                                                    i_sr_epis_interv   => i_id_sr_epis_interv,
                                                    i_prof             => i_prof,
                                                    i_sr_cancel_reason => i_sr_cancel_reason,
                                                    i_notes            => i_notes,
                                                    o_error            => o_error)
        THEN
            RAISE l_excep;
        END IF;
    
        IF i_sup_to_be_cancelled IS NOT NULL
           AND i_sup_to_be_cancelled.count > 0
        THEN
        
            g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.GET_INF_SUPPLY_WORKFLOW FOR ID_CONTEXT: ' ||
                       i_id_sr_epis_interv;
            pk_alertlog.log_debug(g_error);
            --get the id_supply_workflows 
            IF NOT pk_supplies_external_api_db.get_inf_supply_workflow(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_context         => i_id_sr_epis_interv,
                                                                       i_flg_context        => pk_supplies_constant.g_context_surgery,
                                                                       i_id_supply          => i_sup_to_be_cancelled,
                                                                       i_flg_status         => pk_supplies_constant.g_flg_status_can_cancel,
                                                                       o_has_supplies       => l_found,
                                                                       o_id_supply_workflow => l_id_supply_workflow,
                                                                       o_id_supply          => l_id_supply,
                                                                       o_error              => o_error)
            THEN
                RAISE l_excep;
            END IF;
        
            IF l_found = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL pk_supplies_api_db.set_cancel_supply for id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                --cancel supplies associated with the surgical procedure
                IF NOT pk_supplies_api_db.cancel_supply_order(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_supplies         => l_id_supply_workflow,
                                                              i_id_prof_cancel   => NULL,
                                                              i_cancel_notes     => to_clob(i_notes),
                                                              i_id_cancel_reason => i_sr_cancel_reason,
                                                              i_dt_cancel        => NULL,
                                                              o_error            => o_error)
                THEN
                    RAISE l_excep;
                END IF;
            END IF;
        END IF;
    
        l_id_supply_workflow := l_empty_array_number; -- reset variable
        l_id_supply          := l_empty_array_number; -- reset variable
    
        g_error := 'CALL pk_supplies_external_api_db.GET_INF_SUPPLY_WORKFLOW FOR INDEPENDENT SUPPLIES for id_context: ' ||
                   i_id_sr_epis_interv || 'and flg_context: ' || pk_supplies_constant.g_context_surgery;
        pk_alertlog.log_debug(g_error);
        --get the id_supply_workflows 
        IF NOT pk_supplies_external_api_db.get_inf_supply_workflow(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_context         => i_id_sr_epis_interv,
                                                                   i_flg_context        => pk_supplies_constant.g_context_surgery,
                                                                   i_id_supply          => l_empty_array_number,
                                                                   i_flg_status         => pk_supplies_constant.g_flg_status_cannot_cancel,
                                                                   o_has_supplies       => l_found,
                                                                   o_id_supply_workflow => l_id_supply_workflow,
                                                                   o_id_supply          => l_id_supply,
                                                                   o_error              => o_error)
        THEN
            RAISE l_excep;
        END IF;
    
        IF l_found = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.SET_INDEPENDENT_SUPPLY';
            pk_alertlog.log_debug(g_error);
            --put independent supplies (remove the association surgical procedure)
            IF NOT pk_supplies_external_api_db.set_independent_supply(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_id_supply_workflow => l_id_supply_workflow,
                                                                      o_error              => o_error)
            THEN
                RAISE l_excep;
            END IF;
        END IF;
    
        SELECT sr.rowid
          BULK COLLECT
          INTO l_rowids
          FROM schedule_sr sr
         WHERE sr.id_episode = i_id_episode;
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
    
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
            RETURN FALSE;
    END set_cancel_epis_surg_proc;

    /*******************************************************************************************************************************************
    * cancel_assoc_icnp_interv        De-associate Integration of Therapeutic Attitudes
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_SR_EPIS_INTERV      ID of Surgery episode intervention
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          03-Mar-2011
    *******************************************************************************************************************************************/
    FUNCTION cancel_assoc_icnp_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_icnp_interv EXCEPTION;
    BEGIN
        pk_icnp_fo_api_db.set_sugg_status_cancel(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_request_id   => i_id_sr_epis_interv,
                                                 i_task_type_id => pk_alert_constant.g_task_sr_procedures,
                                                 i_sysdate_tstz => g_sysdate_tstz);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'ERROR ON PK_ICNP_FO_API_DB.SET_SUGG_STATUS_CANCEL: ' ||
                                              i_id_sr_epis_interv || ' ' || SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ASSOC_ICNP_INTERV',
                                              o_error);
            RETURN FALSE;
    END cancel_assoc_icnp_interv;

    /*******************************************************************************************************************************************
    * create_assoc_icnp_interv        Associate Integration of Therapeutic Attitudes
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_SR_EPIS_INTERV      ID of Surgery episode intervention
    * @param I_ID_EPISODE             ID of episode
    * @param I_ID_SR_INTERVENTION     ID of Surgery intervention
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          03-Mar-2011
    *******************************************************************************************************************************************/
    FUNCTION create_assoc_icnp_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_sr_intervention IN intervention.id_intervention%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_icnp_sug_interv table_number;
        l_icnp_interv        EXCEPTION;
    BEGIN
        pk_icnp_fo_api_db.create_sugg(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_id_episode         => i_id_episode,
                                      i_request_id         => i_id_sr_epis_interv,
                                      i_task_id            => i_id_sr_intervention,
                                      i_task_type_id       => pk_alert_constant.g_task_sr_procedures,
                                      i_sysdate_tstz       => g_sysdate_tstz,
                                      o_id_icnp_sug_interv => l_id_icnp_sug_interv);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'ERROR ON PK_ICNP_FO_API_DB.CREATE_SUGG: ' || i_id_sr_epis_interv || ' ' ||
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_ASSOC_ICNP_INTERV',
                                              o_error);
            RETURN FALSE;
    END create_assoc_icnp_interv;
    /**************************************************************************
    * Check if exists an principal interv for the episode
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Id episode
    *
    * @param o_flg_principal            Y/N
    * @param o_error                   error description
    *
    * @author                         Rita Lopes
    * @version                        2.5
    * @since                          2011/10/20
    **************************************************************************/

    FUNCTION check_epis_interv_principal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN sr_epis_interv.id_episode_context%TYPE,
        o_id_sr_epis_interv OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_flg_principal     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         VARCHAR2(30) := 'CHECK_EPIS_INTERV_PRINCIPAL';
        l_desc_principal    VARCHAR2(4000);
        l_id_sr_epis_interv sr_epis_interv.id_sr_epis_interv%TYPE;
    
    BEGIN
    
        g_error := 'Check principal interv for the episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        --get information about the surgical procedure
        BEGIN
            SELECT sei.id_sr_epis_interv,
                   decode(sei.flg_code_type,
                          'U',
                          sei.name_interv || ' (' || pk_message.get_message(1, 'SR_UNCODED_LABEL_M001') || ')',
                          pk_translation.get_translation(i_lang,
                                                         'INTERVENTION.CODE_INTERVENTION.' || sei.id_sr_intervention) ||
                          decode(ic.standard_code, NULL, '', ' / ') || to_char(ic.standard_code))
              INTO l_id_sr_epis_interv, l_desc_principal
              FROM sr_epis_interv sei, interv_codification ic
             WHERE sei.id_episode = i_id_episode
               AND sei.flg_status != g_cancel
               AND sei.flg_type = g_flg_type_p
               AND sei.id_interv_codification = ic.id_interv_codification(+);
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sr_epis_interv := NULL;
                l_desc_principal    := NULL;
        END;
    
        o_id_sr_epis_interv := l_id_sr_epis_interv;
        o_flg_principal     := l_desc_principal;
    
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
            RETURN FALSE;
    END check_epis_interv_principal;

    /********************************************************************************************
    * Get surgical procedures summary page
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_context       Identifier of the Episode/Patient based on the i_flg_type
    * @param i_flg_type_context Flag to filter by Episode (E) or by Patient (P)
    * @param o_interv           Data cursor
    * @param o_labels           Labels cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   António Neto
    * @version                  2.6.1
    * @since                    2011-04-08
    *
    *********************************************************************************************/
    FUNCTION get_summ_interv_api
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_context                IN NUMBER,
        i_flg_type_context          IN VARCHAR2,
        o_interv                    OUT pk_types.cursor_type,
        o_labels                    OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_uncoded_label_m001    VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_M001');
        l_uncoded_label_m002    VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_M002');
        l_id_sr_surgery_time_ic sr_surgery_time.id_sr_surgery_time%TYPE;
        l_id_sr_surgery_time_fc sr_surgery_time.id_sr_surgery_time%TYPE;
        l_id_sr_interv          table_number;
    
    BEGIN
    
        g_error := 'OPEN O_LABELS';
        OPEN o_labels FOR
            SELECT pk_message.get_message(i_lang, 'SURG_PROC_T009') lbl_interv,
                   pk_message.get_message(i_lang, 'SURG_PROC_T003') lbl_diagnosis,
                   pk_message.get_message(i_lang, 'SURG_PROC_T010') lbl_supplies,
                   pk_message.get_message(i_lang, 'SURG_PROC_T011') lbl_desc_interv,
                   pk_message.get_message(i_lang, 'SURG_PROC_T012') lbl_notes,
                   pk_message.get_message(i_lang, 'SURG_PROC_T004') lbl_laterality,
                   pk_message.get_message(i_lang, 'PROCEDURES_T189') lbl_surgical_site,
                   pk_message.get_message(i_lang, 'SR_LABEL_T402') lbl_principal,
                   pk_message.get_message(i_lang, 'SR_LABEL_T403') lbl_team,
                   pk_message.get_message(i_lang, 'SR_LABEL_T363') lbl_notes_cancel,
                   pk_message.get_message(i_lang, 'SR_LABEL_T114') lbl_cancel_reason,
                   pk_message.get_message(i_lang, 'SR_LABEL_T345') lbl_cancel,
                   pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_M003') lbl_outdated,
                   pk_message.get_message(i_lang, 'COMMON_M129') lbl_not_order_reason,
                   pk_message.get_message(i_lang, 'SURGERY_REQUEST_T040') lbl_mod_fact
              FROM dual;
    
        g_error := 'READ ID FOR SURGERY START TIME';
        SELECT sst_in.id_sr_surgery_time
          INTO l_id_sr_surgery_time_ic
          FROM sr_surgery_time sst_in
         WHERE sst_in.flg_type = g_surg_time_ic
           AND sst_in.flg_available = pk_alert_constant.g_yes;
    
        g_error := 'READ ID FOR SURGERY END TIME';
        SELECT sst_out.id_sr_surgery_time
          INTO l_id_sr_surgery_time_fc
          FROM sr_surgery_time sst_out
         WHERE sst_out.flg_type = g_surg_time_fc
           AND sst_out.flg_available = pk_alert_constant.g_yes;
    
        g_error := 'OPEN O_INTERV';
        OPEN o_interv FOR
        -- all current surgical procedures updated, uncoded etc
            SELECT t_list.id_sr_epis_interv,
                   t_list.id_sr_intervention,
                   t_list.laterality,
                   t_list.flg_laterality,
                   t_list.diagnosis,
                   t_list.id_diagnosis,
                   t_list.notes,
                   t_list.flg_status,
                   t_list.flg_surg_request,
                   t_list.dt_req,
                   t_list.dt_req_comp,
                   t_list.nick_name,
                   t_list.desc_speciality,
                   t_list.desc_interv,
                   t_list.ordered,
                   t_list.ordered_date,
                   t_list.id_professional,
                   t_list.cancel_reason,
                   t_list.notes_cancel,
                   t_list.supplies,
                   t_list.epis_flg_status,
                   t_list.code_icd,
                   t_list.flg_coding,
                   t_list.interv_desc1 interv,
                   t_list.interv_desc1 || t_list.interv_desc2 interv_desc,
                   CASE
                        WHEN t_list.id_not_order_reason IS NOT NULL THEN
                         g_sei_flg_status_n
                        ELSE
                         t_list.sr_epis_flg_status
                    END sr_epis_flg_status,
                   dt_sr_start_date,
                   dt_sr_end_date,
                   pk_date_utils.dt_chr(i_lang, dt_sr_start_date, i_prof.institution, i_prof.software) sr_start_date,
                   pk_date_utils.date_send_tsz(i_lang, dt_sr_start_date, i_prof) sr_start_date_str,
                   pk_date_utils.date_char_tsz(i_lang, dt_sr_end_date, i_prof.institution, i_prof.software) sr_end_date,
                   pk_date_utils.date_send_tsz(i_lang, dt_sr_end_date, i_prof) sr_end_date_str,
                   CASE
                        WHEN t_list.id_not_order_reason IS NOT NULL THEN
                         pk_sysdomain.get_domain(g_sei_flg_status, g_sei_flg_status_n, i_lang)
                        ELSE
                         t_list.sr_epis_flg_status_str
                    END sr_epis_flg_status_str,
                   t_list.flg_type_desc,
                   t_list.flg_type,
                   t_list.team,
                   t_list.desc_team,
                   t_list.id_not_order_reason,
                   t_list.desc_not_order_reason,
                   t_list.surg_proc_mod_fact_desc,
                   t_list.surg_proc_mod_fact_ids,
                   t_list.dep_clin_serv,
                   t_list.surgical_site,
                   t_list.surgical_site_desc
              FROM (WITH epis_w AS (SELECT *
                                      FROM episode e
                                     WHERE i_flg_type_context = g_flg_type_context_epis_e
                                       AND e.id_episode = i_id_context
                                    UNION
                                    SELECT *
                                      FROM episode e
                                     WHERE i_flg_type_context = g_flg_type_context_pat_p
                                       AND e.id_patient = i_id_context
                                       AND e.flg_status = g_flg_status_epis_inactive_i), --
                   epis_main_w AS (SELECT *
                                     FROM episode e
                                    WHERE i_flg_type_context = g_flg_type_context_epis_e
                                      AND e.id_episode = i_id_context
                                   UNION
                                   SELECT *
                                     FROM episode e
                                    WHERE i_flg_type_context = g_flg_type_context_pat_p
                                      AND e.id_patient = i_id_context
                                      AND e.flg_status IN (pk_alert_constant.g_epis_status_inactive,
                                                           pk_alert_constant.g_epis_status_active))
                       SELECT sei.id_sr_epis_interv id_sr_epis_interv,
                              si.id_intervention id_sr_intervention,
                              CASE
                                   WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                    sei.name_interv
                                   ELSE
                                    pk_translation.get_translation(i_lang, si.code_intervention)
                               END interv_desc1,
                              CASE
                                   WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                    ' (' || l_uncoded_label_m001 || ') '
                                   ELSE
                                    decode(sei.id_interv_codification,
                                           NULL,
                                           '',
                                           pk_procedures_utils.get_procedure_with_codification(i_lang,
                                                                                               i_prof,
                                                                                               si.id_intervention,
                                                                                               NULL))
                               END interv_desc2,
                              pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) laterality,
                              sei.laterality flg_laterality,
                              (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_diagnosis       => d.id_diagnosis,
                                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                 i_code_diagnosis     => ad.code_alert_diagnosis,
                                                                 i_code               => d.code_icd,
                                                                 i_flg_other          => d.flg_other,
                                                                 i_flg_std_diag       => pk_alert_constant.g_yes)
                                 FROM diagnosis d
                                 LEFT JOIN alert_diagnosis ad
                                   ON ad.id_diagnosis = d.id_diagnosis
                                WHERE d.id_diagnosis = ed.id_diagnosis
                                  AND ad.id_alert_diagnosis = ed.id_alert_diagnosis) diagnosis,
                              ed.id_diagnosis,
                              sei.notes,
                              (CASE
                                   WHEN sei.flg_code_type = g_flg_code_type_c THEN
                                    g_value_p
                                   ELSE
                                    g_flg_code_type_u
                               END) flg_status,
                              nvl(sei.flg_surg_request, pk_alert_constant.g_no) flg_surg_request,
                              decode(descr.dt_interv_desc_tstz,
                                     NULL,
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 sei.dt_req_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software),
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 descr.dt_interv_desc_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)) dt_req,
                              decode(descr.dt_interv_desc_tstz,
                                     NULL,
                                     pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof),
                                     pk_date_utils.date_send_tsz(i_lang, descr.dt_interv_desc_tstz, i_prof)) dt_req_comp,
                              pk_prof_utils.get_name_signature(i_lang,
                                                               i_prof,
                                                               decode(descr.dt_interv_desc_tstz,
                                                                      NULL,
                                                                      sei.id_prof_req,
                                                                      descr.id_professional)) nick_name,
                              '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      decode(descr.dt_interv_desc_tstz,
                                                                             NULL,
                                                                             sei.id_prof_req,
                                                                             descr.id_professional),
                                                                      decode(descr.dt_interv_desc_tstz,
                                                                             NULL,
                                                                             sei.dt_req_tstz,
                                                                             descr.dt_interv_desc_tstz),
                                                                      sei.id_episode) || ')' desc_speciality,
                              descr.desc_interv desc_interv,
                              1 ordered,
                              decode(descr.dt_interv_desc_tstz, NULL, sei.dt_req_tstz, descr.dt_interv_desc_tstz) ordered_date,
                              decode(descr.dt_interv_desc_tstz, NULL, sei.id_prof_req, descr.id_professional) id_professional,
                              NULL cancel_reason,
                              sei.notes_cancel,
                              pk_supplies_external_api_db.get_supplies_request(i_lang,
                                                                               i_prof,
                                                                               sei.id_sr_epis_interv,
                                                                               pk_supplies_constant.g_context_surgery) supplies,
                              epis.flg_status epis_flg_status,
                              ic.standard_code code_icd,
                              1 flg_interv_desc_type,
                              decode(sei.flg_code_type, g_flg_code_type_c, g_flg_type_p, g_flg_code_type_u) flg_coding,
                              sei.flg_status sr_epis_flg_status,
                              nvl(sstd_in.dt_surgery_time_det_tstz, epis.dt_begin_tstz) dt_sr_start_date,
                              nvl(sstd_out.dt_surgery_time_det_tstz,
                                  pk_discharge.get_discharge_date(i_lang, i_prof, epis.id_episode)) dt_sr_end_date,
                              pk_sysdomain.get_domain(g_sei_flg_status, sei.flg_status, i_lang) sr_epis_flg_status_str,
                              pk_sysdomain.get_domain(g_sei_flg_type, sei.flg_type, i_lang) flg_type_desc,
                              sei.flg_type,
                              pk_sr_tools.get_sr_interv_team(i_lang,
                                                             i_prof,
                                                             sei.id_episode_context,
                                                             sei.id_sr_epis_interv) team,
                              pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, sei.id_sr_epis_interv) desc_team,
                              CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content,
                              pk_not_order_reason_db.get_not_order_reason_id(i_lang, sei.id_not_order_reason) id_not_order_reason,
                              pk_not_order_reason_db.get_not_order_reason_desc(i_lang, sei.id_not_order_reason) desc_not_order_reason,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_order,
                              pk_sr_planning.get_surg_proc_mod_fact_desc(i_lang, i_prof, sei.id_sr_epis_interv, NULL) surg_proc_mod_fact_desc,
                              pk_sr_planning.get_surg_proc_mod_fact_ids(i_lang, i_prof, sei.id_sr_epis_interv, NULL) surg_proc_mod_fact_ids,
                              dps.id_dep_clin_serv dep_clin_serv,
                              sei.surgical_site,
                              pk_message.get_message(i_lang, 'PROCEDURES_T189') surgical_site_desc
                         FROM epis_main_w epis
                        INNER JOIN sr_epis_interv sei
                           ON epis.id_episode = sei.id_episode_context
                         LEFT OUTER JOIN epis_diagnosis ed
                           ON ed.id_epis_diagnosis = sei.id_epis_diagnosis
                         LEFT OUTER JOIN (SELECT id_sr_epis_interv, desc_interv, dt_interv_desc_tstz, id_professional
                                            FROM sr_epis_interv_desc sepd
                                           INNER JOIN epis_w epis
                                              ON sepd.id_episode_context = epis.id_episode
                                           WHERE sepd.flg_type = g_surg_interv
                                             AND sepd.flg_status != g_interv_can
                                             AND sepd.id_sr_epis_interv_desc =
                                                 (SELECT MAX(id_sr_epis_interv_desc)
                                                    FROM sr_epis_interv_desc sreid
                                                   WHERE sreid.id_episode_context = epis.id_episode
                                                     AND sreid.id_sr_epis_interv = sepd.id_sr_epis_interv)) descr
                           ON sei.id_sr_epis_interv = descr.id_sr_epis_interv
                         LEFT OUTER JOIN intervention si
                           ON sei.id_sr_intervention = si.id_intervention
                         LEFT OUTER JOIN interv_codification ic
                           ON ic.id_interv_codification = sei.id_interv_codification
                         LEFT OUTER JOIN sr_surgery_time_det sstd_in
                           ON sei.id_episode = sstd_in.id_episode
                          AND sstd_in.flg_status = pk_alert_constant.g_active
                          AND sstd_in.id_sr_surgery_time = l_id_sr_surgery_time_ic
                         LEFT OUTER JOIN sr_surgery_time_det sstd_out
                           ON sei.id_episode = sstd_out.id_episode
                          AND sstd_out.flg_status = pk_alert_constant.g_active
                          AND sstd_out.id_sr_surgery_time = l_id_sr_surgery_time_fc
                         LEFT JOIN episode sre
                           ON sre.id_episode = sei.id_episode_context
                         LEFT JOIN dep_clin_serv dps
                           ON dps.id_clinical_service = sre.id_clinical_service
                          AND dps.id_department = sre.id_department
                          AND dps.flg_available = pk_alert_constant.g_available
                        WHERE sei.flg_status != pk_alert_constant.g_cancelled
                       UNION ALL
                       -- Outdated
                       SELECT sei.id_sr_epis_interv id_sr_epis_interv,
                              si.id_intervention id_sr_intervention,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   sei.name_interv
                                  ELSE
                                   pk_translation.get_translation(i_lang, si.code_intervention)
                              END interv_desc1,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   ' (' || l_uncoded_label_m001 || ') '
                                  ELSE
                                   decode(sei.id_interv_codification,
                                          NULL,
                                          '',
                                          pk_procedures_utils.get_procedure_with_codification(i_lang,
                                                                                              i_prof,
                                                                                              si.id_intervention,
                                                                                              NULL))
                              END interv_desc2,
                              pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) laterality,
                              sei.laterality flg_laterality,
                              (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_diagnosis       => d.id_diagnosis,
                                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                 i_code_diagnosis     => ad.code_alert_diagnosis,
                                                                 i_code               => d.code_icd,
                                                                 i_flg_other          => d.flg_other,
                                                                 i_flg_std_diag       => pk_alert_constant.g_yes)
                                 FROM diagnosis d
                                 LEFT JOIN alert_diagnosis ad
                                   ON ad.id_diagnosis = d.id_diagnosis
                                WHERE d.id_diagnosis = ed.id_diagnosis
                                  AND ad.id_alert_diagnosis = ed.id_alert_diagnosis) diagnosis,
                              ed.id_diagnosis,
                              sei.notes,
                              g_flg_type_o flg_status,
                              nvl(sei.flg_surg_request, pk_alert_constant.g_no) flg_surg_request,
                              pk_date_utils.date_char_tsz(i_lang,
                                                          sei.dt_req_unc_tstz,
                                                          i_prof.institution,
                                                          i_prof.software) dt_req,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_req_unc_tstz, i_prof) dt_req_comp,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, sei.id_prof_req_unc) nick_name,
                              '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      sei.id_prof_req_unc,
                                                                      sei.dt_req_tstz,
                                                                      sei.id_episode) || ')' desc_speciality,
                              NULL desc_interv,
                              2 ordered,
                              sei.dt_req_unc_tstz ordered_date,
                              sei.id_prof_req_unc id_professional,
                              NULL cancel_reason,
                              sei.notes_cancel,
                              pk_supplies_external_api_db.get_supplies_request(i_lang,
                                                                               i_prof,
                                                                               sei.id_sr_epis_interv,
                                                                               pk_supplies_constant.g_context_surgery) supplies,
                              epis.flg_status epis_flg_status,
                              ic.standard_code code_icd,
                              2 flg_interv_desc_type,
                              decode(sei.flg_code_type, g_flg_code_type_c, g_flg_type_p, g_flg_code_type_u) flg_coding,
                              sei.flg_status sr_epis_flg_status,
                              nvl(sstd_in.dt_surgery_time_det_tstz, epis.dt_begin_tstz) dt_sr_start_date,
                              nvl(sstd_out.dt_surgery_time_det_tstz,
                                  pk_discharge.get_discharge_date(i_lang, i_prof, epis.id_episode)) dt_sr_end_date,
                              pk_sysdomain.get_domain(g_sei_flg_status, sei.flg_status, i_lang) sr_epis_flg_status_str,
                              pk_sysdomain.get_domain(g_sei_flg_type, sei.flg_type, i_lang) flg_type_desc,
                              sei.flg_type,
                              pk_sr_tools.get_sr_interv_team(i_lang,
                                                             i_prof,
                                                             sei.id_episode_context,
                                                             sei.id_sr_epis_interv) team,
                              pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, sei.id_sr_epis_interv) desc_team,
                              CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content,
                              pk_not_order_reason_db.get_not_order_reason_id(i_lang, sei.id_not_order_reason) id_not_order_reason,
                              pk_not_order_reason_db.get_not_order_reason_desc(i_lang, sei.id_not_order_reason) desc_not_order_reason,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_order,
                              pk_sr_planning.get_surg_proc_mod_fact_desc(i_lang,
                                                                         i_prof,
                                                                         NULL,
                                                                         sei.id_sr_epis_interv_hist) surg_proc_mod_fact_desc,
                              pk_sr_planning.get_surg_proc_mod_fact_ids(i_lang, i_prof, NULL, sei.id_sr_epis_interv_hist) surg_proc_mod_fact_ids,
                              dps.id_dep_clin_serv dep_clin_serv,
                              sei.surgical_site,
                              pk_message.get_message(i_lang, 'PROCEDURES_T189') surgical_site_desc
                         FROM epis_main_w epis
                        INNER JOIN sr_epis_interv_hist sei
                           ON epis.id_episode = sei.id_episode_context
                         LEFT OUTER JOIN epis_diagnosis ed
                           ON ed.id_epis_diagnosis = sei.id_epis_diagnosis
                         LEFT OUTER JOIN intervention si
                           ON sei.id_sr_intervention = si.id_intervention
                         LEFT OUTER JOIN interv_codification ic
                           ON ic.id_interv_codification = sei.id_interv_codification
                         LEFT OUTER JOIN sr_surgery_time_det sstd_in
                           ON sei.id_episode = sstd_in.id_episode
                          AND sstd_in.flg_status = pk_alert_constant.g_active
                          AND sstd_in.id_sr_surgery_time = l_id_sr_surgery_time_ic
                         LEFT OUTER JOIN sr_surgery_time_det sstd_out
                           ON sei.id_episode = sstd_out.id_episode
                          AND sstd_out.flg_status = pk_alert_constant.g_active
                          AND sstd_out.id_sr_surgery_time = l_id_sr_surgery_time_fc
                         LEFT JOIN episode sre
                           ON sre.id_episode = sei.id_episode_context
                         LEFT JOIN dep_clin_serv dps
                           ON dps.id_clinical_service = sre.id_clinical_service
                          AND dps.id_department = sre.id_department
                          AND dps.flg_available = pk_alert_constant.g_available
                        WHERE sei.flg_code_type = g_flg_code_type_c
                          AND sei.name_interv IS NOT NULL
                       -- All  procedures that might had been cancelled
                       UNION ALL
                       SELECT sei.id_sr_epis_interv id_sr_epis_interv,
                              si.id_intervention id_sr_intervention,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   sei.name_interv
                                  ELSE
                                   pk_translation.get_translation(i_lang, si.code_intervention)
                              END interv_desc1,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   ' (' || l_uncoded_label_m001 || ') '
                                  ELSE
                                   decode(sei.id_interv_codification,
                                          NULL,
                                          '',
                                          pk_procedures_utils.get_procedure_with_codification(i_lang,
                                                                                              i_prof,
                                                                                              si.id_intervention,
                                                                                              NULL))
                              END interv_desc2,
                              pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) laterality,
                              sei.laterality flg_laterality,
                              (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_diagnosis       => d.id_diagnosis,
                                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                 i_code_diagnosis     => ad.code_alert_diagnosis,
                                                                 i_code               => d.code_icd,
                                                                 i_flg_other          => d.flg_other,
                                                                 i_flg_std_diag       => pk_alert_constant.g_yes)
                                 FROM diagnosis d
                                 LEFT JOIN alert_diagnosis ad
                                   ON ad.id_diagnosis = d.id_diagnosis
                                WHERE d.id_diagnosis = ed.id_diagnosis
                                  AND ad.id_alert_diagnosis = ed.id_alert_diagnosis) diagnosis,
                              ed.id_diagnosis,
                              sei.notes,
                              g_interv_can flg_status,
                              nvl(sei.flg_surg_request, pk_alert_constant.g_no) flg_surg_request,
                              pk_date_utils.date_char_tsz(i_lang,
                                                          sei.dt_cancel_tstz,
                                                          i_prof.institution,
                                                          i_prof.software) dt_req,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_cancel_tstz, i_prof) dt_req_comp,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, sei.id_prof_cancel) nick_name,
                              '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      sei.id_prof_cancel,
                                                                      sei.dt_req_tstz,
                                                                      sei.id_episode) || ')' desc_speciality,
                              NULL desc_interv,
                              2 ordered,
                              sei.dt_cancel_tstz ordered_date,
                              sei.id_prof_cancel id_prof,
                              pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                              sei.notes_cancel,
                              pk_supplies_external_api_db.get_supplies_request(i_lang,
                                                                               i_prof,
                                                                               sei.id_sr_epis_interv,
                                                                               pk_supplies_constant.g_context_surgery) supplies,
                              epis.flg_status epis_flg_status,
                              ic.standard_code code_icd,
                              3 flg_interv_desc_type,
                              decode(sei.flg_code_type, g_flg_code_type_c, g_flg_type_p, g_flg_code_type_u) flg_coding,
                              sei.flg_status sr_epis_flg_status,
                              nvl(sstd_in.dt_surgery_time_det_tstz, epis.dt_begin_tstz) dt_sr_start_date,
                              nvl(sstd_out.dt_surgery_time_det_tstz,
                                  pk_discharge.get_discharge_date(i_lang, i_prof, epis.id_episode)) dt_sr_end_date,
                              pk_sysdomain.get_domain(g_sei_flg_status, sei.flg_status, i_lang) sr_epis_flg_status_str,
                              pk_sysdomain.get_domain(g_sei_flg_type, sei.flg_type, i_lang) flg_type_desc,
                              sei.flg_type,
                              pk_sr_tools.get_sr_interv_team(i_lang,
                                                             i_prof,
                                                             sei.id_episode_context,
                                                             sei.id_sr_epis_interv) team,
                              pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, sei.id_sr_epis_interv) desc_team,
                              CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content,
                              pk_not_order_reason_db.get_not_order_reason_id(i_lang, sei.id_not_order_reason) id_not_order_reason,
                              pk_not_order_reason_db.get_not_order_reason_desc(i_lang, sei.id_not_order_reason) desc_not_order_reason,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_order,
                              pk_sr_planning.get_surg_proc_mod_fact_desc(i_lang, i_prof, sei.id_sr_epis_interv, NULL) surg_proc_mod_fact_desc,
                              pk_sr_planning.get_surg_proc_mod_fact_ids(i_lang, i_prof, sei.id_sr_epis_interv, NULL) surg_proc_mod_fact_ids,
                              dps.id_dep_clin_serv dep_clin_serv,
                              sei.surgical_site,
                              pk_message.get_message(i_lang, 'PROCEDURES_T189') surgical_site_desc
                         FROM epis_main_w epis
                        INNER JOIN sr_epis_interv sei
                           ON epis.id_episode = sei.id_episode_context
                         LEFT OUTER JOIN epis_diagnosis ed
                           ON ed.id_epis_diagnosis = sei.id_epis_diagnosis
                         LEFT OUTER JOIN intervention si
                           ON sei.id_sr_intervention = si.id_intervention
                         LEFT OUTER JOIN interv_codification ic
                           ON ic.id_interv_codification = sei.id_interv_codification
                         LEFT OUTER JOIN cancel_reason cr
                           ON sei.id_sr_cancel_reason = cr.id_cancel_reason
                         LEFT OUTER JOIN sr_surgery_time_det sstd_in
                           ON sei.id_episode = sstd_in.id_episode
                          AND sstd_in.flg_status = pk_alert_constant.g_active
                          AND sstd_in.id_sr_surgery_time = l_id_sr_surgery_time_ic
                         LEFT OUTER JOIN sr_surgery_time_det sstd_out
                           ON sei.id_episode = sstd_out.id_episode
                          AND sstd_out.flg_status = pk_alert_constant.g_active
                          AND sstd_out.id_sr_surgery_time = l_id_sr_surgery_time_fc
                         LEFT JOIN episode sre
                           ON sre.id_episode = sei.id_episode_context
                         LEFT JOIN dep_clin_serv dps
                           ON dps.id_clinical_service = sre.id_clinical_service
                          AND dps.id_department = sre.id_department
                          AND dps.flg_available = pk_alert_constant.g_available
                        WHERE sei.flg_status = pk_alert_constant.g_cancelled
                       -- all surgical procedures whose descriptions might had been updated
                       UNION ALL
                       SELECT sei.id_sr_epis_interv id_sr_epis_interv,
                              si.id_intervention id_sr_intervention,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   sei.name_interv
                                  WHEN (descr.dt_interv_desc_tstz > sei.dt_req_unc_tstz AND
                                       descr.dt_interv_desc_tstz < sei.dt_req_tstz) THEN
                                   sei.name_interv
                                  WHEN descr.dt_interv_desc_tstz > sei.dt_req_tstz THEN
                                   pk_translation.get_translation(i_lang, si.code_intervention)
                              END interv_desc1,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   ' (' || l_uncoded_label_m001 || ') '
                                  WHEN (descr.dt_interv_desc_tstz > sei.dt_req_unc_tstz AND
                                       descr.dt_interv_desc_tstz < sei.dt_req_tstz) THEN
                                   ' (' || l_uncoded_label_m001 || ') '
                                  WHEN descr.dt_interv_desc_tstz > sei.dt_req_tstz THEN
                                   decode(sei.id_interv_codification,
                                          NULL,
                                          '',
                                          pk_procedures_utils.get_procedure_with_codification(i_lang,
                                                                                              i_prof,
                                                                                              si.id_intervention,
                                                                                              NULL))
                              END interv_desc2,
                              pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) laterality,
                              sei.laterality flg_laterality,
                              (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_diagnosis       => d.id_diagnosis,
                                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                 i_code_diagnosis     => ad.code_alert_diagnosis,
                                                                 i_code               => d.code_icd,
                                                                 i_flg_other          => d.flg_other,
                                                                 i_flg_std_diag       => pk_alert_constant.g_yes)
                                 FROM diagnosis d
                                 LEFT JOIN alert_diagnosis ad
                                   ON ad.id_diagnosis = d.id_diagnosis
                                WHERE d.id_diagnosis = ed.id_diagnosis
                                  AND ad.id_alert_diagnosis = ed.id_alert_diagnosis) diagnosis,
                              ed.id_diagnosis,
                              sei.notes,
                              'O' flg_status,
                              nvl(sei.flg_surg_request, pk_alert_constant.g_no) flg_surg_request,
                              pk_date_utils.date_char_tsz(i_lang,
                                                          decode(descr.dt_interv_desc_tstz,
                                                                 NULL,
                                                                 sei.dt_req_tstz,
                                                                 descr.dt_interv_desc_tstz),
                                                          i_prof.institution,
                                                          i_prof.software) dt_req,
                              pk_date_utils.date_send_tsz(i_lang,
                                                          decode(descr.dt_interv_desc_tstz,
                                                                 NULL,
                                                                 sei.dt_req_tstz,
                                                                 descr.dt_interv_desc_tstz),
                                                          i_prof) dt_req_comp,
                              pk_prof_utils.get_name_signature(i_lang,
                                                               i_prof,
                                                               decode(descr.dt_interv_desc_tstz,
                                                                      NULL,
                                                                      sei.id_prof_req,
                                                                      descr.id_professional)) nick_name,
                              '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      decode(descr.dt_interv_desc_tstz,
                                                                             NULL,
                                                                             sei.id_prof_req,
                                                                             descr.id_professional),
                                                                      decode(descr.dt_interv_desc_tstz,
                                                                             NULL,
                                                                             sei.dt_req_tstz,
                                                                             descr.dt_interv_desc_tstz),
                                                                      sei.id_episode) || ')' desc_speciality,
                              descr.desc_interv desc_interv,
                              2 ordered,
                              decode(descr.dt_interv_desc_tstz, NULL, sei.dt_req_tstz, descr.dt_interv_desc_tstz) ordered_date,
                              decode(descr.dt_interv_desc_tstz, NULL, sei.id_prof_req, descr.id_professional) id_professional,
                              NULL cancel_reason,
                              NULL notes_cancel,
                              pk_supplies_external_api_db.get_supplies_request(i_lang,
                                                                               i_prof,
                                                                               sei.id_sr_epis_interv,
                                                                               pk_supplies_constant.g_context_surgery) supplies,
                              epis.flg_status epis_flg_status,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_c
                                       AND descr.dt_interv_desc_tstz > sei.dt_req_tstz THEN
                                   ic.standard_code
                                  ELSE
                                   NULL
                              END code_icd,
                              4 flg_interv_desc_type,
                              decode(sei.flg_code_type, g_flg_code_type_c, g_flg_type_p, g_flg_code_type_u) flg_coding,
                              sei.flg_status sr_epis_flg_status,
                              nvl(sstd_in.dt_surgery_time_det_tstz, epis.dt_begin_tstz) dt_sr_start_date,
                              nvl(sstd_out.dt_surgery_time_det_tstz,
                                  pk_discharge.get_discharge_date(i_lang, i_prof, epis.id_episode)) dt_sr_end_date,
                              pk_sysdomain.get_domain(g_sei_flg_status, sei.flg_status, i_lang) sr_epis_flg_status_str,
                              pk_sysdomain.get_domain(g_sei_flg_type, sei.flg_type, i_lang) flg_type_desc,
                              sei.flg_type,
                              pk_sr_tools.get_sr_interv_team(i_lang,
                                                             i_prof,
                                                             sei.id_episode_context,
                                                             sei.id_sr_epis_interv) team,
                              pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, sei.id_sr_epis_interv) desc_team,
                              CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content,
                              pk_not_order_reason_db.get_not_order_reason_id(i_lang, sei.id_not_order_reason) id_not_order_reason,
                              pk_not_order_reason_db.get_not_order_reason_desc(i_lang, sei.id_not_order_reason) desc_not_order_reason,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_order,
                              pk_sr_planning.get_surg_proc_mod_fact_desc(i_lang, i_prof, sei.id_sr_epis_interv, NULL) surg_proc_mod_fact_desc,
                              pk_sr_planning.get_surg_proc_mod_fact_ids(i_lang, i_prof, sei.id_sr_epis_interv, NULL) surg_proc_mod_fact_ids,
                              dps.id_dep_clin_serv dep_clin_serv,
                              sei.surgical_site,
                              pk_message.get_message(i_lang, 'PROCEDURES_T189') surgical_site_desc
                         FROM epis_main_w epis
                        INNER JOIN sr_epis_interv sei
                           ON epis.id_episode = sei.id_episode_context
                         LEFT OUTER JOIN epis_diagnosis ed
                           ON ed.id_epis_diagnosis = sei.id_epis_diagnosis
                        INNER JOIN (SELECT sepd.id_sr_epis_interv,
                                           sepd.desc_interv,
                                           sepd.flg_status,
                                           sepd.dt_interv_desc_tstz,
                                           sepd.id_professional
                                      FROM sr_epis_interv_desc sepd
                                     INNER JOIN epis_w epis
                                        ON sepd.id_episode_context = epis.id_episode
                                     WHERE sepd.flg_type = g_surg_interv
                                          -- gets all records about descriptions referring to surgical procedures which may be
                                          -- outdated or cancelled, if outdated they will all be displayed
                                       AND (sepd.flg_status = pk_alert_constant.g_cancelled OR
                                           (sepd.flg_status != pk_alert_constant.g_cancelled AND
                                           sepd.id_sr_epis_interv_desc <
                                           (SELECT MAX(id_sr_epis_interv_desc)
                                                FROM sr_epis_interv_desc sreid
                                               WHERE sreid.id_episode_context = epis.id_episode
                                                 AND sreid.id_sr_epis_interv = sepd.id_sr_epis_interv)))) descr
                           ON sei.id_sr_epis_interv = descr.id_sr_epis_interv
                         LEFT OUTER JOIN intervention si
                           ON sei.id_sr_intervention = si.id_intervention
                         LEFT OUTER JOIN interv_codification ic
                           ON ic.id_interv_codification = sei.id_interv_codification
                         LEFT OUTER JOIN sr_surgery_time_det sstd_in
                           ON sei.id_episode = sstd_in.id_episode
                          AND sstd_in.flg_status = pk_alert_constant.g_active
                          AND sstd_in.id_sr_surgery_time = l_id_sr_surgery_time_ic
                         LEFT OUTER JOIN sr_surgery_time_det sstd_out
                           ON sei.id_episode = sstd_out.id_episode
                          AND sstd_out.flg_status = pk_alert_constant.g_active
                          AND sstd_out.id_sr_surgery_time = l_id_sr_surgery_time_fc
                         LEFT JOIN episode sre
                           ON sre.id_episode = sei.id_episode_context
                         LEFT JOIN dep_clin_serv dps
                           ON dps.id_clinical_service = sre.id_clinical_service
                          AND dps.id_department = sre.id_department
                          AND dps.flg_available = pk_alert_constant.g_available
                       UNION ALL
                       SELECT sei.id_sr_epis_interv id_sr_epis_interv,
                              si.id_intervention id_sr_intervention,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   sei.name_interv
                                  ELSE
                                   pk_translation.get_translation(i_lang, si.code_intervention)
                              END interv_desc1,
                              CASE
                                  WHEN sei.flg_code_type = g_flg_code_type_u THEN
                                   ' (' || l_uncoded_label_m001 || ') '
                                  ELSE
                                   decode(sei.id_interv_codification,
                                          NULL,
                                          '',
                                          pk_procedures_utils.get_procedure_with_codification(i_lang,
                                                                                              i_prof,
                                                                                              si.id_intervention,
                                                                                              NULL))
                              END interv_desc2,
                              pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', sei.laterality, i_lang) laterality,
                              sei.laterality flg_laterality,
                              (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_diagnosis       => d.id_diagnosis,
                                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                 i_code_diagnosis     => ad.code_alert_diagnosis,
                                                                 i_code               => d.code_icd,
                                                                 i_flg_other          => d.flg_other,
                                                                 i_flg_std_diag       => pk_alert_constant.g_yes)
                                 FROM diagnosis d
                                 LEFT JOIN alert_diagnosis ad
                                   ON ad.id_diagnosis = d.id_diagnosis
                                WHERE d.id_diagnosis = ed.id_diagnosis
                                  AND ad.id_alert_diagnosis = ed.id_alert_diagnosis) diagnosis,
                              ed.id_diagnosis,
                              sei.notes,
                              'O' flg_status,
                              nvl(sei.flg_surg_request, pk_alert_constant.g_no) flg_surg_request,
                              decode(descr.dt_interv_desc_tstz,
                                     NULL,
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 sei.dt_req_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software),
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 descr.dt_interv_desc_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)) dt_req,
                              decode(descr.dt_interv_desc_tstz,
                                     NULL,
                                     pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof),
                                     pk_date_utils.date_send_tsz(i_lang, descr.dt_interv_desc_tstz, i_prof)) dt_req_comp,
                              pk_prof_utils.get_name_signature(i_lang,
                                                               i_prof,
                                                               decode(descr.dt_interv_desc_tstz,
                                                                      NULL,
                                                                      sei.id_prof_req,
                                                                      descr.id_professional)) nick_name,
                              '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      decode(descr.dt_interv_desc_tstz,
                                                                             NULL,
                                                                             sei.id_prof_req,
                                                                             descr.id_professional),
                                                                      decode(descr.dt_interv_desc_tstz,
                                                                             NULL,
                                                                             sei.dt_req_tstz,
                                                                             descr.dt_interv_desc_tstz),
                                                                      sei.id_episode) || ')' desc_speciality,
                              descr.desc_interv desc_interv,
                              2 ordered,
                              decode(descr.dt_interv_desc_tstz, NULL, sei.dt_req_tstz, descr.dt_interv_desc_tstz) ordered_date,
                              decode(descr.dt_interv_desc_tstz, NULL, sei.id_prof_req, descr.id_professional) id_professional,
                              NULL cancel_reason,
                              sei.notes_cancel,
                              pk_supplies_external_api_db.get_supplies_request(i_lang,
                                                                               i_prof,
                                                                               sei.id_sr_epis_interv,
                                                                               pk_supplies_constant.g_context_surgery) supplies,
                              epis.flg_status epis_flg_status,
                              ic.standard_code code_icd,
                              1 flg_interv_desc_type,
                              decode(sei.flg_code_type, g_flg_code_type_c, g_flg_type_p, g_flg_code_type_u) flg_coding,
                              sei.flg_status sr_epis_flg_status,
                              nvl(sstd_in.dt_surgery_time_det_tstz, epis.dt_begin_tstz) dt_sr_start_date,
                              nvl(sstd_out.dt_surgery_time_det_tstz,
                                  pk_discharge.get_discharge_date(i_lang, i_prof, epis.id_episode)) dt_sr_end_date,
                              pk_sysdomain.get_domain(g_sei_flg_status, sei.flg_status, i_lang) sr_epis_flg_status_str,
                              pk_sysdomain.get_domain(g_sei_flg_type, sei.flg_type, i_lang) flg_type_desc,
                              sei.flg_type,
                              pk_sr_tools.get_sr_interv_team_hist(i_lang,
                                                                  i_prof,
                                                                  sei.id_episode_context,
                                                                  sei.id_sr_epis_interv_hist) team,
                              pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, sei.id_sr_epis_interv) desc_team,
                              CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content,
                              pk_not_order_reason_db.get_not_order_reason_id(i_lang, sei.id_not_order_reason) id_not_order_reason,
                              pk_not_order_reason_db.get_not_order_reason_desc(i_lang, sei.id_not_order_reason) desc_not_order_reason,
                              pk_date_utils.date_send_tsz(i_lang, sei.dt_req_tstz, i_prof) dt_order,
                              pk_sr_planning.get_surg_proc_mod_fact_desc(i_lang,
                                                                         i_prof,
                                                                         NULL,
                                                                         sei.id_sr_epis_interv_hist) surg_proc_mod_fact_desc,
                              pk_sr_planning.get_surg_proc_mod_fact_ids(i_lang, i_prof, NULL, sei.id_sr_epis_interv_hist) surg_proc_mod_fact_ids,
                              dps.id_dep_clin_serv dep_clin_serv,
                              sei.surgical_site,
                              pk_message.get_message(i_lang, 'PROCEDURES_T189') surgical_site_desc
                         FROM epis_main_w epis
                        INNER JOIN sr_epis_interv_hist sei
                           ON epis.id_episode = sei.id_episode_context
                         LEFT OUTER JOIN epis_diagnosis ed
                           ON ed.id_epis_diagnosis = sei.id_epis_diagnosis
                         LEFT OUTER JOIN (SELECT id_sr_epis_interv, desc_interv, dt_interv_desc_tstz, id_professional
                                            FROM sr_epis_interv_desc sepd
                                           INNER JOIN epis_w epis
                                              ON sepd.id_episode_context = epis.id_episode
                                           WHERE sepd.flg_type = g_surg_interv
                                             AND sepd.flg_status != pk_alert_constant.g_cancelled
                                             AND sepd.id_sr_epis_interv_desc =
                                                 (SELECT MAX(id_sr_epis_interv_desc)
                                                    FROM sr_epis_interv_desc sreid
                                                   WHERE sreid.id_episode_context = epis.id_episode
                                                     AND sreid.id_sr_epis_interv = sepd.id_sr_epis_interv)) descr
                           ON sei.id_sr_epis_interv = descr.id_sr_epis_interv
                         LEFT OUTER JOIN intervention si
                           ON sei.id_sr_intervention = si.id_intervention
                         LEFT OUTER JOIN interv_codification ic
                           ON ic.id_interv_codification = sei.id_interv_codification
                         LEFT OUTER JOIN sr_surgery_time_det sstd_in
                           ON sei.id_episode = sstd_in.id_episode
                          AND sstd_in.flg_status = pk_alert_constant.g_active
                          AND sstd_in.id_sr_surgery_time = l_id_sr_surgery_time_ic
                         LEFT OUTER JOIN sr_surgery_time_det sstd_out
                           ON sei.id_episode = sstd_out.id_episode
                          AND sstd_out.flg_status = pk_alert_constant.g_active
                          AND sstd_out.id_sr_surgery_time = l_id_sr_surgery_time_fc
                         LEFT JOIN episode sre
                           ON sre.id_episode = sei.id_episode_context
                         LEFT JOIN dep_clin_serv dps
                           ON dps.id_clinical_service = sre.id_clinical_service
                          AND dps.id_department = sre.id_department
                          AND dps.flg_available = pk_alert_constant.g_available
                        WHERE sei.flg_status_hist = 'O') t_list
                        ORDER BY t_list.ordered, t_list.dt_order DESC;
    
    
        BEGIN
            SELECT sei.id_sr_epis_interv
              BULK COLLECT
              INTO l_id_sr_interv
              FROM sr_epis_interv sei
              JOIN episode epi
                ON epi.id_episode = sei.id_episode_context
             WHERE epi.id_episode = i_id_context
               AND sei.flg_status <> pk_wtl_prv_core.g_sr_epis_interv_status_c;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sr_interv := NULL;
        END;
    
        IF l_id_sr_interv IS NOT NULL
           AND l_id_sr_interv.count > 0
        THEN
            g_error := 'OPEN o_interv_clinical_questions';
            OPEN o_interv_clinical_questions FOR
                SELECT iqr.id_sr_epis_interv id_interv_presc_det,
                       iqr.id_questionnaire,
                       iqr1.flg_time,
                       q.id_content,
                       pk_mcdt.get_questionnaire_alias(i_lang,
                                                       i_prof,
                                                       'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || iqr.id_questionnaire) desc_questionnaire,
                       nvl(iqr1.id_response, iqr.notes) id_response,
                       decode(dbms_lob.getlength(iqr.notes),
                              NULL,
                              to_clob(iqr1.desc_response),
                              pk_procedures_utils.get_procedure_response(i_lang, i_prof, iqr.notes)) desc_response
                  FROM (SELECT iqr.id_sr_epis_interv,
                               iqr.id_questionnaire,
                               iqr.flg_time,
                               substr(concatenate(iqr.id_response || '; '),
                                      1,
                                      length(concatenate(iqr.id_response || '; ')) - 2) id_response,
                               listagg(pk_mcdt.get_response_alias(i_lang,
                                                                  i_prof,
                                                                  'RESPONSE.CODE_RESPONSE.' || iqr.id_response),
                                       '; ') within GROUP(ORDER BY iqr.id_response) desc_response,
                               iqr.dt_last_update_tstz,
                               row_number() over(PARTITION BY iqr.id_sr_epis_interv, iqr.id_questionnaire, iqr.flg_time ORDER BY iqr.dt_last_update_tstz DESC NULLS FIRST) rn
                          FROM sr_interv_quest_response iqr
                         WHERE iqr.id_sr_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                          *
                                                           FROM TABLE(l_id_sr_interv) t)
                         GROUP BY iqr.id_sr_epis_interv, iqr.id_questionnaire, iqr.flg_time, iqr.dt_last_update_tstz) iqr1,
                       sr_interv_quest_response iqr,
                       sr_epis_interv ipd,
                       questionnaire q
                 WHERE iqr1.rn = 1
                   AND iqr1.id_sr_epis_interv = iqr.id_sr_epis_interv
                   AND iqr1.id_questionnaire = iqr.id_questionnaire
                   AND iqr.id_questionnaire = q.id_questionnaire
                   AND iqr1.dt_last_update_tstz = iqr.dt_last_update_tstz
                   AND iqr.id_sr_epis_interv = ipd.id_sr_epis_interv;
        END IF;
    
        g_error := 'OPEN o_interv_supplies';
        OPEN o_interv_supplies FOR
            SELECT *
              FROM (SELECT sw.id_context id_interv_presc_det,
                           listagg(sw.id_supply_workflow, ';') within GROUP(ORDER BY sw.id_supply_workflow) id_supply_workflow,
                           sw.id_supply id_supply,
                           sw.id_supply_set id_parent_supply,
                           pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                           pk_supplies_api_db.get_attributes(i_lang, i_prof, sw.id_supply_area, sw.id_supply) desc_supply_attribute,
                           sw.flg_cons_type,
                           pk_sysdomain.get_domain('SUPPLY_SOFT_INST.FLG_CONS_TYPE', sw.flg_cons_type, i_lang) desc_consumption_type,
                           SUM(sw.quantity) quantity,
                           pk_date_utils.date_char_tsz(i_lang, sw.dt_returned, i_prof.institution, i_prof.software) dt_return,
                           pk_date_utils.date_send_tsz(i_lang, sw.dt_returned, i_prof) dt_return_str,
                           s.flg_type flg_type,
                           sei.id_sr_intervention
                      FROM supply_workflow sw
                      JOIN supply s
                        ON s.id_supply = sw.id_supply
                      JOIN sr_epis_interv sei
                        ON sei.id_sr_epis_interv = sw.id_context
                      JOIN episode epi
                        ON epi.id_episode = sei.id_episode_context
                     WHERE sw.flg_status NOT IN
                           (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                       AND epi.id_episode = i_id_context
                     GROUP BY sw.id_context,
                              sw.id_supply,
                              sw.id_supply_set,
                              s.code_supply,
                              sw.id_supply_area,
                              sw.flg_cons_type,
                              sw.quantity,
                              sw.dt_returned,
                              s.flg_type,
                              sei.id_sr_intervention);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMM_INTERV_API',
                                              o_error);
            pk_types.open_my_cursor(o_labels);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_interv_clinical_questions);
            pk_types.open_my_cursor(o_interv_supplies);
        
            RETURN FALSE;
    END get_summ_interv_api;

    /********************************************************************************************
    * Checks if some occurrence of a surgery with given surgical procedures was initiated (surgery start date)
    * after the given date.
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_patient            Patient Id
    * @param i_id_sr_intervention    Surgical Procedure Id
    * @param i_start_date            Lower date to be considered
    * @param o_flg_started_procedure Y-the surgical procedure was started after the given date. N-otherwise
    * @param o_id_epis_sr_interv     List with the epis_sr_interv
    * @param o_error                 Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sofia Mendes
    * @version                  2.6.1
    * @since                    19-Apr-2011
    *
    *********************************************************************************************/
    FUNCTION check_surg_procedure
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patiet             IN patient.id_patient%TYPE,
        i_id_sr_intervention    IN intervention.id_intervention%TYPE,
        i_start_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_started_procedure OUT VARCHAR2,
        o_id_epis_sr_interv     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET List of id_sr_epis_interv. i_id_patiet: ' || i_id_patiet || ' i_id_sr_intervention: ' ||
                   i_id_sr_intervention;
        pk_alertlog.log_debug(g_error);
        SELECT s.id_sr_epis_interv
          BULK COLLECT
          INTO o_id_epis_sr_interv
          FROM sr_epis_interv s
          JOIN episode epi
            ON epi.id_episode = s.id_episode_context
          LEFT JOIN sr_surgery_time_det std
            ON std.id_episode = s.id_episode
           AND std.id_sr_surgery_time = 3 --surgery start date
         WHERE epi.id_patient = i_id_patiet
           AND s.id_sr_intervention = i_id_sr_intervention
           AND epi.flg_status = pk_alert_constant.g_active
           AND (i_start_date IS NULL OR std.dt_surgery_time_det_tstz > i_start_date OR
               (std.dt_surgery_time_det_tstz IS NULL AND epi.dt_begin_tstz > i_start_date));
    
        g_error := 'CALC o_id_epis_sr_interv';
        pk_alertlog.log_debug(g_error);
        IF (o_id_epis_sr_interv IS NOT NULL AND o_id_epis_sr_interv.exists(1))
        THEN
            o_flg_started_procedure := pk_alert_constant.g_yes;
        ELSE
            o_flg_started_procedure := pk_alert_constant.g_no;
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
                                              'CHECK_SURG_PROCEDURE',
                                              o_error);
        
            o_flg_started_procedure := pk_alert_constant.g_no;
            o_id_epis_sr_interv     := NULL;
            RETURN FALSE;
    END check_surg_procedure;

    /**************************************************************************
      * List of coded surgical procedures for an institution       
      *                                                                         
      * @param i_lang                   Language ID                             
      * @param i_prof                   Profissional ID                         
      *
      * @param o_surg_proc_list         List of coded surgical procedures 
    * @param o_error                  Error message 
    *           
    * @return                         TRUE/FALSE                                                             
    *
      * @author                         Filipe Silva                            
      * @version                        2.6.1                                 
      * @since                          2011/04/27                              
      **************************************************************************/
    FUNCTION get_coded_surgical_procedures
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_surg_proc_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_CODED_SURGICAL_PROCEDURES';
        l_coding        sys_config.value%TYPE;
    
    BEGIN
    
        g_error  := 'GET SURG CODIFICATION';
        l_coding := pk_sysconfig.get_config(i_code_cf => pk_alert_constant.g_sys_config_surg_coding, i_prof => i_prof);
    
        OPEN o_surg_proc_list FOR
            SELECT i.id_intervention id_sr_intervention,
                   pk_translation.get_translation(i_lang, i.code_intervention) ||
                   decode(ic.standard_code, NULL, '', ' / ') || to_char(ic.standard_code) desc_interv
              FROM intervention i
             INNER JOIN interv_codification ic
                ON i.id_intervention = ic.id_intervention
             WHERE i.flg_status = pk_alert_constant.g_active
             ORDER BY 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_surg_proc_list);
            RETURN FALSE;
    END get_coded_surgical_procedures;

    FUNCTION get_sr_interv_edit_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_edit_permission OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_SR_INTERV_EDIT_PERMISSION';
        l_prof_cat      category.flg_type%TYPE;
    
    BEGIN
    
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        IF l_prof_cat = g_category_nurse
        THEN
            o_edit_permission := 'N';
        ELSE
            o_edit_permission := 'Y';
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_sr_interv_edit_permission;

    /********************************************************************************************
    * Get a surgical procedure team for CDA
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_sr_epis_interv     Surgical intervention Id
    *
    * @return                        The surgial intervention team
    *     
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-Ago-2014
    *
    *********************************************************************************************/
    FUNCTION get_surgical_proc_team_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN t_coll_proc_performed_cda IS
        l_function_name VARCHAR2(30 CHAR) := 'GET_SURGICAL_PROC_TEAM_CDA';
    
        l_error          t_error_out;
        l_proc_performed t_coll_proc_performed_cda;
    BEGIN
        g_error := 'GET SURGICAL PROCEDURE TEAM PERFORMERS';
        SELECT t_rec_proc_performed_cda(id_procedure   => i_id_sr_epis_interv,
                                        id_performed   => ptd.id_professional,
                                        performed_name => pk_prof_utils.get_name(i_lang, ptd.id_professional),
                                        id_institution => pt.id_institution,
                                        id_software    => pt.id_software,
                                        role_code      => ptd.id_category_sub,
                                        role_desc      => pk_translation.get_translation(i_lang, c.code_category_sub))
          BULK COLLECT
          INTO l_proc_performed
          FROM sr_prof_team_det ptd
         INNER JOIN prof_team pt
            ON pt.id_prof_team = ptd.id_prof_team
         INNER JOIN category_sub c
            ON c.id_category_sub = ptd.id_category_sub
         WHERE ptd.id_sr_epis_interv = i_id_sr_epis_interv;
    
        RETURN l_proc_performed;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
        
    END get_surgical_proc_team_cda;

    /********************************************************************************************
    * Get surgical procedures associated to a surgery for a given scope and status for CDA
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_scope              ID for scope
    * @param i_scope_type            Scope Type (E)pisode/(V)isit/(P)atient
    * @param i_flg_status            Flag status (S)cheduled / (P)roposal to add
    *
    * @return                        The surgial procedures associated to a surgery
    *     
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-Ago-2014
    *
    *********************************************************************************************/
    FUNCTION get_surgical_proc_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_scope   IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_flg_status IN table_varchar DEFAULT NULL
    ) RETURN t_coll_surgical_proc_cda IS
        l_function_name VARCHAR2(25 CHAR) := 'GET_SURGICAL_PROC_CDA';
    
        l_error         t_error_out;
        l_surgical_proc t_coll_surgical_proc_cda;
        l_id_patient    patient.id_patient%TYPE;
        l_id_episode    episode.id_episode%TYPE;
        l_id_visit      visit.id_visit%TYPE;
    
        l_status_scheduled VARCHAR(1 CHAR) := 'S';
        l_status_proposal  VARCHAR(2 CHAR) := 'PA';
        l_status_pending   VARCHAR(1 CHAR) := 'D';
        l_status_delayed   VARCHAR(2 CHAR) := 'DL';
    
        l_sm_coded_proc  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_T005');
        l_sm_uncoed_proc sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_T007');
        l_sm_schedule    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_LABEL_T011');
        l_sm_proposal    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROCEDURES_MFR_T137');
        l_sm_pending     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_LABEL_T409');
        l_sm_delayed     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_LABEL_T410');
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_id_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET SURGICAL PROCEDURES';
        SELECT t_rec_surgical_proc_cda(id_procedure    => t.id_sr_epis_interv,
                                       id_content      => t.id_content,
                                       procedure_desc  => t.desc_interv,
                                       type_code       => NULL,
                                       type_desc       => t.flg_type_desc,
                                       status_code     => t.status_code,
                                       status_desc     => t.status_desc,
                                       date_value      => t.date_value,
                                       date_formatted  => NULL,
                                       date_serialized => NULL,
                                       target_code     => t.laterality,
                                       target_desc     => t.laterality_desc,
                                       notes           => t.notes,
                                       performed       => get_surgical_proc_team_cda(i_lang, i_prof, t.id_sr_epis_interv))
          BULK COLLECT
          INTO l_surgical_proc
          FROM (
                /*Surgical procedures with surgery request (except not ordered)*/
                SELECT p.id_sr_epis_interv,
                        p.id_content,
                        p.desc_interv,
                        p.flg_type,
                        p.flg_type_desc,
                        CASE
                             WHEN sr.flg_pat_status = g_sr_flg_pat_status_a /*absent*/
                              THEN
                              nvl2(wl.id_waiting_list, l_status_proposal, l_status_scheduled)
                             WHEN sr.flg_pat_status = g_sr_flg_pat_status_w /*waiting*/
                              THEN
                              CASE
                                  WHEN nvl(s.dt_target_tstz, epi.dt_begin_tstz) > g_sysdate_tstz THEN
                                   l_status_pending
                                  ELSE
                                   l_status_delayed
                              END
                             ELSE
                              NULL
                         END status_code,
                        CASE
                             WHEN sr.flg_pat_status = g_sr_flg_pat_status_a /*absent*/
                              THEN
                              nvl2(wl.id_waiting_list, l_sm_proposal, l_sm_schedule)
                             WHEN sr.flg_pat_status = g_sr_flg_pat_status_w /*waiting*/
                              THEN
                              CASE
                                  WHEN nvl(s.dt_target_tstz, epi.dt_begin_tstz) > g_sysdate_tstz THEN
                                   l_sm_pending
                                  ELSE
                                   l_sm_delayed
                              END
                             ELSE
                              NULL
                         END status_desc,
                        nvl(s.dt_target_tstz, epi.dt_begin_tstz) date_value,
                        p.laterality,
                        p.laterality_desc,
                        nvl(s.notes, p.notes) notes
                  FROM schedule_sr s
                  LEFT JOIN waiting_list wl
                    ON wl.id_waiting_list = s.id_waiting_list
                 INNER JOIN sr_surgery_record sr
                    ON sr.id_schedule_sr = s.id_schedule_sr
                 INNER JOIN (SELECT e.id_episode, e.dt_begin_tstz
                               FROM episode e
                              WHERE e.id_episode = l_id_episode
                                AND e.id_patient = l_id_patient
                                AND i_scope_type = pk_alert_constant.g_scope_type_episode
                             UNION ALL
                             SELECT e.id_episode, e.dt_begin_tstz
                               FROM episode e
                              WHERE e.id_patient = l_id_patient
                                AND i_scope_type = pk_alert_constant.g_scope_type_patient
                             UNION ALL
                             SELECT e.id_episode, e.dt_begin_tstz
                               FROM episode e
                              WHERE e.id_visit = l_id_visit
                                AND e.id_patient = l_id_patient
                                AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                    ON epi.id_episode = s.id_episode
                 INNER JOIN (SELECT sei.id_episode_context id_episode,
                                    sei.id_sr_epis_interv,
                                    i.id_content,
                                    sei.laterality,
                                    pk_sysdomain.get_domain(g_sei_laterality, sei.laterality, i_lang) laterality_desc,
                                    CASE
                                         WHEN sei.flg_code_type = g_sei_flg_code_type_c THEN
                                         --coded surgical procedure
                                          pk_translation.get_translation(i_lang, i.code_intervention)
                                         ELSE
                                         --uncoded surgical procedure
                                          sei.name_interv
                                     END desc_interv,
                                    sei.flg_type,
                                    CASE
                                         WHEN sei.flg_code_type = g_sei_flg_code_type_c THEN
                                         --coded surgical procedure
                                          l_sm_coded_proc
                                         ELSE
                                         --uncoded surgical procedure
                                          l_sm_uncoed_proc
                                     END flg_type_desc,
                                    sei.notes
                               FROM sr_epis_interv sei
                               LEFT JOIN intervention i
                                 ON i.id_intervention = sei.id_sr_intervention
                              WHERE sei.flg_status NOT IN (g_cancel, g_not_orded)) p
                    ON p.id_episode = epi.id_episode
                UNION ALL
                /*Not ordered surgical procedure without surgery request*/
                SELECT sei.id_sr_epis_interv,
                        i.id_content,
                        CASE
                            WHEN sei.flg_code_type = g_sei_flg_code_type_c THEN
                            --coded surgical procedure
                             pk_translation.get_translation(i_lang, i.code_intervention)
                            ELSE
                            --uncoded surgical procedure
                             sei.name_interv
                        END desc_interv,
                        sei.flg_type,
                        CASE
                            WHEN sei.flg_code_type = g_sei_flg_code_type_c THEN
                            --coded surgical procedure
                             l_sm_coded_proc
                            ELSE
                            --uncoded surgical procedure
                             l_sm_uncoed_proc
                        END flg_type_desc,
                        g_not_orded status_code,
                        pk_sysdomain.get_domain(g_sei_flg_status, sei.flg_status, i_lang) status_desc,
                        sei.dt_req_tstz date_value,
                        sei.laterality,
                        pk_sysdomain.get_domain(g_sei_laterality, sei.laterality, i_lang) laterality_desc,
                        sei.notes
                  FROM sr_epis_interv sei
                  LEFT JOIN intervention i
                    ON i.id_intervention = sei.id_sr_intervention
                 INNER JOIN (SELECT e.id_episode, e.dt_begin_tstz
                               FROM episode e
                              WHERE e.id_episode = l_id_episode
                                AND e.id_patient = l_id_patient
                                AND i_scope_type = pk_alert_constant.g_scope_type_episode
                             UNION ALL
                             SELECT e.id_episode, e.dt_begin_tstz
                               FROM episode e
                              WHERE e.id_patient = l_id_patient
                                AND i_scope_type = pk_alert_constant.g_scope_type_patient
                             UNION ALL
                             SELECT e.id_episode, e.dt_begin_tstz
                               FROM episode e
                              WHERE e.id_visit = l_id_visit
                                AND e.id_patient = l_id_patient
                                AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                    ON epi.id_episode = sei.id_episode_context
                 WHERE sei.flg_status = g_not_orded
                   AND NOT EXISTS (SELECT 1
                          FROM schedule_sr s
                         WHERE s.id_episode = sei.id_episode_context)) t
         WHERE t.status_code IS NOT NULL
           AND (i_flg_status IS NULL OR
               t.status_code IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                   column_value
                                    FROM TABLE(i_flg_status) t));
    
        RETURN l_surgical_proc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
    END get_surgical_proc_cda;
    /********************************************************************************************
    * Get List of surgical procedures modifying factors
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_sr_intervention              ID for scope
    *
    * @return                        List modifying factors
    *     
    * @author                        Paulo Teixeira
    * @version                       2.6.5
    * @since                         2015 10 15
    *
    *********************************************************************************************/
    FUNCTION get_surg_proc_mod_fact
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_epis_interv  IN table_number,
        i_id_sr_intervention IN table_number,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_content     table_varchar;
        l_id_content_aux table_varchar := table_varchar();
        l_count          NUMBER(12);
    BEGIN
    
        SELECT si.id_content
          BULK COLLECT
          INTO l_id_content
          FROM intervention si
         WHERE si.id_intervention IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(i_id_sr_intervention) t);
    
        l_id_content_aux := l_id_content_aux MULTISET UNION DISTINCT l_id_content;
        l_count          := l_id_content_aux.count;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT aux.id_concept_term || '|' || aux.id_inst_owner data,
                   aux.desc_mod_factor label,
                   aux.rank,
                   aux.flg_default,
                   get_surg_proc_mod_fact_flg_sel(i_lang,
                                                  i_prof,
                                                  aux.id_concept_term,
                                                  aux.id_inst_owner,
                                                  i_id_sr_epis_interv) flg_select
              FROM (SELECT /*+opt_estimate (table t rows=1)*/
                     COUNT(1) over(PARTITION BY t.id_concept_term, t.id_cncpt_trm_inst_owner) tot_by_ct,
                     row_number() over(PARTITION BY t.id_concept_term, t.id_cncpt_trm_inst_owner ORDER BY t.id_concept_term, t.id_cncpt_trm_inst_owner) rn,
                     t.id_concept_term id_concept_term,
                     t.id_cncpt_trm_inst_owner id_inst_owner,
                     pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                     t.id_task_type,
                                                                     t.id_concept_term,
                                                                     t.id_cncpt_trm_inst_owner) desc_mod_factor,
                     t.rank rank,
                     t.flg_default flg_default
                      FROM TABLE(pk_terminology_search.tf_concept_by_id_content(i_lang,
                                                                                i_prof,
                                                                                table_number(pk_alert_constant.g_task_sr_procedures),
                                                                                l_id_content_aux,
                                                                                g_has_modifier)) t) aux
             WHERE aux.rn = 1
               AND aux.tot_by_ct = l_count
             ORDER BY rank, desc_mod_factor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURG_PROC_MOD_FACT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_surg_proc_mod_fact;
    /********************************************************************************************
    * Get List of surgical procedures modifying factors
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_sr_epis_interv              ID for scope
    * @param i_id_sr_epis_interv_hist              ID for scope
    *
    * @return                        List modifying factors
    *     
    * @author                        Paulo Teixeira
    * @version                       2.6.5
    * @since                         2015 10 15
    *
    *********************************************************************************************/
    FUNCTION get_surg_proc_mod_fact_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv      IN sr_epis_interv_hist.id_sr_epis_interv%TYPE,
        i_id_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE
    ) RETURN VARCHAR2 IS
        l_desc table_varchar := table_varchar();
    BEGIN
    
        CASE
            WHEN i_id_sr_epis_interv IS NOT NULL THEN
                SELECT t.descr
                  BULK COLLECT
                  INTO l_desc
                  FROM (SELECT pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                               pk_alert_constant.g_task_sr_procedures,
                                                                               seimf.id_concept_term,
                                                                               seimf.id_inst_owner) descr
                          FROM sr_epis_interv sei
                          JOIN sr_epis_interv_hist seih
                            ON seih.id_sr_epis_interv = sei.id_sr_epis_interv
                           AND seih.flg_status_hist = pk_alert_constant.g_active
                          JOIN sr_epis_interv_mod_fact seimf
                            ON seimf.id_sr_epis_interv_hist = seih.id_sr_epis_interv_hist
                         WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv) t
                 ORDER BY t.descr DESC;
            
            WHEN i_id_sr_epis_interv_hist IS NOT NULL THEN
                SELECT t.descr
                  BULK COLLECT
                  INTO l_desc
                  FROM (SELECT pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                               pk_alert_constant.g_task_sr_procedures,
                                                                               seimf.id_concept_term,
                                                                               seimf.id_inst_owner) descr
                          FROM sr_epis_interv_mod_fact seimf
                         WHERE seimf.id_sr_epis_interv_hist = i_id_sr_epis_interv_hist) t
                 ORDER BY t.descr DESC;
            
            ELSE
                l_desc := table_varchar();
        END CASE;
    
        RETURN pk_utils.concat_table(l_desc, '; ');
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_surg_proc_mod_fact_desc;
    ---
    FUNCTION get_surg_proc_mod_fact_ids
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv      IN sr_epis_interv_hist.id_sr_epis_interv%TYPE,
        i_id_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE
    ) RETURN table_varchar IS
        l_ids table_varchar := table_varchar();
    BEGIN
    
        CASE
            WHEN i_id_sr_epis_interv IS NOT NULL THEN
                SELECT t.ids
                  BULK COLLECT
                  INTO l_ids
                  FROM (SELECT seimf.id_concept_term || '|' || seimf.id_inst_owner ids,
                               pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                               pk_alert_constant.g_task_sr_procedures,
                                                                               seimf.id_concept_term,
                                                                               seimf.id_inst_owner) descr
                          FROM sr_epis_interv sei
                          JOIN sr_epis_interv_hist seih
                            ON seih.id_sr_epis_interv = sei.id_sr_epis_interv
                           AND seih.flg_status_hist = pk_alert_constant.g_active
                          JOIN sr_epis_interv_mod_fact seimf
                            ON seimf.id_sr_epis_interv_hist = seih.id_sr_epis_interv_hist
                         WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv) t
                 ORDER BY t.descr DESC;
            
            WHEN i_id_sr_epis_interv_hist IS NOT NULL THEN
                SELECT t.ids
                  BULK COLLECT
                  INTO l_ids
                  FROM (SELECT seimf.id_concept_term || '|' || seimf.id_inst_owner ids,
                               pk_api_termin_server_func.get_concept_term_desc(i_lang,
                                                                               pk_alert_constant.g_task_sr_procedures,
                                                                               seimf.id_concept_term,
                                                                               seimf.id_inst_owner) descr
                          FROM sr_epis_interv_mod_fact seimf
                         WHERE seimf.id_sr_epis_interv_hist = i_id_sr_epis_interv_hist) t
                 ORDER BY t.descr DESC;
            
            ELSE
                l_ids := table_varchar();
        END CASE;
    
        RETURN l_ids;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_surg_proc_mod_fact_ids;
    ---
    FUNCTION get_surg_proc_mod_fact_flg_sel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_concept_term   IN concept_term.id_concept_term%TYPE,
        i_id_inst_owner     IN concept_term.id_inst_owner%TYPE,
        i_id_sr_epis_interv IN table_number
    ) RETURN VARCHAR2 IS
        l_count  NUMBER(24);
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_val    VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    BEGIN
    
        IF i_id_sr_epis_interv IS NOT NULL
        THEN
            IF i_id_sr_epis_interv.count > 0
            THEN
            
                FOR i IN 1 .. i_id_sr_epis_interv.count
                LOOP
                    IF i_id_sr_epis_interv(i) IS NULL
                    THEN
                        l_val := pk_alert_constant.g_no;
                        EXIT;
                    END IF;
                END LOOP;
            
                IF l_val = pk_alert_constant.g_yes
                THEN
                    SELECT COUNT(1)
                      INTO l_count
                      FROM sr_epis_interv sei
                      JOIN sr_epis_interv_hist seih
                        ON seih.id_sr_epis_interv = sei.id_sr_epis_interv
                       AND seih.flg_status_hist = pk_alert_constant.g_active
                      JOIN sr_epis_interv_mod_fact seimf
                        ON seimf.id_sr_epis_interv_hist = seih.id_sr_epis_interv_hist
                       AND seimf.id_concept_term = i_id_concept_term
                       AND seimf.id_inst_owner = i_id_inst_owner
                     WHERE sei.id_sr_epis_interv IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                      *
                                                       FROM TABLE(i_id_sr_epis_interv) t);
                
                    IF l_count = i_id_sr_epis_interv.count
                    THEN
                        l_return := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
        
    END get_surg_proc_mod_fact_flg_sel;

    /********************************************************************************************
    * Get number of surgical procedures registered in intervention records in given scope
    *
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return              Count of records
    *
    * @author              Anna Kurowska
    * @since               2017/03/07
       ********************************************************************************************/
    FUNCTION get_sr_interv_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_SR_INTERV_COUNT';
        l_episodes  table_number := table_number();
        l_count     NUMBER(24);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        SELECT COUNT(*)
          INTO l_count
          FROM sr_epis_interv sei
         WHERE sei.id_episode_context IN (SELECT *
                                            FROM TABLE(l_episodes))
           AND sei.flg_status != pk_sr_planning.g_interv_can;
        RETURN l_count;
    END get_sr_interv_count;

    FUNCTION get_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_list FOR
            SELECT DISTINCT id_institution, institution_desc, flg_default
              FROM (SELECT inst.id_institution,
                           pk_translation.get_translation(i_lang, inst.code_institution) institution_desc,
                           decode(inst.id_institution,
                                  i_prof.institution,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_default
                      FROM institution inst
                      JOIN institution inst_mine
                        ON inst.id_parent = inst_mine.id_parent
                      JOIN software_institution si
                        ON si.id_institution = inst.id_institution
                     WHERE inst_mine.id_institution = i_prof.institution
                       AND inst.flg_available = pk_alert_constant.g_yes
                       AND si.id_software = pk_alert_constant.g_soft_oris
                    UNION ALL
                    SELECT inst_mine.id_institution,
                           pk_translation.get_translation(i_lang, inst_mine.code_institution) institution_desc,
                           pk_alert_constant.g_yes flg_default
                      FROM institution inst_mine
                      JOIN software_institution si
                        ON si.id_institution = inst_mine.id_institution
                     WHERE inst_mine.id_institution = i_prof.institution
                       AND si.id_software = pk_alert_constant.g_soft_oris
                    UNION ALL
                    SELECT inst_parent.id_institution,
                           pk_translation.get_translation(i_lang, inst_parent.code_institution) institution_desc,
                           pk_alert_constant.g_no flg_default
                      FROM institution inst_mine
                      JOIN institution inst_parent
                        ON inst_mine.id_parent = inst_parent.id_institution
                      JOIN software_institution si
                        ON si.id_institution = inst_parent.id_institution
                     WHERE inst_mine.id_institution = i_prof.institution
                       AND inst_parent.flg_available = pk_alert_constant.g_yes
                       AND si.id_software = pk_alert_constant.g_soft_oris
                    UNION ALL
                    SELECT inst_child.id_institution,
                           pk_translation.get_translation(i_lang, inst_child.code_institution) institution_desc,
                           pk_alert_constant.g_no flg_default
                      FROM institution inst_mine
                      JOIN institution inst_child
                        ON inst_child.id_parent = inst_mine.id_institution
                      JOIN software_institution si
                        ON si.id_institution = inst_child.id_institution
                     WHERE inst_mine.id_institution = i_prof.institution
                       AND inst_child.flg_available = pk_alert_constant.g_yes
                       AND si.id_software = pk_alert_constant.g_soft_oris);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SR_PLANNING',
                                              'GET_LOCATION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
            RETURN FALSE;
    END get_location_list;

    FUNCTION get_duration_unit_measure_ds
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hours        IN adm_request.expected_duration%TYPE,
        i_date         IN adm_request.dt_admission%TYPE, --Value is sent in minutes
        o_value        OUT NUMBER,
        o_unit_measure OUT unit_measure.id_unit_measure%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_value_mod  NUMBER;
        l_hours_year NUMBER;
        l_hours_week NUMBER := 168;
        l_hours_day  NUMBER := 24;
        l_hours      NUMBER := 1;
    
        --Convert the input minutes in hours
        l_input_hours NUMBER := i_hours / 60;
    
    BEGIN
    
        SELECT (add_months(trunc(i_date, 'YEAR'), 12) - trunc(i_date, 'YEAR')) * 24
          INTO l_hours_year
          FROM dual;
    
        -- verify is a year
        IF l_input_hours >= l_hours_year
        THEN
        
            SELECT MOD(l_input_hours, l_hours_year)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours_year;
                o_unit_measure := 10373;
                RETURN TRUE;
            END IF;
        
        END IF;
    
        -- verify week
        IF l_input_hours >= l_hours_week
        THEN
        
            SELECT MOD(l_input_hours, l_hours_week)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours_week;
                o_unit_measure := 10375;
                RETURN TRUE;
            
            END IF;
        
        END IF;
    
        -- verify day
        IF l_input_hours >= l_hours_day
        THEN
        
            SELECT MOD(l_input_hours, l_hours_day)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours_day;
                o_unit_measure := 1039;
                RETURN TRUE;
            END IF;
        END IF;
    
        IF l_input_hours >= l_hours
        THEN
            SELECT MOD(l_input_hours, l_hours)
              INTO l_value_mod
              FROM dual;
            IF l_value_mod = 0
            THEN
                o_value        := l_input_hours / l_hours;
                o_unit_measure := 1041;
                RETURN TRUE;
            END IF;
        END IF;
    
        -- return hour
        o_value        := i_hours;
        o_unit_measure := 10374;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_duration_unit_measure_ds;

    /********************************************************************************************
    * Obtain the Surgical Procedures configured for a specific dep_clin_serv (when given)
    *
    *********************************************************************************************/

    FUNCTION get_procedure_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN VARCHAR2,
        i_flg_filter    IN VARCHAR2 DEFAULT 'S',
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list t_tbl_procedures_for_selection;
    
        CURSOR c_pat IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat c_pat%ROWTYPE;
    
        l_msg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROCEDURES_T066');
    
        l_inst_dest institution.id_institution%TYPE;
    
        l_permission VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_patient IS NOT NULL
        THEN
            g_error := 'OPEN C_PAT';
            OPEN c_pat;
            FETCH c_pat
                INTO l_pat;
            CLOSE c_pat;
        END IF;
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            SELECT d.id_institution
              INTO l_inst_dest
              FROM dep_clin_serv dps
              JOIN department d
                ON d.id_department = dps.id_department
             WHERE dps.id_dep_clin_serv = i_dep_clin_serv;
        END IF;
    
        g_error := 'SELECT PK_PROCEDURES_UTILS.GET_PROCEDURE_PERMISSION';
        SELECT pk_procedures_utils.get_procedure_permission(i_lang,
                                                            i_prof,
                                                            pk_procedures_constant.g_interv_area_procedures,
                                                            pk_procedures_constant.g_interv_button_create,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL)
          INTO l_permission
          FROM dual;
    
        DELETE FROM tbl_temp;
    
        IF i_flg_filter = pk_procedures_constant.g_interv_institution
        THEN
            g_error := 'GET PROCEDURES 1';
            INSERT INTO tbl_temp
                (num_1, vc_1, vc_2, vc_3, num_2)
                SELECT id_intervention, desc_perform, flg_clinical_question, flg_timeout, rank
                  FROM (SELECT i.id_intervention,
                               decode(i.flg_execute, pk_procedures_constant.g_no, l_msg, NULL) desc_perform,
                               flg_clinical_question,
                               nvl(i.flg_timeout, pk_procedures_constant.g_no) flg_timeout,
                               (SELECT pk_procedures_utils.get_procedure_rank(i_lang,
                                                                              i_prof,
                                                                              i.id_intervention,
                                                                              pk_procedures_constant.g_interv_can_req,
                                                                              NULL)
                                  FROM dual) rank
                          FROM (SELECT DISTINCT i.id_intervention,
                                                iis.flg_execute,
                                                decode(iq.id_intervention,
                                                       NULL,
                                                       pk_procedures_constant.g_no,
                                                       decode(instr(nvl(iq.flg_mandatory, pk_procedures_constant.g_no),
                                                                    pk_procedures_constant.g_yes),
                                                              0,
                                                              pk_procedures_constant.g_yes,
                                                              'M')) flg_clinical_question,
                                                iis.flg_timeout
                                  FROM intervention i
                                  JOIN (SELECT id_intervention, flg_execute, flg_timeout
                                         FROM interv_dep_clin_serv
                                        WHERE flg_type = pk_procedures_constant.g_interv_can_req
                                          AND id_dep_clin_serv IS NULL
                                          AND id_software = pk_alert_constant.g_soft_oris
                                          AND id_institution = coalesce(l_inst_dest, i_prof.institution)) iis
                                    ON i.id_intervention = iis.id_intervention
                                  LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
                                              FROM (SELECT DISTINCT id_intervention, flg_mandatory
                                                      FROM interv_questionnaire
                                                     WHERE flg_time = pk_procedures_constant.g_interv_cq_on_order
                                                       AND id_institution = i_prof.institution
                                                       AND flg_available = pk_procedures_constant.g_available)
                                             GROUP BY id_intervention) iq
                                    ON iq.id_intervention = i.id_intervention
                                 WHERE instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                                   AND i.flg_status = pk_procedures_constant.g_active
                                   AND (iis.flg_execute = pk_procedures_constant.g_yes OR
                                        (iis.flg_execute = pk_procedures_constant.g_no AND
                                        l_permission = pk_procedures_constant.g_yes))
                                   AND (i_patient IS NULL OR
                                        (((l_pat.gender IS NOT NULL AND coalesce(i.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_pat.gender)) OR l_pat.gender IS NULL OR
                                        l_pat.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                                        nvl(i.age_max, nvl(l_pat.age, 0)) OR l_pat.age IS NULL)))
                                   AND rownum > 0) i); -- to solve performance problem when no records are returned)
        
        ELSIF i_flg_filter = 'S'
        THEN
            g_error := 'GET PROCEDURES 1';
            INSERT INTO tbl_temp
                (num_1, vc_1, vc_2, vc_3, num_2)
                SELECT id_intervention, desc_perform, flg_clinical_question, flg_timeout, rank
                  FROM (SELECT i.id_intervention,
                               decode(i.flg_execute, pk_procedures_constant.g_no, l_msg, NULL) desc_perform,
                               flg_clinical_question,
                               nvl(i.flg_timeout, pk_procedures_constant.g_no) flg_timeout,
                               (SELECT pk_procedures_utils.get_procedure_rank(i_lang,
                                                                              i_prof,
                                                                              i.id_intervention,
                                                                              i_flg_type,
                                                                              i.id_dep_clin_serv)
                                  FROM dual) rank
                          FROM (SELECT DISTINCT i.id_intervention,
                                                iis.flg_execute,
                                                decode(iq.id_intervention,
                                                       NULL,
                                                       pk_procedures_constant.g_no,
                                                       decode(instr(nvl(iq.flg_mandatory, pk_procedures_constant.g_no),
                                                                    pk_procedures_constant.g_yes),
                                                              0,
                                                              pk_procedures_constant.g_yes,
                                                              'M')) flg_clinical_question,
                                                iis.flg_timeout,
                                                idcs.id_dep_clin_serv
                                  FROM intervention i
                                  JOIN interv_dep_clin_serv idcs
                                    ON i.id_intervention = idcs.id_intervention
                                   AND idcs.flg_type = i_flg_type
                                   AND ((i_dep_clin_serv IS NULL AND idcs.id_software = pk_alert_constant.g_soft_oris AND
                                       idcs.id_institution = coalesce(l_inst_dest, i_prof.institution)) OR
                                       (i_dep_clin_serv IS NOT NULL AND idcs.id_dep_clin_serv = i_dep_clin_serv))
                                  JOIN (SELECT *
                                         FROM interv_dep_clin_serv
                                        WHERE flg_type = pk_procedures_constant.g_interv_can_req
                                          AND id_dep_clin_serv IS NULL
                                          AND id_software = pk_alert_constant.g_soft_oris
                                          AND id_institution = coalesce(l_inst_dest, i_prof.institution)) iis
                                    ON iis.id_intervention = i.id_intervention
                                  LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
                                              FROM (SELECT DISTINCT id_intervention, flg_mandatory
                                                      FROM interv_questionnaire
                                                     WHERE flg_time = pk_procedures_constant.g_interv_cq_on_order
                                                       AND id_institution = coalesce(l_inst_dest, i_prof.institution)
                                                       AND flg_available = pk_procedures_constant.g_available)
                                             GROUP BY id_intervention) iq
                                    ON iq.id_intervention = i.id_intervention
                                 WHERE instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                                   AND i.flg_status = pk_procedures_constant.g_active
                                   AND idcs.flg_type = i_flg_type
                                   AND idcs.id_software = pk_alert_constant.g_soft_oris
                                   AND ((i_dep_clin_serv IS NOT NULL AND (idcs.flg_execute = pk_procedures_constant.g_yes OR
                                        (idcs.flg_execute = pk_procedures_constant.g_no AND
                                        l_permission = pk_procedures_constant.g_yes)) AND
                                        idcs.id_dep_clin_serv = i_dep_clin_serv) OR
                                        (i_dep_clin_serv IS NULL AND idcs.id_institution = i_prof.institution AND
                                        (EXISTS (SELECT 1
                                                    FROM prof_dep_clin_serv pdcs
                                                   WHERE pdcs.id_professional = i_prof.id
                                                     AND pdcs.id_institution = i_prof.institution
                                                     AND pdcs.flg_status = pk_procedures_constant.g_selected
                                                     AND pdcs.id_dep_clin_serv = idcs.id_dep_clin_serv) OR
                                         idcs.id_professional = i_prof.id)))
                                   AND (i_patient IS NULL OR
                                        (((l_pat.gender IS NOT NULL AND coalesce(i.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_pat.gender)) OR l_pat.gender IS NULL OR
                                        l_pat.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                                        nvl(i.age_max, nvl(l_pat.age, 0)) OR l_pat.age IS NULL)))
                                   AND rownum > 0) i); -- to solve performance problem when no records are returned)
        
        ELSIF i_flg_filter IN ('P', 'N')
        THEN
            g_error := 'GET PROCEDURES 2';
            INSERT INTO tbl_temp
                (num_1, vc_1, vc_2, vc_3, num_2)
                SELECT id_intervention, desc_perform, flg_clinical_question, flg_timeout, rank
                  FROM (SELECT i.id_intervention,
                               decode(i.flg_execute, pk_procedures_constant.g_no, l_msg, NULL) desc_perform,
                               flg_clinical_question,
                               nvl(i.flg_timeout, pk_procedures_constant.g_no) flg_timeout,
                               (SELECT pk_procedures_utils.get_procedure_rank(i_lang,
                                                                              i_prof,
                                                                              i.id_intervention,
                                                                              i_flg_type,
                                                                              i.id_dep_clin_serv)
                                  FROM dual) rank
                          FROM (SELECT DISTINCT i.id_intervention,
                                                iis.flg_execute,
                                                decode(iq.id_intervention,
                                                       NULL,
                                                       pk_procedures_constant.g_no,
                                                       decode(instr(nvl(iq.flg_mandatory, pk_procedures_constant.g_no),
                                                                    pk_procedures_constant.g_yes),
                                                              0,
                                                              pk_procedures_constant.g_yes,
                                                              'M')) flg_clinical_question,
                                                iis.flg_timeout,
                                                iis.id_dep_clin_serv
                                  FROM intervention i
                                  JOIN (SELECT idcs.id_intervention, idcs.id_interv_dep_clin_serv
                                         FROM interv_dep_clin_serv idcs
                                        WHERE (((idcs.flg_type = i_flg_type AND idcs.id_software = i_prof.software AND
                                              (idcs.flg_execute = pk_procedures_constant.g_yes OR
                                              (idcs.flg_execute = pk_procedures_constant.g_no AND
                                              (SELECT pk_procedures_utils.get_procedure_permission(i_lang,
                                                                                                        i_prof,
                                                                                                        pk_procedures_constant.g_interv_area_procedures,
                                                                                                        pk_procedures_constant.g_interv_button_create,
                                                                                                        NULL,
                                                                                                        NULL,
                                                                                                        NULL,
                                                                                                        NULL)
                                                      FROM dual) = pk_procedures_constant.g_yes)))) OR
                                              (idcs.flg_type = i_flg_type AND
                                              idcs.id_software = pk_alert_constant.g_soft_oris) AND
                                              (EXISTS (SELECT 1
                                                          FROM prof_dep_clin_serv pdcs
                                                         WHERE pdcs.id_professional = i_prof.id
                                                           AND pdcs.id_institution = i_prof.institution
                                                           AND pdcs.flg_status = pk_procedures_constant.g_selected
                                                           AND pdcs.id_dep_clin_serv = idcs.id_dep_clin_serv) OR
                                               idcs.id_professional = i_prof.id))) idcs
                                    ON i.id_intervention = idcs.id_intervention
                                  JOIN (SELECT t.id_intervention,
                                              t.flg_execute,
                                              t.flg_timeout,
                                              t.id_dep_clin_serv,
                                              t.id_software
                                         FROM interv_dep_clin_serv t
                                        WHERE flg_type = pk_procedures_constant.g_interv_can_req
                                          AND id_institution = coalesce(l_inst_dest, i_prof.institution)
                                          AND id_software = pk_alert_constant.g_soft_oris) iis
                                    ON i.id_intervention = iis.id_intervention
                                  JOIN interv_dcs_most_freq_except idmfe
                                    ON idcs.id_interv_dep_clin_serv = idmfe.id_interv_dep_clin_serv
                                  LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
                                              FROM (SELECT DISTINCT id_intervention, flg_mandatory
                                                      FROM interv_questionnaire
                                                     WHERE flg_time = pk_procedures_constant.g_interv_cq_on_order
                                                       AND id_institution = i_prof.institution
                                                       AND flg_available = pk_procedures_constant.g_available)
                                             GROUP BY id_intervention) iq
                                    ON i.id_intervention = iq.id_intervention
                                 WHERE instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                                   AND i.flg_status = pk_procedures_constant.g_active
                                   AND idmfe.flg_cat_prof = i_flg_filter
                                   AND iis.id_software = pk_alert_constant.g_soft_oris
                                   AND (i_patient IS NULL OR
                                        (((l_pat.gender IS NOT NULL AND coalesce(i.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_pat.gender)) OR l_pat.gender IS NULL OR
                                        l_pat.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                                        nvl(i.age_max, nvl(l_pat.age, 0)) OR l_pat.age IS NULL)))
                                   AND rownum > 0) i); -- to solve performance problem when no records are returned)
        ELSIF i_flg_filter = 'C'
        THEN
            g_error := 'GET PROCEDURES 3';
            NULL;
        ELSIF i_flg_filter = 'D'
              AND i_codification IS NOT NULL
        THEN
            g_error := 'GET PROCEDURES 4';
            INSERT INTO tbl_temp
                (num_1, vc_1, vc_2, vc_3, num_2)
                SELECT id_intervention, desc_perform, flg_clinical_question, flg_timeout, rank
                  FROM (SELECT i.id_intervention,
                               decode(i.flg_execute, pk_procedures_constant.g_no, l_msg, NULL) desc_perform,
                               flg_clinical_question,
                               nvl(i.flg_timeout, pk_procedures_constant.g_no) flg_timeout,
                               (SELECT pk_procedures_utils.get_procedure_rank(i_lang,
                                                                              i_prof,
                                                                              i.id_intervention,
                                                                              i_flg_type,
                                                                              NULL)
                                  FROM dual) rank
                          FROM (SELECT DISTINCT i.id_intervention,
                                                iis.flg_execute,
                                                decode(iq.id_intervention,
                                                       NULL,
                                                       pk_procedures_constant.g_no,
                                                       decode(instr(nvl(iq.flg_mandatory, pk_procedures_constant.g_no),
                                                                    pk_procedures_constant.g_yes),
                                                              0,
                                                              pk_procedures_constant.g_yes,
                                                              'M')) flg_clinical_question,
                                                iis.flg_timeout
                                  FROM intervention i
                                  JOIN (SELECT *
                                         FROM interv_dep_clin_serv
                                        WHERE flg_type = pk_procedures_constant.g_interv_can_req
                                          AND id_institution = i_prof.institution
                                          AND id_software = pk_alert_constant.g_soft_oris) iis
                                    ON i.id_intervention = iis.id_intervention
                                  LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
                                              FROM (SELECT DISTINCT id_intervention, flg_mandatory
                                                      FROM interv_questionnaire
                                                     WHERE flg_time = pk_procedures_constant.g_interv_cq_on_order
                                                       AND id_institution = i_prof.institution
                                                       AND flg_available = pk_procedures_constant.g_available)
                                             GROUP BY id_intervention) iq
                                    ON i.id_intervention = iq.id_intervention
                                 WHERE instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                                   AND i.flg_status = pk_procedures_constant.g_active
                                   AND EXISTS
                                 (SELECT 1
                                          FROM codification_instit_soft cis, interv_codification ic
                                         WHERE cis.id_codification = i_codification
                                           AND cis.id_institution = i_prof.institution
                                           AND cis.id_software = i_prof.software
                                           AND cis.id_codification = ic.id_codification
                                           AND ic.flg_available = pk_procedures_constant.g_available
                                           AND ic.id_intervention = i.id_intervention)
                                   AND (i_patient IS NULL OR
                                        (((l_pat.gender IS NOT NULL AND coalesce(i.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                                        ('I', 'U', 'N', 'C', 'A', 'B', l_pat.gender)) OR l_pat.gender IS NULL OR
                                        l_pat.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                                        (nvl(l_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                                        nvl(i.age_max, nvl(l_pat.age, 0)) OR l_pat.age IS NULL)))
                                   AND rownum > 0) i); -- to solve performance problem when no records are returned)        
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT id_intervention,
                   desc_intervention,
                   desc_perform,
                   flg_clinical_question,
                   flg_timeout,
                   flg_laterality_mcdt,
                   rank
              FROM (SELECT id_intervention,
                           pk_procedures_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'INTERVENTION.CODE_INTERVENTION.' ||
                                                                      id_intervention,
                                                                      NULL) ||
                           decode(i_flg_filter,
                                  'D',
                                  pk_procedures_utils.get_procedure_code(i_lang,
                                                                         i_prof,
                                                                         id_intervention,
                                                                         i_codification,
                                                                         NULL),
                                  pk_procedures_utils.get_procedure_with_codification(i_lang,
                                                                                      i_prof,
                                                                                      id_intervention,
                                                                                      NULL)) desc_intervention,
                           desc_perform,
                           flg_clinical_question,
                           flg_timeout,
                           (SELECT pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', id_intervention)
                              FROM dual) flg_laterality_mcdt,
                           rank
                      FROM (SELECT num_1 id_intervention,
                                   vc_1 desc_perform,
                                   vc_2 flg_clinical_question,
                                   vc_3 flg_timeout,
                                   num_2 rank,
                                   row_number() over(PARTITION BY num_1, vc_2 ORDER BY num_2 DESC) rn
                              FROM tbl_temp) e
                     WHERE rn = 1
                     ORDER BY rank, desc_intervention);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedure_selection_list;

    /********************************************************************************************
    * Search for a Surgical Procedure
    *
    *********************************************************************************************/

    FUNCTION get_procedure_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_codification  IN codification.id_codification%TYPE,
        i_value         IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_SEARCH';
        IF NOT pk_procedures_core.get_procedure_search(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_procedure_type => pk_procedures_constant.g_type_interv_surgical,
                                                       i_codification   => i_codification,
                                                       i_dep_clin_serv  => i_dep_clin_serv,
                                                       i_value          => i_value,
                                                       o_flg_show       => o_flg_show,
                                                       o_msg            => o_msg,
                                                       o_msg_title      => o_msg_title,
                                                       o_list           => o_list,
                                                       o_error          => o_error)
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
                                              'GET_PROCEDURE_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_search;

    FUNCTION get_value_from_time_pref(i_val IN VARCHAR2) RETURN NUMBER AS
        l_ret NUMBER(24);
    BEGIN
    
        CASE i_val
            WHEN 'M' THEN
                l_ret := 1;
            WHEN 'A' THEN
                l_ret := 2;
            WHEN 'N' THEN
                l_ret := 3;
            WHEN 'O' THEN
                l_ret := 4;
            ELSE
                l_ret := -1;
        END CASE;
    
        RETURN l_ret;
    END get_value_from_time_pref;

    ------------------------------------------------------------      

    PROCEDURE add_new_def_event
    (
        i_pk              IN ds_def_event.id_def_event%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_flg_event_type  IN ds_def_event.flg_event_type%TYPE,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_DEF_EVENT';
        --
        r_ds_def_event    t_rec_ds_def_events;
        l_def_event_found BOOLEAN := FALSE;
    BEGIN
        IF io_tbl_def_events.exists(1)
        THEN
            FOR i IN io_tbl_def_events.first .. io_tbl_def_events.last
            LOOP
                IF io_tbl_def_events(i).id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel
                THEN
                    io_tbl_def_events(i).flg_event_type := i_flg_event_type;
                    io_tbl_def_events(i).id_def_event := i_pk; --This way I know that the value was changed in code
                    l_def_event_found := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        IF NOT l_def_event_found
        THEN
            g_error := 'NEW T_REC_DS_DEF_EVENTS INSTANCE';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_ADMISSION_REQUEST',
                                  sub_object_name => l_proc_name);
            r_ds_def_event := t_rec_ds_def_events(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                                  id_def_event       => i_pk,
                                                  flg_event_type     => i_flg_event_type);
        
            g_error := 'ADD DEF_EVENT TO IO_TBL_DEF_EVENTS';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => 'PK_ADMISSION_REQUEST',
                                  sub_object_name => l_proc_name);
            io_tbl_def_events.extend;
            io_tbl_def_events(io_tbl_def_events.count) := r_ds_def_event;
        END IF;
    END add_new_def_event;

    FUNCTION add_def_events
    (
        i_lang            IN language.id_language%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_edt_mode        IN VARCHAR2,
        i_has_surgery     IN VARCHAR2,
        i_inst_location   IN VARCHAR2,
        i_has_lvl_urg     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_has_unav        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_DEF_EVENTS';
        --
        l_default_uk          CONSTANT VARCHAR2(10) := '00200';
        l_def_event_mandatory CONSTANT VARCHAR2(1) := 'M';
    BEGIN
        IF i_internal_name IN ('RS_SPEC_SURGERY_P',
                               'RS_LOC_SURGERY_P',
                               'RS_PREV_DURATION_P',
                               'RS_UCI_P',
                               'RS_UCI_POS_P',
                               'RS_EXT_SPEC_P',
                               'RS_CONT_DANGER_P',
                               'RS_PREF_TIME_P',
                               'RS_MOT_PREF_TIME_P',
                               'RS_NOTES_P',
                               'RV_REQUEST_P')
        THEN
        
            IF i_has_surgery = pk_alert_constant.g_yes
               OR i_edt_mode = pk_alert_constant.g_yes
            THEN
                IF i_internal_name IN ('RS_LOC_SURGERY_P', 'RS_PREV_DURATION_P')
                THEN
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => l_def_event_mandatory,
                                      io_tbl_def_events => io_tbl_def_events);
                ELSE
                    add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                      i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                      i_flg_event_type  => pk_alert_constant.g_active,
                                      io_tbl_def_events => io_tbl_def_events);
                END IF;
            END IF;
        END IF;
    
        IF i_internal_name IN ('RSP_LVL_URG_P',
                               'RSP_BEGIN_SCHED_P',
                               'RSP_END_SCHED_P',
                               'RSP_TIME_MIN_P',
                               'RSP_SUGG_DT_SURG_P',
                               'RSP_SUGG_DT_INT_P')
           AND i_has_lvl_urg = pk_alert_constant.g_yes
        THEN
            add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                              i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        END IF;
    
        IF (i_internal_name LIKE 'RIP_DURATION%' OR i_internal_name LIKE 'RIP_END_PER%')
           AND i_has_unav = pk_alert_constant.g_yes
        THEN
            add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                              i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SR_PLANNING',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_def_events;

    PROCEDURE remove_section_events
    (
        io_tbl_all_events    IN OUT t_table_ds_events,
        i_tbl_evts_to_remove IN t_table_ds_events
    ) IS
        l_idx              PLS_INTEGER;
        l_tbl_final_events t_table_ds_events;
    BEGIN
        IF i_tbl_evts_to_remove.exists(1)
           AND io_tbl_all_events.exists(1)
        THEN
            --REMOVE EVENTS WHOSE TARGET IS THE TUMOR SECTION
            FOR i IN i_tbl_evts_to_remove.first .. i_tbl_evts_to_remove.last
            LOOP
                l_idx := io_tbl_all_events.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    IF i_tbl_evts_to_remove(i).id_ds_event = io_tbl_all_events(l_idx).id_ds_event
                        AND i_tbl_evts_to_remove(i).target = io_tbl_all_events(l_idx).target
                    THEN
                        io_tbl_all_events.delete(l_idx);
                    END IF;
                
                    l_idx := io_tbl_all_events.next(l_idx);
                END LOOP;
            END LOOP;
        
            --REORGANIZE TABLE ITEMS
            IF io_tbl_all_events.count > 0
            THEN
                l_tbl_final_events := t_table_ds_events();
            
                l_idx := io_tbl_all_events.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    IF io_tbl_all_events(l_idx).id_ds_event IS NOT NULL
                    THEN
                        l_tbl_final_events.extend;
                        l_tbl_final_events(l_tbl_final_events.count) := io_tbl_all_events(l_idx);
                    END IF;
                
                    l_idx := io_tbl_all_events.next(l_idx);
                END LOOP;
            
                io_tbl_all_events := l_tbl_final_events;
            END IF;
        END IF;
    END remove_section_events;

    FUNCTION handle_unav
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_current_section   IN ds_component.internal_name%TYPE,
        i_unav_num          IN NUMBER DEFAULT 1,
        io_tab_sections     IN OUT t_table_ds_sections,
        io_tab_def_events   IN OUT t_table_ds_def_events,
        io_tab_events       IN OUT t_table_ds_events,
        io_tab_items_values IN OUT t_table_ds_items_values,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE table_map_pk IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
        l_tbl_map_components_pk   table_map_pk;
        l_tbl_map_cmpt_mkt_rel_pk table_map_pk;
        --
        l_tab_sections   t_table_ds_sections := t_table_ds_sections();
        l_rec_section    t_rec_ds_sections;
        l_rec_def_event  t_rec_ds_def_events;
        l_rec_event      t_rec_ds_events;
        l_rec_item_value t_rec_ds_items_values;
    
        l_keep_parent            ds_cmpt_mkt_rel.id_ds_component_parent%TYPE;
        l_parent_rank            NUMBER;
        l_new_ds_comp_pk         PLS_INTEGER := NULL;
        l_new_ds_cmpt_mkt_rel_pk PLS_INTEGER := NULL;
    
        l_exception EXCEPTION;
    
        l_rec_unav t_rec_ds_unav_sections;
    
        g_default_unav_section_uk CONSTANT VARCHAR2(10) := '90';
    
        FUNCTION get_uk
        (
            i_current_pk IN PLS_INTEGER,
            i_num_unav   IN PLS_INTEGER
        ) RETURN PLS_INTEGER IS
        BEGIN
            RETURN to_number(i_current_pk || g_default_unav_section_uk) + i_num_unav;
        END get_uk;
    
        FUNCTION has_component_id_changed(i_ds_component_pk IN ds_component.id_ds_component%TYPE) RETURN BOOLEAN IS
        BEGIN
            IF i_ds_component_pk IS NULL
            THEN
                RETURN FALSE;
            ELSE
                RETURN(l_tbl_map_components_pk(i_ds_component_pk) IS NOT NULL);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END has_component_id_changed;
    
        FUNCTION get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk IN PLS_INTEGER) RETURN PLS_INTEGER IS
        BEGIN
            RETURN l_tbl_map_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_old_ds_cmpt_mkt_rel_pk;
        END get_new_ds_cmpt_mkt_rel_pk;
    
        FUNCTION get_new_ds_component_pk(i_old_ds_component_pk IN PLS_INTEGER) RETURN PLS_INTEGER IS
        BEGIN
            RETURN l_tbl_map_components_pk(i_old_ds_component_pk);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_old_ds_component_pk;
        END get_new_ds_component_pk;
    
        FUNCTION get_other_section_events RETURN t_table_ds_events IS
            l_tbl_unav_section t_table_ds_sections;
            l_ret              t_table_ds_events;
        BEGIN
            l_tbl_unav_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_component_name => 'REQUEST_IND_PER');
        
            SELECT t_rec_ds_events(id_ds_event    => de.id_ds_event,
                                   origin         => de.id_ds_cmpt_mkt_rel,
                                   VALUE          => de.value,
                                   target         => det.id_ds_cmpt_mkt_rel,
                                   flg_event_type => det.flg_event_type)
              BULK COLLECT
              INTO l_ret
              FROM ds_event_target det
              JOIN ds_event de
                ON de.id_ds_event = det.id_ds_event
             WHERE det.id_ds_cmpt_mkt_rel IN (SELECT /*+opt_estimate (table t rows=10)*/
                                               t.id_ds_cmpt_mkt_rel
                                                FROM TABLE(l_tbl_unav_section) t)
               AND de.id_ds_cmpt_mkt_rel NOT IN (SELECT /*+opt_estimate (table t rows=10)*/
                                                  t.id_ds_cmpt_mkt_rel
                                                   FROM TABLE(l_tbl_unav_section) t);
        
            RETURN l_ret;
        END get_other_section_events;
    
        --Returns the ds_events whose origin are fields inside the tumor section and target are fields from other sections
        FUNCTION get_evts_to_other_sects RETURN t_table_ds_events IS
            l_tbl_unav_section t_table_ds_sections;
            l_ret              t_table_ds_events;
        BEGIN
            l_tbl_unav_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_component_name => 'REQUEST_IND_PER_P');
        
            SELECT t_rec_ds_events(id_ds_event    => de.id_ds_event,
                                   origin         => de.id_ds_cmpt_mkt_rel,
                                   VALUE          => de.value,
                                   target         => det.id_ds_cmpt_mkt_rel,
                                   flg_event_type => det.flg_event_type)
              BULK COLLECT
              INTO l_ret
              FROM ds_event_target det
              JOIN ds_event de
                ON de.id_ds_event = det.id_ds_event
             WHERE de.id_ds_cmpt_mkt_rel IN (SELECT /*+opt_estimate (table t rows=10)*/
                                              t.id_ds_cmpt_mkt_rel
                                               FROM TABLE(l_tbl_unav_section) t)
               AND det.id_ds_cmpt_mkt_rel NOT IN (SELECT /*+opt_estimate (table t rows=10)*/
                                                   t.id_ds_cmpt_mkt_rel
                                                    FROM TABLE(l_tbl_unav_section) t);
        
            RETURN l_ret;
        END get_evts_to_other_sects;
    
        PROCEDURE add_other_section_events IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_other_section_events;
        
            IF l_tbl_other_evts IS NOT NULL
               AND l_tbl_other_evts.count > 0
            THEN
                IF io_tab_events IS NULL
                THEN
                    io_tab_events := t_table_ds_events();
                END IF;
            
                FOR i IN l_tbl_other_evts.first .. l_tbl_other_evts.last
                LOOP
                    io_tab_events.extend;
                    io_tab_events(io_tab_events.count) := l_tbl_other_evts(i);
                END LOOP;
            END IF;
        END add_other_section_events;
    
        PROCEDURE remove_other_section_events IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_other_section_events;
            remove_section_events(io_tbl_all_events => io_tab_events, i_tbl_evts_to_remove => l_tbl_other_evts);
        END remove_other_section_events;
    
        PROCEDURE remove_evts_to_other_sects IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_evts_to_other_sects;
            remove_section_events(io_tbl_all_events => io_tab_events, i_tbl_evts_to_remove => l_tbl_other_evts);
        END remove_evts_to_other_sects;
    
    BEGIN
    
        IF io_tab_sections.exists(1)
        THEN
        
            FOR i IN io_tab_sections.first .. io_tab_sections.last
            LOOP
            
                l_rec_section := io_tab_sections(i);
            
                l_new_ds_comp_pk := get_uk(i_current_pk => l_rec_section.id_ds_component, i_num_unav => i_unav_num);
            
                l_tbl_map_components_pk(l_rec_section.id_ds_component) := l_new_ds_comp_pk;
                l_rec_section.id_ds_component := l_new_ds_comp_pk;
            
                l_new_ds_cmpt_mkt_rel_pk := get_uk(i_current_pk => l_rec_section.id_ds_cmpt_mkt_rel,
                                                   i_num_unav   => i_unav_num);
                l_tbl_map_cmpt_mkt_rel_pk(l_rec_section.id_ds_cmpt_mkt_rel) := l_new_ds_cmpt_mkt_rel_pk;
                l_rec_section.id_ds_cmpt_mkt_rel := l_new_ds_cmpt_mkt_rel_pk;
            
                l_rec_section.internal_name := l_rec_section.internal_name || '_' || to_char(i_unav_num);
            
                IF l_rec_section.id_ds_component_parent IS NULL
                THEN
                    l_keep_parent                := l_rec_section.id_ds_component;
                    l_rec_section.rank           := l_rec_section.rank + i_unav_num + i;
                    l_parent_rank                := l_rec_section.rank;
                    l_rec_section.component_desc := l_rec_section.component_desc || '(' || i_unav_num || ')';
                ELSE
                    l_rec_section.id_ds_component_parent := l_keep_parent;
                    l_rec_section.rank                   := l_rec_section.rank + (i_unav_num * 10) + i;
                END IF;
            
                l_tab_sections.extend;
                l_tab_sections(l_tab_sections.count) := l_rec_section;
            
            END LOOP;
        END IF;
    
        io_tab_sections := l_tab_sections;
    
        IF io_tab_def_events IS NOT NULL
           AND io_tab_def_events.count > 0
        THEN
            FOR i IN io_tab_def_events.first .. io_tab_def_events.last
            LOOP
                l_rec_def_event := io_tab_def_events(i);
            
                l_rec_def_event.id_ds_cmpt_mkt_rel := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_def_event.id_ds_cmpt_mkt_rel);
            
                io_tab_def_events(i) := l_rec_def_event;
            END LOOP;
        END IF;
    
        IF i_current_section = 'REQUEST_IND_PER_P'
        THEN
            --Add section events whose target is the tumor section
            add_other_section_events;
        ELSE
            --Remove section events whose target is the tumor section
            remove_other_section_events;
        END IF;
    
        IF i_unav_num != 1
        THEN
            --Remove section events whose origin are fields inside the tumor section 
            --and target are fields from other sections
            remove_evts_to_other_sects;
        END IF;
    
        IF io_tab_events IS NOT NULL
           AND io_tab_events.count > 0
        THEN
            FOR i IN io_tab_events.first .. io_tab_events.last
            LOOP
                l_rec_event := io_tab_events(i);
            
                l_rec_event.origin := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_event.origin);
                l_rec_event.target := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_event.target);
            
                io_tab_events(i) := l_rec_event;
            END LOOP;
        END IF;
    
        IF io_tab_items_values IS NOT NULL
           AND io_tab_items_values.count > 0
        THEN
            FOR i IN io_tab_items_values.first .. io_tab_items_values.last
            LOOP
                l_rec_item_value := io_tab_items_values(i);
            
                l_rec_item_value.id_ds_cmpt_mkt_rel := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_item_value.id_ds_cmpt_mkt_rel);
                l_rec_item_value.id_ds_component    := get_new_ds_component_pk(i_old_ds_component_pk => l_rec_item_value.id_ds_component);
            
                io_tab_items_values(i) := l_rec_item_value;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SR_PLANNING',
                                              i_function => 'HANDLE_UNAV',
                                              o_error    => o_error);
            RETURN FALSE;
    END handle_unav;

    FUNCTION get_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SECTION_EVENTS_LIST';
        l_dbg_msg VARCHAR2(100 CHAR);
    
    BEGIN
        l_dbg_msg := 'get dynamic screen section list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => 'PK_SR_PLANNING', sub_object_name => c_function_name);
        IF NOT pk_dynamic_screen.get_ds_section_events_list(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_component_name => 'REQUEST_SURGERY_P_P',
                                                            i_component_type => pk_dynamic_screen.c_root_component,
                                                            o_section        => o_section,
                                                            o_def_events     => o_def_events,
                                                            o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SR_PLANNING',
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        
    END get_section_events_list;

    FUNCTION get_section_data
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_need_surgery              IN VARCHAR2 DEFAULT 'N',
        i_waiting_list              IN waiting_list.id_waiting_list%TYPE,
        i_component_name            IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type            IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_adm_indication            IN adm_indication.id_adm_indication%TYPE,
        i_inst_location             IN institution.id_institution%TYPE,
        i_id_department             IN department.id_department%TYPE,
        i_dep_clin_serv             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dep_clin_serv_surg        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sch_lvl_urg               IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_id_surg_proc_princ        IN intervention.id_intervention%TYPE,
        i_unav_val                  IN NUMBER,
        i_unav_begin                IN VARCHAR2,
        i_unav_duration             IN NUMBER,
        i_unav_duration_mea         IN unit_measure.id_unit_measure%TYPE,
        i_unav_end                  IN VARCHAR2,
        i_ask_hosp                  IN VARCHAR2,
        i_order_set                 IN VARCHAR2,
        i_anesth_field              IN VARCHAR2,
        i_anesth_value              IN VARCHAR2,
        i_adm_phy                   IN professional.id_professional%TYPE,
        o_section                   OUT pk_types.cursor_type,
        o_def_events                OUT pk_types.cursor_type,
        o_events                    OUT pk_types.cursor_type,
        o_items_values              OUT pk_types.cursor_type,
        o_data_val                  OUT CLOB,
        o_data_diag                 OUT pk_types.cursor_type,
        o_data_proc                 OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(50 CHAR) := 'GET_DR_SECTION_DATA';
        l_dbg_msg VARCHAR(200 CHAR);
    
        l_tbl_sections       t_table_ds_sections;
        l_final_tbl_sections t_table_ds_sections := t_table_ds_sections();
        r_section            t_rec_ds_sections;
        l_tbl_items_values   t_table_ds_items_values;
        l_tbl_events         t_table_ds_events;
        l_tbl_def_events     t_table_ds_def_events;
    
        l_tbl_sections_1     t_table_ds_sections;
        l_tbl_items_values_1 t_table_ds_items_values;
        l_tbl_events_1       t_table_ds_events;
        l_tbl_def_events_1   t_table_ds_def_events;
    
        l_sys_config_hide_doc sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                               i_code_cf => 'SURGICAL_EVENT_HIDE_DOC');
    
        l_sys_config_hide_uci sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                               i_code_cf => 'SURGICAL_EVENT_HIDE_UCI');
    
        l_sys_config_surg_dt_sugg sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                   i_code_cf => 'REQUEST_SURGERY_DT_SUGGESTED');
    
        l_section t_table_ds_sections;
    
        l_prof_data  pk_types.cursor_type;
        l_ret        BOOLEAN;
        l_death_date TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_ward           department.id_department%TYPE;
        l_ward_desc      pk_translation.t_desc_translation;
        l_dep_clin_serv  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clin_serv_desc pk_translation.t_desc_translation;
        l_professional   professional.id_professional%TYPE;
        l_prof_desc      pk_translation.t_desc_translation;
        l_adm_type       admission_type.id_admission_type%TYPE;
        l_adm_type_desc  pk_translation.t_desc_translation;
    
        -- ADMISSION_REQUEST_GET_DATA
        l_id_dep_clin_serv     NUMBER(24);
        l_desc_dep_clin_serv   VARCHAR2(300 CHAR);
        l_id_adm_phys          NUMBER(24);
        l_name_adm_phys        VARCHAR2(300 CHAR);
        l_id_adm_indication    NUMBER(24);
        l_desc_adm_indication  VARCHAR2(300 CHAR);
        l_id_admission_type    NUMBER(24);
        l_desc_adm_type        VARCHAR2(300 CHAR);
        l_expected_duration    NUMBER(24);
        l_id_adm_preparation   NUMBER(24);
        l_desc_adm_preparation VARCHAR2(300 CHAR);
        l_id_dest_inst         NUMBER(24);
        l_desc_dest_inst       VARCHAR2(300 CHAR);
        l_id_department        NUMBER(24);
        l_desc_depart          VARCHAR2(300 CHAR);
        l_id_room_type         NUMBER(24);
        l_desc_room_type       VARCHAR2(300 CHAR);
        l_flg_mixed_nursing    VARCHAR2(300 CHAR);
        l_id_bed_type          NUMBER(24);
        l_desc_bed_type        VARCHAR2(300 CHAR);
        l_id_pref_room         NUMBER(24);
        l_dep_pref_room        NUMBER(24);
        l_desc_pref_room       VARCHAR2(300 CHAR);
        l_flg_nit              VARCHAR2(300 CHAR);
        l_flg_nit_desc         VARCHAR2(300 CHAR);
        l_dt_nit_suggested     VARCHAR2(300 CHAR);
        l_id_nit_dcs           NUMBER(24);
        l_nit_dt_sugg_send     VARCHAR2(300 CHAR);
        l_nit_dt_sugg_char     VARCHAR2(300 CHAR);
        l_nit_location         VARCHAR2(300 CHAR);
        l_notes                VARCHAR2(300 CHAR);
        l_diag                 VARCHAR2(4000 CHAR);
        l_diag_c               pk_types.cursor_type;
    
        -- SURGERY REQUEST GET DATA
    
        l_surg_spec_id            NUMBER(24);
        l_surg_spec_desc          VARCHAR2(300 CHAR);
        l_surg_speciality         NUMBER(24);
        l_surg_speciality_desc    VARCHAR2(300 CHAR);
        l_surg_department         NUMBER(24);
        l_surg_department_desc    VARCHAR2(300 CHAR);
        l_surg_pref_id            table_number := table_number();
        l_surg_pref_desc          table_varchar;
        l_surg_proc               VARCHAR2(300 CHAR);
        l_surg_spec_ext_id        table_number := table_number();
        l_surg_spec_ext_desc      table_varchar;
        l_surg_danger_cont        VARCHAR2(300 CHAR);
        l_surg_pref_time_id       table_number := table_number();
        l_surg_pref_time_desc     table_varchar;
        l_surg_pref_time_flg      table_varchar;
        l_surg_pref_reason_id     NUMBER(24);
        l_surg_pref_reason_desc   VARCHAR2(300 CHAR);
        l_surg_duration           NUMBER(24);
        l_surg_icu                VARCHAR2(10 CHAR);
        l_surg_desc_icu           VARCHAR2(300 CHAR);
        l_surg_icu_pos            VARCHAR2(10 CHAR);
        l_surg_desc_icu_pos       VARCHAR2(300 CHAR);
        l_surg_notes              VARCHAR2(300 CHAR);
        l_surg_need               VARCHAR2(10 CHAR);
        l_surg_need_desc          VARCHAR2(300 CHAR);
        l_surg_global_anesth_desc VARCHAR2(10 CHAR);
        l_surg_global_anesth_id   VARCHAR2(2 CHAR);
        l_surg_local_anesth_desc  VARCHAR2(10 CHAR);
        l_surg_local_anesth_id    VARCHAR2(2 CHAR);
    
        l_surg_institution      NUMBER(24);
        l_surg_institution_desc VARCHAR2(300 CHAR);
    
        -- UNAVAILABILITY
    
        l_unav_start     VARCHAR2(100 CHAR);
        l_unav_start_chr VARCHAR2(100 CHAR);
        l_unav_duration  NUMBER(24);
        l_unav_end       VARCHAR2(100 CHAR);
        l_unav_end_chr   VARCHAR2(100 CHAR);
    
        -- SCHEDULING PERIOD
    
        l_sch_dt_start         VARCHAR2(100 CHAR);
        l_sch_dt_start_chr     VARCHAR2(100 CHAR);
        l_sch_lvl_urg          NUMBER(24);
        l_sch_lvl_urg_desc     VARCHAR2(200 CHAR);
        l_sch_dt_end           VARCHAR2(100 CHAR);
        l_sch_dt_end_chr       VARCHAR2(100 CHAR);
        l_sch_min_inform       NUMBER(24);
        l_sch_min_inform_um    NUMBER(24) := 1039;
        l_sch_dt_sug_surg      VARCHAR2(100 CHAR);
        l_sch_dt_sug_surg_chr  VARCHAR2(100 CHAR);
        l_sch_dt_sug_int       VARCHAR2(100 CHAR);
        l_sch_dt_sug_int_chr   VARCHAR2(100 CHAR);
        lvl_start_date_default VARCHAR2(100 CHAR);
        lvl_end_date_default   VARCHAR2(100 CHAR);
        l_today_insttimezone   TIMESTAMP WITH TIME ZONE;
    
        -- POS VERIFICATION
        l_id_sr_pos_schedule sr_pos_schedule.id_sr_pos_schedule%TYPE;
        l_pos_dt_sugg        VARCHAR2(100 CHAR);
        l_pos_dt_sugg_chr    VARCHAR2(100 CHAR);
        l_pos_notes          VARCHAR2(4000 CHAR);
        l_pos_sr_stauts      NUMBER(24);
        l_pos_desc_decision  VARCHAR2(100 CHAR);
        l_pos_valid_days     NUMBER(24);
        l_pos_desc_notes     VARCHAR2(4000 CHAR);
        l_pos_need_op        VARCHAR2(10 CHAR);
        l_pos_need_op_desc   VARCHAR2(100 CHAR);
    
        l_xml_data xmltype;
    
        l_exception EXCEPTION;
    
        l_epis_type_sr  epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_operating;
        l_epis_type_inp epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_inpatient;
    
        l_id_episode_sr  episode.id_episode%TYPE;
        l_id_episode_inp episode.id_episode%TYPE;
    
        l_interv_clinical_questions pk_types.cursor_type;
    
        l_unit_measure_rs unit_measure.id_unit_measure%TYPE;
        l_surg_date       schedule_sr.dt_target_tstz%TYPE;
    
        l_unav_duration_umea unit_measure.id_unit_measure%TYPE;
        l_days_diff          NUMBER;
        l_unav_end_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_has_lvl_urg VARCHAR2(1 CHAR);
        l_has_unav    VARCHAR2(1 CHAR);
    
        l_id_market market.id_market%TYPE := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        PROCEDURE add_data_val
        (
            i_idx_section IN NUMBER,
            i_desc_value  IN VARCHAR2,
            i_value       IN NUMBER DEFAULT NULL,
            i_alt_value   IN VARCHAR2 DEFAULT NULL,
            i_vs_int_name IN VARCHAR2 DEFAULT NULL
        ) IS
            l_rec_data_val t_rec_ds_items_values;
        BEGIN
            l_rec_data_val := NEW t_rec_ds_items_values(id_ds_cmpt_mkt_rel => l_final_tbl_sections(i_idx_section).id_ds_cmpt_mkt_rel,
                                                        id_ds_component    => NULL,
                                                        internal_name      => i_vs_int_name,
                                                        flg_component_type => NULL,
                                                        item_desc          => i_desc_value,
                                                        item_value         => i_value,
                                                        item_alt_value     => i_alt_value,
                                                        item_xml_value     => NULL,
                                                        item_rank          => NULL);
        
            l_final_tbl_sections(i_idx_section).component_values.extend;
            l_final_tbl_sections(i_idx_section).component_values(l_final_tbl_sections(i_idx_section).component_values.count) := l_rec_data_val;
        END add_data_val;
    
        PROCEDURE add_default_values
        (
            i_idx_section   IN NUMBER,
            i_internal_name IN ds_component.internal_name%TYPE
        ) IS
        
            clob_duration CLOB;
        BEGIN
        
            CASE
                WHEN i_internal_name = 'RS_PREV_DURATION_P' THEN
                
                    IF l_surg_duration IS NULL
                       AND i_id_surg_proc_princ IS NOT NULL
                    THEN
                        BEGIN
                            SELECT i.duration / 60
                              INTO l_surg_duration
                              FROM intervention i
                             WHERE i.id_intervention = i_id_surg_proc_princ;
                        
                            l_unit_measure_rs := pk_admission_request.g_unit_measure_hours;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_surg_duration := NULL;
                            
                        END;
                    
                    END IF;
                
                    IF l_surg_duration IS NOT NULL
                    THEN
                        add_data_val(i_idx_section => i_idx_section,
                                     
                                     i_desc_value  => CASE
                                                          WHEN l_surg_duration IS NULL THEN
                                                           NULL
                                                          ELSE
                                                           l_surg_duration || ' ' ||
                                                           pk_translation.get_translation(i_lang,
                                                                                          'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                          g_unit_measure_hours)
                                                      END,
                                     i_value       => l_surg_duration,
                                     i_alt_value   => g_unit_measure_hours,
                                     i_vs_int_name => i_internal_name);
                    END IF;
                
                WHEN i_internal_name = 'RSP_TIME_MIN_P' THEN
                
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => ' ',
                                 i_value       => NULL,
                                 i_alt_value   => g_unit_measure_days,
                                 i_vs_int_name => i_internal_name);
                
                    lvl_start_date_default := NULL;
                    lvl_end_date_default   := NULL;
                
                WHEN i_internal_name = 'RSP_BEGIN_SCHED_P' THEN
                    IF i_sch_lvl_urg IS NOT NULL
                    THEN
                    
                        SELECT pk_date_utils.date_send(i_lang, l_today_insttimezone, i_prof)
                          INTO lvl_start_date_default
                          FROM dual;
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_start_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_start_date_default));
                    END IF;
                
                WHEN i_internal_name = 'RSP_END_SCHED_P' THEN
                    IF i_sch_lvl_urg IS NOT NULL
                    THEN
                    
                        SELECT pk_date_utils.date_send(i_lang, l_today_insttimezone + to_number(wul.duration), i_prof)
                          INTO lvl_end_date_default
                          FROM wtl_urg_level wul
                         WHERE wul.id_wtl_urg_level = i_sch_lvl_urg;
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_end_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_end_date_default));
                    END IF;
                
                WHEN i_internal_name LIKE 'RIP_DURATION_P%' THEN
                    IF i_unav_duration IS NULL
                       AND i_unav_end IS NOT NULL
                    THEN
                    
                        SELECT ((round(pk_date_utils.get_timestamp_diff(pk_date_utils.get_string_tstz(i_lang,
                                                                                                      i_prof,
                                                                                                      i_unav_end,
                                                                                                      NULL),
                                                                        pk_date_utils.get_string_tstz(i_lang,
                                                                                                      i_prof,
                                                                                                      i_unav_begin,
                                                                                                      NULL))) * 24 * 60) +
                               24 * 60)
                          INTO l_days_diff
                          FROM dual;
                    
                        IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_hours        => l_days_diff,
                                                            i_date         => NULL,
                                                            o_value        => l_days_diff,
                                                            o_unit_measure => l_unav_duration_umea,
                                                            o_error        => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     
                                     i_desc_value => l_days_diff || ' ' ||
                                                     pk_translation.get_translation(i_lang,
                                                                                    'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                    l_unav_duration_umea),
                                     
                                     i_value       => l_days_diff,
                                     i_alt_value   => l_unav_duration_umea,
                                     i_vs_int_name => i_internal_name);
                    
                    END IF;
                
                    IF i_unav_duration IS NULL
                       AND i_unav_end IS NULL
                    THEN
                        add_data_val(i_idx_section => i_idx_section,
                                     
                                     i_desc_value => NULL,
                                     
                                     i_value       => NULL,
                                     i_alt_value   => g_unit_measure_days,
                                     i_vs_int_name => i_internal_name);
                    
                    END IF;
                
                WHEN i_internal_name LIKE 'RIP_END_PER_P%' THEN
                    IF i_unav_duration IS NOT NULL
                       AND i_unav_duration > 0
                       AND i_unav_end IS NULL
                    THEN
                    
                        CASE i_unav_duration_mea
                            WHEN 10373 THEN
                                l_days_diff := i_unav_duration * 365;
                            WHEN 1127 THEN
                                l_days_diff := i_unav_duration * 30;
                            WHEN 10375 THEN
                                l_days_diff := i_unav_duration * 7;
                            ELSE
                                l_days_diff := i_unav_duration;
                        END CASE;
                    
                        l_unav_end_tstz := pk_date_utils.add_days_to_tstz(i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                       i_prof,
                                                                                                                       i_unav_begin,
                                                                                                                       NULL),
                                                                          i_days      => (l_days_diff - 1));
                    
                        lvl_start_date_default := pk_date_utils.date_send(i_lang, l_unav_end_tstz, i_prof);
                    
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => pk_date_utils.date_chr_short_read_str(i_lang,
                                                                                            lvl_start_date_default,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                     i_value       => to_number(lvl_start_date_default));
                    END IF;
                
                    IF (i_unav_duration = 0 OR i_unav_duration IS NULL)
                       AND i_unav_end IS NULL
                    THEN
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => ' ',
                                     i_value       => NULL,
                                     i_vs_int_name => i_internal_name);
                    
                    END IF;
                
                ELSE
                    NULL;
            END CASE;
            NULL;
        
        END add_default_values;
    
        PROCEDURE add_values
        (
            i_idx_section   IN NUMBER,
            i_internal_name IN ds_component.internal_name%TYPE
        ) IS
        
        BEGIN
        
            CASE
            
                WHEN i_internal_name = 'RS_SUR_NEED_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_need_desc,
                                 i_alt_value   => l_surg_need);
                WHEN i_internal_name = 'RS_LOC_SURGERY_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_institution_desc,
                                 i_value       => l_surg_institution);
                WHEN i_internal_name = 'RS_SPEC_SURGERY_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_speciality_desc,
                                 i_value       => l_surg_speciality);
                WHEN i_internal_name = 'RS_CLIN_SERVICE_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_spec_desc,
                                 i_value       => l_surg_spec_id);
                WHEN i_internal_name = 'RS_DEPARTMENT_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_department_desc,
                                 i_value       => l_surg_department);
                WHEN i_internal_name = 'RS_GLOBAL_ANESTH_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_global_anesth_desc,
                                 i_alt_value   => l_surg_global_anesth_id);
                WHEN i_internal_name = 'RS_LOCAL_ANESTH_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_local_anesth_desc,
                                 i_alt_value   => l_surg_local_anesth_id);
                WHEN i_internal_name = 'RS_PREF_SURG_P' THEN
                    FOR i IN 1 .. l_surg_pref_id.count
                    LOOP
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_pref_desc(i),
                                     i_value       => l_surg_pref_id(i));
                    END LOOP;
                WHEN i_internal_name = 'RS_PROC_SURG_P' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_surg_proc, i_value => NULL);
                WHEN i_internal_name = 'RS_PREV_DURATION_P' THEN
                
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_surg_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_surg_duration || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      l_unit_measure_rs)
                                                  END,
                                 i_value       => l_surg_duration,
                                 i_alt_value   => CASE
                                                      WHEN l_surg_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_unit_measure_rs
                                                  END);
                WHEN i_internal_name IN ('RS_UCI_P') THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_desc_icu,
                                 i_alt_value   => l_surg_icu);
                WHEN i_internal_name IN ('RS_UCI_POS_P') THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_desc_icu_pos,
                                 i_alt_value   => l_surg_icu_pos);
                WHEN i_internal_name = 'RS_EXT_SPEC_P' THEN
                    FOR i IN 1 .. l_surg_spec_ext_id.count
                    LOOP
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_spec_ext_desc(i),
                                     i_value       => l_surg_spec_ext_id(i));
                    END LOOP;
                WHEN i_internal_name = 'RS_CONT_DANGER_P' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_surg_danger_cont, i_value => NULL);
                WHEN i_internal_name = 'RS_PREF_TIME_P' THEN
                
                    FOR i IN 1 .. l_surg_pref_time_id.count
                    LOOP
                        add_data_val(i_idx_section => i_idx_section,
                                     i_desc_value  => l_surg_pref_time_desc(i),
                                     i_value       => get_value_from_time_pref(l_surg_pref_time_flg(i)));
                    END LOOP;
                WHEN i_internal_name = 'RS_MOT_PREF_TIME_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_surg_pref_reason_desc,
                                 i_value       => l_surg_pref_reason_id);
                WHEN i_internal_name = 'RS_NOTES_P' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_surg_notes, i_value => NULL);
                WHEN i_internal_name LIKE 'RIP_BEGIN_PER_P%' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_unav_start_chr,
                                 i_value       => l_unav_start);
                WHEN i_internal_name LIKE 'RIP_DURATION_P%' THEN
                    --add_data_val(i_idx_section => i_idx_section, i_desc_value => l_unav_duration, i_value => NULL);
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_unav_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_unav_duration || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      l_unav_duration_umea)
                                                  END,
                                 i_value       => l_unav_duration,
                                 i_alt_value   => CASE
                                                      WHEN l_unav_duration IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_unav_duration_umea
                                                  END);
                WHEN i_internal_name LIKE 'RIP_END_PER_P%' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_unav_end_chr, i_value => l_unav_end);
                WHEN i_internal_name = 'RSP_LVL_URG_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_lvl_urg_desc,
                                 i_value       => l_sch_lvl_urg);
                WHEN i_internal_name = 'RSP_BEGIN_SCHED_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_start_chr,
                                 i_value       => l_sch_dt_start);
                WHEN i_internal_name = 'RSP_END_SCHED_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_end_chr,
                                 i_value       => l_sch_dt_end);
                WHEN i_internal_name = 'RSP_TIME_MIN_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => CASE
                                                      WHEN l_sch_min_inform IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_sch_min_inform || ' ' ||
                                                       pk_translation.get_translation(i_lang,
                                                                                      'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                                      l_sch_min_inform_um)
                                                  END,
                                 i_value       => l_sch_min_inform,
                                 i_alt_value   => CASE
                                                      WHEN l_sch_min_inform IS NULL THEN
                                                       NULL
                                                      ELSE
                                                       l_sch_min_inform_um
                                                  END);
                
                WHEN i_internal_name = 'RSP_SUGG_DT_SURG_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_sug_surg_chr,
                                 i_value       => l_sch_dt_sug_surg);
                WHEN i_internal_name = 'RSP_SUGG_DT_INT_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_sch_dt_sug_int_chr,
                                 i_value       => l_sch_dt_sug_int);
                
                WHEN i_internal_name = 'RV_REQUEST_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_need_op_desc,
                                 i_alt_value   => l_pos_need_op);
                WHEN i_internal_name = 'RV_DT_VERIF_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_dt_sugg_chr,
                                 i_value       => l_pos_dt_sugg);
                WHEN i_internal_name = 'RV_NOTES_REQ_P' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_pos_notes, i_value => NULL);
                WHEN i_internal_name = 'RV_DECISION_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_desc_decision,
                                 i_value       => l_pos_sr_stauts);
                WHEN i_internal_name = 'RV_VALID_P' THEN
                    add_data_val(i_idx_section => i_idx_section,
                                 i_desc_value  => l_pos_valid_days,
                                 i_value       => l_pos_valid_days);
                WHEN i_internal_name = 'RV_NOTES_DECIS_P' THEN
                    add_data_val(i_idx_section => i_idx_section, i_desc_value => l_pos_desc_notes, i_value => NULL);
                
                ELSE
                    NULL;
            END CASE;
        
        END add_values;
    
        PROCEDURE add_new_item
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            i_item_desc          IN pk_translation.t_desc_translation,
            i_item_value         IN sys_list.id_sys_list%TYPE,
            i_item_alt_value     IN sys_list_group_rel.flg_context%TYPE,
            i_item_xml_value     IN CLOB DEFAULT NULL,
            i_item_rank          IN sys_list_group_rel.rank%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_ITEM';
            --
            r_item_value t_rec_ds_items_values;
        BEGIN
            g_error      := 'NEW T_REC_DS_ITEMS_VALUES INSTANCE';
            r_item_value := t_rec_ds_items_values(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                                  id_ds_component    => i_ds_component,
                                                  internal_name      => i_internal_name,
                                                  flg_component_type => i_flg_component_type,
                                                  item_desc          => i_item_desc,
                                                  item_value         => i_item_value,
                                                  item_alt_value     => i_item_alt_value,
                                                  item_xml_value     => i_item_xml_value,
                                                  item_rank          => i_item_rank);
        
            g_error := 'ADD TO TABLE L_TBL_ITEMS_VALUES';
            io_tbl_items_values.extend;
            io_tbl_items_values(io_tbl_items_values.count) := r_item_value;
        END add_new_item;
    
        PROCEDURE add_sample_text
        (
            i_intern_name_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
            io_section                     IN OUT t_rec_ds_sections
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SAMPLE_TEXT';
        BEGIN
            g_error := 'ADD SAMPLE TEXT ADDITIONAL_INFO TO SECTION: ' || io_section.internal_name;
        
            SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.intern_name_sample_text_type)).getclobval()
              INTO io_section.addit_info_xml_value
              FROM (SELECT i_intern_name_sample_text_type intern_name_sample_text_type
                      FROM dual) t;
        END add_sample_text;
    
        PROCEDURE add_inst_location
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INST_LOCATION';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_flg_default VARCHAR(2 CHAR);
        
            l_addict_info CLOB;
        BEGIN
            g_error := 'CALL PK_LIST.GET_ORIGIN_LIST';
            IF NOT pk_sr_planning.get_location_list(i_lang  => i_lang,
                                                    i_prof  => i_prof,
                                                    o_list  => c_list,
                                                    o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_surg_institution := i_prof.institution;
            g_error            := 'ADD ALL INST LOCATIONS';
        
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_flg_default;
                EXIT WHEN c_list%NOTFOUND;
            
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(l_id_inst, nvl(i_inst_location, i_prof.institution), pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_default)).getclobval() addit_info
                  INTO l_addict_info
                  FROM dual;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_xml_value     => l_addict_info,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_inst_location;
    
        PROCEDURE add_nurse_intake
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_NURSE_INTAKE';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     VARCHAR2(5 CHAR);
            l_img_name    VARCHAR2(200 CHAR);
            l_rank        NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_admission_request.get_nurse_intake_yesno_list(i_lang  => i_lang,
                                                                    i_prof  => i_prof,
                                                                    o_list  => c_list,
                                                                    o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
            
                EXIT WHEN c_list%NOTFOUND;
            
                /*SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(l_id_inst, pk_alert_constant.g_yes, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_default))
                     .getclobval() addit_info
                INTO l_addict_info
                FROM dual;*/
            
                IF i_internal_name NOT IN
                   ('RS_SUR_NEED_P', 'RS_UCI_P', 'RS_UCI_POS_P', 'RS_GLOBAL_ANESTH_P', 'RS_LOCAL_ANESTH_P')
                THEN
                    SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(decode(l_id_inst, pk_alert_constant.g_yes, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS flg_default)).getclobval() addit_info
                      INTO l_addict_info
                      FROM dual;
                END IF;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => NULL,
                             i_item_alt_value     => l_id_inst,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_nurse_intake;
    
        PROCEDURE add_spec_surgery
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SPEC_SURGERY';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc  VARCHAR2(300 CHAR);
            l_id_inst    NUMBER;
            l_addit_info CLOB;
        BEGIN
        
            CASE
                WHEN i_internal_name = 'RS_SPEC_SURGERY_P'
                     AND l_id_market != pk_alert_constant.g_id_market_cl THEN
                
                    IF NOT pk_list.get_specialty_list(i_lang => i_lang, o_specialty_list => c_list, o_error => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        IF l_id_inst = pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_prof)
                        THEN
                            SELECT xmlelement("ADDITIONAL_INFO", xmlattributes((pk_alert_constant.g_yes) AS flg_default)).getclobval()
                              INTO l_addit_info
                              FROM dual;
                        END IF;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     i_item_xml_value     => l_addit_info,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                    CLOSE c_list;
                
                WHEN i_internal_name = 'RS_DEPARTMENT_P' THEN
                
                    IF NOT pk_surgery_request.get_department(i_lang  => i_lang,
                                                             i_prof  => i_prof,
                                                             i_inst  => nvl(i_inst_location, l_surg_institution),
                                                             o_cs    => c_list,
                                                             o_error => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'ADD ALL INST LOCATIONS';
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc, l_addit_info;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     i_item_xml_value     => l_addit_info,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                    CLOSE c_list;
                
                ELSE
                
                    IF NOT pk_surgery_request.get_dep_clin_serv_ds(i_lang  => i_lang,
                                                                   i_prof  => i_prof,
                                                                   i_inst  => nvl(i_inst_location, l_surg_institution),
                                                                   i_dept  => i_id_department,
                                                                   o_cs    => c_list,
                                                                   o_error => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'ADD ALL INST LOCATIONS';
                    LOOP
                        FETCH c_list
                            INTO l_id_inst, l_inst_desc;
                        EXIT WHEN c_list%NOTFOUND;
                    
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => l_inst_desc,
                                     i_item_value         => l_id_inst,
                                     i_item_alt_value     => NULL,
                                     i_item_rank          => NULL,
                                     io_tbl_items_values  => l_tbl_items_values);
                    END LOOP;
                    CLOSE c_list;
            END CASE;
        
        END add_spec_surgery;
    
        PROCEDURE add_surgeons
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SURGEONS';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     NUMBER;
            l_addict_info CLOB;
            l_no          VARCHAR2(2 CHAR);
            l_num         NUMBER;
        BEGIN
        
            IF NOT pk_surgery_request.get_surgeons_by_dep_clin_serv(i_lang     => i_lang,
                                                                    i_prof     => i_prof,
                                                                    i_inst     => nvl(i_inst_location, l_surg_institution),
                                                                    i_id_dcs   => nvl(i_dep_clin_serv_surg, l_surg_spec_id),
                                                                    o_surgeons => c_list,
                                                                    o_error    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_no, l_num, l_addict_info;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             i_item_xml_value     => l_addict_info,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_surgeons;
    
        PROCEDURE add_pref_time
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_SURGEONS';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc   VARCHAR2(300 CHAR);
            l_id_inst     VARCHAR2(5 CHAR);
            l_img_name    VARCHAR2(200 CHAR);
            l_rank        NUMBER;
            l_addict_info CLOB;
        BEGIN
        
            IF NOT pk_sysdomain.get_values_domain('WTL_PREF_TIME.FLG_VALUE', i_lang, c_list)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => get_value_from_time_pref(l_id_inst),
                             i_item_alt_value     => l_id_inst,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_pref_time;
    
        PROCEDURE add_mot_pref_time
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INST_DEP';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc VARCHAR2(300 CHAR);
            l_id_inst   NUMBER;
        
            l_addit_info CLOB;
        BEGIN
        
            IF NOT pk_surgery_request.get_wtl_ptreason_list(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_id_institution => nvl(i_inst_location, l_surg_institution),
                                                            o_list           => c_list,
                                                            o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_mot_pref_time;
    
        PROCEDURE add_lvl_urg
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_RV_REQUEST';
            --
            c_list pk_types.cursor_type;
        
            c_origin pk_list.cursor_origin;
            r_origin pk_list.rec_origin;
        
            l_inst_desc  VARCHAR2(300 CHAR);
            l_id_inst    NUMBER;
            l_start      VARCHAR2(100 CHAR);
            l_end        VARCHAR2(100 CHAR);
            l_duration   NUMBER;
            l_addit_info CLOB;
        BEGIN
        
            IF NOT pk_surgery_request.get_wtl_urg_level_list(i_lang  => i_lang,
                                                             i_prof  => i_prof,
                                                             o_list  => c_list,
                                                             o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_inst, l_inst_desc, l_start, l_end, l_duration;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => l_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_lvl_urg;
    
        PROCEDURE add_unit_measure_rs
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_UNIT_MEASURE';
            --
            c_list pk_types.cursor_type;
        
            l_id_unit_measure         NUMBER(24);
            l_id_unit_measure_subtype NUMBER(24);
            l_code_unit_measure       VARCHAR2(100 CHAR);
            l_transl_unit_measure     VARCHAR2(100 CHAR);
            l_rank                    NUMBER(24);
            l_addit_info              CLOB;
        
            l_unit_default NUMBER := pk_admission_request.g_dyn_unit_meas_type;
        
        BEGIN
        
            IF l_surg_duration IS NULL
               AND i_internal_name = 'RS_PREV_DURATION_P'
            THEN
                l_unit_measure_rs := pk_admission_request.g_unit_measure_hours;
            ELSIF l_surg_duration IS NULL
                  AND (i_internal_name = 'RSP_TIME_MIN_P' OR i_internal_name LIKE 'RIP_DURATION_P%')
            THEN
                l_unit_measure_rs := pk_admission_request.g_unit_measure_days;
            ELSE
                IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_hours        => l_surg_duration,
                                                    i_date         => l_surg_date,
                                                    o_value        => l_surg_duration,
                                                    o_unit_measure => l_unit_measure_rs,
                                                    o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
            IF i_internal_name = ('RS_PREV_DURATION_P')
            THEN
                l_unit_default := 581;
            END IF;
        
            IF NOT pk_unit_measure.get_umea_type_ds(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_unit_measure_subtype => l_unit_default,
                                                    i_unit_measure         => l_unit_measure_rs,
                                                    o_list                 => c_list,
                                                    o_error                => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_id_unit_measure,
                         l_id_unit_measure_subtype,
                         l_code_unit_measure,
                         l_transl_unit_measure,
                         l_rank,
                         l_addit_info;
                EXIT WHEN c_list%NOTFOUND;
            
                IF (i_internal_name = 'RSP_TIME_MIN_P' OR i_internal_name LIKE 'RIP_DURATION_P%')
                   AND l_id_unit_measure != 1041
                   OR i_internal_name IN ('RS_PREV_DURATION_P')
                THEN
                
                    add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                 i_ds_component       => i_ds_component,
                                 i_internal_name      => i_internal_name,
                                 i_flg_component_type => i_flg_component_type,
                                 i_item_desc          => l_transl_unit_measure,
                                 i_item_value         => l_id_unit_measure,
                                 i_item_alt_value     => NULL,
                                 i_item_rank          => NULL,
                                 i_item_xml_value     => l_addit_info,
                                 io_tbl_items_values  => l_tbl_items_values);
                
                END IF;
            END LOOP;
        
            CLOSE c_list;
        END add_unit_measure_rs;
    
    BEGIN
    
        l_dbg_msg := 'get dynamic screen section complete structure';
        pk_alertlog.log_info(text            => l_dbg_msg,
                             object_name     => 'Pk_ADMISSION_REQUEST',
                             sub_object_name => 'GET_SECTION_DATA');
    
        l_today_insttimezone := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, 'DD');
    
        IF i_waiting_list IS NOT NULL
        THEN
        
            BEGIN
                SELECT wtle.id_episode
                  INTO l_id_episode_sr
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = i_waiting_list
                   AND wtle.id_epis_type = l_epis_type_sr;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_episode_sr := NULL;
            END;
        
            BEGIN
                SELECT wtle.id_episode
                  INTO l_id_episode_inp
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = i_waiting_list
                   AND wtle.id_epis_type = l_epis_type_inp;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_episode_inp := NULL;
            END;
        
            IF i_component_name = 'REQUEST_SURGERY_P'
            THEN
            
                IF l_id_episode_sr IS NOT NULL
                THEN
                    IF NOT pk_surgery_request.get_surgery_request_ds(i_lang                      => i_lang,
                                                                     i_prof                      => i_prof,
                                                                     i_id_episode                => l_id_episode_sr,
                                                                     i_id_waiting_list           => i_waiting_list,
                                                                     o_surg_date                 => l_surg_date,
                                                                     o_surg_spec_id              => l_surg_spec_id,
                                                                     o_surg_spec_desc            => l_surg_spec_desc,
                                                                     o_surg_speciality           => l_surg_speciality,
                                                                     o_surg_speciality_desc      => l_surg_speciality_desc,
                                                                     o_surg_department           => l_surg_department,
                                                                     o_surg_department_desc      => l_surg_department_desc,
                                                                     o_surg_pref_id              => l_surg_pref_id,
                                                                     o_surg_pref_desc            => l_surg_pref_desc,
                                                                     o_surg_proc                 => l_surg_proc,
                                                                     o_surg_spec_ext_id          => l_surg_spec_ext_id,
                                                                     o_surg_spec_ext_desc        => l_surg_spec_ext_desc,
                                                                     o_surg_danger_cont          => l_surg_danger_cont,
                                                                     o_surg_pref_time_id         => l_surg_pref_time_id,
                                                                     o_surg_pref_time_desc       => l_surg_pref_time_desc,
                                                                     o_surg_pref_time_flg        => l_surg_pref_time_flg,
                                                                     o_surg_pref_reason_id       => l_surg_pref_reason_id,
                                                                     o_surg_pref_reason_desc     => l_surg_pref_reason_desc,
                                                                     o_surg_duration             => l_surg_duration,
                                                                     o_surg_icu                  => l_surg_icu,
                                                                     o_surg_desc_icu             => l_surg_desc_icu,
                                                                     o_surg_icu_pos              => l_surg_icu_pos,
                                                                     o_surg_desc_icu_pos         => l_surg_desc_icu_pos,
                                                                     o_surg_notes                => l_surg_notes,
                                                                     o_surg_need                 => l_surg_need,
                                                                     o_surg_need_desc            => l_surg_need_desc,
                                                                     o_surg_institution          => l_surg_institution,
                                                                     o_surg_institution_desc     => l_surg_institution_desc,
                                                                     o_procedures                => o_data_proc,
                                                                     o_interv_clinical_questions => o_interv_clinical_questions,
                                                                     o_danger_cont               => o_data_diag,
                                                                     o_interv_supplies           => o_interv_supplies,
                                                                     o_global_anesth_desc        => l_surg_global_anesth_desc,
                                                                     o_global_anesth_id          => l_surg_global_anesth_id,
                                                                     o_local_anesth_desc         => l_surg_local_anesth_desc,
                                                                     o_local_anesth_id           => l_surg_local_anesth_id,
                                                                     o_error                     => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            END IF;
        
            IF i_component_name LIKE 'REQUEST_IND_PER_P%'
            THEN
            
                BEGIN
                    SELECT z.dt_unav_start_send,
                           z.dt_unav_start_char,
                           z.duration,
                           z.dt_unav_end_send,
                           z.dt_unav_end_char
                      INTO l_unav_start, l_unav_start_chr, l_unav_duration, l_unav_end, l_unav_end_chr
                      FROM (SELECT pk_date_utils.date_send_tsz(i_lang, u.dt_unav_start, i_prof) dt_unav_start_send,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               u.dt_unav_start,
                                                               i_prof.institution,
                                                               i_prof.software) dt_unav_start_char,
                                   (round(pk_date_utils.get_timestamp_diff(u.dt_unav_end, u.dt_unav_start)) * 24 * 60) +
                                   24 * 60 duration,
                                   pk_date_utils.date_send_tsz(i_lang, u.dt_unav_end, i_prof) dt_unav_end_send,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               u.dt_unav_end,
                                                               i_prof.institution,
                                                               i_prof.software) dt_unav_end_char,
                                   row_number() over(PARTITION BY u.id_waiting_list ORDER BY u.id_wtl_unav) rn
                              FROM wtl_unav u
                             WHERE u.id_waiting_list = i_waiting_list
                               AND u.flg_status = pk_alert_constant.g_active
                             ORDER BY u.id_wtl_unav) z
                     WHERE rn = (i_unav_val + 1);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_unav_start    := NULL;
                        l_unav_duration := NULL;
                        l_unav_end      := NULL;
                END;
            
                IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_hours        => l_unav_duration,
                                                    i_date         => NULL,
                                                    o_value        => l_unav_duration,
                                                    o_unit_measure => l_unav_duration_umea,
                                                    o_error        => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF l_unav_start IS NOT NULL
                THEN
                    l_has_unav := pk_alert_constant.g_yes;
                END IF;
            
            END IF;
        
            IF i_component_name = 'REQUEST_SCHED_PER_P'
            THEN
            
                BEGIN
                    SELECT -- 16 - Scheduling period start
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_dpb, i_prof) dt_sched_start_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_dpb, i_prof.institution, i_prof.software) dt_sched_start_char,
                     -- 17 - Urg level
                     wl.id_wtl_urg_level,
                     nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) desc_urg_level,
                     --wul.duration duration_urg_level,
                     -- 18 - Scheduling period end
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_dpa, i_prof) dt_sched_end_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_dpa, i_prof.institution, i_prof.software) dt_sched_end_char,
                     -- 19 - Minimum time to inform
                     wl.min_inform_time,
                     -- 20 - Suggested surgery date / Suggested admission date
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_surgery, i_prof) dt_sug_surg_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_surgery, i_prof.institution, i_prof.software) dt_sug_surg_char,
                     pk_date_utils.date_send_tsz(i_lang, wl.dt_admission, i_prof) dt_sug_admission_send,
                     pk_date_utils.date_char_tsz(i_lang, wl.dt_admission, i_prof.institution, i_prof.software) dt_sug_admission_char
                    -- 21 - Surgery date
                    --pk_date_utils.date_send_tsz(i_lang, s.dt_target_tstz, i_prof) dt_surgery_send,
                    --pk_date_utils.date_char_tsz(i_lang, s.dt_target_tstz, i_prof.institution, i_prof.software) dt_surgery_char,
                    -- 22 - Admission date
                    --pk_date_utils.date_send_tsz(i_lang, adm.dt_admission, i_prof) dt_admission_send,
                    --pk_date_utils.date_char_tsz(i_lang, adm.dt_admission, i_prof.institution, i_prof.software) dt_admission_char
                      INTO l_sch_dt_start,
                           l_sch_dt_start_chr,
                           l_sch_lvl_urg,
                           l_sch_lvl_urg_desc,
                           l_sch_dt_end,
                           l_sch_dt_end_chr,
                           l_sch_min_inform,
                           l_sch_dt_sug_surg,
                           l_sch_dt_sug_surg_chr,
                           l_sch_dt_sug_int,
                           l_sch_dt_sug_int_chr
                      FROM waiting_list wl
                      LEFT JOIN wtl_urg_level wul
                        ON wl.id_wtl_urg_level = wul.id_wtl_urg_level
                      LEFT JOIN adm_request adm
                        ON adm.id_dest_episode = l_id_episode_inp
                    --INNER JOIN schedule_sr s ON wl.id_waiting_list = s.id_waiting_list
                    -- José Brito 07/05/09 Show scheduling period when there's no surgery request
                      LEFT JOIN schedule_sr s
                        ON wl.id_waiting_list = s.id_waiting_list
                     WHERE wl.id_waiting_list = i_waiting_list
                       AND (s.id_episode = l_id_episode_sr OR l_id_episode_sr IS NULL);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_sch_dt_start     := NULL;
                        l_sch_lvl_urg      := NULL;
                        l_sch_lvl_urg_desc := NULL;
                        l_sch_dt_end       := NULL;
                        l_sch_min_inform   := NULL;
                        l_sch_dt_sug_surg  := NULL;
                        l_sch_dt_sug_int   := NULL;
                END;
            
                IF l_sch_lvl_urg IS NOT NULL
                THEN
                    l_has_lvl_urg := pk_alert_constant.g_yes;
                END IF;
            
            END IF;
        
            IF i_component_name = 'REQUEST_VER_OP_P'
            THEN
            
                BEGIN
                    SELECT id_sr_pos_schedule
                      INTO l_id_sr_pos_schedule
                      FROM (SELECT sps.id_sr_pos_schedule, rank() over(ORDER BY sps.dt_req DESC) origin_rank
                              FROM schedule_sr ssr
                             INNER JOIN sr_pos_schedule sps
                                ON sps.id_schedule_sr = ssr.id_schedule_sr
                             WHERE ssr.id_waiting_list = i_waiting_list
                            
                            )
                     WHERE origin_rank = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'ID_SR_POS_SCHEDULE not found';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => 'PK_ADMISSION_REQUEST',
                                              sub_object_name => 'GET_SECTION_DATA');
                        l_id_sr_pos_schedule := NULL;
                END;
            
                IF l_id_sr_pos_schedule IS NOT NULL
                THEN
                
                    IF NOT pk_sr_pos.get_pos_decision_ds(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_sr_pos_schedule => l_id_sr_pos_schedule,
                                                         i_flg_return_opts    => pk_alert_constant.g_no,
                                                         o_pos_dt_sugg        => l_pos_dt_sugg,
                                                         o_pos_dt_sugg_chr    => l_pos_dt_sugg_chr,
                                                         o_pos_notes          => l_pos_notes,
                                                         o_pos_sr_stauts      => l_pos_sr_stauts,
                                                         o_pos_desc_decision  => l_pos_desc_decision,
                                                         o_pos_valid_days     => l_pos_valid_days,
                                                         o_pos_desc_notes     => l_pos_desc_notes,
                                                         o_pos_need_op        => l_pos_need_op,
                                                         o_pos_need_op_desc   => l_pos_need_op_desc,
                                                         o_error              => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            END IF;
        
        ELSE
        
            IF i_component_name = 'REQUEST_SURGERY_P'
            THEN
                IF NOT pk_diagnosis.get_epis_diag(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  o_diag    => o_data_diag,
                                                  o_error   => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
        END IF;
    
        IF NOT pk_dynamic_screen.get_ds_section_complete_struct(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_component_name => i_component_name,
                                                                i_component_type => nvl(i_component_type,
                                                                                        pk_dynamic_screen.c_node_component),
                                                                i_patient        => i_patient,
                                                                o_section        => l_tbl_sections,
                                                                o_def_events     => l_tbl_def_events,
                                                                o_events         => l_tbl_events,
                                                                o_items_values   => l_tbl_items_values,
                                                                o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        END IF;
    
        IF i_unav_val > 0
           AND i_component_name LIKE 'REQUEST_IND_PER_P%'
        THEN
        
            IF NOT handle_unav(i_lang              => i_lang,
                               i_prof              => i_prof,
                               i_episode           => i_episode,
                               i_current_section   => 'REQUEST_IND_PER_P',
                               i_unav_num          => i_unav_val,
                               io_tab_sections     => l_tbl_sections,
                               io_tab_def_events   => l_tbl_def_events,
                               io_tab_events       => l_tbl_events,
                               io_tab_items_values => l_tbl_items_values,
                               o_error             => o_error)
            THEN
                pk_types.open_my_cursor(i_cursor => o_section);
                pk_types.open_my_cursor(i_cursor => o_def_events);
                pk_types.open_my_cursor(i_cursor => o_events);
                pk_types.open_my_cursor(i_cursor => o_items_values);
                o_data_val := NULL;
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF (i_inst_location IS NOT NULL AND i_id_department IS NULL)
           OR l_id_dest_inst IS NOT NULL
        THEN
            -- GET_DEFAULTS_WITH_LOCATION
            IF NOT pk_admission_request.get_defaults_with_location(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_adm_indication => nvl(i_adm_indication,
                                                                                           l_id_adm_indication),
                                                                   i_location       => nvl(i_inst_location, l_id_dest_inst),
                                                                   o_ward           => l_ward,
                                                                   o_ward_desc      => l_ward_desc,
                                                                   o_dep_clin_serv  => l_dep_clin_serv,
                                                                   o_clin_serv_desc => l_clin_serv_desc,
                                                                   o_professional   => l_professional,
                                                                   o_prof_desc      => l_prof_desc,
                                                                   o_adm_type       => l_adm_type,
                                                                   o_adm_type_desc  => l_adm_type_desc,
                                                                   o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF (i_id_department IS NOT NULL AND i_dep_clin_serv IS NULL)
           OR l_id_department IS NOT NULL
        THEN
            -- GET_DEFAULTS_WITH_WARD
            IF NOT
                pk_admission_request.get_defaults_with_ward(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_adm_indication => nvl(i_adm_indication, l_id_adm_indication),
                                                            i_ward           => nvl(i_id_department, l_id_department),
                                                            o_dep_clin_serv  => l_dep_clin_serv,
                                                            o_clin_serv_desc => l_clin_serv_desc,
                                                            o_professional   => l_professional,
                                                            o_prof_desc      => l_prof_desc,
                                                            o_adm_type       => l_adm_type,
                                                            o_adm_type_desc  => l_adm_type_desc,
                                                            o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF i_dep_clin_serv IS NOT NULL
           OR l_id_dep_clin_serv IS NOT NULL
        THEN
            -- GET_DEFAULTS_WITH_DCS
            IF NOT pk_admission_request.get_defaults_with_dcs(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_dep_clin_serv => nvl(i_dep_clin_serv, l_id_dep_clin_serv),
                                                              o_professional  => l_professional,
                                                              o_prof_desc     => l_prof_desc,
                                                              o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_sch_min_inform IS NOT NULL
        THEN
            IF NOT get_duration_unit_measure_ds(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_hours        => (l_sch_min_inform * 24 * 60),
                                                i_date         => l_surg_date,
                                                o_value        => l_sch_min_inform,
                                                o_unit_measure => l_sch_min_inform_um,
                                                o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR i IN l_tbl_sections.first .. l_tbl_sections.last
        LOOP
            r_section := l_tbl_sections(i);
        
            CASE
                WHEN r_section.internal_name IN ('RS_LOC_SURGERY_P') THEN
                
                    r_section.addit_info_xml_value := 'TYPE_SR_PROC_P';
                
                    add_inst_location(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component       => r_section.id_ds_component,
                                      i_internal_name      => r_section.internal_name,
                                      i_flg_component_type => r_section.flg_component_type);
                
                WHEN r_section.internal_name IN ('RS_SUR_NEED_P',
                                                 'RS_UCI_P',
                                                 'RV_REQUEST_P',
                                                 'RS_GLOBAL_ANESTH_P',
                                                 'RS_LOCAL_ANESTH_P',
                                                 'RS_UCI_POS_P') THEN
                    add_nurse_intake(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                     i_ds_component       => r_section.id_ds_component,
                                     i_internal_name      => r_section.internal_name,
                                     i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN
                     ('RS_SPEC_SURGERY_P', 'RS_EXT_SPEC_P', 'RS_DEPARTMENT_P', 'RS_CLIN_SERVICE_P') THEN
                    add_spec_surgery(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                     i_ds_component       => r_section.id_ds_component,
                                     i_internal_name      => r_section.internal_name,
                                     i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RS_PREF_SURG_P' THEN
                    add_surgeons(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                 i_ds_component       => r_section.id_ds_component,
                                 i_internal_name      => r_section.internal_name,
                                 i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RS_PREF_TIME_P' THEN
                    add_pref_time(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                  i_ds_component       => r_section.id_ds_component,
                                  i_internal_name      => r_section.internal_name,
                                  i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RS_MOT_PREF_TIME_P' THEN
                    add_mot_pref_time(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component       => r_section.id_ds_component,
                                      i_internal_name      => r_section.internal_name,
                                      i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RSP_LVL_URG_P' THEN
                    add_lvl_urg(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                i_ds_component       => r_section.id_ds_component,
                                i_internal_name      => r_section.internal_name,
                                i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name IN ('RS_PREV_DURATION_P', 'RSP_TIME_MIN_P') THEN
                    add_unit_measure_rs(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                        i_ds_component       => r_section.id_ds_component,
                                        i_internal_name      => r_section.internal_name,
                                        i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name LIKE 'RIP_DURATION_P%' THEN
                    add_unit_measure_rs(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                        i_ds_component       => r_section.id_ds_component,
                                        i_internal_name      => r_section.internal_name,
                                        i_flg_component_type => r_section.flg_component_type);
                WHEN r_section.internal_name = 'RI_DIAGNOSES_P' THEN
                    r_section.addit_info_xml_value := 'TYPE_DIAGNOSIS';
                    add_sample_text(i_intern_name_sample_text_type => pk_edis_triage.g_sample_text_entourage,
                                    io_section                     => r_section);
                WHEN r_section.internal_name = 'RS_CONT_DANGER_P' THEN
                    r_section.addit_info_xml_value := 'TYPE_DIAGNOSIS';
                    add_sample_text(i_intern_name_sample_text_type => pk_edis_triage.g_sample_text_entourage,
                                    io_section                     => r_section);
                WHEN r_section.internal_name = 'RS_PROC_SURG_P' THEN
                    r_section.addit_info_xml_value := 'TYPE_SR_PROC';
                    add_sample_text(i_intern_name_sample_text_type => pk_edis_triage.g_sample_text_entourage,
                                    io_section                     => r_section);
                WHEN r_section.internal_name = pk_admission_request.g_rs_notes_p THEN
                    -- EMR-2497
                    add_sample_text(i_intern_name_sample_text_type => pk_admission_request.g_disc_fe_notes_st,
                                    io_section                     => r_section);
                ELSE
                    --add_sample_text(i_intern_name_sample_text_type => pk_edis_triage.g_sample_text_entourage,
                    --                io_section                     => r_section);
                    NULL; -- EMR-2497
            END CASE;
        
            l_final_tbl_sections.extend();
            l_final_tbl_sections(l_final_tbl_sections.count) := r_section;
        
            IF NOT add_def_events(i_lang            => i_lang,
                             i_ds_cmpt_mkt_rel => r_section.id_ds_cmpt_mkt_rel,
                             i_internal_name   => r_section.internal_name,
                             i_edt_mode        => (CASE
                                                      WHEN i_waiting_list IS NULL THEN
                                                       pk_alert_constant.g_no
                                                      ELSE
                                                       pk_alert_constant.g_yes
                                                  END),
                             i_has_surgery     => i_need_surgery,
                             i_inst_location   => nvl(i_inst_location, l_surg_institution),
                             i_has_lvl_urg     => l_has_lvl_urg,
                             i_has_unav        => l_has_unav,
                             io_tbl_def_events => l_tbl_def_events,
                             o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF i_waiting_list IS NOT NULL
            THEN
                add_values(i_idx_section => l_final_tbl_sections.count, i_internal_name => r_section.internal_name);
            ELSE
                add_default_values(i_idx_section   => l_final_tbl_sections.count,
                                   i_internal_name => r_section.internal_name);
            END IF;
        
        END LOOP;
    
        SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                 id_ds_component_parent => a.id_ds_component_parent,
                                 id_ds_component        => a.id_ds_component,
                                 component_desc         => a.component_desc,
                                 internal_name          => a.internal_name,
                                 flg_component_type     => a.flg_component_type,
                                 flg_data_type          => a.flg_data_type,
                                 slg_internal_name      => a.slg_internal_name,
                                 addit_info_xml_value   => a.addit_info_xml_value,
                                 rank                   => a.rank,
                                 max_len                => a.max_len,
                                 min_value              => a.min_value,
                                 max_value              => a.max_value,
                                 gender                 => a.gender,
                                 age_min_value          => a.age_min_value,
                                 age_min_unit_measure   => a.age_min_unit_measure,
                                 age_max_value          => a.age_max_value,
                                 age_max_unit_measure   => a.age_max_unit_measure,
                                 component_values       => a.component_values)
          BULK COLLECT
          INTO l_section
          FROM (SELECT b.id_ds_cmpt_mkt_rel,
                       b.id_ds_component_parent,
                       b.id_ds_component,
                       b.component_desc,
                       b.internal_name,
                       b.flg_component_type,
                       b.flg_data_type,
                       b.slg_internal_name,
                       b.addit_info_xml_value,
                       pk_dynamic_screen.get_section_rank(i_tbl_section     => l_final_tbl_sections,
                                                          i_ds_cmpt_mkt_rel => b.id_ds_cmpt_mkt_rel) rank,
                       b.max_len,
                       b.min_value,
                       b.max_value,
                       b.gender,
                       b.age_min_value,
                       b.age_min_unit_measure,
                       b.age_max_value,
                       b.age_max_unit_measure,
                       b.component_values
                  FROM TABLE(l_final_tbl_sections) b) a
         ORDER BY a.rank;
    
        OPEN o_section FOR
            SELECT t.id_ds_cmpt_mkt_rel,
                   t.id_ds_component_parent,
                   t.id_ds_component,
                   t.component_desc,
                   t.internal_name,
                   t.flg_component_type,
                   t.flg_data_type,
                   t.slg_internal_name,
                   t.addit_info_xml_value,
                   t.rank,
                   t.max_len,
                   t.min_value,
                   t.max_value
              FROM TABLE(l_section) t
             WHERE (l_sys_config_hide_doc = pk_alert_constant.g_no OR
                   (l_sys_config_hide_doc = pk_alert_constant.g_yes AND t.internal_name NOT IN ('RS_CONT_DANGER_P')))
               AND (l_sys_config_hide_uci = pk_alert_constant.g_no OR
                   (l_sys_config_hide_uci = pk_alert_constant.g_yes AND
                   t.internal_name NOT IN ('RS_UCI_P', 'RS_UCI_POS_P')));
    
        OPEN o_events FOR
            SELECT DISTINCT id_ds_event,
                            origin,
                            VALUE,
                            target,
                            decode(b.internal_name_child,
                                    'RSP_SUGG_DT_SURG_P',
                                    decode(VALUE,
                                           NULL,
                                           flg_event_type,
                                           CASE
                                               WHEN l_sys_config_surg_dt_sugg = pk_alert_constant.g_yes THEN
                                                'M'
                                               ELSE
                                                flg_event_type
                                           END),
                                    flg_event_type) flg_event_type
              FROM TABLE(l_tbl_events) z
             INNER JOIN ds_cmpt_mkt_rel b
                ON z.target = b.id_ds_cmpt_mkt_rel;
    
        OPEN o_def_events FOR
            SELECT *
              FROM TABLE(l_tbl_def_events);
        --o_items_values - This cursor has all multichoice options for all triage form multichoice fields
        --               - And has all vital sign detail info
        OPEN o_items_values FOR
            SELECT *
              FROM TABLE(l_tbl_items_values);
    
        FOR r_section IN (SELECT t.id_ds_cmpt_mkt_rel, t.internal_name, t.flg_data_type, t.component_values
                            FROM TABLE(l_final_tbl_sections) t)
        LOOP
            IF r_section.component_values.count = 1
            THEN
                FOR r_value IN (SELECT t.id_ds_cmpt_mkt_rel, t.item_desc, t.item_value, t.item_alt_value
                                  FROM TABLE(r_section.component_values) t)
                LOOP
                    SELECT xmlconcat(l_xml_data,
                                     xmlagg(xmlelement("COMPONENT_LEAF",
                                                       xmlattributes(a.id_ds_cmpt_mkt_rel,
                                                                     a.internal_name,
                                                                     a.desc_value,
                                                                     a.value,
                                                                     a.alt_value)))) data_val
                      INTO l_xml_data
                      FROM (SELECT r_value.id_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel,
                                   r_section.internal_name    AS internal_name,
                                   r_value.item_desc          AS desc_value,
                                   r_value.item_value         AS VALUE,
                                   r_value.item_alt_value     AS alt_value
                              FROM dual
                             WHERE r_value.item_desc IS NOT NULL
                                OR r_value.item_value IS NOT NULL
                                OR r_value.item_alt_value IS NOT NULL) a;
                END LOOP;
            ELSIF r_section.component_values.count > 1
            THEN
                SELECT xmlconcat(l_xml_data,
                                 xmlagg(xmlelement("COMPONENT_LEAF",
                                                   xmlattributes(c.id_ds_cmpt_mkt_rel AS "ID_DS_CMPT_MKT_REL",
                                                                 c.internal_name AS "INTERNAL_NAME"), --
                                                   (SELECT xmlagg(xmlelement("SELECTED_ITEM",
                                                                             xmlattributes(d.item_desc AS "DESC_VALUE",
                                                                                           d.item_value AS "VALUE",
                                                                                           d.item_alt_value AS "ALT_VALUE")))
                                                      FROM TABLE(r_section.component_values) d
                                                     WHERE d.item_desc IS NOT NULL
                                                        OR d.item_value IS NOT NULL
                                                        OR d.item_alt_value IS NOT NULL))))
                  INTO l_xml_data
                  FROM (SELECT r_section.id_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel,
                               r_section.internal_name      AS internal_name
                          FROM dual) c;
            END IF;
        END LOOP;
    
        IF l_xml_data IS NOT NULL
        THEN
            --o_data_val - Has all the default triage form fields values
            SELECT xmlelement("COMPONENTS", l_xml_data).getclobval()
              INTO o_data_val
              FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ADMISSION_REQUEST',
                                              i_function => 'GET_SECTION_DATA',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        
    END get_section_data;

    FUNCTION get_procedure_filter_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
        l_has_specialty_results        VARCHAR2(1 CHAR) := pk_procedures_constant.g_no;
        l_has_med_procedures_results   VARCHAR2(1 CHAR) := pk_procedures_constant.g_no;
        l_has_nurse_procedures_results VARCHAR2(1 CHAR) := pk_procedures_constant.g_no;
        l_has_codification_results     VARCHAR2(1 CHAR) := pk_procedures_constant.g_no;
    
        l_list t_tbl_procedures_for_selection;
    
        l_exception EXCEPTION;
    
        l_permission VARCHAR2(1 CHAR);
    
        l_inst_dest institution.id_institution%TYPE;
    
        CURSOR c_pat IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat c_pat%ROWTYPE;
    
    BEGIN
    
        IF i_patient IS NOT NULL
        THEN
            g_error := 'OPEN C_PAT';
            OPEN c_pat;
            FETCH c_pat
                INTO l_pat;
            CLOSE c_pat;
        END IF;
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            SELECT d.id_institution
              INTO l_inst_dest
              FROM dep_clin_serv dps
              JOIN department d
                ON d.id_department = dps.id_department
             WHERE dps.id_dep_clin_serv = i_dep_clin_serv;
        END IF;
    
        g_error := 'SELECT PK_PROCEDURES_UTILS.GET_PROCEDURE_PERMISSION';
        SELECT pk_procedures_utils.get_procedure_permission(i_lang,
                                                            i_prof,
                                                            pk_procedures_constant.g_interv_area_procedures,
                                                            pk_procedures_constant.g_interv_button_create,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL)
          INTO l_permission
          FROM dual;
    
        SELECT COUNT(*)
          INTO l_count
          FROM intervention i
          JOIN interv_dep_clin_serv idcs
            ON i.id_intervention = idcs.id_intervention
           AND idcs.flg_type = pk_procedures_constant.g_interv_freq
           AND ((i_dep_clin_serv IS NULL AND idcs.id_software = pk_alert_constant.g_soft_oris AND
               idcs.id_institution = coalesce(l_inst_dest, i_prof.institution)) OR
               (i_dep_clin_serv IS NOT NULL AND idcs.id_dep_clin_serv = i_dep_clin_serv))
          JOIN (SELECT idcs.id_intervention
                  FROM interv_dep_clin_serv idcs
                 WHERE flg_type = pk_procedures_constant.g_interv_can_req
                   AND idcs.id_dep_clin_serv IS NULL
                   AND idcs.id_software = pk_alert_constant.g_soft_oris
                   AND idcs.id_institution = coalesce(l_inst_dest, i_prof.institution)) iis
            ON iis.id_intervention = i.id_intervention
          LEFT JOIN (SELECT id_intervention, concatenate(flg_mandatory) flg_mandatory
                       FROM (SELECT DISTINCT id_intervention, flg_mandatory
                               FROM interv_questionnaire
                              WHERE flg_time = pk_procedures_constant.g_interv_cq_on_order
                                AND id_institution = coalesce(l_inst_dest, i_prof.institution)
                                AND flg_available = pk_procedures_constant.g_available)
                      GROUP BY id_intervention) iq
            ON iq.id_intervention = i.id_intervention
         WHERE instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
           AND i.flg_status = pk_procedures_constant.g_active
           AND idcs.id_software = pk_alert_constant.g_soft_oris
           AND ((i_dep_clin_serv IS NOT NULL AND
                (idcs.flg_execute = pk_procedures_constant.g_yes OR
                (idcs.flg_execute = pk_procedures_constant.g_no AND l_permission = pk_procedures_constant.g_yes)) AND
                idcs.id_dep_clin_serv = i_dep_clin_serv) OR
                (i_dep_clin_serv IS NULL AND idcs.id_institution = i_prof.institution AND
                (EXISTS
                 (SELECT 1
                     FROM prof_dep_clin_serv pdcs
                    WHERE pdcs.id_professional = i_prof.id
                      AND pdcs.id_institution = i_prof.institution
                      AND pdcs.flg_status = pk_procedures_constant.g_selected
                      AND pdcs.id_dep_clin_serv = idcs.id_dep_clin_serv) OR idcs.id_professional = i_prof.id)))
           AND (i_patient IS NULL OR (((l_pat.gender IS NOT NULL AND coalesce(i.gender, 'I', 'U', 'N', 'C', 'A', 'B') IN
                ('I', 'U', 'N', 'C', 'A', 'B', l_pat.gender)) OR l_pat.gender IS NULL OR
                l_pat.gender IN ('I', 'U', 'N', 'C', 'A', 'B')) AND
                (nvl(l_pat.age, 0) BETWEEN nvl(i.age_min, 0) AND
                nvl(i.age_max, nvl(l_pat.age, 0)) OR l_pat.age IS NULL)))
           AND rownum > 0;
    
        IF l_count > 0
        THEN
            l_has_specialty_results := pk_alert_constant.g_yes;
        END IF;
    
        BEGIN
            SELECT DISTINCT pk_procedures_constant.g_yes
              INTO l_has_med_procedures_results
              FROM interv_dcs_most_freq_except idmfe
              JOIN interv_dep_clin_serv idcs
                ON idcs.id_interv_dep_clin_serv = idmfe.id_interv_dep_clin_serv
             WHERE idcs.flg_type = pk_procedures_constant.g_interv_freq
               AND idmfe.flg_cat_prof = 'P'
               AND idmfe.flg_available = pk_procedures_constant.g_yes
               AND idmfe.flg_status = pk_procedures_constant.g_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_has_med_procedures_results := pk_procedures_constant.g_no;
        END;
    
        BEGIN
            SELECT DISTINCT pk_procedures_constant.g_yes
              INTO l_has_nurse_procedures_results
              FROM interv_dcs_most_freq_except idmfe
              JOIN interv_dep_clin_serv idcs
                ON idcs.id_interv_dep_clin_serv = idmfe.id_interv_dep_clin_serv
             WHERE idcs.flg_type = pk_procedures_constant.g_interv_freq
               AND idmfe.flg_cat_prof = pk_alert_constant.g_cat_type_nurse
               AND idmfe.flg_available = pk_procedures_constant.g_yes
               AND idmfe.flg_status = pk_procedures_constant.g_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_has_nurse_procedures_results := pk_procedures_constant.g_no;
        END;
    
        BEGIN
            SELECT DISTINCT pk_procedures_constant.g_yes
              INTO l_has_codification_results
              FROM codification_instit_soft cis
             WHERE cis.id_institution = i_prof.institution
               AND cis.id_software = i_prof.software
               AND cis.flg_available = pk_procedures_constant.g_available
               AND EXISTS (SELECT 1
                      FROM interv_codification ic,
                           (SELECT i.id_intervention
                              FROM intervention i, interv_dep_clin_serv idcs
                             WHERE i.flg_status = pk_procedures_constant.g_active
                               AND instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                               AND i.id_intervention = idcs.id_intervention
                               AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                               AND idcs.id_software = i_prof.software
                               AND idcs.id_institution = i_prof.institution) idcs
                     WHERE cis.id_codification = ic.id_codification
                       AND ic.flg_available = pk_procedures_constant.g_available
                       AND ic.id_intervention = idcs.id_intervention);
        EXCEPTION
            WHEN no_data_found THEN
                l_has_codification_results := pk_procedures_constant.g_no;
        END;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT id_action, id_parent, to_state, desc_action, icon, flg_default, flg_active, action
              FROM (SELECT a.from_state id_action,
                           NULL id_parent,
                           NULL to_state,
                           a.desc_action,
                           NULL icon,
                           decode(a.from_state,
                                  pk_procedures_constant.g_interv_institution,
                                  pk_procedures_constant.g_yes,
                                  pk_procedures_constant.g_no) flg_default,
                           CASE
                                WHEN a.from_state = 'I' THEN
                                 pk_procedures_constant.g_active
                                WHEN a.from_state = 'D'
                                     AND l_has_codification_results = pk_procedures_constant.g_yes THEN
                                 pk_procedures_constant.g_active
                                WHEN a.from_state = 'S'
                                     AND l_has_specialty_results = pk_procedures_constant.g_yes THEN
                                 pk_procedures_constant.g_active
                                WHEN a.from_state = 'P'
                                     AND l_has_med_procedures_results = pk_procedures_constant.g_yes THEN
                                 pk_procedures_constant.g_active
                                WHEN a.from_state = 'N'
                                     AND l_has_nurse_procedures_results = pk_procedures_constant.g_yes THEN
                                 pk_procedures_constant.g_active
                                ELSE
                                 pk_procedures_constant.g_inactive
                            END flg_active,
                           a.action,
                           NULL rank
                      FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'PROCEDURES_FILTERS', NULL)) a
                    UNION ALL
                    SELECT to_char(cis.id_codification) id_action,
                           'D' id_parent,
                           NULL to_state,
                           pk_translation.get_translation(i_lang,
                                                          'CODIFICATION.CODE_CODIFICATION.' || cis.id_codification) desc_action,
                           NULL icon,
                           pk_procedures_constant.g_no flg_default,
                           pk_procedures_constant.g_active flg_active,
                           NULL action,
                           NULL rank
                      FROM codification_instit_soft cis
                     WHERE cis.id_institution = i_prof.institution
                       AND cis.id_software = i_prof.software
                       AND cis.flg_available = pk_procedures_constant.g_available
                       AND EXISTS (SELECT 1
                              FROM interv_codification ic,
                                   (SELECT i.id_intervention
                                      FROM intervention i, interv_dep_clin_serv idcs
                                     WHERE i.flg_status = pk_procedures_constant.g_active
                                       AND instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0
                                       AND i.id_intervention = idcs.id_intervention
                                       AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                                       AND idcs.id_software = i_prof.software
                                       AND idcs.id_institution = i_prof.institution) idcs
                             WHERE cis.id_codification = ic.id_codification
                               AND ic.flg_available = pk_procedures_constant.g_available
                               AND ic.id_intervention = idcs.id_intervention)
                       AND l_has_codification_results = pk_procedures_constant.g_yes) t
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
                                              'GET_PROCEDURE_FILTER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_filter_list;

    FUNCTION get_procedure_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_search_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_SEARCH_DIAGNOSIS', i_prof);
    
        l_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_tbl_diags t_coll_episode_diagnosis := t_coll_episode_diagnosis();
    
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            l_tbl_diags := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_patient     => NULL,
                                                                        i_id_scope    => i_episode,
                                                                        i_flg_scope   => pk_alert_constant.g_scope_type_episode,
                                                                        i_flg_type    => NULL,
                                                                        i_criteria    => NULL,
                                                                        i_format_text => NULL,
                                                                        i_tbl_status  => table_varchar(pk_diagnosis.g_ed_flg_status_co));
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT id_diagnosis, desc_diagnosis, code_icd, flg_other, rank, id_alert_diagnosis
              FROM (SELECT -1 id_diagnosis,
                           pk_message.get_message(i_lang, i_prof, 'PROCEDURES_T073') desc_diagnosis,
                           NULL code_icd,
                           NULL flg_other,
                           10 rank,
                           -1 id_alert_diagnosis
                      FROM dual
                     WHERE instr(nvl(l_search_diagnosis, '#'), l_profile_template) != 0
                    UNION ALL
                    SELECT /*+opt_estimate (table t rows=1)*/
                     t.id_diagnosis, t.desc_diagnosis, NULL code_icd, t.flg_other, 20 rank, t.id_alert_diagnosis
                      FROM TABLE(l_tbl_diags) t)
             ORDER BY rank ASC, desc_diagnosis ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_diagnosis_list;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN table_varchar,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PK_SUPPLIES_API_DB.GET_SUPPLIES_BY_CONTEXT';
        IF NOT pk_supplies_api_db.get_supplies_by_context(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_context    => i_id_context,
                                                          i_flg_context   => i_flg_context,
                                                          i_dep_clin_serv => i_dep_clin_serv,
                                                          o_supplies      => o_supplies,
                                                          o_error         => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_SUPPLIES_BY_CONTEXT',
                                              o_error);
            pk_types.open_my_cursor(o_supplies);
            RETURN FALSE;
    END get_supplies_by_context;

BEGIN
    g_selected := 'S';
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_sr_planning;
/
