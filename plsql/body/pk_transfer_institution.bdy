/*-- Last Change Revision: $Rev: 2027810 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_transfer_institution IS

    g_package_name VARCHAR2(32);

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
    
    BEGIN
    
        o_error.err_desc := g_package_name || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package_name,
                                        name3_in      => 'FUNCTION',
                                        value3_in     => i_func_proc_name);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    FUNCTION error_handling_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlcode        IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        i_flg_action     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error_in.set_all(i_lang,
                           i_sqlcode,
                           i_sqlerror,
                           i_error,
                           'ALERT',
                           g_package_name,
                           i_func_proc_name,
                           NULL,
                           i_flg_action);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling_ext;

    /********************************************************************************************
    * Creates an institution transfer request (internal function)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_id_institution_orig    Institution ID from which the patient leaves
    * @param i_id_institution_dest    Institution ID in which the patient arrives
    * @param i_id_transp_entity       Transport ID to be used during the transfer
    * @param i_notes                  Request notes
    * @param i_id_dep_clin_serv       Clinical service ID           
    * @param i_id_transfer_option     Transfer reason selected during the request
    * @param o_dt_creation            Creation date of current institution transfer request
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          21/04/2008
    *
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          28/09/2009
    * @dependencies                   INTERFACES TEAM (PK_API_EDIS)
    **********************************************************************************************/

    FUNCTION create_transfer_inst_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_institution_orig IN transfer_institution.id_institution_origin%TYPE,
        i_id_institution_dest IN transfer_institution.id_institution_dest%TYPE,
        i_id_transp_entity    IN transfer_institution.id_transp_entity%TYPE,
        i_notes               IN transfer_institution.notes%TYPE,
        i_id_dep_clin_serv    IN transfer_institution.id_dep_clin_serv%TYPE,
        i_id_transfer_option  IN transfer_institution.id_transfer_option%TYPE,
        o_dt_creation         OUT transfer_institution.dt_creation_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_creation_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_err_visit        EXCEPTION;
        l_msg_visit        sys_message.desc_message%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        l_num NUMBER;
    
        CURSOR c_episode IS
            SELECT 0
              FROM episode e
             WHERE e.id_prev_episode = i_id_episode
               AND pk_episode.get_soft_by_epis_type(e.id_epis_type, i_prof.institution) = i_prof.software
               AND e.flg_status <> g_epis_cancel;
    
    BEGIN
    
        g_error     := 'GET ERROR MESSAGES';
        l_msg_visit := pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_M002');
    
        g_error            := 'TRUNC TIMESTAMP';
        l_dt_creation_tstz := to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                                 current_timestamp,
                                                                                 g_dateformat),
                                              g_dateformat);
    
        IF check_episodes_for_visit(i_id_episode => i_id_episode) = pk_alert_constant.g_no
        THEN
            g_error := 'INSERT INTO TRANSFER INSTITUTION';
            IF NOT t_transfer_institution.ins_transfer_institution(i_lang,
                                                                   i_prof,
                                                                   i_id_episode,
                                                                   l_dt_creation_tstz,
                                                                   i_id_patient,
                                                                   i_id_institution_orig,
                                                                   i_id_institution_dest,
                                                                   i_id_transp_entity,
                                                                   i_notes,
                                                                   g_transfer_inst_req,
                                                                   i_id_dep_clin_serv,
                                                                   i_id_transfer_option,
                                                                   l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE EPIS_INFO';
            IF NOT pk_fast_track.set_epis_info_fast_track(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode,
                                                          o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            RAISE l_err_visit;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_dt_creation := l_dt_creation_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_err_visit THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_TRANSFER_INST_INT',
                                      '',
                                      'TRANSFER_INSTITUTION_M002',
                                      l_msg_visit,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_TRANSFER_INST_INT',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_TRANSFER_INST_INT',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
    END create_transfer_inst_int;

    /********************************************************************************************
    * Creates an institution transfer request
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_id_institution_orig    Institution ID from which the patient leaves
    * @param i_id_institution_dest    Institution ID in which the patient arrives
    * @param i_id_transp_entity       Transport ID to be used during the transfer
    * @param i_notes                  Request notes
    * @param i_id_dep_clin_serv       Clinical service ID           
    * @param i_id_transfer_option     Transfer reason selected during the request   
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          21/04/2008
    **********************************************************************************************/

    FUNCTION create_transfer_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_institution_orig IN transfer_institution.id_institution_origin%TYPE,
        i_id_institution_dest IN transfer_institution.id_institution_dest%TYPE,
        i_id_transp_entity    IN transfer_institution.id_transp_entity%TYPE,
        i_notes               IN transfer_institution.notes%TYPE,
        i_id_dep_clin_serv    IN transfer_institution.id_dep_clin_serv%TYPE,
        i_id_transfer_option  IN transfer_institution.id_transfer_option%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_err_visit   EXCEPTION;
        l_exception   EXCEPTION;
        l_dt_creation transfer_institution.dt_creation_tstz%TYPE;
    BEGIN
        g_error := 'CALL TO CREATE_TRANSFER_INST_INT';
        IF NOT create_transfer_inst_int(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_episode          => i_id_episode,
                                        i_id_patient          => i_id_patient,
                                        i_id_institution_orig => i_id_institution_orig,
                                        i_id_institution_dest => i_id_institution_dest,
                                        i_id_transp_entity    => i_id_transp_entity,
                                        i_notes               => i_notes,
                                        i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                        i_id_transfer_option  => i_id_transfer_option,
                                        o_dt_creation         => l_dt_creation,
                                        o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'CREATE_TRANSFER_INST', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END create_transfer_inst;

    /********************************************************************************************
    * Cancels an institution transfer request
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date
    * @param i_notes_cancel           Cancellation notes
    * @param i_id_cancel_reason       Cancel reason ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          21/04/2008
    **********************************************************************************************/

    FUNCTION cancel_transfer_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN transfer_institution.id_episode%TYPE,
        i_dt_creation      IN VARCHAR2,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL CANCEL_TRANSFER_INST_INT FUNCTION';
        pk_alertlog.log_debug(g_error);
        IF NOT cancel_transfer_inst_int(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_episode          => i_episode,
                                        i_dt_creation      => i_dt_creation,
                                        i_notes_cancel     => i_notes_cancel,
                                        i_id_cancel_reason => i_id_cancel_reason,
                                        o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_TRANSFER_INST',
                                      g_error || ' / ' || o_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'CANCEL_TRANSFER_INST', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END cancel_transfer_inst;

    /********************************************************************************************
    * Updates an institution transfer request
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date
    * @param i_dt_update              Begin or end date of the institution transfer
    * @param i_flg_status             New status of the institution transfer
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    * @dependencies                   INTERFACES TEAM (PK_API_EDIS)
    **********************************************************************************************/
    FUNCTION update_transfer_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN transfer_institution.id_episode%TYPE,
        i_dt_creation IN VARCHAR2,
        i_dt_update   IN VARCHAR2,
        i_flg_status  IN transfer_institution.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_room             room.id_room%TYPE;
        l_id_visit            visit.id_visit%TYPE;
        l_next_epis_inst      NUMBER;
        l_id_patient          patient.id_patient%TYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_id_department       department.id_department%TYPE;
        l_id_dept             dept.id_dept%TYPE;
        l_id_inst             institution.id_institution%TYPE;
        l_dt_creation_tstz    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_update_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_message_cancel CONSTANT sys_message.code_message%TYPE := 'TRANSFER_INSTITUTION_M001';
        l_can_refresh_mviews BOOLEAN := FALSE;
        l_add_alert CONSTANT VARCHAR2(1 CHAR) := 'A';
    
        no_mov_cancel    EXCEPTION;
        wrong_dt_begin   EXCEPTION;
        l_code_dt_begin  sys_message.code_message%TYPE;
        l_msg_dt_begin   sys_message.desc_message%TYPE;
        l_msg_mov_cancel sys_message.desc_message%TYPE;
    
        l_rank NUMBER;
        l_ret  BOOLEAN;
    
        l_cur_epis_type sys_config.value%TYPE;
        l_epis_type_inp CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_prof);
    
        l_exam_room exam_room.id_room%TYPE;
    
        l_id_software software.id_software%TYPE;
    
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
        l_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        CURSOR c_room IS
            SELECT pr.id_room
              FROM prof_room pr
             WHERE pr.id_professional = i_prof.id
               AND pr.id_room IN (SELECT r.id_room
                                    FROM room r, department d, software_dept sd
                                   WHERE d.id_department = r.id_department
                                     AND d.id_institution = l_id_inst
                                     AND sd.id_dept = d.id_dept
                                     AND l_id_software IN (sd.id_software, 0))
               AND pr.flg_pref = g_room_pref;
    
        CURSOR c_epis_room
        (
            l_epis_type     IN epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type et, epis_type_room er
             WHERE et.id_epis_type = l_epis_type
               AND er.id_epis_type = et.id_epis_type
               AND er.id_institution = i_prof.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION
            SELECT er.id_room, 1 rank
              FROM epis_type et, epis_type_room er
             WHERE et.id_epis_type = l_epis_type
               AND er.id_epis_type = et.id_epis_type
               AND er.id_institution = i_prof.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv
             ORDER BY rank DESC;
    
        CURSOR c_movement IS
            SELECT m.id_movement
              FROM movement m
             WHERE m.id_episode = i_episode
               AND m.flg_status IN (g_mov_transp, g_mov_pend, g_mov_req);
    
        CURSOR c_exam IS
            SELECT er.id_exam_req, erd.id_exam_req_det, erd.id_exam
              FROM exam_req er, exam_req_det erd
             WHERE er.id_episode = i_episode
               AND er.id_exam_req = erd.id_exam_req
               AND er.flg_status <> g_status_cancel;
    
        CURSOR c_analysis IS
            SELECT ar.id_analysis_req, ard.id_analysis_req_det, ard.id_analysis
              FROM analysis_req ar, analysis_req_det ard
             WHERE ar.id_episode = i_episode
               AND ar.id_analysis_req = ard.id_analysis_req
               AND ar.flg_status <> g_status_cancel
               AND EXISTS (SELECT 1
                      FROM analysis_instit_soft ais
                     INNER JOIN analysis_instit_recipient air
                        ON air.id_analysis_instit_soft = ais.id_analysis_instit_soft
                     WHERE ais.id_analysis = ard.id_analysis
                       AND ais.flg_available = g_flg_available
                       AND ais.id_institution = i_prof.institution
                       AND ais.id_software = i_prof.software);
    
        CURSOR c_exam_room(l_exam IN exam.id_exam%TYPE) IS
            SELECT er.id_room
              FROM exam_room er, room r, department d
             WHERE er.id_exam = l_exam
               AND er.flg_available = g_flg_available
               AND r.id_room = er.id_room
               AND d.id_department = r.id_department
               AND d.id_institution = i_prof.institution;
    
        CURSOR c_pat_hplan IS
            SELECT php.id_health_plan,
                   php.num_health_plan,
                   php.dt_health_plan,
                   php.flg_default,
                   decode(ehp.id_episode, NULL, 'N', 'Y') flg_default_epis,
                   php.barcode,
                   php.desc_health_plan
              FROM pat_health_plan php, epis_health_plan ehp
             WHERE php.id_patient = l_id_patient
               AND ehp.id_episode(+) = i_episode
               AND php.id_pat_health_plan = ehp.id_pat_health_plan(+)
               AND php.id_institution = l_id_inst
               AND php.num_health_plan IS NOT NULL;
    
        CURSOR c_prev_transfers IS
            SELECT ti.dt_end_tstz
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
               AND ti.flg_status = g_transfer_inst_fin
             ORDER BY ti.dt_end_tstz DESC;
    
        l_clin_record    clin_record%ROWTYPE;
        l_id_clin_record clin_record.id_clin_record%TYPE;
    
        l_rows_ei     table_varchar;
        l_rows_cr     table_varchar;
        l_rows_upder  table_varchar;
        l_rows_upderd table_varchar;
    
        l_epis_value      epis_ext_sys.value%TYPE;
        l_epis_cod        epis_ext_sys.cod_epis_type_ext%TYPE;
        l_external_sys    epis_ext_sys.id_external_sys%TYPE;
        l_id_epis_ext_sys epis_ext_sys.id_epis_ext_sys%TYPE;
    
        l_pat_value        pat_ext_sys.value%TYPE;
        l_pat_external_sys pat_ext_sys.id_external_sys%TYPE;
        l_id_pat_ext_sys   pat_ext_sys.id_pat_ext_sys%TYPE;
    
        l_dt_epis_begin episode.dt_begin_tstz%TYPE;
        l_dt_transf_end transfer_institution.dt_end_tstz%TYPE;
    
        l_prof_cat_type CONSTANT category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
        l_flg_show  VARCHAR2(10);
        l_msg       VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_button    VARCHAR2(10);
    
        l_id_health_plan   table_number;
        l_num_health_plan  table_varchar;
        l_dt_health_plan   table_date;
        l_flg_default      table_varchar;
        l_flg_default_epis table_varchar;
        l_barcode          table_varchar;
        l_desc_health_plan table_varchar;
    
        l_transaction_id           VARCHAR2(4000);
        l_id_necessity_tbl         table_number;
        l_necessity_flg_status_tbl table_varchar;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        l_msg_mov_cancel := pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_M005');
    
        g_error            := 'CONVERT INTO TIMESTAMP';
        l_dt_creation_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_creation, NULL);
        l_dt_update_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_update, NULL);
        l_sysdate_tstz     := current_timestamp;
    
        g_error := 'GET EPIS TYPE';
        SELECT e.id_epis_type, ti.id_dep_clin_serv, ti.id_institution_origin, e.id_visit, v.id_patient, e.dt_begin_tstz
          INTO l_cur_epis_type, l_id_dep_clin_serv, l_id_inst, l_id_visit, l_id_patient, l_dt_epis_begin
          FROM episode e, transfer_institution ti, visit v
         WHERE e.id_episode = i_episode
           AND ti.id_episode = e.id_episode
           AND v.id_visit = e.id_visit
           AND ti.dt_creation_tstz = l_dt_creation_tstz;
    
        g_error := 'GET EPIS_TYPE_SOFT_INST FROM EPIS_TYPE AND INSTITUTION';
        SELECT et.id_software
          INTO l_id_software
          FROM (SELECT etsi.id_software
                  FROM epis_type_soft_inst etsi
                 WHERE etsi.id_epis_type = l_cur_epis_type
                   AND etsi.id_institution IN (i_prof.institution, 0)
                 ORDER BY etsi.id_institution DESC) et
         WHERE rownum = 1;
    
        IF l_id_dep_clin_serv IS NOT NULL
        THEN
        
            g_error := 'GET DEP_CLIN_SERV EPISODE INFO';
            SELECT d.id_department, d.id_dept, dcs.id_clinical_service
              INTO l_id_department, l_id_dept, l_id_clinical_service
              FROM department d, dep_clin_serv dcs
             WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv
               AND dcs.id_department = d.id_department;
        
        END IF;
    
        g_error := 'OPENC_EPIS_ROOM';
        OPEN c_epis_room(l_cur_epis_type, l_id_dep_clin_serv);
        FETCH c_epis_room
            INTO l_id_room, l_rank;
        CLOSE c_epis_room;
    
        IF l_id_room IS NULL
        THEN
            l_id_room := pk_sysconfig.get_config('ADMIN_DEFAULT_ROOM',
                                                 profissional(i_prof.id, i_prof.institution, i_prof.software));
        END IF;
    
        IF i_flg_status = g_transfer_inst_transp
        THEN
            g_error := 'GET PREVIOUS TRANSFERS';
            OPEN c_prev_transfers;
            FETCH c_prev_transfers
                INTO l_dt_transf_end;
            CLOSE c_prev_transfers;
        
            g_error := 'CHECK DT_END FROM PREVIOUS TRANSFER';
            IF nvl(l_dt_transf_end, l_dt_update_tstz) > l_dt_update_tstz
            THEN
                l_code_dt_begin := 'TRANSFER_INSTITUTION_M007';
                l_msg_dt_begin  := pk_message.get_message(i_lang, i_prof, l_code_dt_begin);
                RAISE wrong_dt_begin;
            END IF;
        
            g_error := 'CHECK EPISODE BEGIN DATE';
            IF l_dt_epis_begin > l_dt_update_tstz
            THEN
                l_code_dt_begin := 'TRANSFER_INSTITUTION_M006';
                l_msg_dt_begin  := pk_message.get_message(i_lang, i_prof, l_code_dt_begin);
                RAISE wrong_dt_begin;
            END IF;
        
            g_error := 'CANCEL MOVEMENTS';
            FOR mov IN c_movement
            LOOP
                IF NOT pk_movement.cancel_mov_no_commit(i_lang,
                                                        mov.id_movement,
                                                        i_prof,
                                                        pk_message.get_message(i_lang, l_message_cancel),
                                                        pk_prof_utils.get_category(i_lang, i_prof),
                                                        l_error)
                THEN
                    RAISE no_mov_cancel;
                END IF;
            END LOOP;
        
            g_error := 'UPDATE TRANSFER STATUS';
            IF NOT t_transfer_institution.upd_transfer_institution(i_lang,
                                                                   i_prof,
                                                                   i_episode,
                                                                   l_dt_creation_tstz,
                                                                   i_prof.id,
                                                                   NULL,
                                                                   NULL,
                                                                   l_dt_update_tstz,
                                                                   NULL,
                                                                   NULL,
                                                                   i_flg_status,
                                                                   NULL,
                                                                   NULL,
                                                                   l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE EPIS_INFO';
            IF NOT pk_fast_track.set_epis_info_fast_track(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_episode,
                                                          o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF i_flg_status = g_transfer_inst_fin
        THEN
        
            -- ALERT-176898: a) and b) must be executed in this order. 
        
            -- a) Clears institution first observation date.
            g_error := 'UPDATE EPIS_INFO';
            ts_epis_info.upd(id_episode_in              => i_episode,
                             dt_first_inst_obs_tstz_in  => NULL,
                             dt_first_inst_obs_tstz_nin => FALSE,
                             id_dep_clin_serv_in        => l_id_dep_clin_serv,
                             id_dep_clin_serv_nin       => FALSE,
                             rows_out                   => l_rows_ei);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_INFO',
                                          l_rows_ei,
                                          l_error,
                                          table_varchar('dt_first_inst_obs_tstz', 'id_room', 'id_dep_clin_serv'));
        
            -- b) Data governance actions will check transfer status and institution's first observation date.
            g_error := 'UPDATE TRANSFER STATUS';
            IF NOT t_transfer_institution.upd_transfer_institution(i_lang,
                                                                   i_prof,
                                                                   i_episode,
                                                                   l_dt_creation_tstz,
                                                                   NULL,
                                                                   i_prof.id,
                                                                   NULL,
                                                                   NULL,
                                                                   l_dt_update_tstz,
                                                                   NULL,
                                                                   i_flg_status,
                                                                   NULL,
                                                                   NULL,
                                                                   l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE EPIS_INFO';
            IF NOT pk_fast_track.set_epis_info_fast_track(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_episode,
                                                          o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET BED VACANT';
            IF NOT pk_bmng_pbl.set_episode_bed_status_vacant(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_episode     => i_episode,
                                                             i_transaction_id => l_transaction_id,
                                                             o_error          => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE SYS_ALERT_EVENT';
            UPDATE sys_alert_event sa
               SET sa.id_institution = i_prof.institution
             WHERE sa.id_episode = i_episode;
        
            g_error := 'UPDATE SYS_ALERT_EVENT';
            UPDATE pre_hosp_accident pa
               SET pa.id_institution = i_prof.institution
             WHERE pa.id_episode = i_episode;
        
            g_error := 'UPDATE VISIT INSTITUTION';
            UPDATE visit v
               SET v.id_institution = i_prof.institution
             WHERE v.id_visit = l_id_visit;
        
            g_error := 'INSERT EPIS_INSTITUTION';
            BEGIN
                SELECT ei.id_epis_institution
                  INTO l_next_epis_inst
                  FROM epis_institution ei
                 WHERE ei.id_episode = i_episode
                   AND ei.id_institution = i_prof.institution;
            EXCEPTION
                WHEN no_data_found THEN
                    SELECT seq_epis_institution.nextval
                      INTO l_next_epis_inst
                      FROM dual;
                
                    INSERT INTO epis_institution
                        (id_epis_institution, id_institution, id_episode)
                    VALUES
                        (l_next_epis_inst, i_prof.institution, i_episode);
            END;
        
            g_error := 'UPDATE EPISODE';
            ts_episode.upd(id_clinical_service_in  => l_id_clinical_service,
                           id_clinical_service_nin => FALSE,
                           id_department_in        => l_id_department,
                           id_department_nin       => FALSE,
                           id_dept_in              => l_id_dept,
                           id_dept_nin             => FALSE,
                           id_institution_in       => i_prof.institution,
                           id_institution_nin      => FALSE,
                           where_in                => 'id_visit = ' || l_id_visit,
                           rows_out                => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        
            BEGIN
            
                g_error := 'GET EPIS_EXT_SYS';
                SELECT ees.id_external_sys, ees.value, ees.cod_epis_type_ext
                  INTO l_external_sys, l_epis_value, l_epis_cod
                  FROM epis_ext_sys ees
                 WHERE id_episode = i_episode
                   AND id_institution = l_id_inst
                   AND id_external_sys = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
            
                BEGIN
                    g_error := 'CHECK EPIS_EXT_SYS';
                    SELECT ees.id_epis_ext_sys
                      INTO l_id_epis_ext_sys
                      FROM epis_ext_sys ees
                     WHERE id_episode = i_episode
                       AND id_institution = i_prof.institution
                       AND id_external_sys = l_external_sys;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                IF l_id_epis_ext_sys IS NULL
                THEN
                    g_error := 'SET EPIS_EXT_SYS';
                    INSERT INTO epis_ext_sys
                        (id_epis_ext_sys,
                         id_external_sys,
                         id_episode,
                         VALUE,
                         id_institution,
                         id_epis_type,
                         cod_epis_type_ext)
                    VALUES
                        (seq_epis_ext_sys.nextval,
                         l_external_sys,
                         i_episode,
                         l_epis_value,
                         i_prof.institution,
                         l_cur_epis_type,
                         l_epis_cod);
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            BEGIN
            
                g_error := 'GET PAT_EXT_SYS';
                SELECT pes.id_external_sys, pes.value
                  INTO l_pat_external_sys, l_pat_value
                  FROM pat_ext_sys pes
                 WHERE id_patient = l_id_patient
                   AND id_institution = l_id_inst
                   AND id_external_sys = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
            
                BEGIN
                    g_error := 'CHECK PAT_EXT_SYS';
                    SELECT pes.id_pat_ext_sys
                      INTO l_id_pat_ext_sys
                      FROM pat_ext_sys pes
                     WHERE id_patient = l_id_patient
                       AND id_institution = i_prof.institution
                       AND id_external_sys = l_pat_external_sys;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                IF l_id_pat_ext_sys IS NULL
                THEN
                    g_error := 'SET PAT_EXT_SYS';
                    INSERT INTO pat_ext_sys
                        (id_pat_ext_sys, id_external_sys, id_patient, VALUE, id_institution)
                    VALUES
                        (seq_pat_ext_sys.nextval, l_pat_external_sys, l_id_patient, l_pat_value, i_prof.institution);
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            g_error := 'SET NEW LOCATION';
            IF NOT pk_movement.set_new_location_no_commit(i_lang          => i_lang,
                                                          i_episode       => i_episode,
                                                          i_prof          => i_prof,
                                                          i_room          => l_id_room,
                                                          i_prof_cat_type => l_prof_cat_type,
                                                          o_flg_show      => l_flg_show,
                                                          o_msg           => l_msg,
                                                          o_msg_title     => l_msg_title,
                                                          o_button        => l_button,
                                                          o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE CLIN_RECORD';
            IF NOT pk_adt.update_transfer_adt(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => l_id_patient,
                                              i_id_inst => l_id_inst,
                                              i_episode => i_episode,
                                              o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'GET INSTITUTION HEALTH PLAN';
            OPEN c_pat_hplan;
            FETCH c_pat_hplan BULK COLLECT
                INTO l_id_health_plan,
                     l_num_health_plan,
                     l_dt_health_plan,
                     l_flg_default,
                     l_flg_default_epis,
                     l_barcode,
                     l_desc_health_plan;
            CLOSE c_pat_hplan;
        
            IF l_id_health_plan IS NOT NULL
               AND l_id_health_plan.count > 0
            THEN
                g_error := 'SET INSTITUTION HEALTH PLAN';
                IF NOT pk_patient.set_pat_hplan_internal(i_lang,
                                                         l_id_patient,
                                                         i_episode,
                                                         l_id_health_plan,
                                                         l_num_health_plan,
                                                         l_dt_health_plan,
                                                         l_flg_default,
                                                         l_flg_default_epis,
                                                         l_barcode,
                                                         i_prof,
                                                         l_prof_cat_type,
                                                         l_desc_health_plan,
                                                         l_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            SELECT pn.id_necessity, pn.flg_status
              BULK COLLECT
              INTO l_id_necessity_tbl, l_necessity_flg_status_tbl
              FROM pat_necessity pn
             WHERE pn.id_patient = l_id_patient
               AND pn.id_institution = i_prof.institution;
        
            g_error := 'CALL PK_PATIENT.SET_PAT_NECESS_INTERNAL';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_patient.set_pat_necess(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_patient       => l_id_patient,
                                             i_id_episode       => i_episode,
                                             i_tbl_flg_status   => l_necessity_flg_status_tbl,
                                             i_tbl_id_necessity => l_id_necessity_tbl,
                                             i_id_institution   => l_id_inst,
                                             o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'LOOP C_EXAM';
            FOR r_exam IN c_exam
            LOOP
            
                g_error := 'FETCH EXAM ROOM';
                OPEN c_exam_room(r_exam.id_exam);
                FETCH c_exam_room
                    INTO l_exam_room;
                CLOSE c_exam_room;
            
                g_error := 'UPDATE EXAM_REQ';
                /* <DENORM Fábio> */
                ts_exam_req.upd(id_exam_req_in     => r_exam.id_exam_req,
                                id_institution_in  => i_prof.institution,
                                id_institution_nin => FALSE,
                                rows_out           => l_rows_upder);
            
                g_error := 'UPDATE EXAM_REQ_DET';
                /* <DENORM Fábio> */
                ts_exam_req_det.upd(id_exam_req_det_in => r_exam.id_exam_req_det,
                                    id_room_in         => l_exam_room,
                                    rows_out           => l_rows_upderd);
            
                g_error := 'SET GRIT_TASK_EXAM';
                l_ret   := pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => NULL,
                                                              i_episode      => i_episode,
                                                              i_exam_req     => r_exam.id_exam_req,
                                                              i_exam_req_det => r_exam.id_exam_req_det,
                                                              o_error        => l_error);
            END LOOP;
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EXAM_REQ',
                                          l_rows_upder,
                                          l_error,
                                          table_varchar('ID_INSTITUTION'));
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EXAM_REQ_DET',
                                          l_rows_upderd,
                                          l_error,
                                          table_varchar('ID_ROOM'));
        
            g_error := 'LOOP C_ANALYSIS';
            FOR r_analysis IN c_analysis
            LOOP
                g_error := 'SET GRID_TASK_LAB';
                -- l_ret is not processed. this call isn't used in the function output
                l_ret := pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_patient          => NULL,
                                                                    i_episode          => i_episode,
                                                                    i_analysis_req     => r_analysis.id_analysis_req,
                                                                    i_analysis_req_det => r_analysis.id_analysis_req_det,
                                                                    o_error            => l_error);
            
            END LOOP;
        
            g_error := 'INSERT DOC TRIAGE ALERT';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_edis_triage.set_alert_triage(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_episode       => i_episode,
                                                   i_dt_req_det       => l_sysdate_tstz,
                                                   i_alert_type       => pk_alert_constant.g_cat_type_doc,
                                                   i_type             => l_add_alert,
                                                   i_is_transfer_inst => pk_alert_constant.g_yes,
                                                   o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            pk_ia_event_common.patient_transfer_institution(i_id_institution => i_prof.institution,
                                                            i_id_episode     => i_episode,
                                                            i_creation_date  => l_dt_creation_tstz);
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_can_refresh_mviews := TRUE;
    
        IF l_can_refresh_mviews
        THEN
            pk_episode.update_mv_episodes();
        END IF;
    
        --
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN wrong_dt_begin THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN error_handling_ext(i_lang,
                                      'UPDATE_TRANSFER_INST',
                                      '',
                                      l_code_dt_begin,
                                      l_msg_dt_begin,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN no_mov_cancel THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN error_handling_ext(i_lang,
                                      'UPDATE_TRANSFER_INST',
                                      '',
                                      'TRANSFER_INSTITUTION_M005',
                                      l_msg_mov_cancel,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN error_handling_ext(i_lang,
                                      'UPDATE_TRANSFER_INST',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'UPDATE_TRANSFER_INST', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END update_transfer_inst;

    /********************************************************************************************
    * Gets all the requested transfers for a given episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param o_transfer_inst          Requested transfers for a given episode
    * @param o_flg_create             Y-It is possible to create a new institution transfer request (the episode is active)
    *                                 N-otherwise
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transfer_epis_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN transfer_institution.id_episode%TYPE,
        o_transfer_inst OUT pk_types.cursor_type,
        o_flg_create    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_status CONSTANT sys_domain.code_domain%TYPE := 'TRANSFER_INSTITUTION.FLG_STATUS';
        l_message_no    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         'TRANSFER_INSTITUTION_T013');
        --define the professional categories that can register the departure date        
        l_cfg_ti_depart_dt_set CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => g_sc_departure_dt_set,
                                                                                         i_prof    => i_prof);
    
        --define the professional categories that can register the arrival date        
        l_cfg_ti_arrival_dt_set CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => g_sc_arrival_dt_set,
                                                                                          i_prof    => i_prof);
    
        l_id_prof_category CONSTANT category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_internal_error EXCEPTION;
        l_cancel_message sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_cancel_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'TRANSFER_INSTITUTION_M012');
    
        g_error := 'OPEN O_TRANSFER_INST';
        OPEN o_transfer_inst FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, ti.dt_creation_tstz, i_prof) dt_creation,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ti.id_prof_reg) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ti.id_prof_reg, ti.dt_creation_tstz, ti.id_episode) desc_spec,
                   ti.id_institution_origin,
                   (SELECT pk_translation.get_translation(i_lang, i.code_institution)
                      FROM institution i
                     WHERE i.id_institution = ti.id_institution_origin) institution_origin,
                   ti.id_institution_dest,
                   (SELECT pk_translation.get_translation(i_lang, i.code_institution)
                      FROM institution i
                     WHERE i.id_institution = ti.id_institution_dest) institution_dest,
                   nvl((SELECT pk_translation.get_translation(i_lang, t.code_transp_entity)
                         FROM transp_entity t
                        WHERE t.id_transp_entity = ti.id_transp_entity),
                       l_message_no) desc_transport,
                   pk_sysdomain.get_domain(l_domain_status, ti.flg_status, i_lang) desc_status,
                   get_domain_status(i_lang, i_prof, ti.flg_status, ti.id_institution_dest) flg_status,
                   decode(ti.notes,
                          NULL,
                          decode(ti.notes_cancel,
                                 NULL,
                                 NULL,
                                 '(' || pk_message.get_message(i_lang, 'COMMON_M008') || ')'),
                          '(' || pk_message.get_message(i_lang, 'COMMON_M008') || ')') title_notes,
                   pk_date_utils.date_send_tsz(i_lang, ti.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, ti.dt_end_tstz, i_prof) dt_end,
                   get_inst_transfer_icon_string(i_lang, i_prof, ti.id_episode, ti.dt_creation_tstz) desc_pat_transfer,
                   check_permissions_depart_date(i_lang,
                                                 i_prof,
                                                 ti.id_institution_origin,
                                                 l_cfg_ti_depart_dt_set,
                                                 ti.flg_status,
                                                 l_id_prof_category,
                                                 ti.dt_begin_tstz) flg_departure_date_set,
                   check_permissions_arrival_date(i_lang,
                                                  i_prof,
                                                  ti.id_institution_dest,
                                                  l_cfg_ti_arrival_dt_set,
                                                  ti.flg_status,
                                                  l_id_prof_category,
                                                  ti.dt_end_tstz) flg_arrival_date_set,
                   REPLACE(REPLACE(l_cancel_message,
                                   '@1',
                                   pk_translation.get_translation(i_lang,
                                                                  'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                  id_institution_origin)),
                           '@2',
                           pk_translation.get_translation(i_lang,
                                                          'AB_INSTITUTION.CODE_INSTITUTION.' || ti.id_institution_dest)) transfer_desc
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
             ORDER BY ti.flg_status DESC, ti.dt_creation_tstz DESC;
    
        g_error := 'CALL check_create_transfer';
        pk_alertlog.log_debug(g_error);
        IF NOT check_create_transfer(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_id_episode => i_episode,
                                     o_flg_create => o_flg_create,
                                     o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transfer_inst);
            RETURN error_handling_ext(i_lang, 'GET_TRANSFER_EPIS_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_transfer_epis_list;

    /********************************************************************************************
    * Gets the detail of a given institution transfer
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date    
    * @param o_transfer_inst          Requested transfers for a given episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transfer_epis_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN transfer_institution.id_episode%TYPE,
        i_dt_creation  IN VARCHAR2,
        o_transfer_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_status    sys_domain.code_domain%TYPE := 'TRANSFER_INSTITUTION.FLG_STATUS';
        l_dt_creation_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_message_no CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      'TRANSFER_INSTITUTION_T013');
    
    BEGIN
    
        g_error            := 'CONVERT INTO TIMESTAMP';
        l_dt_creation_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_creation, NULL);
    
        g_error := 'OPEN O_TRANSFER_INST';
        OPEN o_transfer_det FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, ti.id_prof_reg) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ti.id_prof_reg, ti.dt_creation_tstz, ti.id_episode) desc_spec,
                   ti.dt_creation_tstz,
                   pk_date_utils.date_send_tsz(i_lang, ti.dt_creation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ti.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation_chr,
                   (SELECT pk_translation.get_translation(i_lang, i.code_institution)
                      FROM institution i
                     WHERE i.id_institution = ti.id_institution_origin) institution_origin,
                   (SELECT pk_translation.get_translation(i_lang, i.code_institution)
                      FROM institution i
                     WHERE i.id_institution = ti.id_institution_dest) institution_dest,
                   nvl((SELECT pk_translation.get_translation(i_lang, t.code_transp_entity)
                         FROM transp_entity t
                        WHERE t.id_transp_entity = ti.id_transp_entity),
                       l_message_no) desc_transport,
                   pk_sysdomain.get_domain(l_domain_status, ti.flg_status, i_lang) desc_status,
                   ti.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ti.id_prof_begin) prof_begin,
                   pk_date_utils.date_send_tsz(i_lang, ti.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_char_tsz(i_lang, ti.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin_chr,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ti.id_prof_end) prof_end,
                   pk_date_utils.date_send_tsz(i_lang, ti.dt_end_tstz, i_prof) dt_end,
                   pk_date_utils.date_char_tsz(i_lang, ti.dt_end_tstz, i_prof.institution, i_prof.software) dt_end_chr,
                   ti.notes,
                   (SELECT pk_translation.get_translation(i_lang, top.code_transfer_option)
                      FROM transfer_option top
                     WHERE top.id_transfer_option = ti.id_transfer_option) desc_trans_option,
                   (SELECT pk_translation.get_translation(i_lang, d.code_department)
                      FROM department d, dep_clin_serv dcs
                     WHERE dcs.id_department = d.id_department
                       AND dcs.id_dep_clin_serv = ti.id_dep_clin_serv) desc_service,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM clinical_service cs, dep_clin_serv dcs
                     WHERE dcs.id_clinical_service = cs.id_clinical_service
                       AND dcs.id_dep_clin_serv = ti.id_dep_clin_serv) desc_clin_serv,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ti.id_prof_cancel) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ti.id_prof_cancel, ti.dt_cancel_tstz, ti.id_episode) spec_cancel,
                   pk_date_utils.date_send_tsz(i_lang, ti.dt_cancel_tstz, i_prof) dt_cancel,
                   pk_date_utils.date_char_tsz(i_lang, ti.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel_chr,
                   ti.notes_cancel
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
               AND ti.dt_creation_tstz = nvl(l_dt_creation_tstz, ti.dt_creation_tstz);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transfer_det);
            RETURN error_handling_ext(i_lang, 'GET_TRANSFER_EPIS_DET', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_transfer_epis_det;

    /********************************************************************************************
    * Gets the list of available transports to be used in the transfer
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_transp_ent             Transport list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transp_ent_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_transp_ent OUT pk_types.cursor_type,
        o_name       OUT professional.nick_name%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat category.flg_type%TYPE;
    BEGIN
    
        SELECT pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof)
          INTO l_prof_cat
          FROM dual;
    
        g_error := 'OPEN O_TRANSP_ENT';
        OPEN o_transp_ent FOR
            SELECT NULL id_transp_entity,
                   pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T013') desc_transport,
                   -1 rank
              FROM dual
            UNION ALL
            SELECT DISTINCT te.id_transp_entity,
                            pk_translation.get_translation(i_lang, te.code_transp_entity) desc_transport,
                            te.rank
              FROM transp_ent_inst tei, transp_entity te
             WHERE tei.id_institution = i_prof.institution
               AND tei.id_transp_entity = te.id_transp_entity
               AND tei.flg_available = g_yes
               AND te.flg_available = g_yes
               AND tei.flg_type IN (g_transp_transf, g_transp_all)
               AND te.flg_transp = g_transp_depart
               AND te.flg_type = decode(l_prof_cat, g_admin_category, g_admin_category, g_other_category)
             ORDER BY rank, desc_transport;
    
        g_error := 'GET PROFESSIONAL NAME';
        o_name  := pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transp_ent);
            RETURN error_handling_ext(i_lang, 'GET_TRANSP_ENT_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_transp_ent_list;

    /********************************************************************************************
    * Gets the list of available transports to be used in the transfer
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dep_clin_serv          Association ID between clinical service and department
    * @param o_transfer_opt           Transfer option list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transfer_option_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_transfer_opt  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_TRANSFER_OPT';
        OPEN o_transfer_opt FOR
            SELECT DISTINCT top.id_transfer_option,
                            pk_translation.get_translation(i_lang, top.code_transfer_option) desc_transfer_opt
              FROM transfer_option top, transfer_opt_dcs tdcs
             WHERE tdcs.id_dep_clin_serv = i_dep_clin_serv
               AND tdcs.id_transfer_option = top.id_transfer_option
               AND top.flg_available = g_yes
             ORDER BY desc_transfer_opt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transfer_opt);
            RETURN error_handling_ext(i_lang,
                                      'GET_TRANSFER_OPTION_LIST',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_transfer_option_list;

    /********************************************************************************************
    * Gets the date to be used on the patients grid
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    *                        
    * @return                         timestamp to show on the grid arrival column
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_grid_task_arrival
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        CURSOR c_transfer_epis IS
            SELECT ti.flg_status, ti.dt_end_tstz, ti.id_institution_dest
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
             ORDER BY ti.dt_creation_tstz DESC;
    
        l_flg_status transfer_institution.flg_status%TYPE;
        l_dt_end     transfer_institution.dt_end_tstz%TYPE;
        l_id_inst    transfer_institution.id_institution_dest%TYPE;
    
    BEGIN
    
        OPEN c_transfer_epis;
        FETCH c_transfer_epis
            INTO l_flg_status, l_dt_end, l_id_inst;
        CLOSE c_transfer_epis;
    
        IF l_flg_status = g_transfer_inst_fin
           AND l_id_inst = i_prof.institution
        THEN
            RETURN l_dt_end;
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_grid_task_arrival;

    /********************************************************************************************
    * Gets the date to be used on the patients grid
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    *                        
    * @return                         timestamp to show on the grid departure column
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_grid_task_departure
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_color VARCHAR2(1);
        l_dt_task   TIMESTAMP WITH LOCAL TIME ZONE;
        l_shortcut  sys_shortcut.id_sys_shortcut%TYPE;
    
        CURSOR c_transfer_epis IS
            SELECT ti.dt_creation_tstz, g_color_red color
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
               AND ti.id_institution_origin = i_prof.institution
               AND ti.flg_status = g_transfer_inst_req
            UNION ALL
            SELECT ti.dt_begin_tstz, g_no_color color
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
               AND ti.id_institution_origin = i_prof.institution
               AND ti.flg_status = g_transfer_inst_transp
            UNION ALL
            SELECT ti.dt_begin_tstz, g_color_green color
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
               AND ti.id_institution_dest = i_prof.institution
               AND ti.flg_status = g_transfer_inst_transp;
    
        CURSOR c_short_transfer IS
            SELECT a.id_sys_shortcut
              FROM sys_shortcut a
             WHERE a.intern_name = 'TRANSFER_INSTITUTION'
               AND a.id_software = i_prof.software
               AND a.id_parent IS NULL
               AND a.id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC;
    
    BEGIN
    
        OPEN c_transfer_epis;
        FETCH c_transfer_epis
            INTO l_dt_task, l_flg_color;
        IF c_transfer_epis%NOTFOUND
        THEN
            RETURN NULL;
        END IF;
        CLOSE c_transfer_epis;
    
        OPEN c_short_transfer;
        FETCH c_short_transfer
            INTO l_shortcut;
        CLOSE c_short_transfer;
    
        RETURN l_shortcut || '|' || pk_date_utils.date_send_tsz(i_lang, l_dt_task, i_prof) || '|' || l_flg_color || '|' || 'X';
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_grid_task_departure;

    /********************************************************************************************
    * Gets the institution list in order to choose the transfer destination
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_institution            Institution list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          23/04/2008
    **********************************************************************************************/

    FUNCTION get_institution_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_institution OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN CURSOR O_INSTITUTION';
        OPEN o_institution FOR
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution) desc_institution
              FROM institution i
              JOIN (SELECT column_value id_institution
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_trf))) tbl_inst_grp
                ON tbl_inst_grp.id_institution = i.id_institution
             WHERE i.flg_available = g_yes
               AND i.id_institution <> i_prof.institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_institution);
            RETURN error_handling_ext(i_lang, 'GET_INSTITUTION_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_institution_list;
    --
    /********************************************************************************************
    * Gets the clinical service list available in a particular department
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_department             Department ID
    * @param o_clin_serv              Clinical service list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          28/04/2008
    **********************************************************************************************/
    FUNCTION get_clin_serv_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_clin_serv  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_clin_serv FOR
            SELECT dcs.id_dep_clin_serv,
                   c.id_clinical_service,
                   c.rank,
                   pk_translation.get_translation(i_lang, c.code_clinical_service) label
              FROM clinical_service c, dep_clin_serv dcs
             WHERE dcs.id_clinical_service = c.id_clinical_service
               AND dcs.id_department = i_department
               AND dcs.flg_available = g_yes
             ORDER BY c.rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_clin_serv);
            RETURN error_handling_ext(i_lang, 'GET_CLIN_SERV_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_clin_serv_list;

    /********************************************************************************************
    * Gets the department list available in a particular institution
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_institution            Institution ID
    * @param o_department             Department list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          29/04/2008
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        o_department  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_software_inp CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof);
        l_id_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
    
        l_id_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_id_episode);
    
        IF l_id_epis_type = pk_alert_constant.g_epis_type_inpatient
        THEN
        
            g_error := 'GET CURSOR';
            OPEN o_department FOR
                SELECT dpt.id_department, dpt.rank, pk_translation.get_translation(i_lang, dpt.code_department) label
                  FROM department dpt, software_dept sd
                 WHERE dpt.id_institution = i_institution
                   AND sd.id_software = i_prof.software
                   AND sd.id_dept = dpt.id_dept
                   AND dpt.flg_available = g_yes
                   AND instr(dpt.flg_type, 'I') > 0
                 ORDER BY dpt.rank, label;
        
        ELSE
            g_error := 'GET CURSOR';
            OPEN o_department FOR
                SELECT dpt.id_department, dpt.rank, pk_translation.get_translation(i_lang, dpt.code_department) label
                  FROM department dpt, software_dept sd
                 WHERE dpt.id_institution = i_institution
                   AND sd.id_software = i_prof.software
                   AND sd.id_dept = dpt.id_dept
                   AND dpt.flg_available = g_yes
                      -- temp restriction until transfer institution is only available in EDIS
                   AND (i_prof.software <> l_id_software_inp OR
                       (instr(dpt.flg_type, 'I') > 0 AND instr(dpt.flg_type, 'O') > 0))
                 ORDER BY dpt.rank, label;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_department);
            RETURN error_handling_ext(i_lang, 'GET_DEPARTMENT_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_department_list;

    /********************************************************************************************
    * Migration of institution transfer requests from the temporary episode to the definitive
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Definitive episode ID
    * @param i_episode_temp           Temporary episode ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          24/04/2008
    **********************************************************************************************/

    FUNCTION set_match_transfer_inst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tranfer_def IS
            SELECT MAX(ti.dt_creation_tstz)
              FROM transfer_institution ti
             WHERE ti.id_episode = i_episode
               AND ti.flg_status NOT IN (g_transfer_inst_cancel, g_transfer_inst_fin);
    
        l_dt_creation TIMESTAMP WITH LOCAL TIME ZONE;
        l_message_cancel CONSTANT sys_message.code_message%TYPE := 'TRANSFER_INSTITUTION_M004';
        l_message              sys_message.desc_message%TYPE;
        l_transfer_institution ts_transfer_institution.transfer_institution_tc;
        l_rowids               table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'UPDATE TEMP TRANSFER INST';
        UPDATE transfer_institution ti
           SET ti.id_episode = i_episode
         WHERE ti.id_episode = i_episode_temp;
    
        g_error := 'OPEN C_TRANSFER_DEF';
        OPEN c_tranfer_def;
        FETCH c_tranfer_def
            INTO l_dt_creation;
        CLOSE c_tranfer_def;
    
        g_error := 'COLLECT TRANSF INST DATA';
        pk_alertlog.log_debug(g_error);
        SELECT ti.*
          BULK COLLECT
          INTO l_transfer_institution
          FROM transfer_institution ti
         WHERE ti.id_episode = i_episode
           AND ti.flg_status NOT IN (g_transfer_inst_cancel, g_transfer_inst_fin)
           AND ti.dt_creation_tstz <> l_dt_creation
           FOR UPDATE;
    
        IF l_transfer_institution.exists(1)
        THEN
            l_message := pk_message.get_message(i_lang, l_message_cancel);
        
            FOR i IN l_transfer_institution.first .. l_transfer_institution.last
            LOOP
                g_error := 'UPDATE TRANSFER INST (' || i || ')';
                pk_alertlog.log_debug(g_error);
                ts_transfer_institution.upd(id_episode_in       => l_transfer_institution(i).id_episode,
                                            dt_creation_tstz_in => l_transfer_institution(i).dt_creation_tstz,
                                            id_prof_cancel_in   => i_prof.id,
                                            id_prof_cancel_nin  => FALSE,
                                            notes_cancel_in     => l_message,
                                            notes_cancel_nin    => NULL,
                                            dt_cancel_tstz_in   => current_timestamp,
                                            dt_cancel_tstz_nin  => FALSE,
                                            rows_out            => l_rowids);
            END LOOP;
        
            g_error := 'PROCESS UPDATE - TRANSFER_INSTITUTION';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'TRANSFER_INSTITUTION',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_PROF_CANCEL',
                                                                          'NOTES_CANCEL',
                                                                          'DT_CANCEL_TSTZ'));
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_MATCH_TRANSFER_INST', g_error, SQLERRM, TRUE, o_error);
    END set_match_transfer_inst;

    /********************************************************************************************
    * Checks if there is pending institution transfers for a given episode
    *
    * @param i_id_episode             Episode ID
    *                        
    * @return                         Exists pending transfers: 1 - Yes; 0 - No
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          08/05/2008
    **********************************************************************************************/

    FUNCTION check_epis_transfer(i_episode IN transfer_institution.id_episode%TYPE) RETURN NUMBER IS
    
        l_num NUMBER;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_num
          FROM transfer_institution ti
         WHERE ti.id_episode = i_episode
           AND ti.flg_status <> g_transfer_inst_cancel;
    
        IF l_num > 0
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END check_epis_transfer;

    /********************************************************************************************
    * Checks if there is pending institution transfers for a given episode
    *
    * @param i_id_episode             Episode ID
    *                        
    * @return                         Exists pending transfers: (Y)Yes; (N)No
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          08/05/2008
    **********************************************************************************************/

    FUNCTION check_transfer_access
    (
        i_episode IN transfer_institution.id_episode%TYPE,
        i_prof    IN profissional
    ) RETURN VARCHAR2 IS
    
        l_num NUMBER;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_num
          FROM transfer_institution ti
         WHERE ti.id_episode = i_episode
           AND ti.flg_status <> g_transfer_inst_cancel
           AND i_prof.institution IN (ti.id_institution_origin, ti.id_institution_dest);
    
        IF l_num > 0
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_no;
    END check_transfer_access;

    /********************************************************************************************
    * Gets the header label in case of an institution transfer
    *
    * @param i_id_episode             Episode ID
    *                        
    * @return                         Header label
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          18/07/2008
    **********************************************************************************************/

    FUNCTION get_inst_transfer_message
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_message    sys_message.desc_message%TYPE;
        l_flg_status transfer_institution.flg_status%TYPE;
        l_code_message_f CONSTANT sys_message.code_message%TYPE := 'HEADER_M013';
        l_code_message_t CONSTANT sys_message.code_message%TYPE := 'HEADER_M014';
    
    BEGIN
    
        SELECT ti.flg_status
          INTO l_flg_status
          FROM transfer_institution ti
         WHERE ti.id_episode = i_episode
           AND ((ti.flg_status = g_transfer_inst_fin AND ti.id_institution_dest = i_prof.institution) OR
               (ti.flg_status = g_transfer_inst_transp AND
               i_prof.institution IN (ti.id_institution_origin, ti.id_institution_dest)))
              -- José Brito 28/08/2008 Devolver o estado da última transferência activa
           AND ti.dt_creation_tstz = (SELECT MAX(ti2.dt_creation_tstz)
                                        FROM transfer_institution ti2
                                       WHERE ti2.id_episode = i_episode
                                         AND ti2.flg_status <> g_transfer_inst_cancel);
        --
    
        IF l_flg_status = g_transfer_inst_fin
        THEN
            l_message := pk_message.get_message(i_lang, l_code_message_f);
        ELSIF l_flg_status = g_transfer_inst_transp
        THEN
            l_message := pk_message.get_message(i_lang, l_code_message_t);
        END IF;
    
        RETURN l_message;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_inst_transfer_message;

    /********************************************************************************************
    * Cancels an institution transfer request (internal function)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date
    * @param i_notes_cancel           Cancellation notes
    * @param i_id_cancel_reason       Cancel reason ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.0.5.3.4   
    * @since                          07/05/2011
    **********************************************************************************************/

    FUNCTION cancel_transfer_inst_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN transfer_institution.id_episode%TYPE,
        i_dt_creation      IN VARCHAR2,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_creation_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CONVERT INTO TIMESTAMP';
        pk_alertlog.log_debug(g_error);
        l_dt_creation_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_creation, NULL);
    
        g_error := 'CANCEL TRANSFER INSTITUTION REQUEST';
        pk_alertlog.log_debug(g_error);
        IF NOT t_transfer_institution.upd_transfer_institution(i_lang,
                                                               i_prof,
                                                               i_episode,
                                                               l_dt_creation_tstz,
                                                               NULL,
                                                               NULL,
                                                               i_prof.id,
                                                               NULL,
                                                               NULL,
                                                               current_timestamp,
                                                               g_transfer_inst_cancel,
                                                               i_notes_cancel,
                                                               i_id_cancel_reason,
                                                               o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE EPIS_INFO';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_fast_track.set_epis_info_fast_track(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_episode => i_episode,
                                                      o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => o_error)
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
                                              'ALERT',
                                              g_package_name,
                                              'CANCEL_TRANSFER_INST_INT',
                                              o_error);
            RETURN FALSE;
    END cancel_transfer_inst_int;

    /**************************************************************************
    * get transfer list for the current institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    *
    * @param o_in_transfer_list       Transfer list for the current institution 
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/21                                
    **************************************************************************/
    FUNCTION get_in_transfer_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_in_transfer_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_IN_TRANSFER_LIST';
        l_gap_hours     NUMBER;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        l_gap_hours := to_number(nvl(pk_sysconfig.get_config('TRANSF_INST_GRID_TIME', i_prof), 24));
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'OPEN CURSOR O_IN_TRANSFER_LIST';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_in_transfer_list FOR
            SELECT t.id_episode,
                   t.id_patient id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, t.id_patient, t.id_episode) name_pat,
                   t.name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, t.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, t.id_patient) pat_nd_icon,
                   pk_sysdomain.get_domain(pk_inp_grid.g_cf_pat_gender_abbr, t.gender, i_lang) gender,
                   pk_patient.get_pat_age(i_lang, t.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, t.id_patient, t.id_episode, NULL) photo,
                   pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, t.id_episode) desc_diagnosis,
                   t.id_institution_origin,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || t.id_institution_origin) institution_origin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_reg) prof_name,
                   t.id_institution_dest,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || t.id_institution_dest) institution_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_end) prof_name_end,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_end_tstz, i_prof.institution, i_prof.software) dt_end,
                   get_inst_transfer_icon_string(i_lang, i_prof, t.id_episode, t.dt_creation_tstz) icon_status,
                   t.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_creation_tstz, i_prof) dt_creation,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, t.id_episode, l_hand_off_type) resp_icons
              FROM (SELECT ti.id_episode,
                           ti.id_patient,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, ti.id_patient, ti.id_episode) name_pat_to_sort,
                           pat.gender,
                           ti.id_institution_origin,
                           ti.id_prof_reg,
                           ti.id_institution_dest,
                           ti.id_prof_end,
                           ti.dt_creation_tstz,
                           ti.dt_begin_tstz,
                           ti.dt_end_tstz,
                           ti.flg_status
                      FROM transfer_institution ti
                     INNER JOIN patient pat
                        ON pat.id_patient = ti.id_patient
                     INNER JOIN epis_info ei
                        ON ei.id_episode = ti.id_episode
                     WHERE ti.id_institution_dest = i_prof.institution
                       AND ti.flg_status NOT IN (g_transfer_inst_fin, g_transfer_inst_cancel)
                       AND ei.id_software = i_prof.software
                    UNION ALL
                    SELECT ti.id_episode,
                           ti.id_patient,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, ti.id_patient, ti.id_episode) name_pat_to_sort,
                           pat.gender,
                           ti.id_institution_origin,
                           ti.id_prof_reg,
                           ti.id_institution_dest,
                           ti.id_prof_end,
                           ti.dt_creation_tstz,
                           ti.dt_begin_tstz,
                           ti.dt_end_tstz,
                           ti.flg_status
                      FROM transfer_institution ti
                     INNER JOIN patient pat
                        ON pat.id_patient = ti.id_patient
                     INNER JOIN epis_info ei
                        ON ei.id_episode = ti.id_episode
                     WHERE ti.id_institution_dest = i_prof.institution
                       AND ti.flg_status IN (g_transfer_inst_fin, g_transfer_inst_cancel)
                       AND (ti.dt_end_tstz > (current_timestamp - l_gap_hours / 24) OR
                           ti.dt_cancel_tstz > (current_timestamp - l_gap_hours / 24))
                       AND ei.id_software = i_prof.software) t
             ORDER BY t.dt_begin_tstz NULLS LAST, t.name_pat_to_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_in_transfer_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_in_transfer_list;

    /***************************************************************************
    * get transfer list when the current institution is an origin for another institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    *
    * @param o_out_transfer_list      Transfer list for current institution is an origin for another institution
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/21                                
    **************************************************************************/
    FUNCTION get_out_transfer_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_out_transfer_list OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_OUT_TRANSFER_LIST';
        l_gap_hours     NUMBER;
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        l_gap_hours := to_number(nvl(pk_sysconfig.get_config('TRANSF_INST_GRID_TIME', i_prof), 24));
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'OPEN CURSOR O_OUT_TRANSFER_LIST';
        OPEN o_out_transfer_list FOR
            SELECT t.id_episode,
                   t.id_patient id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, t.id_patient, t.id_episode) name_pat,
                   t.name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, t.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, t.id_patient) pat_nd_icon,
                   pk_sysdomain.get_domain(pk_inp_grid.g_cf_pat_gender_abbr, t.gender, i_lang) gender,
                   pk_patient.get_pat_age(i_lang, t.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, t.id_patient, t.id_episode, NULL) photo,
                   pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, t.id_episode) desc_diagnosis,
                   t.id_institution_origin,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || t.id_institution_origin) institution_origin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_reg) prof_name,
                   t.id_institution_dest,
                   pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || t.id_institution_dest) institution_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_end) prof_name_end,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_end_tstz, i_prof.institution, i_prof.software) dt_end,
                   get_inst_transfer_icon_string(i_lang, i_prof, t.id_episode, t.dt_creation_tstz) icon_status,
                   get_domain_status(i_lang, i_prof, t.flg_status, t.id_institution_dest) flg_status,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_creation_tstz, i_prof) dt_creation,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, t.id_episode, l_hand_off_type) resp_icons
              FROM (SELECT ti.id_episode,
                           ti.id_patient,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, ti.id_patient, ti.id_episode) name_pat_to_sort,
                           pat.gender,
                           ti.id_institution_origin,
                           ti.id_prof_reg,
                           ti.id_institution_dest,
                           ti.id_prof_end,
                           ti.dt_creation_tstz,
                           ti.dt_begin_tstz,
                           ti.dt_end_tstz,
                           ti.flg_status
                      FROM transfer_institution ti
                     INNER JOIN patient pat
                        ON pat.id_patient = ti.id_patient
                     INNER JOIN epis_info ei
                        ON ei.id_episode = ti.id_episode
                     WHERE ti.id_institution_origin = i_prof.institution
                       AND ti.flg_status NOT IN (g_transfer_inst_fin, g_transfer_inst_cancel)
                       AND (ei.id_software = i_prof.software OR i_prof.software = pk_alert_constant.g_soft_adt)
                    UNION ALL
                    SELECT ti.id_episode,
                           ti.id_patient,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, ti.id_patient, ti.id_episode) name_pat_to_sort,
                           pat.gender,
                           ti.id_institution_origin,
                           ti.id_prof_reg,
                           ti.id_institution_dest,
                           ti.id_prof_end,
                           ti.dt_creation_tstz,
                           ti.dt_begin_tstz,
                           ti.dt_end_tstz,
                           ti.flg_status
                      FROM transfer_institution ti
                     INNER JOIN patient pat
                        ON pat.id_patient = ti.id_patient
                     INNER JOIN epis_info ei
                        ON ei.id_episode = ti.id_episode
                     WHERE ti.id_institution_origin = i_prof.institution
                       AND ti.flg_status IN (g_transfer_inst_fin, g_transfer_inst_cancel)
                       AND (ti.dt_end_tstz > (current_timestamp - l_gap_hours / 24) OR
                           ti.dt_cancel_tstz > (current_timestamp - l_gap_hours / 24))
                       AND (ei.id_software = i_prof.software OR i_prof.software = pk_alert_constant.g_soft_adt)) t
             ORDER BY t.dt_begin_tstz NULLS LAST, t.name_pat_to_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_out_transfer_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_out_transfer_list;

    /***************************************************************************
    * get transfer list when the current institution is an origin for another institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    * @parma o_in_transfer_list       Transfer list when the institution destination is the current institution
    * @param o_out_transfer_list      Transfer list for current institution is an origin for another institution
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/21                                
    **************************************************************************/

    FUNCTION get_transfer_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_out_list OUT pk_types.cursor_type,
        o_in_list  OUT pk_types.cursor_type,
        o_label1   OUT VARCHAR2,
        o_label2   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name  VARCHAR2(30 CHAR) := 'GET_TRANSFER_LIST';
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL GET_IN_TRANSFER_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT
            get_in_transfer_list(i_lang => i_lang, i_prof => i_prof, o_in_transfer_list => o_in_list, o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL GET_OUT_TRANSFER_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT get_out_transfer_list(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     o_out_transfer_list => o_out_list,
                                     o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        o_label1 := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M019');
        o_label2 := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M020');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_out_list);
            pk_types.open_my_cursor(o_in_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_transfer_list;

    /********************************************************************************************
    * CHECK_PERMISSIONS_DEPART_DATE            Check if the logged professional has permissions 
    *                                          to register the departure date of the active 
    *                                          transfer institution record of the current episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_institution_origin   Origin institution
    * @param i_cfg_departure_date_set  Sys_config value with the professional categories that can
    *                                  register the departure date
    * @param i_flg_status              Tranfer institution record status
    * @param i_id_prof_cat             Professional category Id
    * @param i_departure_date          Departure date
    *
    * @return                          Y - the professional can register the departure date
    *                                  N - Otherwise
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_permissions_depart_date
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution_origin  IN transfer_institution.id_institution_origin%TYPE,
        i_cfg_departure_date_set IN sys_config.value%TYPE,
        i_flg_status             IN transfer_institution.flg_status%TYPE,
        i_id_prof_cat            IN category.id_category%TYPE,
        i_departure_date         IN transfer_institution.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_departure VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_error         t_error_out;
    BEGIN
        IF (i_id_institution_origin = i_prof.institution AND
           i_flg_status IN (g_transfer_inst_req, g_transfer_inst_transp, g_transfer_inst_fin)
           --it is not possible to edit the departure date
           AND i_departure_date IS NULL)
        THEN
            IF (instr(i_cfg_departure_date_set, '|' || to_char(i_id_prof_cat) || '|') != 0)
            THEN
                l_flg_departure := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_flg_departure;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'CHECK_PERMISSIONS_DEPART_DATE',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_flg_departure;
    END check_permissions_depart_date;

    /********************************************************************************************
    * CHECK_PERMISSIONS_DEPART_DATE            Check if the logged professional has permissions 
    *                                          to register the arrival date of the active 
    *                                          transfer institution record of the current episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_institution_origin   Origin institution
    * @param i_cfg_departure_date_set  Sys_config value with the professional categories that can
    *                                  register the departure date
    * @param i_flg_status              Tranfer institution record status
    * @param i_id_prof_cat             Professional category Id
    * @param i_arrival_date            Arrival date
    *
    * @return                          Y - the professional can register the departure date
    *                                  N - Otherwise
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_permissions_arrival_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution_dest  IN transfer_institution.id_institution_dest%TYPE,
        i_cfg_arrival_date_set IN sys_config.value%TYPE,
        i_flg_status           IN transfer_institution.flg_status%TYPE,
        i_id_prof_cat          IN category.id_category%TYPE,
        i_arrival_date         IN transfer_institution.dt_end_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_arrival VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_error       t_error_out;
    BEGIN
        IF (i_id_institution_dest = i_prof.institution AND
           i_flg_status IN (g_transfer_inst_req, g_transfer_inst_transp, g_transfer_inst_fin)
           --it is not possible to edit the departure date
           AND i_arrival_date IS NULL)
        THEN
            IF (instr(i_cfg_arrival_date_set, '|' || to_char(i_id_prof_cat) || '|') != 0)
            THEN
                l_flg_arrival := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_flg_arrival;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'CHECK_PERMISSIONS_ARRIVAL_DATE',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_flg_arrival;
    END check_permissions_arrival_date;

    /***************************************************************************
    * build string icon for institution transfer state
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_dt_creation_tstz       Creation date               
    *
    * OBS: the id_episode and dt_creation_tstz columns are the PK of transfer_institution
    * so that is necessary theses two parameters to calcule the string icon
    * @return string icon   
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/24                               
    **************************************************************************/

    FUNCTION get_inst_transfer_icon_string
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN transfer_institution.id_episode%TYPE,
        i_dt_creation_tstz IN transfer_institution.dt_creation_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_trf_domain  VARCHAR2(40 CHAR) := 'TRANSFER_INSTITUTION.FLG_STATUS';
        l_icon_string VARCHAR2(1000 CHAR);
    
    BEGIN
        g_error := 'GET ICON STRING';
        pk_alertlog.log_debug(g_error);
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
                                                        NULL,
                                                        NULL /* st.dt_server*/)
              INTO l_icon_string
              FROM (SELECT CASE
                                WHEN ti.flg_status IN (g_transfer_inst_req, g_transfer_inst_transp) THEN
                                 pk_alert_constant.g_display_type_date_icon
                                ELSE
                                 pk_alert_constant.g_display_type_icon
                            END display_type,
                           CASE
                                WHEN (ti.flg_status = g_transfer_inst_transp AND
                                     ti.id_institution_origin = i_prof.institution) THEN
                                 g_transfer_inst_transp_out
                                WHEN (ti.flg_status = g_transfer_inst_fin AND
                                     ti.id_institution_origin = i_prof.institution) THEN
                                 g_g_transfer_inst_fin_out
                                ELSE
                                 ti.flg_status
                            END flg_state,
                           NULL value_text,
                           CASE
                                WHEN ti.flg_status = g_transfer_inst_req THEN
                                --                                 pk_date_utils.date_send_tsz(i_lang, ti.dt_creation_tstz, i_prof)
                                 pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                                    i_timestamp => ti.dt_creation_tstz,
                                                                    i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)
                                WHEN ti.flg_status = g_transfer_inst_transp THEN
                                -- pk_date_utils.date_send_tsz(i_lang, ti.dt_begin_tstz, i_prof)
                                 pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                                    i_timestamp => ti.dt_begin_tstz,
                                                                    i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)
                                ELSE
                                 NULL
                            END value_date,
                           l_trf_domain value_icon,
                           pk_service_transfer.get_transfer_shortcut(i_lang,
                                                                     i_prof,
                                                                     pk_service_transfer.g_transfer_flg_hospital_h) shortcut,
                           NULL back_color,
                           CASE
                                WHEN ti.flg_status IN (g_transfer_inst_req, g_transfer_inst_transp) THEN
                                 pk_alert_constant.g_color_icon_light_grey
                                WHEN ti.flg_status = g_transfer_inst_fin THEN
                                 pk_alert_constant.g_color_icon_dark_grey
                            END icon_color,
                           NULL message_style,
                           NULL message_color,
                           NULL flg_text_domain,
                           current_timestamp dt_server
                      FROM transfer_institution ti
                     WHERE ti.id_episode = i_id_episode
                       AND ti.dt_creation_tstz = i_dt_creation_tstz) st;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_icon_string := NULL;
        END;
    
        RETURN l_icon_string;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_inst_transfer_icon_string;

    /********************************************************************************************
    * check_create_transfer            Check if it is possible to create an institution tranfer 
    *                                  in the current episode
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_episode              Episode institution
    * @param o_flg_create              Y-It is possible to create an institution transfer
    *                                  N-otherwise
    *
    * @return                          TRUE-success; FALSE-error
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           25-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_create_transfer
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_create OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_flg_status     episode.flg_status%TYPE;
    BEGIN
        g_error := 'CALL pk_episode.get_flg_status. i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_id_episode,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_flg_status = pk_alert_constant.g_active)
        THEN
            o_flg_create := pk_alert_constant.g_yes;
        ELSE
            o_flg_create := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'CHECK_CREATE_TRANSFER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_create_transfer;

    /********************************************************************************************
    * CHECK_EPISODES_FOR_VISIT         Check the number of active Episodes in the same visit 
    *
    * @param i_id_episode              Episode ID to all others
    *
    * @return                          More than one episode for visit (Y/N)
    *
    * @author                          António Neto
    * @version                         2.5.1.4
    * @since                           25-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_episodes_for_visit(i_id_episode IN episode.id_episode%TYPE) RETURN VARCHAR2 IS
        CURSOR c_episodes IS
            SELECT CASE
                        WHEN COUNT(1) > 1 THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_num_epis
              FROM episode epis_act
             INNER JOIN episode epis_visit
                ON epis_act.id_visit = epis_visit.id_visit
             WHERE epis_act.id_episode = i_id_episode
               AND epis_visit.flg_status = g_epis_active;
    
        l_ret VARCHAR2(1 CHAR);
    BEGIN
    
        OPEN c_episodes;
        FETCH c_episodes
            INTO l_ret;
    
        IF c_episodes%NOTFOUND
        THEN
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END check_episodes_for_visit;

    FUNCTION get_first_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN transfer_institution%ROWTYPE,
        i_flg_screen IN VARCHAR2,
        i_labels     IN table_varchar,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar
    ) RETURN BOOLEAN IS
        l_origin_institution  VARCHAR2(4000 CHAR);
        l_destiny_institution VARCHAR2(4000 CHAR);
        l_desc_transport      VARCHAR2(4000 CHAR);
        l_desc_service        VARCHAR2(4000 CHAR);
        l_desc_specialty      VARCHAR2(4000 CHAR);
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          INTO l_origin_institution
          FROM institution i
         WHERE i.id_institution = i_actual_row.id_institution_origin;
    
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          INTO l_destiny_institution
          FROM institution i
         WHERE i.id_institution = i_actual_row.id_institution_dest;
    
        IF i_actual_row.id_transp_entity IS NOT NULL
        THEN
        
            SELECT pk_translation.get_translation(i_lang, t.code_transp_entity)
              INTO l_desc_transport
              FROM transp_entity t
             WHERE t.id_transp_entity = i_actual_row.id_transp_entity;
        ELSE
            l_desc_transport := pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T013');
        END IF;
    
        IF i_actual_row.id_dep_clin_serv IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, dep.code_department),
                   pk_translation.get_translation(i_lang, cs.code_clinical_service)
              INTO l_desc_service, l_desc_specialty
              FROM dep_clin_serv dcs
             INNER JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             INNER JOIN department dep
                ON dcs.id_department = dep.id_department
             WHERE dcs.id_dep_clin_serv = i_actual_row.id_dep_clin_serv;
        END IF;
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status_aux,
                                                                         i_val      => CASE
                                                                                           WHEN i_flg_screen = g_history_h THEN
                                                                                            g_transfer_inst_req
                                                                                           ELSE
                                                                                            i_actual_row.flg_status
                                                                                       END,
                                                                         i_lang     => i_lang),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_title_t);
    
        --profissional que requisitou
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T068'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                  i_prof,
                                                                                  i_actual_row.id_prof_reg),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        --Request Date
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T006'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                             i_actual_row.dt_creation_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        --origin institution
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T058'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_origin_institution,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        --destiny institution
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T059'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_destiny_institution,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        --destiny Service
        IF i_actual_row.id_dep_clin_serv IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T064'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_desc_service,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => g_content_c);
        
            --destiny Specialty
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T065'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_desc_specialty,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => g_content_c);
        END IF;
    
        --Transport
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T007'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_desc_transport,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        --Notes
        IF i_actual_row.notes IS NOT NULL
        THEN
        
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T012'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => i_actual_row.notes,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => g_content_c);
        END IF;
    
        --Cancel reason
        IF i_actual_row.id_cancel_reason IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T075'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                             i_prof             => i_prof,
                                                                                             i_id_cancel_reason => i_actual_row.id_cancel_reason),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => g_content_c);
        
        END IF;
    
        --Status
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T008'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                         i_val      => CASE
                                                                                           WHEN i_flg_screen = g_history_h THEN
                                                                                            g_transfer_inst_req
                                                                                           ELSE
                                                                                            get_domain_status(i_lang             => i_lang,
                                                                                                              i_prof             => i_prof,
                                                                                                              i_flg_status       => i_actual_row.flg_status,
                                                                                                              i_institution_dest => i_actual_row.id_institution_dest)
                                                                                       
                                                                                       END,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        IF (i_flg_screen = g_detail_d)
        THEN
            --set an empty new line
            IF (i_actual_row.dt_begin_tstz IS NOT NULL OR i_actual_row.dt_end_tstz IS NOT NULL)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_line_l);
            END IF;
        
            --departure date
            IF (i_actual_row.dt_begin_tstz IS NOT NULL)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T069'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_begin_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T071'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                          i_prof,
                                                                                          i_actual_row.id_prof_begin),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            END IF;
        
            --arrival date
            IF (i_actual_row.dt_end_tstz IS NOT NULL)
            THEN
                --set an empty new line
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_line_l);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T070'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_end_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T072'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                          i_prof,
                                                                                          i_actual_row.id_prof_end),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            END IF;
        
            --cancellation fields
            IF (i_actual_row.dt_cancel_tstz IS NOT NULL)
            THEN
                --set an empty new line
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_line_l);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T074'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_cancel_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T073'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_prof_utils.get_name_signature(i_lang,
                                                                                          i_prof,
                                                                                          i_actual_row.id_prof_cancel),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            END IF;
        END IF;
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_service_transfer.get_signature(i_lang                => i_lang,
                                                                                   i_prof                => i_prof,
                                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                                   i_date                => CASE
                                                                                                                WHEN i_flg_screen = g_detail_d THEN
                                                                                                                 coalesce(i_actual_row.dt_end_tstz,
                                                                                                                          i_actual_row.dt_begin_tstz,
                                                                                                                          i_actual_row.dt_cancel_tstz,
                                                                                                                          i_actual_row.dt_creation_tstz)
                                                                                                                ELSE
                                                                                                                 i_actual_row.dt_creation_tstz
                                                                                                            END,
                                                                                   i_id_prof_last_change => CASE
                                                                                                                WHEN i_flg_screen = g_detail_d THEN
                                                                                                                 coalesce(i_actual_row.id_prof_cancel,
                                                                                                                          i_actual_row.id_prof_end,
                                                                                                                          i_actual_row.id_prof_begin,
                                                                                                                          i_actual_row.id_prof_reg
                                                                                                                          
                                                                                                                          )
                                                                                                                ELSE
                                                                                                                 i_actual_row.id_prof_reg
                                                                                                            END),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_signature_s);
    
        RETURN TRUE;
    END get_first_values;

    FUNCTION get_canceled
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_actual_row     IN transfer_institution%ROWTYPE,
        i_flg_screen     IN VARCHAR2,
        i_labels         IN table_varchar,
        i_prv_flg_status IN transfer_institution.flg_status%TYPE,
        o_tbl_labels     OUT table_varchar,
        o_tbl_values     OUT table_varchar,
        o_tbl_types      OUT table_varchar
    ) RETURN BOOLEAN IS
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status_aux,
                                                                         i_val      => g_transfer_inst_cancel,
                                                                         i_lang     => i_lang),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_title_t);
    
        --New state
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T060'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                         i_val      => g_transfer_inst_cancel,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_new_content_n);
    
        --Old state
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T008'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                         i_val      => get_domain_status(i_lang             => i_lang,
                                                                                                         i_prof             => i_prof,
                                                                                                         i_flg_status       => i_prv_flg_status,
                                                                                                         i_institution_dest => i_actual_row.id_institution_dest),
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_content_c);
    
        --Cancel reason
        IF i_actual_row.id_cancel_reason IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T075'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                             i_prof             => i_prof,
                                                                                             i_id_cancel_reason => i_actual_row.id_cancel_reason),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => g_new_content_n);
        END IF;
        --Canceling Notes
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T063'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => i_actual_row.notes_cancel,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_new_content_n);
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_service_transfer.get_signature(i_lang                => i_lang,
                                                                                   i_prof                => i_prof,
                                                                                   i_id_episode          => i_actual_row.id_episode,
                                                                                   i_date                => i_actual_row.dt_cancel_tstz,
                                                                                   i_id_prof_last_change => i_actual_row.id_prof_cancel),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => g_signature_s);
    
        RETURN TRUE;
    END get_canceled;

    FUNCTION get_in_transport
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN transfer_institution%ROWTYPE,
        i_flg_screen  IN VARCHAR2,
        i_labels      IN table_varchar,
        o_tbl_labels  OUT table_varchar,
        o_tbl_values  OUT table_varchar,
        o_tbl_types   OUT table_varchar,
        io_flg_cancel IN OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        IF i_actual_row.dt_cancel_tstz IS NOT NULL
           AND ((i_actual_row.dt_cancel_tstz < i_actual_row.dt_begin_tstz OR i_actual_row.dt_begin_tstz IS NULL) AND
           i_actual_row.dt_begin_tstz IS NULL)
        THEN
            IF io_flg_cancel = pk_alert_constant.g_no
            THEN
                IF NOT get_canceled(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_actual_row     => i_actual_row,
                                    i_flg_screen     => i_flg_screen,
                                    i_labels         => i_labels,
                                    i_prv_flg_status => g_transfer_inst_req,
                                    o_tbl_labels     => o_tbl_labels,
                                    o_tbl_values     => o_tbl_values,
                                    o_tbl_types      => o_tbl_types)
                THEN
                    RETURN FALSE;
                ELSE
                    io_flg_cancel := pk_alert_constant.g_yes;
                END IF;
            END IF;
        ELSE
            IF i_actual_row.dt_begin_tstz IS NOT NULL
            THEN
                --title
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_sysdomain.get_domain(g_sd_flg_status_aux,
                                                                                 g_transfer_inst_transp,
                                                                                 i_lang),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_title_t);
            
                --New state
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T060'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_sysdomain.get_domain(g_sd_flg_status,
                                                                                 get_domain_status(i_lang             => i_lang,
                                                                                                   i_prof             => i_prof,
                                                                                                   i_flg_status       => g_transfer_inst_transp,
                                                                                                   i_institution_dest => i_actual_row.id_institution_dest),
                                                                                 i_lang),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_new_content_n);
            
                --Old state
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T008'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_sysdomain.get_domain(g_sd_flg_status,
                                                                                 g_transfer_inst_req,
                                                                                 i_lang),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            
                --In Transport Date
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T061'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_begin_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_new_content_n);
            
                --signature
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_service_transfer.get_signature(i_lang                => i_lang,
                                                                                           i_prof                => i_prof,
                                                                                           i_id_episode          => i_actual_row.id_episode,
                                                                                           i_date                => i_actual_row.dt_begin_tstz,
                                                                                           i_id_prof_last_change => i_actual_row.id_prof_begin),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_signature_s);
            END IF;
        END IF;
    
        RETURN TRUE;
    END get_in_transport;

    FUNCTION get_finish
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_actual_row  IN transfer_institution%ROWTYPE,
        i_flg_screen  IN VARCHAR2,
        i_labels      IN table_varchar,
        o_tbl_labels  OUT table_varchar,
        o_tbl_values  OUT table_varchar,
        o_tbl_types   OUT table_varchar,
        io_flg_cancel IN OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
    
        IF i_actual_row.dt_cancel_tstz IS NOT NULL
           AND ((i_actual_row.dt_cancel_tstz < i_actual_row.dt_end_tstz OR i_actual_row.dt_end_tstz IS NULL) AND
           i_actual_row.dt_begin_tstz IS NOT NULL)
        THEN
            IF NOT get_canceled(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_actual_row     => i_actual_row,
                                i_flg_screen     => i_flg_screen,
                                i_labels         => i_labels,
                                i_prv_flg_status => g_transfer_inst_transp,
                                o_tbl_labels     => o_tbl_labels,
                                o_tbl_values     => o_tbl_values,
                                o_tbl_types      => o_tbl_types)
            THEN
                RETURN FALSE;
            ELSE
                io_flg_cancel := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            IF i_actual_row.dt_end_tstz IS NOT NULL
            THEN
                --title
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status_aux,
                                                                                 i_val      => g_transfer_inst_fin,
                                                                                 i_lang     => i_lang),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_title_t);
            
                --New state
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T060'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                                 i_val      => get_domain_status(i_lang             => i_lang,
                                                                                                                 i_prof             => i_prof,
                                                                                                                 i_flg_status       => g_transfer_inst_fin,
                                                                                                                 i_institution_dest => i_actual_row.id_institution_dest),
                                                                                 i_lang     => i_lang),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_new_content_n);
            
                --Old state
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T008'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_sysdomain.get_domain(i_code_dom => g_sd_flg_status,
                                                                                 i_val      => get_domain_status(i_lang             => i_lang,
                                                                                                                 i_prof             => i_prof,
                                                                                                                 i_flg_status       => g_transfer_inst_transp,
                                                                                                                 i_institution_dest => i_actual_row.id_institution_dest),
                                                                                 i_lang     => i_lang),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_content_c);
            
                --Finish Date
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => pk_message.get_message(i_lang, 'TRANSFER_INSTITUTION_T062'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_end_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_new_content_n);
            
                --signature
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_service_transfer.get_signature(i_lang                => i_lang,
                                                                                           i_prof                => i_prof,
                                                                                           i_id_episode          => i_actual_row.id_episode,
                                                                                           i_date                => i_actual_row.dt_end_tstz,
                                                                                           i_id_prof_last_change => i_actual_row.id_prof_end),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => g_signature_s);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END get_finish;

    /********************************************************************************************
    * GET_TRANSFER_EPIS_DET                Get the transfer service detail and history data.
    *
    * @param   i_lang                      Language associated to the professional executing the request
    * @param   i_prof                      Professional Identification
    * @param   i_id_episode                Episode ID
    * @param   i_dt_creation               Creation Date of Transfer
    * @param   i_flg_screen                Flag of Detail type (D-detail; H-history)
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              António Neto
    * @version                             2.5.1.4
    * @since                               28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_transfer_epis_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_dt_creation IN VARCHAR2,
        i_flg_screen  IN VARCHAR2,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_TRANSFER_EPIS_DET';
    
        l_dt_creation_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_transf_data      transfer_institution%ROWTYPE;
        l_tab_hist         t_table_history_data := t_table_history_data();
    
        l_tbl_lables table_varchar := table_varchar();
        l_tbl_values table_varchar := table_varchar();
        l_tbl_types  table_varchar := table_varchar();
    
        l_info_labels table_varchar;
        l_info_values table_varchar;
    
        l_labels         table_varchar := table_varchar();
        l_internal_error EXCEPTION;
        l_flg_cancel     VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        FUNCTION get_info_labels RETURN table_varchar IS
            l_table table_varchar := table_varchar();
        BEGIN
            --RECORD_STATE
            pk_inp_detail.add_value(io_table => l_table, i_value => 'RECORD_STATE_TO_FORMAT');
        
            RETURN l_table;
        END get_info_labels;
    
        FUNCTION get_info_values(i_row_flg_status IN epis_prof_resp.flg_status%TYPE) RETURN table_varchar IS
            l_table table_varchar := table_varchar();
        BEGIN
            --RECORD_STATE
            pk_inp_detail.add_value(io_table => l_table,
                                    i_value  => CASE
                                                    WHEN i_row_flg_status = g_transfer_inst_cancel THEN
                                                     g_transfer_inst_cancel
                                                    ELSE
                                                     g_transfer_det_active_a
                                                END);
        
            RETURN l_table;
        END get_info_values;
    BEGIN
    
        g_error := 'CONVERT INTO TIMESTAMP';
        IF i_dt_creation IS NOT NULL
        THEN
            l_dt_creation_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_creation, NULL);
        END IF;
    
        g_error := 'GET DATA FROM TRANSFER RECORD';
        SELECT *
          INTO l_transf_data
          FROM transfer_institution ti
         WHERE ti.id_episode = i_id_episode
           AND (ti.dt_creation_tstz = l_dt_creation_tstz OR ti.dt_creation_tstz IS NULL);
    
        l_info_labels := get_info_labels();
        l_info_values := get_info_values(l_transf_data.flg_status);
    
        IF i_flg_screen = g_history_h
        THEN
            g_error := 'CALL get_finish';
            pk_alertlog.log_debug(g_error);
            IF NOT get_finish(i_lang        => i_lang,
                              i_prof        => i_prof,
                              i_actual_row  => l_transf_data,
                              i_flg_screen  => i_flg_screen,
                              i_labels      => l_labels,
                              o_tbl_labels  => l_tbl_lables,
                              o_tbl_values  => l_tbl_values,
                              o_tbl_types   => l_tbl_types,
                              io_flg_cancel => l_flg_cancel)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_tbl_lables.count > 0
            THEN
                l_tab_hist.extend;
                l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_transf_data.id_episode,
                                                                   flg_status      => CASE
                                                                                          WHEN l_flg_cancel = pk_alert_constant.g_yes THEN
                                                                                           g_transfer_inst_cancel
                                                                                          ELSE
                                                                                           g_transfer_inst_fin
                                                                                      END,
                                                                   date_rec        => NULL,
                                                                   tbl_labels      => l_tbl_lables,
                                                                   tbl_values      => l_tbl_values,
                                                                   tbl_types       => l_tbl_types,
                                                                   tbl_info_labels => l_info_labels,
                                                                   tbl_info_values => l_info_values,
                                                                   table_origin    => NULL);
            END IF;
        
            g_error := 'CALL get_in_transport';
            pk_alertlog.log_debug(g_error);
            IF NOT get_in_transport(i_lang        => i_lang,
                                    i_prof        => i_prof,
                                    i_actual_row  => l_transf_data,
                                    i_flg_screen  => i_flg_screen,
                                    i_labels      => l_labels,
                                    o_tbl_labels  => l_tbl_lables,
                                    o_tbl_values  => l_tbl_values,
                                    o_tbl_types   => l_tbl_types,
                                    io_flg_cancel => l_flg_cancel)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_tbl_lables.count > 0
            THEN
                l_tab_hist.extend;
                l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_transf_data.id_episode,
                                                                   flg_status      => CASE
                                                                                          WHEN l_flg_cancel = pk_alert_constant.g_yes THEN
                                                                                           g_transfer_inst_cancel
                                                                                          ELSE
                                                                                           g_transfer_inst_transp
                                                                                      END,
                                                                   date_rec        => NULL,
                                                                   tbl_labels      => l_tbl_lables,
                                                                   tbl_values      => l_tbl_values,
                                                                   tbl_types       => l_tbl_types,
                                                                   tbl_info_labels => l_info_labels,
                                                                   tbl_info_values => l_info_values,
                                                                   table_origin    => NULL);
            END IF;
        
        END IF;
    
        g_error := 'CALL get_first_values';
        pk_alertlog.log_debug(g_error);
        IF NOT get_first_values(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_actual_row => l_transf_data,
                                i_flg_screen => i_flg_screen,
                                i_labels     => l_labels,
                                o_tbl_labels => l_tbl_lables,
                                o_tbl_values => l_tbl_values,
                                o_tbl_types  => l_tbl_types)
        THEN
            RETURN FALSE;
        ELSE
            l_info_labels := get_info_labels();
            l_info_values := table_varchar(CASE
                                               WHEN i_flg_screen = g_history_h THEN
                                                g_transfer_det_active_a
                                               ELSE
                                                l_transf_data.flg_status
                                           END);
        END IF;
    
        l_tab_hist.extend;
        l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_transf_data.id_episode,
                                                           flg_status      => CASE
                                                                                  WHEN i_flg_screen = g_history_h THEN
                                                                                   g_transfer_inst_req
                                                                                  ELSE
                                                                                   l_transf_data.flg_status
                                                                              END,
                                                           date_rec        => NULL,
                                                           tbl_labels      => l_tbl_lables,
                                                           tbl_values      => l_tbl_values,
                                                           tbl_types       => l_tbl_types,
                                                           tbl_info_labels => l_info_labels,
                                                           tbl_info_values => l_info_values,
                                                           table_origin    => NULL);
    
        g_error := 'OPEN o_data';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_data FOR
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
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_transfer_epis_det;

    /***************************************************************************
    * Returns the status to be used when getting the icon from sys_domain.
    * Checks if the transfer is being done to the prof institution or 
    * other institution in order to determine which status to return.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_flg_status             Transfer institution status
    * @param i_institution_dest       Destiny institution
    * @param i_id_episode             Episode ID
    * @param i_dt_creation_tstz       Creation date               
    *
    * OBS: the id_episode and dt_creation_tstz columns are the PK of transfer_institution
    * so that is necessary theses two parameters to get the transfer institution record.
    * To be used when it is not given the i_flg_status, i_institution_origin and i_institution_dest
    *
    * @return status of the sys_domain
    *                                                                         
    * @author                         Sofia Mendes                         
    * @version                        2.5.1                                  
    * @since                          24-Mar-2011                              
    **************************************************************************/
    FUNCTION get_domain_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN transfer_institution.flg_status%TYPE,
        i_institution_dest IN transfer_institution.id_institution_origin%TYPE,
        i_id_episode       IN transfer_institution.id_episode%TYPE DEFAULT NULL,
        i_dt_creation_tstz IN transfer_institution.dt_creation_tstz%TYPE DEFAULT NULL
    ) RETURN transfer_institution.flg_status%TYPE IS
        l_id_institution_dest transfer_institution.id_institution_dest%TYPE;
        l_flg_status          VARCHAR2(2 CHAR);
        l_internal_error      EXCEPTION;
        l_error               t_error_out;
    BEGIN
        IF (i_flg_status IS NULL)
        THEN
            g_error := 'GET id_institution_origin and id_institution_dest. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT ti.id_institution_dest, ti.flg_status
              INTO l_id_institution_dest, l_flg_status
              FROM transfer_institution ti
             WHERE ti.id_episode = i_id_episode
               AND ti.dt_creation_tstz = i_dt_creation_tstz;
        ELSE
            l_flg_status          := i_flg_status;
            l_id_institution_dest := i_institution_dest;
        END IF;
    
        IF (l_flg_status = g_transfer_inst_transp)
        THEN
            IF (i_prof.institution <> l_id_institution_dest)
            THEN
                l_flg_status := g_transfer_inst_transp_out;
            END IF;
        ELSIF (l_flg_status = g_transfer_inst_fin)
        THEN
            IF (i_prof.institution <> l_id_institution_dest)
            THEN
                l_flg_status := g_g_transfer_inst_fin_out;
            END IF;
        END IF;
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_DOMAIN_STATUS',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_domain_status;

    /********************************************************************************************
    * Return the most recent transfer institution record of the given episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        1.0   
    * @since                          04/10/2011
    **********************************************************************************************/
    FUNCTION tf_most_recent_transfer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN t_transfer_inst
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'TF_MOST_RECENT_TRANSFER';
        --
        l_one CONSTANT PLS_INTEGER := 1;
    BEGIN
        g_error := 'GET MOST RECENT TRANSFER RECORD';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FOR r_transfer_inst IN (SELECT t.id_institution_origin,
                                       t.id_institution_dest,
                                       t.dt_creation_tstz,
                                       t.id_transp_entity,
                                       t.notes,
                                       t.dt_begin_tstz,
                                       t.dt_end_tstz,
                                       t.flg_status,
                                       t.id_prof_reg,
                                       t.id_prof_begin,
                                       t.id_prof_end,
                                       t.id_episode,
                                       t.id_patient,
                                       t.id_transfer_option,
                                       t.id_prof_cancel,
                                       t.dt_cancel_tstz,
                                       t.notes_cancel,
                                       t.id_dep_clin_serv,
                                       t.create_user,
                                       t.create_time,
                                       t.create_institution,
                                       t.update_user,
                                       t.update_time,
                                       t.update_institution,
                                       t.id_cancel_reason
                                  FROM (SELECT ti.*, row_number() over(ORDER BY ti.dt_creation_tstz DESC) line_number
                                          FROM transfer_institution ti
                                         WHERE ti.id_episode = i_episode) t
                                 WHERE t.line_number = l_one)
        LOOP
            PIPE ROW(r_transfer_inst);
        END LOOP;
    
        RETURN;
    END tf_most_recent_transfer;

    /********************************************************************************************
    * Returns only the most recent transfer institution records
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        1.0   
    * @since                          04/10/2011
    **********************************************************************************************/
    FUNCTION tf_most_recent_transfer
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_transfer_inst
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'TF_MOST_RECENT_TRANSFER';
    BEGIN
        g_error := 'GET MOST RECENT TRANSFER RECORD';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FOR r_transfer_inst IN (SELECT t.id_institution_origin,
                                       t.id_institution_dest,
                                       t.dt_creation_tstz,
                                       t.id_transp_entity,
                                       t.notes,
                                       t.dt_begin_tstz,
                                       t.dt_end_tstz,
                                       t.flg_status,
                                       t.id_prof_reg,
                                       t.id_prof_begin,
                                       t.id_prof_end,
                                       t.id_episode,
                                       t.id_patient,
                                       t.id_transfer_option,
                                       t.id_prof_cancel,
                                       t.dt_cancel_tstz,
                                       t.notes_cancel,
                                       t.id_dep_clin_serv,
                                       t.create_user,
                                       t.create_time,
                                       t.create_institution,
                                       t.update_user,
                                       t.update_time,
                                       t.update_institution,
                                       t.id_cancel_reason
                                  FROM transfer_institution t
                                  JOIN (SELECT ti.id_episode, MAX(ti.dt_creation_tstz) dt_creation_tstz
                                         FROM transfer_institution ti
                                        GROUP BY ti.id_episode) t1
                                    ON t1.id_episode = t.id_episode
                                   AND t1.dt_creation_tstz = t.dt_creation_tstz)
        LOOP
            PIPE ROW(r_transfer_inst);
        END LOOP;
    
        RETURN;
    END tf_most_recent_transfer;
BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_transfer_institution;
/
