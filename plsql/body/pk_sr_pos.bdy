/*-- Last Change Revision: $Rev: 2027739 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_pos IS

    g_exception EXCEPTION;

    /**************************************************************************
    *                                                                         *
    *  Function that manages the inserts and updates on SR_POS_SCHEDULE       *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   01-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_sr_pos_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sr_pos_status    IN sr_pos_schedule.id_sr_pos_status%TYPE DEFAULT NULL,
        i_id_schedule_sr      IN sr_pos_schedule.id_schedule_sr%TYPE DEFAULT NULL,
        i_flg_status          IN sr_pos_schedule.flg_status%TYPE,
        i_id_prof_reg         IN sr_pos_schedule.id_prof_reg%TYPE DEFAULT NULL,
        i_dt_reg              IN sr_pos_schedule.dt_reg%TYPE DEFAULT NULL,
        i_dt_pos_suggested    IN sr_pos_schedule.dt_pos_suggested%TYPE DEFAULT NULL,
        i_req_notes           IN sr_pos_schedule.req_notes%TYPE DEFAULT NULL,
        i_id_prof_req         IN sr_pos_schedule.id_prof_req%TYPE DEFAULT NULL,
        i_dt_req              IN sr_pos_schedule.dt_req%TYPE DEFAULT NULL,
        i_dt_valid            IN sr_pos_schedule.dt_valid%TYPE DEFAULT NULL,
        i_valid_days          IN sr_pos_schedule.valid_days%TYPE DEFAULT NULL,
        i_decision_notes      IN sr_pos_schedule.decision_notes%TYPE DEFAULT NULL,
        i_id_prof_decision    IN sr_pos_schedule.id_prof_decision%TYPE DEFAULT NULL,
        i_dt_decision         IN sr_pos_schedule.dt_decision%TYPE DEFAULT NULL,
        io_id_sr_pos_schedule IN OUT sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name    VARCHAR2(30) := 'SET_SR_POS_SCHEDULE';
        l_sps_rec          sr_pos_schedule%ROWTYPE;
        l_sps_rec_bck      sr_pos_schedule%ROWTYPE;
        l_rows             table_varchar;
        l_tbl_diffs        table_table_varchar;
        l_id_sr_pos_status sr_pos_status.id_sr_pos_status%TYPE;
        l_is_notneeded     NUMBER;
    BEGIN
        BEGIN
            g_error := 'GET sr_pos_schedule RECORD';
            pk_alertlog.log_debug(g_error);
            SELECT sps.*
              INTO l_sps_rec_bck
              FROM sr_pos_schedule sps
             WHERE sps.id_sr_pos_schedule = io_id_sr_pos_schedule;
        EXCEPTION
            WHEN no_data_found THEN
                io_id_sr_pos_schedule            := ts_sr_pos_schedule.next_key;
                l_sps_rec_bck.id_sr_pos_schedule := NULL;
        END;
    
        g_error := 'GET i_id_sr_pos_status';
        pk_alertlog.log_debug(g_error);
        IF (i_id_sr_pos_status IS NULL)
        THEN
            SELECT id_sr_pos_status
              INTO l_id_sr_pos_status
              FROM (SELECT sps.id_sr_pos_status, rank() over(ORDER BY sps.id_institution DESC) origin_rank
                      FROM sr_pos_status sps
                     WHERE sps.id_institution IN (0, i_prof.institution)
                       AND sps.flg_available = pk_alert_constant.g_yes
                       AND sps.flg_status = CASE
                               WHEN i_dt_pos_suggested IS NULL THEN
                                pk_alert_constant.g_sr_pos_status_no
                               ELSE
                                pk_alert_constant.g_sr_pos_status_nd
                           END)
             WHERE origin_rank = 1;
        ELSE
            l_id_sr_pos_status := i_id_sr_pos_status;
        END IF;
    
        g_error := 'Check not needed status';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_is_notneeded
          FROM sr_pos_status sps
         WHERE sps.id_sr_pos_status = l_id_sr_pos_status
           AND sps.flg_status = pk_alert_constant.g_sr_pos_status_no;
    
        g_error := 'PREPARE RECORD';
        pk_alertlog.log_debug(g_error);
        l_sps_rec.id_sr_pos_schedule := io_id_sr_pos_schedule;
        l_sps_rec.id_sr_pos_status   := l_id_sr_pos_status;
        l_sps_rec.id_schedule_sr     := nvl(i_id_schedule_sr, l_sps_rec_bck.id_schedule_sr);
        l_sps_rec.flg_status         := nvl(i_flg_status, l_sps_rec_bck.flg_status);
        l_sps_rec.id_prof_reg        := nvl(i_id_prof_reg, l_sps_rec_bck.id_prof_reg);
        l_sps_rec.dt_reg             := nvl(i_dt_reg, l_sps_rec_bck.dt_reg);
        l_sps_rec.dt_pos_suggested := CASE
                                          WHEN l_is_notneeded >= 1 THEN
                                           i_dt_pos_suggested
                                          ELSE
                                           nvl(i_dt_pos_suggested, l_sps_rec_bck.dt_pos_suggested)
                                      END;
        l_sps_rec.req_notes := CASE
                                   WHEN l_is_notneeded >= 1 THEN
                                    i_req_notes
                                   ELSE
                                    nvl(i_req_notes, l_sps_rec_bck.req_notes)
                               END;
        l_sps_rec.id_prof_req        := nvl(i_id_prof_req, l_sps_rec_bck.id_prof_req);
        l_sps_rec.dt_req             := nvl(i_dt_req, l_sps_rec_bck.dt_req);
        l_sps_rec.dt_valid           := i_dt_valid;
        l_sps_rec.valid_days         := i_valid_days;
        l_sps_rec.decision_notes     := i_decision_notes;
        l_sps_rec.id_prof_decision   := nvl(i_id_prof_decision, l_sps_rec_bck.id_prof_decision);
        l_sps_rec.dt_decision        := nvl(i_dt_decision, l_sps_rec_bck.dt_decision);
    
        g_error := 'UPDATE RECORD';
        pk_alertlog.log_debug(g_error);
        ts_sr_pos_schedule.upd(id_sr_pos_schedule_in => l_sps_rec.id_sr_pos_schedule,
                               id_sr_pos_status_in   => l_sps_rec.id_sr_pos_status,
                               id_schedule_sr_in     => l_sps_rec.id_schedule_sr,
                               flg_status_in         => l_sps_rec.flg_status,
                               id_prof_reg_in        => l_sps_rec.id_prof_reg,
                               dt_reg_in             => l_sps_rec.dt_reg,
                               dt_pos_suggested_in   => l_sps_rec.dt_pos_suggested,
                               dt_pos_suggested_nin  => FALSE,
                               req_notes_in          => l_sps_rec.req_notes,
                               req_notes_nin         => FALSE,
                               id_prof_req_in        => l_sps_rec.id_prof_req,
                               dt_req_in             => l_sps_rec.dt_req,
                               dt_valid_in           => l_sps_rec.dt_valid,
                               dt_valid_nin          => FALSE,
                               valid_days_in         => l_sps_rec.valid_days,
                               valid_days_nin        => FALSE,
                               decision_notes_in     => l_sps_rec.decision_notes,
                               decision_notes_nin    => FALSE,
                               id_prof_decision_in   => l_sps_rec.id_prof_decision,
                               dt_decision_in        => l_sps_rec.dt_decision,
                               rows_out              => l_rows);
    
        IF SQL%ROWCOUNT = 0
        THEN
            g_error := 'INSERT RECORD';
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_schedule.ins(id_sr_pos_schedule_in => l_sps_rec.id_sr_pos_schedule,
                                   id_sr_pos_status_in   => l_sps_rec.id_sr_pos_status,
                                   id_schedule_sr_in     => l_sps_rec.id_schedule_sr,
                                   flg_status_in         => l_sps_rec.flg_status,
                                   id_prof_reg_in        => l_sps_rec.id_prof_reg,
                                   dt_reg_in             => l_sps_rec.dt_reg,
                                   dt_pos_suggested_in   => l_sps_rec.dt_pos_suggested,
                                   req_notes_in          => l_sps_rec.req_notes,
                                   id_prof_req_in        => l_sps_rec.id_prof_req,
                                   dt_req_in             => l_sps_rec.dt_req,
                                   dt_valid_in           => l_sps_rec.dt_valid,
                                   valid_days_in         => l_sps_rec.valid_days,
                                   decision_notes_in     => l_sps_rec.decision_notes,
                                   id_prof_decision_in   => l_sps_rec.id_prof_decision,
                                   dt_decision_in        => l_sps_rec.dt_decision,
                                   rows_out              => l_rows);
        
        END IF;
    
        IF (l_sps_rec_bck.id_sr_pos_schedule IS NOT NULL)
        THEN
            g_error := 'PROCESS UPDATE RECORD';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
            l_rows := table_varchar();
        
            g_error := 'INSERT HISTORY';
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_schedule_hist.ins(id_sr_pos_schedule_hist_in => ts_sr_pos_schedule_hist.next_key,
                                        id_sr_pos_schedule_in      => l_sps_rec_bck.id_sr_pos_schedule,
                                        id_sr_pos_status_in        => l_sps_rec_bck.id_sr_pos_status,
                                        id_schedule_sr_in          => l_sps_rec_bck.id_schedule_sr,
                                        flg_status_in              => l_sps_rec_bck.flg_status,
                                        id_prof_reg_in             => l_sps_rec_bck.id_prof_reg,
                                        dt_reg_in                  => l_sps_rec_bck.dt_reg,
                                        dt_pos_suggested_in        => l_sps_rec_bck.dt_pos_suggested,
                                        req_notes_in               => l_sps_rec_bck.req_notes,
                                        id_prof_req_in             => l_sps_rec_bck.id_prof_req,
                                        dt_req_in                  => l_sps_rec_bck.dt_req,
                                        dt_valid_in                => l_sps_rec_bck.dt_valid,
                                        valid_days_in              => l_sps_rec_bck.valid_days,
                                        decision_notes_in          => l_sps_rec_bck.decision_notes,
                                        id_prof_decision_in        => l_sps_rec_bck.id_prof_decision,
                                        dt_decision_in             => l_sps_rec_bck.dt_decision,
                                        rows_out                   => l_rows);
        
            g_error := 'PROCESS INSERT HISTORY';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE_HIST',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        ELSE
            g_error := 'PROCESS INSERT RECORD';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
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
    END set_sr_pos_schedule;

    /**************************************************************************
    * Table Function that returns the detail of a POS request                 *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_doc_area               the doc_area id                         *
    * @param i_episode                the episode id                          *
    *                                                                         *
    * @return                         return detail of a POS request          *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_pos_req_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE
    ) RETURN t_tbl_pos_req_detail IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_POS_REQ_DETAIL';
        l_tbl t_tbl_pos_req_detail;
    
    BEGIN
        --Get list of values
        g_error := 'FILL t_tbl_pos_val_detail';
        pk_alertlog.log_debug(g_error);
        SELECT t_rec_pos_req_detail(t.id_sr_pos_schedule,
                                    t.id_prof_req,
                                    t.dt_req,
                                    t.req_notes,
                                    t.id_sr_pos_status,
                                    t.desc_decision,
                                    t.valid_days,
                                    t.dt_valid,
                                    t.decision_notes,
                                    t.id_prof_reg,
                                    t.dt_reg,
                                    t.id_episode,
                                    t.flg_status,
                                    t.dt_pos_suggested)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT sps.id_sr_pos_schedule,
                       sps.id_prof_req,
                       sps.dt_req,
                       sps.req_notes,
                       sps.id_sr_pos_status,
                       --pk_sysdomain.get_domain(i_lang, i_prof, 'SR_POS_STATUS.FLG_STATUS', spst.flg_status, NULL) desc_decision,
                       pk_translation.get_translation(i_lang, spst.code) desc_decision,
                       sps.valid_days,
                       sps.dt_valid,
                       sps.decision_notes,
                       sps.id_prof_reg,
                       sps.dt_reg,
                       ss.id_episode,
                       spst.flg_status,
                       sps.dt_pos_suggested
                  FROM sr_pos_schedule sps
                 INNER JOIN schedule_sr ss
                    ON ss.id_schedule_sr = sps.id_schedule_sr
                 INNER JOIN sr_pos_status spst
                    ON spst.id_sr_pos_status = sps.id_sr_pos_status
                 WHERE sps.id_sr_pos_schedule = i_id_sr_pos_schedule) t;
    
        RETURN l_tbl;
    END tf_pos_req_detail;

    /**************************************************************************
    * Sets or updates a POS appointment request                               *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_patient                    patient to set the request to       *
    * @param i_episode                    requested admission episode         *
    * @param i_flg_edit                   record type: A - add, R - remove,   *
    *                                     E - edit                            *
    * @param i_consult_req                consult_req ID                      *
    * @param i_dep_clin_serv              appointment type                    *
    * @param i_dt_scheduled_str           appointment date                    *
    * @param io_consult_req               new consult_req ID                  *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                             true or false on success or error   *
    *                                                                         *
    * @author                             José Silva                          *
    * @version                            1.0                                 *
    * @since                              25-04-2009                          *
    **************************************************************************/
    FUNCTION set_pos_appointment_req
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_edit         IN VARCHAR2,
        i_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_notes_req        IN consult_req.notes%TYPE,
        io_consult_req     IN OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_POS_APPOINTMENT_REQ';
        l_exception        EXCEPTION;
        l_status_exception EXCEPTION;
    
        l_msg_err_status sys_message.desc_message%TYPE;
        l_error          t_error_out;
    
        l_cons_req_status consult_req.flg_status%TYPE;
    
        FUNCTION set_consult_req
        (
            o_consult_req OUT consult_req.id_consult_req%TYPE,
            o_error       OUT t_error_out
        ) RETURN BOOLEAN IS
        BEGIN
            RETURN pk_consult_req.set_consult_req(i_lang             => i_lang,
                                                  i_episode          => i_episode,
                                                  i_prof_req         => i_prof,
                                                  i_pat              => i_patient,
                                                  i_instit_requests  => NULL,
                                                  i_instit_requested => NULL,
                                                  i_consult_type     => NULL,
                                                  i_clinical_service => NULL,
                                                  i_dt_scheduled_str => i_dt_scheduled_str,
                                                  i_flg_type_date    => pk_alert_constant.g_flg_type_date_f,
                                                  i_notes            => i_notes_req,
                                                  i_dep_clin_serv    => i_dep_clin_serv,
                                                  i_prof_requested   => -1,
                                                  i_prof_cat_type    => pk_alert_constant.g_cat_type_doc,
                                                  i_id_complaint     => NULL,
                                                  i_commit_data      => pk_alert_constant.g_no,
                                                  i_flg_type         => pk_consult_req.g_flg_type_waitlist,
                                                  o_consult_req      => o_consult_req,
                                                  o_error            => o_error);
        END;
    
    BEGIN
        g_error := 'GET ERROR MESSAGE';
        pk_alertlog.log_debug(g_error);
        l_msg_err_status := pk_message.get_message(i_lang, 'SR_POS_M015');
        IF i_flg_edit = g_flg_new
        THEN
            g_error := 'SET NEW CONSULT_REQ';
            pk_alertlog.log_debug(g_error);
            IF NOT set_consult_req(o_consult_req => io_consult_req, o_error => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSIF i_flg_edit IN (g_flg_edit, g_flg_remove)
        THEN
            g_error := 'EDIT OR REMOVE CONSULT REQ: ' || io_consult_req;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT cr.flg_status
                  INTO l_cons_req_status
                  FROM consult_req cr
                 WHERE cr.id_consult_req = io_consult_req;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE l_exception;
            END;
        
            --           g_error := 'CHECK CONSULT_REQ STATUS';
            --           pk_alertlog.log_debug(g_error);
            --           IF l_cons_req_status = pk_consult_req.g_consult_req_stat_proc
            --           THEN
            --               RAISE l_status_exception;
            --           END IF;
        
            IF l_cons_req_status = pk_consult_req.g_consult_req_stat_cancel
            THEN
                RETURN TRUE;
            END IF;
        
            g_error := 'CANCEL CONSULT_REQ';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_consult_req.cancel_consult_req_noprofcheck(i_lang         => i_lang,
                                                                 i_consult_req  => io_consult_req,
                                                                 i_prof_cancel  => i_prof,
                                                                 i_notes_cancel => NULL,
                                                                 i_commit_data  => pk_alert_constant.g_no,
                                                                 o_error        => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF i_flg_edit = g_flg_edit
            THEN
                io_consult_req := NULL;
                g_error        := 'EDIT CONSULT_REQ';
                pk_alertlog.log_debug(g_error);
                IF NOT set_consult_req(o_consult_req => io_consult_req, o_error => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_status_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   'SR_POS_M015',
                                   l_msg_err_status,
                                   '',
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name,
                                   NULL,
                                   'D');
            
                IF NOT pk_alert_exceptions.process_error(l_error_in, o_error)
                THEN
                    pk_alertlog.log_error(o_error.err_desc, g_package_name, l_function_name);
                END IF;
                RETURN FALSE;
            END;
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error || ' / ' || l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
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
    END set_pos_appointment_req;

    /**************************************************************************
    *                                                                         *
    *  Auxiliary function used on admission request creation and edition      *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   01-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN schedule_sr.id_waiting_list%TYPE,
        i_id_episode_sr       IN schedule_sr.id_episode%TYPE,
        i_id_sr_pos_status    IN sr_pos_schedule.id_sr_pos_status%TYPE DEFAULT NULL,
        i_dt_pos_suggested    IN VARCHAR2 DEFAULT NULL,
        i_req_notes           IN sr_pos_schedule.req_notes%TYPE DEFAULT NULL,
        io_id_sr_pos_schedule IN OUT sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_decision_notes      IN sr_pos_schedule.decision_notes%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name        VARCHAR2(30) := 'SET_POS_SCHEDULE';
        l_error                t_error_out;
        l_id_schedule_sr       schedule_sr.id_schedule_sr%TYPE;
        l_id_episode           schedule_sr.id_episode%TYPE;
        l_id_patient           schedule_sr.id_patient%TYPE;
        l_pos_consult_req      sr_pos_schedule.id_pos_consult_req%TYPE;
        l_dt_pos_suggested_old sr_pos_schedule.dt_pos_suggested%TYPE;
        l_req_notes_old        sr_pos_schedule.req_notes%TYPE;
        l_dt_pos_suggested     sr_pos_schedule.dt_pos_suggested%TYPE;
        l_flg_edit             VARCHAR2(1);
        l_pos_id_dep_clin_serv sys_config.value%TYPE;
        l_rows                 table_varchar;
    
        l_data_error EXCEPTION;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'Get sys_config POS_ID_DEP_CLIN_SERV';
        pk_alertlog.log_debug(g_error);
        l_pos_id_dep_clin_serv := pk_sysconfig.get_config(i_code_cf => 'POS_ID_DEP_CLIN_SERV', i_prof => i_prof);
    
        g_error := 'Get ID_SCHEDULE_SR for i_id_waiting_list: ' || i_id_waiting_list || ', i_id_episode_sr: ' ||
                   i_id_episode_sr;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        BEGIN
            SELECT ssr.id_schedule_sr, ssr.id_episode, ssr.id_patient, pos.id_sr_pos_schedule
              INTO l_id_schedule_sr, l_id_episode, l_id_patient, io_id_sr_pos_schedule
              FROM schedule_sr ssr
              LEFT JOIN sr_pos_schedule pos
                ON pos.id_schedule_sr = ssr.id_schedule_sr
             WHERE ssr.id_waiting_list = nvl(i_id_waiting_list, ssr.id_waiting_list)
               AND ssr.id_episode = i_id_episode_sr;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'ID_SCHEDULE_SR NOT FOUND';
                RAISE l_data_error;
        END;
    
        IF io_id_sr_pos_schedule IS NOT NULL
        THEN
            g_error := 'Get id_pos_consult_req for id_schedule_sr: ' || l_id_schedule_sr;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            BEGIN
                SELECT sps.id_pos_consult_req, sps.dt_pos_suggested, sps.req_notes
                  INTO l_pos_consult_req, l_dt_pos_suggested_old, l_req_notes_old
                  FROM sr_pos_schedule sps
                 WHERE sps.id_sr_pos_schedule = io_id_sr_pos_schedule;
            EXCEPTION
                WHEN no_data_found THEN
                    l_pos_consult_req      := NULL;
                    l_dt_pos_suggested_old := NULL;
                    l_req_notes_old        := NULL;
            END;
        ELSE
            l_pos_consult_req      := NULL;
            l_dt_pos_suggested_old := NULL;
            l_req_notes_old        := NULL;
        END IF;
        IF i_dt_pos_suggested IS NOT NULL
        THEN
            g_error := 'POS APPOINTMENT SETUP';
            pk_alertlog.log_debug(g_error);
            l_dt_pos_suggested := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_pos_suggested, NULL);
        
            IF (l_pos_consult_req IS NULL)
            THEN
                l_flg_edit := g_flg_new;
            ELSIF (pk_date_utils.compare_dates_tsz(i_prof, l_dt_pos_suggested, l_dt_pos_suggested_old) != 'E')
                  OR (i_req_notes != l_req_notes_old)
            THEN
                l_flg_edit := g_flg_edit;
            ELSIF (l_dt_pos_suggested IS NULL)
            THEN
                l_flg_edit := g_flg_remove;
            END IF;
        ELSIF (l_pos_consult_req IS NULL)
        THEN
            l_flg_edit := NULL;
        ELSE
            l_flg_edit := g_flg_remove;
        END IF;
    
        IF io_id_sr_pos_schedule IS NOT NULL
        THEN
            g_error := 'set i_sr_pos_schedule #1 - io_id_sr_pos_schedule: ' || io_id_sr_pos_schedule;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            IF NOT set_sr_pos_schedule(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_sr_pos_status    => i_id_sr_pos_status,
                                       i_flg_status          => pk_alert_constant.g_schedule_sr_status_a,
                                       i_id_prof_reg         => i_prof.id,
                                       i_dt_reg              => g_sysdate_tstz,
                                       i_dt_pos_suggested    => l_dt_pos_suggested,
                                       i_req_notes           => i_req_notes,
                                       io_id_sr_pos_schedule => io_id_sr_pos_schedule,
                                       i_decision_notes      => i_decision_notes,
                                       o_error               => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            g_error := 'set i_sr_pos_schedule #2';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            IF NOT set_sr_pos_schedule(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_sr_pos_status    => i_id_sr_pos_status,
                                       i_id_schedule_sr      => l_id_schedule_sr,
                                       i_flg_status          => pk_alert_constant.g_schedule_sr_status_a,
                                       i_id_prof_reg         => i_prof.id,
                                       i_dt_reg              => g_sysdate_tstz,
                                       i_id_prof_req         => i_prof.id,
                                       i_dt_req              => g_sysdate_tstz,
                                       i_dt_pos_suggested    => l_dt_pos_suggested,
                                       i_req_notes           => i_req_notes,
                                       io_id_sr_pos_schedule => io_id_sr_pos_schedule,
                                       i_decision_notes      => i_decision_notes,
                                       o_error               => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF (l_flg_edit IS NOT NULL AND l_pos_id_dep_clin_serv IS NOT NULL AND l_pos_id_dep_clin_serv != -1)
        THEN
            g_error := 'set POS appointment';
            pk_alertlog.log_debug(g_error);
            IF NOT set_pos_appointment_req(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_patient          => l_id_patient,
                                           i_episode          => l_id_episode,
                                           i_flg_edit         => l_flg_edit,
                                           i_dep_clin_serv    => l_pos_id_dep_clin_serv,
                                           i_dt_scheduled_str => i_dt_pos_suggested,
                                           i_notes_req        => i_req_notes,
                                           io_consult_req     => l_pos_consult_req,
                                           o_error            => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'update sr_pos_schedule.id_pos_consult_req with value :' || l_pos_consult_req;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            l_rows := table_varchar();
            ts_sr_pos_schedule.upd(id_sr_pos_schedule_in => io_id_sr_pos_schedule,
                                   id_pos_consult_req_in => l_pos_consult_req,
                                   rows_out              => l_rows);
        
            g_error := 'PROCESS UPDATE RECORD';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SR_POS_SCHEDULE',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_POS_CONSULT_REQ'));
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_data_error THEN
            pk_alert_exceptions.raise_error(error_code_in => '-20101',
                                            text_in       => g_error,
                                            name1_in      => 'i_id_waiting_list',
                                            value1_in     => i_id_waiting_list,
                                            name2_in      => 'i_id_episode_sr',
                                            value2_in     => i_id_episode_sr);
            RETURN FALSE;
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN FALSE;
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
    END set_pos_schedule;

    /**************************************************************************
    *                                                                         *
    * function used on pos request validation                                 *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   02-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_validation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_status   IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_days_valid         IN sr_pos_schedule.valid_days%TYPE,
        i_dt_valid           IN VARCHAR2,
        i_decision_notes     IN sr_pos_schedule.decision_notes%TYPE,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name      VARCHAR2(30) := 'SET_POS_VALIDATION';
        l_error              t_error_out;
        l_id_schedule_sr     schedule_sr.id_schedule_sr%TYPE;
        l_id_sr_pos_schedule sr_pos_schedule.id_sr_pos_schedule%TYPE;
        l_id_waiting_list    schedule_sr.id_waiting_list%TYPE;
        l_tmp_date           TIMESTAMP WITH LOCAL TIME ZONE;
        l_adm_needed         schedule_sr.adm_needed%TYPE;
    
        l_data_error EXCEPTION;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'TRUNC_INSTTIMEZONE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.trunc_insttimezone(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_timestamp => current_timestamp,
                                                o_timestamp => l_tmp_date,
                                                o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_id_sr_pos_schedule := i_id_sr_pos_schedule;
    
        g_error := 'Get ID_SCHEDULE_SR for i_id_sr_pos_schedule: ' || l_id_sr_pos_schedule;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        BEGIN
            SELECT sps.id_schedule_sr,
                   (SELECT ss.id_waiting_list
                      FROM schedule_sr ss
                     WHERE ss.id_schedule_sr = sps.id_schedule_sr) id_waiting_list
              INTO l_id_schedule_sr, l_id_waiting_list
              FROM sr_pos_schedule sps
             WHERE sps.id_sr_pos_schedule = l_id_sr_pos_schedule;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'ID_SCHEDULE_SR NOT FOUND';
                RAISE l_data_error;
        END;
    
        g_error := 'Calculate date';
        pk_alertlog.log_debug(g_error);
        IF (i_days_valid IS NOT NULL AND i_days_valid != -1)
        THEN
            l_tmp_date := pk_date_utils.add_days_to_tstz(i_timestamp => l_tmp_date, i_days => i_days_valid);
        ELSIF (i_days_valid IS NOT NULL AND i_days_valid = -1)
        THEN
            l_tmp_date := NULL;
        ELSIF (i_dt_valid IS NOT NULL)
        THEN
            l_tmp_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_valid, NULL);
        ELSE
            l_tmp_date := NULL;
        END IF;
    
        g_error := 'set i_sr_pos_schedule';
        pk_alertlog.log_debug(g_error);
        IF NOT set_sr_pos_schedule(i_lang                => i_lang,
                                   i_prof                => i_prof,
                                   i_id_sr_pos_status    => i_id_sr_pos_status,
                                   i_id_schedule_sr      => l_id_schedule_sr,
                                   i_flg_status          => pk_alert_constant.g_schedule_sr_status_a,
                                   i_id_prof_reg         => i_prof.id,
                                   i_dt_reg              => g_sysdate_tstz,
                                   i_valid_days          => i_days_valid,
                                   i_dt_valid            => l_tmp_date,
                                   i_decision_notes      => i_decision_notes,
                                   i_id_prof_decision    => i_prof.id,
                                   i_dt_decision         => g_sysdate_tstz,
                                   io_id_sr_pos_schedule => l_id_sr_pos_schedule,
                                   o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Finally: check status of waiting list
        SELECT nvl(ssr.adm_needed, pk_alert_constant.get_no)
          INTO l_adm_needed
          FROM sr_pos_schedule sps
          JOIN schedule_sr ssr
            ON ssr.id_schedule_sr = sps.id_schedule_sr
         WHERE sps.id_sr_pos_schedule = i_id_sr_pos_schedule;
    
        g_error := 'CALL TO PK_WTL_PBL_CORE.CHECK_WTLIST_STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_pbl_core.check_wtlist_status(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_wtlist  => l_id_waiting_list,
                                                   i_adm_needed => l_adm_needed,
                                                   o_error      => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_data_error THEN
            pk_alert_exceptions.raise_error(error_code_in => '-20101',
                                            text_in       => g_error,
                                            name1_in      => 'id_sr_pos_schedule',
                                            value1_in     => i_id_sr_pos_schedule);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pos_validation;

    /**************************************************************************
    * Returns information to put in the POS Detail screen                     *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/02                              *
    **************************************************************************/
    FUNCTION get_pos_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_pos_detail         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_POS_DETAIL';
        TYPE t_code_messages IS TABLE OF VARCHAR2(2000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_POS_M013', --Requested by
                                                          'SR_POS_M014', --Requested date
                                                          'SR_POS_M011', --Request notes
                                                          'SR_POS_M002', --Decision
                                                          'SR_POS_M003', --Valid for
                                                          'SR_POS_M004', --Decision notes
                                                          'SR_POS_M016', --Expired
                                                          'SR_POS_M010'); --Suggested POS appointment date
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- get all messages
        g_error := 'GET MESSAGES';
        pk_alertlog.log_debug(g_error);
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'OPEN o_pos_detail';
        pk_alertlog.log_debug(g_error);
        OPEN o_pos_detail FOR
            SELECT aa_code_messages('SR_POS_M013') lbl_prof_req,
                   pk_prof_utils.get_name(i_lang, t1.id_prof_req) desc_prof_req,
                   aa_code_messages('SR_POS_M014') lbl_dt_req,
                   pk_date_utils.date_char_tsz(i_lang, t1.dt_req, i_prof.institution, i_prof.software) desc_dt_req,
                   aa_code_messages('SR_POS_M011') lbl_req_notes,
                   t1.req_notes,
                   aa_code_messages('SR_POS_M002') lbl_desc_decision,
                   t1.desc_decision,
                   aa_code_messages('SR_POS_M003') lbl_dt_valid,
                   (CASE
                        WHEN t1.valid_days IS NOT NULL THEN
                         pk_sysdomain.get_domain_list_desc(i_lang, i_prof, 'POS_EXPIRE_LIST', t1.valid_days, NULL)
                        ELSE
                         NULL
                    END) desc_validity,
                   pk_date_utils.date_send_tsz(i_lang, t1.dt_valid, i_prof) desc_dt_valid,
                   aa_code_messages('SR_POS_M004') lbl_decision_notes,
                   t1.decision_notes,
                   pk_date_utils.date_char_tsz(i_lang, t1.dt_reg, i_prof.institution, i_prof.software) desc_dt_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t1.id_prof_reg) desc_id_prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, t1.id_prof_reg, t1.dt_reg, t1.sch_sr_id_episode) desc_prof_reg_spec,
                   check_pos_is_expired(i_lang, i_prof, t1.dt_valid, t1.flg_status) expired,
                   aa_code_messages('SR_POS_M016') lbl_desc_expired,
                   pk_date_utils.date_send_tsz(i_lang, t1.dt_pos_suggested, i_prof) dt_pos_suggested,
                   aa_code_messages('SR_POS_M010') lbl_dt_pos_suggested,
                   t1.dt_reg,
                   pk_alert_constant.g_no flg_history,
                   t1.flg_status
              FROM TABLE(tf_pos_req_detail(i_lang, i_prof, i_id_sr_pos_schedule)) t1
            UNION ALL
            SELECT aa_code_messages('SR_POS_M013') lbl_prof_req,
                   pk_prof_utils.get_name(i_lang, spsh.id_prof_req) desc_prof_req,
                   aa_code_messages('SR_POS_M014') lbl_dt_req,
                   pk_date_utils.date_char_tsz(i_lang, spsh.dt_req, i_prof.institution, i_prof.software) desc_dt_req,
                   aa_code_messages('SR_POS_M011') lbl_req_notes,
                   spsh.req_notes,
                   aa_code_messages('SR_POS_M002') lbl_desc_decision,
                   --pk_sysdomain.get_domain(i_lang, i_prof, 'SR_POS_STATUS.FLG_STATUS', spst.flg_status, NULL) desc_decision,
                   pk_translation.get_translation(i_lang, spst.code) desc_decision,
                   aa_code_messages('SR_POS_M003') lbl_dt_valid,
                   (CASE
                        WHEN spsh.valid_days IS NOT NULL THEN
                         pk_sysdomain.get_domain_list_desc(i_lang, i_prof, 'POS_EXPIRE_LIST', spsh.valid_days, NULL)
                        ELSE
                         NULL
                    END) desc_validity,
                   pk_date_utils.date_send_tsz(i_lang, spsh.dt_valid, i_prof) desc_dt_valid,
                   aa_code_messages('SR_POS_M004') lbl_decision_notes,
                   spsh.decision_notes,
                   pk_date_utils.date_char_tsz(i_lang, spsh.dt_reg, i_prof.institution, i_prof.software) desc_dt_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, spsh.id_prof_reg) desc_id_prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, spsh.id_prof_reg, spsh.dt_reg, ss.id_episode) desc_prof_reg_spec,
                   check_pos_is_expired(i_lang, i_prof, spsh.dt_valid, spst.flg_status) expired,
                   aa_code_messages('SR_POS_M016') lbl_desc_expired,
                   pk_date_utils.date_send_tsz(i_lang, spsh.dt_pos_suggested, i_prof) dt_pos_suggested,
                   aa_code_messages('SR_POS_M010') lbl_dt_pos_suggested,
                   spsh.dt_reg,
                   pk_alert_constant.g_yes flg_history,
                   spsh.flg_status
              FROM sr_pos_schedule_hist spsh
             INNER JOIN schedule_sr ss
                ON ss.id_schedule_sr = spsh.id_schedule_sr
             INNER JOIN sr_pos_status spst
                ON spst.id_sr_pos_status = spsh.id_sr_pos_status
             WHERE spsh.id_sr_pos_schedule = i_id_sr_pos_schedule
             ORDER BY flg_history, dt_reg DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_pos_detail);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_pos_detail);
            RETURN FALSE;
    END get_pos_detail;

    /**************************************************************************
    * Returns information to put in the POS Detail screen                     *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/02                              *
    **************************************************************************/
    FUNCTION get_pos_detail_new
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_pos_detail         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_POS_DETAIL_NEW';
        TYPE t_code_messages IS TABLE OF VARCHAR2(2000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_POS_M013', --Requested by
                                                          'SR_POS_M014', --Requested date
                                                          'SR_POS_M011', --Request notes
                                                          'SR_POS_M002', --Decision
                                                          'SR_POS_M003', --Valid for
                                                          'SR_POS_M004', --Decision notes
                                                          'SR_POS_T001'); --POS validation
    BEGIN
    
        -- get all messages
        g_error := 'GET MESSAGES';
        pk_alertlog.log_debug(g_error);
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'OPEN o_pos_detail';
        pk_alertlog.log_debug(g_error);
        OPEN o_pos_detail FOR
            SELECT table_varchar(aa_code_messages('SR_POS_T001')) title,
                   table_varchar(aa_code_messages('SR_POS_T001')) upper_row,
                   table_varchar(pk_utils.to_bold(aa_code_messages('SR_POS_M013')) || ': ' ||
                                  nvl(pk_prof_utils.get_name(i_lang, t1.id_prof_req), '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M014')) || ': ' ||
                                  nvl(pk_date_utils.dt_chr_date_hour(i_lang, t1.dt_req, i_prof), '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M011')) || ': ' || nvl(t1.req_notes, '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M002')) || ': ' ||
                                  nvl(t1.desc_decision, '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M003')) || ': ' || CASE
                                      WHEN (t1.valid_days IS NOT NULL AND valid_days != -1) THEN
                                       t1.valid_days || '; '
                                      ELSE
                                       ''
                                  END || CASE
                                      WHEN t1.dt_valid IS NOT NULL THEN
                                       pk_date_utils.dt_chr_date_hour(i_lang, t1.dt_valid, i_prof)
                                      ELSE
                                       '---'
                                  END,
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M004')) || ': ' ||
                                  nvl(t1.decision_notes, '---')) detail_rows,
                   table_varchar(pk_date_utils.dt_chr_date_hour(i_lang, t1.dt_reg, i_prof),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, t1.id_prof_reg),
                                 '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                         i_prof,
                                                                         t1.id_prof_reg,
                                                                         t1.dt_reg,
                                                                         t1.sch_sr_id_episode) || ')') bottom_row,
                   t1.dt_reg,
                   pk_alert_constant.g_no flg_history
              FROM TABLE(tf_pos_req_detail(i_lang, i_prof, i_id_sr_pos_schedule)) t1
            UNION ALL
            SELECT table_varchar(aa_code_messages('SR_POS_T001')) title,
                   table_varchar(aa_code_messages('SR_POS_T001')) upper_row,
                   table_varchar(pk_utils.to_bold(aa_code_messages('SR_POS_M013')) || ': ' ||
                                  nvl(pk_prof_utils.get_name(i_lang, spsh.id_prof_req), '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M014')) || ': ' ||
                                  nvl(pk_date_utils.dt_chr_date_hour(i_lang, spsh.dt_req, i_prof), '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M011')) || ': ' || nvl(spsh.req_notes, '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M002')) || ': ' ||
                                  nvl(spsh.decision_notes, '---'),
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M003')) || ': ' || CASE
                                      WHEN (spsh.valid_days IS NOT NULL AND spsh.valid_days != -1) THEN
                                       spsh.valid_days || '; '
                                      ELSE
                                       ''
                                  END || CASE
                                      WHEN spsh.dt_valid IS NOT NULL THEN
                                       pk_date_utils.dt_chr_date_hour(i_lang, spsh.dt_valid, i_prof)
                                      ELSE
                                       '---'
                                  END,
                                  pk_utils.to_bold(aa_code_messages('SR_POS_M004')) || ': ' ||
                                  nvl(spsh.decision_notes, '---')) detail_rows,
                   table_varchar(pk_date_utils.dt_chr_date_hour(i_lang, spsh.dt_reg, i_prof),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, spsh.id_prof_reg),
                                 '(' || pk_prof_utils.get_spec_signature(i_lang,
                                                                         i_prof,
                                                                         spsh.id_prof_reg,
                                                                         spsh.dt_reg,
                                                                         ss.id_episode) || ')') bottom_row,
                   spsh.dt_reg,
                   pk_alert_constant.g_yes flg_history
              FROM sr_pos_schedule_hist spsh
             INNER JOIN schedule_sr ss
                ON ss.id_schedule_sr = spsh.id_schedule_sr
             INNER JOIN sr_pos_status spst
                ON spst.id_sr_pos_status = spsh.id_sr_pos_status
             WHERE spsh.id_sr_pos_schedule = i_id_sr_pos_schedule
             ORDER BY flg_history, dt_reg DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_pos_detail);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_pos_detail);
            RETURN FALSE;
    END get_pos_detail_new;

    /**************************************************************************
    * GET_POS_DECISION                                                        *
    *                                                                         *
    *                                                                         *
    * @param I_LANG                   Language ID for translations            *
    * @param I_PROF                   Professional ID, Institution ID,        *
    *                                 Software ID                             *
    * @param I_ID_SR_POS_SCHEDULE     sr_pos_schedule id                      *
    *                                                                         *
    * @return                         Returns                                 *
    *                                                                         *
    *                                                                         *
    * @raises                         PL/SQL generic error "OTHERS" and       *
    *                                 "wtl_exception"                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/03/29                              *
    **************************************************************************/

    FUNCTION get_pos_decision_ds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_flg_return_opts    IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_pos_dt_sugg        OUT VARCHAR2,
        o_pos_dt_sugg_chr    OUT VARCHAR2,
        o_pos_notes          OUT VARCHAR2,
        o_pos_sr_stauts      OUT NUMBER,
        o_pos_desc_decision  OUT VARCHAR2,
        o_pos_valid_days     OUT NUMBER,
        o_pos_desc_notes     OUT VARCHAR2,
        o_pos_need_op        OUT VARCHAR2,
        o_pos_need_op_desc   OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_POS_DECISION';
        l_error     t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'Open o_pos_validation';
        pk_alertlog.log_debug(g_error);
        SELECT pk_date_utils.date_send_tsz(i_lang, sps.dt_pos_suggested, i_prof) dt_pos_suggested,
               pk_date_utils.date_char_tsz(i_lang, sps.dt_pos_suggested, i_prof.institution, i_prof.software) dt_pos_suggested_chr,
               sps.req_notes req_notes,
               sps.id_sr_pos_status,
               pk_translation.get_translation(i_lang, spst.code) desc_decision,
               sps.valid_days valid_days,
               sps.decision_notes desc_notes,
               CASE
                   WHEN spst.flg_status = 'NO' THEN
                    pk_alert_constant.g_no
                   ELSE
                    pk_alert_constant.g_yes
               END,
               pk_sysdomain.get_domain('ADM_REQUEST.FLG_MIXED_NURSING',
                                        CASE
                                            WHEN spst.flg_status = 'NO' THEN
                                             pk_alert_constant.g_no
                                            ELSE
                                             pk_alert_constant.g_yes
                                        END,
                                        i_lang)
          INTO o_pos_dt_sugg,
               o_pos_dt_sugg_chr,
               o_pos_notes,
               o_pos_sr_stauts,
               o_pos_desc_decision,
               o_pos_valid_days,
               o_pos_desc_notes,
               o_pos_need_op,
               o_pos_need_op_desc
          FROM sr_pos_schedule sps
         INNER JOIN sr_pos_status spst
            ON spst.id_sr_pos_status = sps.id_sr_pos_status
          LEFT JOIN consult_req cr
            ON cr.id_consult_req = sps.id_pos_consult_req
         WHERE sps.id_sr_pos_schedule = i_id_sr_pos_schedule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
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
        
            RETURN FALSE;
    END get_pos_decision_ds;

    FUNCTION get_pos_decision
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_flg_return_opts    IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_pos_validation     OUT pk_types.cursor_type,
        o_pos_decision       OUT pk_types.cursor_type,
        o_pos_validity       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_POS_DECISION';
        l_error     t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'Open o_pos_validation';
        pk_alertlog.log_debug(g_error);
        OPEN o_pos_validation FOR
            SELECT sps.id_sr_pos_schedule,
                   sps.id_schedule_sr,
                   pk_date_utils.date_send_tsz(i_lang, sps.dt_pos_suggested, i_prof) dt_pos_suggested,
                   sps.req_notes req_notes,
                   sps.id_sr_pos_status,
                   CASE
                        WHEN sps.dt_pos_suggested IS NOT NULL
                             AND sps.id_sr_pos_status NOT IN (g_sr_pos_status_no_decision, g_sr_pos_status_not_needed) THEN
                         pk_translation.get_translation(i_lang, spst.code)
                    END desc_decision,
                   sps.valid_days valid_days,
                   pk_date_utils.date_send_tsz(i_lang, sps.dt_valid, i_prof) dt_valid,
                   sps.decision_notes desc_notes,
                   check_pos_is_expired(i_lang, i_prof, sps.dt_valid, spst.flg_status) expired,
                   (CASE
                        WHEN (spst.flg_status NOT IN
                             (pk_alert_constant.g_sr_pos_status_nd, pk_alert_constant.g_sr_pos_status_no)) THEN
                         pk_alert_constant.g_no
                        WHEN cr.flg_status NOT IN (pk_consult_req.g_sched_pend, pk_consult_req.g_sched_canc) THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END) flg_edit,
                   (CASE
                        WHEN sps.valid_days IS NOT NULL THEN
                         pk_sysdomain.get_domain_list_desc(i_lang, i_prof, 'POS_EXPIRE_LIST', sps.valid_days, NULL)
                        ELSE
                         NULL
                    END) desc_validity,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         sps.dt_pos_suggested,
                                                         i_prof.institution,
                                                         i_prof.software) dt_pos_suggested_chr
              FROM sr_pos_schedule sps
             INNER JOIN sr_pos_status spst
                ON spst.id_sr_pos_status = sps.id_sr_pos_status
              LEFT JOIN consult_req cr
                ON cr.id_consult_req = sps.id_pos_consult_req
             WHERE sps.id_sr_pos_schedule = i_id_sr_pos_schedule
               AND sps.flg_status <> pk_alert_constant.g_cancelled;
    
        IF (i_flg_return_opts = pk_alert_constant.get_yes)
        THEN
            g_error := 'Open o_pos_decision';
            pk_alertlog.log_debug(g_error);
            OPEN o_pos_decision FOR
                SELECT id_sr_pos_status, flg_status, desc_flg_status
                  FROM (SELECT spst.id_sr_pos_status,
                               spst.flg_status,
                               pk_translation.get_translation(i_lang, spst.code) desc_flg_status,
                               rank() over(ORDER BY spst.id_institution DESC) origin_rank
                          FROM sr_pos_status spst
                         WHERE spst.id_institution IN (0, i_prof.institution)
                           AND spst.flg_available = pk_alert_constant.g_available
                           AND spst.flg_status != pk_alert_constant.g_sr_pos_status_no)
                 WHERE origin_rank = 1;
        
            g_error := 'Open o_pos_validity';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sysdomain.get_values_domain_list(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_domain_list   => 'POS_EXPIRE_LIST',
                                                       i_dep_clin_serv => NULL,
                                                       o_data          => o_pos_validity,
                                                       o_error         => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            pk_types.open_my_cursor(o_pos_decision);
            pk_types.open_my_cursor(o_pos_validity);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_pos_decision);
            pk_types.open_my_cursor(o_pos_validity);
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
        
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_pos_decision);
            pk_types.open_my_cursor(o_pos_validity);
        
            RETURN FALSE;
    END get_pos_decision;

    /*******************************************************************************************************************************************
    * GET_POS_STATUS_ICONS            Returns all the icons that can appear in the POS status column of the admission/surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_DATA                   Icons
    * @param O_ERROR                  
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         
    * @version                        2.6.0
    * @since                          2010/03/31
    *******************************************************************************************************************************************/
    FUNCTION get_pos_status_icons
    (
        i_lang  IN sys_domain.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET pos request icons';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR --
            SELECT desc_val, val, img_name, rank
              FROM sys_domain s
             WHERE s.code_domain = 'SR_POS_STATUS.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND s.flg_available = pk_alert_constant.g_yes
               AND s.val NOT IN (pk_alert_constant.g_sr_pos_status_ta, pk_alert_constant.g_sr_pos_status_tn)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_POS_STATUS_ICONS',
                                                     o_error    => o_error);
    END get_pos_status_icons;

    /**************************************************************************
    * GET_SUMMARY_POS_DECISION                                                *
    *                                                                         *
    *                                                                         *
    * @param I_LANG                   Language ID for translations            *
    * @param I_PROF                   Professional ID, Institution ID,        *
    *                                 Software ID                             *
    * @param i_id_episode             episode id                              *
    *                                                                         *
    * @return                         Returns                                 *
    *                                                                         *
    *                                                                         *
    * @raises                         PL/SQL generic error "OTHERS" and       *
    *                                 "wtl_exception"                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/07                              *
    **************************************************************************/
    FUNCTION get_summary_pos_decision
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN schedule_sr.id_episode%TYPE,
        o_pos_validation OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SUMMARY_POS_DECISION';
        l_error     t_error_out;
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(200) INDEX BY sys_message.code_message%TYPE;
        sr_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_POS_M002',
                                                          'SR_POS_M003',
                                                          'SR_POS_M004',
                                                          'SR_POS_M011',
                                                          'SR_POS_M013',
                                                          'SR_POS_M014',
                                                          'SR_POS_M016');
    
        wtl_exception EXCEPTION;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- get all messages
        g_error := 'Fetching all labels';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            sr_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'Fetching cursor o_pos_validation for id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        OPEN o_pos_validation FOR
            SELECT pk_date_utils.date_char_tsz(i_lang, sps.dt_reg, i_prof.institution, i_prof.software) action_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sps.id_prof_reg) desc_prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, sps.id_prof_reg, sps.dt_reg, ss.id_episode) desc_prof_sig,
                   --           
                   sps.id_sr_pos_status,
                   sps.id_sr_pos_schedule,
                   sr_code_messages('SR_POS_M013') lbl_req_by,
                   pk_prof_utils.get_name(i_lang, sps.id_prof_req) req_by,
                   sr_code_messages('SR_POS_M014') lbl_req_date,
                   pk_date_utils.date_char_tsz(i_lang, sps.dt_req, i_prof.institution, i_prof.software) req_date,
                   sr_code_messages('SR_POS_M011') lbl_req_notes,
                   sps.req_notes req_notes,
                   sr_code_messages('SR_POS_M002') lbl_desc_decision,
                   pk_translation.get_translation(i_lang, spst.code) desc_decision,
                   sr_code_messages('SR_POS_M003') lbl_desc_validity,
                   --                   sps.valid_days desc_validity
                   (CASE
                        WHEN sps.valid_days IS NOT NULL THEN
                         pk_sysdomain.get_domain_list_desc(i_lang, i_prof, 'POS_EXPIRE_LIST', sps.valid_days, NULL)
                        ELSE
                         NULL
                    END) desc_validity,
                   pk_date_utils.date_send_tsz(i_lang, sps.dt_valid, i_prof) dt_valid,
                   sr_code_messages('SR_POS_M004') lbl_desc_notes,
                   sps.decision_notes desc_notes,
                   check_pos_is_expired(i_lang, i_prof, sps.dt_valid, spst.flg_status) expired,
                   sr_code_messages('SR_POS_M016') lbl_desc_expired,
                   (CASE spst.flg_status
                       WHEN pk_alert_constant.g_sr_pos_status_nd THEN
                        g_pos_requisition
                       ELSE
                        g_pos_decision
                   END) flg_show,
                   (CASE spst.flg_status
                       WHEN pk_alert_constant.g_sr_pos_status_no THEN
                        pk_alert_constant.g_sr_pos_status_no
                       ELSE
                        pk_alert_constant.g_yes
                   END) flg_create
              FROM sr_pos_schedule sps
             INNER JOIN sr_pos_status spst
                ON spst.id_sr_pos_status = sps.id_sr_pos_status
             INNER JOIN schedule_sr ss
                ON ss.id_schedule_sr = sps.id_schedule_sr
             WHERE ss.id_episode = i_id_episode
             ORDER BY sps.dt_req DESC, sps.dt_reg DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            pk_types.open_my_cursor(o_pos_validation);
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
        
            pk_types.open_my_cursor(o_pos_validation);
            RETURN FALSE;
    END get_summary_pos_decision;

    /**************************************************************************
    *                                                                         *
    * function used on pos request                                            *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   08-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested   IN VARCHAR2,
        i_req_notes          IN sr_pos_schedule.req_notes%TYPE,
        o_id_sr_pos_schedule OUT sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name   VARCHAR2(30) := 'SET_POS_REQUEST';
        l_error           t_error_out;
        l_id_waiting_list schedule_sr.id_waiting_list%TYPE;
        l_pos_required    sys_config.value%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_pos_required := pk_sysconfig.get_config(i_code_cf => 'WTL_POS_REQUIRED', i_prof => i_prof);
    
        g_error := 'set_pos_schedule';
        pk_alertlog.log_debug(g_error);
        IF NOT set_pos_schedule(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_id_waiting_list     => NULL,
                                i_id_episode_sr       => i_id_episode,
                                i_id_sr_pos_status    => NULL,
                                i_dt_pos_suggested    => i_dt_pos_suggested,
                                i_req_notes           => i_req_notes,
                                io_id_sr_pos_schedule => o_id_sr_pos_schedule,
                                i_decision_notes      => NULL,
                                o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        SELECT ss.id_waiting_list
          INTO l_id_waiting_list
          FROM sr_pos_schedule sps
          JOIN schedule_sr ss
            ON ss.id_schedule_sr = sps.id_schedule_sr
         WHERE sps.id_sr_pos_schedule = o_id_sr_pos_schedule;
    
        -- Finally: check status of waiting list if value of sys_config WTL_POS_REQUIRED is Yes
        IF l_pos_required = pk_alert_constant.get_yes
        THEN
            g_error := 'CALL TO PK_WTL_PBL_CORE.CHECK_WTLIST_STATUS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_wtl_pbl_core.check_wtlist_status(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_id_wtlist => l_id_waiting_list,
                                                       o_error     => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            o_error := l_error;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pos_request;

    /**************************************************************************
    *                                                                         *
    * function used add tasks to action button                                *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   08-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        i_episode    IN episode.id_episode%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_POS_ACTIONS';
    
        l_flg_enabled VARCHAR2(1);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_episode IS NOT NULL
        THEN
            BEGIN
                g_error := 'Action button options calc';
                pk_alertlog.log_debug(g_error);
                SELECT flg_enabled
                  INTO l_flg_enabled
                  FROM (SELECT (CASE
                                    WHEN spst.flg_status IN
                                         (pk_alert_constant.g_sr_pos_status_no, pk_alert_constant.g_sr_pos_status_na) THEN
                                     pk_alert_constant.g_active
                                    WHEN (pk_sr_pos.check_pos_is_expired(i_lang, i_prof, sps.dt_valid, spst.flg_status) =
                                         pk_alert_constant.g_yes) THEN
                                     pk_alert_constant.g_active
                                    ELSE
                                     pk_alert_constant.g_inactive
                                END) flg_enabled,
                               rank() over(ORDER BY sps.dt_reg DESC) rank_origin
                          FROM schedule_sr ss
                         INNER JOIN sr_pos_schedule sps
                            ON sps.id_schedule_sr = ss.id_schedule_sr
                         INNER JOIN (SELECT id_sr_pos_status, flg_status
                                      FROM (SELECT spst1.id_sr_pos_status,
                                                   spst1.flg_status,
                                                   rank() over(ORDER BY spst1.id_institution DESC) origin_rank
                                              FROM sr_pos_status spst1
                                             WHERE spst1.id_institution IN (0, i_prof.institution))
                                     WHERE origin_rank = 1) spst
                            ON spst.id_sr_pos_status = sps.id_sr_pos_status
                         WHERE ss.id_episode = i_episode
                           AND ss.flg_status <> pk_alert_constant.g_cancelled)
                 WHERE rank_origin = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_enabled := pk_alert_constant.g_inactive;
            END;
        END IF;
    
        g_error := 'GET CURSOR o_actions';
        pk_alertlog.log_debug(g_error);
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l AS "LEVEL",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   MAX(flg_active) flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT id_action,
                           id_parent,
                           LEVEL AS l,
                           to_state,
                           pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                           icon,
                           decode(flg_default, g_action_flg_default, pk_alert_constant.g_yes, g_action_flg_non_default) flg_default,
                           nvl(l_flg_enabled, a.flg_status) AS flg_active,
                           internal_name action,
                           a.from_state,
                           rank
                      FROM action a
                     WHERE subject IN (SELECT *
                                         FROM TABLE(i_subject))
                       AND ((i_from_state IS NOT NULL AND
                           from_state IN (SELECT *
                                              FROM TABLE(i_from_state))) OR i_from_state IS NULL)
                    CONNECT BY PRIOR id_action = id_parent
                     START WITH id_parent IS NULL)
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
            HAVING COUNT(from_state) = (CASE WHEN i_from_state IS NOT NULL THEN (SELECT COUNT(*)
                                                                                   FROM TABLE(table_varchar() MULTISET
                                                                                              UNION DISTINCT
                                                                                              i_from_state)) ELSE COUNT(from_state) END)
             ORDER BY "LEVEL", rank, desc_action;
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
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_pos_actions;

    /**************************************************************************
    *                                                                         *
    * function used to populate pharmaceutical's grid                         *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_pharm_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_POS_PHARM_GRID';
        l_ph_grid_hours sys_config.value%TYPE;
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        -- GET institution date format string
        l_ph_grid_hours := nvl(pk_sysconfig.get_config('POS_PH_GRID_TIME', i_prof), '24');
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --Fetch the list of POS requests for pharm grid
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT ss.id_patient,
                   ss.id_episode,
                   ss.id_schedule,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, ss.id_patient, ss.id_episode, ss.id_schedule) photo,
                   pk_patient.get_pat_name(i_lang, i_prof, ss.id_patient, ss.id_episode, ss.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, ss.id_patient, ss.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, ss.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, ss.id_patient) pat_nd_icon,
                   pk_patient.get_pat_age(i_lang, ss.id_patient, i_prof) pat_age,
                   pk_patient.get_pat_gender(ss.id_patient) pat_gender,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ss.id_episode, i_prof, pk_alert_constant.g_no) surg_proc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sps.id_prof_req) desc_prof_req,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ss.dt_target_tstz, i_prof) dt_surg_extend,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_pos_appt_extend,
                   pk_surgery_request.get_sr_pos_status_str(i_lang,
                                                            i_prof,
                                                            sps.flg_status,
                                                            spst.id_sr_pos_status,
                                                            ss.id_waiting_list,
                                                            ss.id_schedule_sr) pos_status,
                   pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         pk_alert_constant.g_display_type_icon, --display_type
                                                         nvl(spp.flg_status, g_pos_pharm_inactive),
                                                         'SR_POS_PHARM.FLG_STATUS',
                                                         NULL,
                                                         'SR_POS_PHARM.FLG_STATUS',
                                                         NULL,
                                                         CASE
                                                             WHEN spp.flg_status IS NULL THEN
                                                              pk_alert_constant.g_color_red
                                                             ELSE
                                                              NULL
                                                         END,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         current_timestamp) pharm_status,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
              FROM schedule_sr ss
             INNER JOIN sr_pos_schedule sps
                ON sps.id_schedule_sr = ss.id_schedule_sr
             INNER JOIN consult_req cr
                ON cr.id_consult_req = sps.id_pos_consult_req
             INNER JOIN schedule s
                ON s.id_schedule = cr.id_schedule
               AND s.flg_status != pk_grid.g_sched_canc
            -- OUTP admitted                   
              LEFT JOIN epis_info ei
                ON ei.id_schedule = cr.id_schedule
              LEFT JOIN episode e
                ON e.id_episode = ei.id_episode
               AND e.flg_status != pk_alert_constant.g_cancelled
              LEFT JOIN sr_pos_pharm spp
                ON spp.id_sr_pos_schedule = sps.id_sr_pos_schedule
               AND spp.flg_status = g_pos_pharm_active
              LEFT JOIN patient p
                ON p.id_patient = ss.id_patient
             INNER JOIN (SELECT id_sr_pos_status, flg_status
                           FROM (SELECT spst1.id_sr_pos_status,
                                        spst1.flg_status,
                                        rank() over(ORDER BY spst1.id_institution DESC) origin_rank
                                   FROM sr_pos_status spst1
                                  WHERE spst1.id_institution IN (0, i_prof.institution))
                          WHERE origin_rank = 1) spst
                ON spst.id_sr_pos_status = sps.id_sr_pos_status
             WHERE sps.flg_status = g_pos_schedule_active
                  --without POS validation
               AND ((spst.flg_status = pk_alert_constant.g_sr_pos_status_nd AND spp.flg_status IS NULL) OR
                   -- with pharmacist assessment done in less than x hours
                   (spp.flg_status = g_pos_pharm_active AND spp.dt_reg > (g_sysdate_tstz - l_ph_grid_hours / 24)))
                  -- consult status
               AND cr.flg_status IN (pk_consult_req.g_consult_req_stat_auth,
                                     pk_consult_req.g_consult_req_stat_apr,
                                     pk_consult_req.g_consult_req_stat_proc)
               AND ss.id_institution = i_prof.institution
                  -- is the last POS request
               AND sps.id_sr_pos_schedule IN (SELECT a.id_sr_pos_schedule
                                                FROM (SELECT sps1.id_sr_pos_schedule,
                                                             rank() over(PARTITION BY sps1.id_schedule_sr ORDER BY sps1.dt_req DESC, sps1.dt_reg DESC) rank_sps
                                                        FROM sr_pos_schedule sps1
                                                       WHERE sps1.flg_status = g_pos_schedule_active) a
                                               WHERE a.rank_sps = 1)
             ORDER BY s.dt_begin_tstz, s.dt_begin_tstz;
    
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
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_pos_pharm_grid;

    /**************************************************************************
    *                                                                         *
    * function used to return information on pharmacyst evaluation            *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_pharm
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN schedule_sr.id_episode%TYPE,
        o_pos_validation OUT pk_types.cursor_type,
        o_drug_presc     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_POS_PHARM';
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(200) INDEX BY sys_message.code_message%TYPE;
        sr_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_POS_M007', 'SR_POS_M008');
    
        l_tbl_id_prescription      table_number;
        l_tbl_id_prescription_type table_varchar;
        l_id_patient               patient.id_patient%TYPE;
        l_error                    t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- get all messages
        g_error := 'Fetching all labels';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            sr_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'Fetch o_pos_validation';
        pk_alertlog.log_debug(g_error);
        OPEN o_pos_validation FOR
            SELECT id_sr_pos_pharm,
                   id_sr_pos_schedule,
                   notes_evaluation,
                   lbl_notes_evaluation,
                   id_prescription,
                   id_prescription_type,
                   notes_assessment,
                   lbl_notes_assessment,
                   action_date,
                   desc_prof_reg,
                   desc_prof_sig,
                   flg_status,
                   (CASE
                        WHEN (id_sr_pos_pharm IS NOT NULL AND flg_status != pk_alert_constant.g_cancelled) THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END) flg_create,
                   (CASE
                        WHEN (flg_status = pk_alert_constant.g_active) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END) flg_cancel,
                   (CASE
                        WHEN (flg_status = pk_alert_constant.g_active) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END) flg_edit
              FROM (SELECT spp.id_sr_pos_pharm,
                           sps.id_sr_pos_schedule,
                           spp.notes_evaluation,
                           sr_code_messages('SR_POS_M008') lbl_notes_evaluation,
                           sppd.id_prescription,
                           sppd.id_prescription_type,
                           sppd.assessment notes_assessment,
                           sr_code_messages('SR_POS_M007') lbl_notes_assessment,
                           pk_date_utils.date_char_tsz(i_lang, spp.dt_reg, i_prof.institution, i_prof.software) action_date,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, spp.id_prof_reg) desc_prof_reg,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, spp.id_prof_reg, spp.dt_reg, ss.id_episode) desc_prof_sig,
                           rank() over(ORDER BY sps.dt_req DESC, sps.dt_reg DESC, spp.dt_reg DESC) rank,
                           spp.dt_reg,
                           spp.flg_status,
                           sps.flg_status sps_status,
                           sppd.id_sr_pos_pharm_det
                      FROM schedule_sr ss
                     INNER JOIN sr_pos_schedule sps
                        ON sps.id_schedule_sr = ss.id_schedule_sr
                      LEFT JOIN sr_pos_pharm spp
                        ON spp.id_sr_pos_schedule = sps.id_sr_pos_schedule
                       AND spp.flg_status IN (g_pos_pharm_active, g_pos_pharm_cancel)
                      LEFT JOIN sr_pos_pharm_det sppd
                        ON sppd.id_sr_pos_pharm = spp.id_sr_pos_pharm
                       AND sppd.flg_status IN (g_pos_pharm_det_active, g_pos_pharm_det_cancel)
                     WHERE ss.id_episode = i_id_episode)
             WHERE rank = 1
             ORDER BY dt_reg DESC, id_sr_pos_pharm_det ASC;
    
        g_error := 'Fetch prescription collections';
        pk_alertlog.log_debug(g_error);
        SELECT CAST(COLLECT(to_number(id_prescription)) AS table_number) id_prescription,
               CAST(COLLECT(id_prescription_type) AS table_varchar) id_prescription_type
          INTO l_tbl_id_prescription, l_tbl_id_prescription_type
          FROM (SELECT DISTINCT id_prescription, id_prescription_type
                  FROM schedule_sr ss
                 INNER JOIN sr_pos_schedule sps
                    ON sps.id_schedule_sr = ss.id_schedule_sr
                  LEFT JOIN sr_pos_pharm spp
                    ON spp.id_sr_pos_schedule = sps.id_sr_pos_schedule
                   AND spp.flg_status = g_pos_pharm_active
                  LEFT JOIN sr_pos_pharm_det sppd
                    ON sppd.id_sr_pos_pharm = spp.id_sr_pos_pharm
                   AND sppd.flg_status = g_pos_pharm_det_active
                 WHERE ss.id_episode = i_id_episode);
    
        g_error := 'Fetch id_patient';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT ss.id_patient
              INTO l_id_patient
              FROM schedule_sr ss
             WHERE ss.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                SELECT epis.id_patient
                  INTO l_id_patient
                  FROM episode epis
                 WHERE epis.id_episode = i_id_episode;
        END;
    
        g_error := 'Fetch o_drug_presc';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.get_active_medication(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_patient        => l_id_patient,
                                                           i_id_prescription   => l_tbl_id_prescription,
                                                           i_prescription_type => l_tbl_id_prescription_type,
                                                           o_active_med        => o_drug_presc,
                                                           o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_drug_presc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_drug_presc);
            RETURN FALSE;
    END get_pos_pharm;

    /**************************************************************************
    *                                                                         *
    * function used to save pharmacyst evaluation                             *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_pharm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_id_prescription     IN table_number,
        i_prescription_type   IN table_varchar,
        i_notes_assessment    IN table_varchar,
        i_notes_evaluation    IN sr_pos_pharm.notes_evaluation%TYPE,
        o_id_sr_pos_pharm     OUT sr_pos_pharm.id_sr_pos_pharm%TYPE,
        o_id_sr_pos_pharm_det OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_POS_PHARM';
    
        l_diff                  VARCHAR2(1);
        l_rows                  table_varchar;
        l_sr_pos_pharm_next     sr_pos_pharm.id_sr_pos_pharm%TYPE;
        l_sr_pos_pharm          sr_pos_pharm.id_sr_pos_pharm%TYPE;
        l_sr_pos_pharm_det_next sr_pos_pharm_det.id_sr_pos_pharm_det%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'Check if i_id_sr_pos_schedule is already inserted in sr_pos_pharm';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT pk_alert_constant.g_yes, spp.id_sr_pos_pharm
              INTO l_diff, l_sr_pos_pharm
              FROM sr_pos_pharm spp
             WHERE spp.id_sr_pos_schedule = i_id_sr_pos_schedule
               AND spp.flg_status = g_pos_pharm_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_diff         := NULL;
                l_sr_pos_pharm := NULL;
        END;
    
        IF (nvl(l_diff, pk_alert_constant.g_yes) = pk_alert_constant.g_yes)
        THEN
        
            IF l_diff IS NOT NULL
            THEN
                l_rows  := table_varchar();
                g_error := 'call ts_sr_pos_pharm.upd for id_sr_pos_schedule: ' || i_id_sr_pos_schedule;
                pk_alertlog.log_debug(g_error);
                ts_sr_pos_pharm.upd(flg_status_in => g_pos_pharm_outd,
                                    where_in      => 'id_sr_pos_schedule = ' || i_id_sr_pos_schedule ||
                                                     ' and flg_status != ''' || g_pos_pharm_outd || '''',
                                    rows_out      => l_rows);
                g_error := 'PROCESS_UPDATE SR_POS_PHARM';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SR_POS_PHARM',
                                              i_rowids       => l_rows,
                                              i_list_columns => table_varchar('FLG_STATUS'),
                                              o_error        => o_error);
            END IF;
        
            l_sr_pos_pharm_next := ts_sr_pos_pharm.next_key;
        
            l_rows := table_varchar();
        
            g_error := 'call ts_sr_pos_pharm.ins for id_sr_pos_schedule: ' || i_id_sr_pos_schedule;
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_pharm.ins(id_sr_pos_pharm_in    => l_sr_pos_pharm_next,
                                id_sr_pos_schedule_in => i_id_sr_pos_schedule,
                                flg_status_in         => g_pos_pharm_active,
                                notes_evaluation_in   => i_notes_evaluation,
                                id_prof_reg_in        => i_prof.id,
                                dt_reg_in             => g_sysdate_tstz,
                                rows_out              => l_rows);
            g_error := 'PROCESS_INSERT SR_POS_PHARM';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_PHARM',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            o_id_sr_pos_pharm := l_sr_pos_pharm_next;
        END IF;
    
        g_error := 'Check data structure integrity';
        pk_alertlog.log_debug(g_error);
        IF (i_id_prescription.count != i_prescription_type.count AND
           i_id_prescription.count != i_notes_assessment.count)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Process update/insert';
        pk_alertlog.log_debug(g_error);
        o_id_sr_pos_pharm_det := table_number();
        FOR i IN 1 .. i_id_prescription.count
        LOOP
            IF (l_sr_pos_pharm IS NOT NULL)
            THEN
                l_rows := table_varchar();
            
                g_error := 'CALL TS_SR_POS_PHARM_DET.UPD FOR ID_SR_POS_PHARM: ' || l_sr_pos_pharm;
                pk_alertlog.log_debug(g_error);
                ts_sr_pos_pharm_det.upd(flg_status_in => g_pos_pharm_outd,
                                        where_in      => 'id_sr_pos_pharm = ' || l_sr_pos_pharm ||
                                                         ' and id_prescription = ' || i_id_prescription(i) ||
                                                         ' and id_prescription_type = ''' || i_prescription_type(i) || '''',
                                        rows_out      => l_rows);
            
                g_error := 'PROCESS_UPDATE SR_POS_PHARM_DET';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SR_POS_PHARM_DET',
                                              i_rowids       => l_rows,
                                              i_list_columns => table_varchar('FLG_STATUS'),
                                              o_error        => o_error);
            END IF;
        
            l_sr_pos_pharm_det_next := ts_sr_pos_pharm_det.next_key;
        
            l_rows  := table_varchar();
            g_error := 'CALL TS_SR_POS_PHARM_DET.INS FOR ID_SR_POS_PHARM_DET: ' || l_sr_pos_pharm_det_next;
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_pharm_det.ins(id_sr_pos_pharm_det_in  => l_sr_pos_pharm_det_next,
                                    id_sr_pos_pharm_in      => nvl(l_sr_pos_pharm_next, l_sr_pos_pharm),
                                    id_prescription_in      => i_id_prescription(i),
                                    id_prescription_type_in => i_prescription_type(i),
                                    flg_status_in           => g_pos_pharm_det_active,
                                    assessment_in           => i_notes_assessment(i),
                                    rows_out                => l_rows);
        
            g_error := 'PROCESS_INSERT SR_POS_PHARM_DET';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_PHARM_DET',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            o_id_sr_pos_pharm_det.extend;
            o_id_sr_pos_pharm_det(o_id_sr_pos_pharm_det.count) := l_sr_pos_pharm_det_next;
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.raise_error(error_code_in => '-20101',
                                            text_in       => g_error,
                                            name1_in      => 'i_id_prescription.COUNT',
                                            value1_in     => i_id_prescription.count,
                                            name2_in      => 'i_prescription_type.COUNT',
                                            value2_in     => i_prescription_type.count,
                                            name3_in      => 'i_notes_assessment.COUNT',
                                            value3_in     => i_notes_assessment.count);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pos_pharm;

    /**************************************************************************
    *                                                                         *
    * function used to cancel pharmacyst evaluation                           *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION cancel_pos_pharm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sr_pos_pharm  IN sr_pos_pharm.id_sr_pos_pharm%TYPE,
        i_id_cancel_reason IN sr_pos_pharm.id_cancel_reason%TYPE,
        i_notes_cancel     IN sr_pos_pharm.notes_cancel%TYPE,
        o_id_sr_pos_pharm  OUT sr_pos_pharm.id_sr_pos_pharm%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'CANCEL_POS_PHARM';
    
        l_sr_pos_pharm sr_pos_pharm%ROWTYPE;
    
        l_rows                  table_varchar;
        l_sr_pos_pharm_next     sr_pos_pharm.id_sr_pos_pharm%TYPE;
        l_sr_pos_pharm_det_next sr_pos_pharm_det.id_sr_pos_pharm_det%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'FETCH RECORD FOR I_ID_SR_POS_PHARM: ' || i_id_sr_pos_pharm;
        pk_alertlog.log_debug(g_error);
        SELECT spp.*
          INTO l_sr_pos_pharm
          FROM sr_pos_pharm spp
         WHERE spp.id_sr_pos_pharm = i_id_sr_pos_pharm;
    
        l_sr_pos_pharm.flg_status := g_pos_pharm_outd;
    
        g_error := 'OUTDATE RECORD FOR I_ID_SR_POS_PHARM: ' || i_id_sr_pos_pharm;
        pk_alertlog.log_debug(g_error);
        l_rows  := table_varchar();
        g_error := 'CALL TS_SR_POS_PHARM.UPD ';
        pk_alertlog.log_debug(g_error);
        ts_sr_pos_pharm.upd(rec_in => l_sr_pos_pharm, rows_out => l_rows);
    
        g_error := 'CALL PROCESS_UPDATE FOR SR_POS_PHARM TABLE ';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SR_POS_PHARM',
                                      i_rowids       => l_rows,
                                      i_list_columns => table_varchar('FLG_STATUS'),
                                      o_error        => o_error);
    
        l_sr_pos_pharm_next := ts_sr_pos_pharm.next_key;
        o_id_sr_pos_pharm   := l_sr_pos_pharm_next;
    
        g_error := 'CANCEL RECORD FOR ID_SR_POS_SCHEDULE: ' || l_sr_pos_pharm.id_sr_pos_schedule;
        pk_alertlog.log_debug(g_error);
        l_rows := table_varchar();
        ts_sr_pos_pharm.ins(id_sr_pos_pharm_in    => l_sr_pos_pharm_next,
                            id_sr_pos_schedule_in => l_sr_pos_pharm.id_sr_pos_schedule,
                            flg_status_in         => g_pos_pharm_cancel,
                            notes_evaluation_in   => l_sr_pos_pharm.notes_evaluation,
                            id_cancel_reason_in   => i_id_cancel_reason,
                            notes_cancel_in       => i_notes_cancel,
                            id_prof_reg_in        => i_prof.id,
                            dt_reg_in             => g_sysdate_tstz,
                            rows_out              => l_rows);
    
        g_error := 'CALL PROCESS_INSERT FOR SR_POS_PHARM TABLE ';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_POS_PHARM',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'INSERT CANCELED RECORDS INTO SR_POS_PHARM_DET FOR ID_SR_POS_SCHEDULE: ' ||
                   l_sr_pos_pharm.id_sr_pos_schedule;
        pk_alertlog.log_debug(g_error);
        FOR rec IN (SELECT sppd.id_prescription, sppd.id_prescription_type, sppd.flg_status, sppd.assessment
                      FROM sr_pos_pharm_det sppd
                     WHERE sppd.id_sr_pos_pharm = l_sr_pos_pharm.id_sr_pos_pharm)
        LOOP
            l_sr_pos_pharm_det_next := ts_sr_pos_pharm_det.next_key;
        
            l_rows  := table_varchar();
            g_error := 'CALL TS_SR_POS_PHARM_DET.INS FOR ID_SR_POS_PHARM_DET: ' || l_sr_pos_pharm_det_next;
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_pharm_det.ins(id_sr_pos_pharm_det_in  => l_sr_pos_pharm_det_next,
                                    id_sr_pos_pharm_in      => l_sr_pos_pharm_next,
                                    id_prescription_in      => rec.id_prescription,
                                    id_prescription_type_in => rec.id_prescription_type,
                                    flg_status_in           => g_pos_pharm_det_cancel,
                                    assessment_in           => rec.assessment,
                                    rows_out                => l_rows);
        
            g_error := 'CALL PROCESS_INSERT FOR SR_POS_PHARM_DET TABLE ';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_PHARM_DET',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END LOOP;
    
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
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_pos_pharm;

    /**************************************************************************
    *                                                                         *
    * function used to return information on pharmacyst evaluation            *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_pharm_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN schedule_sr.id_episode%TYPE,
        o_pos_validation OUT pk_types.cursor_type,
        o_drug_presc     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_POS_PHARM_DETAIL';
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(200) INDEX BY sys_message.code_message%TYPE;
        sr_code_messages t_code_messages;
        va_code_messages table_varchar2 := table_varchar2('SR_POS_M007', 'SR_POS_M008', 'SR_POS_M018', 'SR_POS_M019');
    
        l_tbl_id_prescription      table_number;
        l_tbl_id_prescription_type table_varchar;
        l_id_patient               patient.id_patient%TYPE;
        l_error                    t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- get all messages
        g_error := 'Fetching all labels';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            sr_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'Fetch o_pos_validation';
        pk_alertlog.log_debug(g_error);
        OPEN o_pos_validation FOR
            SELECT spp.id_sr_pos_pharm,
                   spp.flg_status flg_status_pharm,
                   sppd.id_sr_pos_pharm_det,
                   sppd.flg_status flg_status_pharm_det,
                   ss.id_schedule_sr,
                   sps.id_sr_pos_schedule,
                   spp.notes_evaluation,
                   sr_code_messages('SR_POS_M008') lbl_notes_evaluation,
                   sppd.id_prescription,
                   sppd.id_prescription_type,
                   sppd.assessment notes_assessment,
                   sr_code_messages('SR_POS_M007') lbl_notes_assessment,
                   pk_date_utils.date_char_tsz(i_lang, spp.dt_reg, i_prof.institution, i_prof.software) action_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, spp.id_prof_reg) desc_prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, spp.id_prof_reg, spp.dt_reg, ss.id_episode) desc_prof_sig,
                   (CASE
                        WHEN spp.flg_status = g_pos_pharm_active THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END) flg_history,
                   CASE spp.flg_status
                       WHEN g_pos_pharm_outd THEN
                        sr_code_messages('SR_POS_M018')
                       WHEN g_pos_pharm_cancel THEN
                        sr_code_messages('SR_POS_M019')
                       ELSE
                        NULL
                   END lbl_action
              FROM schedule_sr ss
             INNER JOIN sr_pos_schedule sps
                ON sps.id_schedule_sr = ss.id_schedule_sr
             INNER JOIN sr_pos_pharm spp
                ON spp.id_sr_pos_schedule = sps.id_sr_pos_schedule
             INNER JOIN sr_pos_pharm_det sppd
                ON sppd.id_sr_pos_pharm = spp.id_sr_pos_pharm
             WHERE ss.id_episode = i_id_episode
             ORDER BY spp.dt_reg DESC;
    
        g_error := 'Fetch prescription collections';
        pk_alertlog.log_debug(g_error);
        SELECT CAST(COLLECT(to_number(id_prescription)) AS table_number) id_prescription,
               CAST(COLLECT(id_prescription_type) AS table_varchar) id_prescription_type
          INTO l_tbl_id_prescription, l_tbl_id_prescription_type
          FROM (SELECT DISTINCT id_prescription, id_prescription_type
                  FROM schedule_sr ss
                 INNER JOIN sr_pos_schedule sps
                    ON sps.id_schedule_sr = ss.id_schedule_sr
                 INNER JOIN sr_pos_pharm spp
                    ON spp.id_sr_pos_schedule = sps.id_sr_pos_schedule
                 INNER JOIN sr_pos_pharm_det sppd
                    ON sppd.id_sr_pos_pharm = spp.id_sr_pos_pharm
                 WHERE ss.id_episode = i_id_episode);
    
        g_error := 'Fetch id_patient';
        pk_alertlog.log_debug(g_error);
        SELECT ss.id_patient
          INTO l_id_patient
          FROM schedule_sr ss
         WHERE ss.id_episode = i_id_episode;
    
        g_error := 'Fetch o_drug_presc';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.get_active_medication(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_patient        => l_id_patient,
                                                           i_id_prescription   => l_tbl_id_prescription,
                                                           i_prescription_type => l_tbl_id_prescription_type,
                                                           o_active_med        => o_drug_presc,
                                                           o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_drug_presc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_drug_presc);
            RETURN FALSE;
    END get_pos_pharm_detail;

    /**************************************************************************
    * Check to POS status to know if is necessary to show the warning message
    *
    * @param i_lang           Id language
    * @param i_prof           Id professional, institution and software
    * @param i_episode        ID episode
    *
    * @return                 Yes or no
    * 
    * @author                 Filipe Silva
    * @version                2.6.0.1
    * @since                  2010/04/15
       **********************************************************************/
    FUNCTION check_pos_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_sr_pos_status_values table_number;
        l_ret                     VARCHAR2(1);
        o_error                   t_error_out;
        l_function_name           VARCHAR2(30) := 'CHECK_POS_STATUS';
        l_id_sr_pos_status        sr_pos_schedule.id_sr_pos_status%TYPE;
    
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_episode:' || i_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        BEGIN
            g_error := 'GET ID_SR_POS_STATUS FOR EPISODE ' || i_episode;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            SELECT t.id_sr_pos_status, pk_alert_constant.g_yes
              INTO l_id_sr_pos_status, l_ret
              FROM (SELECT sps.id_sr_pos_status
                      FROM sr_pos_schedule sps
                     INNER JOIN schedule_sr sr
                        ON sr.id_schedule_sr = sps.id_schedule_sr
                       AND sr.id_episode = i_episode
                     ORDER BY sps.dt_req DESC) t
             WHERE rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_ret := pk_alert_constant.g_no;
        END;
    
        IF l_ret = pk_alert_constant.g_yes
        THEN
        
            g_error := 'POS request exists, GET ID_SR_POS_STATUS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            SELECT t.id_sr_pos_status
              BULK COLLECT
              INTO l_id_sr_pos_status_values
              FROM (SELECT sps.id_sr_pos_status, rank() over(ORDER BY sps.id_institution DESC) origin_rank
                      FROM sr_pos_status sps
                     WHERE sps.id_institution IN (0, i_prof.institution)
                       AND sps.flg_status IN (pk_alert_constant.g_sr_pos_status_a, pk_alert_constant.g_sr_pos_status_no)
                       AND sps.flg_available = pk_alert_constant.g_available) t
             WHERE t.origin_rank = 1;
        
            g_error := 'CHECK POS STATUS FOR EPISODE ' || i_episode;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            BEGIN
            
                SELECT pk_alert_constant.g_no
                  INTO l_ret
                  FROM dual
                 WHERE l_id_sr_pos_status IN (SELECT *
                                                FROM TABLE(l_id_sr_pos_status_values));
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := pk_alert_constant.g_yes;
            END;
        END IF;
    
        RETURN l_ret;
    
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
            RETURN NULL;
        
    END check_pos_status;

    /**************************************************************************
    * Returns POS request permission for the professional                     *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_create_permission          Flag with info about create POS     *
    *                                     permission for the professional     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/02                              *
    **************************************************************************/
    FUNCTION check_pos_request_permission
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_create_permission OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'CHECK_POS_REQUEST_PERMISSION';
    
        l_ret   VARCHAR2(1);
        l_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := '';
    
        o_create_permission := l_ret;
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
            RETURN NULL;
        
    END check_pos_request_permission;

    /******************************************************************
    * Returns if the POS validity has expired                         *
    *                                                                 *
    * @param i_lang        language id                                *
    * @param i_prof        professional, software and institution ids *
    * @param i_date        date to check                              *
    * @param i_flg_status  POS status                                 *
    *                                                                 *
    * @return              Returns string Y/N                         *
    *                                                                 *
    * @author              Jorge Canossa                              *
    * @version             1.0                                        *
    * @since               2010/06/29                                 *
    *******************************************************************/
    FUNCTION check_pos_is_expired
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_date       IN sr_pos_schedule.dt_valid%TYPE,
        i_flg_status IN sr_pos_status.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_function_name VARCHAR2(200) := 'CHECK_POS_IS_EXPIRED';
        l_error         t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'CHECK_POS_IS_EXPIRED';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF (i_flg_status = pk_alert_constant.g_sr_pos_status_a AND
           pk_date_utils.compare_dates_tsz(i_prof, nvl(i_date, current_timestamp) + 1, current_timestamp) =
           g_pos_dt_valid_lower)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
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
    END check_pos_is_expired;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_sr_pos;
/
