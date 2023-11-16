/*-- Last Change Revision: $Rev: 1999757 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-10-25 14:01:38 +0100 (seg, 25 out 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_sr_visit IS

    /********************************************************************************************
    * Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    *   de existir um agendamento, diagnóstico base e intervenção a realizar definidos.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_rec              Array de valores a utilizar para criar os registos
    * @param i_id_episode_ext   ID do episódio externo
    * @param io_episode         ID do episódio criado. Se vier a null, será criado um novo
    * @param io_visit           ID da visita criada. Se vier a null, será criada uma nova  
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/11/30 
    * @altered by               Rita Lopes
    * @                         2008/04/17
    * @Notas                    Parametrizei na sys_config para ir buscar o dep_clin_serv
    * @altered by               Filipe Silva
    * @                         2009/07/01
    * @Notas                    create episode with the dep_clin_serv (ALERT - 30974)
       ********************************************************************************************/

    FUNCTION interface_create_all_surgery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_rec             IN pk_api_sr_visit.sr_new_schedule_struct,
        i_id_episode_ext  IN VARCHAR2,
        i_id_prev_episode IN episode.id_prev_episode%TYPE DEFAULT NULL,
        io_episode        IN OUT episode.id_episode%TYPE,
        io_visit          IN OUT visit.id_visit%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_schedule_sr    schedule_sr%ROWTYPE;
        l_schedule       schedule%ROWTYPE;
        l_sr_surg_rec    sr_surgery_record%ROWTYPE;
        l_id_episode     episode.id_episode%TYPE;
        l_id_visit       visit.id_visit%TYPE;
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
        l_id_schedule    schedule.id_schedule%TYPE;
        l_check_director sys_config.value%TYPE;
    
        l_internal_error EXCEPTION;
        l_oris_dcs       sys_config.value%TYPE;
    
        CURSOR c_visit IS
        --Procura uma visita aberta com episódio de internamento aberto. Se existir,
        -- o episódio de bloco a criar irá ficar associado a esta visita.
            SELECT v.id_visit
              FROM visit v
             WHERE v.id_patient = i_rec.id_patient
               AND v.id_institution = i_prof.institution
               AND v.flg_status = 'A'
               AND EXISTS (SELECT 1
                      FROM episode e
                     WHERE e.id_visit = v.id_visit
                       AND ((i_id_prev_episode IS NULL AND e.id_epis_type = g_inp_epis_type --internamento
                           AND e.flg_ehr <> pk_alert_constant.g_epis_ehr_ehr) OR
                           (i_id_prev_episode IS NOT NULL AND e.id_episode = i_id_prev_episode))
                       AND e.flg_status = 'A');
        -- Procura uma visita aberta com episódio anterior. Se existir,
        -- o episódio de bloco a criar irá ficar associado a esta visita.-- ALERT-31101 
        CURSOR c_visit_prev IS
            SELECT v.id_visit
              FROM visit v, episode e
             WHERE v.id_patient = i_rec.id_patient
               AND v.id_institution = i_prof.institution
               AND v.flg_status = g_flg_status_active
               AND v.id_visit = e.id_visit
               AND e.flg_status = g_flg_status_active
               AND e.id_episode IN (SELECT ees.id_episode
                                      FROM epis_ext_sys ees
                                     WHERE ees.value LIKE i_rec.num_episode_prev
                                       AND ees.id_institution = i_prof.institution
                                       AND ees.cod_epis_type_ext LIKE i_rec.cod_module);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_id_episode := io_episode;
        l_id_visit   := NULL;
    
        l_oris_dcs := pk_sysconfig.get_config('SURGERY_DEP_CLIN_SERV', i_prof.institution, i_prof.software);
    
        IF io_visit IS NULL
        THEN
            IF i_rec.num_episode_prev IS NULL
            THEN
                --Procura uma visita aberta com episódio de internamento aberto. Se existir,
                -- o episódio de bloco a criar irá ficar associado a esta visita.
                g_error := 'GET ID_VISIT';
                pk_alertlog.log_debug(g_error);
                OPEN c_visit;
                FETCH c_visit
                    INTO l_id_visit;
                CLOSE c_visit;
                /*BEGIN ALERT-31101*/
            ELSE
                -- Looks for the previous alert episode which originated the surgery room episode
                -- based on the id_episode of the epis_ext_sys table which corresponds to the num_episode_prev parameter
                g_error := 'GET ID_VISIT';
                pk_alertlog.log_debug(g_error);
                OPEN c_visit_prev;
                FETCH c_visit_prev
                    INTO l_id_visit;
                CLOSE c_visit_prev;
            END IF;
            /*END ALERT-31101*/
        ELSE
            l_id_visit := io_visit;
        END IF;
    
        --Cria visita e episódio temporários
        g_error := 'CREATE TEMP EPISODE AND VISIT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_visit(i_lang             => i_lang,
                                        i_patient          => i_rec.id_patient,
                                        i_prof             => i_prof,
                                        i_flg_temp         => g_flg_unknown_def,
                                        i_id_episode_ext   => i_id_episode_ext,
                                        i_flg_ehr          => g_flg_ehr_n, --Episódios vindos por interface são sempre do tipo Normal
                                        i_id_dcs_requested => nvl(i_rec.id_dep_clin_serv, l_oris_dcs), -- FSILVA 2009/07/01
                                        i_num_episode_prev => i_rec.num_episode_prev, -- for later use , insert into epis_ext_sys under value's column -- ALERT-31101 
                                        i_cod_module       => i_rec.cod_module, -- ALERT-31101 
                                        i_id_external_sys  => i_rec.id_external_sys,
                                        i_dt_creation      => NULL,
                                        i_dt_begin         => i_rec.dt_sr_surgery_tstz,
                                        i_flg_migration    => NULL,
                                        io_episode         => l_id_episode,
                                        io_visit           => l_id_visit,
                                        o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        io_episode := l_id_episode;
        io_visit   := l_id_visit;
    
        --Preenche schedule
        g_error := 'CREATE SCHEDULE';
        pk_alertlog.log_debug(g_error);
        l_schedule                     := NULL;
        l_schedule.id_instit_requests  := i_prof.institution;
        l_schedule.id_instit_requested := i_prof.institution;
        -- RL - 20080417 - alterei o dep_clin_serv para ir buscar a sys_config
        l_schedule.id_dcs_requested  := nvl(i_rec.id_dep_clin_serv, l_oris_dcs); --Alterar quando o interface enviar o serviço clinico
        l_schedule.id_prof_schedules := i_rec.id_prof_req;
        l_schedule.dt_schedule_tstz  := g_sysdate_tstz;
        l_schedule.flg_status        := g_flg_status_active;
        l_schedule.dt_begin_tstz     := nvl(i_rec.dt_schedule_tstz, g_sysdate_tstz); --pk_date_utils.get_string_tstz(i_lang,i_prof,to_char(i_rec.dt_schedule, 'YYYYMMDDhh24miss'),NULL);
        l_schedule.flg_urgency       := g_flg_urg_n;
        l_schedule.id_room           := i_rec.id_room;
    
        --Cria o registo de agendamento
        g_error := 'INSERT SCHEDULE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_schedule(i_lang     => i_lang,
                                           i_schedule => l_schedule,
                                           i_episode  => l_id_episode,
                                           o_schedule => l_id_schedule,
                                           o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --Preenche o registo da schedule_sr
        g_error := 'CREATE SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        l_schedule_sr                        := NULL;
        l_schedule_sr.id_sched_sr_parent     := NULL;
        l_schedule_sr.id_schedule            := l_id_schedule;
        l_schedule_sr.id_episode             := l_id_episode;
        l_schedule_sr.dt_target_tstz         := i_rec.dt_schedule_tstz;
        l_schedule_sr.dt_interv_preview_tstz := i_rec.dt_schedule_tstz;
        l_schedule_sr.id_patient             := i_rec.id_patient;
        l_schedule_sr.duration               := i_rec.duration;
        l_schedule_sr.id_diagnosis           := i_rec.id_diagnosis;
        l_schedule_sr.id_speciality          := NULL;
        l_schedule_sr.flg_status             := g_flg_status_active;
        l_schedule_sr.flg_sched              := g_schedule_state_not_sched;
        l_schedule_sr.id_dept_dest           := NULL;
        l_schedule_sr.prev_recovery_time     := NULL;
        l_schedule_sr.id_prof_reg            := i_prof.id;
        l_schedule_sr.id_institution         := i_prof.institution;
    
        --Cria o registo de agendamento
        g_error := 'INSERT SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_schedule_sr(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_schedule_sr => l_schedule_sr,
                                              o_schedule_sr => l_id_schedule_sr,
                                              o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --Cria registo cirurgico
        g_error := 'CREATE SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        l_sr_surg_rec                     := NULL;
        l_sr_surg_rec.id_schedule_sr      := l_id_schedule_sr;
        l_sr_surg_rec.id_sr_intervention  := NULL;
        l_sr_surg_rec.id_prof_team        := NULL;
        l_sr_surg_rec.id_patient          := i_rec.id_patient;
        l_sr_surg_rec.flg_pat_status      := g_flg_pat_status_pend;
        l_sr_surg_rec.flg_state           := g_rec_flg_naoagend;
        l_sr_surg_rec.flg_surg_nat        := NULL;
        l_sr_surg_rec.flg_surg_type       := i_rec.flg_surg_type;
        l_sr_surg_rec.flg_urgency         := NULL;
        l_sr_surg_rec.id_clinical_service := NULL;
        l_sr_surg_rec.id_anesthesia_type  := NULL;
        l_sr_surg_rec.id_institution      := i_prof.institution;
        l_sr_surg_rec.id_episode          := l_id_episode;
    
        g_error := 'GET CHECK DIRECTOR';
        pk_alertlog.log_debug(g_error);
        l_check_director := pk_sysconfig.get_config('CHECK_ALERT_DIRECTOR', i_prof);
    
        IF l_check_director = pk_alert_constant.g_yes
        THEN
            l_sr_surg_rec.flg_sr_proc := pk_sr_approval.g_inc_request;
        ELSE
            l_sr_surg_rec.flg_sr_proc := pk_sr_approval.g_pending;
        END IF;
        /*  l_sr_surg_rec.flg_sr_proc         := pk_sr_approval.g_inc_request;*/
        l_sr_surg_rec.dt_flg_sr_proc := g_sysdate_tstz;
    
        --insere o registo
        g_error := 'INSERT SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_surgery_record(i_lang        => i_lang,
                                                 i_sr_surg_rec => l_sr_surg_rec,
                                                 i_prof        => i_prof,
                                                 o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'SCHEDULE_ROOM';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_sr_visit.schedule_room(i_lang             => i_lang,
                                             i_episode          => l_id_episode,
                                             i_dt_schedule_tstz => nvl(i_rec.dt_schedule_tstz, g_sysdate_tstz),
                                             i_id_room          => i_rec.id_room,
                                             i_rec_flg          => g_rec_flg_agend,
                                             i_id_schedule      => l_id_schedule,
                                             o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --insere parâmetros utilizados pela função para a criação do episódio, visita, etc para possível debug
        g_error := 'INSERT SR_INTERFACE_PARAM';
        pk_alertlog.log_debug(g_error);
        INSERT INTO sr_interface_param
            (id_sr_interface_param,
             id_lang,
             id_prof,
             id_institution,
             id_software,
             id_patient,
             id_episode_ext,
             id_episode,
             id_visit)
        VALUES
            (seq_sr_interface_param.nextval,
             i_lang,
             i_prof.id,
             i_prof.institution,
             i_prof.software,
             i_rec.id_patient,
             i_id_episode_ext,
             io_episode,
             io_visit);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CREATE_ALL_SURGERY',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CREATE_ALL_SURGERY',
                                              o_error);
            RETURN FALSE;
    END interface_create_all_surgery;

    /********************************************************************************************
    * Cancela o agendamento de uma cirurgia.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software 
    * @param i_rec              Array de valores a utilizar para criar os registos
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/11/30 
       ********************************************************************************************/

    FUNCTION interface_cancel_surgery
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_rec   IN pk_api_sr_visit.sr_cancel_schedule_struct,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_visit      visit.id_visit%TYPE;
        l_epi_rowids table_varchar;
        l_rowids     table_varchar;
        l_error      VARCHAR2(4000);
    
        /*      -- codigo integracionista - activar isto quando a agenda oris passar a ser a 3
                CURSOR c_id_schedule_sr IS
                    SELECT id_schedule
                      FROM schedule_sr
                     WHERE id_episode = i_rec.id_episode;
            
                l_transaction_id VARCHAR2(4000);
                cur_rec c_id_schedule_sr%ROWTYPE;
        */
    BEGIN
    
        /*    -- codigo integracionista - activar isto quando a agenda oris passar a ser a 3
                -- gets a new transaction ID and begins the transaction
                l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
            
                OPEN c_id_schedule_sr;
                LOOP
                    FETCH c_id_schedule_sr
                        INTO cur_rec;
                    EXIT WHEN c_id_schedule_sr%NOTFOUND;
                
                    --Cancela na tabela SCHEDULE
                    g_error := 'CANCEL SCHEDULE';
                    IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_schedule      => cur_rec.id_schedule,
                                                       i_id_cancel_reason => i_rec.id_cancel_reason,
                                                       io_transaction_id  => l_transaction_id,
                                                       o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
                CLOSE c_id_schedule_sr;
        */
    
        -- codigo integracionista - desactivar este update quando a agenda oris passar a ser a 3  
        --Cancela na tabela SCHEDULE
        g_error := 'CANCEL SCHEDULE';
        pk_alertlog.log_debug(g_error);
        UPDATE schedule
           SET flg_status       = g_cancel,
               id_prof_cancel   = i_rec.id_prof_cancel,
               dt_cancel_tstz   = i_rec.dt_cancel_tstz,
               id_cancel_reason = i_rec.id_cancel_reason
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule_sr
                                WHERE id_episode = i_rec.id_episode);
    
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in => i_rec.id_episode, flg_sch_status_in => g_cancel, rows_out => l_epi_rowids);
    
        l_epi_rowids := table_varchar();
    
        --Cancela na tabela SCHEDULE_SR
        g_error := 'CALL TS_SCHEDULE_SR.UPD WITH ID_EPISODE = ' || i_rec.id_episode;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_schedule_sr.upd(flg_status_in          => g_cancel,
                           id_prof_cancel_in      => i_rec.id_prof_cancel,
                           dt_cancel_tstz_in      => i_rec.dt_cancel_tstz,
                           id_sr_cancel_reason_in => i_rec.id_cancel_reason,
                           where_in               => 'id_episode = ' || i_rec.id_episode,
                           rows_out               => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH ID_EPISODE = ' || i_rec.id_episode;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
    
        --Cancela episódio
        -- <DENORM_JOSE_BRITO> -- Tracking Board
        g_error := 'CANCEL EPISODE';
        pk_alertlog.log_debug(g_error);
        ts_episode.upd(id_episode_in      => i_rec.id_episode,
                       flg_status_in      => g_cancel,
                       id_prof_cancel_in  => i_rec.id_prof_cancel,
                       dt_cancel_tstz_in  => i_rec.dt_cancel_tstz,
                       id_prof_cancel_nin => FALSE,
                       dt_cancel_tstz_nin => FALSE,
                       rows_out           => l_epi_rowids);
    
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE - EPISODE';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_epi_rowids,
                                      o_error      => o_error);
    
        -- </DENORM_JOSE_BRITO>
    
        --Determina a visita do episódio
        g_error := 'GET EPISODES VISIT';
        pk_alertlog.log_debug(g_error);
        SELECT id_visit
          INTO l_visit
          FROM episode
         WHERE id_episode = i_rec.id_episode;
    
        --Cancela visita se não existir mais nenhum episódio activo para essa visita
        g_error := 'CANCEL VISIT';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_visit.upd(flg_status_in  => g_cancel,
                     flg_status_nin => FALSE,
                     where_in       => 'id_visit = ' || l_visit || ' AND NOT EXISTS (SELECT 1
                  FROM episode e
                 WHERE e.id_visit = ' || l_visit || '
                   AND e.id_episode != ' || i_rec.id_episode || '
                   AND e.flg_status = ''' || g_flg_status_active || ''')',
                     rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'VISIT',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        --g_error := 'CANCEL VISIT';
        --pk_alertlog.log_debug(g_error);
        --UPDATE visit v
        --   SET flg_status = g_cancel
        -- WHERE v.id_visit = l_visit
        --   AND NOT EXISTS (SELECT 1
        --          FROM episode e
        --         WHERE e.id_visit = l_visit
        --           AND e.id_episode != i_rec.id_episode
        --           AND e.flg_status = g_flg_status_active);
    
        -- codigo integracionista - activar isto quando a agenda oris passar a ser a 3
        /*pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
        */
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTERFACE_CANCEL_SURGERY',
                                              o_error);
            -- codigo integracionista - activar isto quando a agenda oris passar a ser a 3
            --pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_cancel_surgery;

    /********************************************************************************************
    * Insere as intervenções cirúrgicas agendadas para o episódio.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          ID do episódio
    * @param i_sr_intervention  ID da intervenção cirúrgica
    * @param i_prof_req         ID do profissional requisitado
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/12/11
       ********************************************************************************************/

    FUNCTION interface_ins_epis_surg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_sr_intervention   IN intervention.id_intervention%TYPE,
        i_prof_req          IN professional.id_professional%TYPE,
        i_flg_type          IN sr_epis_interv.flg_type%TYPE DEFAULT 'P',
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        o_sr_epis_interv    OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids         table_varchar;
        l_sr_epis_interv sr_epis_interv.id_sr_epis_interv%TYPE;
    BEGIN
        g_sysdate_tstz   := current_timestamp;
        l_sr_epis_interv := seq_sr_epis_interv.nextval;
    
        g_error := 'INSERT SR_EPIS_INTERV';
        pk_alertlog.log_debug(g_error);
        ts_sr_epis_interv.ins(id_sr_epis_interv_in  => l_sr_epis_interv,
                              id_episode_in         => i_episode,
                              id_episode_context_in => i_episode,
                              id_sr_intervention_in => i_sr_intervention,
                              dt_req_tstz_in        => g_sysdate_tstz,
                              id_prof_req_in        => i_prof_req,
                              flg_type_in           => i_flg_type,
                              flg_status_in         => g_interv_r,
                              flg_code_type_in      => pk_sr_planning.g_flg_code_type_c,
                              id_epis_diagnosis_in  => i_id_epis_diagnosis,
                              rows_out              => l_rowids);
    
        g_error := 'call t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_EPIS_INTERV',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'call set_ia_event_prescription';
        IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_flg_action        => 'I',
                                                      i_id_sr_epis_interv => l_sr_epis_interv,
                                                      i_flg_status_new    => g_interv_r,
                                                      i_flg_status_old    => NULL,
                                                      o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_sr_epis_interv := l_sr_epis_interv;
    
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
                                              'INTERFACE_INS_EPIS_SURG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_ins_epis_surg;

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
    END error_handling;

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        o_error := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_common_m001) || chr(10) ||
                   g_package_name || '.' || i_func_proc_name;
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
        RETURN FALSE;
    END error_handling;

    /**************************************************************************
    * gets all scheduled oris episodes for a specific time interval           *
    *                                                                         *
    *@param  i_lang                preferred language id                      *
    *@param  i_prof                Professional struture                      *
    *@param  i_dt_begin            Begin date interval                        *
    *@param  i_dt_end              End date interval                          *
    *                                                                         *
    *@return t_tbl_sr_scheduled_episodes collection                           *
    *                                                                         *  
    * @author                          Gustavo Serrano                        *
    * @version                         v2.6.0.3                               *   
    * @since                           2010/06/02                             *    
    **************************************************************************/
    FUNCTION tf_scheduled_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_sr_scheduled_episodes IS
    
        l_func_name VARCHAR2(30) := 'TF_SCHEDULED_EPISODES';
        l_tbl       t_tbl_sr_scheduled_episodes;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'FILL t_tbl_sr_scheduled_episodes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT t_rec_sr_scheduled_episodes(t.id_episode, t.id_patient)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT ss.id_episode, ss.id_patient
                  FROM schedule_sr ss
                 INNER JOIN episode epis
                    ON epis.id_episode = ss.id_episode
                 WHERE ss.id_institution = i_prof.institution
                   AND ss.dt_target_tstz BETWEEN nvl(i_dt_begin, g_sysdate_tstz) AND nvl(i_dt_end, g_sysdate_tstz)
                   AND epis.flg_ehr = pk_alert_constant.g_epis_ehr_normal) t;
    
        RETURN l_tbl;
    END tf_scheduled_episodes;

    FUNCTION schedule_room
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_schedule_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_room          IN room.id_room%TYPE,
        i_rec_flg          IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_room_scheduled room_scheduled.id_room_scheduled%TYPE;
        l_rows_ei           table_varchar;
    BEGIN
        --insere sala agendada
        g_error := 'INSERT ROOM_SCHEDULED';
        pk_alertlog.log_debug(g_error);
        INSERT INTO room_scheduled
            (id_room_scheduled, dt_room_scheduled_tstz, id_schedule, id_room, flg_status)
        VALUES
            (seq_room_scheduled.nextval, i_dt_schedule_tstz, i_id_schedule, i_id_room, i_rec_flg)
        RETURNING id_room_scheduled INTO l_id_room_scheduled;
    
        ts_epis_info.upd(id_episode_in          => i_episode,
                         id_room_scheduled_in   => l_id_room_scheduled,
                         room_sch_flg_status_in => i_rec_flg,
                         rows_out               => l_rows_ei);
    
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
                                              'INTERFACE_INS_EPIS_SURG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    /********************************************************************************************
    * Actualiza a data prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_schedule_sr      ID do agendamento
    * @param i_dt               Data prevista da realização da cirurgia
    * @param i_dep_clin_serv    New dep_clin_serv
    * @param i_duration         New duration in minutes
    * @param i_diagnosis        New diagnosis
    * @param i_room             New cirurgic room
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Paulo Teixeira
    * @since                    2013/09/24
    ********************************************************************************************/
    FUNCTION interface_set_sr_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_schedule_sr   IN schedule_sr.id_schedule_sr%TYPE,
        i_dt            IN schedule_sr.dt_target_tstz%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_duration      IN schedule_sr.duration%TYPE,
        i_diagnosis     IN schedule_sr.id_diagnosis%TYPE,
        i_room          IN room.id_room%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_episode episode.id_episode%TYPE;
        l_rowids  table_varchar;
    BEGIN
    
        IF (i_dt IS NOT NULL OR i_duration IS NOT NULL OR i_diagnosis IS NOT NULL)
           AND i_schedule_sr IS NOT NULL
        THEN
            g_error := 'CALL ts_schedule_sr.upd';
            ts_schedule_sr.upd(id_schedule_sr_in         => i_schedule_sr,
                               dt_target_tstz_in         => i_dt,
                               dt_interv_preview_tstz_in => i_dt,
                               duration_in               => i_duration,
                               id_diagnosis_in           => i_diagnosis,
                               rows_out                  => l_rowids);
        
            g_error := 'PROCESS UPDATE WITH ID_SCHEDULE_SR ' || i_schedule_sr;
            t_data_gov_mnt.process_update(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
        END IF;
    
        IF i_dep_clin_serv IS NOT NULL
           AND i_schedule_sr IS NOT NULL
        THEN
        
            BEGIN
                SELECT s.id_episode
                  INTO l_episode
                  FROM schedule_sr s
                 WHERE s.id_schedule_sr = i_schedule_sr;
            EXCEPTION
                WHEN OTHERS THEN
                    l_episode := NULL;
            END;
        
            IF l_episode IS NOT NULL
            THEN
                l_rowids := table_varchar();
            
                g_error := 'UPDATE EPIS_INFO';
                ts_epis_info.upd(id_episode_in       => l_episode,
                                 id_dcs_requested_in => i_dep_clin_serv,
                                 rows_out            => l_rowids);
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INFO',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
        END IF;
    
        IF i_room IS NOT NULL
           AND i_schedule_sr IS NOT NULL
        THEN
            g_error := 'CALL UPD_SURG_PROC_PREVIEW_DURATION';
            IF NOT pk_sr_visit.upd_surg_proc_preview_room(i_lang        => i_lang,
                                                          i_schedule_sr => i_schedule_sr,
                                                          i_room        => i_room,
                                                          i_prof        => i_prof,
                                                          o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --
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
                                              'INTERFACE_SET_SR_DATA',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_set_sr_data;

    /*******************************************************************************************************************************************
    * Insert surgery times...
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_set_surgery_dates
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_sr_surgery_time IN NUMBER,
        i_dt_surgery_time IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_show               VARCHAR2(10 CHAR);
        l_msg_result             VARCHAR2(1000 CHAR);
        l_title                  VARCHAR2(1000 CHAR);
        l_button                 VARCHAR2(1000 CHAR);
        l_flg_refresh            VARCHAR2(1000 CHAR);
        l_id_sr_surgery_time_det NUMBER(24);
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        IF NOT pk_sr_surg_record.set_surgery_time(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_sr_surgery_time => i_sr_surgery_time,
                                                  i_dt_surgery_time => i_dt_surgery_time,
                                                  o_error           => o_error)
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
                                              'INTERFACE_SET_SURGERY_DATES',
                                              o_error);
            RETURN FALSE;
        
    END interface_set_surgery_dates;

    /*******************************************************************************************************************************************
    * Insert surgery episode...
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_set_surgery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_prev_episode IN episode.id_prev_episode%TYPE,
        i_id_episode_ext  IN VARCHAR2 DEFAULT NULL,
        i_id_schedule     IN NUMBER DEFAULT NULL,
        i_dt_schedule     IN VARCHAR2 DEFAULT NULL,
        i_id_room         IN NUMBER DEFAULT NULL,
        i_duration        IN NUMBER DEFAULT NULL,
        i_prof_resp       IN NUMBER DEFAULT NULL,
        i_prof_req        IN NUMBER DEFAULT NULL,
        io_episode        IN OUT episode.id_episode%TYPE,
        io_visit          IN OUT visit.id_visit%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
    
        i_rec pk_api_sr_visit.sr_new_schedule_struct;
    
    BEGIN
    
        i_rec.id_wait_list       := NULL;
        i_rec.id_schedule        := i_id_schedule;
        i_rec.dt_schedule_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_schedule, NULL);
        i_rec.interv_type        := NULL;
        i_rec.id_room            := i_id_room;
        i_rec.flg_surg_type      := NULL;
        i_rec.duration           := i_duration;
        i_rec.id_prof_resp       := i_prof_resp;
        i_rec.id_prof_req        := i_prof_req;
        i_rec.id_diagnosis       := NULL;
        i_rec.id_patient         := i_id_patient;
        i_rec.flg_blood_req      := pk_alert_constant.g_no;
        i_rec.id_dep_clin_serv   := nvl(pk_sysconfig.get_config('SURGERY_DEP_CLIN_SERV',
                                                                i_prof.institution,
                                                                i_prof.software),
                                        -1);
        i_rec.num_episode_prev   := NULL;
        i_rec.cod_module         := NULL;
        i_rec.id_external_sys    := NULL;
        i_rec.dt_sr_surgery_tstz := current_timestamp;
    
        IF NOT pk_api_sr_visit.interface_create_all_surgery(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_rec             => i_rec,
                                                            i_id_episode_ext  => i_id_episode_ext,
                                                            i_id_prev_episode => i_id_prev_episode,
                                                            io_episode        => io_episode,
                                                            io_visit          => io_visit,
                                                            o_error           => o_error)
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
                                              'INTERFACE_SET_SURGERY',
                                              o_error);
            RETURN FALSE;
        
    END interface_set_surgery;

    /*******************************************************************************************************************************************
    * Insert the team associated to surgery record
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_set_team
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_tbl_prof IN table_number,
        i_tbl_catg IN table_number,
        o_id_team  OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_status table_varchar := table_varchar();
    
        l_team_name VARCHAR(100 CHAR);
        l_flg_show  VARCHAR2(100 CHAR);
        l_msg_title VARCHAR2(100 CHAR);
        l_msg_text  VARCHAR2(100 CHAR);
        l_button    VARCHAR2(100 CHAR);
    
        l_id_surgery_record sr_surgery_record.id_surgery_record%TYPE;
    
    BEGIN
    
        FOR i IN i_tbl_prof.first .. i_tbl_prof.last
        LOOP
            l_tbl_status.extend(1);
            l_tbl_status(i) := pk_alert_constant.g_no;
        END LOOP;
    
        l_team_name := 'Team interface(' || i_episode || ')';
    
        g_error := 'CALL PK_SR_TOOLS.SET_PROF_TEAM';
        IF NOT pk_sr_tools.set_prof_team(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_prof_team    => NULL,
                                         i_name         => l_team_name,
                                         i_desc         => NULL,
                                         i_tbl_prof     => i_tbl_prof,
                                         i_tbl_catg     => i_tbl_catg,
                                         i_tbl_status   => l_tbl_status,
                                         i_test         => pk_alert_constant.g_no,
                                         o_flg_show     => l_flg_show,
                                         o_msg_title    => l_msg_title,
                                         o_msg_text     => l_msg_text,
                                         o_button       => l_button,
                                         o_error        => o_error,
                                         o_id_prof_team => o_id_team)
        THEN
            RAISE g_exception;
        
        END IF;
    
        -- Gets the surgery record associated to the episode...
        g_error := 'GET l_id_surgery_record';
        BEGIN
            SELECT id_surgery_record
              INTO l_id_surgery_record
              FROM sr_surgery_record ssr
             WHERE ssr.id_episode = i_episode;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        g_error := 'CALL pk_sr_tools.set_sr_prof_team_det_interface';
    
        IF NOT pk_sr_tools.set_sr_prof_team_det_interface(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_surgery_record    => l_id_surgery_record,
                                                          i_episode           => i_episode,
                                                          i_episode_context   => NULL,
                                                          i_prof_team         => o_id_team,
                                                          i_tbl_prof          => i_tbl_prof,
                                                          i_tbl_catg          => i_tbl_catg,
                                                          i_tbl_status        => l_tbl_status,
                                                          i_test              => pk_alert_constant.g_no,
                                                          i_id_sr_epis_interv => NULL,
                                                          o_flg_show          => l_flg_show,
                                                          o_msg_title         => l_msg_title,
                                                          o_msg_text          => l_msg_text,
                                                          o_button            => l_button,
                                                          o_error             => o_error)
        THEN
        
            RAISE g_exception;
        
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
                                              'INTERFACE_SET_TEAM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END interface_set_team;

    /*******************************************************************************************************************************************
    * Insert the team associated to intervention record
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_set_interv_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_epis_interv IN epis_interv.id_epis_interv%TYPE,
        i_id_prof_team   IN prof_team.id_prof_team%TYPE,
        i_tbl_prof       IN table_number,
        i_tbl_catg       IN table_number,
        o_id_team        OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_status table_varchar := table_varchar();
    
        l_team_name VARCHAR(100 CHAR);
        l_flg_show  VARCHAR2(100 CHAR);
        l_msg_title VARCHAR2(100 CHAR);
        l_msg_text  VARCHAR2(100 CHAR);
        l_button    VARCHAR2(100 CHAR);
    
        l_id_surgery_record sr_surgery_record.id_surgery_record%TYPE;
    
    BEGIN
    
        FOR i IN i_tbl_prof.first .. i_tbl_prof.last
        LOOP
            l_tbl_status.extend(1);
            l_tbl_status(i) := pk_alert_constant.g_no;
        END LOOP;
    
        l_team_name := 'Team interface(' || i_episode || ')';
    
        g_error := 'CALL PK_SR_TOOLS.SET_PROF_TEAM';
        IF NOT pk_sr_tools.set_prof_team(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_prof_team    => NULL,
                                         i_name         => l_team_name,
                                         i_desc         => NULL,
                                         i_tbl_prof     => i_tbl_prof,
                                         i_tbl_catg     => i_tbl_catg,
                                         i_tbl_status   => l_tbl_status,
                                         i_test         => pk_alert_constant.g_no,
                                         o_flg_show     => l_flg_show,
                                         o_msg_title    => l_msg_title,
                                         o_msg_text     => l_msg_text,
                                         o_button       => l_button,
                                         o_error        => o_error,
                                         o_id_prof_team => o_id_team)
        THEN
            RAISE g_exception;
        
        END IF;
    
        -- Gets the surgery record associated to the episode...
        g_error := 'GET l_id_surgery_record';
        BEGIN
            SELECT id_surgery_record
              INTO l_id_surgery_record
              FROM sr_surgery_record ssr
             WHERE ssr.id_episode = i_episode;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        g_error := 'CALL pk_sr_tools.set_sr_prof_team_det_interface';
    
        IF NOT pk_sr_tools.set_sr_prof_team_det_interface(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_surgery_record    => l_id_surgery_record,
                                                          i_episode           => i_episode,
                                                          i_episode_context   => NULL,
                                                          i_prof_team         => o_id_team,
                                                          i_tbl_prof          => i_tbl_prof,
                                                          i_tbl_catg          => i_tbl_catg,
                                                          i_tbl_status        => l_tbl_status,
                                                          i_test              => pk_alert_constant.g_no,
                                                          i_id_sr_epis_interv => NULL,
                                                          o_flg_show          => l_flg_show,
                                                          o_msg_title         => l_msg_title,
                                                          o_msg_text          => l_msg_text,
                                                          o_button            => l_button,
                                                          o_error             => o_error)
        THEN
        
            RAISE g_exception;
        
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
                                              'INTERFACE_SET_TEAM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END interface_set_interv_team;

    PROCEDURE map_interv_type(i_intervention_type IN OUT table_varchar) IS
    BEGIN
        FOR i IN 1 .. i_intervention_type.count
        LOOP
            IF i_intervention_type(i) IS NULL
            THEN
                i_intervention_type(i) := 'S';
            END IF;
        END LOOP;
    END map_interv_type;

    /*******************************************************************************************************************************************
    * Insert the intervention and the associated team
    *
    * @param i_lang                 ID lang
    * @param i_prof                 ID prof
    * @param i_episode              ID episode
    * @param i_sr_intervention      ID intervention (intervention.id_content)
    * @param i_intervention_type    Intervention type (intervention.flg_type - 'S' or 'P')
    * @param i_id_epis_diagnosis    ID epis_diagnosis 
    * @param i_prof_team            ID_prof_team
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_ins_bulk_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_intervention      IN table_varchar,
        i_intervention_type IN table_varchar,
        i_id_epis_diagnosis IN table_number DEFAULT NULL,
        i_prof_team         IN table_number DEFAULT NULL,
        o_sr_epis_interv    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_status table_table_varchar := table_table_varchar();
        l_tbl_prof   table_table_number := table_table_number();
        l_tbl_cat    table_table_number := table_table_number();
    
        l_flg_show  VARCHAR2(100 CHAR);
        l_msg_title VARCHAR2(100 CHAR);
        l_msg_text  VARCHAR2(100 CHAR);
        l_button    VARCHAR2(100 CHAR);
    
        l_id_surgery_record sr_surgery_record.id_surgery_record%TYPE;
        l_sr_epis_interv    sr_epis_interv.id_sr_epis_interv%TYPE;
        l_id_intervention   table_number;
        l_intervention_type table_varchar;
    
        l_sr_epis_interv_tbl table_number := table_number();
        l_id_epis_diagnosis  table_number := table_number();
    BEGIN
    
        -- gets all team members and categories.
        g_error := 'get interventions ids';
    
        /*sanity check*/
        IF i_id_epis_diagnosis IS NOT NULL
           AND i_prof_team IS NOT NULL
        THEN
            IF i_intervention.count != i_intervention_type.count
               OR i_intervention.count != i_prof_team.count
               OR i_intervention.count != i_id_epis_diagnosis.count
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_id_epis_diagnosis IS NOT NULL
        THEN
            IF i_intervention.count != i_intervention_type.count
               OR i_intervention.count != i_id_epis_diagnosis.count
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_prof_team IS NOT NULL
        THEN
            IF i_intervention.count != i_intervention_type.count
               OR i_intervention.count != i_prof_team.count
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF i_intervention.count != i_intervention_type.count
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        /*sanity check*/
    
        BEGIN
            SELECT id_intervention, id_interv_type, id_epis_diagnosis
              BULK COLLECT
              INTO l_id_intervention, l_intervention_type, l_id_epis_diagnosis
              FROM (SELECT rownum AS rn, column_value AS id_content
                      FROM TABLE(i_intervention)) interv
              JOIN (SELECT rownum AS rn, column_value AS id_interv_type
                      FROM TABLE(i_intervention_type)) TYPE
                ON interv.rn = type.rn
              JOIN (SELECT rownum AS rn, column_value AS id_epis_diagnosis
                      FROM TABLE(i_id_epis_diagnosis)) epis_diag
                ON interv.rn = epis_diag.rn
              JOIN intervention i
                ON i.id_content = interv.id_content
               AND i.flg_status = pk_prog_notes_constants.g_active
               AND instr(i.flg_type, pk_procedures_constant.g_type_interv_surgical) > 0;
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE g_exception;
        END;
    
        g_error := 'get prof team ';
        IF i_prof_team IS NOT NULL
        THEN
        
            <<lup_thru_prof_teams>>
            FOR i IN 1 .. i_prof_team.count
            LOOP
                l_tbl_prof.extend;
                l_tbl_cat.extend;
                l_tbl_status.extend;
                SELECT id_professional, id_category_sub, pk_alert_constant.g_no
                  BULK COLLECT
                  INTO l_tbl_prof(i), l_tbl_cat(i), l_tbl_status(i)
                  FROM prof_team_det
                 WHERE id_prof_team = i_prof_team(i)
                   AND flg_status = pk_alert_constant.g_active;
            END LOOP lup_thru_prof_teams;
        
        END IF;
    
        FOR i IN l_id_intervention.first .. l_id_intervention.last
        LOOP
        
            IF NOT pk_api_sr_visit.interface_ins_epis_surg(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_episode           => i_episode,
                                                           i_sr_intervention   => l_id_intervention(i),
                                                           i_prof_req          => i_prof.id,
                                                           i_flg_type          => l_intervention_type(i),
                                                           i_id_epis_diagnosis => CASE
                                                                                      WHEN i_id_epis_diagnosis IS NOT NULL THEN
                                                                                       l_id_epis_diagnosis(i)
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                           o_sr_epis_interv    => l_sr_epis_interv,
                                                           o_error             => o_error)
            THEN
            
                RAISE g_exception;
            END IF;
        
            l_sr_epis_interv_tbl.extend;
            l_sr_epis_interv_tbl(l_sr_epis_interv_tbl.last) := l_sr_epis_interv;
        
            IF i_prof_team IS NOT NULL
            THEN
                IF NOT pk_sr_tools.set_sr_prof_team_det_interface(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_surgery_record    => NULL,
                                                                  i_episode           => i_episode,
                                                                  i_episode_context   => NULL,
                                                                  i_prof_team         => i_prof_team(i),
                                                                  i_tbl_prof          => l_tbl_prof(i),
                                                                  i_tbl_catg          => l_tbl_cat(i),
                                                                  i_tbl_status        => l_tbl_status(i),
                                                                  i_test              => pk_alert_constant.g_no,
                                                                  i_id_sr_epis_interv => l_sr_epis_interv,
                                                                  o_flg_show          => l_flg_show,
                                                                  o_msg_title         => l_msg_title,
                                                                  o_msg_text          => l_msg_text,
                                                                  o_button            => l_button,
                                                                  o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        END LOOP;
    
        o_sr_epis_interv := l_sr_epis_interv_tbl;
    
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
                                              'INTERFACE_SET_TEAM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END interface_ins_bulk_interv;

    FUNCTION interface_create_surgery
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_prev_episode    IN episode.id_prev_episode%TYPE,
        i_id_episode_ext     IN VARCHAR2,
        i_id_wait_list       IN NUMBER,
        i_id_schedule        IN NUMBER,
        i_dt_schedule_tstz   IN VARCHAR2,
        i_interv_type        IN VARCHAR2,
        i_id_room            IN NUMBER,
        i_flg_surg_type      IN VARCHAR2,
        i_duration           IN NUMBER,
        i_id_prof_resp       IN NUMBER,
        i_id_prof_req        IN NUMBER,
        i_id_diagnosis       IN NUMBER,
        i_cod_icd_diagnosis  IN VARCHAR2,
        i_id_patient         IN NUMBER,
        i_flg_blood_req      IN VARCHAR2,
        i_id_dep_clin_serv   IN NUMBER,
        i_num_episode_prev   IN VARCHAR2,
        i_cod_module         IN VARCHAR2,
        i_id_external_sys    IN NUMBER,
        i_dt_sr_surgery_tstz IN VARCHAR2,
        io_episode           IN OUT episode.id_episode%TYPE,
        io_visit             IN OUT visit.id_visit%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        i_rec          pk_api_sr_visit.sr_new_schedule_struct;
        l_id_diagnosis diagnosis_ea.id_concept_version%TYPE;
    BEGIN
    
        IF i_cod_icd_diagnosis IS NOT NULL
        THEN
            BEGIN
                SELECT MIN(id_concept_version)
                  INTO l_id_diagnosis
                  FROM diagnosis_ea d
                 WHERE d.concept_code = i_cod_icd_diagnosis
                   AND d.id_institution = i_prof.institution
                   AND d.id_software = i_prof.software;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END IF;
    
        i_rec.id_wait_list       := i_id_wait_list;
        i_rec.id_schedule        := i_id_schedule;
        i_rec.dt_schedule_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_schedule_tstz, NULL);
        i_rec.interv_type        := i_interv_type;
        i_rec.id_room            := i_id_room;
        i_rec.flg_surg_type      := i_flg_surg_type;
        i_rec.duration           := i_duration;
        i_rec.id_prof_resp       := i_id_prof_resp;
        i_rec.id_prof_req        := i_id_prof_req;
        i_rec.id_diagnosis       := nvl(l_id_diagnosis, i_id_diagnosis);
        i_rec.id_patient         := i_id_patient;
        i_rec.flg_blood_req      := i_flg_blood_req;
        i_rec.id_dep_clin_serv   := i_id_dep_clin_serv;
        i_rec.num_episode_prev   := i_num_episode_prev;
        i_rec.cod_module         := i_cod_module;
        i_rec.id_external_sys    := i_id_external_sys;
        i_rec.dt_sr_surgery_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_sr_surgery_tstz, NULL);
    
        IF NOT pk_api_sr_visit.interface_create_all_surgery(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_rec             => i_rec,
                                                            i_id_episode_ext  => i_id_episode_ext,
                                                            i_id_prev_episode => i_id_prev_episode,
                                                            io_episode        => io_episode,
                                                            io_visit          => io_visit,
                                                            o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_id_prev_episode IS NOT NULL
        THEN
            UPDATE episode
               SET id_prev_episode = i_id_prev_episode
             WHERE id_episode = io_episode;
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
                                              'INTERFACE_SET_TEAM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interface_create_surgery;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_sr_visit;
/
