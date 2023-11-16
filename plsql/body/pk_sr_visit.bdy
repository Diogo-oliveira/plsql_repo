/*-- Last Change Revision: $Rev: 2027751 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_visit AS

    /********************************************************************************************
    * Criar uma visita. Esta visita é criada obrigatoriamente quando desejamos criar um episódio de 
    *  bloco operatório, que será utilizado para planeamento de uma cirurgia antes do paciente 
    *  iniciar propriamente o episódio. 
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_flg_temp         Indica se é um episódio temporário
    * @param i_id_episode_ext   ID do episódio externo
    * @param i_num_episode_prev id from previous SONHO episode
    * @param i_cod_module       type of module which originated previous episode
    * @param io_episode         ID do episódio criado
    * @param io_visit           ID da visita criada
    * @param i_id_dcs_requested ID da dep_clin_serv
    * @param i_dt_creation      data de criação do episódio (migração de episódios)
    * @param i_dt_begin         data de início do episódio (migração de episódios)
    * @param i_flg_migration    flag de migração M-migrado A-normal (migração de episódios)
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/01/31 
    * @altered by               Filipe Silva
    * @date                     2009/07/01
    * @Notas                    create episode with the dep_clin_serv (ALERT - 30974)
    * @altered by               Filipe Silva
    * @date                     2009/07/02
    * @Notas                    ALERT - 31101
    * @altered by               Sérgio Dias
    * @date                     2010/08/20
    * @Notas                    create episode by migration (ALERT-118077)
    ********************************************************************************************/
    FUNCTION create_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_flg_temp       IN epis_info.flg_unknown%TYPE,
        i_id_episode_ext IN VARCHAR2,
        i_flg_ehr        IN episode.flg_ehr%TYPE,
        /*BEGIN ALERT - 31101*/
        i_num_episode_prev IN epis_ext_sys.value%TYPE,
        i_cod_module       IN epis_ext_sys.cod_epis_type_ext%TYPE,
        /*END ALERT - 31101*/
        i_id_dcs_requested IN dep_clin_serv.id_dep_clin_serv%TYPE, --FSILVA 2009/07/01
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        i_dt_creation      IN episode.dt_creation%TYPE DEFAULT NULL,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_flg_migration    IN episode.flg_migration%TYPE DEFAULT NULL,
        io_episode         IN OUT episode.id_episode%TYPE,
        io_visit           IN OUT visit.id_visit%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --Obtem ID da visita
        g_error := 'GET VISIT SEQ';
        pk_alertlog.log_debug(g_error);
        --Obtém o ID da visita a criar se esta não vier já definida como parâmetro de entrada
        IF io_visit IS NULL
        THEN
            SELECT nvl(seq_visit.nextval, 1)
              INTO io_visit
              FROM dual;
        
            --Cria a visita
            g_error := 'INSERT SURG VISIT';
            pk_alertlog.log_debug(g_error);
            INSERT INTO visit
                (id_visit, dt_begin_tstz, dt_end_tstz, flg_status, id_patient, id_institution, dt_creation)
            VALUES
                (io_visit,
                 nvl(i_dt_begin, g_sysdate_tstz),
                 NULL,
                 g_flg_status_active,
                 i_patient,
                 i_prof.institution,
                 nvl(i_dt_begin, g_sysdate_tstz));
        
        END IF;
    
        --Cria o respectivo episódio
        g_error := 'CREATE SURG EPISODE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_episode(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_visit          => io_visit,
                                          i_flg_temp       => i_flg_temp,
                                          i_id_episode_ext => i_id_episode_ext,
                                          i_dt_creation    => nvl(i_dt_creation, g_sysdate_tstz), -- acrescentado tco 08/04/2008
                                          i_dt_begin       => nvl(i_dt_begin, g_sysdate_tstz), -- acrescentado tco 08/04/2008
                                          io_episode       => io_episode,
                                          i_flg_ehr        => i_flg_ehr,
                                          /*BEGIN ALERT 31101*/
                                          i_num_episode_prev => i_num_episode_prev,
                                          i_cod_module       => i_cod_module,
                                          /*END ALERT 31101*/
                                          i_id_dcs_requested => i_id_dcs_requested, --FSILVA 2009/07/01
                                          i_id_external_sys  => i_id_external_sys,
                                          i_flg_migration    => i_flg_migration,
                                          o_error            => o_error)
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
                                              'CREATE_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_visit;

    /********************************************************************************************
    * Criar registo na tabela SCHEDULE que permita o registo de informações relativas ao agendamento.
    *
    * @param i_lang             Id do idioma
    * @param i_schedule         Rowtype da tabela SCHEDULE
    * @param i_episode          episode identifier
    * @param o_schedule         ID do registo criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/12/09 
    ********************************************************************************************/
    FUNCTION create_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_schedule IN schedule%ROWTYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_schedule OUT schedule.id_schedule%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_schedule       schedule.id_schedule%TYPE;
        l_id_cs_requested   clinical_service.id_clinical_service%TYPE;
        l_id_department_req department.id_department%TYPE;
        l_id_dept_req       dept.id_dept%TYPE;
        l_rowids            table_varchar;
    BEGIN
    
        --Obtem próximo ID da sequência
        SELECT seq_schedule.nextval
          INTO l_id_schedule
          FROM dual;
    
        --insere registo na SCHEDULE
        g_error := 'INSERT SCHEDULE';
        pk_alertlog.log_debug(g_error);
        INSERT INTO schedule
            (id_schedule,
             id_instit_requests,
             id_instit_requested,
             id_dcs_requested,
             id_prof_schedules,
             id_sch_event,
             dt_schedule_tstz,
             flg_status,
             
             dt_begin_tstz,
             flg_urgency,
             id_room,
             flg_sch_type)
        VALUES
            (l_id_schedule,
             i_schedule.id_instit_requests,
             i_schedule.id_instit_requested,
             i_schedule.id_dcs_requested,
             i_schedule.id_prof_schedules,
             i_schedule.id_sch_event,
             i_schedule.dt_schedule_tstz,
             i_schedule.flg_status,
             
             i_schedule.dt_begin_tstz,
             i_schedule.flg_urgency,
             i_schedule.id_room,
             'S');
    
        o_schedule := l_id_schedule;
    
        g_error := 'GET ID_CS_REQUESTED';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT dcs.id_clinical_service, dpt.id_department, dpt.id_dept
              INTO l_id_cs_requested, l_id_department_req, l_id_dept_req
              FROM dep_clin_serv dcs, department dpt
             WHERE dcs.id_dep_clin_serv = i_schedule.id_dcs_requested
               AND dcs.id_department = dpt.id_department;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'UPDATE EPISODE';
        pk_alertlog.log_debug(g_error);
        ts_episode.upd(id_cs_requested_in         => nvl(l_id_cs_requested, -1),
                       id_department_requested_in => nvl(l_id_department_req, -1),
                       id_dept_requested_in       => nvl(l_id_dept_req, -1),
                       id_episode_in              => i_episode,
                       rows_out                   => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => profissional(0, 0, 0),
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
    
        g_error := 'UPDATE EPIS_INFO';
        pk_alertlog.log_debug(g_error);
        ts_epis_info.upd(id_episode_in           => i_episode,
                         id_dcs_requested_in     => i_schedule.id_dcs_requested,
                         id_dcs_requested_nin    => FALSE,
                         id_instit_requested_in  => i_schedule.id_instit_requested,
                         id_instit_requested_nin => FALSE,
                         id_prof_schedules_in    => i_schedule.id_prof_schedules,
                         id_prof_schedules_nin   => FALSE,
                         flg_sch_status_in       => i_schedule.flg_status,
                         flg_sch_status_nin      => FALSE,
                         flg_urgency_in          => i_schedule.flg_urgency,
                         flg_urgency_nin         => FALSE,
                         rows_out                => l_rowids);
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE';
        pk_alertlog.log_debug(g_error);
        --Process the events associated to an update on epis_info                         
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => profissional(0, 0, 0),
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SCHEDULE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_schedule;

    /********************************************************************************************
    * Criar registo na tabela SCHEDULE_SR que permita o registo de informações relativas à cirurgia.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             professional identifier
    * @param i_schedule_sr      Rowtype da tabela SCHEDULE_SR 
    * @param o_schedule_sr      ID do registo criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/01/31
    ********************************************************************************************/
    FUNCTION create_schedule_sr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_schedule_sr IN schedule_sr%ROWTYPE,
        o_schedule_sr OUT schedule_sr.id_schedule_sr%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
        l_rec            schedule_sr%ROWTYPE := i_schedule_sr;
        l_rowids         table_varchar;
    BEGIN
        -- Insert registry in SCHEDULE_SR
        g_error := 'CALL TS_SCHEDULE_SR.INS WITH ID_SCHEDULE_SR = ' || l_id_schedule_sr;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        --
        l_id_schedule_sr     := ts_schedule_sr.next_key();
        l_rec.id_schedule_sr := l_id_schedule_sr;
        --
        ts_schedule_sr.ins(rec_in => l_rec, gen_pky_in => FALSE, rows_out => l_rowids);
    
        g_error := 'PROCESS INSERT WITH ID_SCHEDULE_SR ' || l_id_schedule_sr;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
    
        o_schedule_sr := l_id_schedule_sr;
        IF l_rec.id_episode IS NOT NULL
        THEN
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in     => l_rec.id_episode,
                             id_schedule_sr_in => l_id_schedule_sr,
                             rows_out          => l_rowids);
            g_error := 'PROCESS UPDATE WITH ID_SCHEDULE_SR ' || l_id_schedule_sr;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_INFO',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_SCHEDULE_SR'));
        END IF;
    
        --Call ALERT_INTER event new
        alert_inter.pk_ia_event_schedule.surgery_request_new(i_id_institution => i_prof.institution,
                                                             i_id_schedule_sr => l_rec.id_schedule_sr);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SCHEDULE_SR',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_schedule_sr;

    /********************************************************************************************
    * Criar registo na tabela SR_SURGERY_RECORD que permita o registo de informações relativas à cirurgia.
    *
    * @param i_lang             Id do idioma
    * @param i_sr_surg_rec      Rowtype da tabela SR_SURGERY_RECORD
    * @param i_prof             professional identifier
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/01/31 
    ********************************************************************************************/
    FUNCTION create_surgery_record
    (
        i_lang        IN language.id_language%TYPE,
        i_sr_surg_rec IN sr_surgery_record%ROWTYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_idepisode         schedule_sr.id_episode%TYPE;
        l_rowsid            table_varchar;
        excep               EXCEPTION;
        l_id_surgery_record sr_surgery_record.id_surgery_record%TYPE;
    
    BEGIN
    
        --Insere registo na tabela SR_SURGERY_RECORD
        g_error := 'INSERT SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        ts_sr_surgery_record.ins(id_schedule_sr_in      => i_sr_surg_rec.id_schedule_sr,
                                 id_sr_intervention_in  => i_sr_surg_rec.id_sr_intervention,
                                 id_prof_team_in        => i_sr_surg_rec.id_prof_team,
                                 id_patient_in          => i_sr_surg_rec.id_patient,
                                 flg_pat_status_in      => i_sr_surg_rec.flg_pat_status,
                                 flg_state_in           => i_sr_surg_rec.flg_state,
                                 flg_surg_nat_in        => i_sr_surg_rec.flg_surg_nat,
                                 flg_surg_type_in       => i_sr_surg_rec.flg_surg_type,
                                 flg_urgency_in         => i_sr_surg_rec.flg_urgency,
                                 id_anesthesia_type_in  => i_sr_surg_rec.id_anesthesia_type,
                                 id_clinical_service_in => i_sr_surg_rec.id_clinical_service,
                                 notes_in               => i_sr_surg_rec.notes,
                                 id_prof_cancel_in      => i_sr_surg_rec.id_prof_cancel,
                                 notes_cancel_in        => i_sr_surg_rec.notes_cancel,
                                 id_institution_in      => i_sr_surg_rec.id_institution,
                                 adw_last_update_in     => SYSDATE,
                                 dt_anest_start_tstz_in => i_sr_surg_rec.dt_anest_start_tstz,
                                 dt_anest_end_tstz_in   => i_sr_surg_rec.dt_anest_end_tstz,
                                 dt_sr_entry_tstz_in    => i_sr_surg_rec.dt_sr_entry_tstz,
                                 dt_sr_exit_tstz_in     => i_sr_surg_rec.dt_sr_exit_tstz,
                                 dt_room_entry_tstz_in  => i_sr_surg_rec.dt_room_entry_tstz,
                                 dt_room_exit_tstz_in   => i_sr_surg_rec.dt_room_exit_tstz,
                                 dt_rcv_entry_tstz_in   => i_sr_surg_rec.dt_rcv_entry_tstz,
                                 dt_rcv_exit_tstz_in    => i_sr_surg_rec.dt_rcv_exit_tstz,
                                 dt_cancel_tstz_in      => i_sr_surg_rec.dt_cancel_tstz,
                                 id_episode_in          => i_sr_surg_rec.id_episode,
                                 flg_sr_proc_in         => i_sr_surg_rec.flg_sr_proc,
                                 dt_flg_sr_proc_in      => i_sr_surg_rec.dt_flg_sr_proc,
                                 rows_out               => l_rowsid);
        g_error := 'PROCESS INSERT SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_SURGERY_RECORD',
                                      i_rowids     => SET(l_rowsid),
                                      o_error      => o_error);
    
        SELECT id_episode
          INTO l_idepisode
          FROM schedule_sr
         WHERE id_schedule_sr = i_sr_surg_rec.id_schedule_sr;
    
        IF l_idepisode IS NOT NULL
        THEN
            l_rowsid := table_varchar();
            g_error  := 'CALL TS_EPIS_INFO.UPD FOR ID_EPISODE' || i_sr_surg_rec.id_episode;
            pk_alertlog.log_debug(g_error);
            ts_epis_info.upd(id_episode_in          => l_idepisode,
                             flg_pat_status_in      => i_sr_surg_rec.flg_pat_status,
                             flg_pat_status_nin     => FALSE,
                             dt_room_entry_tstz_in  => i_sr_surg_rec.dt_room_entry_tstz,
                             dt_room_entry_tstz_nin => FALSE,
                             rows_out               => l_rowsid);
            g_error := 'PROCESS UPDATE EPIS_INFO';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_INFO',
                                          i_rowids       => l_rowsid,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_PAT_STATUS', 'DT_ROOM_ENTRY_TSTZ'));
        END IF;
    
        -- insert into t_log
        SELECT id_surgery_record
          INTO l_id_surgery_record
          FROM sr_surgery_record ssr
         WHERE ssr.id_episode = i_sr_surg_rec.id_episode;
    
        g_error := 'CALL T_TI_LOG.INS_LOG FOR ID_EPISODE' || i_sr_surg_rec.id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT t_ti_log.ins_log(i_lang,
                                i_prof,
                                i_sr_surg_rec.id_episode,
                                i_sr_surg_rec.flg_sr_proc,
                                l_id_surgery_record,
                                pk_sr_surg_record.g_surgery_process_type,
                                o_error)
        THEN
            RAISE excep;
        END IF;
    
        g_error := 'CALL CREATE_SR_PAT_STATUS FOR ID_EPISODE : ' || l_idepisode;
        pk_alertlog.log_debug(g_error);
        IF NOT create_sr_pat_status(i_lang, i_prof, l_idepisode, i_sr_surg_rec.flg_pat_status, o_error)
        THEN
            RAISE excep;
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
                                              'CREATE_SURGERY_RECORD',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_surgery_record;

    /*******************************************************************************************************************************************
    * Returns Surgery Request episodes for a specific Scope - for Reports 
    * 
    * @param  I_LANG                   Language ID for translations
    * @param  I_PROF                   Professional vector of information (professional ID, institution ID, software ID)    
    * @param  I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param  I_FLG_SCOPE              Scope type
    * @param  I_START_DATE             Start date for temporal filtering
    * @param  I_END_DATE               End date for temporal filtering
    * @param  I_CANCELLED              Indicates whether the records should be returned canceled
    * @param  I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param  I_FLG_REPORT             Flag used to remove formatting
    * @param  I_FLG_CONTEXT            Grid information aggregated or not
    * @param  I_STATUS                 Episode state
    * @param  I_PLANNED                Planned Surgery
    * @param  O_GRID                   Cursor that returns Episodes for Operating Room in the current Scope
    * @param  O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value  I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value  I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value  I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value  I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * @value  I_FLG_REPORT             {*} 'Y' Yes {*} 'N' No
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          20-May-2011
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          09-Nov-2011
    *
    * @dependencies                   REPORTS
    *******************************************************************************************************************************************/
    FUNCTION get_pat_surg_episodes_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        i_status     IN VARCHAR2,
        i_planned    IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_type episode.id_epis_type%TYPE;
    
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        e_invalid_argument EXCEPTION;
    
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
        l_end_date   TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        --convert string to date format
        IF i_start_date IS NOT NULL
        THEN
            l_start_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL);
        END IF;
        IF i_end_date IS NOT NULL
        THEN
            l_end_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL);
        END IF;
    
        --Obtém o tipo de episódio de Bloco Operatório
        SELECT pk_sysconfig.get_config('ID_EPIS_TYPE_ORIS', i_prof)
          INTO l_id_epis_type
          FROM dual;
    
        --Obtém cursor com os episódios de bloco
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT *
              FROM (SELECT e.id_episode,
                           s.id_schedule_sr,
                           pk_sr_clinical_info.get_proposed_surgery(i_lang, s.id_episode, i_prof, pk_alert_constant.g_no) desc_interv,
                           pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                    s.id_episode,
                                                                    i_prof,
                                                                    pk_alert_constant.g_yes) desc_interv_reports,
                           pk_message.get_message(i_lang, 'SR_LABEL_T360') desc_interv_new,
                           pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_surg_proc,
                           SYSDATE dt_server,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) || ' (' || --
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            e.dt_begin_tstz,
                                                            e.id_episode) || ')' prof_desc,
                           decode(e.flg_status,
                                  g_cancel,
                                  g_cancel,
                                  nvl((SELECT decode(MIN(decode(flg_status, 'E', 1, 'R', 2, 'F', 3, 'C', 4)),
                                                    1,
                                                    'E',
                                                    2,
                                                    'R',
                                                    3,
                                                    'F',
                                                    4,
                                                    'C')
                                        FROM sr_epis_interv
                                       WHERE id_episode_context = e.id_episode),
                                      decode(e.flg_status, g_flg_status_inactive, 'F', 'R'))) flg_status,
                           pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) dt_interv_preview,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       s.dt_interv_preview_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_interv_preview_rep,
                           pk_date_utils.date_char_tsz(i_lang, e.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                           (SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
                              FROM room_scheduled rs, room r
                             WHERE rs.id_schedule = s.id_schedule
                               AND rs.flg_status = g_flg_status_active
                               AND r.id_room = rs.id_room) desc_room,
                           pk_sr_surg_record.get_surg_est_dur(i_lang, i_prof, e.id_episode, s.duration) duration,
                           pk_patient.get_pat_name(i_lang, i_prof, v.id_patient, e.id_episode, s.id_schedule) pat_name,
                           sr.flg_surg_nat,
                           pk_sysdomain.get_domain('SR_SURGERY_RECORD.FLG_SURG_NAT', sr.flg_surg_nat, i_lang) desc_surg_nat,
                           sr.flg_priority,
                           pk_sysdomain.get_domain('SR_SURGERY_RECORD.FLG_PRIORITY', sr.flg_priority, i_lang) desc_priority,
                           pk_sr_visit.check_icon_status(i_lang, i_prof, e.id_episode) icon,
                           sr.flg_sr_proc flg_sr_proc
                      FROM visit v
                     INNER JOIN episode e
                        ON v.id_visit = e.id_visit
                     INNER JOIN schedule_sr s
                        ON e.id_episode = s.id_episode
                      LEFT OUTER JOIN professional p
                        ON s.id_prof_reg = p.id_professional
                     INNER JOIN sr_surgery_record sr
                        ON s.id_schedule_sr = sr.id_schedule_sr
                     WHERE e.id_episode = nvl(l_id_episode, e.id_episode)
                       AND e.id_visit = nvl(l_id_visit, e.id_visit)
                       AND e.id_patient = nvl(l_id_patient, e.id_patient)
                       AND e.dt_begin_tstz BETWEEN nvl(l_start_date, e.dt_begin_tstz) AND
                           nvl(l_end_date, e.dt_begin_tstz)
                       AND v.id_institution = i_prof.institution
                       AND e.id_epis_type = l_id_epis_type -- Tipo de episódio = Bloco Operatório                          
                       AND ((e.flg_status = i_status OR i_status = g_flg_status_all) AND
                           (
                           --if not report show all
                            i_flg_report = pk_alert_constant.g_no OR
                           --if report and not to show cancellations
                            (i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                            e.flg_status <> pk_alert_constant.g_cancelled) OR
                           --if report and show cancellations
                            (i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes)))
                       AND (i_crit_type = g_epis_finished AND e.flg_status = g_flg_status_inactive OR
                           i_crit_type != g_epis_finished)
                     ORDER BY decode(flg_status, g_interv_f, 1, g_interv_e, 2, g_interv_r, 3, g_interv_c, 4),
                              v.dt_begin_tstz) gd
             WHERE (i_planned = 'P' -- planeadas 
                   AND gd.flg_status NOT IN (g_interv_e, g_interv_f, g_interv_c) AND
                   gd.flg_sr_proc NOT IN
                   (pk_sr_approval.g_in_surgery, pk_sr_approval.g_completed_surgery, pk_sr_approval.g_cancel_surgery))
                OR i_planned IS NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_SURG_EPISODES_INT',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_pat_surg_episodes_int;

    /********************************************************************************************
    * Lista de episódios de bloco operatório para o doente indicado. 
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_status           Estado do episódio
    * @param i_planned          cirurgia planeada
    * 
    * @param o_grid             Array de episódios de bloco operatório
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_room             Array com as salas do Bloco Operatório
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/08/28 
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_status   IN VARCHAR2,
        i_planned  IN VARCHAR2,
        o_grid     OUT pk_types.cursor_type,
        o_status   OUT pk_types.cursor_type,
        o_room     OUT pk_types.cursor_type,
        o_id_disch OUT disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_type episode.id_epis_type%TYPE;
    
        l_flg_admin_medic_o CONSTANT discharge_reason.flg_admin_medic%TYPE := 'O';
    
        CURSOR c_disch_reas_dest IS
            SELECT drd.id_disch_reas_dest
              FROM discharge_reason dr, disch_reas_dest drd
             WHERE flg_available = pk_alert_constant.g_available
               AND flg_admin_medic = l_flg_admin_medic_o
               AND drd.flg_active = pk_alert_constant.g_active
               AND dr.flg_available = pk_alert_constant.g_available
               AND drd.id_discharge_reason = dr.id_discharge_reason
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
             ORDER BY dr.rank, drd.rank, drd.id_disch_reas_dest;
    
        err_get_pat_surg_episodes_int EXCEPTION;
    
    BEGIN
    
        --Obtém o tipo de episódio de Bloco Operatório
        SELECT pk_sysconfig.get_config('ID_EPIS_TYPE_ORIS', i_prof)
          INTO l_id_epis_type
          FROM dual;
    
        --Obtém array das salas do Bloco Operatório
        g_error := 'CALL GET_ROOMS_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT get_rooms_list(i_lang => i_lang, i_prof => i_prof, o_room => o_room, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --Abre cursor com os icons dos vários estados
        g_error := 'GET STATUS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_status FOR
            SELECT val, img_name
              FROM sys_domain
             WHERE code_domain = 'SR_EPIS_INTERV.FLG_STATUS'
               AND id_language = i_lang;
    
        -- Default disch_reas_dest to be used when closing an ORIS episode
        g_error := 'GET O_ID_DISCH';
        pk_alertlog.log_debug(g_error);
        OPEN c_disch_reas_dest;
        FETCH c_disch_reas_dest
            INTO o_id_disch;
        CLOSE c_disch_reas_dest;
    
        g_error := 'CALL GET_PAT_SURG_EPISODES_INT';
        pk_alertlog.log_debug(g_error);
        IF NOT get_pat_surg_episodes_int(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_scope      => i_patient,
                                         i_flg_scope  => pk_alert_constant.g_scope_type_patient,
                                         i_start_date => NULL,
                                         i_end_date   => NULL,
                                         i_cancelled  => pk_alert_constant.g_yes,
                                         i_crit_type  => pk_surgery_request.g_sr_crit_type_all_a,
                                         i_flg_report => pk_alert_constant.g_no,
                                         i_status     => i_status,
                                         i_planned    => i_planned,
                                         o_grid       => o_grid,
                                         o_error      => o_error)
        THEN
            RAISE err_get_pat_surg_episodes_int;
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
                                              'GET_PAT_SURG_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_room);
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_surg_episodes;

    /*******************************************************************************************************************************************
    * Returns Surgery Request episodes for a specific Scope - for Reports 
    * 
    * @param  I_LANG                   Language ID for translations
    * @param  I_PROF                   Professional vector of information (professional ID, institution ID, software ID)    
    * @param  I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param  I_FLG_SCOPE              Scope type
    * @param  I_START_DATE             Start date for temporal filtering
    * @param  I_END_DATE               End date for temporal filtering
    * @param  I_CANCELLED              Indicates whether the records should be returned canceled
    * @param  I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param  I_FLG_REPORT             Flag used to remove formatting
    * @param  I_FLG_CONTEXT            Grid information aggregated or not
    * @param  I_STATUS                 Episode state
    * @param  I_PLANNED                Planned Surgery
    * @param  O_GRID                   Cursor that returns Episodes for Operating Room in the current Scope
    * @param  O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value  I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value  I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value  I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value  I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * @value  I_FLG_REPORT             {*} 'Y' Yes {*} 'N' No
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          20-May-2011
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          09-Nov-2011
    *
    * @dependencies                   REPORTS
    *******************************************************************************************************************************************/
    FUNCTION get_pat_surg_episodes_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        i_status     IN VARCHAR2,
        i_planned    IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_get_pat_surg_episodes_int EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL GET_PAT_SURG_EPISODES_INT';
        pk_alertlog.log_debug(g_error);
        IF NOT get_pat_surg_episodes_int(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_scope      => i_scope,
                                         i_flg_scope  => i_flg_scope,
                                         i_start_date => i_start_date,
                                         i_end_date   => i_end_date,
                                         i_cancelled  => i_cancelled,
                                         i_crit_type  => i_crit_type,
                                         i_flg_report => i_flg_report,
                                         i_status     => i_status,
                                         i_planned    => i_planned,
                                         o_grid       => o_grid,
                                         o_error      => o_error)
        THEN
            RAISE err_get_pat_surg_episodes_int;
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
                                              'GET_PAT_SURG_EPISODES_REP',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_pat_surg_episodes_rep;

    /********************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_status           Estado do episódio
    * 
    * @param o_num              Array de episódios de bloco operatório
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/08/28
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes_count
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_status  IN VARCHAR2,
        o_num     OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_type episode.id_epis_type%TYPE;
    
    BEGIN
    
        --Obtém o tipo de episódio de Bloco Operatório
        SELECT pk_sysconfig.get_config('ID_EPIS_TYPE_ORIS', i_prof)
          INTO l_id_epis_type
          FROM dual;
    
        --Obtém número de episódios de bloco
        g_error := 'GET EPISODES COUNT';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO o_num
          FROM visit v, episode e, schedule_sr s --, sr_intervention i, sr_epis_interv ei
         WHERE v.id_patient = i_patient
           AND v.id_institution = i_prof.institution
           AND e.id_visit = v.id_visit
           AND e.id_epis_type = l_id_epis_type -- Tipo de episódio = Bloco Operatório
           AND (e.flg_status = i_status OR i_status = g_flg_status_all)
           AND s.id_episode = e.id_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_SURG_EPISODES_COUNT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_surg_episodes_count;

    /********************************************************************************************
    * Get list of all surgery rooms
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_room             Lista de quartos
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Luís Maia
    * @since                    2011/Jun/01
    ********************************************************************************************/
    FUNCTION get_rooms_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_room  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --Obtém array das salas do Bloco Operatório
        g_error := 'OPEN O_ROOM_LIST ARRAY';
        OPEN o_room FOR
            SELECT t.data, t.label
              FROM (SELECT r.id_room data,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) label,
                           r.rank
                      FROM dept dp, department d, room r
                     WHERE dp.id_dept = d.id_dept
                       AND d.flg_type = g_flg_type_s
                       AND d.flg_available = pk_alert_constant.g_available
                       AND d.id_institution = i_prof.institution
                       AND d.id_department = r.id_department
                       AND r.flg_wait != g_flg_yes
                       AND r.flg_recovery != g_flg_yes
                       AND r.flg_available = pk_alert_constant.g_available) t
             ORDER BY t.rank, regexp_substr(t.label, '^\D*') NULLS FIRST, to_number(regexp_substr(t.label, '\d+'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOMS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_room);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rooms_list;

    /********************************************************************************************
    * Actualiza a data prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_schedule_sr      ID do agendamento
    * @param i_dt               Data prevista da realização da cirurgia
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_flg_show         Indica de deve ou não ser mostrada uma mensagem de aviso
    * @param o_msg_title        Título da mensagem
    * @param o_msg_text         Descrição da mensagem
    * @param o_button           Botões a disponibilizar
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/11/28
    ********************************************************************************************/
    FUNCTION upd_surg_proc_preview_dt
    (
        i_lang        IN language.id_language%TYPE,
        i_schedule_sr IN schedule_sr.id_schedule_sr%TYPE,
        i_dt          IN VARCHAR2,
        i_prof        IN profissional,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num    PLS_INTEGER;
        l_dt     TIMESTAMP WITH LOCAL TIME ZONE;
        l_rowids table_varchar;
    
    BEGIN
    
        l_dt := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL), current_timestamp);
    
        --verifica se já há outro processo cirúrgico para este paciente na mesma data
        SELECT COUNT(*)
          INTO l_num
          FROM schedule_sr
         WHERE id_patient = (SELECT id_patient
                               FROM schedule_sr
                              WHERE id_schedule_sr = i_schedule_sr)
           AND flg_status = g_flg_status_active
           AND pk_date_utils.trunc_insttimezone(i_prof, dt_target_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, l_dt, NULL);
    
        IF l_num > 1
           AND i_test = pk_alert_constant.g_yes
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013'); --"Data inválida"
            o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_M015'); --"Já existe um processo cirúrgico activo para este paciente nesta data. Por favor, indique uma data válida."
            o_button    := 'C';
            RETURN TRUE;
        ELSE
            o_flg_show := 'N';
            --Actualiza data prevista do agendamento
            g_error := 'CALL TS_SCHEDULE_SR.UPD WITH ID_SCHEDULE_SR = ' || i_schedule_sr;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_schedule_sr.upd(id_schedule_sr_in         => i_schedule_sr,
                               dt_target_tstz_in         => l_dt,
                               dt_interv_preview_tstz_in => l_dt,
                               rows_out                  => l_rowids);
        
            g_error := 'PROCESS UPDATE WITH ID_SCHEDULE_SR ' || i_schedule_sr;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
        
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
                                              'UPD_SURG_PROC_PREVIEW_DT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END upd_surg_proc_preview_dt;

    /********************************************************************************************
    * Actualiza a sala prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_schedule_sr      ID do agendamento
    * @param i_room             ID da sala prevista para a intervenção cirúrgica
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/11/28
    ********************************************************************************************/
    FUNCTION upd_surg_proc_preview_room
    (
        i_lang        IN language.id_language%TYPE,
        i_schedule_sr IN schedule_sr.id_schedule_sr%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_id_room room.id_room%TYPE;
        l_schedule    schedule.id_schedule%TYPE;
        l_idepisode   schedule_sr.id_episode%TYPE;
        l_idroomsched room_scheduled.id_room_scheduled%TYPE;
        l_rowsid      table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        --Obtém a sala agendada actualmente
        g_error := 'GET CURRENT ROOM';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT id_room
              INTO l_cur_id_room
              FROM room_scheduled
             WHERE id_schedule = (SELECT id_schedule
                                    FROM schedule_sr
                                   WHERE id_schedule_sr = i_schedule_sr)
               AND flg_status = g_flg_status_active;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_cur_id_room := NULL;
        END;
    
        --Só actualiza a sala se ainda não existir ou for diferente da actual
        IF nvl(l_cur_id_room, -1) != i_room
        THEN
            --Só pode haver uma sala activa para cada agendamento, por isso, cancela as anteriores
            g_error := 'UPDATE OLD ROOM STATUS';
            pk_alertlog.log_debug(g_error);
            UPDATE room_scheduled
               SET flg_status = g_cancel
             WHERE id_schedule IN (SELECT id_schedule
                                     FROM schedule_sr
                                    WHERE id_schedule_sr = i_schedule_sr)
               AND flg_status = g_flg_status_active;
        
            --Obtém ID do agendamento
            BEGIN
                g_error := 'GET ID_SCHEDULE';
                pk_alertlog.log_debug(g_error);
                SELECT id_schedule, id_episode
                  INTO l_schedule, l_idepisode
                  FROM schedule_sr
                 WHERE id_schedule_sr = i_schedule_sr;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_schedule := NULL;
                
            END;
        
            IF l_schedule IS NOT NULL
            THEN
                --Actualiza sala prevista do agendamento
                g_error := 'INSERT INTO ROOM_SCHEDULED';
                pk_alertlog.log_debug(g_error);
                INSERT INTO room_scheduled
                    (id_room_scheduled,
                     dt_room_scheduled_tstz,
                     id_schedule,
                     id_room,
                     flg_status,
                     dt_start_tstz,
                     dt_end_tstz)
                VALUES
                    (seq_room_scheduled.nextval, g_sysdate_tstz, l_schedule, i_room, g_flg_status_active, NULL, NULL)
                RETURNING id_room_scheduled INTO l_idroomsched;
            
                IF l_idepisode IS NOT NULL
                THEN
                    g_error := 'UPDATE EPIS_INFO';
                    pk_alertlog.log_debug(g_error);
                    ts_epis_info.upd(id_episode_in          => l_idepisode,
                                     id_room_scheduled_in   => l_idroomsched,
                                     room_sch_flg_status_in => g_flg_status_active,
                                     rows_out               => l_rowsid);
                
                    g_error := 'PROCESS UPDATE EPIS INFO';
                    pk_alertlog.log_debug(g_error);
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPIS_INFO',
                                                  i_rowids       => l_rowsid,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('ID_ROOM_SCHEDULED',
                                                                                  'ROOM_SCH_FLG_STATUS'));
                END IF;
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
                                              'UPD_SURG_PROC_PREVIEW_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END upd_surg_proc_preview_room;

    /********************************************************************************************
    * Actualiza a duração prevista de realização de uma cirurgia na criação de um novo processo cirúrgico
    *
    * @param i_lang             Id do idioma
    * @param i_schedule_sr      ID do agendamento
    * @param i_duration         Tempo previsto de duração da intervenção (em segundos)
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/11/28
    ********************************************************************************************/
    FUNCTION upd_surg_proc_preview_duration
    (
        i_lang        IN language.id_language%TYPE,
        i_schedule_sr IN schedule_sr.id_schedule_sr%TYPE,
        i_duration    IN schedule_sr.duration%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
    
    BEGIN
    
        --Actualiza a duração prevista da cirurgia
        g_error := 'CALL TS_SCHEDULE_SR.UPD WITH ID_SCHEDULE_SR = ' || i_schedule_sr;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_schedule_sr.upd(duration_in => i_duration,
                           where_in    => 'id_schedule_sr = ' || i_schedule_sr || --
                                          ' AND nvl(duration, 0) != nvl(' || i_duration || ', 0)',
                           rows_out    => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH ID_SCHEDULE_SR = ' || i_schedule_sr;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error, table_varchar('DURATION'));
    
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
                                              'UPD_SURG_PROC_PREVIEW_DURATION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_surg_proc_preview_duration;

    /********************************************************************************************
    * Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    *  de existir um agendamento, diagnóstico base e intervenção a realizar definidos (NOVO PROCESSO CIRÚRGICO)
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_episode_new      ID do novo episodio criado
    * @param o_schedule         ID do agendamento criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2007/05/24
    ********************************************************************************************/
    FUNCTION create_all_surgery
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN OUT patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_episode_new OUT episode.id_episode%TYPE,
        o_schedule    OUT schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_SR_VISIT.CHECK_EXISTS_SOFTWARE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.check_exists_software(i_prof.institution, g_sr_software)
        THEN
            --A instituição não tem ORIS instalado, assim, não será criado o episódio
            RETURN TRUE;
        END IF;
    
        --Cria o processo cirúrgico
        g_error := 'CALL TO PK_SR_VISIT.CREATE_ALL_SURGERY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_all_surgery_int(i_lang             => i_lang,
                                                  i_patient          => i_patient,
                                                  i_prof             => i_prof,
                                                  i_visit            => NULL,
                                                  i_flg_ehr          => g_flg_ehr_n,
                                                  i_id_dcs_requested => NULL, --FSILVA 2009/07/01
                                                  i_dt_creation      => NULL,
                                                  i_dt_begin         => NULL,
                                                  i_id_episode_ext   => NULL,
                                                  i_flg_migration    => NULL,
                                                  i_id_room          => NULL,
                                                  i_id_external_sys  => NULL,
                                                  o_episode_new      => o_episode_new,
                                                  o_schedule         => o_schedule,
                                                  o_error            => o_error)
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
                                              'CREATE_ALL_SURGERY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_all_surgery;

    /********************************************************************************************
    * Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    *  de existir um agendamento, diagnóstico base e intervenção a realizar definidos (NOVO PROCESSO CIRÚRGICO)
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_prev_episode     Id do episódio de consulta, urgência ou internamento ao qual o episódio de bloco
    *                            irá ficar associado
    * @param i_type             Tipo de cirurgia: C-Convencional, A- Ambulatória
    * @param i_dt_surg          Data prevista para a realização da cirurgia
    * @param i_room             ID da sala prevista para a realização da cirurgia
    * @param i_duration         Duração prevista da cirurgia (em segundos, por causa do SONHO)
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * 
    * @param o_episode_new      ID do novo episodio criado
    * @param o_schedule         ID do agendamento criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2007/05/31
    ********************************************************************************************/
    FUNCTION create_all_surgery
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN OUT patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_prev_episode IN episode.id_prev_episode%TYPE,
        i_type         IN VARCHAR2,
        i_dt_surg      IN VARCHAR2,
        i_room         IN room.id_room%TYPE,
        i_duration     IN schedule_sr.duration%TYPE,
        i_flg_ehr      IN episode.flg_ehr%TYPE,
        o_episode_new  OUT episode.id_episode%TYPE,
        o_schedule     OUT schedule.id_schedule%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode_oris      episode.id_episode%TYPE;
        l_schedule          schedule.id_schedule%TYPE;
        l_schedule_sr       schedule_sr.id_schedule_sr%TYPE;
        l_epis_type         epis_type.id_epis_type%TYPE;
        l_oris_epis_type    epis_type.id_epis_type%TYPE;
        l_cod_epis_type_ext VARCHAR2(4);
        l_flg_show          VARCHAR2(1);
        l_msg_title         VARCHAR2(200);
        l_msg_text          VARCHAR2(2000);
        l_button            VARCHAR2(3);
        --l_error             VARCHAR2(4000);
        l_visit             visit.id_visit%TYPE;
        l_id_prev_epis_type episode.id_prev_epis_type%TYPE;
        l_visit_oris        visit.id_visit%TYPE;
        l_prev_room         room.id_room%TYPE;
        l_flg_unknown       epis_info.flg_unknown%TYPE;
    
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
    
        CURSOR c_visit IS
            SELECT v.id_visit, epis.id_epis_type
              FROM episode epis, visit v
             WHERE epis.id_episode = i_prev_episode
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) != 2
               AND v.id_visit = epis.id_visit
               AND v.flg_status = g_flg_status_active
             ORDER BY decode(epis.id_epis_type, 5, 1, 2, 2, 1, 3, 4);
    
        FUNCTION get_epis_type_root(i_episode IN episode.id_episode%TYPE) RETURN episode.id_prev_epis_type%TYPE IS
            l_epis_type_root episode.id_prev_epis_type%TYPE;
        BEGIN
            SELECT a.id_epis_type
              INTO l_epis_type_root
              FROM (SELECT epis.id_epis_type
                      FROM episode epis
                     START WITH epis.id_episode = i_episode
                    CONNECT BY PRIOR epis.id_prev_episode = epis.id_episode
                     ORDER BY epis.id_prev_epis_type NULLS FIRST) a
             WHERE rownum = 1;
        
            RETURN l_epis_type_root;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_epis_type_root;
    
    BEGIN
    
        g_error := 'CALL TO PK_SR_VISIT.CHECK_EXISTS_SOFTWARE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.check_exists_software(i_prof.institution, g_sr_software)
        THEN
            --A instituição não tem ORIS instalado, assim, não será criado o episódio
            RETURN TRUE;
        END IF;
    
        --Obtem o id_epis_type do ORIS
        BEGIN
            g_error := 'GET ORIS EPIS_TYPE';
            pk_alertlog.log_debug(g_error);
            SELECT etsi.id_epis_type
              INTO l_oris_epis_type
              FROM epis_type_soft_inst etsi, software sw
             WHERE sw.intern_name = 'SR'
               AND etsi.id_software = sw.id_software
               AND etsi.id_institution = i_prof.institution;
        EXCEPTION
            WHEN no_data_found THEN
                -- José Brito 12/02/2009 ALERT-9546
                l_oris_epis_type := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_ORIS', i_prof => i_prof);
        END;
    
        --Obtém o ID da visita no caso de já existir uma aberta
        g_error := 'GET OPEN VISIT ID';
        pk_alertlog.log_debug(g_error);
        l_visit := NULL;
    
        IF i_prev_episode IS NOT NULL
        THEN
            OPEN c_visit;
            FETCH c_visit
                INTO l_visit, l_id_prev_epis_type;
            CLOSE c_visit;
        END IF;
    
        --Cria o processo cirúrgico
        g_error := 'CALL TO PK_SR_VISIT.CREATE_ALL_SURGERY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_all_surgery_int(i_lang             => i_lang,
                                                  i_patient          => i_patient,
                                                  i_prof             => i_prof,
                                                  i_visit            => l_visit,
                                                  i_flg_ehr          => i_flg_ehr,
                                                  i_id_dcs_requested => NULL, --FSILVA 2009/07/01
                                                  i_dt_creation      => NULL,
                                                  i_dt_begin         => NULL,
                                                  i_id_episode_ext   => NULL,
                                                  i_flg_migration    => NULL,
                                                  i_id_room          => NULL,
                                                  i_id_external_sys  => NULL,
                                                  o_episode_new      => l_episode_oris,
                                                  o_schedule         => l_schedule,
                                                  o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_episode_new := l_episode_oris;
        o_schedule    := l_schedule;
    
        --obtem o ID do agendamento do bloco, necessário para indicar a duração e a sala previstas
        g_error := 'GET ID_SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT id_schedule_sr
              INTO l_schedule_sr
              FROM schedule_sr
             WHERE id_episode = l_episode_oris;
        EXCEPTION
            WHEN no_data_found THEN
                l_schedule_sr := NULL;
        END;
    
        --Actualiza a sala prevista
        IF i_room IS NOT NULL
           AND l_schedule_sr IS NOT NULL
        THEN
            g_error := 'CALL TO PK_SR_VISIT.UPD_SURG_PROC_PREVIEW_ROOM';
            pk_alertlog.log_debug(g_error);
            IF NOT upd_surg_proc_preview_room(i_lang        => i_lang,
                                              i_schedule_sr => l_schedule_sr,
                                              i_room        => i_room,
                                              i_prof        => i_prof,
                                              o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        --Actualiza a data prevista
        IF l_schedule_sr IS NOT NULL
        THEN
            g_error := 'CALL TO PK_SR_VISIT.UPD_SURG_PROC_PREVIEW_DT';
            pk_alertlog.log_debug(g_error);
            IF NOT upd_surg_proc_preview_dt(i_lang        => i_lang,
                                            i_schedule_sr => l_schedule_sr,
                                            i_dt          => i_dt_surg,
                                            i_prof        => i_prof,
                                            i_test        => pk_alert_constant.g_yes,
                                            o_flg_show    => l_flg_show,
                                            o_msg_title   => l_msg_title,
                                            o_msg_text    => l_msg_text,
                                            o_button      => l_button,
                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        --Actualiza a duração prevista
        IF i_duration IS NOT NULL
           AND l_schedule_sr IS NOT NULL
        THEN
            g_error := 'CALL TO PK_SR_VISIT.UPD_SURG_PROC_PREVIEW_DT';
            pk_alertlog.log_debug(g_error);
            IF NOT upd_surg_proc_preview_duration(i_lang        => i_lang,
                                                  i_schedule_sr => l_schedule_sr,
                                                  i_duration    => i_duration,
                                                  i_prof        => i_prof,
                                                  o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- This param is not used:
        -- It was supposed to be used in an functionality that was never developed by OUTPATIENT team.
        IF i_type = g_ambulatorio
        THEN
            g_error := 'CREATE OUTPATIENT SCHEDULE';
            NULL;
        END IF;
    
        --Actualiza o episódio relacionado ao episodio do ORIS
        g_error := 'UPDATE EPISODE.ID_PREV_EPISODE';
        pk_alertlog.log_debug(g_error);
        ts_episode.upd(id_prev_episode_in    => i_prev_episode,
                       id_prev_episode_nin   => FALSE,
                       id_prev_epis_type_in  => l_id_prev_epis_type,
                       id_prev_epis_type_nin => FALSE,
                       id_episode_in         => l_episode_oris,
                       rows_out              => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
    
        --Obtem o id_epis_type do episodio que deu origem ao episódio do ORIS
        g_error := 'GET PREV EPISODE EPIS_TYPE';
        pk_alertlog.log_debug(g_error);
        SELECT e.id_epis_type, ei.flg_unknown
          INTO l_epis_type, l_flg_unknown
          FROM episode e, epis_info ei
         WHERE ei.id_episode = e.id_episode
           AND e.id_episode = i_prev_episode;
    
        g_error     := 'CALL GET_EPIS_TYPE_ROOT';
        l_epis_type := get_epis_type_root(i_episode => i_prev_episode);
    
        --Obtém o tipo de episódio para facturação
        l_cod_epis_type_ext := CASE l_epis_type
                                   WHEN 1 THEN
                                    'CON'
                                   WHEN 2 THEN
                                    'URG'
                                   WHEN 5 THEN
                                    'INT'
                                   WHEN 6 THEN
                                    'INT'
                                   WHEN 4 THEN
                                    'INT'
                                   ELSE
                                    'XXX'
                               END;
    
        --Actualiza a tabela de mapeamentos para os sistemas externos
        g_error := 'UPDATE EPIS_EXT_SYS';
        pk_alertlog.log_debug(g_error);
        INSERT INTO epis_ext_sys
            (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            SELECT seq_epis_ext_sys.nextval,
                   id_external_sys,
                   l_episode_oris,
                   VALUE,
                   id_institution,
                   l_oris_epis_type,
                   l_cod_epis_type_ext
              FROM epis_ext_sys
             WHERE id_episode = i_prev_episode
               AND rownum < 2; --apenas para garantir que não insere mais que uma linha 
    
        --if the previous episode is not ORIS, check the visit of previous episode is the same of episode ORIS
        IF l_id_prev_epis_type != pk_alert_constant.g_epis_type_operating
        THEN
            g_error := 'GET ID_VISIT ORIS';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT e.id_visit
                  INTO l_visit_oris
                  FROM episode e
                 WHERE e.id_episode = l_episode_oris;
            EXCEPTION
                WHEN no_data_found THEN
                    l_visit_oris := NULL;
            END;
        
            -- If visit ORIS and visit of the previous episode are the same, then the location of the episode ORIS is the same of previous episode
            IF l_visit_oris = l_visit
            THEN
                g_error := 'GET ROOM OF PREVIOUS EPISODE';
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT ei.id_room
                      INTO l_prev_room
                      FROM epis_info ei
                     WHERE ei.id_episode = i_prev_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_prev_room := pk_sysconfig.get_config('SR_DEFAULT_ROOM',
                                                               i_prof.institution,
                                                               pk_alert_constant.g_soft_oris);
                END;
            
                ts_epis_info.upd(id_episode_in => l_episode_oris, id_room_in => l_prev_room, rows_out => l_rowids);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_INFO',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_ROOM'));
                l_rowids := table_varchar();
            
            END IF;
        END IF;
        --Se o episódio relacionado for de Inpatient, marca o episódio como definitivo
        IF l_cod_epis_type_ext = 'INT'
           AND l_flg_unknown = g_flg_unknown_def
        THEN
            g_error := 'UPDATE EPIS_INFO DEF';
            pk_alertlog.log_debug(g_error);
            /* <DENORM Fábio> */
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in   => l_episode_oris,
                             flg_unknown_in  => g_flg_unknown_def,
                             flg_unknown_nin => FALSE,
                             rows_out        => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rowids, o_error, table_varchar('FLG_UNKNOWN'));
        
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
                                              'CREATE_ALL_SURGERY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_all_surgery;

    /********************************************************************************************
    * Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    * de existir um agendamento, diagnóstico base e intervenção a realizar definidos. 
    * O paciente tem que ser fornecido. 
    *
    * @param i_lang             Id do idioma
    * @param i_id_prof          ID do profissional
    * @param i_id_institution   ID da instituição
    * @param i_id_software      ID do software
    * @param i_patient          ID do paciente
    * 
    * @param o_schedule         ID do agendamento criado
    * @param o_ora_sqlcode      Código do erro oracle
    * @param o_ora_sqlerrm      Descrição do erro oracle
    * @param o_err_desc         Descrição do erro
    * @param o_err_action       Descrição da acção a ser tomada
    *
    * @return                   ID do novo episodio criado; -1 em caso de erro; 
    *
    * @author                   Alexandre Santos
    * @since                    2009/03/23 
    ********************************************************************************************/
    FUNCTION create_all_surgery
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN NUMBER,
        i_id_institution IN NUMBER,
        i_id_software    IN NUMBER,
        i_patient        IN OUT patient.id_patient%TYPE,
        i_id_ext_sys     IN external_sys.id_external_sys%TYPE DEFAULT NULL,
        i_value          IN epis_ext_sys.value%TYPE DEFAULT NULL,
        o_schedule       OUT schedule.id_schedule%TYPE,
        o_ora_sqlcode    OUT VARCHAR2,
        o_ora_sqlerrm    OUT VARCHAR2,
        o_err_desc       OUT VARCHAR2,
        o_err_action     OUT VARCHAR2
    ) RETURN NUMBER IS
    
        l_err       NUMBER := -1;
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        l_episode_oris episode.id_episode%TYPE;
    
        l_schedule_sr              schedule_sr%ROWTYPE;
        l_schedule                 schedule%ROWTYPE;
        l_sr_surg_rec              sr_surgery_record%ROWTYPE;
        l_id_visit                 visit.id_visit%TYPE;
        l_id_schedule_sr           schedule_sr.id_schedule_sr%TYPE;
        l_id_schedule              schedule.id_schedule%TYPE;
        l_pat_dmgr_hist_row        pat_dmgr_hist%ROWTYPE;
        l_create_dmgr_hist_bool    BOOLEAN;
        l_pat_dmgr_hist_seq_number NUMBER;
    
        l_oris_dcs sys_config.value%TYPE;
    
        l_next_epis_ext_sys NUMBER;
        l_epis_type         epis_type.id_epis_type%TYPE;
        l_check_director    sys_config.value%TYPE;
    
    BEGIN
    
        -- José Brito 12/05/2009 Get config according to the current institution and software
        g_error := 'GET CONFIG - SURGERY_DEP_CLIN_SERV';
        pk_alertlog.log_debug(g_error);
        l_oris_dcs := pk_sysconfig.get_config('SURGERY_DEP_CLIN_SERV', i_id_institution, i_id_software);
    
        g_error := 'CALL TO PK_SR_VISIT.CHECK_EXISTS_SOFTWARE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.check_exists_software(i_id_institution, g_sr_software)
        THEN
            --A instituição não tem ORIS instalado, assim, não será criado o episódio
            RAISE l_exception;
        END IF;
    
        g_sysdate_tstz := current_timestamp;
    
        --Verifica se já existe o paciente ao qual se vai criar um novo processo cirúrgico.
        g_error := 'VALIDATE IF PATIENT EXISTS';
        pk_alertlog.log_debug(g_error);
        IF i_patient IS NULL
        THEN
            RAISE l_exception;
        ELSE
            l_episode_oris := ts_episode.next_key();
        END IF;
    
        l_id_visit := NULL;
    
        --Cria visita e episódio temporários
        g_error := 'CREATE TEMP EPISODE AND VISIT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_visit(i_lang             => i_lang,
                                        i_patient          => i_patient,
                                        i_prof             => profissional(i_id_prof, i_id_institution, i_id_software),
                                        i_flg_temp         => g_flg_unknown_temp,
                                        i_id_episode_ext   => NULL,
                                        i_flg_ehr          => g_flg_ehr_n,
                                        i_num_episode_prev => NULL, -- ALERT - 31101
                                        i_cod_module       => NULL, -- ALERT - 31101
                                        i_id_dcs_requested => l_oris_dcs, --NULL, --FSILVA 2009/07/01
                                        i_id_external_sys  => NULL,
                                        i_dt_creation      => NULL,
                                        i_dt_begin         => NULL,
                                        i_flg_migration    => NULL,
                                        io_episode         => l_episode_oris,
                                        io_visit           => l_id_visit,
                                        o_error            => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --Preenche schedule
        g_error := 'CREATE SCHEDULE';
        pk_alertlog.log_debug(g_error);
        l_schedule                     := NULL;
        l_schedule.id_instit_requests  := i_id_institution;
        l_schedule.id_instit_requested := i_id_institution;
        l_schedule.id_dcs_requested    := l_oris_dcs; --Alterar quando o interface enviar o serviço clinico
        l_schedule.id_prof_schedules   := i_id_prof;
        l_schedule.dt_schedule_tstz    := g_sysdate_tstz;
        l_schedule.flg_status          := g_flg_status_active;
        l_schedule.dt_begin_tstz       := g_sysdate_tstz;
        l_schedule.flg_urgency         := g_flg_urg_n;
        l_schedule.id_room             := NULL;
    
        --Cria o registo de agendamento
        g_error := 'INSERT SCHEDULE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_schedule(i_lang     => i_lang,
                                           i_schedule => l_schedule,
                                           i_episode  => l_episode_oris,
                                           o_schedule => l_id_schedule,
                                           o_error    => l_error)
        THEN
            RAISE l_exception;
        END IF;
        o_schedule := l_id_schedule;
    
        --Preenche o registo da schedule_sr
        g_error := 'CREATE SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        l_schedule_sr                    := NULL;
        l_schedule_sr.id_sched_sr_parent := NULL;
        l_schedule_sr.id_schedule        := l_id_schedule;
        l_schedule_sr.id_episode         := l_episode_oris;
        -- A hora prevista é a actual (deve ser um paciente não programado vindo das urgências).
        l_schedule_sr.dt_target_tstz         := g_sysdate_tstz;
        l_schedule_sr.dt_interv_preview_tstz := g_sysdate_tstz;
        --
        l_schedule_sr.id_patient     := i_patient;
        l_schedule_sr.flg_status     := g_flg_status_active;
        l_schedule_sr.flg_sched      := g_schedule_state_not_sched;
        l_schedule_sr.id_prof_reg    := i_id_prof;
        l_schedule_sr.id_institution := i_id_institution;
    
        --Cria o registo de agendamento
        g_error := 'INSERT SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_schedule_sr(i_lang        => i_lang,
                                              i_prof        => profissional(i_id_prof, i_id_institution, i_id_software),
                                              i_schedule_sr => l_schedule_sr,
                                              o_schedule_sr => l_id_schedule_sr,
                                              o_error       => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --Cria registo cirurgico
        g_error := 'CREATE SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        l_sr_surg_rec                    := NULL;
        l_sr_surg_rec.id_schedule_sr     := l_id_schedule_sr;
        l_sr_surg_rec.id_patient         := i_patient;
        l_sr_surg_rec.flg_pat_status     := g_flg_pat_status_pend;
        l_sr_surg_rec.id_sr_intervention := NULL;
    
        l_sr_surg_rec.dt_anest_start_tstz := NULL;
    
        l_sr_surg_rec.dt_anest_end_tstz := NULL;
    
        l_sr_surg_rec.dt_sr_entry_tstz := NULL;
    
        l_sr_surg_rec.dt_sr_exit_tstz := NULL;
    
        l_sr_surg_rec.dt_room_entry_tstz := NULL;
    
        l_sr_surg_rec.dt_room_exit_tstz := NULL;
    
        l_sr_surg_rec.dt_rcv_entry_tstz := NULL;
    
        l_sr_surg_rec.dt_rcv_exit_tstz   := NULL;
        l_sr_surg_rec.id_anesthesia_type := NULL;
        l_sr_surg_rec.flg_state          := g_rec_flg_naoagend;
        l_sr_surg_rec.id_institution     := i_id_institution;
        l_sr_surg_rec.id_episode         := l_episode_oris;
        l_sr_surg_rec.dt_flg_sr_proc     := g_sysdate_tstz;
    
        g_error := 'GET CHECK DIRECTOR';
        pk_alertlog.log_debug(g_error);
        l_check_director := pk_sysconfig.get_config('CHECK_ALERT_DIRECTOR', i_id_institution, i_id_software);
    
        IF l_check_director = pk_alert_constant.g_yes
        THEN
            l_sr_surg_rec.flg_sr_proc := pk_sr_approval.g_inc_request;
        ELSE
            l_sr_surg_rec.flg_sr_proc := pk_sr_approval.g_pending;
        END IF;
    
        --insere o registo
        g_error := 'INSERT SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_surgery_record(i_lang        => i_lang,
                                                 i_sr_surg_rec => l_sr_surg_rec,
                                                 i_prof        => profissional(i_id_prof, i_id_institution, i_id_software),
                                                 o_error       => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        SELECT seq_pat_dmgr_hist.nextval
          INTO l_pat_dmgr_hist_seq_number
          FROM dual;
    
        l_pat_dmgr_hist_row.id_pat_dmgr_hist := l_pat_dmgr_hist_seq_number;
        l_pat_dmgr_hist_row.id_patient       := i_patient;
        l_pat_dmgr_hist_row.id_professional  := i_id_prof;
        l_pat_dmgr_hist_row.id_institution   := i_id_institution;
        l_pat_dmgr_hist_row.name             := pk_message.get_message(i_lang, 'SR_LABEL_T369') || ' ' ||
                                                to_char(l_episode_oris);
        l_pat_dmgr_hist_row.dt_change_tstz   := g_sysdate_tstz;
        l_pat_dmgr_hist_row.nick_name        := pk_message.get_message(i_lang, 'SR_LABEL_T369') || ' ' ||
                                                to_char(l_episode_oris);
    
        -- calling the insertion function to the pat_dmgr_hist table
        l_create_dmgr_hist_bool := pk_dmgr_hist.create_dmgr_hist(l_pat_dmgr_hist_row,
                                                                 i_lang,
                                                                 profissional(i_id_prof, i_id_institution, i_id_software),
                                                                 l_error);
        IF NOT l_create_dmgr_hist_bool
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_id_ext_sys IS NOT NULL
           AND i_value IS NOT NULL
        THEN
            g_error := 'GET SEQ_EPIS_EXT_SYS.nextval';
            pk_alertlog.log_debug(g_error);
        
            SELECT seq_epis_ext_sys.nextval
              INTO l_next_epis_ext_sys
              FROM dual;
        
            l_epis_type := pk_sysconfig.get_config('EPIS_TYPE',
                                                   profissional(i_id_prof, i_id_institution, i_id_software));
        
            g_error := 'INSERT INTO EPIS_EXT_SYS FOR ID_EPIS_EXT_SYS : ' || l_next_epis_ext_sys;
            pk_alertlog.log_debug(g_error);
            INSERT INTO epis_ext_sys
                (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            VALUES
                (l_next_epis_ext_sys, i_id_ext_sys, l_episode_oris, i_value, i_id_institution, l_epis_type, 'INT');
        END IF;
    
        RETURN l_episode_oris;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_ALL_SURGERY',
                                              l_error);
            --Os campos que se seguem são necessários no tratamento de erros por parte do JAVA                              
            o_ora_sqlcode := l_error.ora_sqlcode;
            o_ora_sqlerrm := l_error.ora_sqlerrm;
            o_err_desc    := l_error.err_desc;
            o_err_action  := l_error.err_action;
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN l_err;
    END create_all_surgery;

    /** @headcom
    * Get Advanced Input for cipe interventions.
    *
    * @param      I_LANG            number, default language
    * @param      I_PROF            object type, health profisisonal
    * @param      I_EPIS_INTERV     Intervention ID
    * @param      O_FIELDS          varchar array, intervention notes
    * @param      O_FIELDS_DET      varchar array, intervention notes
    * @param      O_ERROR           erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Tércio Soares
    * @version    0.1
    * @since      2007/06/05
    */
    FUNCTION get_advanced_input
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN schedule_sr.id_episode%TYPE,
        o_fields     OUT pk_types.cursor_type,
        o_fields_det OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_fields FOR
            SELECT ai.id_advanced_input,
                   aif.id_advanced_input_field,
                   aif.intern_name AS name,
                   pk_translation.get_translation(i_lang, aif.code_advanced_input_field) AS label,
                   aif.type,
                   aisi.flg_active,
                   pk_message.get_message(i_lang, aisi.error_message) errormessage,
                   aisi.rank
              FROM advanced_input ai, advanced_input_field aif, advanced_input_soft_inst aisi
             WHERE ai.id_advanced_input = g_advanced_input
               AND aisi.id_advanced_input = ai.id_advanced_input
               AND aif.id_advanced_input_field = aisi.id_advanced_input_field
               AND aisi.id_institution IN (i_prof.institution, 0)
               AND aisi.id_software IN (i_prof.software, 0)
             ORDER BY aisi.rank;
    
        g_error := 'GET CURSOR O_FIELDS_DET';
        pk_alertlog.log_debug(g_error);
        OPEN o_fields_det FOR
            SELECT adv_input.id_advanced_input,
                   adv_input.id_advanced_input_field,
                   adv_input.id_advanced_input_field_det,
                   adv_input.field_name,
                   val.descr                             AS VALUE,
                   adv_input.type,
                   adv_input.alignment,
                   adv_input.separator,
                   adv_input.style,
                   adv_input.max_value                   AS maxvalue,
                   adv_input.min_value                   AS minvalue,
                   adv_input.format,
                   adv_input.units
              FROM (SELECT ai.id_advanced_input,
                           aif.id_advanced_input_field,
                           aidet.id_advanced_input_field_det,
                           aidet.field_name,
                           aif.type,
                           aidet.alignment,
                           aidet.separator,
                           aidet.style,
                           decode(aif.type,
                                  g_date_keypad,
                                  NULL,
                                  g_num_keypad,
                                  /*to_number(*/
                                  aidet.max_value /*)*/) AS max_value,
                           decode(aif.type,
                                  g_date_keypad,
                                  aidet.min_value,
                                  g_num_keypad,
                                  /*SYSDATE,*/
                                  /*to_number(*/
                                  aidet.min_value /*)*/) AS min_value,
                           (SELECT s.desc_message
                              FROM sys_message s
                             WHERE s.code_message = aidet.format_message
                               AND s.id_language = i_lang) AS format,
                           aidet.rank,
                           pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || aidet.id_unit) AS units
                      FROM advanced_input           ai,
                           advanced_input_field     aif,
                           advanced_input_soft_inst aisi,
                           advanced_input_field_det aidet
                     WHERE ai.id_advanced_input = g_advanced_input
                       AND aisi.id_advanced_input = ai.id_advanced_input
                       AND aif.id_advanced_input_field = aisi.id_advanced_input_field
                       AND aisi.id_institution IN (i_prof.institution, g_all_institution)
                       AND aisi.id_software IN (i_prof.software, g_all_software)
                       AND aidet.id_advanced_input_field(+) = aif.id_advanced_input_field) adv_input,
                   TABLE(pk_sr_visit.get_adv_input_field_value(i_lang,
                                                               i_prof,
                                                               --adv_input.id_advanced_input,
                                                               4,
                                                               i_id_episode)) val
             WHERE val.id_advanced_input(+) = adv_input.id_advanced_input
               AND val.id_advanced_input_field(+) = adv_input.id_advanced_input_field
               AND val.id_advanced_input_field_det(+) = adv_input.id_advanced_input_field_det
             ORDER BY adv_input.rank;
    
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
                                              'GET_ADVANCED_INPUT',
                                              o_error);
            pk_types.open_my_cursor(o_fields);
            pk_types.open_my_cursor(o_fields_det);
            RETURN FALSE;
    END get_advanced_input;

    /** @headcom
    * Get field's value for the Advanced Input of cipe interventions.
    *
    * @param      I_LANG            Preferred language ID for this professional
    * @param      I_PROF            Object (professional ID, institution ID, software ID)
    * @param      I_ID_ADVANCED_INPUT    Advanced Input ID
    * @param      I_EPIS_INTERV     Intervention ID
    *
    * @return     type t_coll_srvisit_adv_input 
    * @author     Tércio Soares
    * @version    0.1
    * @since      2007/06/05
    */
    FUNCTION get_adv_input_field_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_id_episode        IN schedule_sr.id_episode%TYPE
    ) RETURN t_coll_srvisit_adv_input
        PIPELINED IS
    
        rec_out t_rec_srvisit_adv_input := t_rec_srvisit_adv_input(NULL, NULL, NULL, NULL);
    
        CURSOR c_fields IS
            SELECT a.id_advanced_input_field, a.id_advanced_input
              FROM advanced_input_soft_inst a
             WHERE a.id_advanced_input = i_id_advanced_input
               AND a.id_institution IN (i_prof.institution, g_all_institution)
               AND a.id_software IN (i_prof.software, g_all_institution);
    
        l_field1 VARCHAR2(1000);
        l_field2 VARCHAR2(1000);
        l_field3 VARCHAR2(1000);
    
    BEGIN
    
        g_error := 'GET VALUES FOR ADVANCED INPUT FIELDS';
        FOR rec IN c_fields
        LOOP
            SELECT pk_date_utils.date_send_tsz(i_lang, sche.dt_interv_preview_tstz, i_prof) dt_interv_preview,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_s,
                   sche.duration
              INTO l_field1, l_field2, l_field3
              FROM schedule_sr sche, room_scheduled rs, room r
             WHERE rs.id_room = r.id_room
               AND sche.id_schedule = rs.id_schedule
               AND sche.id_episode = i_id_episode;
        
            rec_out.id_advanced_input       := i_id_advanced_input;
            rec_out.id_advanced_input_field := rec.id_advanced_input_field;
        
            IF (rec.id_advanced_input_field = 19) -- DT_BEGIN
            THEN
                rec_out.descr := l_field1;
            ELSIF (rec.id_advanced_input_field = 20) -- PREV_ROOM
            THEN
                rec_out.descr := l_field2;
            ELSIF (rec.id_advanced_input_field = 21) -- DURATION
            THEN
                rec_out.descr := l_field3;
            END IF;
        
            PIPE ROW(rec_out);
        END LOOP;
    
        RETURN;
    
    END get_adv_input_field_value;

    /********************************************************************************************
    * Função Interna: Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    *  de existir um agendamento, diagnóstico base e intervenção a realizar definidos (NOVO PROCESSO CIRÚRGICO)
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_visit            ID da visita. Vem preenchido quando o episódio tem origem noutro produto Alert
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * @param i_id_dcs_requested ID da dep_clin_serv
    * @param i_dt_creation      data de criação do episódio (migração de episódios)
    * @param i_dt_begin         Data de início do episódio (migração de episódios)
    * @param i_num_episode_prev ID do episódio associado (migração de episódios)
    * @param i_flg_migration    flag de migração M-migrado A-normal (migração de episódios)
    * @param i_id_room          quarto onde vai ser agendado (migração de episódios)
    *   
    * @param o_episode_new      ID do novo episodio criado
    * @param o_schedule         ID do agendamento criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2007/05/24
    * @altered by               Rita Lopes
    * @                         2008/04/17
    * @Notas                    Parametrizei na sys_config para ir buscar o dep_clin_serv   
    * @altered by               Filipe Silva
    * @                         2009/07/01
    * @Notas                    create episode with the dep_clin_serv (ALERT - 30974)
    * @altered by               Sérgio Dias
    * @date                     2010/08/20
    * @Notas                    create episode by migration (ALERT-118077)
    ********************************************************************************************/
    FUNCTION create_all_surgery_int
    (
        i_lang             IN language.id_language%TYPE,
        i_patient          IN OUT patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_visit            IN visit.id_visit%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_id_dcs_requested IN dep_clin_serv.id_dep_clin_serv%TYPE, --FSILVA 2009/07/01
        i_dt_creation      IN episode.dt_creation%TYPE DEFAULT NULL,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE DEFAULT NULL,
        i_flg_migration    IN episode.flg_migration%TYPE DEFAULT NULL,
        i_id_room          IN room.id_room%TYPE DEFAULT NULL,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_inst_dest        IN NUMBER DEFAULT NULL,
        o_episode_new      OUT episode.id_episode%TYPE,
        o_schedule         OUT schedule.id_schedule%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_schedule_sr    schedule_sr%ROWTYPE;
        l_schedule       schedule%ROWTYPE;
        l_sr_surg_rec    sr_surgery_record%ROWTYPE;
        l_id_episode     episode.id_episode%TYPE;
        l_id_visit       visit.id_visit%TYPE;
        l_id_schedule_sr schedule_sr.id_schedule_sr%TYPE;
        l_id_schedule    schedule.id_schedule%TYPE;
        l_id_patient     patient.id_patient%TYPE;
        --l_error                    VARCHAR2(4000);
        l_pat_dmgr_hist_row        pat_dmgr_hist%ROWTYPE;
        l_create_dmgr_hist_bool    BOOLEAN;
        l_pat_dmgr_hist_seq_number NUMBER;
        /*BEGIN ALERT 31101*/
        l_cod_module epis_ext_sys.cod_epis_type_ext%TYPE;
        /*END ALERT 31101*/
    
        l_rows table_varchar;
    
        l_oris_dcs       sys_config.value%TYPE;
        l_check_director sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- José Brito 12/05/2009 Get config according to the current institution and software
        g_error := 'GET CONFIG - SURGERY_DEP_CLIN_SERV';
        pk_alertlog.log_debug(g_error);
        l_oris_dcs := pk_sysconfig.get_config('SURGERY_DEP_CLIN_SERV', i_prof.institution, i_prof.software);
    
        --Verifica se já existe o paciente ao qual se vai criar um novo processo cirúrgico. Se não
        -- existe é porque se está a criar um paciente temporário através do "+" da grelha.
    
        IF i_patient IS NULL
        THEN
            --Cria um paciente temporário
            g_error := 'CREATE TEMP PATIENT';
            pk_alertlog.log_debug(g_error);
            l_id_episode := ts_episode.next_key();
        
            ts_patient.ins(id_patient_out => l_id_patient,
                           name_in        => pk_message.get_message(i_lang, 'SR_LABEL_T369') || ' ' ||
                                             to_char(l_id_episode),
                           flg_status_in  => g_flg_status_active,
                           gender_in      => g_flg_gender_m,
                           rows_out       => l_rows);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PATIENT',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        ELSE
            l_id_episode := ts_episode.next_key();
        
            l_id_patient := i_patient;
        END IF;
    
        --Se a visita já vem preenchida, usa-a na criação do novo episódio
        l_id_visit := i_visit;
        /*BEGIN ALERT 31101*/
        l_cod_module := NULL;
        /*END ALERT 31101*/
        --Cria visita e episódio temporários
        g_error := 'CREATE TEMP EPISODE AND VISIT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_visit(i_lang           => i_lang,
                                        i_patient        => l_id_patient,
                                        i_prof           => i_prof,
                                        i_flg_temp       => g_flg_unknown_temp,
                                        i_id_episode_ext => i_id_episode_ext,
                                        i_flg_ehr        => i_flg_ehr,
                                        /*BEGIN ALERT 31101*/
                                        i_num_episode_prev => NULL,
                                        i_cod_module       => l_cod_module,
                                        /*END ALERT 31101*/
                                        i_id_dcs_requested => nvl(i_id_dcs_requested, l_oris_dcs), --FSILVA 2009/07/01
                                        i_id_external_sys  => i_id_external_sys,
                                        i_dt_creation      => i_dt_creation,
                                        i_dt_begin         => i_dt_begin,
                                        i_flg_migration    => i_flg_migration,
                                        io_episode         => l_id_episode,
                                        io_visit           => l_id_visit,
                                        o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_episode_new := l_id_episode;
    
        --Preenche schedule
        g_error := 'CREATE SCHEDULE';
        pk_alertlog.log_debug(g_error);
        l_schedule                     := NULL;
        l_schedule.id_instit_requests  := i_prof.institution;
        l_schedule.id_instit_requested := nvl(i_inst_dest, i_prof.institution);
        -- RL - 20080417 - alterei o dep_clin_serv para ir buscar a sys_config
        l_schedule.id_dcs_requested  := nvl(i_id_dcs_requested, l_oris_dcs); --Alterar quando o interface enviar o serviço clinico
        l_schedule.id_prof_schedules := i_prof.id;
        l_schedule.dt_schedule_tstz  := g_sysdate_tstz;
        l_schedule.flg_status        := g_flg_status_active;
        l_schedule.dt_begin_tstz     := g_sysdate_tstz;
        l_schedule.flg_urgency       := g_flg_urg_n;
        l_schedule.id_room           := NULL;
        l_schedule.id_sch_event      := pk_schedule_bo.g_surg_sch_event;
    
        --Cria o registo de agendamento
        g_error := 'INSERT SCHEDULE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_schedule(i_lang     => i_lang,
                                           i_schedule => l_schedule,
                                           i_episode  => l_id_episode,
                                           o_schedule => l_id_schedule,
                                           o_error    => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
        o_schedule := l_id_schedule;
    
        --Preenche o registo da schedule_sr
        g_error := 'CREATE SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        l_schedule_sr                    := NULL;
        l_schedule_sr.id_sched_sr_parent := NULL;
        l_schedule_sr.id_schedule        := l_id_schedule;
        l_schedule_sr.id_episode         := l_id_episode;
    
        --Se o novo processo cirúrgico também cria o paciente, significa que está a ser criado pela grelha de entrada,
        -- pelo que a hora prevista é a actual (deve ser um paciente não programado vindo das urgências).
        IF i_patient IS NULL
        THEN
            l_schedule_sr.dt_target_tstz         := g_sysdate_tstz;
            l_schedule_sr.dt_interv_preview_tstz := g_sysdate_tstz;
        ELSE
            l_schedule_sr.dt_target_tstz         := NULL;
            l_schedule_sr.dt_interv_preview_tstz := NULL;
        END IF;
    
        l_schedule_sr.id_patient     := l_id_patient;
        l_schedule_sr.flg_status     := g_flg_status_active;
        l_schedule_sr.flg_sched      := g_schedule_state_not_sched;
        l_schedule_sr.id_prof_reg    := i_prof.id;
        l_schedule_sr.id_institution := nvl(i_inst_dest, i_prof.institution);
    
        --Cria o registo de agendamento
        g_error := 'INSERT SCHEDULE_SR';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_schedule_sr(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_schedule_sr => l_schedule_sr,
                                              o_schedule_sr => l_id_schedule_sr,
                                              o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --Cria registo cirurgico
        g_error := 'CREATE SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        l_sr_surg_rec                    := NULL;
        l_sr_surg_rec.id_schedule_sr     := nvl(l_id_schedule_sr, NULL);
        l_sr_surg_rec.id_patient         := l_id_patient;
        l_sr_surg_rec.flg_pat_status     := g_flg_pat_status_pend;
        l_sr_surg_rec.id_sr_intervention := NULL;
    
        l_sr_surg_rec.dt_anest_start_tstz := NULL;
    
        l_sr_surg_rec.dt_anest_end_tstz := NULL;
    
        l_sr_surg_rec.dt_sr_entry_tstz := NULL;
    
        l_sr_surg_rec.dt_sr_exit_tstz := NULL;
    
        l_sr_surg_rec.dt_room_entry_tstz := NULL;
    
        l_sr_surg_rec.dt_room_exit_tstz := NULL;
    
        l_sr_surg_rec.dt_rcv_entry_tstz := NULL;
    
        l_sr_surg_rec.dt_rcv_exit_tstz   := NULL;
        l_sr_surg_rec.id_anesthesia_type := NULL;
        l_sr_surg_rec.flg_state          := g_rec_flg_naoagend;
        l_sr_surg_rec.id_institution     := i_prof.institution;
        l_sr_surg_rec.id_episode         := l_id_episode;
    
        g_error := 'GET CHECK DIRECTOR';
        pk_alertlog.log_debug(g_error);
        l_check_director := pk_sysconfig.get_config('CHECK_ALERT_DIRECTOR', i_prof);
    
        IF l_check_director = pk_alert_constant.g_yes
        THEN
            l_sr_surg_rec.flg_sr_proc := pk_sr_approval.g_inc_request;
        ELSE
            l_sr_surg_rec.flg_sr_proc := pk_sr_approval.g_pending;
        END IF;
    
        l_sr_surg_rec.dt_flg_sr_proc := g_sysdate_tstz;
    
        --insere o registo
        g_error := 'INSERT SR_SURGERY_RECORD';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_visit.create_surgery_record(i_lang        => i_lang,
                                                 i_sr_surg_rec => l_sr_surg_rec,
                                                 i_prof        => i_prof,
                                                 o_error       => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        IF i_id_room IS NOT NULL
        THEN
            g_error := 'CALL TO PK_SR_VISIT.CREATE_ALL_SURGERY';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_api_sr_visit.schedule_room(i_lang             => i_lang,
                                                 i_episode          => o_episode_new,
                                                 i_dt_schedule_tstz => current_timestamp,
                                                 i_id_room          => i_id_room,
                                                 i_rec_flg          => pk_api_sr_visit.g_rec_flg_agend,
                                                 i_id_schedule      => l_id_schedule,
                                                 o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF i_patient IS NULL
        THEN
            i_patient := l_id_patient;
        END IF;
    
        SELECT seq_pat_dmgr_hist.nextval
          INTO l_pat_dmgr_hist_seq_number
          FROM dual;
    
        l_pat_dmgr_hist_row.id_pat_dmgr_hist := l_pat_dmgr_hist_seq_number;
        l_pat_dmgr_hist_row.id_patient       := i_patient;
        l_pat_dmgr_hist_row.id_professional  := i_prof.id;
        l_pat_dmgr_hist_row.id_institution   := i_prof.institution;
        l_pat_dmgr_hist_row.name             := pk_message.get_message(i_lang, 'SR_LABEL_T369') || ' ' ||
                                                to_char(l_id_episode);
        l_pat_dmgr_hist_row.dt_change_tstz   := g_sysdate_tstz;
        l_pat_dmgr_hist_row.nick_name        := pk_message.get_message(i_lang, 'SR_LABEL_T369') || ' ' ||
                                                to_char(l_id_episode);
    
        -- calling the insertion function to the pat_dmgr_hist table
        l_create_dmgr_hist_bool := pk_dmgr_hist.create_dmgr_hist(l_pat_dmgr_hist_row, i_lang, i_prof, o_error);
        IF NOT l_create_dmgr_hist_bool
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
                                              'CREATE_ALL_SURGERY_INT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_all_surgery_int;

    /********************************************************************************************
    * Criar registo de episódio de consulta, associado a agendamento. 
    *   Se existem episódios activos p/ esta visita, são fechados!! 
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_visit            ID da visita. Pode não vir preenchido 
    * @param i_flg_temp         Indica se é um episódio temporário
    * @param i_id_episode_ext   ID do episódio externo
    * @param i_date_str         Data (visita)
    * @param io_episode         ID do episódio criado
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * @param i_num_episode_prev id from previous SONHO episode
    * @param i_cod_module       type of module which originated previous episode
    * @param i_id_dcs_requested ID da dep_clin_serv
    * @param i_flg_migration    flag de migração M-migrado A-normal (migração de episódios)
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Teresa Coutinho
    * @since                    2008/04/08
    * @altered by               Filipe Silva
    * @                         2009/07/01
    * @Notas                    create episode with the dep_clin_serv (ALERT - 30974)
    * @altered by               Filipe Silva
    * @date                     2009/07/02
    * @Notas          ALERT - 31101
    * @altered by               Sérgio Dias
    * @date                     2010/08/20
    * @Notas                    create episode by migration (ALERT-118077)
    ********************************************************************************************/
    FUNCTION create_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_visit          IN visit.id_visit%TYPE,
        i_flg_temp       IN epis_info.flg_unknown%TYPE,
        i_id_episode_ext IN VARCHAR2,
        i_dt_creation    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_episode       IN OUT episode.id_episode%TYPE,
        i_flg_ehr        IN episode.flg_ehr%TYPE,
        /*BEGIN ALERT 31101*/
        i_num_episode_prev IN epis_ext_sys.value%TYPE,
        i_cod_module       IN epis_ext_sys.cod_epis_type_ext%TYPE,
        /*END ALERT 31101*/
        i_id_dcs_requested IN dep_clin_serv.id_dep_clin_serv%TYPE, --FSILVA 2009/07/01
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration    IN episode.flg_migration%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit IS
            SELECT v.id_patient, v.flg_status, v.id_institution, i.flg_type
              FROM visit v, institution i
             WHERE id_visit = i_visit
               AND i.id_institution = v.id_institution;
    
        /*BEG FSILVA*/
        CURSOR c_dep_clin_serv IS
            SELECT dcs.id_clinical_service, dcs.id_department, d.id_dept
              FROM dep_clin_serv dcs
              JOIN department d
                ON d.id_department = dcs.id_department
             WHERE dcs.id_dep_clin_serv = i_id_dcs_requested;
        /*END FSILVA*/
    
        l_room_default room.id_room%TYPE;
        --l_error             VARCHAR2(4000);
        l_pat               visit.id_patient%TYPE;
        l_visit_status      visit.flg_status%TYPE;
        l_instit_type       institution.flg_type%TYPE;
        l_instit            visit.id_institution%TYPE;
        l_cod_epis_type_ext epis_ext_sys.cod_epis_type_ext%TYPE;
        l_barcode           VARCHAR2(50);
    
        l_rowids table_varchar;
    
        l_no_triage_color triage_color.id_triage_color%TYPE;
    
        l_sr_epis_type  sys_config.value%TYPE;
        l_epis_flg_type sys_config.value%TYPE;
    
        /*BEGIN FSILVA*/
        l_id_clinical   dep_clin_serv.id_clinical_service%TYPE;
        l_id_department dep_clin_serv.id_department%TYPE;
        l_id_dept       department.id_dept%TYPE;
        /*END FSILVA*/
        l_id_external_sys epis_ext_sys.id_external_sys%TYPE;
    
    BEGIN
    
        g_error := 'GET CONFIG ID_EPIS_TYPE_ORIS';
        pk_alertlog.log_debug(g_error);
        l_sr_epis_type := pk_sysconfig.get_config('ID_EPIS_TYPE_ORIS', i_prof.institution, i_prof.software);
    
        IF i_num_episode_prev IS NOT NULL
           OR i_id_episode_ext IS NOT NULL
           OR i_flg_temp = pk_alert_constant.g_no
        THEN
            l_epis_flg_type := pk_alert_constant.g_epis_type_def;
        ELSE
            l_epis_flg_type := CASE nvl(pk_sysconfig.get_config('ORIS_NEW_EPIS_TEMP_FLG_TYPE',
                                                            i_prof.institution,
                                                            i_prof.software),
                                    pk_alert_constant.g_yes)
                                   WHEN pk_alert_constant.g_yes THEN
                                    pk_alert_constant.g_epis_type_tmp
                                   WHEN pk_alert_constant.g_no THEN
                                    pk_alert_constant.g_epis_type_def
                                   ELSE
                                    pk_alert_constant.g_epis_type_tmp
                               END;
        END IF;
    
        IF i_dt_creation IS NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        END IF;
    
        g_error        := 'GET DEFAULT ROOM';
        l_room_default := pk_sysconfig.get_config('SR_DEFAULT_ROOM', i_prof);
    
        g_error := 'GET CURSOR C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_pat, l_visit_status, l_instit, l_instit_type;
        CLOSE c_visit;
    
        IF l_visit_status = g_visit_inactive
        THEN
            g_error := pk_message.get_message(i_lang, 'VISIT_M003');
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        /*BEGIN FSILVA*/
        IF i_id_dcs_requested IS NULL
        THEN
            l_id_dept       := -1;
            l_id_clinical   := -1;
            l_id_department := -1;
        ELSE
            g_error := 'GET CURSOR C_DEP_CLIN_SERV';
            pk_alertlog.log_debug(g_error);
            OPEN c_dep_clin_serv;
            FETCH c_dep_clin_serv
                INTO l_id_clinical, l_id_department, l_id_dept;
            CLOSE c_dep_clin_serv;
        END IF;
        /*END FSILVA*/
    
        --Gera o código de barras
        g_error := 'GENERATE BARCODE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => 'P',
                                           i_institution  => i_prof.institution,
                                           i_software     => i_prof.software,
                                           o_barcode      => l_barcode,
                                           o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --obtem próximo ID se não vier já definido como parâmetro de entrada
        IF io_episode IS NULL
        THEN
            g_error := 'GET CURSOR C_EPIS_SEQ';
            pk_alertlog.log_debug(g_error);
            io_episode := ts_episode.next_key;
        END IF;
    
        --Cria o novo episódio
        g_error := 'CREATE TEMP EPISODE FOR VISIT: ' || i_visit;
        pk_alertlog.log_debug(g_error);
        ts_episode.ins(id_episode_in              => io_episode,
                       id_visit_in                => i_visit,
                       id_patient_in              => l_pat,
                       id_clinical_service_in     => -1,
                       id_department_in           => -1,
                       id_dept_in                 => -1,
                       dt_begin_tstz_in           => nvl(i_dt_begin, g_sysdate_tstz),
                       dt_end_tstz_in             => NULL,
                       flg_migration_in           => nvl(i_flg_migration, pk_episode.g_flg_type_a), -- se a flag não vier preenchida é um episodio normal do tipo 'A'
                       id_epis_type_in            => l_sr_epis_type,
                       flg_status_in              => g_flg_status_active,
                       barcode_in                 => l_barcode,
                       flg_ehr_in                 => nvl(i_flg_ehr, g_flg_ehr_s),
                       dt_creation_in             => nvl(i_dt_creation, g_sysdate_tstz),
                       id_institution_in          => l_instit,
                       id_cs_requested_in         => l_id_clinical, -- FSILVA 2009/07/01
                       id_department_requested_in => l_id_department, --FSILVA 2009/07/01
                       id_dept_requested_in       => l_id_dept, --FSILVA 2009/07/01
                       flg_type_in                => l_epis_flg_type,
                       rows_out                   => l_rowids);
    
        g_error := 'PROCESS INSERT';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- ALERT-41412: AS (03-06-2011)
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_patient     => l_pat,
                                                      i_new_episode => io_episode,
                                                      o_error       => o_error)
        THEN
            g_error := 'ERROR PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN - ID_EPISODE: ' || io_episode || '; LOG_ID: ' ||
                       o_error.log_id;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => 'CREATE_EPISODE');
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
        -- END ALERT-41412
    
        l_rowids := table_varchar();
    
        g_error := 'CREATE EPIS_INSTITUTION';
        pk_alertlog.log_debug(g_error);
        INSERT INTO epis_institution
            (id_epis_institution, id_institution, id_episode)
        VALUES
            (seq_epis_institution.nextval, i_prof.institution, io_episode);
    
        -- José Brito 04/11/2008 Preencher EPIS_INFO.ID_TRIAGE_COLOR com a côr genérica do 
        -- tipo de triagem usado na instituição actual
        g_error := 'GET NO TRIAGE COLOR';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT tco.id_triage_color
              INTO l_no_triage_color
              FROM triage_color tco, triage_type tt
             WHERE tco.id_triage_type = tt.id_triage_type
               AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_prof, io_episode)
               AND tco.flg_type = 'S'
               AND rownum < 2;
        EXCEPTION
            WHEN OTHERS THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CREATE_EPISODE',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
        END;
    
        g_error := 'CREATE EPIS_INFO';
        ts_epis_info.ins(id_episode_in             => io_episode,
                         id_room_in                => l_room_default,
                         flg_unknown_in            => CASE
                                                          WHEN l_epis_flg_type = pk_episode.g_flg_def THEN
                                                           pk_alert_constant.g_no
                                                          ELSE
                                                           pk_alert_constant.g_yes
                                                      END,
                         id_patient_in             => l_pat,
                         id_schedule_in            => -1,
                         id_software_in            => g_sr_software,
                         triage_acuity_in          => pk_alert_constant.g_color_gray,
                         triage_color_text_in      => pk_alert_constant.g_color_white,
                         triage_rank_acuity_in     => pk_alert_constant.g_rank_acuity,
                         id_triage_color_in        => l_no_triage_color,
                         id_dep_clin_serv_in       => i_id_dcs_requested,
                         id_first_dep_clin_serv_in => i_id_dcs_requested,
                         rows_out                  => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_id_episode_ext IS NOT NULL
        THEN
            /*BEGIN ALERT 31101*/
            IF i_num_episode_prev IS NULL
            THEN
                l_cod_epis_type_ext := 'INT';
            ELSE
                l_cod_epis_type_ext := i_cod_module;
            END IF;
            /*END ALERT 31101*/
        
            IF i_id_external_sys IS NULL
            THEN
                l_id_external_sys := 1; --> if interface send the id_external_sys null then is used the id_external_sys = 1 (sonho)
            ELSE
                l_id_external_sys := i_id_external_sys;
            END IF;
        
            g_error := 'CREATE EPIS_EXT_SYS';
            pk_alertlog.log_debug(g_error);
            INSERT INTO epis_ext_sys
                (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            VALUES
                (seq_epis_ext_sys.nextval,
                 l_id_external_sys,
                 io_episode,
                 i_id_episode_ext,
                 i_prof.institution,
                 l_sr_epis_type,
                 l_cod_epis_type_ext);
        END IF;
    
        --ALERT-70086, ASantos 27-01-2009
        g_error := 'call pk_diagnosis.set_visit_diagnosis for id_episode: ' || io_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_diagnosis_core.set_visit_diagnosis(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => io_episode,
                                                     i_tbl_epis_diagnosis => NULL,
                                                     o_error              => o_error)
        THEN
            g_error := 'SET_VISIT_DIAGNOSIS ERROR - ID_EPISODE: ' || io_episode || '; LOG_ID: ' || o_error.log_id;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => 'CREATE_EPISODE');
            pk_utils.undo_changes;
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
                                              'CREATE_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_episode;

    /********************************************************************************************
    * Verifica se a instituição tem o produto i_prof.software instalado 
    *
    * @param i_institution      ID da instituição
    * @param i_software         ID do software
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2008/05/27
    ********************************************************************************************/
    FUNCTION check_exists_software
    (
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN BOOLEAN IS
    
        l_exists PLS_INTEGER;
    
    BEGIN
        --Verifica se a instituição tem o produto instalado
        SELECT COUNT(1)
          INTO l_exists
          FROM software_institution
         WHERE id_institution = i_institution
           AND id_software = i_software;
    
        IF l_exists < 1
        THEN
            --A instituição não tem o produto instalado.
            RETURN FALSE;
        ELSE
            --A instituição tem o produto instalado.
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END check_exists_software;

    /**************************************************************************
    * Check icon status for the surgical procedure                            *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns string with icon format         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/16                              *
    **************************************************************************/
    FUNCTION check_icon_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_prof_cat category.flg_type%TYPE;
        l_ret      VARCHAR2(200);
    
    BEGIN
    
        SELECT c.flg_type
          INTO l_prof_cat
          FROM category c, prof_cat pc
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND c.id_category = pc.id_category;
    
        IF l_prof_cat != pk_alert_constant.g_cat_type_doc
        THEN
            BEGIN
                SELECT pk_utils.get_status_string_immediate(i_lang,
                                                            i_prof,
                                                            st.display_type,
                                                            st.flg_state,
                                                            st.value_text,
                                                            st.value_date,
                                                            st.value_icon,
                                                            st.shortcut,
                                                            st.back_color,
                                                            st.icon_color,
                                                            st.message_style,
                                                            st.message_color,
                                                            st.flg_text_domain,
                                                            st.dt_server)
                  INTO l_ret
                  FROM (SELECT CASE
                                    WHEN (ssr.flg_sr_proc IN
                                         (pk_sr_approval.g_pending_send_request, pk_sr_approval.g_rejected_approval)) THEN
                                     pk_alert_constant.g_display_type_date_icon
                                    ELSE
                                     pk_alert_constant.g_display_type_icon
                                
                                END display_type,
                               ssr.flg_sr_proc flg_state,
                               NULL value_text,
                               CASE
                                    WHEN (ssr.flg_sr_proc IN
                                         (pk_sr_approval.g_pending_send_request, pk_sr_approval.g_rejected_approval)) THEN
                                     pk_date_utils.to_char_insttimezone(i_prof,
                                                                        ssr.dt_flg_sr_proc,
                                                                        pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)
                                    ELSE
                                     NULL
                                END value_date,
                               'SR_SURGERY_RECORD.FLG_SR_PROC' value_icon,
                               NULL shortcut,
                               CASE
                                    WHEN (ssr.flg_sr_proc = pk_sr_approval.g_pending) THEN
                                     pk_alert_constant.g_color_red
                                    ELSE
                                     pk_alert_constant.g_color_null
                                END back_color,
                               CASE
                                    WHEN (ssr.flg_sr_proc = pk_sr_approval.g_pending) THEN
                                     pk_alert_constant.g_color_icon_light_grey
                                    ELSE
                                     pk_alert_constant.g_color_icon_dark_grey
                                END icon_color,
                               NULL message_style,
                               NULL message_color,
                               NULL flg_text_domain,
                               current_timestamp dt_server
                          FROM sr_surgery_record ssr
                         WHERE ssr.id_episode = i_episode) st;
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := NULL;
            END;
        ELSE
            BEGIN
                SELECT pk_utils.get_status_string_immediate(i_lang,
                                                            i_prof,
                                                            st.display_type,
                                                            st.flg_state,
                                                            st.value_text,
                                                            st.value_date,
                                                            st.value_icon,
                                                            st.shortcut,
                                                            st.back_color,
                                                            st.icon_color,
                                                            st.message_style,
                                                            st.message_color,
                                                            st.flg_text_domain,
                                                            st.dt_server)
                  INTO l_ret
                  FROM (SELECT CASE
                                    WHEN (ssr.flg_sr_proc IN
                                         (pk_sr_approval.g_pending_send_request, pk_sr_approval.g_rejected_approval)) THEN
                                     pk_alert_constant.g_display_type_date_icon
                                    ELSE
                                     pk_alert_constant.g_display_type_icon
                                END display_type,
                               ssr.flg_sr_proc flg_state,
                               NULL value_text,
                               CASE
                                    WHEN (ssr.flg_sr_proc IN
                                         (pk_sr_approval.g_pending_send_request, pk_sr_approval.g_rejected_approval)) THEN
                                     pk_date_utils.to_char_insttimezone(i_prof,
                                                                        ssr.dt_flg_sr_proc,
                                                                        pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)
                                
                                    ELSE
                                     NULL
                                END value_date,
                               'SR_SURGERY_RECORD.FLG_SR_PROC' value_icon,
                               NULL shortcut,
                               CASE
                                    WHEN (ssr.flg_sr_proc IN (pk_sr_approval.g_pending_send_request,
                                                              pk_sr_approval.g_rejected_approval,
                                                              pk_sr_approval.g_inc_request,
                                                              pk_sr_approval.g_pending)) THEN
                                     pk_alert_constant.g_color_red
                                    ELSE
                                     pk_alert_constant.g_color_null
                                END back_color,
                               CASE
                                    WHEN (ssr.flg_sr_proc IN (pk_sr_approval.g_pending_send_request,
                                                              pk_sr_approval.g_rejected_approval,
                                                              pk_sr_approval.g_inc_request,
                                                              pk_sr_approval.g_pending)) THEN
                                     pk_alert_constant.g_color_icon_light_grey
                                    ELSE
                                     pk_alert_constant.g_color_icon_medium_grey
                                END icon_color,
                               NULL message_style,
                               NULL message_color,
                               NULL flg_text_domain,
                               current_timestamp dt_server
                          FROM sr_surgery_record ssr
                         WHERE ssr.id_episode = i_episode) st;
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := NULL;
            END;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END check_icon_status;

    /********************************************************************************************
    * Sets an episode as admitted.
    *
    * @param      i_lang                  language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_epis                  I_EPIS   Id of the episode to    
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009/10/23
    **********************************************************************************************/
    FUNCTION set_epis_admission
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows     table_varchar;
        l_dt_begin sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE;
    
        internal_error_exception EXCEPTION;
    
        CURSOR c_eb_dt_surg_time IS
            SELECT sstd.dt_surgery_time_det_tstz
              FROM sr_surgery_time_det sstd
             WHERE sstd.id_episode = i_epis
               AND sstd.flg_status = g_sstd_flg_status_active
               AND sstd.id_sr_surgery_time = get_sr_surgery_time(i_lang, i_prof, sstd.id_episode);
    
    BEGIN
    
        g_error := 'OPEN c_eb_dt_surg_time';
        pk_alertlog.log_debug(g_error);
        OPEN c_eb_dt_surg_time;
        FETCH c_eb_dt_surg_time
            INTO l_dt_begin;
    
        IF c_eb_dt_surg_time%NOTFOUND
        THEN
            l_dt_begin := current_timestamp;
        END IF;
    
        CLOSE c_eb_dt_surg_time;
    
        g_error := 'UPDATE EPISODE EHR';
        pk_alertlog.log_debug(g_error, g_package_name);
        ts_episode.upd(flg_ehr_in        => pk_alert_constant.g_epis_ehr_normal,
                       flg_ehr_nin       => FALSE,
                       dt_begin_tstz_in  => l_dt_begin,
                       dt_begin_tstz_nin => FALSE,
                       where_in          => 'id_episode = ' || i_epis || ' ',
                       rows_out          => l_rows);
    
        g_error := 'PROCESS ROWS';
        pk_alertlog.log_debug(g_error, g_package_name);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_EHR', 'DT_BEGIN_TSTZ'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_ADMISSION',
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
                                              'SET_EPIS_ADMISSION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_admission;

    /********************************************************************************************
    * Cancels the admission of an episode and restores its previous dt_begin.
    *
    * @param      i_lang                  language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_epis                  I_EPIS   Id of the episode to
    * @param      o_id_wl_screens         List of IDs of WL_MACHINEs that will issue the provided machine's calls
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009/10/23
    **********************************************************************************************/
    FUNCTION cancel_epis_admission
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows            table_varchar;
        l_dt_creation_str VARCHAR2(200);
        l_dt_creation     episode.dt_begin_tstz%TYPE;
    
    BEGIN
        g_error := 'GET EPIS CREATION DATE';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_episode.get_epis_dt_creation(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_epis,
                                               o_dt_creation => l_dt_creation_str,
                                               o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'Convert VARCHAR2 dt_creation_str to TIMESTAMP WITH LOCAL TIME ZONE l_dt_creation';
        pk_alertlog.log_debug(g_error);
        l_dt_creation := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_creation_str, NULL);
    
        g_error := 'UPDATE EPISODE EHR';
        pk_alertlog.log_debug(g_error, g_package_name);
        ts_episode.upd(dt_begin_tstz_in  => l_dt_creation,
                       dt_begin_tstz_nin => FALSE,
                       flg_ehr_in        => pk_alert_constant.g_epis_ehr_schedule,
                       flg_ehr_nin       => FALSE,
                       where_in          => 'id_episode = ' || i_epis || ' ',
                       rows_out          => l_rows);
    
        g_error := 'PROCESS ROWS';
        pk_alertlog.log_debug(g_error, g_package_name);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_EHR', 'DT_BEGIN_TSTZ'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_ADMISSION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_epis_admission;

    FUNCTION get_sr_surgery_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN sr_surgery_time.id_sr_surgery_time%TYPE IS
    
        l_id_software        software.id_software%TYPE;
        l_id_sr_surgery_time sr_surgery_time.id_sr_surgery_time%TYPE;
        l_error              t_error_out;
    
        internal_error_exception EXCEPTION;
    
        CURSOR c_eb_data(l_soft software.id_software%TYPE) IS
            SELECT id_sr_surgery_time
              FROM (SELECT sst.id_sr_surgery_time,
                           rank() over(ORDER BY sst.id_institution DESC, sst.id_software DESC) rank
                      FROM sr_surgery_time sst
                     WHERE sst.flg_type = g_sst_flg_type_eb
                       AND sst.flg_available = pk_alert_constant.g_available
                       AND sst.id_institution IN (0, i_prof.institution)
                       AND sst.id_software IN (0, l_soft))
             WHERE rank = 1;
    
    BEGIN
    
        g_error := 'Fetch episode softare -> ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_epis,
                                               o_id_software => l_id_software,
                                               o_error       => l_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        g_error := 'OPEN c_eb_data for software -> ' || l_id_software;
        pk_alertlog.log_debug(g_error);
        OPEN c_eb_data(l_id_software);
        FETCH c_eb_data
            INTO l_id_sr_surgery_time;
    
        IF c_eb_data%NOTFOUND
        THEN
            l_id_sr_surgery_time := NULL;
        END IF;
    
        CLOSE c_eb_data;
    
        RETURN l_id_sr_surgery_time;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_SURGERY_TIME',
                                              l_error);
            RAISE internal_error_exception;
    END get_sr_surgery_time;

    /********************************************************************************************
    * create record in sr_pat_status table
    *
    * @param      i_lang                  language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_episode               id_episode
    * @param      O_ERROR                 an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Silva
    * @version 2.5.0.7.7
    * @since   2010/02/22
    **********************************************************************************************/
    FUNCTION create_sr_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_pat_status IN sr_pat_status.flg_pat_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function VARCHAR2(30 CHAR) := 'CREATE_SR_PAT_STATUS';
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INSERT INTO SR_PAT_STATUS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_function);
        INSERT INTO sr_pat_status
            (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
        VALUES
            (seq_sr_pat_status.nextval, i_episode, i_prof.id, i_flg_pat_status, g_sysdate_tstz);
    
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
                                              l_function,
                                              o_error);
            RETURN FALSE;
    END create_sr_pat_status;

    /**********************************************************************************************
    * Checks if a given episode has already been registered
    *
    * @param i_lang                ID language   
    * @param i_episode             ID of episode      
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.5.0.7.8
    * @since                       2010/03/24
    **********************************************************************************************/
    FUNCTION is_epis_registered
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_is_registered VARCHAR2(1 CHAR);
        l_error         t_error_out;
    
    BEGIN
    
        BEGIN
            g_error := 'IS_EPIS_REGISTERED';
            pk_alertlog.log_debug(g_error);
            SELECT pk_alert_constant.g_yes
              INTO l_is_registered
              FROM episode epis
             WHERE epis.id_episode = i_id_episode
               AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n;
        EXCEPTION
            WHEN no_data_found THEN
                l_is_registered := pk_alert_constant.g_no;
        END;
    
        RETURN l_is_registered;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'IS_EPIS_REGISTERED',
                                              o_error    => l_error);
            RETURN NULL;
    END is_epis_registered;

    /********************************************************************************************
    * Get patient interventions
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional, institution and software IDs
    * @param i_id_patient              Patient ID
    * @param i_flg_status   Surgery status flag. Values : 'S' - Scheduled
    *                                                     'A' - All surgeries
    *
    * @param o_episodes            Episodes information cursor
    * @param o_error               Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/09/15
    * @Notes                    ALERT-ALERT-124895
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_status IN VARCHAR2,
        o_episodes   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'i_lang: ' || i_lang || ' i_prof.institution:' || i_prof.institution || ' i_prof.software:' ||
                   i_prof.software || ' i_prof.id:' || i_prof.id || ' i_id_patient:' || i_id_patient ||
                   ' i_flg_status:' || i_flg_status;
    
        g_error := 'OPEN O_EPISODES';
        OPEN o_episodes FOR
            SELECT ss.id_episode,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ss.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   ss.dt_target_tstz target_date,
                   ss.duration intervention_duration
              FROM schedule_sr ss
             INNER JOIN patient p
                ON ss.id_patient = p.id_patient
             WHERE ss.id_patient = i_id_patient
               AND ((i_flg_status = pk_alert_constant.g_schedule_sr_status_s AND ss.dt_target_tstz IS NOT NULL) OR
                   (i_flg_status = pk_alert_constant.g_schedule_sr_status_a));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_INTERVENTIONS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_surg_episodes;

    /********************************************************************************************
    * Actualiza a data prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_schedule_sr      ID do agendamento
    * @param i_dt               Data prevista da realização da cirurgia
    * @param i_test             Test if there is already one cirurgic episode for selected day ('Y'-yes; 'N'-no)
    * @param i_duration         New duration in minutes
    * @param i_room             New cirurgic room
    * 
    * @param o_flg_show         Indica de deve ou não ser mostrada uma mensagem de aviso
    * @param o_msg_title        Título da mensagem
    * @param o_msg_text         Descrição da mensagem
    * @param o_button           Botões a disponibilizar
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Luís Maia
    * @since                    2011/Jun/01
    ********************************************************************************************/
    FUNCTION set_surg_proc_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_schedule_sr IN schedule_sr.id_schedule_sr%TYPE,
        i_dt          IN VARCHAR2,
        i_test        IN VARCHAR2,
        i_duration    IN schedule_sr.duration%TYPE,
        i_room        IN room.id_room%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_dt IS NOT NULL
        THEN
            g_error := 'CALL UPD_SURG_PROC_PREVIEW_DT';
            pk_alertlog.log_debug(g_error);
            IF NOT upd_surg_proc_preview_dt(i_lang        => i_lang,
                                            i_schedule_sr => i_schedule_sr,
                                            i_dt          => i_dt,
                                            i_prof        => i_prof,
                                            i_test        => i_test,
                                            o_flg_show    => o_flg_show,
                                            o_msg_title   => o_msg_title,
                                            o_msg_text    => o_msg_text,
                                            o_button      => o_button,
                                            o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF i_duration IS NOT NULL
        THEN
            g_error := 'CALL UPD_SURG_PROC_PREVIEW_DURATION';
            pk_alertlog.log_debug(g_error);
            IF NOT upd_surg_proc_preview_duration(i_lang        => i_lang,
                                                  i_schedule_sr => i_schedule_sr,
                                                  i_duration    => i_duration,
                                                  i_prof        => i_prof,
                                                  o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF i_room IS NOT NULL
        THEN
            g_error := 'CALL UPD_SURG_PROC_PREVIEW_DURATION';
            pk_alertlog.log_debug(g_error);
            IF NOT upd_surg_proc_preview_room(i_lang        => i_lang,
                                              i_schedule_sr => i_schedule_sr,
                                              i_room        => i_room,
                                              i_prof        => i_prof,
                                              o_error       => o_error)
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
                                              'SET_SURG_PROC_DATA',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_surg_proc_data;

    /********************************************************************************************
    * Match surgery episode status (update old one or delete the oldest)
    *
    * @param      I_LANG                  Language ID for translations
    * @param      I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param      I_ID_EPISODE_OLD        Old episode identifier to be updated/deleted
    * @param      I_ID_EPISODE_NEW        New episode identifier
    * @param      O_ERROR                 If an error accurs, this parameter will have information about the error    
    *
    * @RETURN                             false if errors occur, true otherwise
    *
    * @author                             antonio.neto
    * @version                            2.5.1.2.11
    * @since                              16-Dec-2011
    **********************************************************************************************/
    FUNCTION set_match_epis_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode_old IN episode.id_episode%TYPE,
        i_id_episode_new IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sr_pat_status IS
            SELECT srps.flg_pat_status,
                   MIN(srps.id_sr_pat_status) min_id_sr_pat_status,
                   MAX(srps.id_sr_pat_status) max_id_sr_pat_status,
                   MAX(srps.id_episode) max_id_episode
              FROM sr_pat_status srps
             WHERE srps.id_episode IN (i_id_episode_old, i_id_episode_new)
             GROUP BY srps.flg_pat_status;
    
        l_flg_pat_status       sr_pat_status.flg_pat_status%TYPE;
        l_min_id_sr_pat_status sr_pat_status.id_sr_pat_status%TYPE;
        l_max_id_sr_pat_status sr_pat_status.id_sr_pat_status%TYPE;
        l_id_episode           sr_pat_status.id_episode%TYPE;
    
    BEGIN
    
        g_error := 'GET O_ID_DISCH';
        OPEN c_sr_pat_status;
        LOOP
            FETCH c_sr_pat_status
                INTO l_flg_pat_status, l_min_id_sr_pat_status, l_max_id_sr_pat_status, l_id_episode;
            EXIT WHEN c_sr_pat_status%NOTFOUND;
        
            IF l_min_id_sr_pat_status <> l_max_id_sr_pat_status
            THEN
                --delete the oldest for the episode/status
                g_error := 'DELETE sr_pat_status';
                DELETE FROM sr_pat_status srps
                 WHERE srps.flg_pat_status = l_flg_pat_status
                   AND srps.id_episode = i_id_episode_old;
            ELSIF l_id_episode = i_id_episode_old
            THEN
                --update the old episode/status to the new episode identifier
                g_error := 'UPDATE sr_pat_status';
                UPDATE sr_pat_status srps
                   SET srps.id_episode = i_id_episode_new
                 WHERE srps.flg_pat_status = l_flg_pat_status
                   AND srps.id_episode = i_id_episode_old;
            END IF;
        
        END LOOP;
        CLOSE c_sr_pat_status;
    
        --update the old episode/status Notes to the new episode identifier
        g_error := 'UPDATE SR_PAT_STATUS_NOTES';
        UPDATE sr_pat_status_notes
           SET id_episode = i_id_episode_new
         WHERE id_episode = i_id_episode_old;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'MATCH_SR_EPIS_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_match_epis_status;

    PROCEDURE get_dates
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_dt_start   OUT VARCHAR2,
        o_dt_end     OUT VARCHAR2
        
    ) IS
    
        l_dt_start_sur VARCHAR2(200 CHAR);
        l_dt_end_sur   VARCHAR2(200 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT t.dt_start -- surgery start date/time
              INTO l_dt_start_sur
              FROM (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                       sstd.dt_surgery_time_det_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_start
                      FROM sr_surgery_time_det sstd
                      JOIN sr_surgery_time sst
                        ON sst.id_sr_surgery_time = sstd.id_sr_surgery_time
                     WHERE sstd.id_episode = i_id_episode
                       AND sst.flg_type = 'IC'
                       AND sstd.flg_status = 'A') t;
        EXCEPTION
            WHEN OTHERS THEN
                l_dt_start_sur := NULL;
        END;
    
        BEGIN
            SELECT t.dt_end -- surgery end date/time
              INTO l_dt_end_sur
              FROM (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                       sstd.dt_surgery_time_det_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_end
                      FROM sr_surgery_time_det sstd
                      JOIN sr_surgery_time sst
                        ON sst.id_sr_surgery_time = sstd.id_sr_surgery_time
                     WHERE sstd.id_episode = i_id_episode
                       AND sst.flg_type = 'FC'
                       AND sstd.flg_status = 'A') t;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_end_sur := NULL;
        END;
    
        o_dt_start := l_dt_start_sur;
        o_dt_end   := l_dt_end_sur;
    END get_dates;

    FUNCTION get_room
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_room VARCHAR2(200 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, r.code_room)
              INTO l_room
              FROM epis_info e
              LEFT JOIN room r
                ON r.id_room = e.id_room
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                l_room := NULL;
        END;
    
        RETURN l_room;
    
    END get_room;

    FUNCTION get_nurse
    (
        i_lang        IN language.id_language%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_tl_task  IN tl_task.id_tl_task%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2 IS
    
        l_nurse VARCHAR2(200 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT nurse_name
              INTO l_nurse
              FROM (SELECT p.name nurse_name
                      FROM task_timeline_ea t
                      JOIN professional p
                        ON p.id_professional = t.id_prof_req
                     WHERE t.id_episode = i_id_episode
                       AND t.id_tl_task = i_id_tl_task
                       AND t.id_doc_area = i_id_doc_area
                     ORDER BY t.dt_req DESC) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN OTHERS THEN
                l_nurse := NULL;
        END;
    
        RETURN l_nurse;
    
    END get_nurse;

    FUNCTION get_team
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_team VARCHAR2(200 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT team_name
              INTO l_team
              FROM (SELECT pk_sr_tools.get_sr_interv_team(i_lang, i_prof, sei.id_episode_context, sei.id_sr_epis_interv) team_name
                      FROM sr_epis_interv sei
                     WHERE sei.id_episode_context = i_id_episode
                       AND sei.flg_status != 'C'
                       AND sei.flg_type = 'P');
        EXCEPTION
            WHEN OTHERS THEN
                l_team := NULL;
        END;
    
        RETURN l_team;
    
    END get_team;

    FUNCTION get_category
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_category          VARCHAR2(1000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                          i_code_mess => 'VISIT_INFO_T017');
        l_id_prev_epis_type NUMBER;
        l_id_waiting_list   NUMBER;
    
    BEGIN
        -- see if it's emergent
        BEGIN
            SELECT s.id_waiting_list
              INTO l_id_waiting_list
              FROM schedule_sr s
             WHERE s.id_episode = i_id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_waiting_list := NULL;
        END;
    
        -- efective or daycase
        IF l_id_waiting_list IS NULL
        THEN
            l_category := l_category || pk_prog_notes_constants.g_colon ||
                          pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T017.1');
        ELSE
            BEGIN
                SELECT e.id_prev_epis_type
                  INTO l_id_prev_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_prev_epis_type := NULL;
            END;
        
            CASE l_id_prev_epis_type
                WHEN 4 THEN
                    l_category := l_category || pk_prog_notes_constants.g_colon ||
                                  pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T017.3');
                WHEN 5 THEN
                    l_category := l_category || pk_prog_notes_constants.g_colon ||
                                  pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T017.2');
                ELSE
                    l_category := l_category || pk_prog_notes_constants.g_colon ||
                                  pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T017.3');
            END CASE;
        
        END IF;
    
        RETURN l_category;
    
    END get_category;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_episode   episode identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          2012/09/05 
    */
    FUNCTION get_desc_surg_proc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_desc_type      IN VARCHAR2,
        i_desc_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB IS
    
        l_exception             EXCEPTION;
        l_ret                   CLOB;
        l_temp_desc             CLOB;
        l_dt_surgery            VARCHAR2(200 CHAR);
        l_diagnosis             VARCHAR2(2000 CHAR);
        l_long                  table_varchar;
        l_id_epis_diagnosis_tbl table_number;
        l_id_epis_diagnosis     sr_epis_interv.id_epis_diagnosis%TYPE;
    
        l_tbl_desc_condition table_varchar;
        l_rec_diag           pk_edis_types.rec_epis_diagnosis;
        l_flg                BOOLEAN;
    
        l_dt_start_sur VARCHAR2(200 CHAR);
        l_dt_end_sur   VARCHAR2(200 CHAR);
        l_room         VARCHAR2(200 CHAR);
        l_nurse        VARCHAR2(200 CHAR);
        l_team         VARCHAR2(200 CHAR);
        l_category     VARCHAR2(200 CHAR);
    
    BEGIN
    
        g_error := 'GET l_dt_surgery';
        BEGIN
            SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                            nvl(ss.dt_target_tstz, e.dt_begin_tstz),
                                            i_prof.institution,
                                            i_prof.software),
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_desc_epis_diagnosis => pk_translation.get_translation(i_lang,
                                                                                                      d.code_diagnosis),
                                              i_flg_std_diag        => pk_alert_constant.g_yes)
              INTO l_dt_surgery, l_diagnosis
              FROM episode e
              LEFT JOIN schedule_sr ss
                ON ss.id_episode = e.id_episode
              LEFT JOIN diagnosis d
                ON d.id_diagnosis = ss.id_diagnosis
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                l_dt_surgery := NULL;
        END;
    
        IF i_desc_type = pk_prog_notes_constants.g_desc_type_s
        THEN
            g_error := 'GET short';
            SELECT desc_interv
              BULK COLLECT
              INTO l_long
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, ei.dt_req_tstz, i_prof) dt_req,
                           CASE
                                WHEN ei.flg_code_type = pk_sr_clinical_info.g_flg_code_type_c THEN
                                 pk_translation.get_translation(i_lang, i.code_intervention) ||
                                 decode(ic.standard_code, NULL, '', ' / ' || ic.standard_code) ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                                ELSE
                                 ei.name_interv ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                            END desc_interv,
                           CASE
                                WHEN ei.flg_code_type = pk_sr_clinical_info.g_flg_code_type_c THEN
                                 1
                                ELSE
                                 0
                            END flg,
                           ei.flg_type,
                           ei.id_epis_diagnosis id_epis_diagnosis
                      FROM sr_epis_interv ei
                      LEFT JOIN intervention i
                        ON i.id_intervention = ei.id_sr_intervention
                      LEFT JOIN interv_codification ic
                        ON ic.id_intervention = i.id_intervention
                     WHERE ei.id_episode_context = i_id_episode
                       AND ei.flg_status != pk_sr_clinical_info.g_cancel
                     ORDER BY flg_type, flg, dt_req);
        
            l_ret := pk_utils.concat_table(l_long, ', ', 1, -1) || --
                     CASE
                         WHEN l_dt_surgery IS NOT NULL THEN
                          ', ' || l_dt_surgery
                         ELSE
                          NULL
                     END;
        
        ELSIF i_desc_type = pk_prog_notes_constants.g_desc_type_visit_info
        THEN
        
            get_dates(i_lang, i_prof, i_id_episode, l_dt_start_sur, l_dt_end_sur);
            l_room     := get_room(i_lang, i_id_episode);
            l_nurse    := get_nurse(i_lang, i_id_episode, pk_prog_notes_constants.g_task_templates, 17);
            l_category := get_category(i_lang, i_id_episode);
            l_team     := get_team(i_lang, i_prof, i_id_episode);
        
            l_ret := pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T013') ||
                     pk_prog_notes_constants.g_colon || nvl(l_dt_start_sur, pk_prog_notes_constants.g_triple_colon) ||
                     chr(10) || -- start date/time 
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T014') ||
                     pk_prog_notes_constants.g_colon || nvl(l_dt_end_sur, pk_prog_notes_constants.g_triple_colon) ||
                     chr(10) || --  end date/time 
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T015') ||
                     pk_prog_notes_constants.g_colon || nvl(l_room, pk_prog_notes_constants.g_triple_colon) || chr(10) || -- room
                     l_category || chr(10) || -- category
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T016') ||
                     pk_prog_notes_constants.g_colon || nvl(l_nurse, pk_prog_notes_constants.g_triple_colon) || chr(10) || -- nurse
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'VISIT_INFO_T018') ||
                     pk_prog_notes_constants.g_colon || nvl(l_team, pk_prog_notes_constants.g_triple_colon) || chr(10); -- team
        
        ELSIF i_desc_type = pk_prog_notes_constants.g_desc_type_c
        THEN
            SELECT desc_interv, id_epis_diagnosis
              BULK COLLECT
              INTO l_long, l_id_epis_diagnosis_tbl
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, ei.dt_req_tstz, i_prof) dt_req,
                           CASE
                                WHEN ei.flg_code_type = pk_sr_clinical_info.g_flg_code_type_c THEN
                                 pk_translation.get_translation(i_lang, i.code_intervention) ||
                                 decode(ic.standard_code, NULL, '', ' / ' || ic.standard_code) ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                                ELSE
                                 ei.name_interv ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                            END desc_interv,
                           CASE
                                WHEN ei.flg_code_type = pk_sr_clinical_info.g_flg_code_type_c THEN
                                 1
                                ELSE
                                 0
                            END flg,
                           ei.flg_type,
                           ei.id_epis_diagnosis id_epis_diagnosis
                      FROM sr_epis_interv ei
                      LEFT JOIN intervention i
                        ON i.id_intervention = ei.id_sr_intervention
                      LEFT JOIN interv_codification ic
                        ON i.id_intervention = ic.id_interv_codification
                     WHERE ei.id_episode_context = i_id_episode
                       AND ei.flg_status != pk_sr_clinical_info.g_cancel
                     ORDER BY flg_type, flg, dt_req);
        
            -- seeing if there is at least
            FOR i IN 1 .. l_id_epis_diagnosis_tbl.count
            LOOP
                l_flg := l_id_epis_diagnosis_tbl(i) IS NOT NULL;
                EXIT WHEN l_flg = TRUE;
            END LOOP;
        
            l_ret := CASE
                         WHEN l_dt_surgery IS NOT NULL THEN
                          l_dt_surgery
                         ELSE
                          NULL
                     END;
        
            l_ret := l_ret || ' ' || pk_utils.concat_table(l_long, ',', 1, -1);
        
            l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_desc_condition, i_delim => '|');
        
            IF l_tbl_desc_condition IS NOT NULL
            THEN
                <<lup_thru_conditions>>
                FOR i IN 1 .. l_tbl_desc_condition.count
                LOOP
                    IF l_tbl_desc_condition(i) = 'TEMPLATE'
                    THEN
                        l_ret := l_ret || chr(10) ||
                                 pk_touch_option.get_template_value(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_patient            => NULL,
                                                                    i_episode            => i_id_episode,
                                                                    i_doc_area           => 16,
                                                                    i_epis_documentation => NULL,
                                                                    i_doc_int_name       => NULL,
                                                                    i_element_int_name   => 'INT_SURG_FIND',
                                                                    i_show_internal      => NULL,
                                                                    i_scope_type         => 'E',
                                                                    i_mask               => NULL,
                                                                    i_field_type         => NULL);
                    
                        IF l_diagnosis IS NOT NULL
                           AND l_flg = FALSE
                        THEN
                            l_ret := l_ret || ' [' || l_diagnosis || ']';
                        END IF;
                    ELSIF l_tbl_desc_condition(i) = 'INTERV_DIAG'
                    THEN
                        <<lup_thru_epis_diagnosis>>
                        FOR i IN 1 .. l_id_epis_diagnosis_tbl.count
                        LOOP
                            IF l_id_epis_diagnosis_tbl(i) IS NOT NULL
                            THEN
                                l_rec_diag := pk_diagnosis.get_epis_diag(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_episode        => i_id_episode,
                                                                         i_epis_diag      => l_id_epis_diagnosis_tbl(i),
                                                                         i_epis_diag_hist => NULL);
                            
                                IF l_temp_desc IS NULL
                                   AND l_rec_diag.desc_diagnosis IS NOT NULL
                                THEN
                                    l_temp_desc := ' [' || l_rec_diag.desc_diagnosis;
                                ELSIF l_rec_diag.desc_diagnosis IS NOT NULL
                                THEN
                                    l_temp_desc := l_temp_desc || ', ' || l_rec_diag.desc_diagnosis;
                                END IF;
                            END IF;
                        END LOOP lup_thru_epis_diagnosis;
                        IF l_temp_desc IS NOT NULL
                        THEN
                            l_temp_desc := l_temp_desc || '] ';
                            l_ret       := l_ret || l_temp_desc;
                        END IF;
                    END IF;
                END LOOP lup_thru_conditions;
            END IF;
        
        ELSE
            g_error := 'GET long';
            SELECT desc_interv || --
                    CASE
                        WHEN desc_prof_team_leader IS NOT NULL THEN
                         ', ' || desc_prof_team_leader
                        ELSE
                         NULL
                    END
              BULK COLLECT
              INTO l_long
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, ei.dt_req_tstz, i_prof) dt_req,
                           CASE
                                WHEN ei.flg_code_type = pk_sr_clinical_info.g_flg_code_type_c THEN
                                 pk_translation.get_translation(i_lang, i.code_intervention) ||
                                 decode(ic.standard_code, NULL, '', ' / ' || ic.standard_code) ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                                ELSE
                                 ei.name_interv ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                            END desc_interv,
                           CASE
                                WHEN ei.flg_code_type = pk_sr_clinical_info.g_flg_code_type_c THEN
                                 1
                                ELSE
                                 0
                            END flg,
                           ei.flg_type,
                           (SELECT pk_prof_utils.get_name_signature(2,
                                                                    profissional(247032, 50002, 11),
                                                                    sptd.id_professional)
                              FROM sr_prof_team_det sptd
                             WHERE sptd.id_sr_epis_interv = ei.id_sr_epis_interv
                               AND sptd.id_prof_team_leader = sptd.id_professional
                               AND rownum = 1) desc_prof_team_leader
                      FROM sr_epis_interv ei
                      LEFT JOIN intervention i
                        ON i.id_intervention = ei.id_sr_intervention
                      LEFT JOIN interv_codification ic
                        ON i.id_intervention = ic.id_interv_codification
                     WHERE ei.id_episode_context = i_id_episode
                       AND ei.flg_status != pk_sr_clinical_info.g_cancel
                     ORDER BY flg_type, flg, dt_req);
        
            l_ret := CASE
                         WHEN l_dt_surgery IS NOT NULL THEN
                          l_dt_surgery || chr(10)
                         ELSE
                          NULL
                     END || pk_utils.concat_table(l_long, chr(10), 1, -1);
        
        END IF;
    
        l_ret := pk_string_utils.trim_empty_lines(i_text => l_ret);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_surg_proc;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    -- Advanced Input configurations
    g_all_institution := 0;
    g_all_software    := 0;

    g_advanced_input := 4;

    -- Keypad Date
    g_multichoice_keypad := 'L';
    g_num_keypad         := 'N';
    g_date_keypad        := 'DT';

END pk_sr_visit;
/
