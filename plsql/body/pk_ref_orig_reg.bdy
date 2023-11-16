/*-- Last Change Revision: $Rev: 2027590 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_orig_reg IS

    g_error         VARCHAR2(4000);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;

    /**
    * Lists all tasks related to p1 by doctor
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ext_req        Referral identifier
    * @param   o_tasks          Array of tasks for schedule
    * @param   o_info           Array of tasks for appointment
    * @param   o_notes          Notes related to each task
    * @param   o_editable       Check if referral is editable     
    * @param   o_error          An error message, set when return=false
    *
    * @value   o_editable       {*} 'Y' - referral is editable {*} 'N' - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION get_tasks_done
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        o_tasks    OUT pk_types.cursor_type,
        o_info     OUT pk_types.cursor_type,
        o_notes    OUT pk_types.cursor_type,
        o_editable OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_notes / ID_REF=' || i_ext_req;
        pk_alertlog.log_debug(g_error);
        OPEN o_notes FOR
            SELECT pd.text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pd.dt_insert_tstz, i_prof) dt_insert,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional) prof_name,
                   pd.flg_status,
                   pd.id_group
              FROM p1_detail pd
             WHERE pd.id_external_request = i_ext_req
               AND pd.flg_type IN (pk_ref_constant.g_detail_type_nadm,
                                   pk_ref_constant.g_detail_type_bdcl,
                                   pk_ref_constant.g_detail_type_admi)
            --AND pd.flg_status = pk_ref_constant.g_detail_status_a
             ORDER BY pd.dt_insert_tstz DESC;
    
        g_error := 'OPEN o_tasks / ID_REF=' || i_ext_req;
        pk_alertlog.log_debug(g_error);
        OPEN o_tasks FOR
            SELECT tkd.id_task_done,
                   tkd.flg_task_done,
                   tkd.flg_type,
                   tkd.notes,
                   pk_translation.get_translation(i_lang, tsk.code_task) desc_documents,
                   decode(tsk.flg_type,
                          pk_ref_constant.g_p1_task_done_type_z,
                          pk_ref_constant.g_no,
                          decode(exr.flg_status,
                                 pk_ref_constant.g_p1_status_n,
                                 pk_ref_constant.g_yes,
                                 pk_ref_constant.g_p1_status_v,
                                 pk_ref_constant.g_yes,
                                 pk_ref_constant.g_no)) editable,
                   tkd.flg_status,
                   tkd.id_group
              FROM p1_external_request exr
              JOIN p1_task_done tkd
                ON (exr.id_external_request = tkd.id_external_request)
              JOIN p1_task tsk
                ON (tsk.id_task = tkd.id_task)
             WHERE exr.id_external_request = i_ext_req
               AND tkd.flg_type IN (pk_ref_constant.g_p1_task_done_type_s, pk_ref_constant.g_p1_task_done_type_z) -- Needed for (S)cheduling or (P)atient data
               AND tkd.flg_status = pk_ref_constant.g_active
             ORDER BY tkd.flg_type, desc_documents;
    
        g_error := 'OPEN o_info / ID_REF=' || i_ext_req;
        pk_alertlog.log_debug(g_error);
        OPEN o_info FOR
            SELECT tkd.id_task_done,
                   tkd.flg_task_done,
                   tkd.flg_type,
                   tkd.notes,
                   pk_translation.get_translation(i_lang, tsk.code_task) desc_documents,
                   tkd.flg_status,
                   tkd.id_group
              FROM p1_task_done tkd
              JOIN p1_task tsk
                ON (tsk.id_task = tkd.id_task)
             WHERE id_external_request = i_ext_req
               AND tkd.flg_type = pk_ref_constant.g_p1_task_done_type_c -- Needed for (C)onsultation               
               AND tkd.flg_status = pk_ref_constant.g_active
             ORDER BY desc_documents;
    
        g_error    := 'o_editable';
        o_editable := pk_ref_core.is_editable(i_lang, i_prof, i_ext_req);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASK_DONE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_tasks);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes);
            RETURN FALSE;
    END get_tasks_done;

    /**
    * Update status of tasks for the request (replaces UPD_TASKS_DONE)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ext_req        Referral identifier
    * @param   I_ID_TASKS array of tasks ids
    * @param   I_FLG_STATUS_INI array tasks initial status
    * @param   I_FLG_STATUS_FIN array tasks final status
    * @param   i_notes notes     
    * @param   i_date           Operation date
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION update_tasks_done
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_tasks       IN table_number,
        i_flg_status_ini IN table_varchar,
        i_flg_status_fin IN table_varchar,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tsd        p1_task_done%ROWTYPE;
        l_editable   VARCHAR2(1);
        l_rowids     table_varchar;
        l_exr_row    p1_external_request%ROWTYPE;
        l_prof_data  t_rec_prof_data;
        l_detail_row p1_detail%ROWTYPE;
        l_var        p1_detail.id_detail%TYPE;
        l_param      table_varchar;
    BEGIN
        g_error        := 'Init update_tasks_done / ID_REF=' || i_ext_req;
        g_sysdate_tstz := nvl(i_date, pk_ref_utils.get_sysdate);
        l_editable     := pk_ref_constant.g_no;
        o_track        := table_number();
    
        g_error := 'LOOP';
        FOR i IN 1 .. i_id_tasks.count
        LOOP
        
            IF (nvl(i_flg_status_fin(i), pk_ref_constant.g_no) != nvl(i_flg_status_ini(i), pk_ref_constant.g_no))
            THEN
            
                l_tsd.flg_task_done := nvl(i_flg_status_fin(i), pk_ref_constant.g_no);
                IF l_tsd.flg_task_done = pk_ref_constant.g_yes
                THEN
                    l_tsd.dt_completed_tstz := g_sysdate_tstz;
                END IF;
            
                UPDATE p1_task_done
                   SET flg_task_done     = l_tsd.flg_task_done,
                       dt_completed_tstz = l_tsd.dt_completed_tstz,
                       id_prof_exec      = i_prof.id,
                       id_inst_exec      = i_prof.institution
                 WHERE id_external_request = i_ext_req
                   AND id_task_done = i_id_tasks(i);
            
                g_error := 'UPDATE P1_EXTERNAL_REQUEST';
                ts_p1_external_request.upd(id_external_request_in      => i_ext_req,
                                           dt_last_interaction_tstz_in => g_sysdate_tstz,
                                           rows_out                    => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'P1_EXTERNAL_REQUEST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        
        END LOOP;
    
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
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_exr_row.id_dep_clin_serv,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- do this check before processing referral status
        g_error    := 'Calling pk_ref_core.is_editable';
        l_editable := pk_ref_core.is_editable(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_prof_data => l_prof_data,
                                              i_ext_row   => l_exr_row);
    
        -- ALERT-50429 - sending referral to dest_institution or for approval
        IF l_exr_row.flg_status IN (pk_ref_constant.g_p1_status_n, pk_ref_constant.g_p1_status_v) -- ALERT-223767
        THEN
            g_error := 'Calling pk_ref_core.init_param_tab / ID_REF=' || l_exr_row.id_external_request;
            l_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ext_req            => l_exr_row.id_external_request,
                                                  i_id_patient         => l_exr_row.id_patient,
                                                  i_id_inst_orig       => l_exr_row.id_inst_orig,
                                                  i_id_inst_dest       => l_exr_row.id_inst_dest,
                                                  i_id_dep_clin_serv   => l_exr_row.id_dep_clin_serv,
                                                  i_id_speciality      => l_exr_row.id_speciality,
                                                  i_flg_type           => l_exr_row.flg_type,
                                                  i_id_prof_requested  => l_exr_row.id_prof_requested,
                                                  i_id_prof_redirected => l_exr_row.id_prof_redirected,
                                                  i_id_prof_status     => l_exr_row.id_prof_status,
                                                  i_external_sys       => l_exr_row.id_external_sys,
                                                  i_flg_status         => l_exr_row.flg_status);
        
            g_error  := 'Call pk_ref_core.process_auto_transition / WF=' || l_exr_row.id_workflow || ' ID_REF=' ||
                        l_exr_row.id_external_request;
            g_retval := pk_ref_core.process_auto_transition(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_prof_data => l_prof_data,
                                                            i_id_ref    => l_exr_row.id_external_request,
                                                            i_date      => g_sysdate_tstz,
                                                            io_param    => l_param,
                                                            io_track    => o_track,
                                                            o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error      := 'Clean l_detail_row';
        l_detail_row := NULL;
    
        IF o_track.exists(1)
           AND o_track(1) IS NOT NULL
        THEN
            l_detail_row.id_tracking := o_track(1); -- first iteration
        END IF;
    
        -- JS 2007-12-15: notes will only be inserted if referral is editable
        IF l_editable = pk_ref_constant.g_yes
           AND i_notes IS NOT NULL
        THEN
        
            g_error                          := 'INSERT DETAIL ' || pk_ref_constant.g_detail_type_admi || ' ';
            l_detail_row.id_external_request := i_ext_req;
            l_detail_row.text                := i_notes;
            l_detail_row.dt_insert_tstz      := g_sysdate_tstz;
            l_detail_row.flg_type            := pk_ref_constant.g_detail_type_admi;
            l_detail_row.id_professional     := i_prof.id;
            l_detail_row.id_institution      := i_prof.institution;
        
            l_detail_row.flg_status := pk_ref_constant.g_detail_status_a;
        
            g_error  := 'Calling pk_ref_api.set_p1_detail';
            g_retval := pk_ref_api.set_p1_detail(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_p1_detail => l_detail_row,
                                                 o_id_detail => l_var,
                                                 o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- JS 2007-12-15: If o_track.count != 0, there was a status change.
        -- In that case, associate all notes (having id_tracking not null) to the current status change (current o_track(1))
        IF l_detail_row.id_tracking IS NOT NULL
        THEN
            g_error := 'UPDATE p1_detail';
            UPDATE p1_detail d
               SET id_tracking = l_detail_row.id_tracking
             WHERE id_external_request = i_ext_req
               AND d.flg_type = pk_ref_constant.g_detail_type_admi
               AND d.id_tracking IS NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := g_error || ' (' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_TASKS_DONE',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_tasks_done;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_orig_reg;
/
