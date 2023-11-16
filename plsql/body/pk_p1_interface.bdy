/*-- Last Change Revision: $Rev: 2027435 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_interface AS

    g_retval BOOLEAN;
    g_found  BOOLEAN;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_error        VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_sched_outp_status_e CONSTANT schedule_outp.flg_state%TYPE := 'E'; -- (E)fectivado
    g_dt_begin            CONSTANT VARCHAR2(20 CHAR) := '19700101000000';

    /**
    * Sets professional interface
    *
    * @param   I_PROF         Professional institution and software
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION set_prof_interface(i_prof IN profissional) RETURN profissional IS
    BEGIN
        RETURN pk_ref_interface.set_prof_interface(i_prof);
    END set_prof_interface;

    /**
    * Sets scheduling Gets request data. Used by the interface that registers the request in the hospital system
    * Notes: DT_SCHEDULE_TSTZ is the schedule creation date (before had the value 00:00:00), DT_BEGIN_TSTZ xx:yy:zz
    *
    * @param   I_LANG              Language identifier
    * @param   I_PROF              Professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ           Referral identifier
    * @param   I_PROF_SCHED        Professessional id for the appointment physician
    * @param   I_DCS               Appoitment's clinical service
    * @param   I_DATE_TSTZ         Appoitment's date/hour
    * @param   I_OP_DATE_TSTZ      Date of status change   
    * @param   I_TRANSACTION_ID    Remote scheduler transaction id. Can be null .     
    * @param   O_ERROR             an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION setscheduling
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date_tstz      IN VARCHAR2,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exr_row        p1_external_request%ROWTYPE;
        l_transaction_id VARCHAR2(4000) := i_transaction_id;
        l_sch_ids        table_number;
        l_prof_interface professional.id_professional%TYPE;
    
        CURSOR c_sch_ref(x_id_ref IN p1_external_request.id_external_request%TYPE) IS
            SELECT p.id_schedule
              FROM p1_external_request p
              JOIN schedule s
                ON s.id_schedule = p.id_schedule
             WHERE p.id_external_request = x_id_ref
               AND s.flg_status != pk_schedule.g_flg_status_sched_c;
    
        l_id_inst_dcs      institution.id_institution%TYPE;
        l_id_prof          professional.id_professional%TYPE;
        l_prof             profissional;
        l_rowids           table_varchar;
        l_rows_ei          table_varchar;
        l_sysdate_tstz     p1_tracking.dt_tracking_tstz%TYPE;
        l_dcs              dep_clin_serv.id_dep_clin_serv%TYPE;
        l_seq_num          p1_match.sequential_number%TYPE;
        l_num_clin_rec     clin_record.num_clin_record%TYPE;
        l_id_ext           sch_api_map_ids.id_schedule_ext%TYPE;
        l_id_schedule      p1_external_request.id_external_request%TYPE;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init setscheduling / ID_REF=' || i_ext_req;
        --l_sysdate_tstz := nvl(i_op_date_tstz, current_timestamp);
        l_sysdate_tstz := nvl(i_op_date_tstz, pk_ref_utils.get_sysdate);
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'Call pk_ref_utils.get_sys_config / ' || pk_ref_constant.g_sc_intf_prof_id;
        l_prof_interface := pk_ref_utils.get_sys_config(i_prof          => profissional(NULL,
                                                                                        i_prof.institution,
                                                                                        i_prof.software),
                                                        i_id_sys_config => pk_ref_constant.g_sc_intf_prof_id);
    
        ----------------------
        -- FUNC
        ----------------------
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_exr_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- JS, 2008-02-12: Considera a instituição associada ao id_dep_clin_serv em vez da indicada no profissional.
        -- O objectivo e assegurar que nas instituicoes que partilham sonhos os medicos e o agendamento ficam associados
        -- a instituicao correcta
        IF i_dcs IS NOT NULL
        THEN
        
            g_error  := 'Call pk_ref_utils.get_institution / ID_REF=' || i_ext_req || ' ID_DEP_CLIN_SERV=' || i_dcs;
            g_retval := pk_ref_utils.get_institution(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_dcs            => i_dcs,
                                                     o_id_institution => l_id_inst_dcs,
                                                     o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'get professional / ID_INSTITUTION=' || l_id_inst_dcs || ' SOFT=' || i_prof.software;
            l_prof  := profissional(l_prof_interface, l_id_inst_dcs, i_prof.software);
        
            -- JS, 2008-05-02: Se instituicao diferente da actual entao muda.
            IF l_id_inst_dcs != l_exr_row.id_inst_dest
            THEN
            
                g_error            := 'Call pk_api_ref_ws.get_flg_availability / ID_WF=' || l_exr_row.id_workflow ||
                                      ' ID_INST_ORIG=' || l_exr_row.id_inst_orig || ' ID_INST_DEST=' ||
                                      l_exr_row.id_inst_dest;
                l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => l_exr_row.id_workflow,
                                                                         i_id_inst_orig => l_exr_row.id_inst_orig,
                                                                         i_id_inst_dest => l_exr_row.id_inst_dest);
            
                -- cannot change referral institution for internal and at hospital entrance referrals
                IF l_flg_availability IN (pk_ref_constant.g_flg_availability_i, pk_ref_constant.g_flg_availability_p)
                THEN
                    g_error := 'Cannot change dep_clin_serv for this kind of referrals / ID_WF=' ||
                               l_exr_row.id_workflow || ' ID_REF=' || l_exr_row.id_external_request || ' ID_INST_ORIG=' ||
                               l_exr_row.id_inst_orig || ' ID_INST_DEST=' || l_exr_row.id_inst_dest ||
                               ' ID_DEP_CLIN_SERV_NEW=' || i_dcs || ' ID_INST_DEST_NEW=' || l_id_inst_dcs;
                    RAISE g_exception;
                END IF;
            
                -- pk_p1_core.set_dest_institution changes institution and sets FLG_STATUS to 'I'
                -- in this case it cannot happen, referral should only change institution dest, without changing status
            
                g_error := 'UPDATE p1_external_request / ID_EXT_REQ=' || i_ext_req || ' ID_INST_DEST_OLD=' ||
                           l_exr_row.id_inst_dest || ' ID_INST_DEST_NEW=' || l_id_inst_dcs || ' DEP_CLIN_SERV=' ||
                           i_dcs;
                ts_p1_external_request.upd(id_external_request_in => i_ext_req,
                                           id_inst_dest_in        => l_id_inst_dcs,
                                           rows_out               => l_rowids);
            
                g_error := 'Process_update P1_EXTERNAL_REQUEST / ID_EXT_REQ=' || i_ext_req || ' ID_INST_DEST_OLD=' ||
                           l_exr_row.id_inst_dest || ' ID_INST_DEST_NEW=' || l_id_inst_dcs || ' DEP_CLIN_SERV=' ||
                           i_dcs;
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'P1_EXTERNAL_REQUEST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error  := 'Call pk_ref_dest_reg.check_match / ID_REF=' || l_exr_row.id_external_request ||
                            ' ID_OLD_INST_DEST=' || l_exr_row.id_inst_dest || ' ID_PATIENT=' || l_exr_row.id_patient;
                g_retval := pk_ref_dest_reg.check_match(i_lang          => i_lang,
                                                        i_prof          => l_prof,
                                                        i_old_inst_dest => l_exr_row.id_inst_dest,
                                                        i_patient       => l_exr_row.id_patient,
                                                        o_seq_num       => l_seq_num,
                                                        o_num_clin_rec  => l_num_clin_rec,
                                                        o_error         => o_error);
            
                IF NOT g_retval
                THEN
                
                    g_error  := 'Call pk_p1_adm_hs.set_match_internal / ID_PATIENT=' || l_exr_row.id_patient ||
                                ' SEQ_NUM=' || l_seq_num || ' CLIN_RECORD=' || l_num_clin_rec;
                    g_retval := pk_p1_adm_hs.set_match_internal(i_lang     => i_lang,
                                                                i_pat      => l_exr_row.id_patient,
                                                                i_prof     => l_prof,
                                                                i_seq_num  => l_seq_num,
                                                                i_clin_rec => l_num_clin_rec,
                                                                i_epis     => NULL,
                                                                o_error    => o_error);
                
                    IF NOT g_retval
                    THEN
                        RAISE g_exception_np;
                    END IF;
                
                END IF;
            
            END IF;
        
            g_error := 'DEP_CLIN_SERV=' || i_dcs;
            l_dcs   := i_dcs;
        
        ELSE
            l_prof := profissional(l_prof_interface, i_prof.institution, i_prof.software);
        
            g_error := 'DEP_CLIN_SERV=' || l_exr_row.id_dep_clin_serv;
            l_dcs   := l_exr_row.id_dep_clin_serv;
        END IF;
    
        -- getting professional (create if not exists)
        g_error  := 'Call pk_ref_interface.set_professional_num_ord / l_prof=' || pk_utils.to_string(l_prof) ||
                    ' i_num_order=' || i_num_order || ' l_dcs=' || l_dcs;
        g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => i_lang,
                                                              i_prof      => l_prof,
                                                              i_num_order => i_num_order,
                                                              i_prof_name => i_prof_name,
                                                              i_dcs       => l_dcs,
                                                              o_id_prof   => l_id_prof,
                                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ------------------------------------------------
        -- Verificar se tem agendamento anterior activo
        OPEN c_sch_ref(l_exr_row.id_external_request);
        FETCH c_sch_ref
            INTO l_id_schedule;
        CLOSE c_sch_ref;
    
        IF l_id_schedule IS NOT NULL
        THEN
            -- Ja tinha agendamento anterior
            g_error := 'CALL pk_schedule_api_upstream.cancel_schedule / i_prof=' || pk_utils.to_string(l_prof) ||
                       ' ID_SCHEDULE=' || l_id_schedule;
            IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                            i_prof             => l_prof,
                                                            i_id_schedule      => l_id_schedule,
                                                            i_id_cancel_reason => NULL,
                                                            i_cancel_notes     => NULL, -- notes to scheduler and referral status
                                                            i_transaction_id   => l_transaction_id,
                                                            i_dt_referral      => l_sysdate_tstz,
                                                            o_error            => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'UPDATE EPIS_INFO / id_schedule=' || l_id_schedule;
            ts_epis_info.upd(flg_sch_status_in => pk_ref_constant.g_cancelled,
                             where_in          => 'id_schedule =' || l_id_schedule,
                             rows_out          => l_rows_ei);
        END IF;
    
        --
        -- Creates schedule and updates referral status       
        g_error  := 'Call pk_schedule_api_upstream.create_schedule / i_prof=' || pk_utils.to_string(l_prof) ||
                    ' i_id_external_req=' || l_exr_row.id_external_request || ' id_instit_requests=' ||
                    l_prof.institution || ' id_instit_requested=' || l_prof.institution || ' id_dcs_requested=' ||
                    l_dcs || ' id_dcs_requests=' || l_dcs || ' id_prof_requests=' || l_id_prof || ' id_prof_schedules=' ||
                    l_id_prof || ' id_schedule_ref=' || l_id_schedule;
        g_retval := pk_schedule_api_upstream.create_schedule(i_lang              => i_lang,
                                                             i_prof              => l_prof,
                                                             i_event_id          => pk_ref_constant.g_sch_event_1,
                                                             i_professional_id   => l_id_prof, -- id_prof_requests
                                                             i_id_patient        => l_exr_row.id_patient,
                                                             i_id_dep_clin_serv  => l_dcs, -- id_dcs_requested
                                                             i_dt_begin_tstz     => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                  i_prof,
                                                                                                                  i_date_tstz,
                                                                                                                  NULL),
                                                             i_dt_end_tstz       => NULL,
                                                             i_flg_vacancy       => NULL,
                                                             i_id_episode        => NULL,
                                                             i_flg_rqst_type     => NULL,
                                                             i_flg_sch_via       => NULL,
                                                             i_sch_notes         => NULL, -- notes to scheduler and referral status
                                                             i_id_inst_requests  => l_prof.institution,
                                                             i_id_dcs_requests   => l_dcs,
                                                             i_id_prof_requests  => l_id_prof,
                                                             i_id_prof_schedules => l_id_prof,
                                                             i_id_sch_ref        => l_id_schedule,
                                                             i_transaction_id    => l_transaction_id,
                                                             i_id_external_req   => l_exr_row.id_external_request,
                                                             i_dt_referral       => l_sysdate_tstz,
                                                             o_ids_schedule      => l_sch_ids,
                                                             o_id_schedule_ext   => l_id_ext,
                                                             o_error             => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'COMMIT EVERYTHING';
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SETSCHEDULING',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END setscheduling;

    /**
    * Updates scheduling after efectivation
    *
    * @param   I_LANG idioma
    * @param   I_PROF professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ external request id
    * @param   i_op_date_tstz Date of status change   
    * @param   i_transaction_id  SCH 3.0 transaction id. Can be null.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION setefectivation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sched          schedule.id_schedule%TYPE;
        l_schedout       schedule_outp.id_schedule_outp%TYPE;
        l_prof           profissional;
        l_sysdate_tstz   p1_tracking.dt_tracking_tstz%TYPE;
        l_id_patient     p1_external_request.id_patient%TYPE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        g_error := '->Init setefectivation / ID_REF=' || i_ext_req;
        pk_alertlog.log_debug(g_error);
    
        --l_sysdate_tstz := nvl(i_op_date_tstz, current_timestamp);
        l_sysdate_tstz := nvl(i_op_date_tstz, pk_ref_utils.get_sysdate);
        l_prof         := set_prof_interface(i_prof);
    
        g_error := 'Get schedule and the patient associated with the P1';
        SELECT s.id_schedule, so.id_schedule_outp, exr.id_patient
          INTO l_sched, l_schedout, l_id_patient
          FROM p1_external_request exr, schedule s, schedule_outp so
         WHERE exr.id_external_request = i_ext_req
           AND exr.id_schedule = s.id_schedule
           AND so.id_schedule = s.id_schedule;
    
        g_error := 'Update schedule_outp';
        UPDATE schedule_outp
           SET flg_state = g_sched_outp_status_e
         WHERE id_schedule_outp = l_schedout;
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, l_prof);
    
        -- efectivar no scheduler 3
        g_error := 'Call pk_schedule_api_upstream.register_schedule / ID_SCHEDULE=' || l_sched || ' ID_PATIENT=' ||
                   l_id_patient;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_schedule_api_upstream.register_schedule(i_lang           => i_lang,
                                                               i_prof           => l_prof,
                                                               i_id_schedule    => l_sched,
                                                               i_id_patient     => l_id_patient,
                                                               i_transaction_id => l_transaction_id,
                                                               o_error          => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_ext_sys.update_referral_status / ID_REF=' || i_ext_req ||
                    ' ID_SCHEDULE=NULL FLG_STATUS=' || pk_ref_constant.g_p1_status_e || ' FLG_RESCHEDULE=NULL';
        g_retval := pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                         i_prof       => l_prof,
                                                         i_ext_req    => i_ext_req,
                                                         i_id_sch     => NULL,
                                                         i_status     => pk_ref_constant.g_p1_status_e,
                                                         i_notes      => NULL,
                                                         i_reschedule => NULL,
                                                         i_date       => l_sysdate_tstz,
                                                         o_error      => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- fechar transacao
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, l_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SETEFECTIVATION',
                                              o_error    => o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END setefectivation;

    /**
    * Updates scheduling after efectivation
    * If there is no scheduling, creates it and then does the efectivation
    *
    * @param   I_LANG            Language identifier
    * @param   I_PROF            Professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ         Referral identifier
    * @param   I_PROF_SCHED      Professessional id for the appointment physician
    * @param   I_DCS             Appoitment's department clinical service
    * @param   I_DATE_TSTZ       Appoitment's date/hour
    * @param   I_OP_DATE_TSTZ    Date of status change
    * @param   i_transaction_id  SCH 3.0 transaction ID. Can be null.
    * @param   O_ERROR           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 1.0
    * @since   18-05-2007
    */
    FUNCTION setefectivation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date_tstz      IN VARCHAR2,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_sch IS
            SELECT s.id_schedule, so.id_schedule_outp, exr.id_patient
              FROM p1_external_request exr, schedule s, schedule_outp so
             WHERE exr.id_external_request = i_ext_req
               AND exr.id_schedule = s.id_schedule
               AND so.id_schedule = s.id_schedule
               AND s.flg_status != 'C'; -- ALERT-26811
    
        l_sched    schedule.id_schedule%TYPE;
        l_schedout schedule_outp.id_schedule_outp%TYPE;
    
        l_prof         profissional;
        l_sysdate_tstz p1_tracking.dt_tracking_tstz%TYPE;
        l_id_patient   p1_external_request.id_patient%TYPE;
        --SCH 3.0 variable 
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        g_error := '->Init setefectivation / ID_REF=' || i_ext_req || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                   i_prof_name || ' ID_DEP_CLIN_SERV=' || i_dcs || ' DATE_SCH=' || i_date_tstz;
        pk_alertlog.log_debug(g_error);
    
        --l_sysdate_tstz := nvl(i_op_date_tstz, current_timestamp);
        l_sysdate_tstz := nvl(i_op_date_tstz, pk_ref_utils.get_sysdate);
    
        l_prof := set_prof_interface(i_prof);
    
        g_error := 'Get schedule / ID_REF=' || i_ext_req || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                   i_prof_name || ' ID_DEP_CLIN_SERV=' || i_dcs || ' DATE_SCH=' || i_date_tstz;
        OPEN c_sch;
        FETCH c_sch
            INTO l_sched, l_schedout, l_id_patient;
        g_found := c_sch%FOUND;
        CLOSE c_sch;
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION / ID_REF=' || i_ext_req || ' NUM_ORDER=' || i_num_order ||
                            ' PROF_NAME=' || i_prof_name || ' ID_DEP_CLIN_SERV=' || i_dcs || ' DATE_SCH=' ||
                            i_date_tstz;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, l_prof);
    
        IF NOT g_found
        THEN
            g_error  := 'Call setscheduling / ID_REF=' || i_ext_req || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                        i_prof_name || ' ID_DEP_CLIN_SERV=' || i_dcs || ' DATE=' || i_date_tstz;
            g_retval := setscheduling(i_lang           => i_lang,
                                      i_prof           => l_prof,
                                      i_ext_req        => i_ext_req,
                                      i_num_order      => i_num_order,
                                      i_prof_name      => i_prof_name,
                                      i_dcs            => i_dcs,
                                      i_date_tstz      => i_date_tstz,
                                      i_op_date_tstz   => l_sysdate_tstz,
                                      i_transaction_id => l_transaction_id,
                                      o_error          => o_error);
        
            IF g_retval = FALSE
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'Get schedule 2';
            OPEN c_sch;
            FETCH c_sch
                INTO l_sched, l_schedout, l_id_patient;
            g_found := c_sch%FOUND;
            CLOSE c_sch;
        
            IF NOT g_found
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        g_error := 'Update schedule_outp';
        UPDATE schedule_outp
           SET flg_state = g_sched_outp_status_e
         WHERE id_schedule_outp = l_schedout;
    
        -- efectivar no scheduler 3
        g_error  := 'Call pk_schedule_api_upstream.register_schedule / ID_SCHEDULE=' || l_sched || ' ID_PATIENT=' ||
                    l_id_patient;
        g_retval := pk_schedule_api_upstream.register_schedule(i_lang           => i_lang,
                                                               i_prof           => l_prof,
                                                               i_id_schedule    => l_sched,
                                                               i_id_patient     => l_id_patient,
                                                               i_transaction_id => l_transaction_id,
                                                               o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_ext_sys.update_referral_status / ID_REF=' || i_ext_req || ' FLG_STATUS=' ||
                    pk_ref_constant.g_p1_status_e;
        g_retval := pk_p1_ext_sys.update_referral_status(i_lang       => i_lang,
                                                         i_prof       => l_prof,
                                                         i_ext_req    => i_ext_req,
                                                         i_id_sch     => NULL,
                                                         i_status     => pk_ref_constant.g_p1_status_e,
                                                         i_notes      => NULL,
                                                         i_reschedule => NULL,
                                                         i_date       => l_sysdate_tstz,
                                                         o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, l_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SETEFECTIVATION',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END setefectivation;

    /**
    * Cancels a request
    *
    * @param   I_LANG idioma
    * @param   I_PROF professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ external request id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION cancelrequest
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_notes          IN VARCHAR2,
        i_reason         IN p1_reason_code.id_reason_code%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof           profissional;
        l_workflow       wf_workflow.id_workflow%TYPE;
        l_flg_sataus     p1_external_request.flg_status%TYPE;
        l_transaction_id VARCHAR2(4000);
    
        CURSOR c_cur IS
            SELECT id_workflow, l_flg_sataus
              FROM p1_external_request
             WHERE id_external_request = i_ext_req;
    
        l_track_tab table_number;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION / ID_REF=' || i_ext_req ||
                            ' i_reason=' || i_reason;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        l_prof           := set_prof_interface(i_prof);
    
        g_error := 'Open c_cur / ID_REF=' || i_ext_req || ' i_reason=' || i_reason;
        OPEN c_cur;
        FETCH c_cur
            INTO l_workflow, l_flg_sataus;
        CLOSE c_cur;
    
        IF l_workflow IS NULL -- workflow CS - HOSPITAL
        THEN
        
            g_error := 'Call pk_p1_med_cs.cancel_external_request_int / ID_REF=' || i_ext_req || ' i_reason=' ||
                       i_reason;
            RETURN pk_p1_med_cs.cancel_external_request_int(i_lang           => i_lang,
                                                            i_prof           => l_prof,
                                                            i_ext_req        => i_ext_req,
                                                            i_mcdts          => NULL,
                                                            i_id_patient     => NULL,
                                                            i_id_episode     => NULL,
                                                            i_notes          => i_notes,
                                                            i_reason         => i_reason,
                                                            i_transaction_id => l_transaction_id,
                                                            o_track          => l_track_tab,
                                                            o_error          => o_error);
        
        ELSE
            -- workflows novos
            g_error := 'Call pk_ref_orig_phy.cancel_referral / ID_REF=' || i_ext_req || ' i_reason=' || i_reason;
            RETURN pk_ref_orig_phy.cancel_referral(i_lang           => i_lang,
                                                   i_prof           => l_prof,
                                                   i_ext_req        => i_ext_req,
                                                   i_id_patient     => NULL,
                                                   i_id_episode     => NULL,
                                                   i_notes          => i_notes,
                                                   i_reason         => i_reason,
                                                   i_transaction_id => l_transaction_id,
                                                   o_track          => l_track_tab,
                                                   o_error          => o_error);
        
        END IF;
    
        --warns the new scheduler that it should commit the transaction 
        --only is activated if function is not called by remote interfaces
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCELREQUEST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancelrequest;

    /**
    * Requests that are refused in SONHO
    *
    * @param   i_lang idioma
    * @param   i_prof professional id, institution and software for the professional that schedules
    * @param   i_ext_req external request id
    * @param   i_notes refusal notes
    * @param   i_reason resason code    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   18-05-2007
    */
    FUNCTION refuserequest
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_notes   IN p1_detail.text%TYPE,
        i_reason  IN p1_reason_code.id_reason_code%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof       profissional;
        l_workflow   wf_workflow.id_workflow%TYPE;
        l_flg_sataus p1_external_request.flg_status%TYPE;
        l_flg_show   VARCHAR2(200);
        l_msg_title  VARCHAR2(200);
        l_msg        VARCHAR2(200);
        l_track_tab  table_number;
    
        CURSOR c_cur IS
            SELECT id_workflow, l_flg_sataus
              FROM p1_external_request
             WHERE id_external_request = i_ext_req;
    BEGIN
        l_prof := set_prof_interface(i_prof);
    
        g_error := 'Open c_cur / ID_REF=' || i_ext_req || ' i_prof=' || pk_utils.to_string(l_prof);
        OPEN c_cur;
        FETCH c_cur
            INTO l_workflow, l_flg_sataus;
        CLOSE c_cur;
    
        IF l_workflow IS NULL
        THEN
        
            g_error  := 'Call pk_p1_med_hs.set_status_internal / i_prof=' || pk_utils.to_string(l_prof) || ' ID_REF=' ||
                        i_ext_req || ' ACTION=' || pk_ref_constant.g_ref_action_x || ' MODE=' || pk_ref_constant.g_no ||
                        ' REASON_CODE=' || i_reason;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof,
                                                         i_id_p1         => i_ext_req,
                                                         i_action        => pk_ref_constant.g_ref_action_x,
                                                         i_level         => NULL,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => NULL,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => pk_ref_constant.g_no,
                                                         i_reason_code   => i_reason,
                                                         i_subtype       => pk_ref_constant.g_tracking_subtype_e,
                                                         i_inst_dest     => NULL,
                                                         i_date          => NULL,
                                                         o_track         => l_track_tab,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / i_prof=' || pk_utils.to_string(l_prof) || ' ID_REF=' ||
                        i_ext_req || ' ACTION=' || pk_ref_constant.g_ref_action_x || ' MODE=' || pk_ref_constant.g_no ||
                        ' REASON_CODE=' || i_reason;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof,
                                                i_ext_req      => i_ext_req,
                                                i_status_begin => l_flg_sataus, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_x, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_x, -- REFUSE
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => pk_ref_constant.g_no,
                                                i_reason_code  => i_reason,
                                                i_subtype      => pk_ref_constant.g_tracking_subtype_e,
                                                i_inst_dest    => NULL,
                                                o_track        => l_track_tab,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        
        END IF;
    
        IF g_retval = FALSE
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'REFUSEREQUEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END refuserequest;

    /**
    * Cancels a previous appointment
    *
    * @param   i_lang              Language identifier
    * @param   i_prof              Professional id, institution and software for the professional that schedules
    * @param   i_ext_req           Referral identifier
    * @param   i_date_tstz         Referral appointment date. Is used to check if corresponds to a active appointment (ther's no other way)
    * @param   i_notes             Appointement cancelation notes
    * @param   i_op_date_tstz      Date of status change   
    * @param   i_transaction_id    SCH 3.0 transaction id . Can be null.
    * @param   i_reason_code       Referral reason code        
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao S
    * @version 1.0
    * @since   19-07-2007
    */
    FUNCTION cancelschedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_date_tstz      IN VARCHAR2,
        i_notes          IN VARCHAR2,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sched_old      schedule.id_schedule%TYPE;
        l_prof           profissional;
        l_rows_ei        table_varchar;
        l_transaction_id VARCHAR2(4000);
        l_sysdate_tstz   p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
    
        g_error := 'Init cancelschedule / ID_REF=' || i_ext_req || ' I_DATE_TSTZ=' || i_date_tstz;
        pk_alertlog.log_debug(g_error);
    
        --l_sysdate_tstz := nvl(i_op_date_tstz, current_timestamp);
        l_sysdate_tstz := nvl(i_op_date_tstz, pk_ref_utils.get_sysdate);
    
        l_prof := set_prof_interface(i_prof);
    
        -- check if schedule already exists
        BEGIN
            SELECT exr.id_schedule
              INTO l_sched_old
              FROM p1_external_request exr, schedule s
             WHERE exr.id_external_request = i_ext_req
               AND s.id_schedule = exr.id_schedule
               AND s.flg_status != pk_ref_constant.g_cancelled
               AND s.dt_begin_tstz = pk_date_utils.get_string_tstz(i_lang, l_prof, i_date_tstz, NULL); -- checks if this appointment date is the active one
        EXCEPTION
            WHEN no_data_found THEN
                l_sched_old := NULL;
        END;
    
        IF l_sched_old IS NOT NULL
        THEN
        
            -- get remote transaction
            g_error          := 'START REMOTE TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, l_prof);
        
            g_error  := 'CALL pk_schedule_api_upstream.cancel_schedule / ID_SCHEDULE=' || l_sched_old;
            g_retval := pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                                 i_prof             => l_prof,
                                                                 i_id_schedule      => l_sched_old,
                                                                 i_id_cancel_reason => 9,
                                                                 i_cancel_notes     => i_notes,
                                                                 i_transaction_id   => l_transaction_id,
                                                                 i_dt_referral      => l_sysdate_tstz,
                                                                 i_referral_reason  => i_reason_code,
                                                                 o_error            => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'UPDATE EPIS_INFO';
            ts_epis_info.upd(flg_sch_status_in => pk_ref_constant.g_cancelled,
                             where_in          => 'id_schedule = ' || l_sched_old,
                             rows_out          => l_rows_ei);
        
            -- Referral status change has already been done inside scheduler integration            
        
            --only does a remote commit if api is not called from external interfaces
            g_error := 'COMMIT EVERYTHING';
            IF i_transaction_id IS NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, l_prof);
            END IF;
        
        ELSE
            g_error := 'There is no active appointment for request: ' || to_char(i_ext_req) || ' with timestamp: ' ||
                       i_date_tstz;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCELSCHEDULE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancelschedule;

    /**
    * Gets request data. Used by the interface that registers the request in the hospital system
    *
    * @param i_lang language associated to the professional executing the request
    * @param i_prof professional id, institution and software
    * @param i_ext_req external system id
    * @param o_error an error message, set when return=false
    *
    * @RETURN TRUE if sucess, FALSE otherwise
    * @author Ricardo Patrocinio
    * @version 1.0
    * @since 05-02-2009
    *
    * MODIFIED BY: Ricardo Patrocinio on 2009-03-20
    * NOTE: Jira Issue: ALERT-20883
    */
    FUNCTION get_request_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Get data / ID_REF=' || i_ext_req;
        OPEN o_data FOR
            SELECT t.id_external_request,
                   t.id_inst_dest,
                   t.id_patient,
                   t.id_dep_clin_serv    id_clinical_service,
                   t.ext_code            cod_unidade_saude,
                   --CASE
                   --     WHEN t.id_workflow = pk_ref_constant.g_wf_x_hosp THEN -- ALERT-256950
                   --      (SELECT rod.prof_name
                   --         FROM ref_orig_data rod
                   --        WHERE rod.id_external_request = t.id_external_request)
                   --     ELSE
                   --      p.nick_name
                   -- END prof_name,                    
                   pk_p1_external_request.get_prof_req_name(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_prof_requested => t.id_prof_requested,
                                                            i_id_prof_roda      => t.id_prof_roda) prof_name,
                   t.flg_priority urgent,
                   t.dt_status_tstz dt_status, -- Data da operacao
                   t.flg_status,
                   CASE
                        WHEN t.flg_status IN (pk_ref_constant.g_p1_status_x, pk_ref_constant.g_p1_status_c) THEN
                         (SELECT id_reason_code
                            FROM (SELECT id_reason_code
                                    FROM p1_tracking exrt
                                   WHERE exrt.id_external_request = i_ext_req
                                     AND ext_req_status IN (pk_ref_constant.g_p1_status_x, pk_ref_constant.g_p1_status_c)
                                     AND flg_type = pk_ref_constant.g_tracking_type_s
                                   ORDER BY dt_tracking_tstz DESC)
                           WHERE rownum <= 1)
                        ELSE
                         NULL
                    END cod_mot_recusa,
                   SYSDATE
              FROM (SELECT exr.id_external_request,
                           exr.id_inst_orig,
                           exr.id_inst_dest,
                           exr.id_patient,
                           exr.id_dep_clin_serv,
                           exr.flg_priority,
                           exr.dt_status_tstz,
                           exr.flg_status,
                           exr.id_workflow,
                           exr.id_prof_requested,
                           rod.id_professional id_prof_roda,
                           --rod.prof_name           prof_name_roda,
                           ist.ext_code
                      FROM p1_external_request exr
                      LEFT JOIN ref_orig_data rod
                        ON exr.id_external_request = rod.id_external_request
                      JOIN institution ist
                        ON (exr.id_inst_orig = ist.id_institution)
                     WHERE exr.id_external_request = i_ext_req) t
            --JOIN professional p
            --  ON (t.id_prof_requested = p.id_professional)
            ;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_REQUEST_DATA',
                                                     o_error    => o_error);
    END get_request_data;

    /**
    * Gets request specialty related data. Used by the interface that registers the request in the hospital system
    * Returned data: Request id, Destination Intitution id, Specialty id and Despination Department id
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ext_req external system id
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION get_esp_update_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_data FOR
            SELECT exr.id_external_request, exr.id_inst_dest, exr.id_speciality, exr.id_dep_clin_serv
              FROM p1_external_request exr
             WHERE exr.id_external_request = i_ext_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_ESP_UPDATE_DATA',
                                                     o_error    => o_error);
    END;

    /**
    * Gets request data when a re-match takes place. Used by the interface that registers the request in the hospital system
    * Returned data: Request Id, Destination Institution Id and Sequencial Number
    *
    * @param i_lang language associated to the professional executing the request
    * @param i_prof professional id, institution and software
    * @param i_id_match external system id
    * @param o_error an error message, set when return=false
    *
    * @RETURN TRUE if sucess, FALSE otherwise
    * @author Ricardo Patrocinio
    * @version 1.0
    * @since 05-02-2009
    *
    * MODIFIED BY: Ricardo Patrocinio on 2009-03-20
    * Note: Jira Issue: ALERT-20883
    */
    FUNCTION get_request_data_rematch
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_match IN p1_match.id_match%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_data FOR
            SELECT DISTINCT r.id_external_request, r.id_inst_dest, m.sequential_number
              FROM p1_match m
              JOIN p1_external_request r
                ON (m.id_patient = r.id_patient AND m.id_institution = r.id_inst_dest)
             WHERE m.id_match = i_id_match
               AND m.flg_status = pk_ref_constant.g_active
               AND m.id_match_prev IS NOT NULL;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_REQUEST_DATA_REMATCH',
                                                     o_error    => o_error);
    END get_request_data_rematch;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao S
    * @version 1.0
    * @since   22-02-2008
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof     profissional;
        l_id_match p1_match.id_match%TYPE;
    BEGIN
        l_prof := set_prof_interface(i_prof);
    
        g_error  := 'Call pk_ref_dest_reg.set_match / i_prof=' || pk_utils.to_string(l_prof) || ' i_pat=' || i_pat ||
                    ' i_seq_num=' || i_seq_num || ' i_clin_rec=' || i_clin_rec;
        g_retval := pk_ref_dest_reg.set_match(i_lang     => i_lang,
                                              i_prof     => l_prof,
                                              i_pat      => i_pat,
                                              i_seq_num  => i_seq_num,
                                              i_clin_rec => i_clin_rec,
                                              i_epis     => NULL,
                                              o_id_match => l_id_match,
                                              o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_match;

    /**
    * Gets data from a P1 event generated by set_match
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_INST_DEST Destination Institution Id
    * @param   O_DATA Cursor with the result of the query, set when return=true
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Patrocinio
    * @version 1.0
    * @since   03-04-2009
    */
    FUNCTION get_p1_data
    (
        i_lang      IN language.id_language%TYPE,
        i_pat       IN p1_external_request.id_patient%TYPE,
        i_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_data / I_PAT=' || i_pat || ' ID_INST_DEST=' || i_inst_dest;
        OPEN o_data FOR
            SELECT id_external_request, id_dep_clin_serv, flg_status, flg_import, ext_reference
              FROM p1_external_request
             WHERE id_patient = i_pat
               AND id_inst_dest = i_inst_dest;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_P1_DATA',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_p1_data;

    /**
    * Gets the scheduled requests in the interval between id_dt_begin and id_dt_end
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   id_dt_begin interval begin
    * @param   id_dt_begin interval end
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   24-04-2008
    */
    FUNCTION get_scheduled_requests
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        id_dt_begin IN VARCHAR2,
        id_dt_end   IN VARCHAR2
    ) RETURN scheduled_requests_table
        PIPELINED IS
        l_scheduled_requests scheduled_requests_rec;
        l_begin              TIMESTAMP;
        l_end                TIMESTAMP;
    BEGIN
    
        g_error := 'Convert dt_begin / id_dt_begin=' || id_dt_begin || ' id_dt_end=' || id_dt_end;
        IF id_dt_begin IS NULL
        THEN
            l_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, g_dt_begin, NULL);
        ELSE
            l_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, id_dt_begin, NULL);
        END IF;
    
        g_error := 'Convert dt_end / id_dt_begin=' || id_dt_begin || ' id_dt_end=' || id_dt_end;
        IF id_dt_end IS NULL
        THEN
            l_end := current_timestamp;
        ELSE
            l_end := pk_date_utils.get_string_tstz(i_lang, i_prof, id_dt_end, NULL);
        END IF;
    
        g_error := 'get data / id_dt_begin=' || id_dt_begin || ' id_dt_end=' || id_dt_end;
        FOR rs IN (SELECT exr.id_external_request, s.dt_begin_tstz
                     FROM p1_external_request exr
                     JOIN schedule s
                       ON (s.id_schedule = exr.id_schedule)
                    WHERE exr.flg_status = pk_ref_constant.g_p1_status_s
                      AND exr.dt_requested BETWEEN l_begin AND l_end)
        LOOP
            l_scheduled_requests.id_external_request := rs.id_external_request;
            l_scheduled_requests.dt_schedule         := rs.dt_begin_tstz;
        
            PIPE ROW(l_scheduled_requests);
        
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => pk_ref_constant.g_sm_common_m001) || chr(10) ||
                                  g_error || '/ ' || SQLERRM);
            RETURN;
    END;

    /**
    * Gets the scheduled requests without triage
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_ext_req external system id
    * @param   O_DATA Cursor with the result of the query, set when return=true
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Patrocinio
    * @version 1.0
    * @since   03-04-2009
    */
    FUNCTION get_sch_without_triage
    (
        i_lang    IN language.id_language%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SELECT o_data / ID_REF=' || i_ext_req;
        SELECT COUNT(s.id_schedule)
          INTO o_data
          FROM p1_external_request e
          JOIN schedule s
            ON (e.id_schedule = s.id_schedule)
         WHERE e.id_external_request = i_ext_req
           AND s.flg_status != pk_ref_constant.g_p1_status_c;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCH_WITHOUT_TRIAGE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_sch_without_triage;

    /**
    * Get descriptions for provided tables and ids.
    * Used by the interface to get Alert description of mapped ids.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_key  table names and ids, third field used only for sys_domain. (TABLE_NAME, ID[VAL], [CODE_DOMAIN])
    * @param   o_id   result id  description. (ID[VAL])
    * @param   o_desc result description. (Description)    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   28-10-2008
    */
    FUNCTION get_description
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_key   IN table_table_varchar, -- (TABELA, ID[VAL], [CODE_DOMAIN])
        o_id    OUT table_varchar,
        o_desc  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'call pk_p1_core.get_description';
        IF NOT pk_p1_core.get_description(i_lang  => i_lang,
                                          i_prof  => i_prof,
                                          i_key   => i_key,
                                          o_id    => o_id,
                                          o_desc  => o_desc,
                                          o_error => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DESCRIPTION',
                                                     o_error    => o_error);
    END get_description;

    /**
    *
    * Sets the request status to "T": hospital registrar has to send the request to triage.
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional id, institution and software
    * @param   I_ID_EXT_REQ   External request id
    * @param   I_DATE         Date of status change
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-06-2009
    */
    FUNCTION set_to_triage
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_date       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_date_tstz p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row   p1_external_request%ROWTYPE;
        l_flg_show  VARCHAR2(200);
        l_msg_title VARCHAR2(200);
        l_msg       VARCHAR2(200);
        l_track_tab table_number;
    BEGIN
        ----------------------
        -- FUNC
        ----------------------   
        g_error := 'Calling pk_ref_interface.set_prof_interface / ID_REF=' || i_id_ext_req;
        l_prof  := pk_ref_interface.set_prof_interface(i_prof);
    
        g_error     := 'Calling pk_date_utils.get_string_tstz / ID_REF=' || i_id_ext_req;
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, i_date, NULL);
    
        g_error := 'g_sysdate_tstz / ID_REF=' || i_id_ext_req || ' i_date=' || i_date;
        --g_sysdate_tstz := nvl(l_date_tstz, current_timestamp);
        g_sysdate_tstz := nvl(l_date_tstz, pk_ref_utils.get_sysdate);
    
        -- checking status referral
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'l_ref_row.flg_status / ID_REF=' || i_id_ext_req;
        IF l_ref_row.flg_status = pk_ref_constant.g_p1_status_i
        THEN
            -- referral is issued, changing status to (T)riage
            IF l_ref_row.id_workflow IS NULL
            THEN
            
                g_error  := 'Calling PK_P1_ADM_HS.set_status_internal / ID_REF=' || i_id_ext_req;
                g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                             i_prof        => l_prof,
                                                             i_ext_req     => i_id_ext_req,
                                                             i_status      => pk_ref_constant.g_p1_status_t,
                                                             i_notes       => NULL,
                                                             i_reason_code => NULL,
                                                             i_dcs         => NULL,
                                                             i_date        => g_sysdate_tstz,
                                                             o_track       => l_track_tab,
                                                             o_error       => o_error);
            ELSE
                g_error  := 'Call pk_ref_core.set_status / ID_REFERRAL=' || i_id_ext_req || ' STATUS=' ||
                            pk_ref_constant.g_p1_status_t || ' ACTION=' || pk_ref_constant.g_ref_action_t;
                g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                    i_prof         => l_prof,
                                                    i_ext_req      => i_id_ext_req,
                                                    i_status_begin => NULL, -- deprecated
                                                    i_status_end   => pk_ref_constant.g_p1_status_t, -- deprecated
                                                    i_action       => pk_ref_constant.g_ref_action_t, -- TRIAGE
                                                    i_level        => NULL,
                                                    i_prof_dest    => NULL,
                                                    i_dcs          => NULL,
                                                    i_notes        => NULL,
                                                    i_dt_modified  => NULL,
                                                    i_mode         => NULL,
                                                    i_reason_code  => NULL,
                                                    i_subtype      => NULL,
                                                    i_inst_dest    => NULL,
                                                    i_date         => g_sysdate_tstz,
                                                    o_track        => l_track_tab,
                                                    o_flg_show     => l_flg_show,
                                                    o_msg_title    => l_msg_title,
                                                    o_msg          => l_msg,
                                                    o_error        => o_error);
            END IF;
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_TO_TRIAGE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_to_triage;

    /**
    * Triage the request
    * Sets the request status to "A": hospital physician has triaged the request.
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional id, institution and software
    * @param   I_ID_EXT_REQ   External request id
    * @param   I_INST         Institution id    
    * @param   I_DCS          Destination department/clinical_service
    * @param   I_NUM_ORDER    Professional num order for the appointment physician
    * @param   I_PROF_NAME    Professional name for the appointment physician
    * @param   I_LEVEL        Decision urgency level
    * @param   I_DATE         Triage Date   
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION triage_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_inst       IN institution.id_institution%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_num_order  IN professional.num_order%TYPE,
        i_prof_name  IN professional.name%TYPE,
        i_level      IN p1_external_request.decision_urg_level%TYPE,
        i_date       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_track(x_ext_req IN p1_tracking.id_external_request%TYPE) IS
            SELECT *
              FROM (SELECT p.dt_tracking_tstz
                      FROM p1_tracking p
                     WHERE id_external_request = x_ext_req
                       AND flg_type = pk_ref_constant.g_tracking_type_s
                     ORDER BY p.dt_tracking_tstz DESC)
             WHERE rownum = 1;
    
        l_prof          profissional;
        l_id_prof_sch   professional.id_professional%TYPE;
        l_sysdate_v     VARCHAR2(50);
        l_flg_show      VARCHAR2(1);
        l_msg_title     sys_message.desc_message%TYPE;
        l_msg           sys_message.desc_message%TYPE;
        l_dt_last_tstz  p1_tracking.dt_tracking_tstz%TYPE;
        l_date_tstz     p1_tracking.dt_tracking_tstz%TYPE;
        l_ref_row       p1_external_request%ROWTYPE;
        l_flg_available VARCHAR2(1 CHAR);
        l_track_tab     table_number;
    BEGIN
        ----------------------------
        -- VAL
        ----------------------------
        IF i_id_ext_req IS NULL
           OR i_inst IS NULL
           OR i_dcs IS NULL
           OR i_level IS NULL
        THEN
            g_error := 'Validating parameters / i_id_ext_req=' || i_id_ext_req || ' i_inst=' || i_inst || ' i_dcs=' ||
                       i_dcs || ' i_level=' || i_level;
            RAISE g_exception;
        END IF;
    
        l_prof := pk_ref_interface.set_prof_interface(i_prof);
    
        g_error     := 'Calling pk_date_utils.get_string_tstz';
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, i_date, NULL);
    
        g_error := 'g_sysdate_tstz';
        --g_sysdate_tstz := nvl(l_date_tstz, current_timestamp);
        g_sysdate_tstz := nvl(l_date_tstz, pk_ref_utils.get_sysdate);
    
        -- i_date must be greater than the last status change
        g_error := 'OPEN c_track(' || i_id_ext_req || ')';
        OPEN c_track(i_id_ext_req);
        FETCH c_track
            INTO l_dt_last_tstz;
        g_found := c_track%FOUND;
        CLOSE c_track;
    
        g_error := '|triage_request|i_date=' || i_date || '|g_sysdate_tstz=' ||
                   pk_date_utils.to_char_insttimezone(l_prof, g_sysdate_tstz, 'DD-MM-YYYY HH24:MI:SSXFF') ||
                   '|l_dt_last_tstz=' ||
                   pk_date_utils.to_char_insttimezone(l_prof, l_dt_last_tstz, 'DD-MM-YYYY HH24:MI:SSXFF');
        --pk_alertlog.log_debug(g_error);
    
        IF pk_date_utils.compare_dates_tsz(i_prof => l_prof, i_date1 => g_sysdate_tstz, i_date2 => l_dt_last_tstz) = 'L'
        THEN
            g_error := 'DATE NOT VALID';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------   
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ext_req;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check dep_clin_serv
        g_error  := 'Call pk_api_ref_ws.check_dep_clin_serv / i_id_inst_dest=' || i_inst || ' i_dcs=' || i_dcs;
        g_retval := pk_api_ref_ws.check_dep_clin_serv(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_inst_dest  => i_inst,
                                                      i_dcs           => i_dcs,
                                                      o_flg_available => l_flg_available,
                                                      o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            g_error := g_error || ' / DEP_CLIN_SERV not found';
            RAISE g_exception;
        END IF;
    
        -- getting professional id
        IF i_num_order IS NULL
        THEN
            l_id_prof_sch := NULL;
        ELSE
            g_error  := 'Call pk_ref_interface.set_professional_num_ord / l_prof=' || pk_utils.to_string(l_prof) ||
                        ' i_num_order=' || i_num_order || ' i_dcs=' || i_dcs;
            g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => i_lang,
                                                                  i_prof      => l_prof,
                                                                  i_num_order => i_num_order,
                                                                  i_prof_name => i_prof_name,
                                                                  i_dcs       => i_dcs,
                                                                  o_id_prof   => l_id_prof_sch,
                                                                  o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error     := 'Calling pk_date_utils.get_timestamp_str';
        l_sysdate_v := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                       i_prof      => l_prof,
                                                       i_timestamp => g_sysdate_tstz,
                                                       i_timezone  => NULL);
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            g_error  := 'Calling PK_P1_MED_HS.set_status_internal / ID_REF=' || i_id_ext_req || ' i_level=' || i_level ||
                        ' i_prof_dest=' || l_id_prof_sch || ' i_dep_clin_serv=' || i_dcs || ' DT_MODIFIED=' ||
                        l_sysdate_v;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof,
                                                         i_id_p1         => i_id_ext_req,
                                                         i_action        => pk_ref_constant.g_ref_action_a,
                                                         i_level         => i_level,
                                                         i_prof_dest     => l_id_prof_sch,
                                                         i_dep_clin_serv => i_dcs,
                                                         i_notes         => NULL,
                                                         i_dt_modified   => l_sysdate_v,
                                                         i_mode          => NULL, -- do not validate referral changes, for now
                                                         i_reason_code   => NULL,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => l_track_tab,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        ELSE
        
            -- setting referral status to 'A' 
            g_error  := 'Call PK_REF_CORE.set_status / ID_REFERRAL=' || i_id_ext_req || ' STATUS=' ||
                        pk_ref_constant.g_p1_status_a || ' LEVEL=' || i_level || ' DCS=' || i_dcs || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_a;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional that triaged the referral
                                                i_ext_req      => i_id_ext_req,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_a, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_a, -- ACCEPTED
                                                i_level        => i_level,
                                                i_prof_dest    => l_id_prof_sch,
                                                i_dcs          => i_dcs,
                                                i_notes        => NULL,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => l_track_tab,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_show = pk_ref_constant.g_yes
        THEN
            g_error := l_msg_title;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'TRIAGE_REQUEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END triage_request;

    /**
    * Function to get information for field Reason
    *
    * @param   I_LANG    Language associated to the professional executing the request
    * @param   I_PROF    Professional id, institution and software    
    * @param   i_ext_req       Referral identifier
    *
    * @RETURN  Referral reason  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-08-2009
    */
    FUNCTION get_justification
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2 IS
    
        -- reason, symptomology, progress, history, family history, objective exam and diagnostic exams
        CURSOR c_detail IS
            SELECT p1d.text, p1d.flg_type
              FROM p1_detail p1d
             WHERE p1d.flg_type IN (pk_ref_constant.g_detail_type_jstf,
                                    pk_ref_constant.g_detail_type_sntm,
                                    pk_ref_constant.g_detail_type_evlt,
                                    pk_ref_constant.g_detail_type_hstr,
                                    pk_ref_constant.g_detail_type_hstf,
                                    pk_ref_constant.g_detail_type_obje,
                                    pk_ref_constant.g_detail_type_cmpe)
               AND p1d.flg_status = pk_ref_constant.g_active
               AND p1d.id_external_request = i_ext_req;
    
        -- problems and diagnosis
        CURSOR c_diagnosis IS
            SELECT pk_translation.get_translation(i_lang, d.code_diagnosis) desc_diagnosis, pd.flg_type
              FROM p1_exr_diagnosis pd
              JOIN diagnosis d
                ON pd.id_diagnosis = d.id_diagnosis
             WHERE pd.flg_status = pk_ref_constant.g_active
               AND pd.flg_type IN (pk_ref_constant.g_exr_diag_type_p, pk_ref_constant.g_exr_diag_type_d)
               AND pd.id_external_request = i_ext_req;
    
        -- Problem begin date 
        CURSOR c_ref IS
            SELECT p.year_begin, p.month_begin, p.day_begin
              FROM p1_external_request p
             WHERE p.id_external_request = i_ext_req;
    
        l_year_begin  p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin   p1_exr_diagnosis.day_begin%TYPE;
    
        -- detail
        l_detail_text_tab table_varchar;
        l_detail_type_tab table_number;
    
        -- problem
        l_diag_text_tab table_varchar;
        l_diag_type_tab table_varchar;
    
        l_reason      p1_detail.text%TYPE;
        l_sympt       p1_detail.text%TYPE;
        l_progress    p1_detail.text%TYPE;
        l_hist        p1_detail.text%TYPE;
        l_family_hist p1_detail.text%TYPE;
        l_obj_exam    p1_detail.text%TYPE;
        l_compl_exam  p1_detail.text%TYPE;
    
        l_prob        p1_detail.text%TYPE;
        l_diag        p1_detail.text%TYPE;
        l_result      p1_detail.text%TYPE;
        l_probl_begin VARCHAR2(500);
    
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    
        l_error t_error_out;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------    
        g_error        := 'Fill l_code_msg_arr / ID_REF=' || i_ext_req;
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_p1_detail_t013, -- Reason
                                        pk_ref_constant.g_sm_p1_detail_t021, -- Symptomology 
                                        pk_ref_constant.g_sm_doctor_cs_t030, -- Problems
                                        pk_ref_constant.g_sm_p1_detail_t020, -- Problem begin date
                                        pk_ref_constant.g_sm_p1_detail_t022, -- Progress
                                        pk_ref_constant.g_sm_p1_detail_t024, -- History
                                        pk_ref_constant.g_sm_p1_detail_t025, -- Family history
                                        pk_ref_constant.g_sm_p1_detail_t026, -- Objective exam
                                        pk_ref_constant.g_sm_p1_detail_t027, -- Diagnostic exams
                                        pk_ref_constant.g_sm_p1_detail_t028 -- Diagnostic
                                        );
    
        g_error  := 'Call pk_ref_utils.get_message_ibt / ID_REF=' || i_ext_req || ' / l_code_msg_arr.COUNT=' ||
                    l_code_msg_arr.count;
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------        
    
        -- fetching data
        g_error := 'OPEN c_detail / ID_REF=' || i_ext_req;
        OPEN c_detail;
        FETCH c_detail BULK COLLECT
            INTO l_detail_text_tab, l_detail_type_tab;
        CLOSE c_detail;
    
        -- problems and diagnosis
        g_error := 'OPEN c_diagnosis / ID_REF=' || i_ext_req;
        OPEN c_diagnosis;
        FETCH c_diagnosis BULK COLLECT
            INTO l_diag_text_tab, l_diag_type_tab;
        CLOSE c_diagnosis;
    
        -- problem begin date
        g_error := 'OPEN c_ref / ID_REF=' || i_ext_req;
        OPEN c_ref;
        FETCH c_ref
            INTO l_year_begin, l_month_begin, l_day_begin;
        CLOSE c_ref;
    
        g_error       := 'problem begin varchar / ID_REF=' || i_ext_req;
        l_probl_begin := pk_ref_utils.parse_dt_str_app(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       i_year  => l_year_begin,
                                                       i_month => l_month_begin,
                                                       i_day   => l_month_begin);
    
        -- retrieving information       
        g_error := 'DETAIL / ID_REF=' || i_ext_req;
        FOR i IN 1 .. l_detail_text_tab.count
        LOOP
        
            g_error := 'DETAIL_TYPE=' || l_detail_type_tab(i) || ' / ID_REF=' || i_ext_req;
            CASE l_detail_type_tab(i)
            
                WHEN pk_ref_constant.g_detail_type_jstf THEN
                
                    -- reason                
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                    
                        IF l_reason IS NOT NULL
                        THEN
                            l_reason := l_reason || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_reason := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_detail_type_sntm THEN
                
                    -- symptomology                
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                        IF l_sympt IS NOT NULL
                        THEN
                            l_sympt := l_sympt || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_sympt := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_detail_type_evlt THEN
                
                    -- Progress
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                        IF l_progress IS NOT NULL
                        THEN
                            l_progress := l_progress || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_progress := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_detail_type_hstr THEN
                
                    -- History
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                        IF l_hist IS NOT NULL
                        THEN
                            l_hist := l_hist || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_hist := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_detail_type_hstf THEN
                
                    -- Family history
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                        IF l_family_hist IS NOT NULL
                        THEN
                            l_family_hist := l_family_hist || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_family_hist := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_detail_type_obje THEN
                
                    -- Objective exam
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                        IF l_obj_exam IS NOT NULL
                        THEN
                            l_obj_exam := l_obj_exam || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_obj_exam := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_detail_type_cmpe THEN
                    -- Diagnostic exams
                
                    IF l_detail_text_tab(i) IS NOT NULL
                    THEN
                        IF l_compl_exam IS NOT NULL
                        THEN
                            l_compl_exam := l_compl_exam || chr(10) || l_detail_text_tab(i);
                        ELSE
                            l_compl_exam := l_detail_text_tab(i);
                        END IF;
                    
                    END IF;
                
                ELSE
                    g_error := 'DETAIL TYPE ' || l_detail_type_tab(i) || ' not found';
                    RAISE g_exception;
            END CASE;
        
        END LOOP;
    
        g_error := 'PROBLEM / ID_REF=' || i_ext_req;
        FOR i IN 1 .. l_diag_text_tab.count
        LOOP
        
            g_error := 'DIAGNOSIS_TYPE=' || l_diag_type_tab(i) || ' / ID_REF=' || i_ext_req;
            CASE l_diag_type_tab(i)
            
                WHEN pk_ref_constant.g_exr_diag_type_p THEN
                    -- Problems
                    IF l_diag_text_tab(i) IS NOT NULL
                    THEN
                        IF l_prob IS NOT NULL
                        THEN
                            l_prob := l_prob || chr(10) || l_diag_text_tab(i);
                        ELSE
                            l_prob := l_diag_text_tab(i);
                        END IF;
                    
                    END IF;
                
                WHEN pk_ref_constant.g_exr_diag_type_d THEN
                    -- Diagnosis
                    IF l_diag_text_tab(i) IS NOT NULL
                    THEN
                        IF l_diag IS NOT NULL
                        THEN
                            l_diag := l_diag || chr(10) || l_diag_text_tab(i);
                        ELSE
                            l_diag := l_diag_text_tab(i);
                        END IF;
                    
                    END IF;
                
                ELSE
                    g_error := 'DIAGNOSIS TYPE ' || l_diag_type_tab(i) || ' not found / ID_REF=' || i_ext_req;
                    RAISE g_exception;
            END CASE;
        
        END LOOP;
    
        -- formatting justification
        g_error := 'Formatting justification / ID_REF=' || i_ext_req;
        IF l_reason IS NOT NULL
        THEN
            l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t013) || ':' || chr(10) || l_reason;
        END IF;
    
        -- Problems
        g_error := 'Formatting problems / ID_REF=' || i_ext_req;
        IF l_prob IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t030) || ':' ||
                            chr(10) || l_prob;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_doctor_cs_t030) || ':' || chr(10) || l_prob;
            END IF;
        END IF;
    
        -- Problem begin date
        g_error := 'Formatting problem begin date / ID_REF=' || i_ext_req;
        IF l_probl_begin IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t020) || ':' ||
                            chr(10) || l_probl_begin;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t020) || ':' || chr(10) || l_probl_begin;
            END IF;
        END IF;
    
        -- Symptomology
        g_error := 'Formatting symptomology / ID_REF=' || i_ext_req;
        IF l_sympt IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t021) || ':' ||
                            chr(10) || l_sympt;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t021) || ':' || chr(10) || l_sympt;
            END IF;
        END IF;
    
        -- Progress
        g_error := 'Formatting progress / ID_REF=' || i_ext_req;
        IF l_progress IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t022) || ':' ||
                            chr(10) || l_progress;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t022) || ':' || chr(10) || l_progress;
            END IF;
        END IF;
    
        -- History
        g_error := 'Formatting history / ID_REF=' || i_ext_req;
        IF l_hist IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t024) || ':' ||
                            chr(10) || l_hist;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t024) || ':' || chr(10) || l_hist;
            END IF;
        END IF;
    
        -- Family history
        g_error := 'Formatting family history / ID_REF=' || i_ext_req;
        IF l_family_hist IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t025) || ':' ||
                            chr(10) || l_family_hist;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t025) || ':' || chr(10) || l_family_hist;
            END IF;
        END IF;
    
        -- Objective exam
        g_error := 'Formatting objective exam / ID_REF=' || i_ext_req;
        IF l_obj_exam IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t026) || ':' ||
                            chr(10) || l_obj_exam;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t026) || ':' || chr(10) || l_obj_exam;
            END IF;
        END IF;
    
        -- Diagnostic exams
        g_error := 'Formatting diagnostic exams / ID_REF=' || i_ext_req;
        IF l_compl_exam IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t027) || ':' ||
                            chr(10) || l_compl_exam;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t027) || ':' || chr(10) || l_compl_exam;
            END IF;
        END IF;
    
        -- Diagnosis
        g_error := 'Formatting diagnosis / ID_REF=' || i_ext_req;
        IF l_diag IS NOT NULL
        THEN
            IF l_result IS NOT NULL
            THEN
                l_result := l_result || chr(10) || chr(10) || l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t028) || ':' ||
                            chr(10) || l_diag;
            ELSE
                l_result := l_desc_message_ibt(pk_ref_constant.g_sm_p1_detail_t028) || ':' || chr(10) || l_diag;
            END IF;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'PK_P1_INTERFACE.GET_JUSTIFICATION / id_p1=' || i_ext_req || ' / ' || g_error;
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END get_justification;

    /**
    * Gets the previous referral dest institution (when there was a change of institution)
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional id, institution and software
    * @param   i_id_ref          Referral identifier
    * @param   o_id_inst         Institution identifier
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-03-02
    */
    FUNCTION get_prev_dest_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_ref  IN p1_external_request.id_external_request%TYPE,
        o_id_inst OUT p1_external_request.id_inst_dest%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tracking IS
            SELECT t.id_inst_dest id_inst_dest_track, p.id_inst_dest
              FROM p1_tracking t
              JOIN p1_external_request p
                ON (t.id_external_request = p.id_external_request)
             WHERE t.ext_req_status IN (pk_ref_constant.g_p1_status_i, pk_ref_constant.g_p1_status_n)
               AND t.flg_type = pk_ref_constant.g_tracking_type_s
               AND t.id_inst_dest IS NOT NULL
               AND t.id_external_request = i_id_ref
             ORDER BY t.dt_tracking_tstz DESC;
    BEGIN
        g_error := 'Init get_prev_dest_inst / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
    
        FOR i IN c_tracking
        LOOP
            IF i.id_inst_dest_track != i.id_inst_dest
            THEN
            
                -- previous id_inst_dest is not the same as p1_external_request.id_inst_dest (this is the last)
                g_error   := 'ID_INST_DEST_TRACK=' || i.id_inst_dest_track || ' ID_INST_DEST=' || i.id_inst_dest;
                o_id_inst := i.id_inst_dest_track;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PREV_DEST_INST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prev_dest_inst;

BEGIN

    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_p1_interface;
/
