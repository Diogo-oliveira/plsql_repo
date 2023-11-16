/*-- Last Change Revision: $Rev: 2026690 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_migration IS
    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_EPISODE
    * Description:                    Function that updates EPIS_INFO with information from EPISODE
    *     
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/
    FUNCTION epis_info_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_episode IS
            SELECT id_episode, id_patient, id_software
              FROM episode e,
                   (SELECT DISTINCT etsi.id_epis_type, etsi.id_software
                      FROM epis_type_soft_inst etsi) etsi
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)))
               AND e.id_epis_type = etsi.id_epis_type;
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_patient IS TABLE OF episode.id_patient%TYPE;
        TYPE t_software IS TABLE OF software.id_software%TYPE;
        l_episode  t_episode;
        l_patient  t_patient;
        l_software t_software;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_EPISODE');
        g_error    := 'OPEN c_episode';
        start_time := dbms_utility.get_time;
        OPEN c_episode;
        LOOP
            g_error := 'FETCH c_episode';
            FETCH c_episode BULK COLLECT
                INTO l_episode, l_patient, l_software LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
            
                UPDATE epis_info
                   SET id_patient = l_patient(i), id_software = l_software(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_episode%NOTFOUND;
        
        END LOOP;
        CLOSE c_episode;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_EPISODE');
        start_time := dbms_utility.get_time;
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT', 'ID_SOFTWARE'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_EPISODE');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_EPISODE',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END epis_info_episode;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_TRIAGE
    * Description:                    Function that updates EPIS_INFO with information from TRIAGE
    *     
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/27
    *******************************************************************************************************************************************/

    FUNCTION epis_info_triage
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_ft_color         VARCHAR2(200) := '0xFFFFFF';
        g_ft_triage_white  VARCHAR2(200) := '0x787864';
        g_icon_ft          VARCHAR2(1) := 'F';
        g_icon_ft_transfer VARCHAR2(1) := 'T';
        g_desc_grid        VARCHAR2(1) := 'G';
    
        CURSOR c_triage IS
            SELECT ei.id_episode,
                   et.id_triage,
                   et.id_triage_white_reason,
                   tco.id_triage_color,
                   decode(pk_transfer_institution.check_epis_transfer(epis.id_episode),
                          0,
                          pk_fast_track.get_fast_track_icon(1, NULL, epis.id_fast_track, g_icon_ft),
                          pk_fast_track.get_fast_track_icon(1, NULL, epis.id_fast_track, g_icon_ft_transfer)) fast_track_icon,
                   pk_fast_track.get_fast_track_desc(1, NULL, epis.id_fast_track, g_desc_grid) fast_track_desc,
                   decode(tco.color, g_ft_color, g_ft_triage_white, g_ft_color) fast_track_color,
                   et.flg_letter,
                   tco.color acuity,
                   tco.color_text color_text,
                   tco.rank rank_acuity,
                   et2.id_triage id_first_triage,
                   et2.id_triage_white_reason id_first_triage_wr
              FROM epis_info ei, triage_color tco, episode epis, epis_triage et, epis_triage et2
             WHERE ei.id_episode = epis.id_episode
               AND ei.id_episode = et.id_episode
               AND ei.id_episode = et2.id_episode
               AND (tco.id_triage_color, et.id_epis_triage) =
                   (SELECT e.id_triage_color, e.id_epis_triage
                      FROM (SELECT etr.id_triage_color, etr.id_episode, etr.id_epis_triage
                              FROM epis_triage etr
                             WHERE etr.id_episode IN
                                   (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)))
                             ORDER BY etr.dt_end_tstz DESC) e
                     WHERE e.id_episode = epis.id_episode
                       AND rownum < 2)
               AND et2.id_epis_triage =
                   (SELECT e1.id_epis_triage
                      FROM (SELECT etr2.id_episode, etr2.id_epis_triage, etr2.id_triage, etr2.dt_end_tstz
                              FROM epis_triage etr2
                             WHERE etr2.id_episode IN
                                   (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)))
                             ORDER BY etr2.dt_end_tstz) e1
                     WHERE e1.id_episode = epis.id_episode
                       AND rownum < 2)
               AND ei.id_episode IN (SELECT *
                                       FROM TABLE(CAST(i_episode_list AS table_number)))
            UNION ALL
            --sem triagem
            SELECT epis.id_episode,
                   NULL            id_triage,
                   NULL            id_triage_white_reason,
                   -- José Brito 26/01/2010 ALERT-16615 Triage refactoring
                   pk_edis_triage.get_id_no_color(i_lang, profissional(NULL, v.id_institution, NULL), NULL) id_triage_color,
                   NULL fast_track_icon,
                   NULL fast_track_desc,
                   NULL fast_track_color,
                   NULL flg_letter,
                   g_ft_triage_white acuity,
                   g_ft_color color_text,
                   999 rank_acuity,
                   NULL id_first_triage,
                   NULL id_first_triage_wr
              FROM episode epis,
                   visit v,
                   (SELECT DISTINCT etsi.id_epis_type, etsi.id_software
                      FROM epis_type_soft_inst etsi) etsi
            
             WHERE NOT EXISTS
             (SELECT 1
                      FROM epis_triage et
                     WHERE et.id_episode = epis.id_episode)
               AND epis.id_visit = v.id_visit
               AND epis.id_epis_type = etsi.id_epis_type
               AND epis.id_episode IN (SELECT *
                                         FROM TABLE(CAST(i_episode_list AS table_number)));
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
    
        TYPE t_id_triage IS TABLE OF epis_triage.id_triage%TYPE;
        TYPE t_id_triage_white_reason IS TABLE OF epis_triage.id_triage_white_reason%TYPE;
        TYPE t_id_triage_color IS TABLE OF epis_triage.id_triage_color%TYPE;
    
        TYPE t_fast_track_icon IS TABLE OF epis_info.fast_track_icon%TYPE;
        TYPE t_fast_track_desc IS TABLE OF epis_info.fast_track_desc%TYPE;
        TYPE t_fast_track_color IS TABLE OF epis_info.fast_track_color%TYPE;
    
        TYPE t_acuity IS TABLE OF epis_info.triage_acuity%TYPE;
        TYPE t_color_text IS TABLE OF epis_info.triage_color_text%TYPE;
        TYPE t_rank_acuity IS TABLE OF epis_info.triage_rank_acuity%TYPE;
        TYPE t_id_first_triage IS TABLE OF epis_triage.id_triage%TYPE;
        TYPE t_id_first_triage_wr IS TABLE OF epis_triage.id_triage%TYPE;
        TYPE t_flg_letter IS TABLE OF epis_triage.flg_letter%TYPE;
    
        l_episode                t_episode;
        l_id_triage              t_id_triage;
        l_id_triage_white_reason t_id_triage_white_reason;
        l_id_triage_color        t_id_triage_color;
        l_fast_track_icon        t_fast_track_icon;
        l_fast_track_desc        t_fast_track_desc;
        l_fast_track_color       t_fast_track_color;
        l_flg_letter             t_flg_letter;
        l_acuity                 t_acuity;
        l_color_text             t_color_text;
        l_rank_acuity            t_rank_acuity;
        l_id_first_triage        t_id_first_triage;
        l_id_first_triage_wr     t_id_first_triage_wr;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        pk_alertlog.log_debug('EPIS_INFO_TRIAGE');
        g_error    := 'OPEN c_triage';
        start_time := dbms_utility.get_time;
        OPEN c_triage;
        LOOP
            g_error := 'FETCH c_episode';
            FETCH c_triage BULK COLLECT
                INTO l_episode,
                     l_id_triage,
                     l_id_triage_white_reason,
                     l_id_triage_color,
                     l_fast_track_icon,
                     l_fast_track_desc,
                     l_fast_track_color,
                     l_flg_letter,
                     l_acuity,
                     l_color_text,
                     l_rank_acuity,
                     l_id_first_triage,
                     l_id_first_triage_wr LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
            
                UPDATE epis_info
                   SET id_triage              = l_id_triage(i),
                       id_triage_white_reason = l_id_triage_white_reason(i),
                       id_triage_color        = l_id_triage_color(i),
                       triage_flg_letter      = l_flg_letter(i),
                       triage_acuity          = l_acuity(i),
                       triage_rank_acuity     = l_rank_acuity(i),
                       triage_color_text      = l_color_text(i),
                       fast_track_icon        = l_fast_track_icon(i),
                       fast_track_desc        = l_fast_track_desc(i),
                       fast_track_color       = l_fast_track_color(i),
                       id_first_triage        = l_id_first_triage(i),
                       id_first_triage_wr     = l_id_first_triage_wr(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_triage%NOTFOUND;
        
        END LOOP;
        CLOSE c_triage;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_TRIAGE');
        start_time := dbms_utility.get_time;
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_TRIAGE',
                                                                      'ID_TRIAGE_WHITE_REASON',
                                                                      'ID_TRIAGE_COLOR',
                                                                      'TRIAGE_FLG_LETTER',
                                                                      'TRIAGE_ACUITY',
                                                                      'TRIAGE_RANK_ACUITY',
                                                                      'TRIAGE_COLOR_TEXT',
                                                                      'FAST_TRACK_ICON',
                                                                      'FAST_TRACK_DESC',
                                                                      'FAST_TRACK_COLOR',
                                                                      'ID_FIRST_TRIAGE',
                                                                      'ID_FIRST_TRIAGE_WR'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_TRIAGE');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_TRIAGE',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END epis_info_triage;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_EXAM
    * Description:                    Function that updates EPIS_INFO with information from EXAMS
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/

    FUNCTION epis_info_exam
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exam IS
            SELECT e.id_episode,
                   (SELECT MIN(er.dt_req_tstz)
                      FROM exam_req er
                     WHERE er.id_episode = e.id_episode),
                   (SELECT MIN(es.dt_exam_result_tstz)
                      FROM exam_req er, exam_req_det erd, exam_result es
                     WHERE er.id_episode = e.id_episode
                       AND erd.id_exam_req = er.id_exam_req
                       AND erd.id_exam_req_det = es.id_exam_req_det
                       AND es.flg_status != pk_exam_constant.g_exam_result_cancel)
              FROM epis_info e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)));
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_dt_req IS TABLE OF exam_req.dt_req_tstz%TYPE;
        TYPE t_dt_exec IS TABLE OF exam_result.dt_exam_result_tstz%TYPE;
        l_episode t_episode;
        l_dt_req  t_dt_req;
        l_dt_exec t_dt_exec;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('EPIS_INFO_EXAM');
        g_error := 'OPEN c_exam';
    
        start_time := dbms_utility.get_time;
        OPEN c_exam;
        LOOP
            g_error := 'FETCH c_exam';
            FETCH c_exam BULK COLLECT
                INTO l_episode, l_dt_req, l_dt_exec LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET dt_first_image_req_tstz = l_dt_req(i), dt_first_image_exec_tstz = l_dt_exec(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_exam%NOTFOUND;
        
        END LOOP;
        CLOSE c_exam;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_EXAM');
        start_time := dbms_utility.get_time;
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_IMAGE_REQ_TSTZ',
                                                                      'DT_FIRST_IMAGE_EXEC_TSTZ'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_EXAM');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_EXAM',
                                              o_error    => o_error);
        
            dbms_output.put_line(o_error.err_desc || ' - ' || o_error.ora_sqlerrm);
            RETURN FALSE;
        
    END epis_info_exam;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_ANALYSIS
    * Description:                    Function that updates EPIS_INFO with information from ANALYSIS
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/

    FUNCTION epis_info_analysis
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis IS
            SELECT e.id_episode,
                   (SELECT MIN(ar.dt_req_tstz)
                      FROM analysis_req ar
                     WHERE ar.id_episode = e.id_episode),
                   (SELECT MIN(h.dt_harvest_tstz)
                      FROM harvest h
                     WHERE h.id_episode = e.id_episode)
              FROM epis_info e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)));
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_dt_req IS TABLE OF exam_req.dt_req_tstz%TYPE;
        TYPE t_dt_exec IS TABLE OF exam_result.dt_exam_result_tstz%TYPE;
        l_episode t_episode;
        l_dt_req  t_dt_req;
        l_dt_exec t_dt_exec;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_ANALYSIS');
        g_error    := 'OPEN c_exam';
        start_time := dbms_utility.get_time;
        OPEN c_analysis;
        LOOP
            g_error := 'FETCH c_exam';
            FETCH c_analysis BULK COLLECT
                INTO l_episode, l_dt_req, l_dt_exec LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET dt_first_analysis_req_tstz = l_dt_req(i), dt_first_analysis_exe_tstz = l_dt_exec(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_analysis%NOTFOUND;
        
        END LOOP;
        CLOSE c_analysis;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_ANALYSIS');
        start_time := dbms_utility.get_time;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_ANALYSIS_REQ_TSTZ',
                                                                      'DT_FIRST_ANALYSIS_EXE_TSTZ'));
    
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_ANALYSIS');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_ANALYSIS',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END epis_info_analysis;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_PRESCRIPTION
    * Description:                    Function that updates EPIS_INFO with information from PRESCRIPTION
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/27
    *******************************************************************************************************************************************/

    FUNCTION epis_info_prescription
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_prescription IS
            SELECT e.id_episode,
                   (SELECT MIN(ip.dt_interv_prescription_tstz)
                      FROM interv_prescription ip
                     WHERE ip.id_episode = e.id_episode),
                   (SELECT MIN(ipp.dt_take_tstz)
                      FROM interv_prescription ip, interv_presc_det epd, interv_presc_plan ipp
                     WHERE ip.id_episode = e.id_episode
                       AND epd.id_interv_prescription = ip.id_interv_prescription
                       AND epd.id_interv_presc_det = ipp.id_interv_presc_det) --,
              FROM episode e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)));
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_dt_req IS TABLE OF interv_prescription.dt_interv_prescription_tstz%TYPE;
        TYPE t_dt_exec IS TABLE OF interv_presc_plan.dt_take_tstz%TYPE;
        l_episode t_episode;
        l_dt_req  t_dt_req;
        l_dt_exec t_dt_exec;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_PRESCRIPTION');
        g_error    := 'OPEN c_prescription';
        start_time := dbms_utility.get_time;
        OPEN c_prescription;
        LOOP
            g_error := 'FETCH c_prescription';
            FETCH c_prescription BULK COLLECT
                INTO l_episode, l_dt_req, l_dt_exec LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET dt_first_interv_prsc_tstz = l_dt_req(i), dt_first_interv_take_tstz = l_dt_exec(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_prescription%NOTFOUND;
        
        END LOOP;
        CLOSE c_prescription;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_PRESCRIPTION');
        start_time := dbms_utility.get_time;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_INTERV_PRSC_TSTZ',
                                                                      'DT_FIRST_INTERV_TAKE_TSTZ'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_PRESCRIPTION');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_PRESCRIPTION',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END epis_info_prescription;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_DRUG
    * Description:                    Function that updates EPIS_INFO with information from DRUG PRESCRIPTION
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/27
    *******************************************************************************************************************************************/

    FUNCTION epis_info_drug
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_drug IS
            SELECT e.id_episode,
                   MIN(a.dt_first),
                   (SELECT MIN(dpp.dt_take_tstz)
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_episode = e.id_episode
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpd.id_drug_presc_det = dpp.id_drug_presc_det)
              FROM episode e,
                   (SELECT p.id_episode, MIN(p.dt_prescription_tstz) dt_first
                      FROM prescription p
                     WHERE p.id_episode IN (SELECT *
                                              FROM TABLE(CAST(i_episode_list AS table_number)))
                     GROUP BY p.id_episode
                    UNION
                    SELECT dr.id_episode, MIN(dr.dt_drug_req_tstz) dt_first
                      FROM drug_req dr
                     WHERE dr.id_episode IN (SELECT *
                                               FROM TABLE(CAST(i_episode_list AS table_number)))
                     GROUP BY dr.id_episode
                    UNION
                    SELECT dp.id_episode, MIN(dp.dt_drug_prescription_tstz) dt_first
                      FROM drug_prescription dp
                     WHERE dp.id_episode IN (SELECT *
                                               FROM TABLE(CAST(i_episode_list AS table_number)))
                     GROUP BY dp.id_episode) a
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)))
               AND e.id_episode = a.id_episode(+)
             GROUP BY e.id_episode;
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_dt_req IS TABLE OF drug_prescription.dt_drug_prescription_tstz%TYPE;
        TYPE t_dt_exec IS TABLE OF drug_presc_plan.dt_take_tstz%TYPE;
        l_episode t_episode;
        l_dt_req  t_dt_req;
        l_dt_exec t_dt_exec;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_DRUG');
        g_error    := 'OPEN c_DRUG';
        start_time := dbms_utility.get_time;
        OPEN c_drug;
        LOOP
            g_error := 'FETCH c_DRUG';
            FETCH c_drug BULK COLLECT
                INTO l_episode, l_dt_req, l_dt_exec LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET dt_first_drug_prsc_tstz = l_dt_req(i), dt_first_drug_take_tstz = l_dt_exec(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_drug%NOTFOUND;
        
        END LOOP;
        CLOSE c_drug;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_DRUG');
        start_time := dbms_utility.get_time;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_DRUG_PRSC_TSTZ',
                                                                      'DT_FIRST_DRUG_TAKE_TSTZ'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_DRUG');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_DRUG',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END epis_info_drug;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_SCHEDULE
    * Description:                    Function that updates EPIS_INFO with information from SCHEDULE
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/

    FUNCTION epis_info_schedule
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_schedule IS
            SELECT ei.id_episode,
                   nvl(s.id_schedule, -1) id_schedule,
                   s.id_dcs_requested,
                   s.id_instit_requested,
                   s.id_prof_schedules,
                   s.flg_status,
                   decode(s.flg_reason_type, 'C', s.id_reason, NULL) id_complaint,
                   s.flg_urgency,
                   sg.id_patient,
                   so.id_schedule_outp,
                   spo.id_professional
              FROM schedule s, epis_info ei, sch_group sg, schedule_outp so, sch_prof_outp spo
             WHERE s.id_schedule(+) = ei.id_schedule
               AND sg.id_schedule(+) = ei.id_schedule
               AND so.id_schedule(+) = ei.id_schedule
               AND so.id_schedule_outp = spo.id_schedule_outp(+)
               AND ei.id_episode IN (SELECT *
                                       FROM TABLE(CAST(i_episode_list AS table_number)));
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_id_schedule IS TABLE OF schedule.id_schedule%TYPE;
        TYPE t_id_dcs_requested IS TABLE OF schedule.id_dcs_requested%TYPE;
        TYPE t_id_instit_requested IS TABLE OF schedule.id_instit_requested%TYPE;
        TYPE t_id_prof_schedules IS TABLE OF schedule.id_prof_schedules%TYPE;
        TYPE t_flg_status IS TABLE OF schedule.flg_status%TYPE;
        TYPE t_id_complaint IS TABLE OF schedule.id_reason%TYPE;
        TYPE t_flg_urgency IS TABLE OF schedule.flg_urgency%TYPE;
        TYPE t_id_patient IS TABLE OF sch_group.id_patient%TYPE;
        TYPE t_id_schedule_outp IS TABLE OF schedule_outp.id_schedule_outp%TYPE;
        TYPE t_id_professional IS TABLE OF sch_prof_outp.id_professional%TYPE;
    
        l_episode             t_episode;
        l_id_schedule         t_id_schedule;
        l_id_dcs_requested    t_id_dcs_requested;
        l_id_instit_requested t_id_instit_requested;
        l_id_prof_schedules   t_id_prof_schedules;
        l_flg_status          t_flg_status;
        l_id_complaint        t_id_complaint;
        l_flg_urgency         t_flg_urgency;
        l_id_patient          t_id_patient;
        l_id_schedule_outp    t_id_schedule_outp;
        l_id_professional     t_id_professional;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_SCHEDULE');
        g_error    := 'OPEN c_schedule';
        start_time := dbms_utility.get_time;
        OPEN c_schedule;
        LOOP
            g_error := 'FETCH c_schedule';
        
            FETCH c_schedule BULK COLLECT
                INTO l_episode,
                     l_id_schedule,
                     l_id_dcs_requested,
                     l_id_instit_requested,
                     l_id_prof_schedules,
                     l_flg_status,
                     l_id_complaint,
                     l_flg_urgency,
                     l_id_patient,
                     l_id_schedule_outp,
                     l_id_professional LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET id_schedule           = l_id_schedule(i),
                       id_dcs_requested      = l_id_dcs_requested(i),
                       id_instit_requested   = l_id_instit_requested(i),
                       id_prof_schedules     = l_id_prof_schedules(i),
                       flg_sch_status        = l_flg_status(i),
                       id_complaint          = l_id_complaint(i),
                       flg_urgency           = l_flg_urgency(i),
                       sch_group_id_patient  = l_id_patient(i),
                       id_schedule_outp      = l_id_schedule_outp(i),
                       sch_prof_outp_id_prof = l_id_professional(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_schedule%NOTFOUND;
        
        END LOOP;
        CLOSE c_schedule;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_SCHEDULE');
        start_time := dbms_utility.get_time;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_SCHEDULE',
                                                                      'ID_DCS_REQUESTED',
                                                                      'ID_INSTIT_REQUESTED',
                                                                      'ID_PROF_SCHEDULES',
                                                                      'FLG_SCH_STATUS',
                                                                      'ID_COMPLAINT',
                                                                      'FLG_URGENCY',
                                                                      'SCH_GROUP_ID_PATIENT',
                                                                      'ID_SCHEDULE_OUTP',
                                                                      'SCH_PROF_OUTP_ID_PROF'));
    
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_SCHEDULE');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_SCHEDULE',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END epis_info_schedule;

    /*******************************************************************************************************************************************
    * Name:                           epis_info_DISCHARGE
    * Description:                    Function that updates EPIS_INFO with information from DISCHARGE
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/27
    *******************************************************************************************************************************************/

    FUNCTION epis_info_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_discharge IS
            SELECT d.id_episode,
                   d.flg_status,
                   d.id_disch_reas_dest,
                   d.dt_med_tstz,
                   d.dt_pend_active_tstz,
                   pk_discharge_core.get_dt_admin(i_lang,
                                                  profissional(0, e.id_institution, ei.id_software),
                                                  NULL,
                                                  d.flg_status_adm,
                                                  d.dt_admin_tstz) dt_admin_tstz
              FROM discharge d
              JOIN epis_info ei
                ON ei.id_episode = d.id_episode
              JOIN episode e
                ON e.id_episode = ei.id_episode
             WHERE d.id_discharge = (SELECT MAX(disch.id_discharge)
                                       FROM discharge disch
                                      WHERE d.id_episode = disch.id_episode)
               AND EXISTS (SELECT 1
                      FROM disch_reas_dest drd
                     WHERE drd.id_disch_reas_dest = d.id_disch_reas_dest)
               AND d.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)))
            UNION ALL
            SELECT e.id_episode,
                   NULL         flg_status,
                   NULL         id_disch_reas_dest,
                   NULL         dt_med_tstz,
                   NULL         dt_pend_active_tstz,
                   NULL         dt_admin_tstz
              FROM epis_info e
             WHERE NOT EXISTS (SELECT 1
                      FROM discharge d
                     WHERE e.id_episode = d.id_episode)
               AND e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)));
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_flg_status IS TABLE OF discharge.flg_status%TYPE;
        TYPE t_id_disch_reas_dest IS TABLE OF discharge.id_disch_reas_dest%TYPE;
        TYPE t_dt_med_tstz IS TABLE OF discharge.dt_med_tstz%TYPE;
        TYPE t_dt_pend_active_tstz IS TABLE OF discharge.dt_pend_active_tstz%TYPE;
        TYPE t_dt_admin_tstz IS TABLE OF discharge.dt_admin_tstz%TYPE;
    
        l_episode             t_episode;
        l_flg_status          t_flg_status;
        l_id_disch_reas_dest  t_id_disch_reas_dest;
        l_dt_med_tstz         t_dt_med_tstz;
        l_dt_pend_active_tstz t_dt_pend_active_tstz;
        l_dt_admin_tstz       t_dt_admin_tstz;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_DISCHARGE');
        g_error    := 'OPEN c_discharge';
        start_time := dbms_utility.get_time;
        OPEN c_discharge;
        LOOP
            g_error := 'FETCH c_discharge';
        
            FETCH c_discharge BULK COLLECT
                INTO l_episode,
                     l_flg_status,
                     l_id_disch_reas_dest,
                     l_dt_med_tstz,
                     l_dt_pend_active_tstz,
                     l_dt_admin_tstz LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET flg_dsch_status     = l_flg_status(i),
                       id_disch_reas_dest  = l_id_disch_reas_dest(i),
                       dt_med_tstz         = l_dt_med_tstz(i),
                       dt_pend_active_tstz = l_dt_pend_active_tstz(i),
                       dt_admin_tstz       = l_dt_admin_tstz(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_discharge%NOTFOUND;
        
        END LOOP;
        CLOSE c_discharge;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_DISCHARGE');
        start_time := dbms_utility.get_time;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_DSCH_STATUS',
                                                                      'ID_DISCH_REAS_DEST',
                                                                      'DT_MED_TSTZ',
                                                                      'DT_PEND_ACTIVE_TSTZ',
                                                                      'DT_ADMIN_TSTZ'));
    
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_DISCHARGE');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_DISCHARGE',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END epis_info_discharge;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_MOVEMENT
    * Description:                    Function that updates EPIS_INFO with information from MOVEMENT
    *     
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/27
    *******************************************************************************************************************************************/

    FUNCTION epis_info_movement
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_movement IS
            SELECT id_episode,
                   greatest(dt_req_tstz, dt_end_tstz),
                   dt_end_tstz,
                   (SELECT id_room_to
                      FROM movement
                     WHERE id_episode = a.id_episode
                       AND id_movement = (SELECT MAX(id_movement)
                                            FROM movement
                                           WHERE flg_status = 'F')) id_room
              FROM (SELECT e.id_episode, MAX(m.dt_req_tstz) dt_req_tstz, MAX(m.dt_end_tstz) dt_end_tstz
                      FROM episode e, movement m
                     WHERE e.id_episode IN (SELECT *
                                              FROM TABLE(CAST(i_episode_list AS table_number)))
                       AND e.id_episode = m.id_episode
                     GROUP BY e.id_episode) a
            UNION ALL
            SELECT id_episode, dt_req, dt_ent, decode(id_room2, NULL, id_room1, id_room2) id_room
              FROM (SELECT e.id_episode,
                           NULL dt_req,
                           NULL dt_ent,
                           (SELECT er.id_room
                              FROM epis_type_room er
                             WHERE er.id_epis_type = e.id_epis_type
                               AND er.id_institution = e.id_institution
                               AND nvl(er.id_dep_clin_serv, 0) = 0
                               AND rownum < 2) id_room1,
                           (SELECT er.id_room
                              FROM epis_type_room er
                             WHERE er.id_epis_type = e.id_epis_type
                               AND er.id_institution = e.id_institution
                               AND er.id_dep_clin_serv = ei.id_dep_clin_serv
                               AND rownum < 2) id_room2
                      FROM episode e, epis_info ei
                     WHERE e.id_episode = ei.id_episode
                       AND e.id_episode IN (SELECT *
                                              FROM TABLE(CAST(i_episode_list AS table_number)))
                       AND NOT EXISTS (SELECT 1
                              FROM movement m
                             WHERE m.id_episode = e.id_episode));
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_dt_movement IS TABLE OF movement.dt_req_tstz%TYPE;
        TYPE t_dt_entrance IS TABLE OF movement.dt_end_tstz%TYPE;
        TYPE t_id_room IS TABLE OF movement.id_room_to%TYPE;
        l_episode     t_episode;
        l_dt_movement t_dt_movement;
        l_dt_entrance t_dt_entrance;
        l_id_room     t_id_room;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_MOVEMENT');
        g_error    := 'OPEN c_movement';
        start_time := dbms_utility.get_time;
        OPEN c_movement;
        LOOP
            g_error := 'FETCH c_movement';
            FETCH c_movement BULK COLLECT
                INTO l_episode, l_dt_movement, l_dt_entrance, l_id_room LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
            
                UPDATE epis_info
                   SET dt_movement_tstz      = l_dt_movement(i),
                       dt_entrance_room_tstz = l_dt_entrance(i),
                       id_room               = nvl(l_id_room(i), id_room)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_movement%NOTFOUND;
        
        END LOOP;
        CLOSE c_movement;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_MOVEMENT');
        start_time := dbms_utility.get_time;
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_MOVEMENT_TSTZ',
                                                                      'DT_ENTRANCE_ROOM_TSTZ',
                                                                      'ID_ROOM'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_MOVEMENT');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_MOVEMENT',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END epis_info_movement;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_ORIS_SCHEDULE
    * Description:                    Function that updates EPIS_INFO with information from ORIS SCHEDULE AND ROOM_SCHEDULE
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/

    FUNCTION epis_info_oris_schedule
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_schedule_sr IS
            SELECT ei.id_episode, sr.id_schedule_sr, ssr.flg_pat_status, ssr.dt_room_entry_tstz
              FROM schedule_sr sr, epis_info ei, sr_surgery_record ssr
             WHERE sr.id_schedule(+) = ei.id_schedule
               AND ssr.id_schedule_sr(+) = sr.id_schedule_sr
               AND ei.id_episode IN (SELECT *
                                       FROM TABLE(CAST(i_episode_list AS table_number)))
            UNION ALL
            SELECT ei.id_episode, NULL id_schedule_sr, NULL flg_pat_status, NULL dt_room_entry_tstz
              FROM epis_info ei
             WHERE NOT EXISTS (SELECT 1
                      FROM schedule_sr sr
                     WHERE sr.id_schedule = ei.id_schedule)
               AND ei.id_episode IN (SELECT *
                                       FROM TABLE(CAST(i_episode_list AS table_number)));
    
        CURSOR c_oris_schedule IS
            SELECT ei.id_episode,
                   rs.id_room_scheduled,
                   rs.flg_status,
                   (SELECT dt_surgery_time_det_tstz
                      FROM sr_surgery_time_det sstd
                     WHERE sstd.id_episode = ei.id_episode
                       AND sstd.id_sr_surgery_time_det =
                           (SELECT MAX(id_sr_surgery_time_det)
                              FROM sr_surgery_time_det sstd1
                             WHERE sstd1.id_episode = sstd.id_episode)) dt_surgery_time_det_tstz
              FROM (SELECT rs.id_room_scheduled, rs.id_schedule, rsched.flg_status
                      FROM (SELECT MAX(id_room_scheduled) id_room_scheduled, id_schedule
                              FROM room_scheduled
                             GROUP BY id_schedule) rs,
                           room_scheduled rsched
                     WHERE rs.id_room_scheduled = rsched.id_room_scheduled) rs,
                   epis_info ei
             WHERE rs.id_schedule(+) = ei.id_schedule
               AND ei.id_episode IN (SELECT *
                                       FROM TABLE(CAST(i_episode_list AS table_number)))
            UNION ALL
            SELECT ei.id_episode, NULL, NULL, NULL
              FROM epis_info ei
             WHERE NOT EXISTS (SELECT 1
                      FROM room_scheduled rs
                     WHERE rs.id_schedule = ei.id_schedule)
               AND ei.id_episode IN (SELECT *
                                       FROM TABLE(CAST(i_episode_list AS table_number)));
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_id_schedule_sr IS TABLE OF schedule_sr.id_schedule_sr%TYPE;
        TYPE t_flg_pat_status IS TABLE OF sr_surgery_record.flg_pat_status%TYPE;
        TYPE t_dt_room_entry_tstz IS TABLE OF sr_surgery_record.dt_room_entry_tstz%TYPE;
        TYPE t_id_room_scheduled IS TABLE OF room_scheduled.id_room_scheduled%TYPE;
        TYPE t_flg_status IS TABLE OF room_scheduled.flg_status%TYPE;
        TYPE t_dt_surgery_time_det_tstz IS TABLE OF sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE;
    
        l_episode                  t_episode;
        l_id_schedule_sr           t_id_schedule_sr;
        l_flg_pat_status           t_flg_pat_status;
        l_dt_room_entry_tstz       t_dt_room_entry_tstz;
        l_id_room_scheduled        t_id_room_scheduled;
        l_flg_status               t_flg_status;
        l_dt_surgery_time_det_tstz t_dt_surgery_time_det_tstz;
    
        l_rows      table_varchar;
        l_all_rows  table_varchar := table_varchar();
        l_all_rows1 table_varchar := table_varchar();
        l_all_rows2 table_varchar := table_varchar();
        start_time  NUMBER;
        end_time    NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_ORIS_SCHEDULE');
        g_error    := 'OPEN c_schedule_sr';
        start_time := dbms_utility.get_time;
        OPEN c_schedule_sr;
        LOOP
            g_error := 'FETCH c_schedule_sr';
        
            FETCH c_schedule_sr BULK COLLECT
                INTO l_episode, l_id_schedule_sr, l_flg_pat_status, l_dt_room_entry_tstz LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET id_schedule_sr     = l_id_schedule_sr(i),
                       flg_pat_status     = l_flg_pat_status(i),
                       dt_room_entry_tstz = l_dt_room_entry_tstz(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            IF (l_all_rows IS NULL)
            THEN
                l_all_rows := table_varchar();
            END IF;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_schedule_sr%NOTFOUND;
        
        END LOOP;
        CLOSE c_schedule_sr;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO SHEDULE_SR Limit(: ' || i_limit || ') ' ||
                              to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_ORIS_SCHEDULE');
        start_time := dbms_utility.get_time;
        g_error    := 'OPEN c_oris_schedule';
    
        OPEN c_oris_schedule;
        LOOP
            g_error := 'FETCH c_oris_schedule';
        
            FETCH c_oris_schedule BULK COLLECT
                INTO l_episode, l_id_room_scheduled, l_flg_status, l_dt_surgery_time_det_tstz LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET id_room_scheduled        = l_id_room_scheduled(i),
                       room_sch_flg_status      = l_flg_status(i),
                       dt_surgery_time_det_tstz = l_dt_surgery_time_det_tstz(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows1 := l_all_rows1 MULTISET UNION l_rows;
        
            EXIT WHEN c_oris_schedule%NOTFOUND;
        
        END LOOP;
        CLOSE c_oris_schedule;
    
        end_time    := dbms_utility.get_time;
        l_all_rows2 := l_all_rows1 MULTISET UNION l_all_rows;
    
        pk_alertlog.log_debug('UPDATE EPIS_INFO ROOM SCHEDULE Limit(: ' || i_limit || ') ' ||
                              to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_ORIS_SCHEDULE');
        start_time := dbms_utility.get_time;
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows2,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_SCHEDULE_SR',
                                                                      'FLG_PAT_STATUS',
                                                                      'DT_ROOM_ENTRY_TSTZ',
                                                                      'ID_ROOM_SCHEDULED',
                                                                      'ROOM_SCH_FLG_STATUS',
                                                                      'DT_SURGERY_TIME_DET_TSTZ'));
    
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_ORIS_SCHEDULE');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_ORIS_SCHEDULE',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END epis_info_oris_schedule;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_BED
    * Description:                    Function that updates EPIS_INFO with information from BMNG_ALLOCATION_BED
    * 
    * @param i_episode_list           List of episodes to update
    * @param i_limit           Limit for commit
    * 
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/27
    *******************************************************************************************************************************************/

    FUNCTION epis_info_bed
    (
        i_lang         IN language.id_language%TYPE,
        i_episode_list IN table_number,
        i_limit        IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_bed IS
            SELECT e.id_episode,
                   (SELECT bab.id_bed
                      FROM bmng_allocation_bed bab, bmng_action ba
                     WHERE bab.id_episode = e.id_episode
                       AND bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
                       AND ba.flg_bed_status NOT IN ('R', 'S')
                       AND ba.flg_bed_ocupacity_status = 'O'
                       AND ba.flg_status = 'A'
                       AND bab.flg_outdated = 'N') id_bed
              FROM epis_info e
             WHERE e.id_episode IN (SELECT *
                                      FROM TABLE(CAST(i_episode_list AS table_number)));
    
        TYPE t_episode IS TABLE OF episode.id_episode%TYPE;
        TYPE t_id_bed IS TABLE OF epis_info.id_bed%TYPE;
        l_episode t_episode;
        l_id_bed  t_id_bed;
    
        l_rows     table_varchar;
        l_all_rows table_varchar := table_varchar();
        start_time NUMBER;
        end_time   NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('EPIS_INFO_BED');
        start_time := dbms_utility.get_time;
        g_error    := 'OPEN c_bed';
        OPEN c_bed;
        LOOP
            g_error := 'FETCH c_bed';
            FETCH c_bed BULK COLLECT
                INTO l_episode, l_id_bed LIMIT i_limit;
        
            g_error := 'FORALL ' || l_episode.count;
            FORALL i IN 1 .. l_episode.count
                UPDATE epis_info
                   SET id_bed = l_id_bed(i)
                 WHERE id_episode = l_episode(i)
                RETURNING ROWID BULK COLLECT INTO l_rows;
        
            l_all_rows := l_all_rows MULTISET UNION l_rows;
        
            EXIT WHEN c_bed%NOTFOUND;
        
        END LOOP;
        CLOSE c_bed;
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('UPDATE EPIS_INFO Limit(: ' || i_limit || ') ' || to_char(end_time - start_time) / 100 ||
                              ' seconds ',
                              g_package_name,
                              'EPIS_INFO_BED');
        start_time := dbms_utility.get_time;
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => NULL,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_all_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_BED'));
        end_time := dbms_utility.get_time;
        pk_alertlog.log_debug('PROCESS_UPDATE: ' || to_char(end_time - start_time) / 100 || ' seconds ',
                              g_package_name,
                              'EPIS_INFO_BED');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EPIS_INFO_BED',
                                              o_error    => o_error);
            RETURN FALSE;
    END epis_info_bed;

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_UPDATE
    * Description:                    Function that updates EPIS_INFO with information from diferent areas
    * 
    * @param i_lang                   Language
    * @param i_area                   Area (EPISODE/EXAM/ANALYSIS/TRIAGE/MOVEMENT/PRESCRIPTION/SCHEDULE/DISCHARGE/DRUG/SCHEDULE_ORIS/BED)
    * @param i_episode_list           List of episodes to update
    * @param i_limit                  Limit for BULK COLLECT
    * @param i_commit_data            BOOLEAN that indicates if the function does commit.
    *                                 If FALSE the commit must be processed by the calling function
    * 
    * @param out O_desc_ERROR         Returns a string with the description of the error
    *          
    * @return                         Return FALSE if an error occours, otherwise return TRUE. 
    *                                  
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/
    FUNCTION epis_info_update
    (
        i_lang        IN language.id_language%TYPE,
        i_area        IN VARCHAR2,
        i_episode_lis IN table_number,
        i_limit       IN NUMBER DEFAULT 1000,
        i_commit_data IN BOOLEAN DEFAULT FALSE,
        o_desc_error  OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_error t_error_out;
        l_area  VARCHAR2(200);
    BEGIN
        l_area := upper(i_area);
        IF l_area = 'EPISODE'
        THEN
            IF NOT epis_info_episode(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'EXAM'
        THEN
            IF NOT epis_info_exam(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'ANALYSIS'
        THEN
            IF NOT epis_info_analysis(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'TRIAGE'
        THEN
            IF NOT epis_info_triage(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'MOVEMENT'
        THEN
            IF NOT epis_info_movement(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'PRESCRIPTION'
        THEN
            IF NOT epis_info_prescription(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'SCHEDULE'
        THEN
            IF NOT epis_info_schedule(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_area = 'DISCHARGE'
        THEN
            IF NOT epis_info_discharge(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'DRUG'
        THEN
            IF NOT epis_info_drug(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'SCHEDULE_ORIS'
        THEN
            IF NOT epis_info_oris_schedule(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_area = 'BED'
        THEN
            IF NOT epis_info_bed(i_lang, i_episode_lis, i_limit, l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        IF i_commit_data
        THEN
            COMMIT;
        END IF;
        --  pk_utils.undo_changes();
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            /*      pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'EPIS_INFO_UPDATE',
                                                  o_error    => l_error);
            */
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state();
            o_desc_error := l_error.err_desc || ':' || l_error.ora_sqlerrm;
            RETURN FALSE;
    END epis_info_update;

BEGIN

    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_sysdate_tstz := current_timestamp;

END pk_api_migration;
/
