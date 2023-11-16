/*-- Last Change Revision: $Rev: 2014281 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-05-16 10:01:35 +0100 (seg, 16 mai 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_visit IS

    /**
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_institution      institution identification
    * @param i_id_patient          patient identification
    * @param i_id_schedule         schedule identification
    * @param i_id_epis_type        tpye of episode identification
    *
    * @param o_error               error message
    *
    * @return                      true if sucess, false otherwise
    *
    * @author  Eduardo Lourenco
    * @version 2.4.3
    * @since   2008/09/10
    */
    FUNCTION intf_create_scheduled_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_epis_type   IN epis_type.id_epis_type%TYPE,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INTF_CREATE_SCHEDULED_EPISODE';
        RETURN pk_visit.create_visit(i_lang            => i_lang,
                                     i_id_pat          => i_id_patient,
                                     i_id_institution  => i_id_institution,
                                     i_id_sched        => i_id_schedule,
                                     i_id_professional => i_prof,
                                     i_id_episode      => NULL,
                                     i_external_cause  => NULL,
                                     i_health_plan     => NULL,
                                     i_epis_type       => i_id_epis_type,
                                     i_dep_clin_serv   => NULL, -- The dep_clin_serv is assigned to the schedule
                                     i_origin          => NULL,
                                     i_flg_ehr         => pk_ehr_access.g_flg_ehr_scheduled,
                                     i_dt_begin        => current_timestamp,
                                     o_episode         => o_episode,
                                     o_error           => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'INTF_CREATE_SCHEDULED_EPISODE');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
            END;
    END intf_create_scheduled_episode;

    /********************************************************************************************
    * UPDATE epis_ext_sys with the real value and real id_epis_type of the external episode ID
    *
    * i_lang                Language ID,
    * i_id_professional     Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_institution      Institution ID,
    * i_epis_type_old       Episode Type ID,
    * i_epis_ext_value_old  External Episode ID
    * i_epis_type_new       Episode Type ID,
    * i_epis_ext_value_new  External Episode ID
    *
    * @author                      Luís Maia
    * @since                       2009/02/12
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION intf_set_epis_ext_sys
    (
        i_lang               IN language.id_language%TYPE,
        i_id_professional    IN profissional,
        i_id_institution     IN institution.id_institution%TYPE,
        i_epis_type_old      IN epis_ext_sys.id_epis_type%TYPE,
        i_epis_ext_value_old IN epis_ext_sys.value%TYPE,
        i_epis_type_new      IN epis_ext_sys.id_epis_type%TYPE,
        i_epis_ext_value_new IN epis_ext_sys.value%TYPE,
        o_error              OUT t_error_out
        
    ) RETURN BOOLEAN IS
    BEGIN
        -- UPDATE epis_ext_sys with the real value and real id_epis_type of the external episode ID
        g_error := 'UPDATE epis_ext_sys';
        UPDATE epis_ext_sys ees
           SET ees.value = i_epis_ext_value_new, ees.id_epis_type = i_epis_type_new
         WHERE ees.value = i_epis_ext_value_old
           AND ees.id_epis_type = i_epis_type_old
           AND ees.id_institution = i_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'INTF_SET_EPIS_EXT_SYS',
                                                     o_error);
    END intf_set_epis_ext_sys;

    /********************************************************************************************
    * UPDATE epis_ext_sys with the real value and real id_epis_type of the external episode ID
    *
    * i_lang                   Language ID,
    * i_prof                   Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_institution         Institution ID,
    * i_id_episode             Episode ID,
    * i_epis_type_old          Episode Type ID,
    * i_cod_epis_type_ext_old  Episode code type,
    * i_epis_ext_value_old     External Episode ID
    * i_epis_type_new          Episode Type ID,
    * i_epis_ext_value_new     External Episode Type
    * i_cod_epis_type_ext_new  Episode code type,
    *
    * @author                      Rui Duarte
    * @since                       2010/09/14
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION intf_set_epis_ext_sys
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_epis_type_old         IN epis_ext_sys.value%TYPE,
        i_cod_epis_type_ext_old IN epis_ext_sys.cod_epis_type_ext%TYPE,
        i_epis_ext_value_old    IN epis_ext_sys.value%TYPE,
        i_epis_type_new         IN epis_ext_sys.id_epis_type%TYPE,
        i_cod_epis_type_ext_new IN epis_ext_sys.cod_epis_type_ext%TYPE,
        i_epis_ext_value_new    IN epis_ext_sys.value%TYPE,
        o_error                 OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_epis_type          epis_type.id_epis_type%TYPE;
        l_other_id_episode   episode.id_episode%TYPE;
        l_other_id_epis_type episode.id_epis_type%TYPE;
    
        l_inp_id_episode episode.id_episode%TYPE;
        l_id_visit       visit.id_visit%TYPE;
    
        l_current_id_visit visit.id_visit%TYPE;
        l_id_patient       patient.id_patient%TYPE;
        l_rowids           table_varchar;
        l_exception EXCEPTION;
        l_count NUMBER;
    BEGIN
        g_error := 'UPDATE epis_ext_sys';
        UPDATE epis_ext_sys ees
           SET ees.id_epis_type      = i_epis_type_new,
               ees.cod_epis_type_ext = i_cod_epis_type_ext_new,
               ees.value             = i_epis_ext_value_new
         WHERE ees.id_episode = i_id_episode
           AND ees.id_institution = i_id_institution
           AND ees.id_epis_type = i_epis_type_old
           AND ees.cod_epis_type_ext = i_cod_epis_type_ext_old
              --AND ees.value = i_epis_ext_value_old
           AND (ees.value = i_epis_ext_value_old OR ees.value IS NULL);
    
        IF i_epis_type_new = pk_alert_constant.g_epis_type_operating
        THEN
            IF i_epis_ext_value_new IS NOT NULL
            THEN
                SELECT id_visit, id_patient
                  INTO l_current_id_visit, l_id_patient
                  FROM episode e
                 WHERE id_episode = i_id_episode;
            
                -- Search for another episode with the same external value.
                BEGIN
                
                    g_error := 'GET EPISODE COUNT';
                    SELECT ees.id_episode, e.id_visit, e.id_epis_type
                      INTO l_other_id_episode, l_id_visit, l_other_id_epis_type
                      FROM epis_ext_sys ees
                      JOIN episode e
                        ON e.id_episode = ees.id_episode
                     WHERE ees.value = i_epis_ext_value_new
                       AND ees.id_institution = i_id_institution
                       AND ees.id_episode <> nvl(i_id_episode, 0)
                       AND e.id_visit <> l_current_id_visit
                       AND e.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_other_id_episode := NULL;
                END;
            
                IF l_other_id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND l_id_visit IS NOT NULL
                THEN
                    g_error := 'UPDATE INP PREV EPISODE';
                    pk_alertlog.log_debug(g_error);
                    ts_episode.upd(id_episode_in         => i_id_episode,
                                   id_prev_episode_in    => l_other_id_episode,
                                   id_prev_episode_nin   => FALSE,
                                   id_visit_in           => l_id_visit,
                                   id_prev_epis_type_in  => l_other_id_epis_type,
                                   id_prev_epis_type_nin => FALSE,
                                   rows_out              => l_rowids);
                
                    g_error := 'PROCESS UPDATE - EPISODE';
                    pk_alertlog.log_debug(g_error);
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPISODE',
                                                  i_rowids       => l_rowids,
                                                  i_list_columns => table_varchar('ID_PREV_EPISODE',
                                                                                  'ID_PREV_EPIS_TYPE',
                                                                                  'ID_VISIT'),
                                                  o_error        => o_error);
                
                    l_rowids := table_varchar();
                    -- Permanently delete previous visit record
                    SELECT COUNT(1)
                      INTO l_count
                      FROM episode e
                     WHERE id_visit = l_current_id_visit;
                    IF l_count = 0
                    THEN
                        g_error := 'CALL pk_vital_sign.merge_vs_visit_ea_dup';
                        IF NOT pk_vital_sign.merge_vs_visit_ea_dup(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_patient        => l_id_patient,
                                                                   i_id_visit       => l_id_visit,
                                                                   i_other_id_visit => l_current_id_visit,
                                                                   o_error          => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                        UPDATE task_timeline_ea
                           SET id_visit = l_id_visit
                         WHERE id_episode = i_id_episode
                           AND id_visit = l_current_id_visit;
                    
                        g_error := 'DELETE OLD VISIT';
                        ts_visit.del(id_visit_in => l_current_id_visit, rows_out => l_rowids);
                    
                        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'VISIT',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                    END IF;
                
                END IF;
            END IF;
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
                                                     'INTF_SET_EPIS_EXT_SYS',
                                                     o_error);
    END intf_set_epis_ext_sys;

    /********************************************************************************************
    * Criar ou actualizar a informação do episódio
    *
    * @param i_lang                language id
    * @param i_rec_epis_ext        Registo dos dados do episódio externo
    * @param i_rec_episode         Registo dos dados do episódio
    * @param i_epis_type           Tipo de episódio
    * @param i_institution         ID da instituição onde é realizada a criação/actualização do episódio
    * @param i_transaction_id       SCH 3.0 transaction id
    * @param o_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Emília Taborda
    * @since                       2007/01/09
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_pfh
    (
        i_lang           IN language.id_language%TYPE,
        i_rec_epis_ext   IN rec_epis_ext_sys,
        i_rec_episode    IN rec_episode,
        i_epis_type      IN epis_type.id_epis_type%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_EPISODE_PFH';
        l_ret         BOOLEAN;
        l_epis_ext_id NUMBER;
        --
        l_prof        profissional;
        l_char        VARCHAR2(1);
        l_health_plan health_plan.id_health_plan%TYPE;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
        --
        l_flg_show                VARCHAR2(1);
        l_msg_title               sys_message.desc_message%TYPE;
        l_msg_body                sys_message.desc_message%TYPE;
        l_id_epis_prof_resp       epis_prof_resp.id_epis_prof_resp%TYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
    
        CURSOR c_epis_ext IS
            SELECT 'X'
              FROM epis_ext_sys ees, episode epis
             WHERE ees.value = i_rec_epis_ext.id_ext_episode
               AND ees.id_institution = i_institution
               AND ees.id_episode = epis.id_episode
               AND epis.flg_status IN (g_status_act, g_status_ina)
               AND epis.id_epis_type = i_rec_episode.id_epis_type
               AND ees.id_institution IN
                   (SELECT column_value id_institution
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_institution, g_inst_grp_flg_rel_adt)));
    
        CURSOR c_health_plan IS
            SELECT id_health_plan
              FROM pat_health_plan
             WHERE id_patient = i_rec_episode.id_patient
               AND flg_default = g_flg_default
               AND id_institution = i_institution;
    BEGIN
        l_prof := profissional(i_rec_episode.id_professional, i_rec_episode.id_institution, i_rec_episode.id_software);
        --
        g_error := 'OPEN C_EPIS_EXT';
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN c_epis_ext;
        FETCH c_epis_ext
            INTO l_char;
        g_found := c_epis_ext%FOUND;
        CLOSE c_epis_ext;
        --
        IF g_found
        THEN
            RETURN FALSE;
        ELSE
            IF i_rec_episode.id_health_plan IS NULL
            THEN
                g_error := 'OPEN c_health_plan';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                OPEN c_health_plan;
                FETCH c_health_plan
                    INTO l_health_plan;
                CLOSE c_health_plan;
            ELSE
                l_health_plan := i_rec_episode.id_health_plan;
            END IF;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id);
        
            --
            g_error := 'CALL pk_visit.create_visit';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_ret := pk_visit.call_create_visit(i_lang                 => i_lang,
                                                i_id_pat               => i_rec_episode.id_patient,
                                                i_id_institution       => i_institution,
                                                i_id_sched             => i_rec_episode.id_schedule,
                                                i_id_professional      => l_prof,
                                                i_id_episode           => i_rec_episode.id_episode,
                                                i_external_cause       => i_rec_episode.id_external_cause,
                                                i_health_plan          => l_health_plan,
                                                i_epis_type            => i_rec_episode.id_epis_type,
                                                i_dep_clin_serv        => i_rec_episode.id_dep_clin_serv,
                                                i_origin               => i_rec_episode.id_origin,
                                                i_flg_ehr              => nvl(i_rec_episode.flg_ehr, 'N'),
                                                i_dt_begin             => i_rec_episode.dt_begin_tstz,
                                                i_flg_appointment_type => i_rec_episode.flg_appointment_type,
                                                i_transaction_id       => l_transaction_id,
                                                i_ext_value            => i_rec_epis_ext.id_ext_episode,
                                                i_flg_unknown          => i_rec_episode.flg_unknown,
                                                o_episode              => o_episode,
                                                o_error                => o_error);
        
            IF l_ret = FALSE
            THEN
                RETURN FALSE;
            ELSE
                g_error := 'PK_API_VISIT.SET_EPIS_EXT_SYS';
                IF NOT pk_api_visit.set_epis_ext_sys(i_lang         => i_lang,
                                                     i_external_sys => i_rec_epis_ext.id_external_sys,
                                                     i_ext_episode  => i_rec_epis_ext.id_ext_episode,
                                                     i_epis_type    => i_epis_type,
                                                     i_institution  => i_institution,
                                                     i_episode      => o_episode,
                                                     o_epis_ext_sys => l_epis_ext_id,
                                                     o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                g_error := 'PK_VISIT.UPDATE_EPIS_INFO_NO_OBS';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (i_rec_episode.id_room IS NOT NULL)
                THEN
                    IF NOT pk_visit.update_epis_info_no_obs(i_lang         => i_lang,
                                                            i_id_episode   => o_episode,
                                                            i_id_room      => i_rec_episode.id_room,
                                                            i_bed          => NULL,
                                                            i_norton       => NULL,
                                                            i_professional => NULL,
                                                            i_flg_hydric   => NULL,
                                                            i_flg_wound    => NULL,
                                                            i_companion    => NULL,
                                                            i_flg_unknown  => NULL,
                                                            i_desc_info    => NULL,
                                                            i_prof         => profissional(0,
                                                                                           i_institution,
                                                                                           pk_episode.get_soft_by_epis_type(i_epis_type,
                                                                                                                            i_institution)),
                                                            o_error        => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                IF i_rec_episode.dt_arrival IS NOT NULL
                THEN
                    g_error := 'INSERT EPIS_INTAKE_TIME';
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    ts_epis_intake_time.ins(id_episode_in      => o_episode,
                                            dt_register_in     => current_timestamp,
                                            id_patient_in      => i_rec_episode.id_patient,
                                            id_professional_in => i_rec_episode.id_professional,
                                            dt_intake_time_in  => i_rec_episode.dt_arrival);
                END IF;
            
                IF i_rec_episode.id_prof_resp IS NOT NULL
                THEN
                    g_error := 'PK_HAND_OFF_CORE.CALL_SET_OVERALL_RESP';
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                                  i_prof                    => l_prof,
                                                                  i_id_episode              => o_episode,
                                                                  i_id_prof_resp            => i_rec_episode.id_prof_resp,
                                                                  i_id_speciality           => pk_prof_utils.get_prof_speciality_id(i_lang => i_lang,
                                                                                                                                    i_prof => profissional(i_rec_episode.id_prof_resp,
                                                                                                                                                           i_institution,
                                                                                                                                                           pk_episode.get_soft_by_epis_type(i_epis_type,
                                                                                                                                                                                            i_institution))),
                                                                  i_notes                   => NULL,
                                                                  i_dt_reg                  => current_timestamp,
                                                                  o_flg_show                => l_flg_show,
                                                                  o_msg_title               => l_msg_title,
                                                                  o_msg_body                => l_msg_body,
                                                                  o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                                  o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                  o_error                   => o_error)
                    THEN
                        RETURN FALSE; -- direct return in order to keep possible user error messages
                    END IF;
                END IF;
            END IF;
            --remote scheduler commit. Doesn't affect PFH.
            IF i_transaction_id IS NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id);
            END IF;
            --
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPISODE_PFH',
                                                     o_error);
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
    END;
    --

    /********************************************************************************************
    * Criar ou actualizar a informação do episódio
    *
    * @param i_lang                language id
    * @param i_epis_type           Tipo de episodio
    * @param i_institution         ID da instituicao onde e realizada a criacao/actualizacao do episodio
    * @param i_professional        Professional ID
    * @param i_software            Software ID
    * @param i_patient             Patient ID
    * @param i_episode             Episode ID
    * @param i_ext_episode         External Episode ID
    * @param i_external_sys        External System ID
    * @param i_health_plan         Health Plan ID
    * @param i_schedule            Schedule ID
    * @param i_flg_ehr             Electronic Health Record Flag
    * @param i_origin              Origin of the episode
    * @param i_dt_begin            Begin date
    * @param i_dep_clin_serv       Department Clinical Service
    * @param i_external_cause      ID of external cause
    * @param i_transaction_id       SCH 3.0 transaction id
    * @param o_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2007/02/04
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_pfh
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_type      IN epis_type.id_epis_type%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_professional   IN professional.id_professional%TYPE,
        i_software       IN software.id_software%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_ext_episode    IN epis_ext_sys.value%TYPE,
        i_external_sys   IN external_sys.id_external_sys%TYPE,
        i_health_plan    IN health_plan.id_health_plan%TYPE,
        i_schedule       IN epis_info.id_schedule%TYPE,
        i_flg_ehr        IN episode.flg_ehr%TYPE,
        i_origin         IN origin.id_origin%TYPE,
        i_dt_begin       IN episode.dt_begin_tstz%TYPE,
        i_dep_clin_serv  IN epis_info.id_dep_clin_serv%TYPE,
        i_external_cause IN visit.id_external_cause%TYPE,
        i_dt_arrival     IN epis_intake_time.dt_intake_time%TYPE DEFAULT NULL,
        i_prof_resp      IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        i_flg_unknown    IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN PLS_INTEGER IS
    
        i_rec_epis_ext rec_epis_ext_sys;
        i_rec_episode  rec_episode;
    
        vresult BOOLEAN := FALSE;
        mytrue  CONSTANT PLS_INTEGER := 1;
        myfalse CONSTANT PLS_INTEGER := 0;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        i_rec_epis_ext.id_episode      := NULL;
        i_rec_epis_ext.id_ext_episode  := i_ext_episode;
        i_rec_epis_ext.id_external_sys := i_external_sys;
        i_rec_epis_ext.id_institution  := NULL;
    
        i_rec_episode.id_episode        := i_episode;
        i_rec_episode.id_epis_type      := i_epis_type;
        i_rec_episode.id_institution    := i_institution;
        i_rec_episode.id_software       := i_software;
        i_rec_episode.id_schedule       := i_schedule;
        i_rec_episode.id_professional   := i_professional;
        i_rec_episode.id_external_cause := i_external_cause;
        i_rec_episode.id_prof_cancel    := NULL;
        i_rec_episode.dt_cancel         := NULL;
        i_rec_episode.dt_cancel_tstz    := NULL;
        i_rec_episode.id_patient        := i_patient;
        i_rec_episode.id_room           := NULL;
        i_rec_episode.id_origin         := i_origin;
        i_rec_episode.flg_unknown       := i_flg_unknown;
        i_rec_episode.nr_companion      := NULL;
        i_rec_episode.id_health_plan    := i_health_plan;
        i_rec_episode.id_dep_clin_serv  := i_dep_clin_serv;
        i_rec_episode.dt_arrival        := i_dt_arrival;
        i_rec_episode.id_prof_resp      := i_prof_resp;
        --        i_rec_episode.episode_ext       := t_tbl_epis_ext();
        i_rec_episode.dt_begin_tstz := i_dt_begin;
        i_rec_episode.flg_ehr       := i_flg_ehr;
    
        --i_rec_episode.episode_ext := t_tbl_epis_ext();
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id);
    
        vresult := set_episode_pfh(i_lang => i_lang,
                                   
                                   i_rec_epis_ext   => i_rec_epis_ext,
                                   i_rec_episode    => i_rec_episode,
                                   i_epis_type      => i_epis_type,
                                   i_institution    => i_institution,
                                   i_transaction_id => l_transaction_id,
                                   o_episode        => o_episode,
                                   o_error          => o_error);
    
        IF vresult
        THEN
            IF i_transaction_id IS NULL
            THEN
                pk_schedule_api_upstream.do_commit(i_id_transaction => l_transaction_id);
            END IF;
            RETURN mytrue;
        ELSE
            IF i_transaction_id IS NULL
            THEN
                pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id);
            END IF;
            RETURN myfalse;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPISODE_PFH',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            pk_utils.undo_changes;
            RETURN myfalse;
    END set_episode_pfh;

    /********************************************************************************************
    * Inserts a new record on epis_ext_sys
    *
    * @param i_lang                language id
    * @param i_external_sys        external system id
    * @param i_ext_episode         external episode id
    * @param i_epis_type           Tipo de episódio
    * @param i_institution         ID da instituição onde é realizada a criação/actualização do episódio
    * @param i_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       30-09-2009
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_epis_ext_sys
    (
        i_lang         IN language.id_language%TYPE,
        i_external_sys IN epis_ext_sys.id_external_sys%TYPE,
        i_ext_episode  IN epis_ext_sys.value%TYPE,
        i_epis_type    IN epis_type.id_epis_type%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_epis_ext_sys OUT epis_ext_sys.id_epis_ext_sys%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_ext_id     NUMBER;
        l_id_epis_ext_sys epis_ext_sys.id_epis_ext_sys%TYPE;
        l_exception EXCEPTION;
    
        CURSOR c_epis_ext IS
            SELECT ees.id_epis_ext_sys
              FROM epis_ext_sys ees, episode epis
             WHERE ees.id_episode = i_episode
               AND ees.id_episode = epis.id_episode
               AND epis.flg_status IN (g_status_act, g_status_ina)
               AND epis.id_epis_type = i_epis_type
               AND ees.id_institution = i_institution;
    
    BEGIN
        --
        OPEN c_epis_ext;
        FETCH c_epis_ext
            INTO l_id_epis_ext_sys;
        g_found := c_epis_ext%NOTFOUND;
        CLOSE c_epis_ext;
        --
        IF g_found
        THEN
            g_error := 'GET seq_epis_ext_sys';
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT seq_epis_ext_sys.nextval
              INTO l_epis_ext_id
              FROM dual;
            --
            g_error := 'INSERT epis_ext_sys';
            pk_alertlog.log_debug(g_error, g_package_name);
            INSERT INTO epis_ext_sys
                (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            VALUES
                (l_epis_ext_id,
                 i_external_sys,
                 i_episode,
                 i_ext_episode,
                 i_institution,
                 i_epis_type,
                 decode(i_epis_type, 1, 'CON', 2, 'URG', 5, 'INT', 6, 'INT', 4, 'INT', 'XXX'));
            --
            o_epis_ext_sys := l_epis_ext_id;
        ELSIF l_id_epis_ext_sys IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_EXT_SYS';
            UPDATE epis_ext_sys es
               SET es.id_external_sys = i_external_sys, es.value = i_ext_episode
             WHERE es.id_epis_ext_sys = l_id_epis_ext_sys;
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
                                                     'SET_EPIS_EXT_SYS',
                                                     o_error);
    END set_epis_ext_sys;

    /**
    * Cancels a patient's registration.
    * The episode is changed to a 'scheduled' state (FLG_EHR = 'S').
    *
    * This function is the migration of PK_PFH_INTERFACE.INTF_CANCEL_EPISODE
    * for the cancellation of Ambulatory episodes (OUTP, PP, CARE).
    *
    * @param i_lang            language identifier
    * @param i_id_episode      episode identifier
    * @param i_prof            professional identification
    * @param i_cancel_reason   motive of cancellation
    * @param o_error           error message
    *
    * @return                  false, if errors occur, or true, otherwise
    *
    * @author                  Pedro Carneiro
    * @version                  2.5.0.7.6.1
    * @since                   2010/02/10
    */
    FUNCTION intf_cancel_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN episode.desc_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_visit.call_cancel_episode(i_lang          => i_lang,
                                            i_id_episode    => i_id_episode,
                                            i_prof          => i_prof,
                                            i_cancel_reason => i_cancel_reason,
                                            i_cancel_type   => pk_visit.g_cancel_efectiv,
                                            o_error         => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INTF_CANCEL_EPISODE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_cancel_episode;

    /**
    * Cancels an episode.
    * The episode status is set to 'cancelled', and it will have further use (FLG_STATUS = 'C').
    *
    * This function is the migration of PK_PFH_INTERFACE.INTF_CANCEL_SCHED_EPISODE
    * for the cancellation of Ambulatory episodes (OUTP, PP, CARE).
    *
    * @param i_lang            language identifier
    * @param i_id_episode      episode identifier
    * @param i_prof            professional identification
    * @param i_transaction_id  Scheduller 3 transsaction id
    * @param o_error           error message
    *
    * @return                  false, if errors occur, or true, otherwise
    *
    * @author                  Pedro Carneiro
    * @version                  2.5.0.7.6.1
    * @since                   2010/02/10
    */
    FUNCTION intf_cancel_sched_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        RETURN pk_visit.call_cancel_episode(i_lang           => i_lang,
                                            i_id_episode     => i_id_episode,
                                            i_prof           => i_prof,
                                            i_cancel_reason  => NULL,
                                            i_cancel_type    => pk_visit.g_cancel_sched_epis,
                                            i_transaction_id => i_transaction_id,
                                            o_error          => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INTF_CANCEL_SCHED_EPISODE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_cancel_sched_episode;

    /********************************************************************************************
    * Convert a schedule episode (flg_ehr = 'S') to a normal episode (flg_ehr = 'N')
    * and updates epis_ext_sys external episode
    *
    * i_lang            Language ID,
    * i_id_pat          Patient ID,
    * i_id_institution  Institution ID,
    * i_id_sched        Schedule ID,
    * i_id_professional Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_episode      Episode ID,
    * i_epis_type       Episode Type ID,
    * i_epis_ext_value  External Episode ID
    *
    * @author                      Sérgio Santos
    * @since                       2008/11/05
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_sched_to_normal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_epis_ext_value  IN epis_ext_sys.value%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id);
    
        --update epis_ext_sys with the real value of the external episode ID
        g_error := 'UPDATE epis_ext_sys';
        UPDATE epis_ext_sys ees
           SET ees.value = i_epis_ext_value
         WHERE ees.id_episode = i_id_episode
           AND ees.id_institution = i_id_institution;
    
        --Register the episode
        g_error := 'CALL CALL_CREATE_VISIT';
        IF NOT pk_visit.call_create_visit(i_lang                 => i_lang,
                                          i_id_pat               => i_id_pat,
                                          i_id_institution       => i_id_institution,
                                          i_id_sched             => i_id_sched,
                                          i_id_professional      => i_id_professional,
                                          i_id_episode           => i_id_episode,
                                          i_external_cause       => NULL,
                                          i_health_plan          => NULL,
                                          i_epis_type            => i_epis_type,
                                          i_dep_clin_serv        => NULL,
                                          i_origin               => NULL,
                                          i_flg_ehr              => 'N',
                                          i_flg_appointment_type => NULL,
                                          i_transaction_id       => l_transaction_id,
                                          o_episode              => o_episode,
                                          o_error                => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --Commit changes made
        COMMIT;
        --remote scheduler commit. Doesn't affect PFH.
        pk_schedule_api_upstream.do_commit(l_transaction_id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPISODE_SCHED_TO_NORMAL',
                                                     o_error);
        
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            pk_utils.undo_changes;
    END;

    /********************************************************************************************
    * Returns the episode intake time
    *
    * @param i_lang                language id
    * @param i_prof                Profissional
    * @param i_id_episode          Episode ID
    * @param o_dt_intake_time      Intake Time
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Sergio Dias
    * @since                       10-07-2013
    * @version                     2.6.3.6
    **********************************************************************************************/
    FUNCTION get_dt_intake_time(i_id_episode IN episode.id_episode%TYPE) RETURN epis_intake_time.dt_intake_time%TYPE IS
        l_dt_intake_time epis_intake_time.dt_intake_time%TYPE;
    BEGIN
    
        BEGIN
            SELECT dt_intake_time
              INTO l_dt_intake_time
              FROM (SELECT eit.dt_intake_time
                      FROM epis_intake_time eit
                     WHERE eit.id_episode = i_id_episode
                     ORDER BY eit.dt_register DESC) a
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_intake_time := NULL;
        END;
    
        RETURN l_dt_intake_time;
    END;

    FUNCTION get_dt_intake_time
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_dt_intake_time OUT epis_intake_time.dt_intake_time%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DT_INTAKE_TIME';
    BEGIN
    
        g_error := 'GET EPIS_INTAKE_TIME RECORD';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        o_dt_intake_time := get_dt_intake_time(i_id_episode);
    
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
    END get_dt_intake_time;

    /**********************************************************************************************
    * DATABASE INTERNAL FUNCION. Register the data about the arrival of the patient.
    *
    * @param i_lang              the id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_epis           episode id        
    * @param i_dt_transportation Data do transporte
    * @param i_id_transp_entity  Transporte entidade
    * @param i_flg_time          E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes             Notes
    * @param i_origin            Origem
    * @param i_external_cause    external cause
    * @param i_companion         acompanhante
    * @param i_internal_type     Called from (A) Arrived by (T) Triage
    * @param i_sysdate           Current date
    * @param o_error             Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise                            
    *
    * @author                   José Brito (using SET_ARRIVE by Luís Gaspar)
    * @version                  2.6.0
    * @since                    2009/12/07
    **********************************************************************************************/
    FUNCTION update_episode_pfh
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN visit.id_origin%TYPE,
        i_external_cause        IN visit.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        i_internal_type         IN VARCHAR2, -- (A) Arrived by (T) Triage
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_resp          IN epis_multi_prof_resp.id_professional%TYPE,
        i_dt_intake_time        IN epis_intake_time.dt_intake_time%TYPE,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'UPDATE_EPISODE_PFH';
        l_exception EXCEPTION;
    
        l_dt_first_obs        epis_info.dt_first_obs_tstz%TYPE;
        l_dt_discharge        discharge.dt_med_tstz%TYPE;
        l_save_dt_intake_time BOOLEAN := TRUE;
        l_id_transportation   transportation.id_transportation%TYPE;
    BEGIN
        g_error := 'CALL PK_EDIS_PROC.set_arrive_internal';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_edis_proc.set_arrive_internal(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_id_epis               => i_id_epis,
                                                i_dt_transportation_str => i_dt_transportation_str,
                                                i_id_transp_entity      => i_id_transp_entity,
                                                i_flg_time              => i_flg_time,
                                                i_notes                 => i_notes,
                                                i_origin                => i_origin,
                                                i_external_cause        => i_external_cause,
                                                i_companion             => i_companion,
                                                i_internal_type         => i_internal_type,
                                                i_sysdate               => i_sysdate,
                                                i_dep_clin_serv         => i_dep_clin_serv,
                                                o_id_transportation     => l_id_transportation,
                                                o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_id_prof_resp IS NOT NULL
        THEN
            g_error := 'CALL PK_HAND_OFF_CORE.override_main_responsible';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_hand_off_core.override_main_responsible(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_id_episode   => i_id_epis,
                                                              i_id_prof_resp => i_id_prof_resp,
                                                              o_error        => o_error)
            THEN
                RETURN FALSE; -- direct return in order to keep possible user error messages
            END IF;
        END IF;
    
        IF i_dt_intake_time IS NOT NULL
        THEN
            BEGIN
                g_error := 'GET DT_FIRST_OBS';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
            
                SELECT pk_episode.get_epis_dt_first_obs(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_episode   => i_id_epis,
                                                        i_dt_first_obs => ei.dt_first_obs_tstz) dt_first_obs
                  INTO l_dt_first_obs
                  FROM epis_info ei
                 WHERE ei.id_episode = i_id_epis;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
            BEGIN
                g_error := 'GET DT_DISCHARGE';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
            
                SELECT d.dt_med_tstz
                  INTO l_dt_discharge
                  FROM discharge d
                 WHERE d.id_episode = i_id_epis
                   AND d.flg_status = pk_alert_constant.g_active;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
            IF l_dt_first_obs IS NOT NULL
               AND l_dt_first_obs < i_dt_intake_time
            THEN
                g_error := 'INTAKE DATE CAN''T BE MORE RECENT THAN FIRST OBSERVATION DATE';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                l_save_dt_intake_time := FALSE;
            END IF;
        
            IF l_dt_discharge IS NOT NULL
               AND l_dt_discharge < i_dt_intake_time
            THEN
                g_error := 'INTAKE DATE CAN''T BE MORE RECENT THAN DISCHARGE DATE';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
                l_save_dt_intake_time := FALSE;
            END IF;
        
            IF l_save_dt_intake_time = TRUE
            THEN
                g_error := 'INSERT EPIS_INTAKE_TIME';
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => g_package_name,
                                               sub_object_name => l_func_name);
            
                ts_epis_intake_time.ins(id_episode_in      => i_id_epis,
                                        dt_register_in     => current_timestamp,
                                        id_patient_in      => pk_episode.get_epis_patient(i_lang    => i_lang,
                                                                                          i_prof    => i_prof,
                                                                                          i_episode => i_id_epis),
                                        id_professional_in => i_prof.id,
                                        dt_intake_time_in  => i_dt_intake_time);
            ELSE
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              'The arrival date can''t be more recent than the discharge or first observation dates. ' ||
                                              i_dt_intake_time || ' - ' || l_dt_discharge || ' - ' || l_dt_first_obs,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_episode_pfh;

    /** Used only to prevent decompile. Do not use */
    FUNCTION set_episode_sched_to_normal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_epis_ext_value  IN epis_ext_sys.value%TYPE,
        o_episode         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_api_visit.set_episode_sched_to_normal(i_lang            => i_lang,
                                                        i_id_pat          => i_id_pat,
                                                        i_id_institution  => i_id_institution,
                                                        i_id_sched        => i_id_sched,
                                                        i_id_professional => i_id_professional,
                                                        i_id_episode      => i_id_episode,
                                                        i_epis_type       => i_epis_type,
                                                        i_epis_ext_value  => i_epis_ext_value,
                                                        i_transaction_id  => NULL,
                                                        o_episode         => o_episode,
                                                        o_error           => o_error);
    
    END set_episode_sched_to_normal;

    FUNCTION get_patient_active_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_lst_episodes OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT id_episode
          BULK COLLECT
          INTO o_lst_episodes
          FROM episode e
         WHERE e.id_institution = i_prof.institution
           AND e.id_patient = i_id_patient
           AND e.flg_status = pk_alert_constant.g_active
           AND e.flg_ehr = pk_alert_constant.g_flg_ehr_n;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_ACTIVE_EPISODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_patient_active_episode;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_status_act := 'A';
    g_status_ina := 'I';

    g_inst_grp_flg_rel_adt := 'ADT';
    g_flg_default          := 'Y';

END pk_api_visit;
/
