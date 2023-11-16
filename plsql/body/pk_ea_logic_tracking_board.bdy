/*-- Last Change Revision: $Rev: 1989158 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-05-17 10:16:03 +0100 (seg, 17 mai 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_tracking_board IS

    g_prof_category category.flg_type%TYPE;

    -- Update tracking_board_ea
    FUNCTION update_on_tracking_board_ea
    (
        i_lang                  IN language.id_language%TYPE,
        i_tracking_board_ea_rec IN ts_tracking_board_ea.tracking_board_ea_tc,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'UPDATE_ON_TRACKING_BOARD_EA';
        l_rows table_varchar;
    BEGIN
        IF i_tracking_board_ea_rec.exists(1)
        THEN
            FOR i IN i_tracking_board_ea_rec.first .. i_tracking_board_ea_rec.last
            LOOP
                ts_tracking_board_ea.upd(id_episode_in            => i_tracking_board_ea_rec(i).id_episode,
                                         id_patient_in            => i_tracking_board_ea_rec(i).id_patient,
                                         id_epis_type_in          => i_tracking_board_ea_rec(i).id_epis_type,
                                         id_triage_color_in       => i_tracking_board_ea_rec(i).id_triage_color,
                                         id_fast_track_in         => i_tracking_board_ea_rec(i).id_fast_track,
                                         id_room_in               => i_tracking_board_ea_rec(i).id_room,
                                         id_bed_in                => i_tracking_board_ea_rec(i).id_bed,
                                         dt_begin_in              => i_tracking_board_ea_rec(i).dt_begin,
                                         id_diet_in               => i_tracking_board_ea_rec(i).id_diet,
                                         desc_diet_in             => i_tracking_board_ea_rec(i).desc_diet,
                                         id_prof_resp_in          => i_tracking_board_ea_rec(i).id_prof_resp,
                                         id_nurse_resp_in         => i_tracking_board_ea_rec(i).id_nurse_resp,
                                         lab_count_in             => i_tracking_board_ea_rec(i).lab_count,
                                         lab_pend_in              => i_tracking_board_ea_rec(i).lab_pend,
                                         lab_req_in               => i_tracking_board_ea_rec(i).lab_req,
                                         lab_harv_in              => i_tracking_board_ea_rec(i).lab_harv,
                                         lab_transp_in            => i_tracking_board_ea_rec(i).lab_transp,
                                         lab_exec_in              => i_tracking_board_ea_rec(i).lab_exec,
                                         lab_result_in            => i_tracking_board_ea_rec(i).lab_result,
                                         lab_result_read_in       => i_tracking_board_ea_rec(i).lab_result_read,
                                         lab_ext_in               => i_tracking_board_ea_rec(i).lab_ext,
                                         lab_wtg_in               => i_tracking_board_ea_rec(i).lab_wtg,
                                         exam_count_in            => i_tracking_board_ea_rec(i).exam_count,
                                         exam_pend_in             => i_tracking_board_ea_rec(i).exam_pend,
                                         exam_req_in              => i_tracking_board_ea_rec(i).exam_req,
                                         exam_transp_in           => i_tracking_board_ea_rec(i).exam_transp,
                                         exam_exec_in             => i_tracking_board_ea_rec(i).exam_exec,
                                         exam_result_in           => i_tracking_board_ea_rec(i).exam_result,
                                         exam_result_read_in      => i_tracking_board_ea_rec(i).exam_result_read,
                                         exam_ext_in              => i_tracking_board_ea_rec(i).exam_ext,
                                         exam_perf_in             => i_tracking_board_ea_rec(i).exam_perf,
                                         exam_wtg_in              => i_tracking_board_ea_rec(i).exam_wtg,
                                         interv_count_in          => i_tracking_board_ea_rec(i).interv_count,
                                         interv_pend_in           => i_tracking_board_ea_rec(i).interv_pend,
                                         interv_sos_in            => i_tracking_board_ea_rec(i).interv_sos,
                                         interv_req_in            => i_tracking_board_ea_rec(i).interv_req,
                                         interv_exec_in           => i_tracking_board_ea_rec(i).interv_exec,
                                         interv_finish_in         => i_tracking_board_ea_rec(i).interv_finish,
                                         med_count_in             => i_tracking_board_ea_rec(i).med_count,
                                         med_pend_in              => i_tracking_board_ea_rec(i).med_pend,
                                         med_req_in               => i_tracking_board_ea_rec(i).med_req,
                                         med_exec_in              => i_tracking_board_ea_rec(i).med_exec,
                                         med_finish_in            => i_tracking_board_ea_rec(i).med_finish,
                                         med_sos_in               => i_tracking_board_ea_rec(i).med_sos,
                                         transp_count_in          => i_tracking_board_ea_rec(i).transp_count,
                                         transp_delay_in          => i_tracking_board_ea_rec(i).transp_delay,
                                         transp_ongoing_in        => i_tracking_board_ea_rec(i).transp_ongoing,
                                         monit_count_in           => i_tracking_board_ea_rec(i).monit_count,
                                         monit_delay_in           => i_tracking_board_ea_rec(i).monit_delay,
                                         monit_ongoing_in         => i_tracking_board_ea_rec(i).monit_ongoing,
                                         monit_finish_in          => i_tracking_board_ea_rec(i).monit_finish,
                                         dt_dg_last_update_in     => i_tracking_board_ea_rec(i).dt_dg_last_update,
                                         flg_has_stripes_in       => i_tracking_board_ea_rec(i).flg_has_stripes,
                                         lab_cc_in                => i_tracking_board_ea_rec(i).lab_cc,
                                         lab_sos_in               => i_tracking_board_ea_rec(i).lab_sos,
                                         exam_sos_in              => i_tracking_board_ea_rec(i).exam_sos,
                                         oth_exam_count_in        => i_tracking_board_ea_rec(i).oth_exam_count,
                                         oth_exam_pend_in         => i_tracking_board_ea_rec(i).oth_exam_pend,
                                         oth_exam_req_in          => i_tracking_board_ea_rec(i).oth_exam_req,
                                         oth_exam_transp_in       => i_tracking_board_ea_rec(i).oth_exam_transp,
                                         oth_exam_exec_in         => i_tracking_board_ea_rec(i).oth_exam_exec,
                                         oth_exam_result_in       => i_tracking_board_ea_rec(i).oth_exam_result,
                                         oth_exam_result_read_in  => i_tracking_board_ea_rec(i).oth_exam_result_read,
                                         oth_exam_ext_in          => i_tracking_board_ea_rec(i).oth_exam_ext,
                                         oth_exam_perf_in         => i_tracking_board_ea_rec(i).oth_exam_perf,
                                         oth_exam_wtg_in          => i_tracking_board_ea_rec(i).oth_exam_wtg,
                                         opinion_count_in         => i_tracking_board_ea_rec(i).opinion_count,
                                         opinion_state_in         => i_tracking_board_ea_rec(i).opinion_state,
                                         id_fast_track_nin        => FALSE,
                                         id_bed_nin               => FALSE,
                                         id_diet_nin              => FALSE,
                                         desc_diet_nin            => FALSE,
                                         id_prof_resp_nin         => FALSE,
                                         id_nurse_resp_nin        => FALSE,
                                         lab_count_nin            => FALSE,
                                         lab_pend_nin             => FALSE,
                                         lab_req_nin              => FALSE,
                                         lab_harv_nin             => FALSE,
                                         lab_transp_nin           => FALSE,
                                         lab_exec_nin             => FALSE,
                                         lab_result_nin           => FALSE,
                                         lab_result_read_nin      => FALSE,
                                         lab_ext_nin              => FALSE,
                                         exam_count_nin           => FALSE,
                                         exam_pend_nin            => FALSE,
                                         exam_req_nin             => FALSE,
                                         exam_transp_nin          => FALSE,
                                         exam_exec_nin            => FALSE,
                                         exam_result_nin          => FALSE,
                                         exam_result_read_nin     => FALSE,
                                         exam_ext_nin             => FALSE,
                                         exam_perf_nin            => FALSE,
                                         interv_count_nin         => FALSE,
                                         interv_pend_nin          => FALSE,
                                         interv_sos_nin           => FALSE,
                                         interv_req_nin           => FALSE,
                                         interv_exec_nin          => FALSE,
                                         interv_finish_nin        => FALSE,
                                         med_count_nin            => FALSE,
                                         med_pend_nin             => FALSE,
                                         med_req_nin              => FALSE,
                                         med_exec_nin             => FALSE,
                                         med_finish_nin           => FALSE,
                                         med_sos_nin              => FALSE,
                                         transp_count_nin         => FALSE,
                                         transp_delay_nin         => FALSE,
                                         transp_ongoing_nin       => FALSE,
                                         monit_count_nin          => FALSE,
                                         monit_delay_nin          => FALSE,
                                         monit_ongoing_nin        => FALSE,
                                         monit_finish_nin         => FALSE,
                                         dt_dg_last_update_nin    => FALSE,
                                         flg_has_stripes_nin      => TRUE,
                                         lab_cc_nin               => FALSE,
                                         lab_sos_nin              => FALSE,
                                         exam_sos_nin             => FALSE,
                                         oth_exam_count_nin       => FALSE,
                                         oth_exam_pend_nin        => FALSE,
                                         oth_exam_req_nin         => FALSE,
                                         oth_exam_transp_nin      => FALSE,
                                         oth_exam_exec_nin        => FALSE,
                                         oth_exam_result_nin      => FALSE,
                                         oth_exam_result_read_nin => FALSE,
                                         oth_exam_ext_nin         => FALSE,
                                         oth_exam_perf_nin        => FALSE,
                                         oth_exam_sos_nin         => FALSE,
                                         opinion_count_nin        => FALSE,
                                         opinion_state_nin        => FALSE,
                                         rows_out                 => l_rows);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END update_on_tracking_board_ea;

    /**
    * Count the number of not null timestamps inside the given array.
    *
    * @param i_timestamp_list Array with timestamps
    *
    * @return The number of not null elements
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/20
    */
    FUNCTION count_not_nulls(i_timestamp_list IN table_varchar) RETURN NUMBER IS
        l_ret NUMBER := 0;
        l_idx PLS_INTEGER;
    BEGIN
        FOR l_idx IN i_timestamp_list.first .. i_timestamp_list.last
        LOOP
            IF i_timestamp_list(l_idx) IS NOT NULL
            THEN
                l_ret := l_ret + 1;
            END IF;
        END LOOP;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;

    /**
    * Updates a record in the tracking_board_ea table
    *
    * @param i_lang            Language
    * @param i_prof            Professional array
    * @param i_id_episode_list Array with modified episodes
    *
    * @author Fábio Oliveira
    * @version 2.4.3-Denormalized
    * @since 2008/10/22
    */
    PROCEDURE update_ea_logic_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode_list IN table_number
    ) IS
        l_func_proc_name VARCHAR2(30) := 'UPDATE_EA_LOGIC_INFO';
        e_exception      EXCEPTION;
        l_error          t_error_out;
    
        CURSOR c_info IS
            SELECT ea.id_episode,
                   ea.id_patient,
                   ea.id_epis_type,
                   ei.id_triage_color,
                   ea.id_fast_track,
                   ei.id_room,
                   ei.id_bed,
                   ea.dt_begin,
                   diet.id_diet,
                   nvl2(diet.id_diet, 'DIET.CODE_DIET.' || diet.id_diet, diet.desc_diet) desc_diet,
                   ei.id_professional id_prof_resp,
                   ei.id_first_nurse_resp,
                   ea.lab_count,
                   ea.lab_pend,
                   ea.lab_req,
                   ea.lab_harv,
                   ea.lab_transp,
                   ea.lab_exec,
                   ea.lab_result,
                   ea.lab_result_read,
                   ea.exam_count,
                   ea.exam_pend,
                   ea.exam_req,
                   ea.exam_transp,
                   ea.exam_exec,
                   ea.exam_result,
                   ea.exam_result_read,
                   ea.interv_count,
                   ea.interv_pend,
                   ea.interv_sos,
                   ea.interv_req,
                   ea.interv_exec,
                   ea.interv_finish,
                   ea.med_count,
                   ea.med_pend,
                   ea.med_req,
                   ea.med_exec,
                   ea.med_finish,
                   ea.med_sos,
                   ea.transp_count,
                   ea.transp_delay,
                   ea.transp_ongoing,
                   ea.monit_count,
                   ea.monit_delay,
                   ea.monit_ongoing,
                   ea.monit_finish,
                   current_timestamp dt_dg_last_update,
                   ea.create_user,
                   ea.create_time,
                   ea.create_institution,
                   NULL update_user,
                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) update_time,
                   NULL update_institution,
                   ea.lab_ext,
                   ea.exam_ext,
                   ea.exam_perf,
                   ea.exam_wtg,
                   ea.lab_wtg,
                   -- Value of "flg_has_stripes" changes to "N" only if professional category is allowed to update DT_FIRST_OBS
                   -- and if DT_FIRST_OBS is not null.
                   decode((SELECT COUNT(*)
                            FROM dual
                           WHERE (pk_visit.check_first_obs_category(i_lang, g_prof_category) = pk_alert_constant.g_yes OR
                                 (ei.flg_dsch_status = 'R' AND
                                 pk_transfer_institution.check_epis_transfer(ei.id_episode) = 0))
                             AND ei.dt_first_obs_tstz IS NOT NULL),
                          1,
                          pk_alert_constant.g_no,
                          -- Check if DT_FIRST_OBS was cleared (e.g. when cancelling episode responsability).
                          -- Otherwise, send "NULL" to keep previous value.
                          decode((SELECT COUNT(*)
                                   FROM dual
                                  WHERE ei.dt_first_obs_tstz IS NULL),
                                 1,
                                 pk_alert_constant.g_yes,
                                 NULL)) flg_has_stripes,
                   ea.lab_cc,
                   ea.lab_sos,
                   ea.exam_sos,
                   ea.oth_exam_count,
                   ea.oth_exam_pend,
                   ea.oth_exam_req,
                   ea.oth_exam_transp,
                   ea.oth_exam_exec,
                   ea.oth_exam_result,
                   ea.oth_exam_result_read,
                   ea.oth_exam_ext,
                   ea.oth_exam_perf,
                   ea.oth_exam_wtg,
                   ea.oth_exam_sos,
                   ea.opinion_count,
                   ea.opinion_state
              FROM tracking_board_ea ea
              JOIN epis_info ei
                ON ei.id_episode = ea.id_episode
              LEFT JOIN (SELECT ed.id_episode, ed.id_diet, ed.desc_diet
                           FROM epis_diet ed
                          WHERE ed.flg_status = 'R') diet
                ON ea.id_episode = diet.id_episode
             WHERE ea.id_episode IN (SELECT *
                                       FROM TABLE(i_id_episode_list));
    
        l_tracking_board_ea_list ts_tracking_board_ea.tracking_board_ea_tc;
    
    BEGIN
        IF i_id_episode_list IS NULL
           OR i_id_episode_list.count = 0
        THEN
            RETURN;
        END IF;
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Selecting info', g_package_name, l_func_proc_name);
    
        OPEN c_info;
        FETCH c_info BULK COLLECT
            INTO l_tracking_board_ea_list;
        CLOSE c_info;
    
        IF l_tracking_board_ea_list IS NOT NULL
           AND l_tracking_board_ea_list.count > 0
        THEN
            pk_alertlog.log_debug('TRACKING_BOARD_EA: Updating', g_package_name, l_func_proc_name);
            IF NOT update_on_tracking_board_ea(i_lang                  => i_lang,
                                               i_tracking_board_ea_rec => l_tracking_board_ea_list,
                                               o_error                 => l_error)
            THEN
                RAISE e_exception;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END update_ea_logic_info;

    /**
    * Inserts or updates a record in the tracking_board_ea table
    *
    * @param i_lang       Language
    * @param i_prof       Professional array
    * @param i_episode_tc Array with inserted/modified episodes
    *
    * @author Fábio Oliveira
    * @version 2.4.3-Denormalized
    * @since 2008/10/22
    */
    PROCEDURE insert_ea_logic_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode_t IN episode%ROWTYPE
    ) IS
        l_func_proc_name      VARCHAR2(30) := 'INSERT_EA_LOGIC_ALL';
        l_tracking_board_ea_r tracking_board_ea%ROWTYPE;
        l_rows                table_varchar;
    
        l_dt_first_obs_tstz epis_info.dt_first_obs_tstz%TYPE;
    
        CURSOR c_info IS
            SELECT /*+ OPT_PARAM('_OPTIMIZER_USE_FEEDBACK' 'FALSE') */
             i_episode_t.id_episode,
             i_episode_t.id_patient,
             i_episode_t.id_epis_type,
             ei.id_triage_color,
             i_episode_t.id_fast_track,
             ei.id_room,
             ei.id_bed,
             i_episode_t.dt_begin_tstz dt_begin,
             diet.id_diet,
             nvl2(diet.id_diet, 'DIET.CODE_DIET.' || diet.id_diet, diet.desc_diet) desc_diet,
             ei.id_professional id_prof_resp,
             ei.id_first_nurse_resp,
             --
             /* ANALYSIS */
             pk_ea_logic_tracking_board.count_not_nulls(table_varchar(analysis.lab_pend,
                                                                      analysis.lab_req,
                                                                      analysis.lab_harv,
                                                                      analysis.lab_transp,
                                                                      analysis.lab_fin,
                                                                      analysis.lab_result,
                                                                      analysis.lab_result_read,
                                                                      analysis.lab_ext,
                                                                      analysis.lab_cc,
                                                                      analysis.lab_sos)) lab_count,
             analysis.lab_pend,
             analysis.lab_req,
             analysis.lab_harv,
             analysis.lab_transp,
             analysis.lab_fin,
             analysis.lab_result,
             analysis.lab_result_read,
             --
             /* EXAMS */
             pk_ea_logic_tracking_board.count_not_nulls(table_varchar(exam.exam_pend,
                                                                      exam.exam_req,
                                                                      exam.exam_transp,
                                                                      exam.exam_exec,
                                                                      exam.exam_result,
                                                                      exam.exam_result_read,
                                                                      exam.exam_ext,
                                                                      exam.exam_perf,
                                                                      exam.exam_sos)) exam_count,
             exam.exam_pend,
             exam.exam_req,
             exam.exam_transp,
             exam.exam_exec,
             exam.exam_result,
             exam.exam_result_read,
             --
             0,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             0,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             --
             /* MOVEMENTS */
             count_not_nulls(table_varchar(transp.transp_delay, transp.transp_ongoing)) transp_count,
             to_char(transp.transp_delay, pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
             
             to_char(transp.transp_ongoing, pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
             --
             0,
             NULL,
             NULL,
             NULL,
             current_timestamp dt_dg_last_update,
             NULL create_user,
             CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) create_time,
             NULL create_institution,
             NULL update_user,
             NULL update_time,
             NULL update_institution,
             analysis.lab_ext,
             exam.exam_ext,
             exam.exam_perf,
             exam.exam_wtg,
             analysis.lab_wtg,
             -- "NULL" if 1st observation date is filled in, will keep the previous value in "flg_has_stripes".
             nvl2(ei.dt_first_obs_tstz, NULL, pk_alert_constant.g_yes) flg_has_stripes,
             analysis.lab_cc,
             analysis.lab_sos,
             exam.exam_sos,
             /* OTHER EXAMS */
             pk_ea_logic_tracking_board.count_not_nulls(table_varchar(exam.exam_pend,
                                                                      exam.exam_req,
                                                                      exam.exam_transp,
                                                                      exam.exam_exec,
                                                                      exam.exam_result,
                                                                      exam.exam_result_read,
                                                                      exam.exam_ext,
                                                                      exam.exam_perf,
                                                                      exam.exam_sos)) oth_exam_count,
             exam.exam_pend,
             exam.exam_req,
             exam.exam_transp,
             exam.exam_exec,
             exam.exam_result,
             exam.exam_result_read,
             exam.exam_ext,
             exam.exam_perf,
             exam.exam_wtg,
             exam.exam_sos,
             opinion.opinion_count,
             opinion.opinion_state
              FROM epis_info ei
              LEFT JOIN (SELECT ed.id_episode, ed.id_diet, ed.desc_diet
                           FROM epis_diet ed
                          WHERE ed.flg_status = 'R') diet
                ON ei.id_episode = diet.id_episode
            --
            /* EXAMS */
              LEFT JOIN v_ea_logic_trk_brd_exam exam
                ON exam.id_episode = ei.id_episode
            --
            /* ANALYSIS */
              LEFT JOIN v_ea_logic_trk_board_analy analysis
                ON analysis.id_episode = ei.id_episode
            --                
            /* OPINION */
              LEFT JOIN (SELECT COUNT(opinion_count) opinion_count,
                                id_episode,
                                substr(concatenate(state || ';'), 1, length(concatenate(state || ';')) - 1) opinion_state
                           FROM (SELECT o.id_episode id_episode,
                                        
                                        1 opinion_count,
                                        CASE
                                             WHEN o.flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_req_read) THEN
                                              '|' || nvl(pk_date_utils.date_send_tsz(i_lang, o.dt_problem_tstz, i_prof),
                                                         'xxxxxxxxxxxxxx') || '|' || pk_alert_constant.g_display_type_date || '|' ||
                                              pk_alert_constant.g_color_red || '|' || NULL
                                             ELSE
                                              '|' || '' || '|' || pk_alert_constant.g_display_type_icon || '|' ||
                                              pk_alert_constant.g_color_none || '|' || 'ConsultRepliedIcon'
                                         END state
                                   FROM opinion o
                                  WHERE o.id_episode = i_episode_t.id_episode
                                    AND o.flg_state <> pk_opinion.g_opinion_cancel
                                    AND o.id_opinion_type IS NULL)
                          GROUP BY id_episode) opinion
                ON opinion.id_episode = ei.id_episode
            /* MOVEMENTS */
              LEFT JOIN (SELECT mov.id_episode,
                                MIN(decode(mov.flg_status,
                                           pk_alert_constant.g_mov_status_transp,
                                           mov.dt_begin_tstz,
                                           NULL)) transp_ongoing,
                                MIN(decode(mov.flg_status,
                                           pk_alert_constant.g_mov_status_req,
                                           mov.dt_req_tstz,
                                           pk_alert_constant.g_mov_status_pend,
                                           mov.dt_req_tstz,
                                           NULL)) transp_delay
                           FROM movement mov
                          WHERE mov.id_episode = i_episode_t.id_episode
                          GROUP BY mov.id_episode) transp
                ON transp.id_episode = ei.id_episode
             WHERE i_episode_t.id_episode = ei.id_episode;
    
        l_continue BOOLEAN := TRUE;
    BEGIN
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Selecting info', g_package_name, l_func_proc_name);
    
        DELETE FROM tbl_temp;
        insert_tbl_temp(i_num_1 => table_number(i_episode_t.id_episode));
    
        OPEN c_info;
        FETCH c_info
            INTO l_tracking_board_ea_r;
        IF c_info%NOTFOUND
        THEN
            l_continue := FALSE;
        END IF;
        CLOSE c_info;
    
        IF NOT l_continue
        THEN
            RETURN;
        END IF;
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Updating', g_package_name, l_func_proc_name);
        ts_tracking_board_ea.upd(id_episode_in         => l_tracking_board_ea_r.id_episode,
                                 id_patient_in         => l_tracking_board_ea_r.id_patient,
                                 id_epis_type_in       => l_tracking_board_ea_r.id_epis_type,
                                 id_triage_color_in    => l_tracking_board_ea_r.id_triage_color,
                                 id_fast_track_in      => l_tracking_board_ea_r.id_fast_track,
                                 id_room_in            => l_tracking_board_ea_r.id_room,
                                 id_bed_in             => l_tracking_board_ea_r.id_bed,
                                 dt_begin_in           => l_tracking_board_ea_r.dt_begin,
                                 id_diet_in            => l_tracking_board_ea_r.id_diet,
                                 desc_diet_in          => l_tracking_board_ea_r.desc_diet,
                                 id_prof_resp_in       => l_tracking_board_ea_r.id_prof_resp,
                                 id_nurse_resp_in      => l_tracking_board_ea_r.id_nurse_resp,
                                 lab_count_in          => l_tracking_board_ea_r.lab_count,
                                 lab_pend_in           => l_tracking_board_ea_r.lab_pend,
                                 lab_req_in            => l_tracking_board_ea_r.lab_req,
                                 lab_harv_in           => l_tracking_board_ea_r.lab_harv,
                                 lab_transp_in         => l_tracking_board_ea_r.lab_transp,
                                 lab_exec_in           => l_tracking_board_ea_r.lab_exec,
                                 lab_result_in         => l_tracking_board_ea_r.lab_result,
                                 lab_result_read_in    => l_tracking_board_ea_r.lab_result_read,
                                 lab_ext_in            => l_tracking_board_ea_r.lab_ext,
                                 exam_count_in         => l_tracking_board_ea_r.exam_count,
                                 exam_pend_in          => l_tracking_board_ea_r.exam_pend,
                                 exam_req_in           => l_tracking_board_ea_r.exam_req,
                                 exam_transp_in        => l_tracking_board_ea_r.exam_transp,
                                 exam_exec_in          => l_tracking_board_ea_r.exam_exec,
                                 exam_result_in        => l_tracking_board_ea_r.exam_result,
                                 exam_result_read_in   => l_tracking_board_ea_r.exam_result_read,
                                 exam_ext_in           => l_tracking_board_ea_r.exam_ext,
                                 interv_count_in       => l_tracking_board_ea_r.interv_count,
                                 interv_pend_in        => l_tracking_board_ea_r.interv_pend,
                                 interv_sos_in         => l_tracking_board_ea_r.interv_sos,
                                 interv_req_in         => l_tracking_board_ea_r.interv_req,
                                 interv_exec_in        => l_tracking_board_ea_r.interv_exec,
                                 interv_finish_in      => l_tracking_board_ea_r.interv_finish,
                                 med_count_in          => l_tracking_board_ea_r.med_count,
                                 med_pend_in           => l_tracking_board_ea_r.med_pend,
                                 med_req_in            => l_tracking_board_ea_r.med_req,
                                 med_exec_in           => l_tracking_board_ea_r.med_exec,
                                 med_finish_in         => l_tracking_board_ea_r.med_finish,
                                 med_sos_in            => l_tracking_board_ea_r.med_sos,
                                 transp_count_in       => l_tracking_board_ea_r.transp_count,
                                 transp_delay_in       => l_tracking_board_ea_r.transp_delay,
                                 transp_ongoing_in     => l_tracking_board_ea_r.transp_ongoing,
                                 monit_count_in        => l_tracking_board_ea_r.monit_count,
                                 monit_delay_in        => l_tracking_board_ea_r.monit_delay,
                                 monit_ongoing_in      => l_tracking_board_ea_r.monit_ongoing,
                                 monit_finish_in       => l_tracking_board_ea_r.monit_finish,
                                 dt_dg_last_update_in  => l_tracking_board_ea_r.dt_dg_last_update,
                                 exam_wtg_in           => l_tracking_board_ea_r.exam_wtg,
                                 lab_wtg_in            => l_tracking_board_ea_r.lab_wtg,
                                 flg_has_stripes_in    => l_tracking_board_ea_r.flg_has_stripes,
                                 lab_cc_in             => l_tracking_board_ea_r.lab_cc,
                                 lab_sos_in            => l_tracking_board_ea_r.lab_sos,
                                 exam_sos_in           => l_tracking_board_ea_r.exam_sos,
                                 id_fast_track_nin     => FALSE,
                                 id_bed_nin            => FALSE,
                                 id_diet_nin           => FALSE,
                                 desc_diet_nin         => FALSE,
                                 id_prof_resp_nin      => FALSE,
                                 id_nurse_resp_nin     => FALSE,
                                 lab_count_nin         => FALSE,
                                 lab_pend_nin          => FALSE,
                                 lab_req_nin           => FALSE,
                                 lab_harv_nin          => FALSE,
                                 lab_transp_nin        => FALSE,
                                 lab_exec_nin          => FALSE,
                                 lab_result_nin        => FALSE,
                                 lab_result_read_nin   => FALSE,
                                 lab_ext_nin           => FALSE,
                                 exam_count_nin        => FALSE,
                                 exam_pend_nin         => FALSE,
                                 exam_req_nin          => FALSE,
                                 exam_transp_nin       => FALSE,
                                 exam_exec_nin         => FALSE,
                                 exam_result_nin       => FALSE,
                                 exam_result_read_nin  => FALSE,
                                 exam_ext_nin          => FALSE,
                                 interv_count_nin      => FALSE,
                                 interv_pend_nin       => FALSE,
                                 interv_sos_nin        => FALSE,
                                 interv_req_nin        => FALSE,
                                 interv_exec_nin       => FALSE,
                                 interv_finish_nin     => FALSE,
                                 med_count_nin         => FALSE,
                                 med_pend_nin          => FALSE,
                                 med_req_nin           => FALSE,
                                 med_exec_nin          => FALSE,
                                 med_finish_nin        => FALSE,
                                 med_sos_nin           => FALSE,
                                 transp_count_nin      => FALSE,
                                 transp_delay_nin      => FALSE,
                                 transp_ongoing_nin    => FALSE,
                                 monit_count_nin       => FALSE,
                                 monit_delay_nin       => FALSE,
                                 monit_ongoing_nin     => FALSE,
                                 monit_finish_nin      => FALSE,
                                 dt_dg_last_update_nin => FALSE,
                                 exam_wtg_nin          => FALSE,
                                 lab_wtg_nin           => FALSE,
                                 flg_has_stripes_nin   => TRUE,
                                 lab_cc_nin            => FALSE,
                                 lab_sos_nin           => FALSE,
                                 exam_sos_nin          => FALSE,
                                 rows_out              => l_rows);
    
        IF (NOT l_rows.exists(1))
           OR (l_rows.count = 0)
        THEN
        
            BEGIN
                pk_alertlog.log_debug('TRACKING_BOARD_EA: Check 1st obs date', g_package_name, l_func_proc_name);
                SELECT ei.dt_first_obs_tstz
                  INTO l_dt_first_obs_tstz
                  FROM epis_info ei
                 WHERE ei.id_episode = l_tracking_board_ea_r.id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    l_dt_first_obs_tstz := NULL;
            END;
        
            pk_alertlog.log_debug('TRACKING_BOARD_EA: Inserting', g_package_name, l_func_proc_name);
            ts_tracking_board_ea.ins(id_episode_in        => l_tracking_board_ea_r.id_episode,
                                     id_patient_in        => l_tracking_board_ea_r.id_patient,
                                     id_epis_type_in      => l_tracking_board_ea_r.id_epis_type,
                                     id_triage_color_in   => l_tracking_board_ea_r.id_triage_color,
                                     id_fast_track_in     => l_tracking_board_ea_r.id_fast_track,
                                     id_room_in           => l_tracking_board_ea_r.id_room,
                                     id_bed_in            => l_tracking_board_ea_r.id_bed,
                                     dt_begin_in          => l_tracking_board_ea_r.dt_begin,
                                     id_diet_in           => l_tracking_board_ea_r.id_diet,
                                     desc_diet_in         => l_tracking_board_ea_r.desc_diet,
                                     id_prof_resp_in      => l_tracking_board_ea_r.id_prof_resp,
                                     id_nurse_resp_in     => l_tracking_board_ea_r.id_nurse_resp,
                                     lab_count_in         => l_tracking_board_ea_r.lab_count,
                                     lab_pend_in          => l_tracking_board_ea_r.lab_pend,
                                     lab_req_in           => l_tracking_board_ea_r.lab_req,
                                     lab_harv_in          => l_tracking_board_ea_r.lab_harv,
                                     lab_transp_in        => l_tracking_board_ea_r.lab_transp,
                                     lab_exec_in          => l_tracking_board_ea_r.lab_exec,
                                     lab_result_in        => l_tracking_board_ea_r.lab_result,
                                     lab_result_read_in   => l_tracking_board_ea_r.lab_result_read,
                                     lab_ext_in           => l_tracking_board_ea_r.lab_ext,
                                     exam_count_in        => l_tracking_board_ea_r.exam_count,
                                     exam_pend_in         => l_tracking_board_ea_r.exam_pend,
                                     exam_req_in          => l_tracking_board_ea_r.exam_req,
                                     exam_transp_in       => l_tracking_board_ea_r.exam_transp,
                                     exam_exec_in         => l_tracking_board_ea_r.exam_exec,
                                     exam_result_in       => l_tracking_board_ea_r.exam_result,
                                     exam_result_read_in  => l_tracking_board_ea_r.exam_result_read,
                                     exam_ext_in          => l_tracking_board_ea_r.exam_ext,
                                     interv_count_in      => l_tracking_board_ea_r.interv_count,
                                     interv_pend_in       => l_tracking_board_ea_r.interv_pend,
                                     interv_sos_in        => l_tracking_board_ea_r.interv_sos,
                                     interv_req_in        => l_tracking_board_ea_r.interv_req,
                                     interv_exec_in       => l_tracking_board_ea_r.interv_exec,
                                     interv_finish_in     => l_tracking_board_ea_r.interv_finish,
                                     med_count_in         => l_tracking_board_ea_r.med_count,
                                     med_pend_in          => l_tracking_board_ea_r.med_pend,
                                     med_req_in           => l_tracking_board_ea_r.med_req,
                                     med_exec_in          => l_tracking_board_ea_r.med_exec,
                                     med_finish_in        => l_tracking_board_ea_r.med_finish,
                                     med_sos_in           => l_tracking_board_ea_r.med_sos,
                                     transp_count_in      => l_tracking_board_ea_r.transp_count,
                                     transp_delay_in      => l_tracking_board_ea_r.transp_delay,
                                     transp_ongoing_in    => l_tracking_board_ea_r.transp_ongoing,
                                     monit_count_in       => l_tracking_board_ea_r.monit_count,
                                     monit_delay_in       => l_tracking_board_ea_r.monit_delay,
                                     monit_ongoing_in     => l_tracking_board_ea_r.monit_ongoing,
                                     monit_finish_in      => l_tracking_board_ea_r.monit_finish,
                                     dt_dg_last_update_in => l_tracking_board_ea_r.dt_dg_last_update,
                                     exam_wtg_in          => l_tracking_board_ea_r.exam_wtg,
                                     lab_wtg_in           => l_tracking_board_ea_r.lab_wtg,
                                     flg_has_stripes_in   => CASE l_dt_first_obs_tstz
                                                                 WHEN NULL THEN
                                                                  pk_alert_constant.g_yes
                                                                 ELSE
                                                                  pk_alert_constant.g_no
                                                             END,
                                     lab_cc_in            => l_tracking_board_ea_r.lab_cc,
                                     lab_sos_in           => l_tracking_board_ea_r.lab_sos,
                                     exam_sos_in          => l_tracking_board_ea_r.exam_sos);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END insert_ea_logic_all;

    /**
    * Updated the exam related fields in the TRACKING_BOARD_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_id_episode_list    List of episodes.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/20
    */
    PROCEDURE update_ea_logic_exam
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN table_varchar,
        i_id_episode_list IN table_number
    ) IS
        l_func_proc_name         VARCHAR2(30) := 'UPDATE_EA_LOGIC_EXAM';
        l_tracking_board_ea_list ts_tracking_board_ea.tracking_board_ea_tc;
        e_exception              EXCEPTION;
        l_error                  t_error_out;
    
        CURSOR c_info IS
            SELECT ea.id_episode,
                   ea.id_patient,
                   ea.id_epis_type,
                   ea.id_triage_color,
                   ea.id_fast_track,
                   ea.id_room,
                   ea.id_bed,
                   ea.dt_begin,
                   ea.id_diet,
                   ea.desc_diet,
                   ea.id_prof_resp,
                   ea.id_nurse_resp,
                   ea.lab_count,
                   ea.lab_pend,
                   ea.lab_req,
                   ea.lab_harv,
                   ea.lab_transp,
                   ea.lab_exec,
                   ea.lab_result,
                   ea.lab_result_read,
                   decode(t.flg_type,
                          pk_exam_constant.g_type_img,
                          pk_ea_logic_tracking_board.count_not_nulls(table_varchar(t.exam_pend,
                                                                                   t.exam_req,
                                                                                   t.exam_transp,
                                                                                   t.exam_exec,
                                                                                   t.exam_result,
                                                                                   t.exam_result_read,
                                                                                   t.exam_ext,
                                                                                   t.exam_perf,
                                                                                   t.exam_sos)),
                          ea.exam_count) exam_count,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_pend, ea.exam_pend) exam_pend,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_req, ea.exam_req) exam_req,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_transp, ea.exam_transp) exam_transp,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_exec, ea.exam_exec) exam_exec,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_result, ea.exam_result) exam_result,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_result_read, ea.exam_result_read) exam_result_read,
                   ea.interv_count,
                   ea.interv_pend,
                   ea.interv_sos,
                   ea.interv_req,
                   ea.interv_exec,
                   ea.interv_finish,
                   ea.med_count,
                   ea.med_pend,
                   ea.med_req,
                   ea.med_exec,
                   ea.med_finish,
                   ea.med_sos,
                   ea.transp_count,
                   ea.transp_delay,
                   ea.transp_ongoing,
                   ea.monit_count,
                   ea.monit_delay,
                   ea.monit_ongoing,
                   ea.monit_finish,
                   current_timestamp dt_dg_last_update,
                   ea.create_user,
                   ea.create_time,
                   ea.create_institution,
                   NULL update_user,
                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) update_time,
                   NULL update_institution,
                   ea.lab_ext,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_ext, ea.exam_ext) exam_ext,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_perf, ea.exam_perf) exam_perf,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_wtg, ea.exam_wtg) exam_wtg,
                   ea.lab_wtg,
                   ea.flg_has_stripes, -- Keep same value
                   ea.lab_cc,
                   ea.lab_sos,
                   decode(t.flg_type, pk_exam_constant.g_type_img, t.exam_sos, ea.exam_sos) exam_sos,
                   decode(t.flg_type,
                          pk_exam_constant.g_type_exm,
                          pk_ea_logic_tracking_board.count_not_nulls(table_varchar(t.exam_pend,
                                                                                   t.exam_req,
                                                                                   t.exam_transp,
                                                                                   t.exam_exec,
                                                                                   t.exam_result,
                                                                                   t.exam_result_read,
                                                                                   t.exam_ext,
                                                                                   t.exam_perf,
                                                                                   t.exam_sos)),
                          ea.oth_exam_count) oth_exam_count,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_pend, ea.oth_exam_pend) oth_exam_pend,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_req, ea.oth_exam_req) oth_exam_req,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_transp, ea.oth_exam_transp) oth_exam_transp,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_exec, ea.oth_exam_exec) oth_exam_exec,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_result, ea.oth_exam_result) oth_exam_result,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_result_read, ea.oth_exam_result_read) oth_exam_result_read,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_ext, ea.oth_exam_ext) oth_exam_ext,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_perf, ea.oth_exam_perf) oth_exam_perf,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_wtg, ea.oth_exam_wtg) oth_exam_wtg,
                   decode(t.flg_type, pk_exam_constant.g_type_exm, t.exam_sos, ea.oth_exam_sos) oth_exam_sos,
                   ea.opinion_count,
                   ea.opinion_state
              FROM tracking_board_ea ea
              JOIN v_ea_logic_trk_brd_exam_type t
                ON t.id_episode = ea.id_episode;
    
    BEGIN
        IF i_id_episode_list IS NULL
           OR i_id_episode_list.count = 0
        THEN
            RETURN;
        END IF;
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Selecting info', g_package_name, l_func_proc_name);
    
        -- inserting episodes on tbl_temp
        DELETE FROM tbl_temp;
        insert_tbl_temp(i_num_1 => i_id_episode_list, i_vc_1 => i_flg_type);
    
        OPEN c_info;
        FETCH c_info BULK COLLECT
            INTO l_tracking_board_ea_list;
        CLOSE c_info;
    
        IF l_tracking_board_ea_list IS NOT NULL
           AND l_tracking_board_ea_list.count > 0
        THEN
            pk_alertlog.log_debug('TRACKING_BOARD_EA: Updating', g_package_name, l_func_proc_name);
            IF NOT update_on_tracking_board_ea(i_lang                  => i_lang,
                                               i_tracking_board_ea_rec => l_tracking_board_ea_list,
                                               o_error                 => l_error)
            THEN
                RAISE e_exception;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END update_ea_logic_exam;

    /**
    * Inserts or Updates Exams related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Fábio Oliveira
    * @version 2.4.3-Denormalized
    * @since 2008/10/17
    */
    PROCEDURE set_exam
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name  VARCHAR2(30);
        l_id_episode_list table_number;
        l_flg_type        table_varchar;
    BEGIN
        l_func_proc_name := 'SET_EXAMS';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        g_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TRACKING_BOARD_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
        /* Tratamento da EXAM_REQ_DET */
        IF upper(i_source_table_name) = 'EXAM_REQ_DET'
        THEN
            -- Process event
            pk_alertlog.log_debug('EXAM_REQ_DET: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            /*  Gets flg_type of the exam ('I' - image, 'E' - Other exam)*/
            SELECT /*+RULE*/
            DISTINCT e.flg_type
              BULK COLLECT
              INTO l_flg_type
              FROM exam_req_det erd, exam e
             WHERE erd.rowid IN (SELECT *
                                   FROM TABLE(i_rowids))
               AND erd.id_exam = e.id_exam;
        
            /* Se for INSERT verifico se diz respeito a um exame dos tipos que me interessa registar */
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                SELECT /*+RULE*/
                DISTINCT er.id_episode
                  BULK COLLECT
                  INTO l_id_episode_list
                  FROM exam_req_det erd, exam_req er
                 WHERE erd.rowid IN (SELECT *
                                       FROM TABLE(i_rowids))
                   AND er.id_exam_req = erd.id_exam_req
                   AND er.flg_time = pk_alert_constant.g_flg_time_e;
            ELSIF i_event_type != t_data_gov_mnt.g_event_delete
            THEN
                /* Senão então pode dizer respeito a qualquer tipo de exame */
                /* Poderiamos obter o tipo antigo do exame mas isso iria requerer uma query mais pesada */
                SELECT /*+RULE*/
                DISTINCT er.id_episode
                  BULK COLLECT
                  INTO l_id_episode_list
                  FROM exam_req_det erd, exam_req er
                 WHERE erd.rowid IN (SELECT *
                                       FROM TABLE(i_rowids))
                   AND er.id_exam_req = erd.id_exam_req;
            END IF;
        
            /* Só me interessa verificar os updates da EXAM_REQ */
        ELSIF upper(i_source_table_name) = 'EXAM_REQ'
              AND i_event_type = t_data_gov_mnt.g_event_update
        THEN
            pk_alertlog.log_debug('EXAM_REQ: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            /*  Gets flg_type of the exam ('I' - image, 'E' - Other exam)*/
            SELECT /*+RULE*/
            DISTINCT e.flg_type
              BULK COLLECT
              INTO l_flg_type
              FROM exam_req er, exam_req_det erd, exam e
             WHERE er.rowid IN (SELECT *
                                  FROM TABLE(i_rowids))
               AND erd.id_exam_req = er.id_exam_req
               AND erd.id_exam = e.id_exam;
        
            SELECT /*+RULE*/
            DISTINCT id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM exam_req
             WHERE ROWID IN (SELECT *
                               FROM TABLE(i_rowids));
        
            /* Só actualizo os exam_result que pertencerem a exames válidos */
        ELSIF upper(i_source_table_name) = 'EXAM_RESULT'
              AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('EXAM_RESULT: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
            DISTINCT er.id_episode, e.flg_type
              BULK COLLECT
              INTO l_id_episode_list, l_flg_type
              FROM exam_result ere, exam_req_det erd, exam_req er, exam e
             WHERE ere.rowid IN (SELECT *
                                   FROM TABLE(i_rowids))
               AND ere.id_exam_req_det = erd.id_exam_req_det
               AND erd.flg_status IN (pk_alert_constant.g_exam_det_result, pk_alert_constant.g_exam_det_read)
               AND er.flg_time = pk_alert_constant.g_flg_time_e
               AND erd.id_exam_req = er.id_exam_req
               AND e.id_exam = erd.id_exam;
        
            /* Só actualizo os ti_log que apontarem para exames válidos para o tracking board */
        ELSIF upper(i_source_table_name) = 'TI_LOG'
              AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('TI_LOG: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
            DISTINCT er.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM ti_log tl, exam_req_det erd, exam_req er
             WHERE tl.flg_type = pk_alert_constant.g_exam_type_det
               AND tl.id_record = erd.id_exam_req_det
               AND tl.rowid IN (SELECT *
                                  FROM TABLE(i_rowids))
               AND erd.flg_status = pk_alert_constant.g_exam_det_exec
               AND er.id_exam_req = erd.id_exam_req
               AND er.flg_time = pk_alert_constant.g_flg_time_e;
        ELSE
            RETURN;
        END IF;
    
        update_ea_logic_exam(i_lang, i_prof, l_flg_type, l_id_episode_list);
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_exam;

    PROCEDURE set_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name VARCHAR2(30);
    
        l_episode_tc      ts_episode.episode_tc;
        l_id_episode_list table_number;
    
    BEGIN
        l_func_proc_name := 'SET_EXAMS';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        g_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TRACKING_BOARD_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
        /* Tratamento da EPISODE */
        IF upper(i_source_table_name) = 'EPISODE'
        THEN
            pk_alertlog.log_debug('EPISODE: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            IF i_event_type != t_data_gov_mnt.g_event_delete
            THEN
                --l_episode_tc := ts_episode.get_data_rowid(i_rowids);
            
                SELECT /*+RULE*/
                 *
                  BULK COLLECT
                  INTO l_episode_tc
                  FROM episode epis
                 WHERE ROWID IN (SELECT column_value
                                   FROM TABLE(i_rowids))
                   AND epis.flg_status = 'A'
                   AND epis.flg_ehr = 'N'
                   AND epis.id_epis_type IN
                       (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient);
            
                IF l_episode_tc.exists(1)
                   AND l_episode_tc.count > 0
                THEN
                    FOR i IN l_episode_tc.first .. l_episode_tc.last
                    LOOP
                        insert_ea_logic_all(i_lang, i_prof, l_episode_tc(i));
                    END LOOP;
                END IF;
            
                l_episode_tc.delete;
            
                SELECT /*+RULE*/
                 epis.*
                  BULK COLLECT
                  INTO l_episode_tc
                  FROM episode epis
                  JOIN tracking_board_ea tbea
                    ON (epis.id_episode = tbea.id_episode)
                 WHERE epis.rowid IN (SELECT column_value
                                        FROM TABLE(i_rowids))
                   AND (epis.flg_status != 'A' OR epis.flg_ehr != 'N' OR
                       epis.id_epis_type NOT IN
                       (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient));
            
                IF l_episode_tc.exists(1)
                   AND l_episode_tc.count > 0
                THEN
                    FOR i IN l_episode_tc.first .. l_episode_tc.last
                    LOOP
                        ts_tracking_board_ea.del_id_episode(id_episode_in => l_episode_tc(i).id_episode);
                    END LOOP;
                END IF;
            
                /*IF l_episode_tc.COUNT > 0
                THEN
                    FOR i IN l_episode_tc.FIRST .. l_episode_tc.LAST
                    LOOP
                        IF l_episode_tc(i).flg_status = 'A'
                           AND l_episode_tc(i).flg_ehr = 'N'
                           AND l_episode_tc(i)
                        .id_epis_type IN
                           (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
                        THEN
                            --upd_ins
                            insert_ea_logic_all(i_lang, i_prof, l_episode_tc(i));
                        ELSE
                            --del
                            ts_tracking_board_ea.del_id_episode(id_episode_in => l_episode_tc(i).id_episode);
                        END IF;
                    END LOOP;
                END IF;*/
            ELSE
                l_episode_tc := ts_episode.get_data_rowid_pat(i_rowids);
                IF l_episode_tc.count > 0
                THEN
                    FOR i IN l_episode_tc.first .. l_episode_tc.last
                    LOOP
                        ts_tracking_board_ea.del_id_episode(id_episode_in => l_episode_tc(i).id_episode);
                    END LOOP;
                END IF;
            END IF;
        ELSIF upper(i_source_table_name) = 'EPIS_INFO'
              AND i_event_type = t_data_gov_mnt.g_event_insert
        THEN
            pk_alertlog.log_debug('EPIS_INFO: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
             epis.*
              BULK COLLECT
              INTO l_episode_tc
              FROM epis_info ei, episode epis
             WHERE ei.rowid IN (SELECT *
                                  FROM TABLE(i_rowids))
               AND ei.id_episode = epis.id_episode
               AND epis.flg_ehr = 'N'
               AND epis.flg_status = 'A'
               AND epis.id_epis_type IN
                   (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient);
        
            IF l_episode_tc.count > 0
            THEN
                FOR i IN l_episode_tc.first .. l_episode_tc.last
                LOOP
                    IF l_episode_tc(i).flg_status = 'A'
                        AND l_episode_tc(i).flg_ehr = 'N'
                        AND l_episode_tc(i)
                       .id_epis_type IN
                        (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
                    THEN
                        --upd_ins
                        insert_ea_logic_all(i_lang, i_prof, l_episode_tc(i));
                    ELSE
                        --del
                        ts_tracking_board_ea.del_id_episode(id_episode_in => l_episode_tc(i).id_episode);
                    END IF;
                END LOOP;
            END IF;
        ELSIF upper(i_source_table_name) = 'EPIS_DIET'
              AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('EPIS_DIET: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
             ed.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM epis_diet ed
             WHERE ed.rowid IN (SELECT *
                                  FROM TABLE(i_rowids));
        
            update_ea_logic_info(i_lang, i_prof, l_id_episode_list);
        ELSIF upper(i_source_table_name) = 'EPIS_INFO'
              AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('EPIS_INFO: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
             ei.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM epis_info ei
             WHERE ei.rowid IN (SELECT *
                                  FROM TABLE(i_rowids));
        
            update_ea_logic_info(i_lang, i_prof, l_id_episode_list);
        END IF;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
        
            pk_utils.undo_changes();
    END set_episode;

    /**
    * Updated the analysis related fields in the TRACKING_BOARD_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_id_episode_list    List of episodes.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/20
    */
    PROCEDURE update_ea_logic_analysis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode_list table_number
    ) IS
        l_func_proc_name         VARCHAR2(30) := 'UPDATE_EA_LOGIC_ANALYSIS';
        l_tracking_board_ea_list ts_tracking_board_ea.tracking_board_ea_tc;
        e_exception              EXCEPTION;
        l_error                  t_error_out;
    
        CURSOR c_info IS
            SELECT ea.id_episode,
                   ea.id_patient,
                   ea.id_epis_type,
                   ea.id_triage_color,
                   ea.id_fast_track,
                   ea.id_room,
                   ea.id_bed,
                   ea.dt_begin,
                   ea.id_diet,
                   ea.desc_diet,
                   ea.id_prof_resp,
                   ea.id_nurse_resp,
                   pk_ea_logic_tracking_board.count_not_nulls(table_varchar(t.lab_pend,
                                                                            t.lab_req,
                                                                            t.lab_harv,
                                                                            t.lab_transp,
                                                                            t.lab_fin,
                                                                            t.lab_result,
                                                                            t.lab_result_read,
                                                                            t.lab_ext,
                                                                            t.lab_cc,
                                                                            t.lab_sos)) lab_count,
                   t.lab_pend,
                   t.lab_req,
                   t.lab_harv,
                   t.lab_transp,
                   t.lab_fin,
                   t.lab_result,
                   t.lab_result_read,
                   ea.exam_count,
                   ea.exam_pend,
                   ea.exam_req,
                   ea.exam_transp,
                   ea.exam_exec,
                   ea.exam_result,
                   ea.exam_result_read,
                   ea.interv_count,
                   ea.interv_pend,
                   ea.interv_sos,
                   ea.interv_req,
                   ea.interv_exec,
                   ea.interv_finish,
                   ea.med_count,
                   ea.med_pend,
                   ea.med_req,
                   ea.med_exec,
                   ea.med_finish,
                   ea.med_sos,
                   ea.transp_count,
                   ea.transp_delay,
                   ea.transp_ongoing,
                   ea.monit_count,
                   ea.monit_delay,
                   ea.monit_ongoing,
                   ea.monit_finish,
                   current_timestamp dt_dg_last_update,
                   ea.create_user,
                   ea.create_time,
                   ea.create_institution,
                   NULL update_user,
                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) update_time,
                   NULL update_institution,
                   t.lab_ext,
                   ea.exam_ext,
                   ea.exam_perf,
                   ea.exam_wtg,
                   t.lab_wtg,
                   ea.flg_has_stripes, -- Keep same value
                   t.lab_cc,
                   t.lab_sos,
                   ea.exam_sos,
                   ea.oth_exam_count,
                   ea.oth_exam_pend,
                   ea.oth_exam_req,
                   ea.oth_exam_transp,
                   ea.oth_exam_exec,
                   ea.oth_exam_result,
                   ea.oth_exam_result_read,
                   ea.oth_exam_ext,
                   ea.oth_exam_perf,
                   ea.oth_exam_wtg,
                   ea.oth_exam_sos,
                   ea.opinion_count,
                   ea.opinion_state
              FROM tracking_board_ea ea
              JOIN v_ea_logic_trk_brd_analy t
                ON t.id_episode = ea.id_episode;
    BEGIN
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Selecting info', g_package_name, l_func_proc_name);
    
        IF i_id_episode_list IS NULL
           OR i_id_episode_list.count = 0
        THEN
            RETURN;
        END IF;
    
        -- inserting episodes on tbl_temp
        DELETE FROM tbl_temp;
        insert_tbl_temp(i_num_1 => i_id_episode_list);
    
        OPEN c_info;
        FETCH c_info BULK COLLECT
            INTO l_tracking_board_ea_list;
        CLOSE c_info;
    
        IF l_tracking_board_ea_list IS NOT NULL
           AND l_tracking_board_ea_list.count > 0
        THEN
            IF NOT update_on_tracking_board_ea(i_lang                  => i_lang,
                                               i_tracking_board_ea_rec => l_tracking_board_ea_list,
                                               o_error                 => l_error)
            THEN
                RAISE e_exception;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END update_ea_logic_analysis;

    /**
    * Updated the transport related fields in the TRACKING_BOARD_EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_id_episode_list    List of episodes.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/21
    */
    PROCEDURE update_ea_logic_transport
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode_list table_number
    ) IS
        l_func_proc_name         VARCHAR2(30) := 'UPDATE_EA_LOGIC_TRANSPORT';
        l_tracking_board_ea_list ts_tracking_board_ea.tracking_board_ea_tc;
        e_exception              EXCEPTION;
        l_error                  t_error_out;
    
        CURSOR c_info IS
            SELECT ea.id_episode,
                   ea.id_patient,
                   ea.id_epis_type,
                   ea.id_triage_color,
                   ea.id_fast_track,
                   ea.id_room,
                   ea.id_bed,
                   ea.dt_begin,
                   ea.id_diet,
                   ea.desc_diet,
                   ea.id_prof_resp,
                   ea.id_nurse_resp,
                   ea.lab_count,
                   ea.lab_pend,
                   ea.lab_req,
                   ea.lab_harv,
                   ea.lab_transp,
                   ea.lab_exec,
                   ea.lab_result,
                   ea.lab_result_read,
                   ea.exam_count,
                   ea.exam_pend,
                   ea.exam_req,
                   ea.exam_transp,
                   ea.exam_exec,
                   ea.exam_result,
                   ea.exam_result_read,
                   ea.interv_count,
                   ea.interv_pend,
                   ea.interv_sos,
                   ea.interv_req,
                   ea.interv_exec,
                   ea.interv_finish,
                   ea.med_count,
                   ea.med_pend,
                   ea.med_req,
                   ea.med_exec,
                   ea.med_finish,
                   ea.med_sos,
                   count_not_nulls(table_varchar(t.transp_delay, t.transp_ongoing)) transp_count,
                   decode(t.transp_delay,
                          NULL,
                          NULL,
                          to_char(t.transp_delay, pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)),
                   
                   decode(t.transp_ongoing,
                          NULL,
                          NULL,
                          to_char(t.transp_ongoing, pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)),
                   ea.monit_count,
                   ea.monit_delay,
                   ea.monit_ongoing,
                   ea.monit_finish,
                   current_timestamp dt_dg_last_update,
                   ea.create_user,
                   ea.create_time,
                   ea.create_institution,
                   NULL update_user,
                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) update_time,
                   NULL update_institution,
                   ea.lab_ext,
                   ea.exam_ext,
                   ea.exam_perf,
                   ea.exam_wtg,
                   ea.lab_wtg,
                   ea.flg_has_stripes, -- Keep same value
                   ea.lab_cc,
                   ea.lab_sos,
                   ea.exam_sos,
                   ea.oth_exam_count,
                   ea.oth_exam_pend,
                   ea.oth_exam_req,
                   ea.oth_exam_transp,
                   ea.oth_exam_exec,
                   ea.oth_exam_result,
                   ea.oth_exam_result_read,
                   ea.oth_exam_ext,
                   ea.oth_exam_perf,
                   ea.oth_exam_wtg,
                   ea.oth_exam_sos,
                   ea.opinion_count,
                   ea.opinion_state
              FROM tracking_board_ea ea,
                   (SELECT mov.id_episode,
                           MIN(decode(mov.flg_status, pk_alert_constant.g_mov_status_transp, mov.dt_begin_tstz, NULL)) transp_ongoing,
                           MIN(decode(mov.flg_status,
                                      pk_alert_constant.g_mov_status_req,
                                      mov.dt_req_tstz,
                                      pk_alert_constant.g_mov_status_pend,
                                      mov.dt_req_tstz,
                                      NULL)) transp_delay
                      FROM movement mov
                     WHERE mov.id_episode IN (SELECT /*+opt_estimate (table a rows=1) */
                                               *
                                                FROM TABLE(i_id_episode_list) a)
                     GROUP BY mov.id_episode) t
             WHERE t.id_episode = ea.id_episode;
    BEGIN
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Selecting info', g_package_name, l_func_proc_name);
    
        IF i_id_episode_list IS NULL
           OR i_id_episode_list.count = 0
        THEN
            RETURN;
        END IF;
    
        OPEN c_info;
        FETCH c_info BULK COLLECT
            INTO l_tracking_board_ea_list;
        CLOSE c_info;
    
        IF l_tracking_board_ea_list IS NOT NULL
           AND l_tracking_board_ea_list.count > 0
        THEN
            IF NOT update_on_tracking_board_ea(i_lang                  => i_lang,
                                               i_tracking_board_ea_rec => l_tracking_board_ea_list,
                                               o_error                 => l_error)
            THEN
                RAISE e_exception;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END update_ea_logic_transport;

    /**
    * Inserts or Updates Analysis related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/17
    */
    PROCEDURE set_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name  VARCHAR2(30);
        l_id_episode_list table_number;
    BEGIN
        l_func_proc_name := 'SET_ANALYSIS';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        g_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TRACKING_BOARD_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
        IF upper(i_source_table_name) = 'ANALYSIS_REQ_DET'
           AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            -- Process event
            pk_alertlog.log_debug('ANALYSIS_REQ_DET: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
            DISTINCT ar.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM analysis_req_det ard, analysis_req ar
             WHERE ard.rowid IN (SELECT *
                                   FROM TABLE(i_rowids))
               AND ar.id_analysis_req = ard.id_analysis_req;
        ELSIF upper(i_source_table_name) = 'ANALYSIS_REQ'
              AND i_event_type = t_data_gov_mnt.g_event_update
        THEN
            pk_alertlog.log_debug('ANALYSIS_REQ: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
            DISTINCT id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM analysis_req
             WHERE ROWID IN (SELECT *
                               FROM TABLE(i_rowids));
        ELSIF upper(i_source_table_name) = 'HARVEST'
              AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('HARVEST: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
            DISTINCT id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM harvest h
             WHERE ROWID IN (SELECT *
                               FROM TABLE(i_rowids));
        ELSIF upper(i_source_table_name) = 'ANALYSIS_RESULT'
              AND i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('ANALYSIS_RESULT: Getting list of id_episode', g_package_name, l_func_proc_name);
        
            SELECT /*+RULE*/
            DISTINCT ar.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM analysis_result ares, analysis_req_det ard, analysis_req ar
             WHERE ares.rowid IN (SELECT *
                                    FROM TABLE(i_rowids))
               AND ares.id_analysis_req_det = ard.id_analysis_req_det
               AND ard.id_analysis_req = ar.id_analysis_req;
        ELSE
            RETURN;
        END IF;
        update_ea_logic_analysis(i_lang, i_prof, l_id_episode_list);
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_analysis;

    /**
    * Inserts or Updates Transport related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/21
    */
    PROCEDURE set_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name  VARCHAR2(30);
        l_id_episode_list table_number;
    BEGIN
        l_func_proc_name := 'SET_TRANSPORT';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        g_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'MOVEMENT',
                                                 i_expected_dg_table_name => 'TRACKING_BOARD_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
        -- Process event
        pk_alertlog.log_debug('MOVEMENT: Getting list of id_episode', g_package_name, l_func_proc_name);
        IF i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            SELECT /*+RULE*/
            DISTINCT m.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM movement m
             WHERE m.rowid IN (SELECT *
                                 FROM TABLE(i_rowids));
            update_ea_logic_transport(i_lang, i_prof, l_id_episode_list);
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_transport;

    /**
    * Inserts or Updates Facility Transfer related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author José Brito
    * @version 2.5.1
    * @since 17-May-2011
    */
    PROCEDURE set_transfer_institution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name VARCHAR2(30 CHAR);
    
        l_tracking_board_ea_list ts_tracking_board_ea.tracking_board_ea_tc;
    
        e_exception EXCEPTION;
        l_error     t_error_out;
    BEGIN
        l_func_proc_name := 'SET_TRANSFER_INSTITUTION';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        g_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'TRANSFER_INSTITUTION',
                                                 i_expected_dg_table_name => 'TRACKING_BOARD_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process event
        IF i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            pk_alertlog.log_debug('TRANSFER_INSTITUTION: Getting list of rows', g_package_name, l_func_proc_name);
            SELECT ea.id_episode,
                   ea.id_patient,
                   ea.id_epis_type,
                   ea.id_triage_color,
                   ea.id_fast_track,
                   ea.id_room,
                   ea.id_bed,
                   ea.dt_begin,
                   ea.id_diet,
                   ea.desc_diet,
                   ea.id_prof_resp,
                   ea.id_nurse_resp,
                   ea.lab_count,
                   ea.lab_pend,
                   ea.lab_req,
                   ea.lab_harv,
                   ea.lab_transp,
                   ea.lab_exec,
                   ea.lab_result,
                   ea.lab_result_read,
                   ea.exam_count,
                   ea.exam_pend,
                   ea.exam_req,
                   ea.exam_transp,
                   ea.exam_exec,
                   ea.exam_result,
                   ea.exam_result_read,
                   ea.interv_count,
                   ea.interv_pend,
                   ea.interv_sos,
                   ea.interv_req,
                   ea.interv_exec,
                   ea.interv_finish,
                   ea.med_count,
                   ea.med_pend,
                   ea.med_req,
                   ea.med_exec,
                   ea.med_finish,
                   ea.med_sos,
                   ea.transp_count,
                   ea.transp_delay,
                   ea.transp_ongoing,
                   ea.monit_count,
                   ea.monit_delay,
                   ea.monit_ongoing,
                   ea.monit_finish,
                   current_timestamp dt_dg_last_update,
                   ea.create_user,
                   ea.create_time,
                   ea.create_institution,
                   NULL update_user,
                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) update_time,
                   NULL update_institution,
                   ea.lab_ext,
                   ea.exam_ext,
                   ea.exam_perf,
                   ea.exam_wtg,
                   ea.lab_wtg,
                   decode(ti.flg_status, pk_transfer_institution.g_transfer_inst_fin, pk_alert_constant.g_yes, NULL) flg_has_stripes,
                   ea.lab_cc,
                   ea.lab_sos,
                   ea.exam_sos,
                   ea.oth_exam_count,
                   ea.oth_exam_pend,
                   ea.oth_exam_req,
                   ea.oth_exam_transp,
                   ea.oth_exam_exec,
                   ea.oth_exam_result,
                   ea.oth_exam_result_read,
                   ea.oth_exam_ext,
                   ea.oth_exam_perf,
                   ea.oth_exam_wtg,
                   ea.oth_exam_sos,
                   ea.opinion_count,
                   ea.opinion_state
              BULK COLLECT
              INTO l_tracking_board_ea_list
              FROM tracking_board_ea ea
              JOIN transfer_institution ti
                ON ti.id_episode = ea.id_episode
              JOIN episode epis
                ON epis.id_episode = ea.id_episode
             WHERE ti.rowid IN (SELECT column_value
                                  FROM TABLE(i_rowids))
               AND epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
               AND epis.flg_ehr != 'E';
        
            IF l_tracking_board_ea_list IS NOT NULL
               AND l_tracking_board_ea_list.count > 0
            THEN
                pk_alertlog.log_debug('TRACKING_BOARD_EA: Updating', g_package_name, l_func_proc_name);
                IF NOT update_on_tracking_board_ea(i_lang                  => i_lang,
                                                   i_tracking_board_ea_rec => l_tracking_board_ea_list,
                                                   o_error                 => l_error)
                THEN
                    RAISE e_exception;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_transfer_institution;

    /**
    * Inserts or Updates Transport related fields in the TRACKING BOARD EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Eduardo Lourenco
    * @version 2.4.3-Denormalized
    * @since 2008/10/21
    */
    PROCEDURE set_opinion
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name  VARCHAR2(30);
        l_id_episode_list table_number;
    BEGIN
        l_func_proc_name := 'SET_OPINION';
        pk_alertlog.log_info(text            => 'BEGIN: ' || i_rowids.count,
                             object_name     => g_package_name,
                             sub_object_name => l_func_proc_name);
    
        g_prof_category := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'OPINION',
                                                 i_expected_dg_table_name => 'TRACKING_BOARD_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
        -- Process event
        pk_alertlog.log_debug('MOVEMENT: Getting list of id_episode', g_package_name, l_func_proc_name);
        IF i_event_type != t_data_gov_mnt.g_event_delete
        THEN
            SELECT /*+RULE*/
            DISTINCT o.id_episode
              BULK COLLECT
              INTO l_id_episode_list
              FROM opinion o
             WHERE o.rowid IN (SELECT *
                                 FROM TABLE(i_rowids));
            update_ea_logic_opinion(i_lang, i_prof, l_id_episode_list);
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes();
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_utils.undo_changes();
    END set_opinion;

    PROCEDURE update_ea_logic_opinion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode_list table_number
    ) IS
        l_func_proc_name         VARCHAR2(30) := 'UPDATE_EA_LOGIC_OPINION';
        l_tracking_board_ea_list ts_tracking_board_ea.tracking_board_ea_tc;
        e_exception              EXCEPTION;
        l_error                  t_error_out;
    
        CURSOR c_info IS
            SELECT ea.id_episode,
                   ea.id_patient,
                   ea.id_epis_type,
                   ea.id_triage_color,
                   ea.id_fast_track,
                   ea.id_room,
                   ea.id_bed,
                   ea.dt_begin,
                   ea.id_diet,
                   ea.desc_diet,
                   ea.id_prof_resp,
                   ea.id_nurse_resp,
                   ea.lab_count,
                   ea.lab_pend,
                   ea.lab_req,
                   ea.lab_harv,
                   ea.lab_transp,
                   ea.lab_exec,
                   ea.lab_result,
                   ea.lab_result_read,
                   ea.exam_count,
                   ea.exam_pend,
                   ea.exam_req,
                   ea.exam_transp,
                   ea.exam_exec,
                   ea.exam_result,
                   ea.exam_result_read,
                   ea.interv_count,
                   ea.interv_pend,
                   ea.interv_sos,
                   ea.interv_req,
                   ea.interv_exec,
                   ea.interv_finish,
                   ea.med_count,
                   ea.med_pend,
                   ea.med_req,
                   ea.med_exec,
                   ea.med_finish,
                   ea.med_sos,
                   ea.transp_count,
                   ea.transp_delay,
                   ea.transp_ongoing,
                   ea.monit_count,
                   ea.monit_delay,
                   ea.monit_ongoing,
                   ea.monit_finish,
                   current_timestamp dt_dg_last_update,
                   ea.create_user,
                   ea.create_time,
                   ea.create_institution,
                   NULL update_user,
                   CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE) update_time,
                   NULL update_institution,
                   ea.lab_ext,
                   ea.exam_ext,
                   ea.exam_perf,
                   ea.exam_wtg,
                   ea.lab_wtg,
                   ea.flg_has_stripes, -- Keep same value
                   ea.lab_cc,
                   ea.lab_sos,
                   ea.exam_sos,
                   ea.oth_exam_count,
                   ea.oth_exam_pend,
                   ea.oth_exam_req,
                   ea.oth_exam_transp,
                   ea.oth_exam_exec,
                   ea.oth_exam_result,
                   ea.oth_exam_result_read,
                   ea.oth_exam_ext,
                   ea.oth_exam_perf,
                   ea.oth_exam_wtg,
                   ea.oth_exam_sos,
                   t.opinion_count,
                   t.opinion_state
              FROM tracking_board_ea ea
              LEFT JOIN (SELECT COUNT(opinion_count) opinion_count,
                                id_episode,
                                substr(concatenate(state || ';'), 1, length(concatenate(state || ';')) - 1) opinion_state
                           FROM (SELECT o.id_episode id_episode,
                                        1 opinion_count,
                                        CASE
                                             WHEN o.flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_req_read) THEN
                                              '|' || nvl(pk_date_utils.date_send_tsz(i_lang, o.dt_problem_tstz, i_prof),
                                                         'xxxxxxxxxxxxxx') || '|' || pk_alert_constant.g_display_type_date || '|' ||
                                              pk_alert_constant.g_color_red || '|' || NULL
                                             ELSE
                                              '|' || 'xxxxxxxxxxxxxx' || '|' || 'I' || '|' ||
                                              pk_alert_constant.g_color_none || '|' ||
                                              pk_sysdomain.get_img(i_lang,
                                                                   pk_opinion.g_opinion_consults,
                                                                   pk_opinion.g_opinion_reply)
                                         END state,
                                        o.flg_state
                                   FROM opinion o
                                  WHERE o.id_episode IN (SELECT /*+opt_estimate (table e rows=1) */
                                                          *
                                                           FROM TABLE(i_id_episode_list) e)
                                    AND o.flg_state != pk_opinion.g_opinion_cancel
                                    AND o.id_opinion_type IS NULL)
                          GROUP BY id_episode) t
                ON t.id_episode = ea.id_episode
             WHERE ea.id_episode IN (SELECT /*+opt_estimate (table a rows=1) */
                                      *
                                       FROM TABLE(i_id_episode_list) a);
    BEGIN
        pk_alertlog.log_debug('TRACKING_BOARD_EA: Selecting info', g_package_name, l_func_proc_name);
    
        IF i_id_episode_list IS NULL
           OR i_id_episode_list.count = 0
        THEN
            RETURN;
        END IF;
    
        OPEN c_info;
        FETCH c_info BULK COLLECT
            INTO l_tracking_board_ea_list;
        CLOSE c_info;
    
        IF l_tracking_board_ea_list IS NOT NULL
           AND l_tracking_board_ea_list.count > 0
        THEN
            IF NOT update_on_tracking_board_ea(i_lang                  => i_lang,
                                               i_tracking_board_ea_rec => l_tracking_board_ea_list,
                                               o_error                 => l_error)
            THEN
                RAISE e_exception;
            END IF;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END update_ea_logic_opinion;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_ea_logic_tracking_board;
/
