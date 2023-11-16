/*-- Last Change Revision: $Rev: 2027903 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wtl_pbl_core IS

    -- Private Package Constants
    g_yes      CONSTANT VARCHAR2(1) := 'Y';
    g_no       CONSTANT VARCHAR2(1) := 'N';
    g_active   CONSTANT VARCHAR2(1) := 'A';
    g_inactive CONSTANT VARCHAR2(1) := 'I';

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    g_grid_date_format CONSTANT VARCHAR2(20) := 'DATE_FORMAT_M006';

    --wtl_epis.flg_status
    g_wtle_stat_sched CONSTANT VARCHAR2(1) := 'S';

    --wtl_documentation.flg_status
    g_wtl_doc_flg_pending CONSTANT VARCHAR2(1) := 'P';

    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    g_exception EXCEPTION;

    /******************************************************************************
    *  returns list of episodes for this id_waiting_list.
    *  All episodes if i_id_epis_type is null or episodes of epis_type equal to i_id_epis_type.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_epis_type       epis type for episode filtering
    *  @param  o_episodes          output
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN epis_type.id_epis_type%TYPE,
        o_episodes        OUT t_rec_episodes,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPISODES';
    BEGIN
        g_error := 'fill output collection';
        SELECT w.id_episode, e.id_epis_type, w.id_schedule
          BULK COLLECT
          INTO o_episodes
          FROM wtl_epis w
          JOIN episode e
            ON e.id_episode = w.id_episode
         WHERE w.id_waiting_list = i_id_waiting_list
           AND (i_id_epis_type IS NULL OR e.id_epis_type = i_id_epis_type);
    
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
    END get_episodes;

    /**
    * upgrade da anterior para contemplar a flg_status
    */
    FUNCTION get_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_epis_type    IN epis_type.id_epis_type%TYPE,
        i_flg_status      IN wtl_epis.flg_status%TYPE,
        o_episodes        OUT t_rec_episodes,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPISODES';
    BEGIN
        g_error := 'fill output collection';
        SELECT w.id_episode, e.id_epis_type, w.id_schedule
          BULK COLLECT
          INTO o_episodes
          FROM wtl_epis w
          JOIN episode e
            ON e.id_episode = w.id_episode
         WHERE w.id_waiting_list = i_id_waiting_list
           AND (i_id_epis_type IS NULL OR e.id_epis_type = i_id_epis_type)
           AND (i_flg_status IS NULL OR w.flg_status = i_flg_status);
    
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
    END get_episodes;

    /******************************************************************************
    *  Returns true if episode exists on waiting list. Returns false otherwise.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_episodes          episode identifier
    *
    *  @return                     Y - Yes, N - No
    *
    *  @author                     Luís Maia
    *  @version                    2.5.1.2
    *  @since                      12-11-2010
    *
    ******************************************************************************/
    FUNCTION check_episode_in_wtl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_episode_in_wl_exists PLS_INTEGER;
    BEGIN
        g_error := 'CHECK_EPISODE_IN_WTL';
        SELECT COUNT(0)
          INTO l_episode_in_wl_exists
          FROM wtl_epis we
         WHERE we.id_episode = i_episode;
    
        RETURN CASE l_episode_in_wl_exists WHEN 0 THEN pk_alert_constant.g_no ELSE pk_alert_constant.g_yes END;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_episode_in_wtl;

    /******************************************************************************
    *  Returns true if episode exists on waiting list and is schedule. 
    *  Returns false otherwise.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_episodes          episode identifier
    *
    *  @return                      Y - Yes, N - No
    *
    *  @author                     Luís Maia
    *  @version                    2.5.1.2
    *  @since                      12-11-2010
    *
    ******************************************************************************/
    FUNCTION check_episode_sched_wtl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_episode_in_wl_exists PLS_INTEGER;
    BEGIN
        g_error := 'CHECK_EPISODE_SCHED_WTL';
        SELECT COUNT(0)
          INTO l_episode_in_wl_exists
          FROM wtl_epis we
         WHERE we.id_episode = i_episode
           AND we.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule;
    
        RETURN CASE l_episode_in_wl_exists WHEN 0 THEN pk_alert_constant.g_no ELSE pk_alert_constant.g_yes END;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_episode_sched_wtl;

    /******************************************************************************
    *  returns list of unavailability periods for this patient and this particular waiting list entry.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_unavailabilities  output       
    *  @param  o_error               
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5.0.2
    *  @since                      2009/04/13
    *
    ******************************************************************************/
    FUNCTION get_unavailability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE,
        i_all              IN VARCHAR2 DEFAULT 'Y',
        o_unavailabilities OUT t_rec_unavailabilities,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_UNAVAILABILITY';
    BEGIN
        g_error := 'fill output collection';
        SELECT dt_unav_start, dt_unav_end
          BULK COLLECT
          INTO o_unavailabilities
          FROM wtl_unav u
         WHERE u.id_waiting_list = i_id_waiting_list
           AND (i_all = g_yes OR u.flg_status = g_active);
    
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
    END get_unavailability;

    /******************************************************************************
    *  Returns list of schedule periods for this patient and this particular waiting list entry.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_episode_sr        ID of the oris episode
    *  @param  i_episode_inp        ID of the INP episode
    *  @param  o_sched_period  output       
    *  @param  o_error               
    *
    *  @return                     TRUE for success, FALSE for failure
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    1.0
    *  @since                      2009/06/09
    *
    ******************************************************************************/
    FUNCTION get_sch_periods
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_episode_sr      IN episode.id_episode%TYPE,
        i_episode_inp     IN episode.id_episode%TYPE,
        o_sched_period    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCH_PERIODS';
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_sched_period FOR
            SELECT -- 16 - Scheduling period start
             pk_date_utils.date_send_tsz(i_lang, wl.dt_dpb, i_prof) dt_sched_start_send,
             pk_date_utils.date_char_tsz(i_lang, wl.dt_dpb, i_prof.institution, i_prof.software) dt_sched_start_char,
             -- 17 - Urg level
             wl.id_wtl_urg_level,
             nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) desc_urg_level,
             wul.duration duration_urg_level,
             -- 18 - Scheduling period end
             pk_date_utils.date_send_tsz(i_lang, wl.dt_dpa, i_prof) dt_sched_end_send,
             pk_date_utils.date_char_tsz(i_lang, wl.dt_dpa, i_prof.institution, i_prof.software) dt_sched_end_char,
             -- 19 - Minimum time to inform
             wl.min_inform_time,
             -- 20 - Suggested surgery date / Suggested admission date
             pk_date_utils.date_send_tsz(i_lang, wl.dt_surgery, i_prof) dt_sug_surg_send,
             pk_date_utils.date_char_tsz(i_lang, wl.dt_surgery, i_prof.institution, i_prof.software) dt_sug_surg_char,
             pk_date_utils.date_send_tsz(i_lang, wl.dt_admission, i_prof) dt_sug_admission_send,
             pk_date_utils.date_char_tsz(i_lang, wl.dt_admission, i_prof.institution, i_prof.software) dt_sug_admission_char,
             -- 21 - Surgery date
             pk_date_utils.date_send_tsz(i_lang, s.dt_target_tstz, i_prof) dt_surgery_send,
             pk_date_utils.date_char_tsz(i_lang, s.dt_target_tstz, i_prof.institution, i_prof.software) dt_surgery_char,
             -- 22 - Admission date
             pk_date_utils.date_send_tsz(i_lang, adm.dt_admission, i_prof) dt_admission_send,
             pk_date_utils.date_char_tsz(i_lang, adm.dt_admission, i_prof.institution, i_prof.software) dt_admission_char,
             CASE
                  WHEN wl.min_inform_time IS NULL THEN
                   NULL
                  WHEN wl.min_inform_time <= 1 THEN
                   wl.min_inform_time || ' ' || pk_message.get_message(i_lang, 'COMMON_M092')
                  ELSE
                   wl.min_inform_time || ' ' || pk_message.get_message(i_lang, 'COMMON_M093')
              END desc_min_inform_time,
             CASE
                  WHEN wul.duration IS NOT NULL THEN
                   nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) || ' - ' ||
                   pk_admission_request.get_duration_desc(i_lang  => i_lang,
                                                          i_prof  => i_prof,
                                                          i_value => (wul.duration * 24))
              END desc_urg_level_duration
              FROM waiting_list wl
              LEFT JOIN wtl_urg_level wul
                ON wl.id_wtl_urg_level = wul.id_wtl_urg_level
              LEFT JOIN adm_request adm
                ON adm.id_dest_episode = i_episode_inp
            --INNER JOIN schedule_sr s ON wl.id_waiting_list = s.id_waiting_list
            -- José Brito 07/05/09 Show scheduling period when there's no surgery request
              LEFT JOIN schedule_sr s
                ON wl.id_waiting_list = s.id_waiting_list
             WHERE wl.id_waiting_list = i_id_waiting_list
               AND (s.id_episode = i_episode_sr OR i_episode_sr IS NULL);
    
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
    END get_sch_periods;

    /******************************************************************************
    *  returns list of professionals in this waiting list entry. 
    *  These professionals come from the requisition and are only of type surgeon or admitting physician
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_episode        filter by episode (null = all episodes)
    *  @param  i_flg_type          filter by type of professional (null = all types)
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_professionals     output
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_professionals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN epis_prof_rec.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_prof.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_professionals   OUT t_rec_professionals,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROFESSIONALS';
    BEGIN
    
        SELECT id_prof, flg_type
          BULK COLLECT
          INTO o_professionals
          FROM wtl_prof wtlp
         WHERE wtlp.id_waiting_list = i_id_waiting_list
           AND (i_id_episode IS NULL OR wtlp.id_episode = i_id_episode)
           AND (i_flg_type IS NULL OR wtlp.flg_type = i_flg_type)
           AND (i_all = g_yes OR wtlp.flg_status = g_active);
    
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
    END get_professionals;

    /******************************************************************************
    *  returns list of professionals in this waiting list entry. 
    *  These professionals come from the requisition and are only of type surgeon or admitting physician
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_episode        filter by episode (null = all episodes)
    *  @param  i_flg_type          filter by type of professional (null = all types)
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_professionals     output
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_professionals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN epis_prof_rec.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_prof.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_professionals   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROFESSIONALS';
    BEGIN
    
        OPEN o_professionals FOR
            SELECT wtlp.id_prof,
                   wtlp.flg_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, wtlp.id_prof) prof_name
              FROM wtl_prof wtlp
             WHERE wtlp.id_waiting_list = i_id_waiting_list
               AND (i_id_episode IS NULL OR wtlp.id_episode = i_id_episode)
               AND (i_flg_type IS NULL OR wtlp.flg_type = i_flg_type)
               AND (i_all = g_yes OR wtlp.flg_status = g_active);
    
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
            pk_types.open_my_cursor(o_professionals);
            RETURN FALSE;
    END get_professionals;

    /******************************************************************************
    *  returns list of professionals in this waiting list entry. 
    *  These professionals come from the requisition and are only of type surgeon or admitting physician
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_episode        filter by episode (null = all episodes)
    *  @param  i_flg_type          filter by type of professional (null = all types)
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      22-04-2009
    *
    ******************************************************************************/
    FUNCTION get_prof_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN epis_prof_rec.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_prof.flg_type%TYPE DEFAULT NULL
        
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_PROF_STRING';
        l_error     t_error_out;
        l_prof      VARCHAR2(2000) := NULL;
        l_first     BOOLEAN := TRUE;
    
    BEGIN
    
        FOR rec IN (SELECT wtlp.id_prof,
                           wtlp.flg_type,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, wtlp.id_prof) prof
                      FROM wtl_prof wtlp
                     WHERE wtlp.id_waiting_list = i_id_waiting_list
                       AND (i_id_episode IS NULL OR wtlp.id_episode = i_id_episode)
                       AND (i_flg_type IS NULL OR wtlp.flg_type = i_flg_type)
                       AND (wtlp.flg_status = g_active))
        LOOP
            IF l_first
            THEN
                l_prof  := rec.prof;
                l_first := FALSE;
            ELSE
                l_prof := l_prof || ', ' || rec.prof;
            END IF;
        END LOOP;
    
        RETURN l_prof;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_prof_string;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_episode        filter by episode (null = all episodes)
    *  @param  i_flg_type          filter by type (null = all types)
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_dcs               output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_dep_clin_servs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_dcs             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DEP_CLIN_SERVS';
    BEGIN
        OPEN o_dcs FOR
            SELECT dcs.id_dep_clin_serv,
                   wdcs.flg_type,
                   wdcs.id_episode,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv_desc,
                   s.id_speciality,
                   pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc,
                   d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) department_desc
              FROM wtl_dep_clin_serv wdcs
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = wdcs.id_dep_clin_serv
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
              LEFT JOIN department d
                ON d.id_department = wdcs.id_ward
              LEFT JOIN speciality s
                ON s.id_speciality = wdcs.id_prof_speciality
             WHERE wdcs.id_waiting_list = i_id_waiting_list
               AND wdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND (i_id_episode IS NULL OR wdcs.id_episode = i_id_episode)
               AND (i_flg_type IS NULL OR wdcs.flg_type = i_flg_type)
               AND (i_all = g_yes OR wdcs.flg_status = g_active);
    
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
            pk_types.open_my_cursor(o_dcs);
            RETURN FALSE;
    END get_dep_clin_servs;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_episode        filter by episode (null = all episodes)
    *  @param  i_flg_type          filter by type (null = all types)
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_dcs               output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_dep_clin_servs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_dep_clin_serv.flg_type%TYPE DEFAULT NULL,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_dcs             OUT t_rec_dcss,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DEP_CLIN_SERVS';
    BEGIN
        SELECT id_dep_clin_serv, flg_type, id_episode
          BULK COLLECT
          INTO o_dcs
          FROM wtl_dep_clin_serv s
         WHERE s.id_waiting_list = i_id_waiting_list
           AND (i_id_episode IS NULL OR s.id_episode = i_id_episode)
           AND (i_flg_type IS NULL OR s.flg_type = i_flg_type)
           AND (i_all = g_yes OR s.flg_status = g_active);
    
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
    END get_dep_clin_servs;

    /******************************************************************************
    *  returns clinical services string for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_id_episode        filter by episode (null = all episodes)
    *  @param  i_flg_type          filter by type (null = all types)
    *
    *  @return                     string width clinical services 
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_clin_servs_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_id_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_type        IN wtl_dep_clin_serv.flg_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_CLIN_SERVS_STRING';
        l_cs        VARCHAR2(2000) := NULL;
        l_first     BOOLEAN := TRUE;
        l_error     t_error_out;
    BEGIN
    
        FOR rec IN (SELECT wtls.id_dep_clin_serv,
                           wtls.flg_type,
                           wtls.id_episode,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) clin_serv
                      FROM wtl_dep_clin_serv wtls
                     INNER JOIN dep_clin_serv s
                        ON s.id_dep_clin_serv = wtls.id_dep_clin_serv
                     INNER JOIN clinical_service cs
                        ON cs.id_clinical_service = s.id_clinical_service
                     WHERE wtls.id_waiting_list = i_id_waiting_list
                       AND (i_id_episode IS NULL OR wtls.id_episode = i_id_episode)
                       AND (i_flg_type IS NULL OR wtls.flg_type = i_flg_type)
                       AND (wtls.flg_status = g_active))
        LOOP
            IF l_first
            THEN
                l_cs    := rec.clin_serv;
                l_first := FALSE;
            ELSE
                l_cs := l_cs || ', ' || rec.clin_serv;
            END IF;
        END LOOP;
    
        RETURN l_cs;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_clin_servs_string;

    /******************************************************************************
    *  returns list of surgical procedures in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  o_procedures        Surgical procedures
    *  @param  o_error             error data
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_surgical_procedures
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_wtlist                 IN table_number,
        o_procedures                OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_SURGICAL_PROCEDURES';
    
        l_id_sr_interv   table_number;
        l_question_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'PROCEDURES_T163');
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN o_procedures FOR
            SELECT wtle.id_waiting_list,
                   srei.id_episode,
                   srei.id_sr_epis_interv,
                   ic.standard_code,
                   sri.id_intervention,
                   srei.flg_status sr_epis_flg_status,
                   pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || sri.id_intervention,
                                                              NULL) ||
                   pk_procedures_utils.get_procedure_with_codification(i_lang, i_prof, NULL, ic.id_interv_codification) interv_desc,
                   ic.id_codification,
                   srei.laterality,
                   pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', srei.laterality, i_lang) laterality_desc,
                   srei.flg_type,
                   pk_sysdomain.get_domain('SR_EPIS_INTERV.FLG_TYPE', srei.flg_type, i_lang) l_desc_principal,
                   srei.surgical_site,
                   pk_message.get_message(i_lang, 'PROCEDURES_T189') surgical_site_desc,
                   ed.id_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9) diagnosis_desc,
                   ed.flg_status status_diagnosis,
                   ed.notes specific_notes,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => ed.id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   srei.notes sp_notes,
                   pk_supplies_external_api_db.get_supplies_request(i_lang,
                                                                    i_prof,
                                                                    srei.id_sr_epis_interv,
                                                                    pk_supplies_constant.g_context_surgery) desc_supplies,
                   (SELECT desc_interv
                      FROM sr_epis_interv_desc seid
                     WHERE seid.flg_type = pk_sr_planning.g_surg_interv
                       AND seid.flg_status != pk_sr_planning.g_interv_can
                       AND seid.id_sr_epis_interv_desc =
                           (SELECT MAX(seid2.id_sr_epis_interv_desc)
                              FROM sr_epis_interv_desc seid2
                             WHERE seid2.id_episode_context = srei.id_episode_context
                               AND seid2.id_sr_epis_interv = srei.id_sr_epis_interv)) desc_interv,
                   ed.flg_add_problem flg_add_problem_sp,
                   pk_sr_tools.get_sr_interv_team_name(i_lang, i_prof, srei.id_sr_epis_interv) desc_team,
                   pk_sr_tools.get_sr_interv_team(i_lang, i_prof, srei.id_episode_context, srei.id_sr_epis_interv) desc_compose_team,
                   (SELECT DISTINCT sptd.id_surgery_record
                      FROM sr_prof_team_det sptd
                     WHERE sptd.id_sr_epis_interv = srei.id_sr_epis_interv) id_surgery_record,
                   (SELECT DISTINCT sptd.id_prof_team
                      FROM sr_prof_team_det sptd
                     WHERE sptd.id_sr_epis_interv = srei.id_sr_epis_interv
                       AND sptd.flg_status != 'C') id_prof_team,
                   (CAST(MULTISET (SELECT sptd.id_professional
                            FROM sr_prof_team_det sptd
                           WHERE sptd.id_sr_epis_interv = srei.id_sr_epis_interv) AS table_number)) tbl_prof,
                   (CAST(MULTISET (SELECT c.id_category_sub
                            FROM sr_prof_team_det sptd, category_sub c
                           WHERE sptd.id_sr_epis_interv = srei.id_sr_epis_interv
                             AND sptd.id_category_sub = c.id_category_sub(+)) AS table_number)) tbl_catg,
                   (CAST(MULTISET (SELECT sptd.flg_status
                            FROM sr_prof_team_det sptd
                           WHERE sptd.id_sr_epis_interv = srei.id_sr_epis_interv) AS table_varchar)) tbl_status,
                   d.flg_other,
                   pk_sr_planning.get_surg_proc_mod_fact_desc(i_lang, i_prof, srei.id_sr_epis_interv, NULL) surg_proc_mod_fact_desc,
                   pk_sr_planning.get_surg_proc_mod_fact_ids(i_lang, i_prof, srei.id_sr_epis_interv, NULL) surg_proc_mod_fact_ids,
                   (CAST(MULTISET (SELECT sw.id_supply
                            FROM supply_workflow sw
                           WHERE sw.id_episode = srei.id_episode_context) AS table_number)) tbl_supplies
              FROM sr_epis_interv srei
             INNER JOIN intervention sri
                ON sri.id_intervention = srei.id_sr_intervention
              LEFT JOIN interv_codification ic
                ON srei.id_interv_codification = ic.id_interv_codification
             INNER JOIN wtl_epis wtle
                ON wtle.id_episode = srei.id_episode_context
              LEFT JOIN epis_diagnosis ed
                ON (srei.id_episode_context = ed.id_episode AND srei.id_epis_diagnosis = ed.id_epis_diagnosis)
              LEFT JOIN diagnosis d
                ON (d.id_diagnosis = ed.id_diagnosis)
              LEFT OUTER JOIN alert_diagnosis ad
                ON (ad.id_alert_diagnosis = ed.id_alert_diagnosis)
             WHERE wtle.id_waiting_list IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                             t.*
                                              FROM TABLE(i_id_wtlist) t)
                  --AND srei.flg_type = pk_sr_planning.g_epis_interv_type_p
               AND srei.flg_status <> pk_wtl_prv_core.g_sr_epis_interv_status_c
             ORDER BY wtle.id_waiting_list, srei.flg_type, ic.standard_code;
    
        BEGIN
            SELECT srei.id_sr_epis_interv
              BULK COLLECT
              INTO l_id_sr_interv
              FROM sr_epis_interv srei
             INNER JOIN intervention sri
                ON sri.id_intervention = srei.id_sr_intervention
              LEFT JOIN interv_codification ic
                ON sri.id_intervention = ic.id_intervention
             INNER JOIN wtl_epis wtle
                ON wtle.id_episode = srei.id_episode_context
             WHERE wtle.id_waiting_list IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                             t.*
                                              FROM TABLE(i_id_wtlist) t)
               AND srei.flg_type = pk_sr_planning.g_epis_interv_type_p
               AND srei.flg_status <> pk_wtl_prv_core.g_sr_epis_interv_status_c;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sr_interv := NULL;
        END;
    
        IF l_id_sr_interv IS NOT NULL
           AND l_id_sr_interv.count > 0
        THEN
            OPEN o_interv_clinical_questions FOR
                SELECT iqr.id_sr_epis_interv id_interv_presc_det,
                       iqr.id_questionnaire,
                       q.id_content,
                       iqr1.flg_time,
                       ipd.id_sr_intervention id_intervention,
                       pk_mcdt.get_questionnaire_alias(i_lang,
                                                       i_prof,
                                                       'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || iqr.id_questionnaire) desc_questionnaire,
                       iqr1.id_response id_response,
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
                       questionnaire q,
                       sr_epis_interv ipd
                 WHERE iqr1.rn = 1
                   AND iqr1.id_sr_epis_interv = iqr.id_sr_epis_interv
                   AND iqr1.id_questionnaire = iqr.id_questionnaire
                   AND iqr1.dt_last_update_tstz = iqr.dt_last_update_tstz
                   AND iqr.id_questionnaire = q.id_questionnaire
                   AND iqr.id_sr_epis_interv = ipd.id_sr_epis_interv;
        
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
                         WHERE sw.flg_status NOT IN
                               (pk_supplies_constant.g_sww_updated, pk_supplies_constant.g_sww_cancelled)
                           AND sw.id_supply_request IN
                               (SELECT sw.id_supply_request
                                  FROM waiting_list wl
                                  JOIN wtl_epis we
                                    ON we.id_waiting_list = wl.id_waiting_list
                                  JOIN supply_request sr
                                    ON sr.id_episode = we.id_episode
                                  JOIN supply_workflow sw
                                    ON sw.id_supply_request = sr.id_supply_request
                                 WHERE wl.id_waiting_list IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                                               t.*
                                                                FROM TABLE(i_id_wtlist) t))
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
            pk_types.open_my_cursor(o_procedures);
            RETURN FALSE;
    END get_surgical_procedures;

    /******************************************************************************
    *  returns string of surgical procedures in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     string width surgical procedures
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_surg_proc_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
    
        l_proc      VARCHAR2(2000) := NULL;
        l_func_name VARCHAR2(30) := 'GET_SURG_PROC_STRING';
        l_error     t_error_out;
    
    BEGIN
    
        g_error := 'GET SURG PROC STRING';
    
        SELECT pk_sr_clinical_info.get_proposed_surgery(i_lang, s.id_episode, i_prof, pk_alert_constant.g_no)
          INTO l_proc
          FROM schedule_sr s
         WHERE s.id_waiting_list = i_id_wtlist;
    
        RETURN l_proc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_surg_proc_string;

    /******************************************************************************
    *  returns string of surgical procedures id_content in this waiting list entry. 
    * Requested by scheduler 3. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     string width surgical procedures' id_content
    *
    *  @author                     Telmo
    *  @version                    2.6.0.3
    *  @since                      18-06-2010
    *
    ******************************************************************************/
    FUNCTION get_sr_proc_id_content_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_proc      VARCHAR2(4000) := NULL;
        l_func_name VARCHAR2(30) := 'GET_SR_PROC_ID_CONTENT_STRING';
        l_error     t_error_out;
    BEGIN
        g_error := 'GET SURG PROC STRING';
    
        SELECT pk_sr_clinical_info.get_surgeries_id_content(i_lang, i_prof, s.id_episode)
          INTO l_proc
          FROM schedule_sr s
         WHERE s.id_waiting_list = i_id_wtlist;
    
        RETURN l_proc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
    END get_sr_proc_id_content_string;

    /******************************************************************************
    *  returns list of preferred time in this waiting list entries. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_flg_status        status flag A 
    *  @param  o_preferred_time    preferred time
    *  @param  o_error             error data
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      21-04-2009
    *
    ******************************************************************************/
    FUNCTION get_preferred_time
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_wtlist      IN table_number,
        i_flg_status     IN VARCHAR2 DEFAULT 'A',
        o_preferred_time OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PREFERRED_TIME';
    BEGIN
        g_error := 'OPEN CURSOR';
    
        OPEN o_preferred_time FOR
            SELECT prf.id_wtl_pref_time,
                   prf.flg_value,
                   (SELECT pk_sysdomain.get_domain('WTL_PREF_TIME.FLG_VALUE', prf.flg_value, i_lang)
                      FROM dual) pref_time_desc
              FROM wtl_pref_time prf
             WHERE prf.id_waiting_list IN (SELECT *
                                             FROM TABLE(i_id_wtlist))
               AND prf.flg_status = i_flg_status
             ORDER BY 1;
    
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
            pk_types.open_my_cursor(o_preferred_time);
            RETURN FALSE;
    END get_preferred_time;

    /******************************************************************************
    *  returns string of preferred time in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     string with preferred time
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      21-04-2009
    *
    ******************************************************************************/
    FUNCTION get_pref_time_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_preferred_time VARCHAR2(2000) := NULL;
        l_first          BOOLEAN := TRUE;
        l_func_name      VARCHAR2(30) := 'GET_PREF_TIME_STRING';
        l_error          t_error_out;
    BEGIN
        g_error := 'PREFERRED TIME STRING';
        FOR rec IN (SELECT prf.id_waiting_list,
                           prf.flg_value,
                           pk_sysdomain.get_domain('WTL_PREF_TIME.FLG_VALUE', prf.flg_value, i_lang) desc_pref_time
                      FROM wtl_pref_time prf
                     WHERE prf.id_waiting_list = i_id_wtlist
                       AND prf.flg_status = g_active)
        LOOP
            IF l_first
            THEN
                l_preferred_time := rec.desc_pref_time;
                l_first          := FALSE;
            ELSE
                l_preferred_time := l_preferred_time || ', ' || rec.desc_pref_time;
            END IF;
        END LOOP;
    
        RETURN l_preferred_time;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_pref_time_string;

    /******************************************************************************
    *  returns list of preferred time reasons in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_flg_status        status flag A 
    *  @param  o_pref_time_reason  reasons for preferred time
    *  @param  o_error             error data
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      21-04-2009
    *
    ******************************************************************************/
    FUNCTION get_ptime_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_wtlist        IN waiting_list.id_waiting_list%TYPE,
        i_flg_status       IN VARCHAR2 DEFAULT 'A',
        o_pref_time_reason OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PTIME_REASON';
    BEGIN
        g_error := 'OPEN CURSOR';
    
        OPEN o_pref_time_reason FOR
            SELECT pftr.id_wtl_ptreason, pk_translation.get_translation(i_lang, wp.code) pref_time_reason_desc
              FROM wtl_ptreason_wtlist pftr, wtl_ptreason wp
             WHERE pftr.id_wtl_ptreason = wp.id_wtl_ptreason
               AND pftr.id_waiting_list = i_id_wtlist
               AND pftr.flg_status = i_flg_status
             ORDER BY 1;
    
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
            pk_types.open_my_cursor(o_pref_time_reason);
            RETURN FALSE;
    END get_ptime_reason;

    /******************************************************************************
    *  returns string of reasons for preferred time in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     String with reason for preferred time 
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      21-04-2009
    *
    ******************************************************************************/
    FUNCTION get_ptime_reason_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_ptime_reason VARCHAR2(2000) := NULL;
        l_first        BOOLEAN := TRUE;
        l_func_name    VARCHAR2(30) := 'GET_PTIME_REASON_STRING';
        l_error        t_error_out;
    BEGIN
        g_error := 'PREFERRED TIME REASON STRING';
        FOR rec IN (SELECT pk_translation.get_translation(i_lang, ptr.code) desc_pref_time
                      FROM wtl_ptreason_wtlist ptrw
                     INNER JOIN wtl_ptreason ptr
                        ON ptr.id_wtl_ptreason = ptrw.id_wtl_ptreason
                     WHERE ptrw.id_waiting_list = i_id_wtlist
                       AND ptrw.flg_status = pk_alert_constant.g_active)
        LOOP
            IF l_first
            THEN
                l_ptime_reason := rec.desc_pref_time;
                l_first        := FALSE;
            ELSE
                l_ptime_reason := l_ptime_reason || ', ' || rec.desc_pref_time;
            END IF;
        END LOOP;
    
        RETURN l_ptime_reason;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_ptime_reason_string;

    /******************************************************************************
    *  returns main data for an entry.
    *
    *  @param  i_lang               Language ID
    *  @param  i_prof               Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list    ID of the waiting list request
    *  @param  o_id_patient         patient id
    *  @param  o_flg_type           flg type
    *  @param  o_flg_status         status
    *  @param  o_dpb                dont perform before
    *  @param  o_dpa                dont perform after
    *  @param  o_dt_surgery         date surgery
    *  @param  o_min_inform_time    minimum inform type
    *  @param  o_id_urgency_lev     urgency level
    *  @param  o_error              error data 
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      17-04-2009
    *
    ******************************************************************************/
    FUNCTION get_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN waiting_list.id_waiting_list%TYPE,
        o_id_patient          OUT waiting_list.id_patient%TYPE,
        o_flg_type            OUT waiting_list.flg_type%TYPE,
        o_flg_status          OUT waiting_list.flg_status%TYPE,
        o_dpb                 OUT waiting_list.dt_dpb%TYPE,
        o_dpa                 OUT waiting_list.dt_dpa%TYPE,
        o_dt_surgery          OUT waiting_list.dt_surgery%TYPE,
        o_min_inform_time     OUT waiting_list.min_inform_time%TYPE,
        o_id_urgency_lev      OUT waiting_list.id_wtl_urg_level%TYPE,
        o_id_external_request OUT waiting_list.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WL_DATA';
    BEGIN
        g_error := 'get data';
        SELECT id_patient,
               flg_type,
               flg_status,
               dt_dpb,
               dt_dpa,
               dt_surgery,
               min_inform_time,
               id_wtl_urg_level,
               id_external_request
          INTO o_id_patient,
               o_flg_type,
               o_flg_status,
               o_dpb,
               o_dpa,
               o_dt_surgery,
               o_min_inform_time,
               o_id_urgency_lev,
               o_id_external_request
          FROM waiting_list
         WHERE id_waiting_list = i_id_waiting_list;
    
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
    END get_data;

    /******************************************************************************
    *  check and update the waiting list status 
    *  update placement date if status change from Inactive to Active  
    * 
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting list ID
    *  @param  o_error             Error data  
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5.0.2
    *  @since                      2009/04/16
    *
    ******************************************************************************/
    FUNCTION check_wtlist_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_wtlist  IN waiting_list.id_waiting_list%TYPE,
        i_adm_needed IN schedule_sr.adm_needed%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name        VARCHAR2(30) := 'CHECK_WTLIST_STATUS';
        l_status_old       waiting_list.flg_status%TYPE;
        l_status_new       waiting_list.flg_status%TYPE;
        l_dt_placement     waiting_list.dt_placement%TYPE;
        l_new_dt_placement waiting_list.dt_placement%TYPE;
        l_id_wtlist        waiting_list.id_waiting_list%TYPE;
        l_syscfg_val       sys_config.value%TYPE;
    BEGIN
    
        g_error := 'GET WAITING LIST STATUS';
        SELECT wtl.flg_status, wtl.dt_placement
          INTO l_status_old, l_dt_placement
          FROM waiting_list wtl
         WHERE wtl.id_waiting_list = i_id_wtlist;
    
        g_error := 'GET WAITING LIST NEW STATUS';
    
        IF NOT pk_wtl_prv_core.get_wtlist_status(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_wtlist  => i_id_wtlist,
                                                 i_adm_needed => i_adm_needed,
                                                 o_status     => l_status_new,
                                                 o_error      => o_error)
        THEN
            RETURN FALSE;
        ELSE
            g_error := 'UPDATE WAITING LIST STATUS';
        
            l_id_wtlist := i_id_wtlist;
            IF NOT set_waiting_list(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    flg_status_in      => l_status_new,
                                    id_waiting_list_io => l_id_wtlist,
                                    o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF (l_status_old = pk_wtl_prv_core.g_wtlist_status_inactive AND
               l_status_new IN (pk_wtl_prv_core.g_wtlist_status_active,
                                 pk_wtl_prv_core.g_wtlist_status_schedule,
                                 pk_wtl_prv_core.g_wtlist_status_partial))
            THEN
                g_error := 'UPD PLACEMENT DATE';
            
                l_syscfg_val := pk_sysconfig.get_config(i_code_cf => 'FLG_WTL_DT_PLACEMENT_ORIG', i_prof => i_prof);
            
                IF l_syscfg_val = pk_alert_constant.g_yes
                   AND l_dt_placement IS NOT NULL
                THEN
                    l_new_dt_placement := NULL; --to keep the original dt_placement
                ELSE
                    l_new_dt_placement := current_timestamp; --new dt_placement
                END IF;
            
                l_id_wtlist := i_id_wtlist;
                IF NOT set_waiting_list(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        dt_placement_in    => l_new_dt_placement,
                                        id_waiting_list_io => l_id_wtlist,
                                        o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    
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
        
    END check_wtlist_status;

    /******************************************************************************
    *  Set placement date on the waiting list entry
    *  update new date if the waiting list status changes from Inactive to Active
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting list ID
    *  @param  o_error             error data  
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5.0.2
    *  @since                      2009/04/28
    *
    ******************************************************************************/
    FUNCTION set_placement_date
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name        VARCHAR2(30) := 'SET_PLACEMENT_DATE';
        l_wtlist_type      waiting_list.flg_type%TYPE;
        l_wtlist_status    waiting_list.flg_status%TYPE;
        l_dt_placement     waiting_list.dt_placement%TYPE;
        l_new_dt_placement waiting_list.dt_placement%TYPE;
        l_flg_valid        VARCHAR(1);
        l_id_wtlist        waiting_list.id_waiting_list%TYPE;
        l_syscfg_val       sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'GET WAITING LIST TYPE AND STATUS';
        SELECT wtl.flg_type, wtl.flg_status, wtl.dt_placement
          INTO l_wtlist_type, l_wtlist_status, l_dt_placement
          FROM waiting_list wtl
         WHERE wtl.id_waiting_list = i_id_wtlist;
    
        IF (l_wtlist_status = pk_wtl_prv_core.g_wtlist_status_inactive)
        THEN
            g_error := 'READY TO WAITING LIST';
            IF NOT pk_wtl_prv_core.get_ready_to_wtlist(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_wtlist        => i_id_wtlist,
                                                       i_flg_type         => l_wtlist_type,
                                                       i_pos_confirmation => pk_alert_constant.g_yes,
                                                       o_flg_valid        => l_flg_valid,
                                                       o_error            => o_error)
            THEN
                RETURN FALSE;
            ELSE
                IF (l_flg_valid = pk_alert_constant.g_yes)
                THEN
                    g_error := 'UPD PLACEMENT DATE';
                
                    l_syscfg_val := pk_sysconfig.get_config(i_code_cf => 'FLG_WTL_DT_PLACEMENT_ORIG', i_prof => i_prof);
                
                    IF l_syscfg_val = pk_alert_constant.g_yes
                       AND l_dt_placement IS NOT NULL
                    THEN
                        l_new_dt_placement := NULL; --to keep the original dt_placement
                    ELSE
                        l_new_dt_placement := current_timestamp; --new dt_placement
                    END IF;
                
                    l_id_wtlist := i_id_wtlist;
                    IF NOT set_waiting_list(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            dt_placement_in    => l_new_dt_placement,
                                            id_waiting_list_io => l_id_wtlist,
                                            o_error            => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
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
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_placement_date;

    /******************************************************************************
    *  mark/update a waiting list entry as scheduled and check the waiting list status
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting list ID
    *  @param  i_id_episode        Episode ID
    *  @param  i_id_schedule       Schedule ID
    *  @param  o_error             error data  
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5.0.2
    *  @since                      2009/04/16
    *
    ******************************************************************************/
    FUNCTION set_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_wtlist   IN waiting_list.id_waiting_list%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'SET_SCHEDULE';
        l_rowids    table_varchar;
    
    BEGIN
        g_error := 'CALL set_wtl_epis_hist. i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_prv_core.set_wtl_epis_hist(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_episode       => i_id_episode,
                                                 i_id_waiting_list  => NULL,
                                                 i_dt_wtl_epis_hist => current_timestamp,
                                                 o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- update id_schedule através do i_id_wtlist e/ou do id_episode
        g_error := 'UPDATE EPIS_WAITING_LIST';
    
        ts_wtl_epis.upd(id_schedule_in => i_id_schedule,
                        flg_status_in  => pk_wtl_prv_core.g_wtl_epis_st_schedule,
                        where_in       => '(id_waiting_list =' || i_id_wtlist || 'AND id_episode =' || i_id_episode || ')
            OR (' || i_id_episode || ' IS NULL AND id_waiting_list =' ||
                                          i_id_wtlist || ')',
                        rows_out       => l_rowids);
    
        g_error := 'CHECK WAITING LIST STATUS';
        IF NOT check_wtlist_status(i_lang => i_lang, i_prof => i_prof, i_id_wtlist => i_id_wtlist, o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
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
            -- pk_alert_exceptions.reset_error_state;
            -- o undo_changes é feito pela função que invoca esta
            -- pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    /**************************************************************************
    * Calculates the sum of an epis documentation scale (Eg. Barthel Index)   *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_waiting_list             waiting list id                       *
    *                                                                         *
    * @param o_scale_sum                Cursor with doc scale summary         *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/05                            *
    **************************************************************************/
    FUNCTION get_scale_summ
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_waiting_list IN wtl_documentation.id_waiting_list%TYPE,
        o_scale_sum    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_scale_sum';
        OPEN o_scale_sum FOR
            SELECT t.id_epis_documentation id_epis_documentation,
                   t.id_scales,
                   t.id_doc_template,
                   decode(t.score_value,
                          NULL,
                          NULL,
                          t.score_value || ' ' || pk_translation.get_translation(i_lang, t.code_scale_score) || ' - ' ||
                          pk_translation.get_translation(i_lang,
                                                         pk_inp_nurse.get_scales_class(i_lang,
                                                                                       i_prof,
                                                                                       t.score_value,
                                                                                       t.id_scales,
                                                                                       t.id_episode,
                                                                                       pk_alert_constant.g_scope_type_episode))) desc_class,
                   decode(t.score_value,
                          NULL,
                          NULL,
                          t.score_value || ' ' || pk_translation.get_translation(i_lang, t.code_scale_score) || ' ' ||
                          decode(pk_translation.get_translation(i_lang,
                                                                'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || t.id_doc_template),
                                 NULL,
                                 NULL,
                                 '(') ||
                          pk_translation.get_translation(i_lang, 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || t.id_doc_template) ||
                          decode(pk_translation.get_translation(i_lang,
                                                                'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || t.id_doc_template),
                                 NULL,
                                 NULL,
                                 ')') || chr(10) ||
                          pk_translation.get_translation(i_lang,
                                                         pk_inp_nurse.get_scales_class(i_lang,
                                                                                       i_prof,
                                                                                       t.score_value,
                                                                                       t.id_scales,
                                                                                       t.id_episode,
                                                                                       pk_alert_constant.g_scope_type_episode))) doc_desc_class,
                   t.score_value soma,
                   t.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) nick_name,
                   pk_date_utils.dt_chr_tsz(i_lang, t.dt_last_update_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, t.dt_last_update_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_last_update_tstz, i_prof) dt_last_update
              FROM (SELECT eb.id_epis_documentation,
                           s.id_scales,
                           ess.score_value,
                           s.code_scale_score,
                           eb.id_episode,
                           eb.id_doc_template,
                           eb.id_professional,
                           eb.dt_last_update_tstz
                      FROM epis_documentation eb
                     INNER JOIN wtl_documentation wd
                        ON wd.id_epis_documentation = eb.id_epis_documentation
                     INNER JOIN epis_scales_score ess
                        ON ess.id_epis_documentation = eb.id_epis_documentation
                     INNER JOIN scales s
                        ON s.id_scales = ess.id_scales
                     WHERE wd.id_waiting_list = i_waiting_list
                    UNION ALL
                    SELECT eb.id_epis_documentation,
                           s.id_scales,
                           ess.score_value,
                           s.code_scale_score,
                           eb.id_episode,
                           eb.id_doc_template,
                           eb.id_professional,
                           eb.dt_last_update_tstz
                      FROM epis_documentation eb
                     INNER JOIN wtl_documentation wd
                        ON wd.id_epis_documentation = eb.id_epis_documentation
                     INNER JOIN epis_scales_score_hist ess
                        ON ess.id_epis_documentation = eb.id_epis_documentation
                     INNER JOIN scales s
                        ON s.id_scales = ess.id_scales
                     WHERE wd.id_waiting_list = i_waiting_list) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_scale_summ',
                                              o_error);
            pk_types.open_my_cursor(o_scale_sum);
            RETURN FALSE;
    END get_scale_summ;

    /**************************************************************************
    * Calculates the sum of an epis documentation scale (Eg. Barthel Index)   *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_waiting_list             waiting list id                       *
    *                                                                         *
    * @param o_scale_sum                Cursor with doc scale summary         *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/05                            *
    **************************************************************************/
    FUNCTION get_scale_summ
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_waiting_list IN wtl_documentation.id_waiting_list%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(32) := 'GET_SCALE_SUMM';
        l_scale_sum pk_types.cursor_type;
        l_number24  NUMBER(24);
        l_varchar2  VARCHAR2(4000);
        l_summ      NUMBER(24);
        l_error     t_error_out;
    
        wtl_exception EXCEPTION;
    BEGIN
        g_error := 'OPEN o_scale_sum';
        IF NOT get_scale_summ(i_lang         => i_lang,
                              i_prof         => i_prof,
                              i_waiting_list => i_waiting_list,
                              o_scale_sum    => l_scale_sum,
                              o_error        => l_error)
        THEN
            RAISE wtl_exception;
        END IF;
    
        LOOP
            FETCH l_scale_sum
                INTO l_number24,
                     l_number24,
                     l_number24,
                     l_varchar2,
                     l_varchar2,
                     l_summ,
                     l_number24,
                     l_varchar2,
                     l_varchar2,
                     l_varchar2,
                     l_varchar2;
            EXIT WHEN l_scale_sum%NOTFOUND;
        END LOOP;
    
        RETURN l_summ;
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
    END get_scale_summ;

    /**************************************************************************
    * Cancels a record in WTL_DOCUMENTATION by updating flg_status to 'I'     *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_waiting_list             waiting list id                       *
    * @param i_epis_documentation       epis documentation id                 *
    *                                                                         *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.1                                   *
    * @since                            2010/03/05                            *
    **************************************************************************/
    FUNCTION manage_wtl_func_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_waiting_list       IN wtl_documentation.id_waiting_list%TYPE,
        i_epis_documentation IN wtl_documentation.id_epis_documentation%TYPE,
        i_wtl_change         IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'MANAGE_WTL_FUNC_EVAL';
        l_rowids           table_varchar;
        l_rowids_upd_final table_varchar := table_varchar();
        l_rowids_ins_final table_varchar := table_varchar();
    
        l_flg_val            VARCHAR2(1);
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        l_summ               NUMBER(24);
        l_epis_doc_count     NUMBER(24);
    
        wtl_exception EXCEPTION;
    
        CURSOR c_list_wtl IS
            SELECT wtl.id_waiting_list, wtl.flg_status, wtl.id_patient
              FROM waiting_list wtl
             WHERE wtl.id_patient = (SELECT wtl.id_patient
                                       FROM waiting_list wtl
                                      WHERE wtl.id_waiting_list = i_waiting_list)
               AND pk_surgery_request.get_wtl_started_state(i_lang, wtl.id_waiting_list) = pk_alert_constant.g_no
               AND ((nvl(i_wtl_change, pk_alert_constant.g_no) = pk_alert_constant.g_no AND
                   wtl.flg_status IN
                   (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_inactive)) OR
                   (nvl(i_wtl_change, pk_alert_constant.g_no) = pk_alert_constant.g_yes AND
                   wtl.flg_status IN (pk_wtl_prv_core.g_wtlist_status_active,
                                        pk_wtl_prv_core.g_wtlist_status_schedule,
                                        pk_wtl_prv_core.g_wtlist_status_partial,
                                        pk_wtl_prv_core.g_wtlist_status_inactive)));
    
    BEGIN
        g_error := 'OPEN c_list_wtl';
        FOR r_list_wtl IN c_list_wtl
        LOOP
            g_error  := 'UPDATE wtl_documentation for id_waiting_list: ' || r_list_wtl.id_waiting_list;
            l_rowids := table_varchar();
            ts_wtl_documentation.upd(flg_status_in => g_inactive,
                                     where_in      => 'flg_status != ''' || g_inactive || ''' AND id_waiting_list = ' ||
                                                      r_list_wtl.id_waiting_list,
                                     rows_out      => l_rowids);
        
            l_rowids_upd_final := l_rowids_upd_final MULTISET UNION l_rowids;
        
            IF (i_epis_documentation IS NOT NULL)
            THEN
                g_error := 'Insert wtl_documentation record for id_waiting_list: ' || r_list_wtl.id_waiting_list ||
                           ' and id_epis_documentation_in: ' || i_epis_documentation;
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            
                l_rowids := table_varchar();
                ts_wtl_documentation.ins(id_waiting_list_in       => r_list_wtl.id_waiting_list,
                                         id_epis_documentation_in => i_epis_documentation,
                                         flg_type_in              => g_wtl_doc_flg_barthel_idx,
                                         flg_status_in            => CASE
                                                                         WHEN r_list_wtl.flg_status IN
                                                                              (pk_alert_constant.g_wl_status_s,
                                                                               pk_alert_constant.g_wl_status_p) THEN
                                                                          g_wtl_doc_flg_active
                                                                         ELSE
                                                                          g_wtl_doc_flg_pending
                                                                     END,
                                         rows_out                 => l_rowids);
            
                l_rowids_ins_final := l_rowids_ins_final MULTISET UNION l_rowids;
            
                --Update waiting_list.func_eval_score with barthel idx score
                l_summ := get_scale_summ(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_waiting_list => r_list_wtl.id_waiting_list);
            
                IF NOT set_waiting_list(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        func_eval_score    => l_summ,
                                        id_waiting_list_io => r_list_wtl.id_waiting_list,
                                        o_error            => o_error)
                THEN
                    RAISE wtl_exception;
                END IF;
            ELSE
                g_error := 'Get last valid id_epis_documentation';
                IF NOT check_wtl_func_eval_pat(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_patient            => r_list_wtl.id_patient,
                                               o_flg_val            => l_flg_val,
                                               o_last_epis_doc      => l_last_epis_doc,
                                               o_last_date_epis_doc => l_last_date_epis_doc,
                                               o_epis_doc_count     => l_epis_doc_count,
                                               o_error              => o_error)
                THEN
                    RAISE wtl_exception;
                END IF;
            
                IF (l_last_epis_doc IS NOT NULL)
                THEN
                    g_error := '2# Insert wtl_documentation record for id_waiting_list: ' || r_list_wtl.id_waiting_list ||
                               ' and id_epis_documentation_in: ' || l_last_epis_doc;
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                
                    l_rowids := table_varchar();
                    ts_wtl_documentation.ins(id_waiting_list_in       => r_list_wtl.id_waiting_list,
                                             id_epis_documentation_in => l_last_epis_doc,
                                             flg_type_in              => g_wtl_doc_flg_barthel_idx,
                                             flg_status_in            => CASE r_list_wtl.flg_status
                                                                             WHEN g_wtle_stat_sched THEN
                                                                              g_wtl_doc_flg_pending
                                                                             ELSE
                                                                              g_wtl_doc_flg_active
                                                                         END,
                                             rows_out                 => l_rowids);
                
                    l_rowids_ins_final := l_rowids_ins_final MULTISET UNION l_rowids;
                
                    --Update waiting_list.func_eval_score with barthel idx score
                    l_summ := get_scale_summ(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_waiting_list => r_list_wtl.id_waiting_list);
                
                    IF NOT set_waiting_list(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            func_eval_score    => l_summ,
                                            id_waiting_list_io => r_list_wtl.id_waiting_list,
                                            o_error            => o_error)
                    THEN
                        RAISE wtl_exception;
                    END IF;
                END IF;
            END IF;
        
            IF (nvl(i_wtl_change, pk_alert_constant.g_no) = pk_alert_constant.g_yes AND
               --r_list_wtl.id_waiting_list != i_waiting_list AND
               r_list_wtl.flg_status IN
               (pk_wtl_prv_core.g_wtlist_status_schedule, pk_wtl_prv_core.g_wtlist_status_partial))
            THEN
                g_error := 'CREATE THE SYS_ALERT for id_patient : ' || r_list_wtl.id_patient;
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT set_wtl_func_eval_alert(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_patient => r_list_wtl.id_patient,
                                               i_epis_doc   => i_epis_documentation,
                                               i_id_wtlist  => r_list_wtl.id_waiting_list,
                                               o_error      => o_error)
                THEN
                    RAISE wtl_exception;
                END IF;
            END IF;
        
            IF NOT check_wtlist_status(i_lang      => i_lang,
                                       i_prof      => i_prof,
                                       i_id_wtlist => r_list_wtl.id_waiting_list,
                                       o_error     => o_error)
            THEN
                RAISE wtl_exception;
            END IF;
        END LOOP;
    
        IF (l_rowids_upd_final.count > 0)
        THEN
            g_error := 'PROCESS_UPDATE wtl_documentation';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'WTL_DOCUMENTATION',
                                          i_rowids       => l_rowids_upd_final,
                                          i_list_columns => table_varchar('FLG_STATUS'),
                                          o_error        => o_error);
        END IF;
    
        IF (l_rowids_ins_final.count > 0)
        THEN
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'WTL_DOCUMENTATION',
                                          i_rowids     => l_rowids_ins_final,
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END manage_wtl_func_eval;

    /******************************************************************************
    *  Cancel the schedule from a waiting list entry
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting list ID
    *  @param  i_id_schedule       Schedule ID
    *  @param  o_error               
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5.0.2
    *  @since                      2009/04/16
    *
    ******************************************************************************/
    FUNCTION cancel_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_wtlist   IN waiting_list.id_waiting_list%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'CANCEL_SCHEDULE';
        l_rowids    table_varchar;
    
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL set_wtl_epis_hist. i_id_waiting_list: ' || i_id_wtlist;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_prv_core.set_wtl_epis_hist(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_episode       => NULL,
                                                 i_id_waiting_list  => i_id_wtlist,
                                                 i_dt_wtl_epis_hist => current_timestamp,
                                                 o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- update id_schedule através do i_id_wtlist e/ou do i_id_schedule
        g_error := 'UPDATE EPIS_WAITING_LIST';
    
        ts_wtl_epis.upd( --id_schedule_in => NULL,
                        flg_status_in => pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule,
                        where_in      => '(id_waiting_list =' || i_id_wtlist || ' AND id_schedule =' || i_id_schedule || ')
            OR (' || i_id_schedule || ' IS NULL AND id_waiting_list =' ||
                                         i_id_wtlist || ')',
                        rows_out      => l_rowids);
    
        IF NOT manage_wtl_func_eval(i_lang               => i_lang,
                                    i_prof               => i_prof,
                                    i_waiting_list       => i_id_wtlist,
                                    i_epis_documentation => NULL,
                                    i_wtl_change         => pk_alert_constant.g_no,
                                    o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CHECK WAITING LIST STATUS';
        IF NOT check_wtlist_status(i_lang => i_lang, i_prof => i_prof, i_id_wtlist => i_id_wtlist, o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
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
            -- o undo_changes é feito pela função que invoca esta
            -- pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /******************************************************************************
    *  patient attributes search function 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_bsn               search field: BSN number
    *  @param  i_ssn               search field: social security number
    *  @param  i_nhn               search field: national health record
    *  @param  i_recnum            search field: record number
    *  @param  i_birthdate         search field: birth date
    *  @param  i_gender            search field: gender
    *  @param  i_surnameprefix     search field: surname prefix
    *  @param  i_surnamemaiden     search field: maiden surname
    *  @param  i_names             search field: name
    *  @param  i_initials          search field: initials
    *  @param  o_list              output list   
    *  @param  o_error             error info 
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      26-10-2009
    ******************************************************************************/
    FUNCTION search_patient
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_bsn           IN v_patient_all_markets.bsn%TYPE,
        i_ssn           IN v_patient_all_markets.social_security_number%TYPE,
        i_nhn           IN v_patient_all_markets.social_security_number%TYPE,
        i_recnum        IN v_patient_all_markets.alert_process_number%TYPE,
        i_birthdate     IN VARCHAR2, -- alert_adtcod.patient.dt_birth%TYPE,
        i_gender        IN v_patient_all_markets.gender%TYPE,
        i_surnameprefix IN v_patient_all_markets.surname_prefix%TYPE,
        i_surnamemaiden IN v_patient_all_markets.surname_maiden%TYPE,
        i_names         IN v_patient_all_markets.name%TYPE,
        i_initials      IN v_patient_all_markets.initials%TYPE,
        i_min_age       IN NUMBER DEFAULT NULL,
        i_max_age       IN NUMBER DEFAULT NULL,
        o_list          OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SEARCH_PATIENT';
    
        l_tbl_institutions table_number;
    BEGIN
    
        SELECT column_value
          BULK COLLECT
          INTO l_tbl_institutions
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_adt.g_inst_grp_flg_rel_adt)) t;
    
        g_error := 'SEARCH PATIENT';
        SELECT DISTINCT pam.id_patient
          BULK COLLECT
          INTO o_list
          FROM v_patient_all_markets pam
          JOIN episode e
            ON pam.id_patient = e.id_patient
         WHERE
        -- pesquisa por BSN
         (i_bsn IS NULL OR pam.bsn = i_bsn)
        -- pesquisa por SSN
         AND (TRIM(i_ssn) IS NULL OR pam.social_security_number LIKE '%' || TRIM(i_ssn) || '%')
        -- pesquisa por NHN
         AND (TRIM(i_nhn) IS NULL OR pam.national_health_number LIKE '%' || TRIM(i_nhn) || '%')
        -- pesquisa por RECORD NUMBER
         AND (TRIM(i_recnum) IS NULL OR pam.alert_process_number LIKE TRIM(i_recnum) || '%')
        -- pesquisa por birthdate (i_birthdate tem de estar na forma YYYYMMDDhh24miss)
         AND (i_birthdate IS NULL OR pam.dt_birth = to_date(i_birthdate, 'YYYYMMDDhh24miss'))
        -- pesquisa por gender
         AND (i_gender IS NULL OR pam.gender = i_gender)
        -- pesquisa por surname prefix
         AND (TRIM(i_surnameprefix) IS NULL OR
         translate(upper(pk_patient.get_pat_name(i_lang, i_prof, pam.id_patient, e.id_episode)),
                    'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                    'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
         '%' || translate(upper(TRIM(i_surnameprefix)), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%')
        -- pesquisa por surname maiden
         AND (TRIM(i_surnamemaiden) IS NULL OR
         translate(upper(pk_patient.get_pat_name(i_lang, i_prof, pam.id_patient, e.id_episode)),
                    'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                    'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
         '%' || translate(upper(TRIM(i_surnamemaiden)), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%')
        -- pesquisa por name
         AND (TRIM(i_names) IS NULL OR
         translate(upper(pk_patient.get_pat_name(i_lang, i_prof, pam.id_patient, e.id_episode)),
                    'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                    'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
         '%' || translate(upper(TRIM(i_names)), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%')
        -- pesquisa por initials         
         AND (TRIM(i_initials) IS NULL OR
         pk_patient.get_pat_name(i_lang, i_prof, pam.id_patient, e.id_episode) LIKE '%' || TRIM(i_initials) || '%')
        -- id_institution
         AND pam.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(l_tbl_institutions) t)
         AND e.flg_status = pk_alert_constant.g_active
         AND e.id_epis_type IN (pk_alert_constant.g_epis_type_operating, pk_alert_constant.g_epis_type_inpatient)
         AND e.flg_ehr = pk_alert_constant.g_epis_ehr_schedule
         AND (i_min_age IS NULL OR (trunc((SYSDATE - pam.dt_birth) / 365) >= i_min_age))
         AND (i_max_age IS NULL OR (trunc((SYSDATE - pam.dt_birth) / 365) <= i_max_age));
    
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
    END search_patient;

    /******************************************************************************
    *  patient attributes search function specific for NL market. For other markets 
    *  similar functions are needed since there are other tables and logic 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_bsn               search field: BSN number
    *  @param  i_ssn               search field: social security number
    *  @param  i_recnum            search field: record number
    *  @param  i_birthdate         search field: birth date
    *  @param  i_gender            search field: gender
    *  @param  i_surnameprefix     search field: surname prefix
    *  @param  i_surnamemaiden     search field: maiden surname
    *  @param  i_names             search field: name
    *  @param  i_initials          search field: initials
    *  @param  o_list              output list   
    *  @param  o_error             error info 
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      23-04-2009
    ******************************************************************************/
    FUNCTION search_patient_nl
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN alert_adtcod.patient.id_patient%TYPE,
        i_bsn           IN alert_adtcod.patient.bsn%TYPE,
        i_ssn           IN alert_adtcod.person.social_security_number%TYPE,
        i_recnum        IN alert_adtcod.pat_identifier.alert_process_number%TYPE,
        i_birthdate     IN VARCHAR2, -- alert_adtcod.patient.dt_birth%TYPE,
        i_gender        IN alert_adtcod.patient.gender%TYPE,
        i_surnameprefix IN alert_adtcod.patient.surname_prefix%TYPE,
        i_surnamemaiden IN alert_adtcod.person.surname_maiden%TYPE,
        i_names         IN alert_adtcod.patient.name%TYPE,
        i_initials      IN alert_adtcod.patient.initials%TYPE,
        o_list          OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SEARCH_PATIENT_NL';
    BEGIN
        g_error := 'SEARCH PATIENT_NL';
        SELECT p.id_patient
          BULK COLLECT
          INTO o_list
          FROM alert_adtcod.patient p
          JOIN alert_adtcod.person prs
            ON p.id_person = prs.id_person
        -- PARA QUE A PESQUISA ENCONTRE O PATIENT PT
        -- FROM alert_adtcod.patient_nl pnl
        -- JOIN alert_adtcod.patient p ON pnl.id_patient_nl = p.id_patient
         WHERE
        -- pesquisa por patient id
         (i_id_pat IS NULL OR p.id_patient = i_id_pat)
        -- pesquisa por BSN
         AND (i_bsn IS NULL OR p.bsn = i_bsn)
        -- pesquisa por SSN
         AND (TRIM(i_ssn) IS NULL OR prs.social_security_number LIKE '%' || TRIM(i_ssn) || '%')
        -- pesquisa por RECORD NUMBER
         AND (TRIM(i_recnum) IS NULL OR
         p.id_patient IN (SELECT id_patient
                             FROM alert_adtcod.pat_identifier pid
                            WHERE pid.alert_process_number LIKE TRIM(i_recnum) || '%')) -- possible hog here
        -- pesquisa por birthdate (i_birthdate tem de estar na forma YYYYMMDDhh24miss)
         AND (i_birthdate IS NULL OR p.dt_birth = to_date(i_birthdate, 'YYYYMMDDhh24miss'))
        -- pesquisa por gender
         AND (i_gender IS NULL OR p.gender = i_gender)
        -- pesquisa por surname prefix
        -- AND (TRIM(i_surnameprefix) IS NULL OR pnl.surname_prefix LIKE '%' || TRIM(i_surnameprefix) || '%')
        
         AND (TRIM(i_surnameprefix) IS NULL OR
         translate(upper(p.surname_prefix), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
         '%' || translate(upper(TRIM(i_surnameprefix)), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%')
        -- pesquisa por surname maiden
        --  AND (TRIM(i_surnamemaiden) IS NULL OR pnl.surname_maiden LIKE '%' || TRIM(i_surnamemaiden) || '%')
        
         AND (TRIM(i_surnamemaiden) IS NULL OR
         translate(upper(prs.surname_maiden), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
         '%' || translate(upper(TRIM(i_surnamemaiden)), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%')
        -- pesquisa por name
        -- AND (TRIM(i_names) IS NULL OR p.name LIKE '%' || TRIM(i_names) || '%')
         AND (TRIM(i_names) IS NULL OR
         translate(upper(p.name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
         '%' || translate(upper(TRIM(i_names)), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%')
        -- pesquisa por initials
         AND (TRIM(i_initials) IS NULL OR p.initials LIKE '%' || TRIM(i_initials) || '%');
    
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
    END search_patient_nl;

    /******************************************************************************
    *  
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_flg_status        Admission Status A-all status, S-Schedule, U-Unschedule,
    *  @param  i_dpb           
    *  @param  i_dpa          
    *  @param  i_dpcs          
    *  @param  i_surgeons      
    *  @param  i_surg_proc     
    *  @param  i_cancel_reason 
    *  @param  o_wtlist     
    *  @param  o_error               
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5.0.2
    *  @since                      2009/04/20
    *
    ******************************************************************************/

    FUNCTION get_wtlist_search
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_args    IN table_varchar,
        i_wl_type IN VARCHAR2,
        o_wtlist  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SEARCH';
    BEGIN
        IF nvl(i_wl_type, pk_wtl_prv_core.g_wtlist_type_surgery) = pk_wtl_prv_core.g_wtlist_type_surgery
        THEN
            IF NOT get_wtlist_search_surgery(i_lang   => i_lang,
                                             i_prof   => i_prof,
                                             i_args   => i_args,
                                             o_wtlist => o_wtlist,
                                             o_error  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSIF i_wl_type = pk_wtl_prv_core.g_wtlist_type_bed
        THEN
            RETURN TRUE; --substituir pela funcao respectiva
        ELSIF i_wl_type = pk_wtl_prv_core.g_wtlist_type_both
        THEN
            RETURN TRUE; --substituir pela funcao respectiva
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
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_wtlist);
            RETURN FALSE;
    END get_wtlist_search;

    /******************************************************************************
    *  universal waiting list search for surgery entries. Market independent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            output
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      24-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_search_surgery
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_wtlist OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SEARCH';
        l_id_wtlist table_number;
        l_inst      institution.id_institution%TYPE;
        l_query     VARCHAR2(1000 CHAR);
    
        --sorting criteria
        l_acc      PLS_INTEGER := 0;
        l_const    PLS_INTEGER := 27;
        l_total_sk PLS_INTEGER := 6;
    
        l_sk           t_table_wtl_skis := t_table_wtl_skis();
        l_wtlsk_gender wtl_sort_key.id_wtl_sort_key%TYPE := 6; --gender
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        DECLARE
            l_dpa                  waiting_list.dt_dpa%TYPE;
            l_dpb                  waiting_list.dt_dpb%TYPE;
            l_ids_dcs              table_number := table_number();
            l_ids_surgeons         table_number := table_number();
            l_ids_procs            table_number := table_number();
            l_flg_status           table_varchar := table_varchar();
            l_sched_cancel_reasons table_varchar := table_varchar();
            l_ids_pat              table_number; -- Do not initialize this variable
            l_surg_wtl_inst        table_number := table_number();
            l_flg_status_count     NUMBER := 0;
        
        BEGIN
        
            -- ANY EXCEPTION OCURRING HERE GOES TO MAIN HANDLER
        
            -- convert dpa to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR dpa';
            IF i_args.exists(pk_wtl_prv_core.idx_dpa)
               AND i_args(pk_wtl_prv_core.idx_dpa) IS NOT NULL
            THEN
                IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => TRIM(i_args(pk_wtl_prv_core.idx_dpa)),
                                                     i_timezone  => NULL,
                                                     o_timestamp => l_dpa,
                                                     o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- convert dpb to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR dpb';
            IF i_args.exists(pk_wtl_prv_core.idx_dpb)
               AND i_args(pk_wtl_prv_core.idx_dpb) IS NOT NULL
            THEN
                IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => i_args(pk_wtl_prv_core.idx_dpb),
                                                     i_timezone  => NULL,
                                                     o_timestamp => l_dpb,
                                                     o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- convert dep_clin_serv
            g_error := 'CONVERT DCS';
            IF i_args.exists(pk_wtl_prv_core.idx_ids_dcs)
            THEN
                l_ids_dcs := pk_wtl_prv_core.get_list_number_csv(i_args(pk_wtl_prv_core.idx_ids_dcs));
            END IF;
        
            -- convert ids surgeons
            g_error := 'CONVERT SURGEONS';
            IF i_args.exists(pk_wtl_prv_core.idx_ids_surgeons)
            THEN
                l_ids_surgeons := pk_wtl_prv_core.get_list_number_csv(i_args(pk_wtl_prv_core.idx_ids_surgeons));
            END IF;
        
            -- convert ids procedures
            g_error := 'CONVERT PROCEDURES';
            IF i_args.exists(pk_wtl_prv_core.idx_ids_procedures)
            THEN
                l_ids_procs := pk_wtl_prv_core.get_list_number_csv(i_args(pk_wtl_prv_core.idx_ids_procedures));
            END IF;
        
            -- convert ids schedule cancel reasons
            g_error := 'CONVERT SCHEDULE CANCEL REASONS';
            IF i_args.exists(pk_wtl_prv_core.idx_id_sched_cancel_reason)
            THEN
                l_sched_cancel_reasons := pk_wtl_prv_core.get_list_string_csv(i_args(pk_wtl_prv_core.idx_id_sched_cancel_reason));
            END IF;
        
            -- convert search status
            g_error := 'CONVERT SEARCH STATUS';
        
            IF i_args.exists(pk_wtl_prv_core.idx_flg_status)
            THEN
                l_flg_status := pk_wtl_prv_core.get_list_string_csv(i_args(pk_wtl_prv_core.idx_flg_status));
            
            END IF;
            l_flg_status_count := l_flg_status.count;
        
            -- convert ids institutions
            g_error := 'CONVERT INSTITUTIONS LIST IDS';
            IF i_args.exists(pk_wtl_prv_core.idx_dest_inst)
            THEN
                l_surg_wtl_inst := pk_wtl_prv_core.get_list_number_csv(i_args(pk_wtl_prv_core.idx_dest_inst));
                --l_surg_wtl_inst := NULL;
            END IF;
        
            -- get patients that match given criteria 
            IF (i_args.exists(pk_wtl_prv_core.idx_bsn) AND i_args(pk_wtl_prv_core.idx_bsn) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_ssn) AND i_args(pk_wtl_prv_core.idx_ssn) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_nhn) AND i_args(pk_wtl_prv_core.idx_nhn) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_recnum) AND i_args(pk_wtl_prv_core.idx_recnum) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_birthdate) AND i_args(pk_wtl_prv_core.idx_birthdate) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_gender) AND i_args(pk_wtl_prv_core.idx_gender) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_surnameprefix) AND
               i_args(pk_wtl_prv_core.idx_surnameprefix) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_surnamemaiden) AND
               i_args(pk_wtl_prv_core.idx_surnamemaiden) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_names) AND i_args(pk_wtl_prv_core.idx_names) IS NOT NULL)
               OR (i_args.exists(pk_wtl_prv_core.idx_initials) AND i_args(pk_wtl_prv_core.idx_initials) IS NOT NULL)
            THEN
                IF NOT search_patient(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_bsn           => CASE i_args.exists(pk_wtl_prv_core.idx_bsn)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_bsn)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_ssn           => CASE i_args.exists(pk_wtl_prv_core.idx_ssn)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_ssn)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_nhn           => CASE i_args.exists(pk_wtl_prv_core.idx_nhn)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_nhn)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_recnum        => CASE i_args.exists(pk_wtl_prv_core.idx_recnum)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_recnum)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_birthdate     => CASE i_args.exists(pk_wtl_prv_core.idx_birthdate)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_birthdate)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_gender        => CASE i_args.exists(pk_wtl_prv_core.idx_gender)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_gender)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_surnameprefix => CASE i_args.exists(pk_wtl_prv_core.idx_surnameprefix)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_surnameprefix)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_surnamemaiden => CASE i_args.exists(pk_wtl_prv_core.idx_surnamemaiden)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_surnamemaiden)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_names         => CASE i_args.exists(pk_wtl_prv_core.idx_names)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_names)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_initials      => CASE i_args.exists(pk_wtl_prv_core.idx_initials)
                                                             WHEN TRUE THEN
                                                              i_args(pk_wtl_prv_core.idx_initials)
                                                             ELSE
                                                              NULL
                                                         END,
                                      o_list          => l_ids_pat,
                                      o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'SEARCH ID_WAITING_LIST';
            SELECT DISTINCT wtl.id_waiting_list
              BULK COLLECT
              INTO l_id_wtlist
              FROM waiting_list wtl
             INNER JOIN wtl_epis wtle
                ON wtle.id_waiting_list = wtl.id_waiting_list
             INNER JOIN schedule_sr ssr
                ON wtl.id_waiting_list = ssr.id_waiting_list
              LEFT JOIN sr_epis_interv si
                ON ssr.id_episode = si.id_episode_context
              LEFT JOIN wtl_dep_clin_serv wdcs
                ON ssr.id_waiting_list = wdcs.id_waiting_list
               AND wdcs.flg_status = pk_alert_constant.g_active
              LEFT JOIN wtl_prof wprf
                ON ssr.id_waiting_list = wprf.id_waiting_list
               AND wprf.flg_status = pk_alert_constant.g_active
             WHERE
            --waiting list status
             wtl.flg_status IN (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
            --only surgery episodes
             AND wtle.id_epis_type = pk_alert_constant.g_epis_type_operating
             AND wtl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_surgery, pk_wtl_prv_core.g_wtlist_type_both)
            --surgery episode not schedule
             AND wtle.flg_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
            
            -- The requested institution belong to one of the selected hospitalar facilities
             AND (SELECT ar.id_dest_inst
                FROM wtl_epis we
               INNER JOIN adm_request ar
                  ON (ar.id_dest_episode = we.id_episode)
               WHERE we.id_waiting_list = wtl.id_waiting_list
                 AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                 AND rownum = 1) IN (SELECT column_value
                                       FROM TABLE(l_surg_wtl_inst))
            
            --waiting list episodes status
             AND ((l_flg_status_count = 0) OR
             --all status
             (g_wtl_search_st_all IN (SELECT *
                                         FROM TABLE(l_flg_status))) OR
             --schedule
             (g_wtl_search_st_schedule IN (SELECT *
                                              FROM TABLE(l_flg_status)) AND
             wtl.id_waiting_list IN
             (SELECT id_waiting_list
                  FROM wtl_epis
                 WHERE id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule)) OR
             --not schedule
             (g_wtl_search_st_not_schedule IN (SELECT *
                                                  FROM TABLE(l_flg_status)) AND
             wtl.id_waiting_list IN
             (SELECT id_waiting_list
                  FROM wtl_epis
                 WHERE id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND flg_status IN
                       (pk_wtl_prv_core.g_wtl_epis_st_not_schedule, pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule))) OR
             
             --temporary schedule
             (g_wtl_search_st_schedule IN (SELECT *
                                              FROM TABLE(l_flg_status)) AND
             wtl.id_waiting_list IN
             (SELECT id_waiting_list
                  FROM wtl_epis we2
                 WHERE we2.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND we2.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule
                   AND pk_alert_constant.g_yes IN (SELECT nvl(sb.flg_temporary, pk_alert_constant.g_no)
                                                     FROM schedule_bed sb
                                                    WHERE sb.id_schedule = we2.id_schedule))))
            
            --dpb & dpa
             AND ((i_args(pk_wtl_prv_core.idx_dpb) IS NULL AND i_args(pk_wtl_prv_core.idx_dpa) IS NULL) OR
             (i_args(pk_wtl_prv_core.idx_dpb) IS NULL AND wtl.dt_dpa <= l_dpa) OR
             (i_args(pk_wtl_prv_core.idx_dpa) IS NULL AND wtl.dt_dpb >= l_dpb) OR
             (wtl.dt_dpb >= l_dpb AND wtl.dt_dpa <= l_dpa) OR (wtl.dt_dpb <= l_dpb AND wtl.dt_dpa >= l_dpa) OR
             (wtl.dt_dpb >= l_dpb AND wtl.dt_dpa >= l_dpa AND wtl.dt_dpb <= l_dpa) OR
             (wtl.dt_dpb <= l_dpb AND wtl.dt_dpa <= l_dpa AND wtl.dt_dpa >= l_dpb))
            
            -- dep_clin_servs
             AND (i_args(pk_wtl_prv_core.idx_ids_dcs) IS NULL OR
             (i_args(pk_wtl_prv_core.idx_ids_dcs) IS NOT NULL AND
             wdcs.id_dep_clin_serv IN (SELECT *
                                           FROM TABLE(l_ids_dcs))))
            -- surgeons
             AND (i_args(pk_wtl_prv_core.idx_ids_surgeons) IS NULL OR
             (i_args(pk_wtl_prv_core.idx_ids_surgeons) IS NOT NULL AND
             wprf.id_prof IN (SELECT *
                                  FROM TABLE(l_ids_surgeons))))
            -- procedures
             AND (i_args(pk_wtl_prv_core.idx_ids_procedures) IS NULL OR
             (i_args(pk_wtl_prv_core.idx_ids_procedures) IS NOT NULL AND
             si.id_sr_intervention IN (SELECT *
                                           FROM TABLE(l_ids_procs))))
            -- patients
             AND (l_ids_pat IS NULL OR wtl.id_patient IN (SELECT *
                                                        FROM TABLE(l_ids_pat)))
            -- schedule cancel reasons 
             AND (i_args(pk_wtl_prv_core.idx_id_sched_cancel_reason) IS NULL OR
             (wtle.flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule AND
             wtle.id_schedule IN
             (SELECT wtle.id_schedule
                  FROM schedule s
                 WHERE s.id_schedule = wtle.id_schedule
                   AND s.id_cancel_reason IN (SELECT *
                                                FROM TABLE(l_sched_cancel_reasons)))
             
             ))
            -- referral
             AND (i_args(pk_wtl_prv_core.idx_referral) IS NULL OR
             (TRIM(i_args(pk_wtl_prv_core.idx_referral)) IS NOT NULL AND
             wtl.id_external_request IN
             (SELECT p1.id_external_request
                  FROM p1_external_request p1
                 WHERE p1.num_req = TRIM(i_args(pk_wtl_prv_core.idx_referral)))));
        
            g_error := 'GET SORTING CRITERIA';
            BEGIN
                --institution
                IF NOT pk_utils.get_institution_parent(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_inst   => i_prof.institution,
                                                       o_parent => l_inst,
                                                       o_error  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                --sk
                l_sk := pk_wtl_prv_core.get_sort_keys_core(i_lang => i_lang, i_prof => i_prof, i_inst => l_inst);
            
                l_acc := (l_total_sk - l_sk.count);
                FOR i IN 0 .. l_acc
                LOOP
                    l_sk.extend;
                    l_sk(l_sk.last) := t_rec_wtl_skis(0, NULL, NULL, NULL, NULL);
                END LOOP;
            
                l_query := (l_const + l_sk(1).id_wtl_sort_key) || ', ' || (l_const + l_sk(2).id_wtl_sort_key) || ', ' ||
                           (l_const + l_sk(3).id_wtl_sort_key) || ', ' || (l_const + l_sk(4).id_wtl_sort_key) || ', ' ||
                           (l_const + l_sk(5).id_wtl_sort_key) || ', ' || (l_const + l_sk(6).id_wtl_sort_key);
            END;
        
        END;
    
        g_error := 'REPLACE BIND VARIABLES';
        pk_context_api.set_parameter('i_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof', i_prof.id);
        pk_context_api.set_parameter('i_software', i_prof.software);
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('l_inst', l_inst);
        pk_context_api.set_parameter('l_wtlsk_gender', l_wtlsk_gender);
        pk_context_api.set_parameter('g_wtl_prof_type_adm_phys', g_wtl_prof_type_adm_phys);
        pk_context_api.set_parameter('g_wtl_dcs_type_specialty', g_wtl_dcs_type_specialty);
        pk_context_api.set_parameter('g_wtl_dcs_type_ext_disc', g_wtl_dcs_type_ext_disc);
    
        g_error := 'GET WAITING LIST';
        OPEN o_wtlist FOR 'SELECT v.* 
										 FROM v_wtl_search_oris v
										 WHERE v.id_waiting_list IN (SELECT *
																										 FROM TABLE(:0))
										ORDER BY ' || l_query
            USING l_id_wtlist;
    
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
            pk_types.open_my_cursor(o_wtlist);
            RETURN FALSE;
        
    END get_wtlist_search_surgery;

    /******************************************************************************
    *  returns danger of contamination diagnosis in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        episode ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  o_danger_cont       danger of contamination
    *  @param  o_error             error data
    *
    *  @return                     boolean
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      23-04-2009
    *
    ******************************************************************************/
    FUNCTION get_danger_cont
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        o_danger_cont     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DANGER_CONT';
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_danger_cont FOR
            SELECT ed.id_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9) diag_desc,
                   ed.flg_type,
                   pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_TYPE', ed.flg_type, i_lang) type_desc,
                   ed.flg_status flg_diag_status,
                   pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_STATUS', ed.flg_status, i_lang) status_desc,
                   ed.notes specific_notes,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => i_id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   ed.flg_add_problem flg_add_problem_doc,
                   d.flg_other
              FROM (SELECT ed.id_diagnosis,
                           ed.id_epis_diagnosis,
                           ed.flg_type,
                           ed.flg_status,
                           ed.notes,
                           ed.id_epis_diagnosis_notes,
                           ed.flg_add_problem,
                           ed.desc_epis_diagnosis,
                           ed.id_alert_diagnosis,
                           row_number() over(PARTITION BY ed.id_diagnosis ORDER BY ed.flg_type) rn
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = i_id_episode
                       AND ed.flg_status NOT IN ('C', 'R')) ed
              JOIN diagnosis d
                ON (d.id_diagnosis = ed.id_diagnosis)
              LEFT OUTER JOIN alert_diagnosis ad
                ON (ad.id_alert_diagnosis = ed.id_alert_diagnosis)
              JOIN sr_danger_cont sdc
                ON (sdc.id_epis_diagnosis = ed.id_epis_diagnosis)
             WHERE sdc.flg_status = 'A'
               AND sdc.id_episode = i_id_episode
             ORDER BY diag_desc;
    
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
            pk_types.open_my_cursor(o_danger_cont);
            RETURN FALSE;
    END get_danger_cont;

    /******************************************************************************
    *  returns string with danger of contamination diagnosis in this waiting list entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        episode ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     string with danger of contamination diagnosis
    *
    *  @author                     JC
    *  @version                    2.5
    *  @since                      23-04-2009
    *
    ******************************************************************************/
    FUNCTION get_danger_cont_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_danger_cont VARCHAR2(2000) := NULL;
        l_first       BOOLEAN := TRUE;
        l_func_name   VARCHAR2(30) := 'GET_DANGER_CONT_STRING';
        l_error       t_error_out;
    BEGIN
        g_error := 'DANGER CONTAMINATION';
        FOR rec IN (SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_diagnosis => d.id_diagnosis,
                                                      i_code         => d.code_icd,
                                                      i_flg_other    => d.flg_other,
                                                      i_flg_std_diag => pk_alert_constant.g_yes) diagnosis
                      FROM sr_danger_cont dc
                     INNER JOIN schedule_sr s
                        ON dc.id_schedule_sr = s.id_schedule_sr
                      JOIN epis_diagnosis ed
                        ON ed.id_epis_diagnosis = dc.id_epis_diagnosis
                     INNER JOIN diagnosis d
                        ON d.id_diagnosis = ed.id_diagnosis
                     WHERE dc.flg_status = g_active
                          --AND s.flg_status = g_active
                       AND ((i_id_episode IS NOT NULL AND s.id_episode = i_id_episode) OR
                           (i_id_waiting_list IS NOT NULL AND s.id_waiting_list = i_id_waiting_list)))
        LOOP
            IF l_first
            THEN
                l_danger_cont := rec.diagnosis;
                l_first       := FALSE;
            ELSE
                l_danger_cont := l_danger_cont || ', ' || rec.diagnosis;
            END IF;
        END LOOP;
    
        RETURN l_danger_cont;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RAISE g_exception;
            -- RETURN NULL;
    END get_danger_cont_string;

    FUNCTION get_clinical_questions_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 AS
        l_ret          VARCHAR2(4000);
        l_id_sr_interv table_number := table_number();
    BEGIN
    
        BEGIN
            SELECT srei.id_sr_epis_interv
              BULK COLLECT
              INTO l_id_sr_interv
              FROM sr_epis_interv srei
             INNER JOIN intervention sri
                ON sri.id_intervention = srei.id_sr_intervention
              LEFT JOIN interv_codification ic
                ON sri.id_intervention = ic.id_intervention
             INNER JOIN wtl_epis wtle
                ON wtle.id_episode = srei.id_episode_context
             WHERE wtle.id_waiting_list IN (i_id_wtlist)
               AND srei.flg_type = pk_sr_planning.g_epis_interv_type_p
               AND srei.flg_status <> pk_wtl_prv_core.g_sr_epis_interv_status_c;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sr_interv := NULL;
        END;
    
        SELECT listagg('<br><b>' || desc_intervention || ' </b><br> ' || text) within GROUP(ORDER BY desc_intervention)
          INTO l_ret
          FROM (SELECT DISTINCT desc_intervention,
                                listagg('       ' || z.desc_questionnaire || ': ' || nvl(z.desc_response, '---') ||
                                        '; <br>') within GROUP(ORDER BY desc_intervention) over(PARTITION BY desc_intervention) text
                
                  FROM (SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => iqr1.code_intervention) desc_intervention,
                               iqr.id_sr_epis_interv id_interv_presc_det,
                               iqr.id_questionnaire,
                               iqr1.flg_time,
                               pk_mcdt.get_questionnaire_alias(i_lang,
                                                               i_prof,
                                                               'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || iqr.id_questionnaire) desc_questionnaire,
                               decode(instr(pk_procedures_utils.get_procedure_question_type(i_lang,
                                                                                            i_prof,
                                                                                            ipd.id_sr_intervention,
                                                                                            pk_procedures_constant.g_interv_cq_on_order,
                                                                                            iqr.id_questionnaire,
                                                                                            iqr.id_response),
                                            'D'),
                                      0,
                                      to_char(iqr1.id_response),
                                      to_char(iqr.notes)) id_response,
                               decode(dbms_lob.getlength(iqr.notes),
                                      NULL,
                                      iqr1.desc_response,
                                      pk_procedures_utils.get_procedure_response(i_lang, i_prof, iqr.notes)) desc_response
                          FROM (SELECT i.code_intervention,
                                       iqr.id_sr_epis_interv,
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
                                 INNER JOIN sr_epis_interv sei
                                    ON iqr.id_sr_epis_interv = sei.id_sr_epis_interv
                                 INNER JOIN intervention i
                                    ON i.id_intervention = sei.id_sr_intervention
                                 WHERE iqr.id_sr_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                                  *
                                                                   FROM TABLE(l_id_sr_interv) t)
                                 GROUP BY iqr.id_sr_epis_interv,
                                          i.code_intervention,
                                          iqr.id_sr_epis_interv,
                                          iqr.id_questionnaire,
                                          iqr.flg_time,
                                          iqr.dt_last_update_tstz) iqr1,
                               sr_interv_quest_response iqr,
                               sr_epis_interv ipd
                         WHERE iqr1.rn = 1
                           AND iqr1.id_sr_epis_interv = iqr.id_sr_epis_interv
                           AND iqr1.id_questionnaire = iqr.id_questionnaire
                           AND iqr1.dt_last_update_tstz = iqr.dt_last_update_tstz
                           AND iqr.id_sr_epis_interv = ipd.id_sr_epis_interv) z) w;
    
        RETURN l_ret;
    
    END get_clinical_questions_str;

    /******************************************************************************
    *  Returns the Waiting List summary for an entry. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting List ID
    *  @param  o_data              data
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      27-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN waiting_list.id_waiting_list%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SUMMARY';
        l_flg_type  waiting_list.flg_type%TYPE;
        -- GET institution date format string
        l_grid_date_format sys_message.desc_message%TYPE := pk_message.get_message(i_lang, g_grid_date_format);
    
        -- descs dos blocos
        l_b_adm_req        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ADM_REQUEST_T027');
        l_b_surg_req       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURGERY_REQUEST_T009');
        l_b_sched_per      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T001');
        l_b_unav_per       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T009');
        l_b_referral       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T035');
        l_b_barthel        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T049');
        l_b_pontuation     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SCALES_T013');
        l_b_pos            sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SR_POS_T001');
        l_b_proc_surgeon   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_T052');
        l_b_proc_diagnosis sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ADM_REQUEST_T028');
    
        -- data holders
        l_ind_for_adm       VARCHAR2(2000);
        l_diagnosis         VARCHAR2(2000);
        l_adm_location      VARCHAR2(2000);
        l_id_adm_service    VARCHAR2(2000);
        l_adm_service       VARCHAR2(2000);
        l_adm_specialty     VARCHAR2(2000);
        l_adm_physician     VARCHAR2(2000);
        l_id_adm_type       VARCHAR2(2000);
        l_adm_type          VARCHAR2(2000);
        l_expected_duration VARCHAR2(2000);
        l_adm_preparation   VARCHAR2(2000);
        l_id_room_type      VARCHAR2(2000);
        l_room_type         VARCHAR2(2000);
        l_flg_mixed_nursing VARCHAR2(2000);
        l_id_bed_type       VARCHAR2(2000);
        l_bed_type          VARCHAR2(2000);
        l_id_pref_room      VARCHAR2(2000);
        l_pref_room         VARCHAR2(2000);
        l_flg_nit           VARCHAR2(2000);
        l_nit_location      VARCHAR2(2000);
        l_nit_dt_sugg_char  VARCHAR2(2000);
        l_adm_notes         VARCHAR2(2000);
        l_regim             VARCHAR2(2000);
        l_benef             VARCHAR2(2000);
        l_precau            VARCHAR2(2000);
        l_contact           VARCHAR2(2000);
    
        l_surg_location     VARCHAR2(2000);
        l_surg_needed       VARCHAR2(2000);
        l_surg_spec         VARCHAR2(2000);
        l_pref_surgeon      VARCHAR2(2000);
        l_surg_proc         VARCHAR2(2000);
        l_duration          VARCHAR2(2000);
        l_icu               VARCHAR2(2000);
        l_ext_disc          VARCHAR2(2000);
        l_danger_cont       VARCHAR2(2000);
        l_pref_time         VARCHAR2(2000);
        l_ptime_reason      VARCHAR2(2000);
        l_pos_decision      VARCHAR2(2000);
        l_surg_notes        VARCHAR2(2000);
        l_clinical_question VARCHAR2(2000);
    
        l_urg_lev         VARCHAR2(2000);
        l_dt_dpb          VARCHAR2(2000);
        l_dt_dpa          VARCHAR2(2000);
        l_min_time_inf    VARCHAR2(2000);
        l_dt_sug_surg     VARCHAR2(2000);
        l_dt_sug_adm      VARCHAR2(2000);
        l_dt_surg         VARCHAR2(2000);
        l_dt_adm          VARCHAR2(2000);
        l_referral_num    VARCHAR2(2000);
        l_func_eval_score VARCHAR2(2000);
        l_code_decision   VARCHAR2(2000);
        l_decision_notes  sr_pos_schedule.req_notes%TYPE;
        l_proc_surgeon    VARCHAR2(2000);
        l_proc_diagnosis  VARCHAR2(2000);
        l_wtl_referral    sys_config.id_sys_config%TYPE;
    
    BEGIN
    
        g_error        := 'GET SYS_CONFIG WTL_REFERRAL';
        l_wtl_referral := pk_sysconfig.get_config('WTL_REFERRAL', i_prof);
    
        g_error := 'GET WAITING LIST TYPE';
        SELECT wtl.flg_type
          INTO l_flg_type
          FROM waiting_list wtl
         WHERE wtl.id_waiting_list = i_id_wtlist;
    
        IF (l_flg_type = pk_wtl_prv_core.g_wtlist_type_both)
        THEN
            l_surg_needed := pk_sysdomain.get_domain('SURGERY_NEEDED', pk_alert_constant.g_yes, i_lang);
        END IF;
    
        IF (l_flg_type = pk_wtl_prv_core.g_wtlist_type_both OR l_flg_type = pk_wtl_prv_core.g_wtlist_type_surgery)
        THEN
            g_error := 'GET SR DATA VALUES';
            pk_alertlog.log_debug('GET SR DATA VALUES for i_id_wtlist  = ' || i_id_wtlist);
            SELECT desc_dest_inst,
                   get_clin_servs_string(i_lang,
                                         i_prof,
                                         t.id_waiting_list,
                                         NULL,
                                         pk_wtl_pbl_core.g_wtl_dcs_type_specialty) d_surg_spec,
                   get_prof_string(i_lang, i_prof, t.id_waiting_list, NULL, pk_wtl_pbl_core.g_wtl_prof_type_surgeon) d_pref_surgeon,
                   get_surg_proc_string(i_lang, i_prof, t.id_waiting_list) surg_proc,
                   pk_surgery_request.get_duration(i_lang, t.duration) d_sr_exp_dur,
                   pk_sysdomain.get_domain('SCHEDULE_SR.ICU', t.icu, i_lang) d_icu,
                   get_clin_servs_string(i_lang,
                                         i_prof,
                                         t.id_waiting_list,
                                         NULL,
                                         pk_wtl_pbl_core.g_wtl_dcs_type_ext_disc) d_ext_disc,
                   get_danger_cont_string(i_lang, i_prof, NULL, t.id_waiting_list) d_danger_cont,
                   get_pref_time_string(i_lang, i_prof, t.id_waiting_list) d_pref_time,
                   get_ptime_reason_string(i_lang, i_prof, t.id_waiting_list) d_ptime_reason,
                   pk_surgery_request.get_pos_decision_string(i_lang, i_prof, t.id_episode) d_pos_decison,
                   t.notes,
                   to_char(t.dt_target_tstz, l_grid_date_format) dt_surgery_char,
                   pk_translation.get_translation(i_lang, t.code),
                   t.decision_notes,
                   pk_wtl_pbl_core.get_clinical_questions_str(i_lang, i_prof, i_id_wtlist) clinical_question,
                   pk_wtl_pbl_core.get_procedure_diagnosis_string(i_lang, i_prof, i_id_wtlist) procdiagnosis,
                   pk_wtl_pbl_core.get_proc_main_surgeon_string(i_lang, i_prof, i_id_wtlist) procsurgeon
              INTO l_surg_location,
                   l_surg_spec,
                   l_pref_surgeon,
                   l_surg_proc,
                   l_duration,
                   l_icu,
                   l_ext_disc,
                   l_danger_cont,
                   l_pref_time,
                   l_ptime_reason,
                   l_pos_decision,
                   l_surg_notes,
                   l_dt_surg,
                   l_code_decision,
                   l_decision_notes,
                   l_clinical_question,
                   l_proc_diagnosis,
                   l_proc_surgeon
              FROM (SELECT pk_translation.get_translation(i_lang, i.code_institution) desc_dest_inst, -- location--schs.id_institution-------------fazer join com insto e obter descritivo (como adm)
                           schs.duration,
                           schs.icu,
                           wtl.id_waiting_list,
                           schs.id_episode,
                           schs.notes,
                           schs.dt_target_tstz,
                           sps.decision_notes,
                           spst.code,
                           rank() over(PARTITION BY schs.id_schedule_sr ORDER BY sps.dt_req DESC, sps.dt_reg DESC) origin_rank
                      FROM waiting_list wtl
                      LEFT JOIN schedule_sr schs
                        ON schs.id_waiting_list = wtl.id_waiting_list
                      LEFT JOIN institution i
                        ON i.id_institution = schs.id_institution
                      LEFT JOIN sr_pos_schedule sps
                        ON sps.id_schedule_sr = schs.id_schedule_sr
                      LEFT JOIN sr_pos_status spst
                        ON spst.id_sr_pos_status = sps.id_sr_pos_status
                     WHERE wtl.id_waiting_list = i_id_wtlist) t
             WHERE t.origin_rank = 1;
            --AND rownum = 1;
        END IF;
    
        IF (l_flg_type = pk_wtl_prv_core.g_wtlist_type_both OR l_flg_type = pk_wtl_prv_core.g_wtlist_type_bed)
        THEN
        
            g_error := 'GET ADM DATA VALUES';
            SELECT --ai.desc_adm_indication desc_adm_indication,
            --pk_translation.get_translation(i_lang, ap.code_adm_preparation) desc_adm_preparation,
             nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) desc_adm_indication,
             pk_admission_request.get_adm_req_diag_string(i_lang, i_prof, ar.id_adm_request) diagnosis,
             pk_translation.get_translation(i_lang, i.code_institution) desc_dest_inst, -- location
             pk_translation.get_translation(i_lang, d.code_department) desc_depart,
             d.id_department id_depart, -- service
             pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_dep_clin_serv, -- specialty
             pk_prof_utils.get_name_signature(i_lang, i_prof, wp.id_prof) name_adm_phys, -- physician
             nvl(atp.desc_admission_type, pk_translation.get_translation(i_lang, atp.code_admission_type)) desc_adm_type,
             atp.id_admission_type id_adm_type,
             pk_admission_request.get_duration(i_lang, ar.expected_duration) adm_exp_duration,
             --ap.desc_adm_preparation desc_adm_preparation,
             nvl(ap.desc_adm_preparation, pk_translation.get_translation(i_lang, ap.code_adm_preparation)) desc_adm_preparation,
             nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) desc_room_type,
             rt.id_room_type id_room_type,
             --rt.desc_room_type desc_room_type,
             pk_sysdomain.get_domain('ADM_REQUEST.FLG_MIXED_NURSING', ar.flg_mixed_nursing, i_lang) flg_mixed_nursing,
             nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) desc_bed_type,
             bt.id_bed_type id_bed_type,
             nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_pref_room,
             r.id_room id_pref_room,
             pk_sysdomain.get_domain('YES_NO', ar.flg_nit, i_lang) nit_flg,
             (SELECT pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || d2.id_institution)
                FROM department d2
               INNER JOIN dep_clin_serv dcs2
                  ON (d2.id_department = dcs2.id_department)
               WHERE dcs2.id_dep_clin_serv = ar.id_nit_dcs) desc_nit_location,
             --to_char(ar.nit_dt_suggested, l_grid_date_format) nit_dt_sugg_char,
             pk_date_utils.date_char_tsz(i_lang, ar.dt_nit_suggested, i_prof.institution, i_prof.software) nit_dt_sugg_char,
             ar.notes,
             to_char(ar.dt_admission, l_grid_date_format) dt_admission_char,
             pk_sysdomain.get_domain('ADM_REQUEST.REGIMEN', ar.flg_regim, i_lang) regim_desc,
             pk_sysdomain.get_domain('ADM_REQUEST.BENEFICIARIO', ar.flg_benefi, i_lang) benefic_desc,
             pk_sysdomain.get_domain('ADM_REQUEST.PRECAUCIONES', ar.flg_precauc, i_lang) precauc_desc,
             pk_sysdomain.get_domain('ADM_REQUEST.CONTACTADO', ar.flg_contact, i_lang) contact_desc
              INTO l_ind_for_adm,
                   l_diagnosis,
                   l_adm_location,
                   l_adm_service,
                   l_id_adm_service,
                   l_adm_specialty,
                   l_adm_physician,
                   l_adm_type,
                   l_id_adm_type,
                   l_expected_duration,
                   l_adm_preparation,
                   l_room_type,
                   l_id_room_type,
                   l_flg_mixed_nursing,
                   l_bed_type,
                   l_id_bed_type,
                   l_pref_room,
                   l_id_pref_room,
                   l_flg_nit,
                   l_nit_location,
                   l_nit_dt_sugg_char,
                   l_adm_notes,
                   l_dt_adm,
                   l_regim,
                   l_benef,
                   l_precau,
                   l_contact
              FROM adm_request ar
             INNER JOIN adm_indication ai
                ON ar.id_adm_indication = ai.id_adm_indication
             INNER JOIN institution i
                ON ar.id_dest_inst = i.id_institution
             INNER JOIN department d
                ON ar.id_department = d.id_department
             INNER JOIN dep_clin_serv dcs
                ON ar.id_dep_clin_serv = dcs.id_dep_clin_serv
             INNER JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             INNER JOIN wtl_epis we
                ON ar.id_dest_episode = we.id_episode
              LEFT JOIN wtl_prof wp
                ON we.id_waiting_list = wp.id_waiting_list
               AND wp.flg_type = g_wtl_prof_type_adm_phys
               AND wp.flg_status = pk_alert_constant.g_active
              LEFT JOIN admission_type atp
                ON ar.id_admission_type = atp.id_admission_type
              LEFT JOIN adm_preparation ap
                ON ar.id_adm_preparation = ap.id_adm_preparation
              LEFT JOIN room_type rt
                ON ar.id_room_type = rt.id_room_type
              LEFT JOIN bed_type bt
                ON ar.id_bed_type = bt.id_bed_type
              LEFT JOIN room r
                ON ar.id_pref_room = r.id_room
             WHERE we.id_waiting_list = i_id_wtlist
               AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient;
        
        END IF;
    
        g_error := 'GET SCHEDULING PERIOD DATA';
        SELECT nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) desc_urg_level,
               --Sofia Mendes (ALERT-46794)
               --to_char(wl.dt_dpb, l_grid_date_format) dt_sched_start_char,
               --to_char(wl.dt_dpa, l_grid_date_format) dt_sched_end_char,
               --       pk_date_utils.to_char_insttimezone(i_lang, i_prof, wl.dt_dpb, l_grid_date_format) 
               pk_date_utils.date_char_tsz(i_lang => i_lang,
                                           i_date => wl.dt_dpb,
                                           i_inst => i_prof.institution,
                                           i_soft => i_prof.software) dt_sched_start_char,
               --     pk_date_utils.to_char_insttimezone(i_lang, i_prof, wl.dt_dpa, l_grid_date_format) 
               pk_date_utils.date_char_tsz(i_lang => i_lang,
                                           i_date => wl.dt_dpa,
                                           i_inst => i_prof.institution,
                                           i_soft => i_prof.software) dt_sched_end_char,
               decode(nvl(wl.min_inform_time, ''),
                      '',
                      '',
                      wl.min_inform_time || ' ' || pk_message.get_message(i_lang, 'COMMON_M020')) min_inform_time,
               --to_char(wl.dt_surgery, l_grid_date_format)
               --pk_date_utils.to_char_insttimezone(i_lang, i_prof, wl.dt_surgery, l_grid_date_format) dt_sug_surg_char,
               pk_date_utils.date_char_tsz(i_lang => i_lang,
                                           i_date => wl.dt_surgery,
                                           i_inst => i_prof.institution,
                                           i_soft => i_prof.software) dt_sug_surg_char,
               --to_char(wl.dt_admission, l_grid_date_format)
               --               pk_date_utils.to_char_insttimezone(i_lang, i_prof, wl.dt_admission, l_grid_date_format) dt_sug_admission_char,
               pk_date_utils.date_char_tsz(i_lang => i_lang,
                                           i_date => wl.dt_admission,
                                           i_inst => i_prof.institution,
                                           i_soft => i_prof.software) dt_sug_admission_char,
               (SELECT num_req
                  FROM p1_external_request p1
                 WHERE p1.id_external_request = wl.id_external_request
                   AND l_wtl_referral = pk_alert_constant.g_yes),
               wl.func_eval_score
          INTO l_urg_lev,
               l_dt_dpb,
               l_dt_dpa,
               l_min_time_inf,
               l_dt_sug_surg,
               l_dt_sug_adm,
               l_referral_num,
               l_func_eval_score
          FROM waiting_list wl
          LEFT JOIN wtl_urg_level wul
            ON wl.id_wtl_urg_level = wul.id_wtl_urg_level
         WHERE wl.id_waiting_list = i_id_wtlist;
    
        g_error := 'OPEN CURSOR';
    
        INSERT INTO wtl_adm_surg_tmptab
            (SELECT *
               FROM (
                     --Admission Request
                     SELECT i_id_wtlist id_wtlist,
                             l_b_adm_req bloco,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             1 ordem,
                             -1 id_label
                       FROM dual
                     UNION
                     
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_ind_adm_name)),
                             l_ind_for_adm,
                             2 ordem,
                             pk_wtl_prv_core.ix_out_id_ind_adm_name
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_diagnosis)),
                             l_diagnosis,
                             3 ordem,
                             pk_wtl_prv_core.ix_out_diagnosis
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_location)),
                             l_adm_location,
                             4 ordem,
                             pk_wtl_prv_core.ix_out_adm_location
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_service)),
                             l_adm_service,
                             5 ordem,
                             pk_wtl_prv_core.ix_out_adm_service
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_speciality)),
                             l_adm_specialty,
                             6 ordem,
                             pk_wtl_prv_core.ix_out_adm_speciality
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_physic)),
                             l_adm_physician,
                             7 ordem,
                             pk_wtl_prv_core.ix_out_adm_physic
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_type)),
                             l_adm_type,
                             8 ordem,
                             pk_wtl_prv_core.ix_out_adm_type
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_exp_duration)),
                             l_expected_duration,
                             9 ordem,
                             pk_wtl_prv_core.ix_out_adm_exp_duration
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_preparation)),
                             l_adm_preparation,
                             10 ordem,
                             pk_wtl_prv_core.ix_out_preparation
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_room_type)),
                             l_room_type,
                             11 ordem,
                             pk_wtl_prv_core.ix_out_room_type
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_mix_nurs)),
                             l_flg_mixed_nursing,
                             12 ordem,
                             pk_wtl_prv_core.ix_out_mix_nurs
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_bed_type)),
                             l_bed_type,
                             13 ordem,
                             pk_wtl_prv_core.ix_out_bed_type
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_pref_room)),
                             l_pref_room,
                             14 ordem,
                             pk_wtl_prv_core.ix_out_pref_room
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_nurs_int_need)),
                             l_flg_nit,
                             15 ordem,
                             pk_wtl_prv_core.ix_out_nurs_int_need
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_nurs_int_loc)),
                             l_nit_location,
                             16 ordem,
                             pk_wtl_prv_core.ix_out_nurs_int_loc
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_sugg_int_date)),
                             l_nit_dt_sugg_char,
                             17 ordem,
                             pk_wtl_prv_core.ix_out_sugg_int_date
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_translation.get_translation(i_lang,
                                                            pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_regim)),
                             l_regim,
                             18 ordem,
                             pk_wtl_prv_core.ix_out_id_regim
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_translation.get_translation(i_lang,
                                                            pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_benef)),
                             l_benef,
                             19 ordem,
                             pk_wtl_prv_core.ix_out_id_benef
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_translation.get_translation(i_lang,
                                                            pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_precau)),
                             l_precau,
                             20 ordem,
                             pk_wtl_prv_core.ix_out_id_precau
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_translation.get_translation(i_lang,
                                                            pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_contact)),
                             l_contact,
                             21 ordem,
                             pk_wtl_prv_core.ix_out_id_contact
                       FROM dual
                     
                     UNION
                     
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_adm_service)),
                             l_id_adm_service,
                             22 ordem,
                             pk_wtl_prv_core.ix_out_id_adm_service
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_adm_type)),
                             l_id_adm_type,
                             23 ordem,
                             pk_wtl_prv_core.ix_out_id_adm_type
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_room_type)),
                             l_id_room_type,
                             24 ordem,
                             pk_wtl_prv_core.ix_out_id_room_type
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_bed_type)),
                             l_id_bed_type,
                             25 ordem,
                             pk_wtl_prv_core.ix_out_id_bed_type
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_id_pref_room)),
                             l_id_pref_room,
                             26 ordem,
                             pk_wtl_prv_core.ix_out_id_pref_room
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_notes)),
                             l_adm_notes,
                             27 ordem,
                             pk_wtl_prv_core.ix_out_notes
                       FROM dual
                     UNION
                     --Surgery Request
                     SELECT i_id_wtlist id_wtlist,
                             l_b_surg_req,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             28 ordem,
                             -1 id_label
                       FROM dual
                     
                     UNION
                     
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_surg_needed)),
                             l_surg_needed,
                             29 ordem,
                             pk_wtl_prv_core.ix_out_surg_needed
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_location)),
                             l_surg_location,
                             30 ordem,
                             pk_wtl_prv_core.ix_out_adm_location
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_surg_spec)),
                             l_surg_spec,
                             31 ordem,
                             pk_wtl_prv_core.ix_out_surg_spec
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_pref_surgeon)),
                             l_pref_surgeon,
                             32 ordem,
                             pk_wtl_prv_core.ix_out_pref_surgeon
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_proc_name)),
                             l_surg_proc,
                             33 ordem,
                             pk_wtl_prv_core.ix_out_proc_name
                       FROM dual
                     UNION
                     SELECT i_id_wtlist                         id_wtlist,
                             NULL,
                             l_b_proc_surgeon,
                             l_proc_surgeon,
                             34                                  ordem,
                             pk_wtl_prv_core.ix_out_proc_surgeon
                       FROM dual
                     UNION
                     SELECT i_id_wtlist                           id_wtlist,
                             NULL,
                             l_b_proc_diagnosis,
                             l_proc_diagnosis,
                             35                                    ordem,
                             pk_wtl_prv_core.ix_out_proc_diagnosis
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_clinical_q)),
                             l_clinical_question,
                             36 ordem,
                             pk_wtl_prv_core.ix_out_clinical_q
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_surg_exp_duration)),
                             l_duration,
                             37 ordem,
                             pk_wtl_prv_core.ix_out_surg_exp_duration
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_icu)),
                             l_icu,
                             38 ordem,
                             pk_wtl_prv_core.ix_out_icu
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_ext_disc)),
                             l_ext_disc,
                             39 ordem,
                             pk_wtl_prv_core.ix_out_ext_disc
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_dang_contam)),
                             l_danger_cont,
                             40 ordem,
                             pk_wtl_prv_core.ix_out_dang_contam
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_pref_time)),
                             l_pref_time,
                             41 ordem,
                             pk_wtl_prv_core.ix_out_pref_time
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_pref_time_reason)),
                             l_ptime_reason,
                             42 ordem,
                             pk_wtl_prv_core.ix_out_pref_time_reason
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_surg_notes)),
                             l_surg_notes,
                             43 ordem,
                             pk_wtl_prv_core.ix_out_surg_notes
                       FROM dual
                     UNION
                     
                     --POS Validation
                     SELECT i_id_wtlist id_wtlist,
                             l_b_pos bloco,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             44 ordem,
                             -1
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_pos_validation)),
                             l_code_decision,
                             45 ordem,
                             pk_wtl_prv_core.ix_out_pos_validation
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_pos_validation_notes)),
                             l_decision_notes,
                             46 ordem,
                             pk_wtl_prv_core.ix_out_pos_validation_notes
                       FROM dual
                     UNION
                     
                     --Referral
                     SELECT i_id_wtlist id_wtlist,
                             l_b_referral,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             47 ordem,
                             -1
                       FROM dual
                      WHERE l_wtl_referral = pk_alert_constant.g_yes
                     UNION
                     
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_rec_num)),
                             l_referral_num,
                             48 ordem,
                             pk_wtl_prv_core.ix_out_rec_num
                       FROM dual
                      WHERE l_wtl_referral = pk_alert_constant.g_yes
                     UNION
                     
                     --Barthel
                     SELECT i_id_wtlist id_wtlist,
                             l_b_barthel,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             49 ordem,
                             -1
                       FROM dual
                      WHERE l_wtl_referral = pk_alert_constant.g_yes
                     UNION
                     
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_barthel_num)),
                             l_func_eval_score || ' ' || l_b_pontuation,
                             50 ordem,
                             pk_wtl_prv_core.ix_out_barthel_num
                       FROM dual
                      WHERE l_wtl_referral = pk_alert_constant.g_yes
                     UNION
                     
                     -- Scheduling period
                     SELECT i_id_wtlist id_wtlist,
                             l_b_sched_per,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             51 ordem,
                             -1 id_label
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_urg_level)),
                             l_urg_lev,
                             52 ordem,
                             pk_wtl_prv_core.ix_out_urg_level
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_sch_per_start)),
                             l_dt_dpb,
                             53 ordem,
                             pk_wtl_prv_core.ix_out_sch_per_start
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_sch_per_end)),
                             l_dt_dpa,
                             54 ordem,
                             pk_wtl_prv_core.ix_out_sch_per_end
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_min_time_infor)),
                             l_min_time_inf,
                             55 ordem,
                             pk_wtl_prv_core.ix_out_min_time_infor
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_sugg_surg_date)),
                             l_dt_sug_surg,
                             56 ordem,
                             pk_wtl_prv_core.ix_out_sugg_surg_date
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_sug_adm_date)),
                             l_dt_sug_adm,
                             57 ordem,
                             pk_wtl_prv_core.ix_out_sug_adm_date
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang, pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_adm_date)),
                             l_dt_adm,
                             58 ordem,
                             pk_wtl_prv_core.ix_out_adm_date
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist,
                             NULL,
                             pk_message.get_message(i_lang,
                                                    pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_dt_surgery)),
                             l_dt_surg,
                             59 ordem,
                             pk_wtl_prv_core.ix_out_dt_surgery
                       FROM dual
                     UNION
                     
                     --Unavailability period
                     SELECT i_id_wtlist id_wtlist,
                             l_b_unav_per,
                             NULL label,
                             CAST(NULL AS VARCHAR2(2000)) data,
                             60 ordem,
                             -1
                       FROM dual
                     UNION
                     SELECT i_id_wtlist id_wtlist, label_b, label, data, 60 + rownum, id_label
                       FROM (
                              -- Pedriod Start
                              SELECT us.id_wtl_unav id_unav,
                                      1 ord,
                                      NULL label_b,
                                      pk_message.get_message(i_lang,
                                                             pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_unav_start)) label,
                                      to_char(us.dt_unav_start, l_grid_date_format) data,
                                      pk_wtl_prv_core.ix_out_unav_start id_label
                                FROM wtl_unav us
                               WHERE us.id_waiting_list = i_id_wtlist
                                 AND us.flg_status = pk_alert_constant.g_active
                              UNION
                              -- Duration
                              SELECT us.id_wtl_unav id_unav,
                                      2 ord,
                                      NULL label_b,
                                      pk_message.get_message(i_lang,
                                                             pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_duration)) label,
                                      (trunc(pk_date_utils.diff_timestamp(us.dt_unav_end, us.dt_unav_start)) + 1) || ' ' ||
                                      pk_message.get_message(i_lang, 'COMMON_M020') data,
                                      pk_wtl_prv_core.ix_out_duration
                                FROM wtl_unav us
                               WHERE us.id_waiting_list = i_id_wtlist
                                 AND us.flg_status = pk_alert_constant.g_active
                              UNION
                              -- Pedriod End
                              SELECT us.id_wtl_unav id_unav,
                                      3 ord,
                                      NULL label_b,
                                      pk_message.get_message(i_lang,
                                                             pk_wtl_prv_core.ix_out_names(pk_wtl_prv_core.ix_out_unav_end)) label,
                                      to_char(us.dt_unav_end, l_grid_date_format) data,
                                      pk_wtl_prv_core.ix_out_unav_end
                                FROM wtl_unav us
                               WHERE us.id_waiting_list = i_id_wtlist
                                 AND us.flg_status = pk_alert_constant.g_active)
                      ORDER BY 1, 2
                     
                     ))
        
        ORDER BY ordem;
    
        --        OPEN o_data FOR
        --            SELECT *
        --              FROM wtl_adm_surg_tmptab;
    
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
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_wtlist_summary;

    /**********************************************************************************************
    * Function to show the viewer checklist
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_waiting_list           waiting list id
    * @param o_list                   array with the checklist
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                       
    * @version                        2.0 
    * @since                          
    **********************************************************************************************/
    FUNCTION get_viewer_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_screen       IN VARCHAR2 DEFAULT 'I',
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wtl waiting_list%ROWTYPE;
    BEGIN
    
        g_error := 'GET CURRENT WTL RECORD';
        IF i_waiting_list IS NOT NULL
        THEN
            SELECT wtl.*
              INTO l_wtl
              FROM waiting_list wtl
             WHERE wtl.id_waiting_list = i_waiting_list;
        END IF;
    
        g_error := 'GET REQUIRED FIELDS';
        IF NOT pk_wtl_prv_core.get_surg_adm_req_mandatory(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_wtl      => l_wtl,
                                                          i_screen   => i_screen,
                                                          o_required => o_list,
                                                          o_error    => o_error)
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
                                              'GET_VIEWER_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_viewer_list;

    /******************************************************************************
    *  Adds Admission or Surgery Requests to the Waiting List.
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional ID/Institution ID/Software ID
    * @param i_id_patient                Patient ID
    * @param i_id_episode                Current episode ID
    * @param io_id_episode_sr             Surgical episode ID (if exists)
    * @param io_id_episode_inp            Inpatient episode ID (if exists)
    * @param i_id_waiting_list           Waiting list ID (if exists)     
    * @param i_flg_type                  Type of request: (B) Bed - admission request (S) Surgery request (A) All
    * @param i_id_wtl_urg_level          Urgency level ID
    * @param i_dt_sched_period_start     Scheduling period start date
    * @param i_dt_sched_period_end       Scheduling period end date
    * @param i_min_inform_time           Minimum time to inform
    * @param i_dt_surgery                Suggested surgery date
    * @param i_unav_period_start         Unavailability period: start date(s)
    * @param i_unav_period_end           Unavailability period: end date(s)    
    * @param i_pref_surgeons              Array of preferred surgeons
    * @param i_external_dcs               Array of external disciplines
    * @param i_dep_clin_serv_sr           Array of specialities (for the surgical procedure)
    * @param i_flg_pref_time              Array for preferred time: (M) Morning (A) Afternoon (N) Night (O) Any
    * @param i_reason_pref_time           Array of reasons for preferred time
    * @param i_id_sr_intervention         Array of surgical procedures ID
    * @param i_flg_laterality             Array of laterality for each procedure
    * @param i_id_diagnosis_proc          Array of diagnosis ID associated with surgical procedures
    * @param i_duration                   Expected duration of the surgical procedure
    * @param i_icu                        Intensive care unit: (Y) Yes (N) No
    * @param i_notes_surg                 Scheduling notes
    * @param i_adm_needed                 Admission needed: (Y) Yes (N) No
    * @param i_id_sr_pos_status           POS Decision   
    * @param i_surg_needed                Surgery needed: (Y) Yes (N) No
    * @param i_adm_indication             Indication for admission ID
    * @param i_dest_inst                  Location requested
    * @param i_adm_type                   Admission type
    * @param i_department                 Department requested
    * @param i_room_type                  Room type
    * @param i_dep_clin_serv              Specialty requested
    * @param i_pref_room                  Preferred room
    * @param i_mixed_nursing              Mixed nursing preference
    * @param i_bed_type                   Bed type
    * @param i_dest_prof                  Professional requested to take the admission
    * @param i_adm_preparation            Admission preparation
    * @param i_expect_duration            Admission's expected duration
    * @param i_dt_admission               Date of admission (final)
    * @param i_notes                      Entered notes
    * @param i_nit_flg                    Flag indicating need for a nurse intake
    * @param i_nit_dt_suggested           Date suggested for the nurse intake
    * @param i_nit_dcs                    Dep_clin_serv for nurse intake
    * @param i_supply                     Supply ID
    * @param i_supply_set                 Parent supply set (if applicable)
    * @param i_supply_qty                 Supply quantity
    * @param i_supply_loc                 Supply location
    * @param i_dt_return                  Estimated date of of return
    * @param i_supply_soft_inst           list
    * @param i_flg_cons_type              flag of consumption type
    * @param i_description_sp             Table varchar with surgical procedures' description
    * @param i_id_sr_epis_interv          Table number with id_sr_epis_interv
    * @param i_id_req_reason              Reasons for each supply
    * @param i_supply_notes               Supply Request notes
    * @param i_diagnosis_adm_req          Desc diagnosis from the diagnosis of the admission request
    * @param i_diagnosis_surg_proc        Desc diagnosis from the diagnosis of the surgical procedures
    * @param i_diagnosis_contam           Desc diagnosis from the diagnosis of the danger of contamination
    * @param i_id_cdr_call                Rule event identifier.
    * @param o_error                      Error
    *
    *  @return                     TRUE if successful, FALSE otherwise
    *
    *  @author                     José Brito
    *  @version                    1.0
    *  @since                      2009/05/04
    *
    ******************************************************************************/
    FUNCTION set_adm_surg_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        -- Logic
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list      IN OUT waiting_list.id_waiting_list%TYPE,
        i_flg_type              IN waiting_list.flg_type%TYPE,
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2, -- 10
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        i_unav_period_start     IN table_varchar,
        i_unav_period_end       IN table_varchar, -- 15
        -- Surgery Request
        i_pref_surgeons      IN table_number,
        i_external_dcs       IN table_number,
        i_dep_clin_serv_sr   IN table_number,
        i_speciality_sr      IN table_number,
        i_department_sr      IN table_number,
        i_flg_pref_time      IN table_varchar,
        i_reason_pref_time   IN table_number, -- 20
        i_id_sr_intervention IN table_number,
        i_flg_principal      IN table_varchar,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_surgical_site      IN table_varchar,
        i_sp_notes           IN table_varchar, --25
        i_duration           IN schedule_sr.duration%TYPE,
        i_icu                IN schedule_sr.icu%TYPE,
        i_icu_pos            IN schedule_sr.icu_pos%TYPE,
        i_notes_surg         IN schedule_sr.notes%TYPE,
        i_adm_needed         IN schedule_sr.adm_needed%TYPE,
        i_id_sr_pos_status   IN sr_pos_status.id_sr_pos_status%TYPE, --30
        -- Admission Request
        i_surg_needed       IN VARCHAR2,
        i_adm_indication    IN adm_request.id_adm_indication%TYPE,
        i_adm_ind_desc      IN adm_request.adm_indication_ft%TYPE DEFAULT NULL,
        i_dest_inst         IN adm_request.id_dest_inst%TYPE,
        i_adm_type          IN adm_request.id_admission_type%TYPE,
        i_department        IN adm_request.id_department%TYPE, --35
        i_room_type         IN adm_request.id_room_type%TYPE,
        i_dep_clin_serv_adm IN adm_request.id_dep_clin_serv%TYPE,
        i_pref_room         IN adm_request.id_pref_room%TYPE,
        i_mixed_nursing     IN adm_request.flg_mixed_nursing%TYPE,
        i_bed_type          IN adm_request.id_bed_type%TYPE, --40
        i_dest_prof         IN adm_request.id_dest_prof%TYPE,
        i_adm_preparation   IN adm_request.id_adm_preparation%TYPE,
        i_dt_admission      IN VARCHAR2,
        i_expect_duration   IN adm_request.expected_duration%TYPE,
        i_notes_adm         IN adm_request.notes%TYPE, --45
        i_nit_flg           IN adm_request.flg_nit%TYPE,
        i_nit_dt_suggested  IN VARCHAR2,
        i_nit_dcs           IN adm_request.id_nit_dcs%TYPE,
        i_external_request  IN p1_external_request.id_external_request%TYPE,
        i_func_eval_score   IN waiting_list.func_eval_score%TYPE DEFAULT NULL, --50
        i_notes_edit        IN waiting_list.notes_edit%TYPE DEFAULT NULL,
        --Barthel Index Template
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE, --55
        i_doc_flg_type          IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar, --60
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_wtl_change            IN VARCHAR2, --65
        --SYS_ALERT 64
        i_profs_alert IN table_number DEFAULT NULL,
        --ALERT-14505 - POS Validation Request
        i_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested IN VARCHAR2,
        i_pos_req_notes    IN sr_pos_schedule.req_notes%TYPE,
        i_decision_notes   IN sr_pos_schedule.decision_notes%TYPE,
        -- Surgical supplies
        i_supply           IN table_table_number, --70
        i_supply_set       IN table_table_number,
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number, --75
        i_flg_cons_type    IN table_table_varchar,
        --
        i_description_sp    IN table_varchar,
        i_id_sr_epis_interv IN table_number,
        i_id_req_reason     IN table_table_number,
        i_supply_notes      IN table_table_varchar, --80
        i_surgery_record    IN table_number,
        i_prof_team         IN table_number,
        i_tbl_prof          IN table_table_number,
        i_tbl_catg          IN table_table_number,
        i_tbl_status        IN table_table_varchar, --85
        i_test              IN VARCHAR2,
        --Diagnosis information
        i_diagnosis_adm_req   IN pk_edis_types.rec_in_epis_diagnosis,
        i_diagnosis_surg_proc IN pk_edis_types.table_in_epis_diagnosis,
        i_diagnosis_contam    IN pk_edis_types.rec_in_epis_diagnosis,
        -- clinical decision rules 
        i_id_cdr_call IN cdr_call.id_cdr_call%TYPE, --90
        i_id_ct_io    IN table_table_varchar DEFAULT NULL,
        --Chile Market
        i_regimen                 IN VARCHAR2 DEFAULT NULL,
        i_beneficiario            IN VARCHAR2 DEFAULT NULL,
        i_precauciones            IN VARCHAR2 DEFAULT NULL,
        i_contactado              IN VARCHAR2 DEFAULT NULL, --95
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_table_clob DEFAULT NULL,
        i_id_inst_dest            IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set               IN VARCHAR2, --100
        i_global_anesth           IN VARCHAR2 DEFAULT NULL,
        i_local_anesth            IN VARCHAR2 DEFAULT NULL,
        i_id_mrp                  IN NUMBER DEFAULT NULL,
        i_id_written_by           IN NUMBER DEFAULT NULL,
        i_ri_prof_spec            IN NUMBER DEFAULT NULL, --105
        i_flg_compulsory          IN VARCHAR2 DEFAULT NULL,
        i_id_compulsory_reason    IN adm_request.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason       IN adm_request.compulsory_reason%TYPE DEFAULT NULL,
        o_adm_request             OUT adm_request.id_adm_request%TYPE,
        o_msg_error               OUT VARCHAR2,
        o_title_error             OUT VARCHAR2,
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ADM_SURG_REQUEST';
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE;
        l_internal_error EXCEPTION;
        l_rowids         table_varchar;
        --
        l_bed_request     CONSTANT VARCHAR2(1) := 'B'; -- Bed (or Admission Request)
        l_surgery_request CONSTANT VARCHAR2(1) := 'S'; -- Surgery Request
        l_all_requests    CONSTANT VARCHAR2(1) := 'A'; -- All (Both)
        --
        l_id_patient         patient.id_patient%TYPE;
        l_id_waiting_list    waiting_list.id_waiting_list%TYPE;
        l_current_wl_status  waiting_list.flg_status%TYPE;
        l_id_schedule        schedule.id_schedule%TYPE;
        l_id_episode_sr      episode.id_episode%TYPE;
        l_id_episode_inp     episode.id_episode%TYPE;
        l_prev_epis_type     epis_type.id_epis_type%TYPE;
        l_id_room_inp        epis_info.id_room%TYPE;
        l_visit              visit.id_visit%TYPE;
        l_nit_dt_suggested   TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_prof_cat       category.flg_type%TYPE;
        l_adm_request        adm_request.id_adm_request%TYPE;
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        l_episode_oris      episode.id_episode%TYPE;
        l_schedule          schedule.id_schedule%TYPE;
        l_schedule_sr       schedule_sr.id_schedule_sr%TYPE;
        l_epis_type         epis_type.id_epis_type%TYPE;
        l_oris_epis_type    epis_type.id_epis_type%TYPE;
        l_cod_epis_type_ext VARCHAR2(4);
        l_prev_episode      episode.id_episode%TYPE;
    
        /*BEGIN ALERT 34065*/
        l_id_dcs_requested dep_clin_serv.id_dep_clin_serv%TYPE := NULL;
        /*END ALERT 34065*/
    
        --Scheduler 3.0 variables DO NOT REMOVE
        l_transaction_id  VARCHAR2(4000);
        o_ref_map         ref_map.id_ref_map%TYPE := NULL;
        l_rows            table_varchar := table_varchar();
        l_flg_ins_upd     VARCHAR2(1 CHAR);
        l_exception_dates EXCEPTION;
    
        PROCEDURE inactivate_adm_diag_req(i_id_adm_req IN adm_req_diagnosis.id_adm_request%TYPE) IS
            l_adm_req_diag table_number := table_number();
        BEGIN
        
            SELECT ard.id_adm_req_diagnosis
              BULK COLLECT
              INTO l_adm_req_diag
              FROM adm_req_diagnosis ard
             WHERE ard.id_adm_request = i_id_adm_req
               AND ard.flg_status = pk_alert_constant.g_active;
        
            FOR i IN 1 .. l_adm_req_diag.count()
            LOOP
            
                ts_adm_req_diagnosis.upd(id_adm_req_diagnosis_in => l_adm_req_diag(i),
                                         flg_status_in           => pk_alert_constant.g_outdated);
            END LOOP;
        
        END;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        -- Set current date. Use this date for ALL records that need the current date.
        l_sysdate         := current_timestamp;
        l_id_patient      := i_id_patient;
        l_id_waiting_list := io_id_waiting_list;
    
        g_error := 'GET PROF CATEGORY';
        pk_alertlog.log_debug(g_error);
        l_flg_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Get waiting list current status
        IF l_id_waiting_list IS NOT NULL
        THEN
            g_error := 'GET WAITING LIST STATUS';
            pk_alertlog.log_debug(g_error);
            SELECT wl.flg_status
              INTO l_current_wl_status
              FROM waiting_list wl
             WHERE wl.id_waiting_list = l_id_waiting_list;
        ELSE
            l_current_wl_status := 'I'; -- If its a new record, create as INACTIVE
        END IF;
    
        g_error := 'CALL TO SET_WAITING_LIST'; -- Create a new waiting list, or add a new record to the history
        pk_alertlog.log_debug(g_error);
        IF NOT set_waiting_list(i_lang              => i_lang,
                                i_prof              => i_prof,
                                id_patient_in       => i_id_patient,
                                id_prof_req_in      => i_prof.id,
                                flg_type_in         => i_flg_type,
                                flg_status_in       => l_current_wl_status,
                                id_prof_reg_in      => i_prof.id,
                                dt_reg_in           => l_sysdate,
                                id_external_request => i_external_request,
                                id_waiting_list_io  => l_id_waiting_list,
                                notes_edit          => i_notes_edit,
                                i_order_set         => i_order_set,
                                o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'get id_visit'; -- get surgery id_visit 
        pk_alertlog.log_debug(g_error);
        IF io_id_episode_sr IS NOT NULL
           AND io_id_episode_inp IS NULL
        THEN
            BEGIN
                SELECT e.id_visit
                  INTO l_visit
                  FROM episode e
                 WHERE e.id_episode = io_id_episode_sr;
            EXCEPTION
                WHEN no_data_found THEN
                    l_visit := NULL;
            END;
        END IF;
    
        -- Set common data between Admission and Surgery Request
        g_error := 'CALL TO SET_WAITING_LIST_INFO';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_wtl_prv_core.set_waiting_list_info(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_id_patient            => l_id_patient,
                                                     i_id_waiting_list       => l_id_waiting_list,
                                                     i_id_wtl_urg_level      => i_id_wtl_urg_level,
                                                     i_dt_sched_period_start => i_dt_sched_period_start,
                                                     i_dt_sched_period_end   => i_dt_sched_period_end,
                                                     i_min_inform_time       => i_min_inform_time,
                                                     i_dt_surgery            => i_dt_surgery,
                                                     i_dt_admission          => i_dt_admission,
                                                     i_unav_period_start     => i_unav_period_start,
                                                     i_unav_period_end       => i_unav_period_end,
                                                     o_msg_error             => o_msg_error,
                                                     o_title_error           => o_title_error,
                                                     o_error                 => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF o_msg_error IS NOT NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -- ADMISSION REQUEST --
        IF i_flg_type IN (l_bed_request, l_all_requests)
           OR (i_flg_type = l_surgery_request AND i_adm_needed = pk_alert_constant.g_yes)
        THEN
        
            l_id_episode_inp := io_id_episode_inp;
        
            IF i_nit_dt_suggested IS NOT NULL
            THEN
                l_nit_dt_suggested := pk_date_utils.get_string_tstz(i_lang, i_prof, i_nit_dt_suggested, NULL);
            END IF;
        
            g_error := 'CALL TO SET_ADMISSION_REQUEST';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_admission_request.set_adm_request(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_req_episode           => i_id_episode,
                                                        i_patient               => i_id_patient,
                                                        i_adm_indication        => i_adm_indication,
                                                        i_adm_ind_desc          => i_adm_ind_desc,
                                                        i_dest_inst             => i_dest_inst,
                                                        i_adm_type              => i_adm_type,
                                                        i_department            => i_department,
                                                        i_room_type             => i_room_type,
                                                        i_dep_clin_serv         => i_dep_clin_serv_adm,
                                                        i_pref_room             => i_pref_room,
                                                        i_mixed_nursing         => i_mixed_nursing,
                                                        i_bed_type              => i_bed_type,
                                                        i_dest_prof             => i_dest_prof,
                                                        i_adm_preparation       => i_adm_preparation,
                                                        i_expect_duration       => i_expect_duration,
                                                        i_notes                 => i_notes_adm,
                                                        i_flg_nit               => i_nit_flg,
                                                        i_dt_nit_suggested      => l_nit_dt_suggested,
                                                        i_nit_dcs               => i_nit_dcs,
                                                        i_timestamp             => l_sysdate,
                                                        i_waiting_list          => l_id_waiting_list,
                                                        i_dt_sched_period_start => i_dt_sched_period_start,
                                                        io_dest_episode         => l_id_episode_inp,
                                                        i_transaction_id        => l_transaction_id,
                                                        i_flg_process_event     => pk_alert_constant.g_no,
                                                        i_regimen               => i_regimen,
                                                        i_beneficiario          => i_beneficiario,
                                                        i_precauciones          => i_precauciones,
                                                        i_contactado            => i_contactado,
                                                        i_order_set             => i_order_set,
                                                        i_id_mrp                => i_id_mrp,
                                                        i_id_written_by         => i_id_written_by,
                                                        i_ri_prof_spec          => i_ri_prof_spec,
                                                        i_flg_compulsory        => i_flg_compulsory,
                                                        i_id_compulsory_reason  => i_id_compulsory_reason,
                                                        i_compulsory_reason     => i_compulsory_reason,
                                                        o_adm_request           => l_adm_request,
                                                        o_visit                 => l_visit, -- New or already existing visit
                                                        o_flg_ins_upd           => l_flg_ins_upd,
                                                        o_rows                  => l_rows,
                                                        o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        END IF;
    
        IF l_adm_request IS NOT NULL
        THEN
            o_adm_request := l_adm_request;
            inactivate_adm_diag_req(l_adm_request);
        END IF;
    
        IF i_dep_clin_serv_sr.exists(1)
        THEN
            l_id_dcs_requested := i_dep_clin_serv_sr(i_dep_clin_serv_sr.first);
        END IF;
    
        -- SURGERY REQUEST --       
        IF i_flg_type IN (l_surgery_request, l_all_requests)
           OR (i_flg_type = l_bed_request AND i_surg_needed = pk_alert_constant.g_yes)
        THEN
        
            IF io_id_episode_sr IS NULL
            THEN
                -- Create a new surgical episode
                g_error := 'CREATE SURGICAL EPISODE';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_visit.create_all_surgery_int(i_lang             => i_lang,
                                                          i_patient          => l_id_patient,
                                                          i_prof             => i_prof,
                                                          i_visit            => l_visit, -- Same visit as the INP episode!!
                                                          i_flg_ehr          => 'S', -- Scheduled episode
                                                          i_id_dcs_requested => l_id_dcs_requested, -- ALERT 30974*/
                                                          i_dt_creation      => NULL,
                                                          i_dt_begin         => NULL,
                                                          i_id_episode_ext   => NULL,
                                                          i_flg_migration    => NULL,
                                                          i_id_room          => NULL,
                                                          i_id_external_sys  => NULL,
                                                          i_inst_dest        => i_dest_inst,
                                                          o_episode_new      => l_id_episode_sr,
                                                          o_schedule         => l_id_schedule,
                                                          o_error            => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                BEGIN
                    SELECT ei.id_room
                      INTO l_id_room_inp
                      FROM episode e
                     INNER JOIN epis_info ei
                        ON e.id_episode = ei.id_episode
                     WHERE e.id_episode = i_id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_room_inp := NULL;
                END;
            
                IF l_id_room_inp IS NOT NULL
                THEN
                    ts_epis_info.upd(id_episode_in => l_id_episode_sr,
                                     id_room_in    => l_id_room_inp,
                                     rows_out      => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_INFO',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            
                l_rowids := NULL;
            
                g_error := 'UPDATE SCHEDULE_SR'; -- Set new waiting list in SCHEDULE_SR
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_rowids := table_varchar();
                ts_schedule_sr.upd(id_waiting_list_in  => l_id_waiting_list,
                                   id_waiting_list_nin => FALSE,
                                   where_in            => 'id_episode = ' || l_id_episode_sr,
                                   rows_out            => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SCHEDULE_SR',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_WAITING_LIST'));
            ELSE
                l_id_episode_sr := io_id_episode_sr;
            END IF;
        
            -- Set INPATIENT episode as a previous episode
            IF l_id_episode_inp IS NOT NULL
               AND i_id_episode IS NOT NULL
            THEN
                g_error := 'GET PREV EPIS TYPE - INP';
                pk_alertlog.log_debug(g_error);
                SELECT e.id_epis_type, ei.id_room
                  INTO l_prev_epis_type, l_id_room_inp
                  FROM episode e
                 INNER JOIN epis_info ei
                    ON e.id_episode = ei.id_episode
                 WHERE e.id_episode = i_id_episode;
            
                l_rowids := table_varchar();
                g_error  := 'GET PREV EPIS TYPE - INP - ' || l_id_episode_sr || ';' || i_id_episode || ';' ||
                            l_prev_epis_type;
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                ts_episode.upd(id_episode_in        => l_id_episode_sr,
                               id_prev_episode_in   => i_id_episode,
                               id_prev_epis_type_in => l_prev_epis_type,
                               rows_out             => l_rowids);
            
                g_error := 'PROCESS UPDATE - EPISODE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPISODE',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                IF l_id_room_inp IS NOT NULL
                THEN
                    ts_epis_info.upd(id_episode_in => l_id_episode_sr,
                                     id_room_in    => l_id_room_inp,
                                     rows_out      => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_INFO',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                END IF;
            
                l_rowids := NULL;
            END IF;
        
            -- Create or update surgery request data
            g_error := 'CALL TO SET_SURGERY_REQUEST';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            IF NOT pk_surgery_request.set_surgery_request(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_flg_prof_cat            => l_flg_prof_cat,
                                                          i_id_episode              => coalesce(i_id_episode,
                                                                                                l_id_episode_inp,
                                                                                                l_id_episode_sr),
                                                          i_id_episode_sr           => l_id_episode_sr,
                                                          i_id_patient              => l_id_patient,
                                                          i_id_waiting_list         => l_id_waiting_list,
                                                          i_sysdate                 => l_sysdate,
                                                          i_professionals           => i_pref_surgeons,
                                                          i_external_dcs            => i_external_dcs,
                                                          i_dep_clin_serv           => i_dep_clin_serv_sr,
                                                          i_speciality              => i_speciality_sr,
                                                          i_department              => i_department_sr,
                                                          i_flg_pref_time           => i_flg_pref_time,
                                                          i_reason_pref_time        => i_reason_pref_time,
                                                          i_id_sr_intervention      => i_id_sr_intervention,
                                                          i_flg_type                => i_flg_principal,
                                                          i_codification            => i_codification,
                                                          i_flg_laterality          => i_flg_laterality,
                                                          i_surgical_site           => i_surgical_site,
                                                          i_sp_notes                => i_sp_notes,
                                                          i_duration                => i_duration,
                                                          i_icu                     => i_icu,
                                                          i_icu_pos                 => i_icu_pos,
                                                          i_notes                   => i_notes_surg,
                                                          i_adm_needed              => i_adm_needed,
                                                          i_id_sr_pos_status        => i_id_sr_pos_status,
                                                          i_sr_pos_schedule         => i_sr_pos_schedule,
                                                          i_dt_pos_suggested        => i_dt_pos_suggested,
                                                          i_decision_notes          => i_decision_notes,
                                                          i_pos_req_notes           => i_pos_req_notes,
                                                          i_supply                  => i_supply,
                                                          i_supply_set              => i_supply_set,
                                                          i_supply_qty              => i_supply_qty,
                                                          i_supply_loc              => i_supply_loc,
                                                          i_dt_return               => i_dt_return,
                                                          i_supply_soft_inst        => i_supply_soft_inst,
                                                          i_flg_cons_type           => i_flg_cons_type,
                                                          i_description_sp          => i_description_sp,
                                                          i_id_sr_epis_interv       => i_id_sr_epis_interv,
                                                          i_id_req_reason           => i_id_req_reason,
                                                          i_supply_notes            => i_supply_notes,
                                                          i_surgery_record          => i_surgery_record,
                                                          i_prof_team               => i_prof_team,
                                                          i_tbl_prof                => i_tbl_prof,
                                                          i_tbl_catg                => i_tbl_catg,
                                                          i_tbl_status              => i_tbl_status,
                                                          i_test                    => i_test,
                                                          i_diagnosis_surg_proc     => i_diagnosis_surg_proc,
                                                          i_diagnosis_contam        => i_diagnosis_contam,
                                                          i_id_cdr_call             => i_id_cdr_call,
                                                          i_id_ct_io                => i_id_ct_io,
                                                          i_clinical_question       => i_clinical_question,
                                                          i_response                => i_response,
                                                          i_clinical_question_notes => i_clinical_question_notes,
                                                          i_id_inst_dest            => i_id_inst_dest,
                                                          i_global_anesth           => i_global_anesth,
                                                          i_local_anesth            => i_local_anesth,
                                                          o_error                   => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF l_adm_request IS NOT NULL
           AND i_diagnosis_adm_req.tbl_diagnosis IS NOT NULL
           AND i_diagnosis_adm_req.tbl_diagnosis.count > 0
        THEN
            g_error := 'SET ADMISSION REQUEST DIAGNOSIS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_admission_request.set_diagnosis(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_diagnosis_adm_req => i_diagnosis_adm_req,
                                                      i_adm_request       => l_adm_request,
                                                      i_episode_inp       => l_id_episode_inp,
                                                      i_episode_sr        => l_id_episode_sr,
                                                      i_timestamp         => l_sysdate,
                                                      i_id_cdr_call       => i_id_cdr_call,
                                                      o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_id_episode_sr IS NOT NULL
        THEN
            -- Set WTL_EPIS for the surgical episode
            g_error := 'CALL TO SET_WTL_EPIS - SR';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_wtl_prv_core.set_wtl_epis(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_episode      => l_id_episode_sr,
                                                i_id_waiting_list => l_id_waiting_list,
                                                i_id_schedule     => l_id_schedule, -- IMPORTANT: used to warn Scheduler Team if its necessary a new record in SCHEDULE_SR
                                                o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_id_episode_inp IS NULL
               AND i_id_episode IS NOT NULL
            THEN
                g_error := 'GET PREV EPIS TYPE - surg';
                pk_alertlog.log_debug(g_error);
                SELECT e.id_epis_type
                  INTO l_prev_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                l_rowids := table_varchar();
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                ts_episode.upd(id_episode_in        => l_id_episode_sr,
                               id_prev_episode_in   => i_id_episode,
                               id_prev_epis_type_in => l_prev_epis_type,
                               rows_out             => l_rowids);
            
                g_error := 'PROCESS UPDATE - EPISODE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPISODE',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                l_rowids := table_varchar();
            END IF;
        END IF;
    
        -- Set WTL_EPIS for the inpatient episode
        -- Alterado apenas para fazer um teste...
        IF l_id_episode_inp IS NOT NULL
        THEN
            g_error := 'CALL TO SET_WTL_EPIS - INP';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_wtl_prv_core.set_wtl_epis(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_episode      => l_id_episode_inp,
                                                i_id_waiting_list => l_id_waiting_list,
                                                i_id_schedule     => NULL,
                                                o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        l_epis_documentation := i_epis_documentation;
        IF i_doc_template IS NOT NULL
        THEN
            g_error := 'CALL TO pk_touch_option.set_epis_document_internal';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_prof_cat_type         => i_prof_cat_type,
                                                              i_epis                  => l_id_episode_inp, --@ToDo confirmar episódio INP
                                                              i_doc_area              => i_doc_area,
                                                              i_doc_template          => i_doc_template,
                                                              i_epis_documentation    => i_epis_documentation,
                                                              i_flg_type              => i_doc_flg_type,
                                                              i_id_documentation      => i_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_notes                 => i_notes,
                                                              i_id_epis_complaint     => NULL,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_epis_context          => i_epis_context,
                                                              i_episode_context       => io_id_episode_sr, --@ToDo confirmar episódio SR
                                                              o_epis_documentation    => l_epis_documentation,
                                                              o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'CALL TO pk_clinical_notes.set_clinical_notes_doc_area';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_clinical_notes.set_clinical_notes_doc_area(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_episode  => io_id_episode_sr,
                                                                 i_id_doc_area => i_doc_area,
                                                                 i_desc        => i_summary_and_notes,
                                                                 o_error       => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF l_epis_documentation IS NOT NULL
        THEN
            g_error := 'CALL manage_wtl_func_eval';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT manage_wtl_func_eval(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_waiting_list       => l_id_waiting_list,
                                        i_epis_documentation => l_epis_documentation,
                                        i_wtl_change         => i_wtl_change,
                                        o_error              => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        -- associate referral with episodes
        IF i_external_request IS NOT NULL
        THEN
            IF l_id_episode_inp IS NOT NULL
            THEN
                g_error := 'CALL pk_api_ref_circle.set_ref_map_episode';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT pk_api_ref_circle.set_ref_map_episode(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_ref     => i_external_request,
                                                             i_episode => l_id_episode_inp,
                                                             o_ref_map => o_ref_map,
                                                             o_error   => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            IF l_id_episode_sr IS NOT NULL
            THEN
                g_error := 'CALL pk_api_ref_circle.set_ref_map_episode';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT pk_api_ref_circle.set_ref_map_episode(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_ref     => i_external_request,
                                                             i_episode => l_id_episode_sr,
                                                             o_ref_map => o_ref_map,
                                                             o_error   => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        END IF;
    
        -- Finally: check status of waiting list
        g_error := 'CALL TO PK_WTL_PBL_CORE.CHECK_WTLIST_STATUS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF i_order_set != pk_alert_constant.g_yes
        THEN
            IF NOT pk_wtl_pbl_core.check_wtlist_status(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_wtlist  => l_id_waiting_list,
                                                       i_adm_needed => i_adm_needed,
                                                       o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'CREATE ALERT 64';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT (i_profs_alert IS NULL OR i_profs_alert.count = 0)
            THEN
                pk_alertlog.log_info(text            => 'io_id_episode_inp: ' || io_id_episode_inp,
                                     object_name     => g_package_name,
                                     sub_object_name => l_func_name);
                pk_alertlog.log_info(text            => 'l_id_waiting_list: ' || l_id_waiting_list,
                                     object_name     => g_package_name,
                                     sub_object_name => l_func_name);
            
                IF NOT pk_admission_request.set_adm_req_alert(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_epis  => coalesce(io_id_episode_inp,
                                                                                  l_id_episode_inp,
                                                                                  i_id_episode),
                                                              i_wtl   => l_id_waiting_list,
                                                              i_profs => i_profs_alert,
                                                              o_error => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        END IF;
    
        g_error := 'i_flg_type: ' || i_flg_type || ' l_flg_ins_upd: ' || l_flg_ins_upd;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        --because it is necessary that the admission request event is raised only after the records being inserted in the wtl_epis table
        --because of the insertion in the task_timeline_ea table
        IF i_flg_type IN (l_bed_request, l_all_requests)
           OR (i_flg_type = l_surgery_request AND i_adm_needed = pk_alert_constant.g_yes)
        THEN
            IF (l_flg_ins_upd = pk_admission_request.g_update)
            THEN
                g_error := 'PROCESS ADM_REQUEST UPD';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                t_data_gov_mnt.process_update(i_lang, i_prof, 'ADM_REQUEST', l_rows, o_error);
            ELSE
                g_error := 'PROCESS ADM_REQUEST INS';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'ADM_REQUEST', l_rows, o_error);
            END IF;
        END IF;
    
        io_id_episode_inp  := l_id_episode_inp;
        io_id_episode_sr   := l_id_episode_sr;
        io_id_waiting_list := l_id_waiting_list;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            --
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN l_exception_dates THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            --
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            --
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END set_adm_surg_request;

    /***************************************************************************************************************
    * 
    * If all required conditions are met, the provided WTList is restored, and so are all of its related 
    * episodes and schedules.
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to cancel.
    * @param      i_id_cancel_reason  code of CANCEL_REASON.
    * @param      i_notes_cancel      Free text
    * @param      o_error             output in case of error
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-04-2009
    *
    ****************************************************************************************************/
    FUNCTION undelete_wtlist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_wtl         IN waiting_list.id_waiting_list%TYPE,
        i_id_epis        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wtl_id             waiting_list.id_waiting_list%TYPE;
        l_wtl_old_flg_status waiting_list.flg_status%TYPE;
        l_adm_req            adm_request.id_adm_request%TYPE;
        l_not_eligible       EXCEPTION;
        l_epis               table_number;
        l_epis_type          table_number;
        l_rez                VARCHAR2(1);
        l_transaction_id     VARCHAR2(4000);
        l_pos_rec_bck        sr_pos_schedule%ROWTYPE;
        l_rows               table_varchar;
    BEGIN
    
        g_error := 'CHECK IF WTL ENTRY IS ELIGIBLE FOR UNDELETION';
        IF NOT get_wtlist_is_undel(i_lang   => i_lang,
                                   i_prof   => i_prof,
                                   i_wtl_id => i_id_wtl,
                                   o_result => l_rez,
                                   o_error  => o_error)
        THEN
            RAISE l_not_eligible;
        END IF;
    
        IF l_rez = pk_alert_constant.g_no
        THEN
            RAISE l_not_eligible;
        END IF;
    
        g_error := 'GET WAITING LIST EPISODES';
        SELECT we.id_episode, we.id_epis_type
          BULK COLLECT
          INTO l_epis, l_epis_type
          FROM waiting_list wtl
         INNER JOIN wtl_epis we
            ON we.id_waiting_list = wtl.id_waiting_list
          JOIN episode e
            ON e.id_episode = we.id_episode
           AND e.flg_status = pk_alert_constant.g_flg_status_c
         WHERE wtl.id_waiting_list = i_id_wtl
           AND wtl.flg_status = pk_alert_constant.g_cancelled;
    
        IF l_epis.count > 0
        THEN
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            FOR i IN l_epis.first .. l_epis.last
            LOOP
            
                g_error := 'GET INP EPISODE';
                IF l_epis_type(i) = pk_alert_constant.g_epis_type_inpatient
                
                THEN
                
                    g_error := 'REACTIVATE EPISODES';
                    IF NOT pk_visit.set_reactivate_epis(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_epis        => l_epis(i),
                                                        i_transaction_id => l_transaction_id,
                                                        o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'GET ADM_REQUEST';
                
                    SELECT ar.id_adm_request
                      INTO l_adm_req
                      FROM adm_request ar
                     WHERE ar.id_dest_episode = l_epis(i)
                       AND ar.flg_status = pk_alert_constant.g_flg_status_c
                     ORDER BY ar.dt_upd;
                
                    g_error := 'RESTORE ADMISSION REQUEST';
                    IF NOT pk_admission_request.undelete_admission_req(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_id_adm_req => l_adm_req,
                                                                       o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                END IF;
            END LOOP;
        
        END IF;
    
        g_error := 'GET LAST WAITING_LIST_HIST';
        SELECT data.flg_status
          INTO l_wtl_old_flg_status
          FROM (SELECT wtlh.flg_status
                  FROM waiting_list_hist wtlh
                 WHERE wtlh.id_waiting_list = i_id_wtl
                 ORDER BY wtlh.create_time DESC) data
         WHERE rownum = 1;
    
        g_error  := 'REACTIVATE WTL';
        l_wtl_id := i_id_wtl;
        IF NOT set_waiting_list(i_lang              => i_lang,
                                i_prof              => i_prof,
                                flg_status_in       => l_wtl_old_flg_status,
                                id_prof_cancel_in   => NULL,
                                dt_cancel_in        => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE),
                                id_cancel_reason_in => NULL,
                                notes_cancel_in     => NULL,
                                id_waiting_list_io  => l_wtl_id,
                                o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        BEGIN
            SELECT pos.*
              INTO l_pos_rec_bck
              FROM waiting_list wtl
              JOIN schedule_sr ssr
                ON wtl.id_waiting_list = ssr.id_waiting_list
              JOIN sr_pos_schedule pos
                ON pos.id_schedule_sr = ssr.id_schedule_sr
               AND pos.flg_status = pk_alert_constant.g_cancelled
             WHERE wtl.id_waiting_list = i_id_wtl;
        EXCEPTION
            WHEN no_data_found THEN
                l_pos_rec_bck := NULL;
        END;
    
        IF l_pos_rec_bck.id_sr_pos_schedule IS NOT NULL
        THEN
        
            g_error := 'call ts_sr_pos_schedule.upd';
            ts_sr_pos_schedule.upd(id_sr_pos_schedule_in => l_pos_rec_bck.id_sr_pos_schedule,
                                   flg_status_in         => pk_alert_constant.g_active,
                                   id_prof_reg_in        => i_prof.id,
                                   dt_reg_in             => current_timestamp,
                                   rows_out              => l_rows);
        
            g_error := 'call t_data_gov_mnt.process_update SR_POS_SCHEDULE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            l_rows := table_varchar();
        
            g_error := 'call ts_sr_pos_schedule_hist.ins';
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_schedule_hist.ins(id_sr_pos_schedule_hist_in => ts_sr_pos_schedule_hist.next_key,
                                        id_sr_pos_schedule_in      => l_pos_rec_bck.id_sr_pos_schedule,
                                        id_sr_pos_status_in        => l_pos_rec_bck.id_sr_pos_status,
                                        id_schedule_sr_in          => l_pos_rec_bck.id_schedule_sr,
                                        flg_status_in              => l_pos_rec_bck.flg_status,
                                        id_prof_reg_in             => l_pos_rec_bck.id_prof_reg,
                                        dt_reg_in                  => l_pos_rec_bck.dt_reg,
                                        dt_pos_suggested_in        => l_pos_rec_bck.dt_pos_suggested,
                                        req_notes_in               => l_pos_rec_bck.req_notes,
                                        id_prof_req_in             => l_pos_rec_bck.id_prof_req,
                                        dt_req_in                  => l_pos_rec_bck.dt_req,
                                        dt_valid_in                => l_pos_rec_bck.dt_valid,
                                        valid_days_in              => l_pos_rec_bck.valid_days,
                                        decision_notes_in          => l_pos_rec_bck.decision_notes,
                                        id_prof_decision_in        => l_pos_rec_bck.id_prof_decision,
                                        dt_decision_in             => l_pos_rec_bck.dt_decision,
                                        rows_out                   => l_rows);
        
            g_error := 't_data_gov_mnt.process_insert SR_POS_SCHEDULE_HIST';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE_HIST',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            IF l_pos_rec_bck.id_pos_consult_req IS NOT NULL
            THEN
                g_error := 'call pk_consult_req.undo_cancel_consult_req';
                IF NOT pk_consult_req.undo_cancel_consult_req(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_consult_req => l_pos_rec_bck.id_pos_consult_req,
                                                              i_episode     => i_id_epis,
                                                              o_error       => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_not_eligible THEN
            --RAISE EXCEPTION
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_E028'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UNDELETE_WTLIST',
                                              'U',
                                              NULL,
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTL_REACTIVATE',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END undelete_wtlist;

    /***************************************************************************************************************
    * 
    * If all required conditions are met, the provided WTList is cancelled, and so are all of its related 
    * episodes and schedules.
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to cancel.
    * @param      i_id_cancel_reason  code of CANCEL_REASON.
    * @param      i_notes_cancel      Free text
    * @param      i_flg_rollback      This function makes rollback ('Y' - This function makes rollback; 'N' - This function only return false)
    * @param      o_msg_error         error message if this cancelation is not possible
    * @param      o_error             output in case of error
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-04-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_wtlist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_wtl_id           IN waiting_list.id_waiting_list%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN waiting_list.notes_cancel%TYPE,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        i_flg_rolback      IN VARCHAR2,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_inp  table_number;
        l_id_epis_oris table_number;
        l_adm_request  adm_request%ROWTYPE;
        e_status       EXCEPTION;
        e_cancel_epis  EXCEPTION;
        l_rez          VARCHAR2(1);
    
        l_wtl_id waiting_list.id_waiting_list%TYPE;
        -- SCH 3.0 variable
        l_transaction_id  VARCHAR2(4000);
        l_pos_rec_bck     sr_pos_schedule%ROWTYPE;
        l_rows            table_varchar;
        l_id_epis_origin  episode.id_episode%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CHECK IF WTL ENTRY IS ELIGIBLE FOR CANCELLATION';
        IF NOT get_wtlist_is_cancel(i_lang   => i_lang,
                                    i_prof   => i_prof,
                                    i_wtl_id => i_wtl_id,
                                    o_result => l_rez,
                                    o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_rez = pk_alert_constant.g_no
        THEN
            o_msg_error := pk_message.get_message(i_lang, 'ADM_REQUEST_E007');
            -- Only makes rollback if passed on function
            IF i_flg_rolback = pk_alert_constant.g_yes
            THEN
                RAISE e_status;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'GET EPISODES';
        SELECT (SELECT wle.id_episode
                  FROM wtl_epis wle
                 INNER JOIN episode ep
                    ON wle.id_episode = ep.id_episode
                  LEFT JOIN discharge dis
                    ON dis.id_episode = ep.id_episode
                   AND dis.flg_status NOT IN (pk_wtl_prv_core.g_wtlist_status_cancelled)
                 WHERE wle.id_waiting_list = i_wtl_id
                   AND dis.id_discharge IS NULL
                   AND ep.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND ep.flg_status = pk_wtl_prv_core.g_wtlist_status_active) ep_inp,
               (SELECT wle.id_episode
                  FROM wtl_epis wle
                 INNER JOIN episode ep
                    ON wle.id_episode = ep.id_episode
                  LEFT JOIN discharge dis
                    ON dis.id_episode = ep.id_episode
                   AND dis.flg_status NOT IN (pk_wtl_prv_core.g_wtlist_status_cancelled)
                 WHERE wle.id_waiting_list = i_wtl_id
                   AND dis.id_discharge IS NULL
                   AND ep.id_epis_type = pk_alert_constant.g_epis_type_operating
                   AND ep.flg_status = pk_wtl_prv_core.g_wtlist_status_active) ep_oris
          BULK COLLECT
          INTO l_id_epis_inp, l_id_epis_oris
          FROM dual;
    
        g_error := 'CANCEL ORIS EPISODES';
    
        FOR i IN l_id_epis_oris.first .. l_id_epis_oris.last
        LOOP
            IF l_id_epis_oris(i) IS NOT NULL
            THEN
            
                g_error := 'CALL CANCEL_EPISODE - OR';
                IF NOT pk_visit.call_cancel_episode(i_lang           => i_lang,
                                                    i_id_episode     => l_id_epis_oris(i),
                                                    i_prof           => i_prof,
                                                    i_cancel_reason  => i_notes_cancel,
                                                    i_transaction_id => l_transaction_id,
                                                    o_error          => o_error)
                THEN
                    --RETURN FALSE;
                    RAISE e_cancel_epis;
                END IF;
            
            END IF;
        END LOOP;
    
        g_error := 'CANCEL INP EPISODES';
    
        FOR i IN l_id_epis_inp.first .. l_id_epis_inp.last
        LOOP
            IF l_id_epis_inp(i) IS NOT NULL
            THEN
            
                g_error := 'GET ADM_REQUEST';
                SELECT ar.*
                  INTO l_adm_request
                  FROM adm_request ar
                 WHERE ar.id_dest_episode = l_id_epis_inp(i);
            
                --Cancel Co-Sign
            
                IF l_adm_request.id_co_sign_order IS NOT NULL
                THEN
                
                    pk_alertlog.error('Aqui - ' || l_adm_request.id_dest_episode);
                
                    SELECT b.id_prev_episode
                      INTO l_id_epis_origin
                      FROM adm_request a
                      JOIN episode b
                        ON a.id_dest_episode = b.id_episode
                     WHERE a.id_adm_request = l_adm_request.id_adm_request;
                
                    IF NOT pk_co_sign_api.set_task_outdated(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => l_id_epis_origin,
                                                            i_id_co_sign      => l_adm_request.id_co_sign_order,
                                                            i_id_co_sign_hist => NULL,
                                                            i_dt_update       => current_timestamp,
                                                            o_id_co_sign_hist => l_id_co_sign_hist,
                                                            o_error           => o_error)
                    THEN
                        RAISE e_cancel_epis;
                    END IF;
                END IF;
            
                ts_adm_request.upd(id_adm_request_in    => l_adm_request.id_adm_request,
                                   id_co_sign_cancel_in => l_id_co_sign_hist,
                                   rows_out             => l_rows);
            
                t_data_gov_mnt.process_update(i_lang, i_prof, 'ADM_REQUEST', l_rows, o_error);
            
                g_error := 'CALL CANCEL_EPISODE - INP';
                IF NOT pk_visit.call_cancel_episode(i_lang           => i_lang,
                                                    i_id_episode     => l_id_epis_inp(i),
                                                    i_prof           => i_prof,
                                                    i_cancel_reason  => i_notes_cancel,
                                                    i_cancel_type    => 'A',
                                                    i_transaction_id => l_transaction_id,
                                                    o_error          => o_error)
                THEN
                    --RETURN FALSE;
                    RAISE e_cancel_epis;
                END IF;
            
                g_error := 'UPDATE ADM_REQUEST';
                IF NOT pk_admission_request.cancel_admission_request(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_id_adm_req => l_adm_request.id_adm_request,
                                                                     o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
        BEGIN
            SELECT pos.*
              INTO l_pos_rec_bck
              FROM waiting_list wtl
              JOIN schedule_sr ssr
                ON wtl.id_waiting_list = ssr.id_waiting_list
              JOIN sr_pos_schedule pos
                ON pos.id_schedule_sr = ssr.id_schedule_sr
               AND pos.flg_status NOT IN (pk_alert_constant.g_cancelled)
             WHERE wtl.id_waiting_list = i_wtl_id;
        EXCEPTION
            WHEN no_data_found THEN
                l_pos_rec_bck := NULL;
        END;
    
        IF l_pos_rec_bck.id_sr_pos_schedule IS NOT NULL
        THEN
        
            g_error := 'call ts_sr_pos_schedule.upd';
            ts_sr_pos_schedule.upd(id_sr_pos_schedule_in => l_pos_rec_bck.id_sr_pos_schedule,
                                   flg_status_in         => pk_alert_constant.g_cancelled,
                                   id_prof_reg_in        => i_prof.id,
                                   dt_reg_in             => current_timestamp,
                                   rows_out              => l_rows);
        
            g_error := 'call t_data_gov_mnt.process_update SR_POS_SCHEDULE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            l_rows := table_varchar();
        
            g_error := 'call ts_sr_pos_schedule_hist.ins';
            pk_alertlog.log_debug(g_error);
            ts_sr_pos_schedule_hist.ins(id_sr_pos_schedule_hist_in => ts_sr_pos_schedule_hist.next_key,
                                        id_sr_pos_schedule_in      => l_pos_rec_bck.id_sr_pos_schedule,
                                        id_sr_pos_status_in        => l_pos_rec_bck.id_sr_pos_status,
                                        id_schedule_sr_in          => l_pos_rec_bck.id_schedule_sr,
                                        flg_status_in              => l_pos_rec_bck.flg_status,
                                        id_prof_reg_in             => l_pos_rec_bck.id_prof_reg,
                                        dt_reg_in                  => l_pos_rec_bck.dt_reg,
                                        dt_pos_suggested_in        => l_pos_rec_bck.dt_pos_suggested,
                                        req_notes_in               => l_pos_rec_bck.req_notes,
                                        id_prof_req_in             => l_pos_rec_bck.id_prof_req,
                                        dt_req_in                  => l_pos_rec_bck.dt_req,
                                        dt_valid_in                => l_pos_rec_bck.dt_valid,
                                        valid_days_in              => l_pos_rec_bck.valid_days,
                                        decision_notes_in          => l_pos_rec_bck.decision_notes,
                                        id_prof_decision_in        => l_pos_rec_bck.id_prof_decision,
                                        dt_decision_in             => l_pos_rec_bck.dt_decision,
                                        rows_out                   => l_rows);
        
            g_error := 't_data_gov_mnt.process_insert SR_POS_SCHEDULE_HIST';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_POS_SCHEDULE_HIST',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END IF;
    
        g_error  := 'UPDATE WAITING_LIST - CANCEL';
        l_wtl_id := i_wtl_id;
        IF NOT set_waiting_list(i_lang              => i_lang,
                                i_prof              => i_prof,
                                flg_status_in       => pk_wtl_prv_core.g_wtlist_status_cancelled,
                                id_prof_cancel_in   => i_prof.id,
                                dt_cancel_in        => current_timestamp,
                                id_cancel_reason_in => i_id_cancel_reason,
                                notes_cancel_in     => i_notes_cancel,
                                
                                id_waiting_list_io => l_wtl_id,
                                o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Scheduler 3.0. DO NOT REMOVE
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_cancel_epis THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              'CANCEL_EPIS',
                                              'ERROR CANCELLING EPISODE - ' || o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTLIST_CANCEL',
                                              o_error);
        
            -- will be needed when new scheduler is active  DO NOT REMOVE                                 
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN e_status THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'ADM_REQUEST_E007');
                l_ret           BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ADM_REQUEST_T060',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CANCEL_ADMISSION_REQUEST');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state();
                -- will be needed when new scheduler is active  DO NOT REMOVE                                 
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTLIST_CANCEL',
                                              o_error);
        
            -- will be needed when new scheduler is active  DO NOT REMOVE                                 
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
    END cancel_wtlist;

    /***************************************************************************************************************
    * 
    * Checks if the provided WL entry is eligible for cancelation
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to check.
    * @param      o_result            Y or N, wether the record is eligible for cancelation or not.
    * @param      o_error             output in case of error
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-04-2009
    *
    ****************************************************************************************************/
    FUNCTION get_wtlist_is_cancel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE,
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_acc NUMBER;
    BEGIN
        g_error := 'COUNT ELIGIBLE RESULTS';
    
        SELECT COUNT(wl.id_waiting_list)
          INTO l_acc
          FROM waiting_list wl
         WHERE wl.id_waiting_list = i_wtl_id
           AND wl.flg_status NOT IN (pk_wtl_prv_core.g_wtlist_status_partial,
                                     pk_wtl_prv_core.g_wtlist_status_schedule,
                                     pk_wtl_prv_core.g_wtlist_status_cancelled);
    
        g_error := 'CHECK WTLIST';
        IF l_acc > 0
        THEN
            o_result := 'Y';
        ELSE
            o_result := 'N';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_WTLIST_IS_CANCEL_AVAILABLE',
                                                     o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_wtlist_is_cancel;

    /***************************************************************************************************************
    *
    * Checks if the provided WL entry is eligible for cancelation. Same as previous function except this overload is callable
    * within SQL queries. 
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to check.    
    *
    * @RETURN  Y or N, if the record is eligible for cancelation or not.
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-04-2009
    *
    ****************************************************************************************************/
    FUNCTION get_wtlist_is_cancel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(1);
        l_error t_error_out;
    BEGIN
        IF NOT get_wtlist_is_cancel(i_lang   => i_lang,
                                    i_prof   => i_prof,
                                    i_wtl_id => i_wtl_id,
                                    o_result => l_ret,
                                    o_error  => l_error)
        THEN
            RETURN 'F';
        ELSE
            RETURN l_ret;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END get_wtlist_is_cancel;

    /***************************************************************************************************************
    * 
    * Checks if the provided WL entry is eligible for undeletion
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to check.
    * @param      o_result            Y or N, wether the record is eligible for undeletion or not.
    * @param      o_error             output in case of error
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   08-06-2009
    *
    ****************************************************************************************************/
    FUNCTION get_wtlist_is_undel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE,
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_acc            NUMBER;
        l_restore_period NUMBER;
    BEGIN
    
        g_error := 'GET RESTORE LIMIT';
        IF NOT pk_sysconfig.get_config(i_code_cf   => 'WTL_RESTORE_PERIOD',
                                       i_prof_inst => i_prof.institution,
                                       i_prof_soft => i_prof.software,
                                       o_msg_cf    => l_restore_period)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'COUNT ELIGIBLE RESULTS';
    
        SELECT COUNT(wl.id_waiting_list)
          INTO l_acc
          FROM waiting_list wl
         WHERE wl.id_waiting_list = i_wtl_id
           AND wl.flg_status IN (pk_wtl_prv_core.g_wtlist_status_cancelled)
           AND pk_date_utils.add_days_to_tstz(wl.dt_cancel, l_restore_period) > current_timestamp;
    
        g_error := 'CHECK WTLIST';
        IF l_acc > 0
        THEN
            o_result := 'Y';
        ELSE
            o_result := 'N';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_WTLIST_IS_UNDEL_AVAILABLE',
                                                     o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_wtlist_is_undel;

    /***************************************************************************************************************
    *
    * Checks if the provided WL entry is eligible for undelete. Same as previous function except this overload is callable
    * within SQL queries. 
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to check.    
    *
    * @RETURN  Y or N, if the record is eligible for undelete or not.
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   08-06-2009
    *
    ****************************************************************************************************/
    FUNCTION get_wtlist_is_undel
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_wtl_id waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(1);
        l_error t_error_out;
    BEGIN
        IF NOT get_wtlist_is_undel(i_lang   => i_lang,
                                   i_prof   => i_prof,
                                   i_wtl_id => i_wtl_id,
                                   o_result => l_ret,
                                   o_error  => l_error)
        THEN
            RETURN 'F';
        ELSE
            RETURN l_ret;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END get_wtlist_is_undel;

    /***************************************************************************************************************
    *
    *  Função de gravação da Waiting List
    * 
    * @param      i_lang              language ID
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   29-04-2009
    *
    ****************************************************************************************************/
    FUNCTION set_waiting_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        id_patient_in       IN waiting_list.id_patient%TYPE DEFAULT NULL,
        id_prof_req_in      IN waiting_list.id_prof_req%TYPE DEFAULT NULL,
        dt_placement_in     IN waiting_list.dt_placement%TYPE DEFAULT NULL,
        flg_type_in         IN waiting_list.flg_type%TYPE DEFAULT NULL,
        flg_status_in       IN waiting_list.flg_status%TYPE DEFAULT NULL,
        dt_dpb_in           IN waiting_list.dt_dpb%TYPE DEFAULT NULL,
        dt_dpa_in           IN waiting_list.dt_dpa%TYPE DEFAULT NULL,
        dt_surgery_in       IN waiting_list.dt_surgery%TYPE DEFAULT NULL,
        dt_admission_in     IN waiting_list.dt_admission%TYPE DEFAULT NULL,
        min_inform_time_in  IN waiting_list.min_inform_time%TYPE DEFAULT NULL,
        id_wtl_urg_level_in IN waiting_list.id_wtl_urg_level%TYPE DEFAULT NULL,
        id_prof_reg_in      IN waiting_list.id_prof_reg%TYPE DEFAULT NULL,
        dt_reg_in           IN waiting_list.dt_reg%TYPE DEFAULT NULL,
        id_cancel_reason_in IN waiting_list.id_cancel_reason%TYPE DEFAULT NULL,
        notes_cancel_in     IN waiting_list.notes_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_in   IN waiting_list.id_prof_cancel%TYPE DEFAULT NULL,
        dt_cancel_in        IN waiting_list.dt_cancel%TYPE DEFAULT NULL,
        id_external_request IN waiting_list.id_external_request%TYPE DEFAULT NULL,
        func_eval_score     IN waiting_list.func_eval_score%TYPE DEFAULT NULL,
        notes_edit          IN waiting_list.notes_edit%TYPE DEFAULT NULL,
        i_order_set         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        id_waiting_list_io  IN OUT waiting_list.id_waiting_list%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wtlist     waiting_list%ROWTYPE;
        l_wtlist_bck waiting_list%ROWTYPE;
        l_rows       table_varchar;
        l_ret        BOOLEAN;
    BEGIN
        BEGIN
            g_error := 'GET RECORD';
            SELECT wtl.*
              INTO l_wtlist_bck
              FROM waiting_list wtl
             WHERE wtl.id_waiting_list = id_waiting_list_io;
        EXCEPTION
            WHEN no_data_found THEN
                id_waiting_list_io           := ts_waiting_list.next_key;
                l_wtlist_bck.id_waiting_list := NULL;
        END;
    
        g_error                   := 'PREPARE RECORD';
        l_wtlist.id_waiting_list  := id_waiting_list_io;
        l_wtlist.id_patient       := nvl(id_patient_in, l_wtlist_bck.id_patient);
        l_wtlist.id_prof_req      := nvl(id_prof_req_in, l_wtlist_bck.id_prof_req);
        l_wtlist.dt_placement     := nvl(dt_placement_in, l_wtlist_bck.dt_placement);
        l_wtlist.flg_type         := nvl(flg_type_in, l_wtlist_bck.flg_type);
        l_wtlist.flg_status := CASE
                                   WHEN i_order_set = pk_alert_constant.g_yes THEN
                                    'PD'
                                   ELSE
                                    nvl(flg_status_in, l_wtlist_bck.flg_status)
                               END;
        l_wtlist.dt_dpb           := nvl(dt_dpb_in, l_wtlist_bck.dt_dpb);
        l_wtlist.dt_dpa           := nvl(dt_dpa_in, l_wtlist_bck.dt_dpa);
        l_wtlist.dt_surgery       := nvl(dt_surgery_in, l_wtlist_bck.dt_surgery);
        l_wtlist.dt_admission     := nvl(dt_admission_in, l_wtlist_bck.dt_admission);
        l_wtlist.min_inform_time  := nvl(min_inform_time_in, l_wtlist_bck.min_inform_time);
        l_wtlist.id_wtl_urg_level := nvl(id_wtl_urg_level_in, l_wtlist_bck.id_wtl_urg_level);
        l_wtlist.id_prof_reg      := nvl(id_prof_reg_in, l_wtlist_bck.id_prof_reg);
        l_wtlist.dt_reg           := nvl(dt_reg_in, l_wtlist_bck.dt_reg);
        l_wtlist.id_cancel_reason := id_cancel_reason_in;
        l_wtlist.notes_cancel     := notes_cancel_in;
        l_wtlist.id_prof_cancel   := id_prof_cancel_in;
        l_wtlist.dt_cancel        := dt_cancel_in;
    
        l_wtlist.id_external_request := nvl(id_external_request, l_wtlist_bck.id_external_request);
        l_wtlist.func_eval_score     := nvl(func_eval_score, l_wtlist_bck.func_eval_score);
        l_wtlist.notes_edit          := nvl(notes_edit, l_wtlist_bck.notes_edit);
    
        g_error := 'CHECK CHANGES';
        IF NOT pk_wtl_prv_core.check_changes(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_wtl     => l_wtlist,
                                             i_wtl_old => l_wtlist_bck,
                                             o_result  => l_ret,
                                             o_error   => o_error)
        THEN
        
            RETURN FALSE;
        END IF;
    
        IF l_ret
        
        THEN
        
            g_error := 'UPDATE OR INSERT RECORD';
            ts_waiting_list.upd(id_waiting_list_in     => l_wtlist.id_waiting_list,
                                id_patient_in          => l_wtlist.id_patient,
                                id_prof_req_in         => l_wtlist.id_prof_req,
                                dt_placement_in        => l_wtlist.dt_placement,
                                flg_type_in            => l_wtlist.flg_type,
                                flg_status_in          => l_wtlist.flg_status,
                                dt_dpb_in              => l_wtlist.dt_dpb,
                                dt_dpa_in              => l_wtlist.dt_dpa,
                                dt_surgery_in          => l_wtlist.dt_surgery,
                                dt_admission_in        => l_wtlist.dt_admission,
                                min_inform_time_in     => l_wtlist.min_inform_time,
                                id_wtl_urg_level_in    => l_wtlist.id_wtl_urg_level,
                                id_prof_reg_in         => l_wtlist.id_prof_reg,
                                dt_reg_in              => l_wtlist.dt_reg,
                                id_cancel_reason_in    => l_wtlist.id_cancel_reason,
                                id_cancel_reason_nin   => FALSE,
                                notes_cancel_in        => l_wtlist.notes_cancel,
                                notes_cancel_nin       => FALSE,
                                id_prof_cancel_in      => l_wtlist.id_prof_cancel,
                                id_prof_cancel_nin     => FALSE,
                                dt_cancel_in           => l_wtlist.dt_cancel,
                                dt_cancel_nin          => FALSE,
                                id_external_request_in => l_wtlist.id_external_request,
                                func_eval_score_in     => l_wtlist.func_eval_score,
                                notes_edit_in          => l_wtlist.notes_edit,
                                rows_out               => l_rows);
            IF SQL%ROWCOUNT = 0
            THEN
                ts_waiting_list.ins(id_waiting_list_in     => l_wtlist.id_waiting_list,
                                    id_patient_in          => l_wtlist.id_patient,
                                    id_prof_req_in         => l_wtlist.id_prof_req,
                                    dt_placement_in        => l_wtlist.dt_placement,
                                    flg_type_in            => l_wtlist.flg_type,
                                    flg_status_in          => l_wtlist.flg_status,
                                    dt_dpb_in              => l_wtlist.dt_dpb,
                                    dt_dpa_in              => l_wtlist.dt_dpa,
                                    dt_surgery_in          => l_wtlist.dt_surgery,
                                    dt_admission_in        => l_wtlist.dt_admission,
                                    min_inform_time_in     => l_wtlist.min_inform_time,
                                    id_wtl_urg_level_in    => l_wtlist.id_wtl_urg_level,
                                    id_prof_reg_in         => l_wtlist.id_prof_reg,
                                    dt_reg_in              => l_wtlist.dt_reg,
                                    id_cancel_reason_in    => l_wtlist.id_cancel_reason,
                                    notes_cancel_in        => l_wtlist.notes_cancel,
                                    id_prof_cancel_in      => l_wtlist.id_prof_cancel,
                                    dt_cancel_in           => l_wtlist.dt_cancel,
                                    id_external_request_in => l_wtlist.id_external_request,
                                    func_eval_score_in     => l_wtlist.func_eval_score,
                                    notes_edit_in          => l_wtlist.notes_edit,
                                    rows_out               => l_rows);
            END IF;
        
            IF (l_wtlist_bck.id_waiting_list IS NOT NULL)
            THEN
                g_error := 'PROCESS UPDATE RECORD';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'WAITING_LIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
                l_rows := table_varchar();
            
                g_error := 'INSERT HISTORY';
                ts_waiting_list_hist.ins(id_waiting_list_hist_in => ts_waiting_list_hist.next_key,
                                         id_waiting_list_in      => l_wtlist_bck.id_waiting_list,
                                         id_patient_in           => l_wtlist_bck.id_patient,
                                         id_prof_req_in          => l_wtlist_bck.id_prof_req,
                                         dt_placement_in         => l_wtlist_bck.dt_placement,
                                         flg_type_in             => l_wtlist_bck.flg_type,
                                         flg_status_in           => l_wtlist_bck.flg_status,
                                         dt_dpb_in               => l_wtlist_bck.dt_dpb,
                                         dt_dpa_in               => l_wtlist_bck.dt_dpa,
                                         dt_surgery_in           => l_wtlist_bck.dt_surgery,
                                         dt_admission_in         => l_wtlist_bck.dt_admission,
                                         min_inform_time_in      => l_wtlist_bck.min_inform_time,
                                         id_wtl_urg_level_in     => l_wtlist_bck.id_wtl_urg_level,
                                         id_prof_reg_in          => l_wtlist_bck.id_prof_reg,
                                         dt_reg_in               => l_wtlist_bck.dt_reg,
                                         id_cancel_reason_in     => l_wtlist_bck.id_cancel_reason,
                                         notes_cancel_in         => l_wtlist_bck.notes_cancel,
                                         id_prof_cancel_in       => l_wtlist_bck.id_prof_cancel,
                                         dt_cancel_in            => l_wtlist_bck.dt_cancel,
                                         id_external_request_in  => l_wtlist_bck.id_external_request,
                                         func_eval_score_in      => l_wtlist_bck.func_eval_score,
                                         notes_edit_in           => l_wtlist_bck.notes_edit,
                                         rows_out                => l_rows);
            
                g_error := 'PROCESS INSERT HISTORY';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'WAITING_LIST_HIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            ELSE
                g_error := 'PROCESS INSERT RECORD';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'WAITING_LIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
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
                                              'SET_WAITING_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_waiting_list;

    /**************************************************************************
    * Gets the summary of an epis documentation (Eg. Barthel Index)           *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_episode                  episode id                            *
    * @param i_waiting_list             waiting list id                       *
    *                                                                         *
    * @param o_doc_area_register        Cursor with doc area data             *
    * @param o_doc_area_val             Documentation data for the patient's  *
    *                                   episode                               *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/07                            *
    **************************************************************************/
    FUNCTION get_summ_page_documentation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_waiting_list      IN wtl_documentation.id_waiting_list%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
        OPEN o_doc_area_register FOR
            SELECT ed.id_epis_documentation,
                   ed.id_doc_template,
                   pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   ed.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality,
                   ed.id_doc_area,
                   ed.flg_status,
                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', ed.flg_status, i_lang) desc_status,
                   decode(ed.id_episode, i_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                   ed.notes,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   pk_alert_constant.g_yes flg_detail,
                   pk_alert_constant.g_no flg_external
              FROM wtl_documentation wd
             INNER JOIN epis_documentation ed
                ON ed.id_epis_documentation = wd.id_epis_documentation
              LEFT JOIN doc_template dt
                ON dt.id_doc_template = ed.id_doc_template
             WHERE wd.id_waiting_list = i_waiting_list
             ORDER BY dt_last_update DESC;
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT ed.id_epis_documentation,
                   d.id_documentation,
                   d.id_doc_component,
                   decr.id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   dc.flg_type,
                   TRIM(pk_translation.get_translation(i_lang, decr.code_element_close)) desc_element,
                   TRIM(pk_translation.get_translation(i_lang, decr.code_element_view)) desc_element_view,
                   pk_touch_option.get_formatted_value(i_lang,
                                                       i_prof,
                                                       de.flg_type,
                                                       edd.value,
                                                       edd.value_properties,
                                                       de.input_mask,
                                                       de.flg_optional_value,
                                                       de.flg_element_domain_type,
                                                       de.code_element_domain) VALUE,
                   ed.id_doc_area,
                   decode(ed.id_episode, i_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                   edd.id_epis_documentation_det id_epis_documentation_det,
                   pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                   pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                   pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                   pk_alert_constant.g_no flg_external,
                   dtad.rank rank_component
              FROM wtl_documentation wd
             INNER JOIN epis_documentation ed
                ON ed.id_epis_documentation = wd.id_epis_documentation
             INNER JOIN epis_documentation_det edd
                ON edd.id_epis_documentation = ed.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
               AND d.flg_available = pk_alert_constant.g_available --
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
               AND dc.flg_available = pk_alert_constant.g_available
             WHERE wd.id_waiting_list = i_waiting_list
               AND (pk_translation.get_translation(i_lang, decr.code_element_close) IS NOT NULL OR
                   edd.value IS NOT NULL)
            UNION ALL
            SELECT epis_d.id_epis_documentation,
                   d.id_documentation,
                   dc.id_doc_component,
                   NULL id_doc_element_crit,
                   NULL dt_reg,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   dc.flg_type,
                   NULL desc_element,
                   NULL desc_element_view,
                   NULL VALUE,
                   epis_d.id_doc_area,
                   decode(epis_d.id_episode, i_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                   NULL id_epis_documentation_det,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   pk_alert_constant.g_no flg_external,
                   dtad.rank rank_component
              FROM documentation d
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
               AND dc.flg_available = pk_alert_constant.g_available
             INNER JOIN (SELECT DISTINCT ed.id_episode,
                                         ed.id_epis_documentation,
                                         ed.id_doc_area,
                                         ed.id_doc_template,
                                         d.id_documentation_parent
                           FROM wtl_documentation wd
                          INNER JOIN epis_documentation ed
                             ON ed.id_epis_documentation = wd.id_epis_documentation
                          INNER JOIN epis_documentation_det edd
                             ON edd.id_epis_documentation = ed.id_epis_documentation
                          INNER JOIN documentation d
                             ON d.id_documentation = edd.id_documentation
                            AND d.flg_available = pk_alert_constant.g_available
                          WHERE wd.id_waiting_list = i_waiting_list
                            AND d.id_documentation_parent IS NOT NULL) epis_d
                ON d.id_documentation = epis_d.id_documentation_parent
             INNER JOIN doc_template_area_doc dtad
                ON epis_d.id_doc_template = dtad.id_doc_template
               AND epis_d.id_doc_area = dtad.id_doc_area
               AND d.id_documentation = dtad.id_documentation
             WHERE dc.flg_type = pk_summary_page.g_doc_title
               AND d.flg_available = pk_alert_constant.g_available
             ORDER BY id_epis_documentation, id_doc_component, id_epis_documentation_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_page_documentation',
                                              o_error);
            RETURN FALSE;
    END get_summ_page_documentation;

    /********************************************************************************************
    * Returns all data for Admission and Surgery Request for a given waiting list.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_adm_request      Admission request data       
    * @param o_diag             Diagnoses
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_waiting_list     Remaining info. about the waiting list
    * @param o_unavailabilities List of unavailability periods
    * @param o_sched_period     Scheduling period
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_adm_request               OUT pk_types.cursor_type,
        o_diag                      OUT pk_types.cursor_type,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_waiting_list              OUT pk_types.cursor_type,
        o_unavailabilities          OUT pk_types.cursor_type,
        o_sched_period              OUT pk_types.cursor_type,
        o_referral                  OUT pk_types.cursor_type,
        o_doc_area_register         OUT pk_types.cursor_type,
        o_doc_area_val              OUT pk_types.cursor_type,
        o_doc_scales                OUT pk_types.cursor_type,
        o_pos_validation            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_info pk_types.cursor_type;
    
    BEGIN
    
        RETURN get_adm_surg_request(i_lang                      => i_lang,
                                    i_prof                      => i_prof,
                                    i_id_episode                => i_id_episode,
                                    i_id_waiting_list           => i_id_waiting_list,
                                    o_adm_request               => o_adm_request,
                                    o_diag                      => o_diag,
                                    o_surg_specs                => o_surg_specs,
                                    o_pref_surg                 => o_pref_surg,
                                    o_procedures                => o_procedures,
                                    o_ext_disc                  => o_ext_disc,
                                    o_danger_cont               => o_danger_cont,
                                    o_preferred_time            => o_preferred_time,
                                    o_pref_time_reason          => o_pref_time_reason,
                                    o_pos                       => o_pos,
                                    o_surg_request              => o_surg_request,
                                    o_waiting_list              => o_waiting_list,
                                    o_unavailabilities          => o_unavailabilities,
                                    o_sched_period              => o_sched_period,
                                    o_referral                  => o_referral,
                                    o_doc_area_register         => o_doc_area_register,
                                    o_doc_area_val              => o_doc_area_val,
                                    o_doc_scales                => o_doc_scales,
                                    o_pos_validation            => o_pos_validation,
                                    o_cancel_info               => l_cancel_info,
                                    o_interv_clinical_questions => o_interv_clinical_questions,
                                    o_error                     => o_error);
    END get_adm_surg_request;

    /********************************************************************************************
    * Returns all data for Admission and Surgery Request for a given waiting list.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_adm_request      Admission request data       
    * @param o_diag             Diagnoses
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_waiting_list     Remaining info. about the waiting list
    * @param o_unavailabilities List of unavailability periods
    * @param o_sched_period     Scheduling period
    * @param o_cancel_info      Cancelation Info
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_adm_request               OUT pk_types.cursor_type,
        o_diag                      OUT pk_types.cursor_type,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_waiting_list              OUT pk_types.cursor_type,
        o_unavailabilities          OUT pk_types.cursor_type,
        o_sched_period              OUT pk_types.cursor_type,
        o_referral                  OUT pk_types.cursor_type,
        o_doc_area_register         OUT pk_types.cursor_type,
        o_doc_area_val              OUT pk_types.cursor_type,
        o_doc_scales                OUT pk_types.cursor_type,
        o_pos_validation            OUT pk_types.cursor_type,
        o_cancel_info               OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name     VARCHAR2(200) := 'GET_ADM_SURG_REQUEST';
        l_runtime_error EXCEPTION;
    
        l_epis_type_sr  epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_operating;
        l_epis_type_inp epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_inpatient;
    
        l_id_episode_sr  episode.id_episode%TYPE;
        l_id_episode_inp episode.id_episode%TYPE;
    
        l_id_sr_pos_schedule sr_pos_schedule.id_sr_pos_schedule%TYPE;
    
        l_dummy_cursor pk_types.cursor_type;
    
        --Antonio.Neto 03-Dec-2010 Return Cancelation Info for Details screen ALERT-141801
        --Return Cancelation Info for Details screen
        FUNCTION get_cancelation_info(o_cancel_info OUT pk_types.cursor_type) RETURN BOOLEAN IS
            l_surg_req_reason     pk_translation.t_desc_translation;
            l_surg_req_prof_dt    waiting_list.dt_cancel%TYPE;
            l_surg_req_prof_notes waiting_list.notes_cancel%TYPE;
            l_surg_req_prof_name  professional.name%TYPE;
            l_surg_req_prof_spec  pk_translation.t_desc_translation;
            l_flg_status          waiting_list.flg_status%TYPE;
        BEGIN
            --Antonio.Neto 03-Dec-2010 Return Cancelation Info for Details screen ALERT-141801
            SELECT wtl.flg_status
              INTO l_flg_status
              FROM waiting_list wtl
             WHERE wtl.id_waiting_list = i_id_waiting_list;
        
            IF l_flg_status = pk_wtl_prv_core.g_wtlist_status_cancelled
            THEN
            
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, prf.id_professional) nick_name,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        prf.id_professional,
                                                        wtl.dt_cancel,
                                                        i_id_episode) desc_speciality,
                       pk_translation.get_translation(i_lang, cr.code_cancel_reason),
                       wtl.dt_cancel,
                       wtl.notes_cancel
                  INTO l_surg_req_prof_name,
                       l_surg_req_prof_spec,
                       l_surg_req_reason,
                       l_surg_req_prof_dt,
                       l_surg_req_prof_notes
                  FROM professional prf
                 INNER JOIN waiting_list wtl
                    ON prf.id_professional = wtl.id_prof_cancel
                 INNER JOIN cancel_reason cr
                    ON wtl.id_cancel_reason = cr.id_cancel_reason
                 WHERE wtl.id_waiting_list = i_id_waiting_list;
            
                OPEN o_cancel_info FOR
                    SELECT l_surg_req_reason surg_req_reason,
                           pk_date_utils.date_char_tsz(i_lang, l_surg_req_prof_dt, i_prof.institution, i_prof.software) surg_req_prof_dt,
                           l_surg_req_prof_notes surg_req_prof_notes,
                           l_surg_req_prof_name surg_req_prof_name,
                           l_surg_req_prof_spec surg_req_prof_spec
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_cancel_info);
            END IF;
        
            RETURN TRUE;
        
        EXCEPTION
        
            WHEN OTHERS THEN
                RETURN FALSE;
        END get_cancelation_info;
    
    BEGIN
    
        -- Get WAITING LIST surgical and inpatient episodes
        g_error := 'GET SURGICAL EPISODE';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT wtle.id_episode
              INTO l_id_episode_sr
              FROM wtl_epis wtle
             WHERE wtle.id_waiting_list = i_id_waiting_list
               AND wtle.id_epis_type = l_epis_type_sr;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_episode_sr := NULL;
        END;
    
        g_error := 'GET INPATIENT EPISODE';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT wtle.id_episode
              INTO l_id_episode_inp
              FROM wtl_epis wtle
             WHERE wtle.id_waiting_list = i_id_waiting_list
               AND wtle.id_epis_type = l_epis_type_inp;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_episode_inp := NULL;
        END;
    
        g_error := 'CALL TO GET_SURGERY_REQUEST';
        pk_alertlog.log_debug(g_error);
        -- LMAIA 06-05-2009
        -- Added this to guarantee that return cursors are open when there is only one admission request.
        IF l_id_episode_sr IS NOT NULL
        THEN
            IF NOT pk_surgery_request.get_surgery_request(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_id_episode                => l_id_episode_sr,
                                                          i_id_waiting_list           => i_id_waiting_list,
                                                          o_surg_specs                => o_surg_specs,
                                                          o_pref_surg                 => o_pref_surg,
                                                          o_procedures                => o_procedures,
                                                          o_ext_disc                  => o_ext_disc,
                                                          o_danger_cont               => o_danger_cont,
                                                          o_preferred_time            => o_preferred_time,
                                                          o_pref_time_reason          => o_pref_time_reason,
                                                          o_pos                       => o_pos,
                                                          o_surg_request              => o_surg_request,
                                                          o_interv_clinical_questions => o_interv_clinical_questions,
                                                          o_error                     => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
            pk_types.open_my_cursor(o_referral);
        END IF;
    
        g_error := 'CALL TO GET_ADMISSION_REQUEST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_admission_request.get_admission_request(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => l_id_episode_inp,
                                                          i_id_waiting_list => i_id_waiting_list,
                                                          i_all             => 'N', -- Only active records
                                                          o_adm_request     => o_adm_request,
                                                          o_diag            => o_diag,
                                                          o_error           => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        -- Get WAITING LIST common data
        g_error := 'OPEN CURSOR O_WAITING_LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_waiting_list FOR
            SELECT wl.flg_type wl_flg_type, l_id_episode_sr id_episode_sr, l_id_episode_inp id_episode_inp
              FROM waiting_list wl
             WHERE wl.id_waiting_list = i_id_waiting_list;
    
        -- 23 - Unavailability period start; 25 - Unavailability period end; 
        g_error := 'GET GET_UNAVAILABILITY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_prv_core.get_unavailability(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_waiting_list  => i_id_waiting_list,
                                                  i_all              => pk_alert_constant.g_no, -- 'N' - Only Active Rows
                                                  o_unavailabilities => o_unavailabilities,
                                                  o_error            => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        -- Scheduling period
        g_error := 'OPEN CURSOR O_SCHED_PERIOD';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_pbl_core.get_sch_periods(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_id_waiting_list => i_id_waiting_list,
                                               i_episode_sr      => l_id_episode_sr,
                                               i_episode_inp     => l_id_episode_inp,
                                               o_sched_period    => o_sched_period,
                                               o_error           => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        --Referral
        g_error := 'OPEN CURSOR O_REFERRAL';
        pk_alertlog.log_debug(g_error);
        OPEN o_referral FOR
            SELECT re.id_external_request, re.num_req
              FROM waiting_list wtl
             INNER JOIN p1_external_request re
                ON re.id_external_request = wtl.id_external_request
             WHERE wtl.id_waiting_list = i_id_waiting_list;
    
        --Fetch barthel index summ page
        g_error := 'OPEN CURSORS o_doc_area_register AND o_doc_area_val';
        pk_alertlog.log_debug(g_error);
        IF NOT get_summ_page_documentation(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_episode           => i_id_episode,
                                           i_waiting_list      => i_id_waiting_list,
                                           o_doc_area_register => o_doc_area_register,
                                           o_doc_area_val      => o_doc_area_val,
                                           o_error             => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        g_error := 'OPEN CURSORS o_doc_scales';
        pk_alertlog.log_debug(g_error);
        IF NOT get_scale_summ(i_lang         => i_lang,
                              i_prof         => i_prof,
                              i_waiting_list => i_id_waiting_list,
                              o_scale_sum    => o_doc_scales,
                              o_error        => o_error)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        g_error := 'Fetch id_sr_pos_schedule for i_id_waiting_list: ' || i_id_waiting_list;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT id_sr_pos_schedule
              INTO l_id_sr_pos_schedule
              FROM (SELECT sps.id_sr_pos_schedule, rank() over(ORDER BY sps.dt_req DESC) origin_rank
                      FROM schedule_sr ssr
                     INNER JOIN sr_pos_schedule sps
                        ON sps.id_schedule_sr = ssr.id_schedule_sr
                     WHERE ssr.id_waiting_list = i_id_waiting_list)
             WHERE origin_rank = 1;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'ID_SR_POS_SCHEDULE not found';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_id_sr_pos_schedule := NULL;
        END;
    
        IF l_id_sr_pos_schedule IS NOT NULL
        THEN
            g_error := 'OPEN CURSORS o_pos_validation';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_sr_pos.get_pos_decision(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_sr_pos_schedule => l_id_sr_pos_schedule,
                                              i_flg_return_opts    => pk_alert_constant.g_no,
                                              o_pos_validation     => o_pos_validation,
                                              o_pos_decision       => l_dummy_cursor,
                                              o_pos_validity       => l_dummy_cursor,
                                              o_error              => o_error)
            THEN
                RAISE l_runtime_error;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_pos_validation);
        END IF;
    
        --Antonio.Neto 03-Dec-2010 Return Cancelation Info for Details screen ALERT-141801
        IF NOT get_cancelation_info(o_cancel_info)
        THEN
            RAISE l_runtime_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_runtime_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_sched_period);
            pk_types.open_my_cursor(o_unavailabilities);
            pk_types.open_my_cursor(o_waiting_list);
            --
            pk_types.open_my_cursor(o_adm_request);
            pk_types.open_my_cursor(o_diag);
            --
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
            pk_types.open_my_cursor(o_referral);
            --
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            --
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_cancel_info);
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
        
            pk_types.open_my_cursor(o_sched_period);
            pk_types.open_my_cursor(o_unavailabilities);
            pk_types.open_my_cursor(o_waiting_list);
            --
            pk_types.open_my_cursor(o_adm_request);
            pk_types.open_my_cursor(o_diag);
            --
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
            pk_types.open_my_cursor(o_referral);
            --
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            --
            pk_types.open_my_cursor(o_pos_validation);
            pk_types.open_my_cursor(o_cancel_info);
            RETURN FALSE;
    END get_adm_surg_request;

    /********************************************************************************************
    * Checks if the patient's order in the waiting list may be changed, and returns a message.
    * Possible sorting keys such as gender or placement date are not to be considered since the professional
    * has no way of editing.
    * 
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_flg_show         Show message: (Y) Yes (N) No
    * @param o_msg_title        Message title
    * @param o_msg_text         Message text
    * @param o_button           Button type
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/06
    *********************************************************************************************/
    FUNCTION check_waiting_list_order
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN waiting_list.id_waiting_list%TYPE,
        i_dt_sched_period_end IN VARCHAR2,
        i_wtl_urg_level       IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_func_eval_modified  IN VARCHAR2,
        i_id_patient          IN patient.id_patient%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg_text            OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_func_name VARCHAR2(200) := 'CHECK_WAITING_LIST_ORDER';
    
        l_cur_dt_sched_period_end VARCHAR2(200);
        l_wtl_urg                 wtl_urg_level.id_wtl_urg_level%TYPE;
        l_func_eval               waiting_list.func_eval_score%TYPE;
    
        l_has_changes BOOLEAN := FALSE;
        l_skis        t_table_wtl_skis := t_table_wtl_skis();
        l_count       PLS_INTEGER := 0;
        l_flg_status  waiting_list.flg_status%TYPE;
    
        FUNCTION exists_val
        (
            i_skis t_table_wtl_skis,
            i_sk   wtl_sort_key.id_wtl_sort_key%TYPE
        ) RETURN BOOLEAN IS
            aux t_rec_wtl_skis;
        BEGIN
        
            IF i_skis.count = 0
            THEN
                RETURN FALSE;
            END IF;
        
            FOR i IN i_skis.first .. i_skis.last
            LOOP
                aux := i_skis(i);
                IF aux.id_wtl_sort_key = i_sk
                THEN
                    RETURN TRUE;
                END IF;
            END LOOP;
        
            RETURN FALSE;
        END exists_val;
    
    BEGIN
    
        -- Load all relevant fields for the WTL sorting keys configuration.    
        IF i_id_waiting_list IS NOT NULL
        THEN
            g_error := 'GET CURRENT DATA';
            pk_alertlog.log_debug(g_error);
            SELECT pk_date_utils.date_send_tsz(i_lang, wl.dt_dpa, i_prof),
                   wl.id_wtl_urg_level,
                   wl.func_eval_score,
                   wl.flg_status
              INTO l_cur_dt_sched_period_end, l_wtl_urg, l_func_eval, l_flg_status
              FROM waiting_list wl
             WHERE wl.id_waiting_list = i_id_waiting_list;
        END IF;
    
        --This validation should only be performed if the request is already in the Waiting List
        IF (l_flg_status = 'A')
        THEN
            g_error := 'LOAD SORTING CRITERIA';
            l_skis  := pk_wtl_prv_core.get_sort_keys_core(i_lang,
                                                          i_prof,
                                                          pk_utils.get_institution_parent(i_lang,
                                                                                          i_prof,
                                                                                          i_prof.institution));
        
            g_error := 'EVALUATE CHANGES';
            IF l_skis.count = 0
            THEN
                l_has_changes := FALSE;
            ELSIF (nvl(l_cur_dt_sched_period_end, 0) <> nvl(i_dt_sched_period_end, 0) AND
                  (exists_val(l_skis, pk_wtl_pbl_core.g_wtl_sk_rel_urg) OR
                  exists_val(l_skis, pk_wtl_pbl_core.g_wtl_sk_abs_urg)))
                  OR (nvl(i_wtl_urg_level, 0) <> nvl(l_wtl_urg, 0) AND
                  exists_val(l_skis, pk_wtl_pbl_core.g_wtl_sk_urg_level))
            THEN
            
                l_has_changes := TRUE;
            END IF;
        
            g_error := 'EVALUATE CHANGES - Barthel';
            pk_alertlog.log_debug(g_error);
            IF (l_skis.count > 0 AND i_func_eval_modified = pk_alert_constant.g_yes AND
               exists_val(l_skis, pk_wtl_pbl_core.g_wtl_sk_barthel) AND NOT l_has_changes)
            THEN
                --Barthel needs extra verification.
                SELECT COUNT(wtl.id_waiting_list)
                  INTO l_count
                  FROM waiting_list wtl
                 WHERE wtl.id_patient = i_id_patient
                   AND wtl.flg_status = pk_wtl_prv_core.g_wtlist_status_active;
            
                IF l_count > 0
                THEN
                    l_has_changes := TRUE;
                END IF;
            
            END IF;
        ELSE
            l_has_changes := FALSE;
        END IF;
    
        -- Check difference between dates
        IF l_has_changes
        THEN
            g_error := 'SET MESSAGE (1)';
            pk_alertlog.log_debug(g_error);
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SURGERY_REQUEST_M001');
            o_msg_text  := pk_message.get_message(i_lang, 'SURGERY_REQUEST_M002');
            o_button    := 'NC';
        ELSE
            g_error := 'SET MESSAGE (2)';
            pk_alertlog.log_debug(g_error);
            o_flg_show := 'N';
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
    END check_waiting_list_order;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            output
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Sérgio Cunha
    *  @version                    2.5.0.3
    *  @since                      22-05-2009
    ******************************************************************************/
    FUNCTION get_wtlist_search_inpatient
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_args_inp IN table_varchar,
        o_wtlist   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_wtlist table_number;
        l_inst      institution.id_institution%TYPE;
        l_query     VARCHAR2(1000 CHAR);
    
        --sorting criteria
        l_const        PLS_INTEGER := 32;
        l_sk           t_table_wtl_skis := t_table_wtl_skis();
        l_wtlsk_gender wtl_sort_key.id_wtl_sort_key%TYPE := 6; --gender
    BEGIN
    
        g_error := 'GET SORTING CRITERIA';
        BEGIN
            --institution
            IF NOT pk_utils.get_institution_parent(i_lang   => i_lang,
                                                   i_prof   => i_prof,
                                                   i_inst   => i_prof.institution,
                                                   o_parent => l_inst,
                                                   o_error  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            --sk
            l_sk := pk_wtl_prv_core.get_sort_keys_core(i_lang => i_lang, i_prof => i_prof, i_inst => l_inst);
        
            FOR i IN 1 .. l_sk.count
            LOOP
                l_query := l_query || CASE
                               WHEN i = 1 THEN
                                ''
                               ELSE
                                ', '
                           END || (l_const + l_sk(i).id_wtl_sort_key);
            END LOOP;
        
        END;
    
        g_error := 'CALL TO GET_WTLIST_SEARCH_INP_CORE';
        IF NOT pk_wtl_pbl_core.get_wtlist_search_inp_core(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_args_inp => i_args_inp,
                                                          o_wtlist   => l_id_wtlist,
                                                          o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'REPLACE BIND VARIABLES';
        pk_context_api.set_parameter('i_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof', i_prof.id);
        pk_context_api.set_parameter('i_software', i_prof.software);
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('g_id_epis_type_surgery', pk_wtl_prv_core.g_id_epis_type_surgery);
        pk_context_api.set_parameter('g_id_epis_type_inpatient', pk_wtl_prv_core.g_id_epis_type_inpatient);
        pk_context_api.set_parameter('l_inst', l_inst);
        pk_context_api.set_parameter('l_wtlsk_gender', l_wtlsk_gender);
    
        g_error := 'GET WAITING LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_wtlist FOR 'SELECT v.* 
										 FROM V_WTL_SEARCH_INP v
										 WHERE v.id_waiting_list IN (SELECT *
																										 FROM TABLE(:0))
										ORDER BY ' || l_query
            USING l_id_wtlist;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_wtlist_search_inpatient',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_wtlist);
            RETURN FALSE;
        
    END get_wtlist_search_inpatient;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent.
    *  Note that this function only returns the ids of the waiting list entries to be returned; the info to be displayed
    *  is retrieved independently on function get_wtlist_search_inpatient.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            table_number containing the IDs of all WTL keys to be presented.
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0.1
    *  @since                      03-03-2010
    ******************************************************************************/
    FUNCTION get_wtlist_search_inp_core
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_args_inp IN table_varchar,
        o_wtlist   OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SEARCH_INPATIENT';
        l_id_wtlist table_number;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        DECLARE
            l_inp_dpa           waiting_list.dt_dpa%TYPE;
            l_inp_dpb           waiting_list.dt_dpb%TYPE;
            l_inp_ids_cs        table_number := table_number();
            l_inp_ids_ward      table_number := table_number();
            l_inp_id_adm_phys   table_number := table_number();
            l_inp_id_ind_adm    table_number := table_number();
            l_inp_adm_duration  adm_request.expected_duration%TYPE;
            l_inp_cancel_reason table_varchar := table_varchar();
            l_inp_surg_status   table_varchar := table_varchar();
            l_inp_wtl_ids       table_number := table_number();
            l_inp_flg_search    VARCHAR2(1);
            l_ids_pat           table_number; -- Do not initialize this variable
            l_flg_status_count  NUMBER := 0;
            l_inp_wtl_inst      table_number; -- Do not initialize this variable
        
        BEGIN
        
            -- ANY EXCEPTION OCURRING HERE GOES TO MAIN HANDLER
        
            -- convert dpa to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR dpa';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_dpa)
               AND i_args_inp(pk_wtl_prv_core.idx_inp_dpa) IS NOT NULL
            THEN
                IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => TRIM(i_args_inp(pk_wtl_prv_core.idx_inp_dpa)),
                                                     i_timezone  => NULL,
                                                     o_timestamp => l_inp_dpa,
                                                     o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- convert dpb to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR dpb';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_dpb)
               AND i_args_inp(pk_wtl_prv_core.idx_inp_dpb) IS NOT NULL
            THEN
                IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => i_args_inp(pk_wtl_prv_core.idx_inp_dpb),
                                                     i_timezone  => NULL,
                                                     o_timestamp => l_inp_dpb,
                                                     o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- convert clinical services
            g_error := 'CONVERT CLINICAL SERVICES';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_ids_dcs)
            THEN
                l_inp_ids_cs := pk_wtl_prv_core.get_list_number_csv(i_args_inp(pk_wtl_prv_core.idx_inp_ids_dcs));
            END IF;
        
            -- convert ids wards
            g_error := 'CONVERT WARDS';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_ids_ward)
            THEN
                l_inp_ids_ward := pk_wtl_prv_core.get_list_number_csv(i_args_inp(pk_wtl_prv_core.idx_inp_ids_ward));
            END IF;
        
            -- convert ids physicians
            g_error := 'CONVERT PHYSICIANS';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_id_adm_phys)
            THEN
                l_inp_id_adm_phys := pk_wtl_prv_core.get_list_number_csv(i_args_inp(pk_wtl_prv_core.idx_inp_id_adm_phys));
            END IF;
        
            -- convert ids admission indications
            g_error := 'CONVERT ADMISSION INDICATIONS';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_id_ind_adm)
            THEN
                l_inp_id_ind_adm := pk_wtl_prv_core.get_list_number_csv(i_args_inp(pk_wtl_prv_core.idx_inp_id_ind_adm));
            END IF;
        
            -- convert ids cancel reasons
            g_error := 'CONVERT CANCEL REASONS';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_cancel_reason)
            THEN
                l_inp_cancel_reason := pk_wtl_prv_core.get_list_string_csv(i_args_inp(pk_wtl_prv_core.idx_inp_cancel_reason));
            END IF;
        
            -- convert adm duration to number
            g_error := 'CALL ADM_DURATION';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_adm_duration)
               AND i_args_inp(pk_wtl_prv_core.idx_inp_adm_duration) IS NOT NULL
            THEN
                l_inp_adm_duration := i_args_inp(pk_wtl_prv_core.idx_inp_adm_duration);
            END IF;
        
            -- convert search status
            g_error := 'CONVERT SEARCH STATUS';
        
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_surg_status)
            THEN
                l_inp_surg_status := pk_wtl_prv_core.get_list_string_csv(i_args_inp(pk_wtl_prv_core.idx_inp_surg_status));
            
            END IF;
            l_flg_status_count := l_inp_surg_status.count;
        
            -- convert ids waiting lists
            g_error := 'CONVERT WAITING LIST IDS';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_wtl_ids)
            THEN
                l_inp_wtl_ids := pk_wtl_prv_core.get_list_number_csv(i_args_inp(pk_wtl_prv_core.idx_inp_wtl_ids));
            END IF;
        
            -- convert ids institutions
            g_error := 'CONVERT INSTITUTION IDS';
            IF i_args_inp.exists(pk_wtl_prv_core.idx_inp_dest_inst)
            THEN
                l_inp_wtl_inst := pk_wtl_prv_core.get_list_number_csv(i_args_inp(pk_wtl_prv_core.idx_inp_dest_inst));
            END IF;
        
            l_inp_flg_search := i_args_inp(pk_wtl_prv_core.idx_inp_flg_search);
        
            -- get patients that match given criteria 
            IF (i_args_inp.exists(pk_wtl_prv_core.idx_inp_bsn) AND i_args_inp(pk_wtl_prv_core.idx_inp_bsn) IS NOT NULL)
               OR
               (i_args_inp.exists(pk_wtl_prv_core.idx_inp_ssn) AND i_args_inp(pk_wtl_prv_core.idx_inp_ssn) IS NOT NULL)
               OR
               (i_args_inp.exists(pk_wtl_prv_core.idx_inp_nhn) AND i_args_inp(pk_wtl_prv_core.idx_inp_nhn) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_recnum) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_recnum) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_birthdate) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_birthdate) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_gender) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_gender) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_surnameprefix) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_surnameprefix) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_surnamemaiden) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_surnamemaiden) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_names) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_names) IS NOT NULL)
               OR (i_args_inp.exists(pk_wtl_prv_core.idx_inp_initials) AND
               i_args_inp(pk_wtl_prv_core.idx_inp_initials) IS NOT NULL)
            THEN
                IF NOT search_patient(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_bsn           => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_bsn)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_bsn)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_ssn           => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_ssn)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_ssn)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_nhn           => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_nhn)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_nhn)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_recnum        => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_recnum)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_recnum)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_birthdate     => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_birthdate)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_birthdate)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_gender        => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_gender)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_gender)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_surnameprefix => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_surnameprefix)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_surnameprefix)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_surnamemaiden => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_surnamemaiden)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_surnamemaiden)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_names         => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_names)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_names)
                                                             ELSE
                                                              NULL
                                                         END,
                                      i_initials      => CASE i_args_inp.exists(pk_wtl_prv_core.idx_inp_initials)
                                                             WHEN TRUE THEN
                                                              i_args_inp(pk_wtl_prv_core.idx_inp_initials)
                                                             ELSE
                                                              NULL
                                                         END,
                                      o_list          => l_ids_pat,
                                      o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'SEARCH ID_WAITING_LIST';
            SELECT DISTINCT wtl.id_waiting_list
              BULK COLLECT
              INTO l_id_wtlist
              FROM waiting_list wtl
             INNER JOIN wtl_epis wtle
                ON wtle.id_waiting_list = wtl.id_waiting_list
             INNER JOIN adm_request ar
                ON wtle.id_episode = ar.id_dest_episode
             INNER JOIN adm_indication ai
                ON ai.id_adm_indication = ar.id_adm_indication
             INNER JOIN adm_ind_dep_clin_serv aidcs
                ON ar.id_adm_indication = aidcs.id_adm_indication
               AND aidcs.flg_available = pk_alert_constant.g_yes
              LEFT JOIN escape_department ed
                ON aidcs.id_adm_indication = ed.id_adm_indication
               AND ai.flg_escape = pk_alert_constant.g_active
              LEFT JOIN wtl_prof wprf
                ON wtl.id_waiting_list = wprf.id_waiting_list
               AND wprf.flg_status = pk_alert_constant.g_active
               AND wprf.flg_type = pk_alert_constant.g_active
             WHERE (l_inp_flg_search = pk_alert_constant.g_yes AND
                   --waiting list status
                   wtl.flg_status IN (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
                   --only inpatient episodes
                   AND wtle.id_epis_type = pk_alert_constant.g_epis_type_inpatient AND
                   wtl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_bed, pk_wtl_prv_core.g_wtlist_type_both)
                   --inpatient episode not schedule
                   AND wtle.flg_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
                   -- The requested admission belongs to one of the searched institutions
                   AND ar.id_dest_inst IN (SELECT column_value
                                              FROM TABLE(l_inp_wtl_inst))
                   --waiting list episodes status
                   AND
                   ((l_flg_status_count = 0) OR
                   --all status
                   (g_wtl_search_st_all IN (SELECT *
                                                FROM TABLE(l_inp_surg_status))) OR
                   --schedule
                   (g_wtl_search_st_schedule IN (SELECT *
                                                     FROM TABLE(l_inp_surg_status)) AND
                   wtl.id_waiting_list IN
                   (SELECT wep.id_waiting_list
                         FROM wtl_epis wep
                        WHERE wep.id_epis_type = pk_alert_constant.g_epis_type_operating
                          AND wep.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule)) OR
                   
                   --not schedule
                   (g_wtl_search_st_not_schedule IN
                   (SELECT *
                         FROM TABLE(l_inp_surg_status)) AND
                   wtl.id_waiting_list IN
                   (SELECT wep.id_waiting_list
                         FROM wtl_epis wep
                        WHERE wep.id_epis_type = pk_alert_constant.g_epis_type_operating
                          AND wep.flg_status IN
                              (pk_wtl_prv_core.g_wtl_epis_st_not_schedule, pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule))) OR
                   
                   --no surgery
                   (g_wtl_search_st_no_surgery IN (SELECT *
                                                       FROM TABLE(l_inp_surg_status)) AND
                   wtl.flg_type = pk_wtl_prv_core.g_wtlist_type_bed) OR
                   
                   --temporary schedule
                   (g_wtl_search_st_schedule_temp IN
                   (SELECT *
                         FROM TABLE(l_inp_surg_status)) AND
                   wtl.id_waiting_list IN
                   (SELECT wep.id_waiting_list
                         FROM wtl_epis wep
                        WHERE wep.id_epis_type = pk_alert_constant.g_epis_type_operating
                          AND wep.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule
                          AND wep.id_schedule IN (SELECT DISTINCT ssr.id_schedule
                                                    FROM schedule_sr ssr
                                                   WHERE ssr.flg_temporary = pk_alert_constant.g_yes))))
                   
                   --dpb & dpa
                   
                   AND ((i_args_inp(pk_wtl_prv_core.idx_inp_dpb) IS NULL AND
                   i_args_inp(pk_wtl_prv_core.idx_inp_dpa) IS NULL) OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_dpb) IS NULL AND wtl.dt_dpa <= l_inp_dpa) OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_dpa) IS NULL AND wtl.dt_dpb >= l_inp_dpb) OR
                   (wtl.dt_dpb >= l_inp_dpb AND wtl.dt_dpa <= l_inp_dpa) OR
                   (wtl.dt_dpb <= l_inp_dpb AND wtl.dt_dpa >= l_inp_dpa) OR
                   (wtl.dt_dpb >= l_inp_dpb AND wtl.dt_dpa >= l_inp_dpa AND wtl.dt_dpb <= l_inp_dpa) OR
                   (wtl.dt_dpb <= l_inp_dpb AND wtl.dt_dpa <= l_inp_dpa AND wtl.dt_dpa >= l_inp_dpb))
                   
                   -- clinical_services
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_ids_dcs) IS NULL OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_ids_dcs) IS NOT NULL AND
                   ar.id_dep_clin_serv IN
                   (SELECT dcs.id_dep_clin_serv
                             FROM dep_clin_serv dcs
                             JOIN department d
                               ON dcs.id_department = d.id_department
                            WHERE dcs.id_clinical_service IN (SELECT *
                                                                FROM TABLE(l_inp_ids_cs))
                              AND d.id_institution IN (SELECT *
                                                         FROM TABLE(l_inp_wtl_inst)))))
                   
                   -- ward
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_ids_ward) IS NULL OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_ids_ward) IS NOT NULL AND
                   (ed.id_department IN (SELECT *
                                                  FROM TABLE(l_inp_ids_ward)) OR
                   ar.id_department IN (SELECT *
                                                  FROM TABLE(l_inp_ids_ward))
                   
                   )))
                   
                   -- admiting physicians
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_id_adm_phys) IS NULL OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_id_adm_phys) IS NOT NULL AND
                   wprf.id_prof IN (SELECT *
                                             FROM TABLE(l_inp_id_adm_phys))))
                   
                   -- indication admissions
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_id_ind_adm) IS NULL OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_id_ind_adm) IS NOT NULL AND
                   ar.id_adm_indication IN (SELECT *
                                                     FROM TABLE(l_inp_id_ind_adm))))
                   
                   -- admission duration
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_adm_duration) IS NULL OR
                   (ar.expected_duration = l_inp_adm_duration AND
                   i_args_inp(pk_wtl_prv_core.idx_inp_adm_duration) IS NOT NULL))
                   
                   -- patients
                   AND (l_ids_pat IS NULL OR
                   wtl.id_patient IN (SELECT *
                                              FROM TABLE(l_ids_pat)))
                   -- cancel reasons 
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_cancel_reason) IS NULL OR
                   (wtle.flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule AND
                   wtle.id_schedule IN
                   (SELECT wtle.id_schedule
                             FROM schedule s
                            WHERE s.id_schedule = wtle.id_schedule
                              AND s.id_cancel_reason IN (SELECT *
                                                           FROM TABLE(l_inp_cancel_reason)))))
                   -- referral
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_referral) IS NULL OR
                   (TRIM(i_args_inp(pk_wtl_prv_core.idx_inp_referral)) IS NOT NULL AND
                   wtl.id_external_request IN
                   (SELECT p1.id_external_request
                             FROM p1_external_request p1
                            WHERE p1.num_req = TRIM(i_args_inp(pk_wtl_prv_core.idx_inp_referral)))))
                   
                   )
                  --Waiting List ID Search
                OR (l_inp_flg_search = pk_alert_constant.g_no
                   -- waiting list ids
                   AND (i_args_inp(pk_wtl_prv_core.idx_inp_wtl_ids) IS NULL OR
                   (i_args_inp(pk_wtl_prv_core.idx_inp_wtl_ids) IS NOT NULL AND
                   wtl.id_waiting_list IN (SELECT *
                                                    FROM TABLE(l_inp_wtl_ids)))));
        END;
    
        o_wtlist := l_id_wtlist;
    
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
        
    END get_wtlist_search_inp_core;

    /******************************************************************************
    *  Get a list of admission indications for a specific ward
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_ward              ward ID
    *  @param  o_adm_indication    Adm Indication ID
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Sérgio Cunha
    *  @version                    2.5.0.3
    *  @since                      22-05-2009
    ******************************************************************************/
    FUNCTION get_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ward           IN department.id_department%TYPE,
        o_adm_indication OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ADM_INDICATION';
    
    BEGIN
    
        OPEN o_adm_indication FOR
            SELECT DISTINCT aidcs.id_adm_indication,
                            --ai.desc_adm_indication desc_indication
                            nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) desc_adm_indication
              FROM adm_ind_dep_clin_serv aidcs
              JOIN adm_indication ai
                ON aidcs.id_adm_indication = ai.id_adm_indication
             WHERE aidcs.id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                FROM dep_clin_serv dcs
                                               WHERE dcs.id_department = i_ward)
               AND aidcs.flg_available = pk_alert_constant.g_yes;
    
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
            pk_types.open_my_cursor(o_adm_indication);
            RETURN FALSE;
        
    END get_adm_indication;

    /******************************************************************************
    *  Returns the Waiting List summary for multiple entries. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting List IDs
    *  @param  o_data              data
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      27-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_summary_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SUMMARY_ALL';
    BEGIN
    
        DELETE FROM wtl_adm_surg_tmptab;
    
        FOR i IN i_id_wtlist.first .. i_id_wtlist.last
        LOOP
            IF NOT get_wtlist_summary(i_lang      => i_lang,
                                      i_prof      => i_prof,
                                      i_id_wtlist => i_id_wtlist(i),
                                      o_data      => o_data,
                                      o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
        OPEN o_data FOR
            SELECT *
              FROM wtl_adm_surg_tmptab
             ORDER BY id_wtlist, ordem;
    
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
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        
    END get_wtlist_summary_all;

    /**************************************************************************
    * Checks if an id_epis_documentation is associated to an admission request*
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_epis_documentation       epis documentation id                 *
    *                                                                         *
    * @param o_error                    Error message                         *
    * @param o_flg_val                  Y - Associated; N - No association    *
    * @param o_waiting_list             Id_waiting_list (if applicable)       *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/08                            *
    **************************************************************************/
    FUNCTION check_wtl_func_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN wtl_documentation.id_epis_documentation%TYPE,
        o_flg_val            OUT VARCHAR2,
        o_waiting_list       OUT wtl_documentation.id_waiting_list%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CHECK_WTL_FUNC_EVAL';
    
    BEGIN
    
        g_error := 'Fetch id_waiting_list';
        SELECT wd.id_waiting_list
          INTO o_waiting_list
          FROM wtl_documentation wd
         WHERE wd.id_epis_documentation = i_epis_documentation;
    
        IF o_waiting_list IS NULL
        THEN
            o_flg_val := pk_alert_constant.g_no;
        ELSE
            o_flg_val := pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_flg_val := pk_alert_constant.g_no;
            RETURN TRUE;
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
    END check_wtl_func_eval;

    /**************************************************************************
    * Indica se um profissional fez registos numa dada doc_area num dado      *
    * episódio no caso afirmativo, devolve a última documentation             *
    * IMP: This function is cloned on PK_TOUCH_OPTION.get_prof_doc_area_exists*
    *                                                                         *
    * @param i_lang                id da lingua                               *
    * @param i_prof                utilizador autenticado                     *
    * @param i_episode             id do episódio                             *
    * @param i_doc_area            id da doc_area da qual se verificam se     *
    *                              foram feitos registos                      *
    * @param o_last_prof_epis_doc  Last documentation epis ID to profissional *
    * @param o_date_last_epis      Data do último episódio                    *
    * @param o_flg_data            Y if there are data, F when no date found  *
    * @param o_error               Error message                              *
    *                                                                         *
    * @return                      true or false on success or error          *
    *                                                                         *
    * @autor                                                                  *
    * @version                     1.0                                        *
    * @since                                                                  *
    **************************************************************************/
    FUNCTION get_prof_doc_area_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis     OUT epis_documentation.dt_creation_tstz%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_last_epis_doc IS
            SELECT id_epis_documentation, dt_creation_tstz
              FROM (SELECT ed.id_epis_documentation,
                           ed.dt_creation_tstz,
                           row_number() over(PARTITION BY ed.id_episode ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_documentation ed
                      JOIN wtl_documentation wd
                        ON wd.id_epis_documentation = ed.id_epis_documentation
                     WHERE ed.id_episode = i_episode
                       AND ed.id_doc_area = i_doc_area
                       AND ed.id_professional = i_prof.id
                       AND ed.flg_status = pk_touch_option.g_epis_doc_active
                       AND ed.dt_creation_tstz IS NOT NULL)
             WHERE rn = 1;
    
    BEGIN
        g_error := 'OPEN C_LAST_EPIS_DOC';
        OPEN c_last_epis_doc;
        FETCH c_last_epis_doc
            INTO o_last_prof_epis_doc, o_date_last_epis;
    
        IF c_last_epis_doc%FOUND
        THEN
            o_flg_data := g_yes;
        ELSE
            o_flg_data := g_no;
        END IF;
        CLOSE c_last_epis_doc;
    
        RETURN TRUE;
    
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
                                   'GET_PROF_DOC_AREA_EXISTS');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_prof_doc_area_exists;

    /**************************************************************************
    * Saves epis_documentation data with wtl_documentation logic (based on    *
    * the PK_TOUCH_OPTION.SET_EPIS_DOCUMENTATION function)                    *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_prof_cat_type                                                  *
    * @param i_epis                                                           *
    * @param i_doc_area                                                       *
    * @param i_doc_template                                                   *
    * @param i_epis_documentation                                             *
    * @param i_flg_type                                                       *
    * @param i_id_documentation                                               *
    * @param i_id_doc_element                                                 *
    * @param i_id_doc_element_crit                                            *
    * @param i_value                                                          *
    * @param i_notes                                                          *
    * @param i_id_doc_element_qualif                                          *
    * @param i_epis_context                                                   *
    * @param i_summary_and_notes                                              *
    * @param i_episode_context                                                *
    * @param i_wtl_change               Flag that states if the new docum.    *
    *                                   will affect waiting list              *
    * @param   i_flags                  List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                    List of ids: Scale, Documentation, Group
    * @param   i_scores                 List of calculated scores    
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    *                                                                         *
    * @param o_epis_documentation       Generated id_epis_documentation       *
    * @param   o_id_epis_scales_score       The epis_scales_score ID created
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/02/22                            *
    **************************************************************************/
    FUNCTION set_wtl_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT pk_touch_option.g_flg_tab_origin_epis_doc,
        i_wtl_change            IN VARCHAR2,
        i_notes_wtl             IN VARCHAR2,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'SET_WTL_EPIS_DOCUMENTATION';
        wtl_exception         EXCEPTION;
        l_waiting_list        wtl_documentation.id_waiting_list%TYPE;
        l_wtl_epis_flg_status wtl_epis.flg_status%TYPE;
        l_epis_documentation  epis_documentation.id_epis_documentation%TYPE;
        l_id_pat              patient.id_patient%TYPE;
    
    BEGIN
        g_error := 'Fetch id_waiting_list for id_epis_documentation: ' || i_epis_documentation;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT wd.id_waiting_list, we.flg_status, wtl.id_patient
              INTO l_waiting_list, l_wtl_epis_flg_status, l_id_pat
              FROM wtl_documentation wd
             INNER JOIN waiting_list wtl
                ON wtl.id_waiting_list = wd.id_waiting_list
              LEFT JOIN wtl_epis we
                ON we.id_waiting_list = wd.id_waiting_list
             WHERE wd.id_epis_documentation = i_epis_documentation
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_waiting_list := NULL;
        END;
    
        g_error := 'Saving epis_documentation with alert and score';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_nurse.set_epis_doc_scales(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_prof_cat_type         => i_prof_cat_type,
                                                i_epis                  => i_epis,
                                                i_doc_area              => i_doc_area,
                                                i_doc_template          => i_doc_template,
                                                i_epis_documentation    => i_epis_documentation,
                                                i_flg_type              => i_flg_type,
                                                i_id_documentation      => i_id_documentation,
                                                i_id_doc_element        => i_id_doc_element,
                                                i_id_doc_element_crit   => i_id_doc_element_crit,
                                                i_value                 => i_value,
                                                i_notes                 => i_notes,
                                                i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                i_epis_context          => i_epis_context,
                                                i_summary_and_notes     => i_summary_and_notes,
                                                i_episode_context       => i_episode_context,
                                                i_flg_table_origin      => i_flg_table_origin,
                                                i_vs_element_list       => NULL,
                                                i_vs_save_mode_list     => NULL,
                                                i_vs_list               => NULL,
                                                i_vs_value_list         => NULL,
                                                i_vs_uom_list           => NULL,
                                                i_vs_scales_list        => NULL,
                                                i_vs_date_list          => NULL,
                                                i_vs_read_list          => NULL,
                                                i_flags                 => i_flags,
                                                i_ids                   => i_ids,
                                                i_scores                => i_scores,
                                                i_id_scales_formulas    => i_id_scales_formulas,
                                                i_dt_clinical           => i_dt_clinical,
                                                o_epis_documentation    => l_epis_documentation,
                                                o_id_epis_scales_score  => o_id_epis_scales_score,
                                                o_error                 => o_error)
        THEN
            RAISE wtl_exception;
        END IF;
    
        o_epis_documentation := l_epis_documentation;
    
        IF l_waiting_list IS NOT NULL
        THEN
            IF NOT manage_wtl_func_eval(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_waiting_list       => l_waiting_list,
                                        i_epis_documentation => l_epis_documentation,
                                        i_wtl_change         => i_wtl_change,
                                        o_error              => o_error)
            THEN
                RAISE wtl_exception;
            END IF;
        
            IF NOT set_waiting_list(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    notes_edit         => i_notes_wtl,
                                    id_waiting_list_io => l_waiting_list,
                                    o_error            => o_error)
            THEN
                RAISE wtl_exception;
            END IF;
        END IF;
    
        g_error := 'CALL TO pk_clinical_notes.set_clinical_notes_doc_area';
        IF NOT pk_clinical_notes.set_clinical_notes_doc_area(i_lang,
                                                             i_prof,
                                                             i_episode_context,
                                                             i_doc_area,
                                                             i_summary_and_notes,
                                                             o_error)
        THEN
            RAISE wtl_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
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
    END set_wtl_epis_documentation;

    /**************************************************************************
    * Cancels epis_documentation data with wtl_documentation logic (based on    *
    * the PK_TOUCH_OPTION.CANCEL_EPIS_DOCUMENTATION function)                    *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_id_episode                                                     *
    * @param i_doc_area                                                       *
    * @param i_id_epis_doc                                                    *
    * @param i_notes                                                          *
    * @param i_test                                                           *
    * @param i_wtl_change                                                     *
    * @param o_flg_show                                                       *
    * @param o_msg_title                                                      *
    * @param o_msg_text                                                       *
    * @param o_button                                                         *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/02/22                            *
    **************************************************************************/
    FUNCTION cancel_wtl_scale_epis_doc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_wtl_change       IN VARCHAR2,
        i_notes_wtl        IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'CANCEL_WTL_SCALE_EPIS_DOC';
        wtl_exception EXCEPTION;
    
        l_waiting_list        wtl_documentation.id_waiting_list%TYPE;
        l_wtl_epis_flg_status wtl_epis.flg_status%TYPE;
        l_id_pat              patient.id_patient%TYPE;
    BEGIN
    
        g_error := 'Fetch id_waiting_list for id_epis_documentation: ' || i_id_epis_doc;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT wd.id_waiting_list, we.flg_status, wtl.id_patient
              INTO l_waiting_list, l_wtl_epis_flg_status, l_id_pat
              FROM wtl_documentation wd
             INNER JOIN waiting_list wtl
                ON wtl.id_waiting_list = wd.id_waiting_list
              LEFT JOIN wtl_epis we
                ON we.id_waiting_list = wd.id_waiting_list
             WHERE wd.id_epis_documentation = i_id_epis_doc
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_waiting_list := NULL;
        END;
    
        g_error := 'Cancel epis_documentation';
        IF NOT pk_inp_nurse.cancel_scale_epis_doc(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_episode       => i_id_episode,
                                                  i_doc_area         => i_doc_area,
                                                  i_id_epis_doc      => i_id_epis_doc,
                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                  i_notes            => i_notes,
                                                  o_flg_show         => o_flg_show,
                                                  o_msg_title        => o_msg_title,
                                                  o_msg_text         => o_msg_text,
                                                  o_button           => o_button,
                                                  o_error            => o_error)
        THEN
            RAISE wtl_exception;
        END IF;
    
        g_error := 'Validate test condition o_flg_show';
        IF (o_flg_show = pk_alert_constant.g_yes)
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        END IF;
    
        IF l_waiting_list IS NOT NULL
        THEN
            IF NOT manage_wtl_func_eval(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_waiting_list       => l_waiting_list,
                                        i_epis_documentation => i_id_epis_doc,
                                        i_wtl_change         => i_wtl_change,
                                        o_error              => o_error)
            THEN
                RAISE wtl_exception;
            END IF;
        
            IF NOT set_waiting_list(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    notes_edit         => i_notes_wtl,
                                    id_waiting_list_io => l_waiting_list,
                                    o_error            => o_error)
            THEN
                RAISE wtl_exception;
            END IF;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
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
    END cancel_wtl_scale_epis_doc;
    /******************************************************************************
    *  Verifies if the Barthel Index is configured to be considered in the waiting list ordering 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_insitution     Insitution identifier
    *  @param  o_is_mandatory      Y - Indicates if the Barthel Index is mandatory to the WL;
    *                              N - otherwise
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION is_bi_ord_crit_to_wl
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_is_mandatory   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sort_keys t_table_wtl_skis;
    BEGIN
        g_error := 'CALL PK_WTL_PRV_CORE.GET_SORT_KEYS_CORE';
        pk_alertlog.log_debug(g_error);
        l_sort_keys := pk_wtl_prv_core.get_sort_keys_core(i_lang  => i_lang,
                                                          i_prof  => i_prof,
                                                          i_inst  => i_id_institution, --TODO: check i_inst
                                                          i_wtlsk => 5); --13 removed                                                          
    
        IF l_sort_keys IS NULL
        THEN
            o_is_mandatory := pk_alert_constant.g_no;
        ELSE
            o_is_mandatory := pk_alert_constant.g_yes;
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
                                              'IS_BI_MANDATORY_TO_WL',
                                              o_error);
            RETURN FALSE;
    END is_bi_ord_crit_to_wl;

    /******************************************************************************
    *  Verifies if the Barthel Index evaluation if the last evaluation associated to a patient .    
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_insitution     Insitution identifier
    *  @param  o_is_mandatory      Y - Indicates if the Barthel Index is mandatory to the WL;
    *                              N - otherwise
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION is_last_active_eval
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_has_active_eval       OUT VARCHAR2,
        o_last_epis_doc         OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        l_flg_val            VARCHAR2(1);
        l_epis_doc_count     NUMBER(24);
        l_internal_error     EXCEPTION;
    BEGIN
        g_error := 'CALL PK_WTL_PBL_CORE.CHECK_WTL_FUNC_EVAL_PAT FOR i_id_patient: ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_pbl_core.check_wtl_func_eval_pat(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_patient            => i_id_patient,
                                                       o_flg_val            => l_flg_val,
                                                       o_last_epis_doc      => o_last_epis_doc,
                                                       o_last_date_epis_doc => l_last_date_epis_doc,
                                                       o_epis_doc_count     => l_epis_doc_count,
                                                       o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_flg_val = pk_alert_constant.g_yes AND l_epis_doc_count = 1)
        THEN
            o_has_active_eval := pk_alert_constant.g_yes;
        ELSIF (l_flg_val = pk_alert_constant.g_yes AND l_epis_doc_count > 1)
        THEN
            o_has_active_eval := pk_alert_constant.g_no;
        ELSE
            o_has_active_eval := NULL;
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
                                              'IS_LAST_EVALUATION',
                                              o_error);
            RETURN FALSE;
    END is_last_active_eval;

    /******************************************************************************
    *  Verifies if there is admission requests associated to a patient (with or without schedule,
    * registered or not registered). Also, builds the common part of the message in case there is 
    * admission/surgery requests that match the given conditions (Pedido de admissão e cirurgia com motivo de Internamento A e procedimentos cirúrgicos B e C.
    * Pedido de admissão com motivo de Internamento C.)
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        Patient identifier
    *  @param  I_REQ_STATUS        Admission Request Status: S-scheduled, N-not scheduled, C-cancelled
    *  @param  I_FLG_EHR           Episode flg_ehr (N-registered episodes; S-scheduled episodes [not registered])  
    * @param i_id_epis_documentation  Barthel Index Evaluation ID  
    *  @param  o_has_requests      Y- there is admission requets that match the inputed criteria; N-otherwise
    *  @param  o_msg               Common part of the message.
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION has_requests
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN patient.id_patient%TYPE,
        i_req_status            IN wtl_epis.flg_status%TYPE,
        i_flg_ehr               IN episode.flg_ehr%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_has_requests          OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error  EXCEPTION;
        l_adm_requests    pk_types.cursor_type;
        l_id_waiting_list waiting_list.id_waiting_list%TYPE;
        l_desc_admission  VARCHAR2(4000 CHAR);
        l_surg_proc       VARCHAR2(4000 CHAR);
        l_msg_inp_surg    VARCHAR2(4000 CHAR);
        l_msg_inp         VARCHAR2(4000 CHAR);
        l_msg_aux         VARCHAR2(4000 CHAR);
        l_index           PLS_INTEGER := 0;
    BEGIN
        o_has_requests := pk_alert_constant.g_no;
    
        g_error := 'BUILD_MESSAGE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_admission_request.get_admission_requests(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_patient               => i_id_patient,
                                                           i_req_status            => i_req_status,
                                                           i_flg_ehr               => i_flg_ehr,
                                                           i_id_epis_documentation => i_id_epis_documentation,
                                                           o_adm_requests          => l_adm_requests,
                                                           o_error                 => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'LOOP THROUGHT L_ADM_REQUESTS CURSOR';
        pk_alertlog.log_debug(g_error);
        LOOP
        
            FETCH l_adm_requests
                INTO l_id_waiting_list, l_desc_admission, l_surg_proc;
            EXIT WHEN l_adm_requests%NOTFOUND;
            o_has_requests := pk_alert_constant.g_yes;
        
            g_error := 'LOOP THROUGHT L_ADM_REQUESTS WITH l_id_waiting_list: ' || l_id_waiting_list;
            pk_alertlog.log_debug(g_error);
        
            --
            l_msg_inp_surg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T011');
            l_msg_inp      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T012');
            --
        
            IF (l_surg_proc IS NOT NULL)
            THEN
                l_msg_aux := REPLACE(l_msg_inp_surg, '@1', l_desc_admission);
                o_msg := o_msg || CASE
                             WHEN l_index > 0 THEN
                              '<br><br>'
                             ELSE
                              '<br>'
                         END || REPLACE(l_msg_aux, '@2', l_surg_proc);
            ELSE
                o_msg := o_msg || CASE
                             WHEN l_index > 0 THEN
                              '<br><br>'
                             ELSE
                              '<br>'
                         END || REPLACE(l_msg_inp, '@1', l_desc_admission);
            END IF;
            l_index := l_index + 1;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'HAS_REQUESTS',
                                              o_error);
            RETURN FALSE;
    END has_requests;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a warning popup, when creating, 
    *  updating or cancelling the Barthel Index.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier
    *  @param  i_action                   Action that is being taken (A- Add, E-Edit, C-cancel, O-OK)
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION check_wtl_feval_wr_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_action                IN VARCHAR2,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_wr_pop_msgs           OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error      EXCEPTION;
        l_is_last_active_eval VARCHAR2(1 CHAR);
        l_msg_nr              PLS_INTEGER := 0;
        l_common_msg          VARCHAR2(4000 CHAR);
        l_action_name         VARCHAR2(4000 CHAR);
        l_has_requests_wl     VARCHAR2(1 CHAR);
        l_text                VARCHAR2(4000 CHAR);
        l_last_epis_doc       epis_documentation.id_epis_documentation%TYPE;
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
    
        -------Warning popup
        -- build common message for the admission requests in Waiting List
        g_error := 'CALL HAS_REQUESTS FOR i_req_status: ' || pk_wtl_prv_core.g_wtl_epis_st_not_schedule ||
                   ' i_flg_ehr: ' || NULL;
        pk_alertlog.log_debug(g_error);
        IF NOT has_requests(i_lang         => i_lang,
                            i_prof         => i_prof,
                            i_id_patient   => i_id_patient,
                            i_req_status   => pk_wtl_prv_core.g_wtl_epis_st_not_schedule,
                            i_flg_ehr      => NULL,
                            o_has_requests => l_has_requests_wl,
                            o_msg          => l_common_msg,
                            o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_has_requests_wl = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL IS_LAST_EVALUATION FOR i_id_epis_documentation: ' || i_id_epis_documentation;
            pk_alertlog.log_debug(g_error);
            IF NOT is_last_active_eval(i_lang                  => i_lang,
                                       i_prof                  => i_prof,
                                       i_id_epis_documentation => i_id_epis_documentation,
                                       i_id_patient            => i_id_patient,
                                       o_has_active_eval       => l_is_last_active_eval,
                                       o_last_epis_doc         => l_last_epis_doc,
                                       o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_is_last_active_eval = pk_alert_constant.g_no
               AND (l_last_epis_doc = i_id_epis_documentation OR i_action = g_barthel_index_a)
            THEN
                l_msg_nr := 1;
            ELSIF l_is_last_active_eval = pk_alert_constant.g_yes
            THEN
                IF (i_action = g_barthel_index_c)
                THEN
                    l_msg_nr := 2;
                ELSE
                    l_msg_nr := 1;
                END IF;
            END IF;
        END IF;
    
        --build warnig popup messages
        IF (l_msg_nr <> 0)
        THEN
            o_flg_show := pk_alert_constant.g_yes;
        
            l_text := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T00' || l_msg_nr);
        
            --select action name to be substituted in the message
            IF (l_msg_nr = 1)
            THEN
                IF i_action = g_barthel_index_a
                THEN
                    l_action_name := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T014');
                ELSIF i_action = g_barthel_index_c
                THEN
                    l_action_name := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T016');
                END IF;
            
                l_text := REPLACE(l_text, '@1', l_action_name);
            END IF;
        
            -- build final message            
            o_wr_pop_msgs := table_varchar(g_warning_popup, --popup type
                                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T013'), --title
                                           l_text, -- question
                                           REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                                          i_code_mess => 'INP_WL_MNGM_T00' ||
                                                                                         (l_msg_nr + 5)),
                                                   '@1',
                                                   l_common_msg) --
                                           );
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
                                              'CHECK_WTL_FEVAL_WR_POP',
                                              o_error);
            RETURN FALSE;
    END check_wtl_feval_wr_pop;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a action popup, when creating, 
    *  updating or cancelling the Barthel Index.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier
    *  @param  i_action                   Action that is being taken (A- Add, E-Edit, C-cancel, O-OK)
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION check_wtl_feval_ac_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_action                IN VARCHAR2,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_ac_pop_msgs           OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        --l_is_mandatory        VARCHAR2(1 CHAR);
        l_is_last_active_eval VARCHAR2(1 CHAR);
        l_msg_nr              PLS_INTEGER := 0;
        l_common_msg          VARCHAR2(4000 CHAR);
        --l_action_name         VARCHAR2(4000 CHAR);
        l_has_requests_sch VARCHAR2(1 CHAR);
        l_text             VARCHAR2(4000 CHAR);
        l_last_epis_doc    epis_documentation.id_epis_documentation%TYPE;
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
    
        -- Action popup
        -- build common message for the admission requests scheduled but not registered
        g_error := 'CALL build_message FOR i_req_status: ' || pk_wtl_prv_core.g_wtl_epis_st_schedule || ' i_flg_ehr: ' ||
                   pk_inp_episode.g_scheduled_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT has_requests(i_lang                  => i_lang,
                       i_prof                  => i_prof,
                       i_id_patient            => i_id_patient,
                       i_req_status            => pk_wtl_prv_core.g_wtl_epis_st_schedule,
                       i_flg_ehr               => pk_inp_episode.g_scheduled_episode,
                       i_id_epis_documentation => CASE
                                                      WHEN i_action = g_barthel_index_c THEN
                                                       i_id_epis_documentation
                                                      ELSE
                                                       NULL
                                                  END,
                       o_has_requests          => l_has_requests_sch,
                       o_msg                   => l_common_msg,
                       o_error                 => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_has_requests_sch = pk_alert_constant.g_yes)
        THEN
            IF (i_action = g_barthel_index_o)
            THEN
                l_msg_nr := 3;
            ELSIF (i_action = g_barthel_index_c)
            THEN
                g_error := 'CALL IS_LAST_EVALUATION FOR i_id_epis_documentation: ' || i_id_epis_documentation;
                pk_alertlog.log_debug(g_error);
                IF NOT is_last_active_eval(i_lang                  => i_lang,
                                           i_prof                  => i_prof,
                                           i_id_epis_documentation => i_id_epis_documentation,
                                           i_id_patient            => i_id_patient,
                                           o_has_active_eval       => l_is_last_active_eval,
                                           o_last_epis_doc         => l_last_epis_doc,
                                           o_error                 => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF l_is_last_active_eval = pk_alert_constant.g_no
                THEN
                    -- this evaluation is associated to a scheduled admission appointment?                  
                    l_msg_nr := 4;
                ELSIF l_is_last_active_eval = pk_alert_constant.g_yes
                THEN
                    l_msg_nr := 5;
                END IF;
            END IF;
        END IF;
    
        --build action popup messages
        IF (l_msg_nr <> 0)
        THEN
            o_flg_show := pk_alert_constant.g_yes;
            IF (l_msg_nr = 5)
            THEN
                l_text := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T010');
            END IF;
        
            -- build final message            
            o_ac_pop_msgs := table_varchar(g_action_popup, --popup type: action popup
                                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T013'), --title
                                           pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => 'INP_WL_MNGM_T00' || l_msg_nr), -- question
                                           l_common_msg,
                                           l_text);
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
                                              'CHECK_WTL_FEVAL_AC_POP',
                                              o_error);
            RETURN FALSE;
    END check_wtl_feval_ac_pop;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a popup, when creating, 
    *  updating or cancelling the Barthel Index.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier
    *  @param  i_action                   Action that is being taken (A- Add, E-Edit, C-cancel, O-OK)
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      19-02-2010
    ******************************************************************************/
    FUNCTION check_wtl_func_eval_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_action                IN VARCHAR2,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_pop_msgs              OUT table_table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_is_mandatory   VARCHAR2(1 CHAR);
        l_flg_show_wr    VARCHAR2(1 CHAR);
    
        l_flg_show_ac VARCHAR2(1 CHAR);
        l_wr_pop_msgs table_varchar;
        l_ac_pop_msgs table_varchar;
        l_index       PLS_INTEGER := 0;
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
        o_pop_msgs := table_table_varchar();
    
        g_error := 'CHECK_WTL_FUNC_EVAL_POP FOR I_ID_EPISODE: ' || i_id_episode || ' I_ACTION:' || i_action;
        pk_alertlog.log_debug(g_error);
    
        -- it is only displayied popup if the Barthel Index is used to the WL ordering
        g_error := 'CALL is_bi_ord_crit_to_wl FOR i_id_institution: ' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
        IF NOT is_bi_ord_crit_to_wl(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_institution => pk_utils.get_institution_parent(i_lang, i_prof, i_prof.institution),
                                    o_is_mandatory   => l_is_mandatory,
                                    o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_is_mandatory = pk_alert_constant.g_no)
        THEN
            RETURN TRUE;
        END IF;
    
        IF (i_action = g_barthel_index_a OR i_action = g_barthel_index_c)
        THEN
            g_error := 'CALL CHECK_WTL_FEVAL_AC_POP';
            pk_alertlog.log_debug(g_error);
            IF NOT check_wtl_feval_wr_pop(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_id_episode            => i_id_episode,
                                          i_id_patient            => i_id_patient,
                                          i_action                => i_action,
                                          i_id_epis_documentation => i_id_epis_documentation,
                                          o_flg_show              => l_flg_show_wr,
                                          o_wr_pop_msgs           => l_wr_pop_msgs,
                                          o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF (i_action = g_barthel_index_c OR i_action = g_barthel_index_o)
        THEN
            g_error := 'CALL CHECK_WTL_FEVAL_AC_POP';
            pk_alertlog.log_debug(g_error);
            IF NOT check_wtl_feval_ac_pop(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_id_episode            => i_id_episode,
                                          i_id_patient            => i_id_patient,
                                          i_action                => i_action,
                                          i_id_epis_documentation => i_id_epis_documentation,
                                          o_flg_show              => l_flg_show_ac,
                                          o_ac_pop_msgs           => l_ac_pop_msgs,
                                          o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF (l_flg_show_wr = pk_alert_constant.g_yes OR l_flg_show_ac = pk_alert_constant.g_yes)
        THEN
            o_flg_show := pk_alert_constant.g_yes;
        END IF;
    
        IF l_wr_pop_msgs IS NOT NULL
           AND l_wr_pop_msgs.exists(1)
        THEN
            o_pop_msgs.extend(1);
            l_index := l_index + 1;
            o_pop_msgs(l_index) := l_wr_pop_msgs;
        END IF;
    
        IF l_ac_pop_msgs IS NOT NULL
           AND l_ac_pop_msgs.exists(1)
        THEN
            o_pop_msgs.extend(1);
            l_index := l_index + 1;
            o_pop_msgs(l_index) := l_ac_pop_msgs;
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
                                              'CHECK_WTL_FUNC_EVAL_POP',
                                              o_error);
            RETURN FALSE;
    END check_wtl_func_eval_pop;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a popup, when creating, 
    *  updating an admission requests.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier    
    *  @param  i_id_patient               Patient identifier 
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_last_epis_doc            Last epis documentation ID (last BI evaluation)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      26-02-2010
    ******************************************************************************/
    FUNCTION check_adm_req_feval_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_pop_msgs              OUT table_table_varchar,
        o_last_epis_doc         OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_is_mandatory   VARCHAR2(1 CHAR);
    
        l_is_last_active_eval VARCHAR2(1 CHAR);
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
        o_pop_msgs := table_table_varchar();
    
        g_error := 'CHECK_WTL_FUNC_EVAL_POP FOR I_ID_EPISODE: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        -- it is only displayied popup if the Barthel Index is used to the WL ordering
        g_error := 'CALL is_bi_ord_crit_to_wl FOR i_id_institution: ' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
        IF NOT is_bi_ord_crit_to_wl(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_institution => pk_utils.get_institution_parent(i_lang, i_prof, i_prof.institution),
                                    o_is_mandatory   => l_is_mandatory,
                                    o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_is_mandatory = pk_alert_constant.g_no)
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL IS_LAST_EVALUATION FOR i_id_epis_documentation: ' || i_id_epis_documentation;
        pk_alertlog.log_debug(g_error);
        IF NOT is_last_active_eval(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_id_epis_documentation => i_id_epis_documentation,
                                   i_id_patient            => i_id_patient,
                                   o_has_active_eval       => l_is_last_active_eval,
                                   o_last_epis_doc         => o_last_epis_doc,
                                   o_error                 => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --IF (l_is_last_active_eval = pk_alert_constant.g_no)
        IF (o_last_epis_doc <> i_id_epis_documentation)
        THEN
            o_flg_show := g_yes;
            o_pop_msgs.extend(1);
            -- build final message
            o_pop_msgs(1) := table_varchar(g_action_popup, --popup type: action popup
                                           pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_pop_title), --title
                                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T019'), -- question
                                           pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_WL_MNGM_T020'));
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
                                              'CHECK_ADM_REQ_FEVAL_POP',
                                              o_error);
            RETURN FALSE;
    END check_adm_req_feval_pop;

    /******************************************************************************
    *  Function that creates the sys_alert for the planner profiles, in case of an edition to a barthel index
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_patient               Patient identifier
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0
    *  @since                      23-02-2010
    ******************************************************************************/
    FUNCTION set_wtl_func_eval_alert
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_epis_doc   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_id_wtlist  IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cur   pk_types.cursor_type;
        l_wtl   table_number;
        l_dummy table_varchar;
    BEGIN
    
        g_error := 'CHECK REQUESTS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_admission_request.get_admission_requests(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_patient               => i_id_patient,
                                                           i_req_status            => NULL,
                                                           i_flg_ehr               => NULL,
                                                           i_id_epis_documentation => i_epis_doc,
                                                           i_id_wtlist             => i_id_wtlist,
                                                           o_adm_requests          => l_cur,
                                                           o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'COLLECT WTL IDs';
        pk_alertlog.log_debug(g_error);
        FETCH l_cur BULK COLLECT
            INTO l_wtl, l_dummy, l_dummy;
        CLOSE l_cur;
    
        g_error := 'GENERATE REQUESTS';
        pk_alertlog.log_debug(g_error);
        FOR l_rec IN (SELECT we.id_waiting_list, we.id_episode
                        FROM wtl_epis we
                       WHERE we.id_waiting_list IN (SELECT *
                                                      FROM TABLE(l_wtl)))
        LOOP
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => 84,
                                                    i_id_episode          => l_rec.id_episode,
                                                    i_id_record           => l_rec.id_waiting_list,
                                                    i_dt_record           => NULL,
                                                    i_id_professional     => NULL,
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => pk_prof_utils.get_nickname(i_lang, i_prof.id),
                                                    i_replace2            => NULL,
                                                    o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END LOOP;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTL_FUNC_EVAL_ALERT',
                                              o_error);
            RETURN FALSE;
    END set_wtl_func_eval_alert;

    /***************************************************************************
    *  Returns the summary page values for the scale evaluation summary page.  *
    *                                                                          *
    * @param i_lang                    language id                             *
    * @param i_prof                    professional, software and institution  *
    *                                  ids                                     *
    * @param i_doc_area                documentation area ID                   *
    * @param i_id_episode              the episode id                          *
    * @param i_id_patient              the patient id                          *
    * @param o_doc_area_register       Cursor with the doc area info register  *
    * @param o_doc_area_val            Cursor containing the completed info for* 
    *                                  episode                                 *
    * @param o_doc_scales              Cursor containing the association       *
    *                                  between documentation elements and      *
    *                                  scale values                            *
    * @param o_error                   Error message                           *
    * @return                          true (sucess), false (error)            *
    *                                                                          *
    * @author                          Gustavo Serrano                         *
    * @version                         1.0                                     *
    * @since                           24-02-2010                              *
    ***************************************************************************/
    FUNCTION get_wtl_scales_summ_page
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_doc_area          IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient patient.id_patient%TYPE;
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            l_patient := i_id_patient;
        ELSE
            g_error := 'CALL pk_episode.get_id_patient. id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            l_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        END IF;
    
        g_error := 'GET CURSOR o_doc_area_register';
        OPEN o_doc_area_register FOR
            SELECT id_epis_documentation,
                   PARENT,
                   id_doc_template,
                   template_desc,
                   dt_creation,
                   dt_register,
                   id_professional,
                   nick_name,
                   desc_speciality,
                   id_doc_area,
                   flg_status,
                   desc_status,
                   notes,
                   dt_last_update,
                   flg_type_register
              FROM (SELECT t.id_epis_documentation,
                           t.parent,
                           t.id_doc_template,
                           t.template_desc,
                           t.dt_creation,
                           t.dt_register,
                           t.id_professional,
                           t.nick_name,
                           t.desc_speciality,
                           t.id_doc_area,
                           t.flg_status,
                           t.desc_status,
                           t.notes,
                           t.dt_last_update,
                           t.flg_type_register,
                           rank() over(ORDER BY t.dt_last_update_tstz DESC) origin_rank
                      FROM TABLE(pk_past_history.tf_doc_area_register(i_lang, i_prof, i_id_episode, i_doc_area)) t
                     WHERE t.flg_status = pk_touch_option.g_epis_doc_active
                       AND t.id_doc_template IS NOT NULL)
             WHERE origin_rank = 1;
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT id_epis_documentation,
                   PARENT,
                   id_documentation,
                   id_doc_component,
                   id_doc_element_crit,
                   dt_reg,
                   desc_doc_component,
                   flg_type,
                   desc_element,
                   desc_element_view,
                   VALUE,
                   id_doc_area,
                   rank_component,
                   rank_element,
                   desc_qualification
              FROM (SELECT t.id_epis_documentation,
                           t.parent,
                           t.id_documentation,
                           t.id_doc_component,
                           t.id_doc_element_crit,
                           t.dt_reg,
                           t.desc_doc_component,
                           t.flg_type,
                           t.desc_element,
                           t.desc_element_view,
                           t.value,
                           t.id_doc_area,
                           t.rank_component,
                           t.rank_element,
                           t.desc_qualification,
                           rank() over(ORDER BY ed.dt_last_update_tstz DESC) origin_rank
                      FROM TABLE(pk_past_history.tf_doc_area_val_documentation(i_lang, i_prof, i_id_episode, i_doc_area)) t
                      JOIN epis_documentation ed
                        ON ed.id_epis_documentation = t.id_epis_documentation
                     WHERE ed.flg_status = pk_touch_option.g_epis_doc_active
                       AND ed.id_doc_template IS NOT NULL)
             WHERE origin_rank = 1;
    
        g_error := 'CALL TO GET_SCALES_LIST';
        g_error := 'GET CURSOR O_EPIS_BARTCHART';
        OPEN o_doc_scales FOR
            SELECT id_epis_documentation,
                   id_scales,
                   id_doc_template,
                   desc_class,
                   doc_desc_class,
                   soma,
                   id_professional,
                   nick_name,
                   date_target,
                   hour_target,
                   dt_last_update
              FROM (SELECT t.id_epis_documentation,
                           t.id_scales,
                           t.id_doc_template,
                           t.desc_class,
                           t.doc_desc_class,
                           t.soma,
                           t.id_professional,
                           t.nick_name,
                           t.date_target,
                           t.hour_target,
                           t.dt_last_update,
                           rank() over(ORDER BY t.dt_last_update_tstz DESC) origin_rank
                      FROM TABLE(pk_scales_core.tf_scales_list(i_lang,
                                                               i_prof,
                                                               i_doc_area,
                                                               l_patient,
                                                               pk_inp_util.g_scope_patient_p)) t
                     WHERE t.flg_status = pk_touch_option.g_epis_doc_active
                       AND t.id_doc_template IS NOT NULL)
             WHERE origin_rank = 1;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTL_SCALES_SUMM_PAGE',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            RETURN FALSE;
    END get_wtl_scales_summ_page;

    /******************************************************************************
    *  Function that creates the sys_alert message for the planner profiles, in case of an edition to a barthel index
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_wtl               Waiting List
    *  @param  o_msg                  Message 
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0
    *  @since                      23-02-2010
    ******************************************************************************/
    FUNCTION get_wtl_func_eval_alert_msg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_wtl IN waiting_list.id_waiting_list%TYPE,
        o_msg    OUT sys_message.desc_message%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_mask sys_message.desc_message%TYPE := TRIM(pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'DATE_FORMAT_M006'));
    BEGIN
        g_error := 'GET WTL INFO';
        pk_alertlog.log_debug(g_error);
        SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pk_message.get_message(i_lang,
                                                                              decode(wtl.flg_type,
                                                                                     'A',
                                                                                     'WTL_EVAL_SCORE_01',
                                                                                     'WTL_EVAL_SCORE_02')),
                                                       '@1',
                                                       pk_prof_utils.get_nickname(i_lang, wtl.id_prof_req)),
                                               '@2',
                                               nvl(bi.desc_bed, pk_translation.get_translation(i_lang, bi.code_bed))),
                                       '@3',
                                       pk_date_utils.to_char_timezone(i_lang, si.dt_begin_tstz, l_mask)),
                               '@4',
                               nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))),
                       '@5',
                       pk_date_utils.to_char_timezone(i_lang, s.dt_target_tstz, l_mask))
          INTO o_msg
          FROM waiting_list wtl
          LEFT JOIN schedule_bed sb
            ON sb.id_waiting_list = wtl.id_waiting_list
          LEFT JOIN bed bi
            ON bi.id_bed = sb.id_bed
          LEFT JOIN schedule si
            ON si.id_schedule = sb.id_schedule
          LEFT JOIN wtl_epis we
            ON we.id_waiting_list = wtl.id_waiting_list
           AND we.id_epis_type = pk_alert_constant.g_epis_type_operating
          LEFT JOIN schedule_sr s
            ON s.id_schedule = we.id_schedule
          LEFT JOIN schedule so
            ON so.id_schedule = s.id_schedule
          LEFT JOIN room r
            ON r.id_room = so.id_room
         WHERE wtl.id_waiting_list = i_id_wtl;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTL_FUNC_EVAL_',
                                              o_error);
            RETURN FALSE;
    END get_wtl_func_eval_alert_msg;

    FUNCTION get_wtl_func_eval_alert_msg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_wtl IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
        l_err t_error_out;
        l_msg sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'CALL TO CORE';
        IF NOT get_wtl_func_eval_alert_msg(i_lang, i_prof, i_id_wtl, l_msg, l_err)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTL_FUNC_EVAL_ALERT_MSG',
                                              l_err);
            RETURN NULL;
        
    END get_wtl_func_eval_alert_msg;

    /**************************************************************************
    * Checks if a patient has a valid epis_documentation associated           *
    * to an admission request                                                 *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_patient                  epis documentation id                 *
    *                                                                         *
    * @param o_error                    Error message                         *
    * @param o_flg_val                  Y - Associated; N - No association    *
    * @param o_last_epis_doc            Id_epis_documentation (if applicable) *
    * @param o_last_date_epis_doc       epis_documentation date(if applicable)*
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/01/08                            *
    **************************************************************************/
    FUNCTION check_wtl_func_eval_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE DEFAULT pk_summary_page.g_doc_area_barthel,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        o_flg_val            OUT VARCHAR2,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_epis_doc_count     OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CHECK_WTL_FUNC_EVAL_PAT';
    
    BEGIN
    
        g_error := 'Fetch last doc_area with args i_patient, i_doc_area, i_doc_template: ' || i_patient || ', ' ||
                   i_doc_area || ', ' || i_doc_template;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT id_epis_documentation, dt_creation_tstz, epis_doc_count
          INTO o_last_epis_doc, o_last_date_epis_doc, o_epis_doc_count
          FROM (SELECT ed.id_epis_documentation,
                       ed.dt_creation_tstz,
                       row_number() over(ORDER BY ed.dt_creation_tstz DESC) rn,
                       COUNT(id_epis_documentation) over(PARTITION BY pat.id_patient) epis_doc_count
                  FROM epis_documentation ed
                  JOIN episode epis
                    ON epis.id_episode = ed.id_episode
                  JOIN patient pat
                    ON pat.id_patient = epis.id_patient
                 WHERE pat.id_patient = i_patient
                   AND ed.id_doc_area = i_doc_area
                   AND ed.id_doc_template = nvl(i_doc_template, ed.id_doc_template)
                   AND ed.id_doc_template IS NOT NULL
                   AND ed.flg_status = pk_touch_option.g_epis_doc_active
                   AND ed.dt_creation_tstz IS NOT NULL)
         WHERE rn = 1;
    
        IF o_last_epis_doc IS NULL
        THEN
            o_flg_val := pk_alert_constant.g_no;
        ELSE
            o_flg_val := pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_flg_val := pk_alert_constant.g_no;
            RETURN TRUE;
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
    END check_wtl_func_eval_pat;

    /***************************************************************************************************************
    *
    * Inserts a new sorting criteria for the provided institution, if no active requests exist
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_inst              Institution ID 
    * @param      i_wtl_sk            WTL sorting key ID
    * @param      o_error                         
    *
    *
    * @RETURN  TRUE or FALSE, 
    * @author  RicardoNunoAlmeida
    * @version 2.6.0
    * @since   01-03-2010
    *
    ****************************************************************************************************/
    FUNCTION ins_sort_key
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        i_wtl_sk    IN wtl_sort_key.id_wtl_sort_key%TYPE,
        i_rank      IN wtl_sort_key_inst_soft.rank%TYPE,
        i_available IN wtl_sort_key_inst_soft.flg_available%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'INS_SORT_KEY';
        l_flg       VARCHAR2(1);
    BEGIN
    
        g_error := 'CALL CHECK_WTL_ACTIVE_RECS';
        IF NOT pk_wtl_prv_core.check_wtl_active_recs(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_inst      => i_inst,
                                                     o_flg_exist => l_flg,
                                                     o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'EVALUATE RESULT';
        IF l_flg = pk_alert_constant.g_yes
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'EVALUATE BARTHEL';
        IF i_wtl_sk = 5
           AND pk_sysconfig.get_config(pk_wtl_pbl_core.g_wtl_sysconfig, i_prof.institution, i_prof.software) <>
           pk_alert_constant.g_yes
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'WRITE TO TABLE';
        MERGE INTO wtl_sort_key_inst_soft wskis
        USING (SELECT i_wtl_sk    id_wtl_sort_key, --
                      i_inst      id_institution,
                      i_rank      rank,
                      i_available flg_available
                 FROM dual) args
        ON (wskis.id_institution = args.id_institution AND wskis.id_wtl_sort_key = args.id_wtl_sort_key)
        WHEN MATCHED THEN
            UPDATE
               SET wskis.rank          = nvl(args.rank, wskis.rank),
                   wskis.flg_available = nvl(args.flg_available, wskis.flg_available)
        WHEN NOT MATCHED THEN
            INSERT
                (id_wtl_sort_key, rank, id_institution, id_software, flg_available)
            VALUES
                (args.id_wtl_sort_key, args.rank, args.id_institution, 0, args.flg_available);
    
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
    END ins_sort_key;

    /***************************************************************************************************************
    *
    * Deletes an existing sorting criteria for the provided institution, if no active requests exist.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_inst              Institution ID 
    * @param      i_wtl_sk            WTL sorting key ID
    * @param      o_error                         
    *
    *
    * @RETURN  TRUE or FALSE, 
    * @author  RicardoNunoAlmeida
    * @version 2.6.0
    * @since   01-03-2010
    *
    ****************************************************************************************************/
    FUNCTION del_sort_key
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_inst   IN institution.id_institution%TYPE,
        i_wtl_sk IN wtl_sort_key.id_wtl_sort_key%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'DEL_SORT_KEY';
        l_flg       VARCHAR2(1);
    BEGIN
    
        g_error := 'CALL CHECK_WTL_ACTIVE_RECS';
        IF NOT pk_wtl_prv_core.check_wtl_active_recs(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_inst      => i_inst,
                                                     o_flg_exist => l_flg,
                                                     o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'EVALUATE RESULT';
        IF l_flg = pk_alert_constant.g_yes
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'WRITE TO TABLE';
        DELETE FROM wtl_sort_key_inst_soft wskis
         WHERE wskis.id_wtl_sort_key = i_wtl_sk
           AND wskis.id_institution = i_inst;
    
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
    END del_sort_key;

    /* 
    *
    */
    FUNCTION get_wl_profs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_wl_type IN VARCHAR2,
        i_dt_dpb  IN waiting_list.dt_dpb%TYPE,
        i_dt_dpa  IN waiting_list.dt_dpa%TYPE,
        i_ids_dcs IN table_number,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_WL_PROFS';
        l_dpb       waiting_list.dt_dpb%TYPE;
        l_count     PLS_INTEGER;
    BEGIN
    
        IF i_ids_dcs IS NULL
        THEN
            l_count := 0;
        ELSE
            l_count := i_ids_dcs.count;
        END IF;
    
        -- search surgery entries
        g_error := 'OPEN CURSOR';
        IF i_wl_type = pk_wtl_prv_core.g_wtlist_type_surgery
        THEN
            OPEN o_result FOR
                SELECT t_wl_prof(id_prof, prof_name)
                  FROM (SELECT DISTINCT wprf.id_prof,
                                         pk_prof_utils.get_name_signature(i_lang, i_prof, wprf.id_prof) prof_name
                           FROM waiting_list wl
                          INNER JOIN wtl_epis wtle
                             ON wtle.id_waiting_list = wl.id_waiting_list
                          INNER JOIN schedule_sr ssr
                             ON wl.id_waiting_list = ssr.id_waiting_list
                           LEFT JOIN wtl_dep_clin_serv wdcs
                             ON ssr.id_waiting_list = wdcs.id_waiting_list
                            AND wdcs.flg_status = pk_alert_constant.g_active
                           LEFT JOIN wtl_prof wprf
                             ON ssr.id_waiting_list = wprf.id_waiting_list
                            AND wprf.id_episode = wtle.id_episode
                          WHERE
                         --waiting list status
                          wl.flg_status IN
                          (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
                         --only surgery episodes
                       AND wtle.id_epis_type = pk_alert_constant.g_epis_type_operating
                       AND wl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_surgery, pk_wtl_prv_core.g_wtlist_type_both)
                         --surgery episode not scheduled
                       AND wtle.flg_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
                         --dpb & dpa
                       AND ((i_dt_dpb IS NULL AND i_dt_dpa IS NULL) OR (i_dt_dpb IS NULL AND wl.dt_dpa <= i_dt_dpa) OR
                          (i_dt_dpa IS NULL AND wl.dt_dpb >= i_dt_dpb) OR
                          (wl.dt_dpb >= i_dt_dpb AND wl.dt_dpa <= i_dt_dpa) OR
                          (wl.dt_dpb <= i_dt_dpb AND wl.dt_dpa >= i_dt_dpa) OR
                          (wl.dt_dpb >= i_dt_dpb AND wl.dt_dpa >= i_dt_dpa AND wl.dt_dpb <= i_dt_dpa) OR
                          (wl.dt_dpb <= i_dt_dpb AND wl.dt_dpa <= i_dt_dpa AND wl.dt_dpa >= i_dt_dpb))
                         -- dcs 
                       AND (l_count = 0 OR (l_count > 0 AND wdcs.id_dep_clin_serv IN
                          (SELECT *
                                                              FROM TABLE(i_ids_dcs))))
                       AND wprf.flg_status = pk_alert_constant.g_active
                       AND wprf.id_prof IS NOT NULL
                          ORDER BY prof_name);
        ELSIF i_wl_type = pk_wtl_prv_core.g_wtlist_type_bed
        THEN
            OPEN o_result FOR
                SELECT t_wl_prof(id_prof, prof_name)
                  FROM (SELECT DISTINCT wprf.id_prof,
                                         pk_prof_utils.get_name_signature(i_lang, i_prof, wprf.id_prof) prof_name
                           FROM waiting_list wtl
                          INNER JOIN wtl_epis wtle
                             ON wtle.id_waiting_list = wtl.id_waiting_list
                          INNER JOIN adm_request ar
                             ON wtle.id_episode = ar.id_dest_episode
                           LEFT JOIN wtl_prof wprf
                             ON wtl.id_waiting_list = wprf.id_waiting_list
                            AND wprf.flg_status = pk_alert_constant.g_active
                          WHERE --waiting list status
                          wtl.flg_status IN
                          (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
                         --only inpatient episodes
                       AND wtle.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                       AND wtl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_bed, pk_wtl_prv_core.g_wtlist_type_both)
                         --inpatient episode not scheduled
                       AND wtle.flg_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
                         -- dpa & dpb
                       AND ((i_dt_dpb IS NULL AND i_dt_dpa IS NULL) OR (i_dt_dpb IS NULL AND wtl.dt_dpa <= i_dt_dpa) OR
                          (i_dt_dpa IS NULL AND wtl.dt_dpb >= i_dt_dpb) OR
                          (wtl.dt_dpb >= i_dt_dpb AND wtl.dt_dpa <= i_dt_dpa) OR
                          (wtl.dt_dpb <= i_dt_dpb AND wtl.dt_dpa >= i_dt_dpa) OR
                          (wtl.dt_dpb >= i_dt_dpb AND wtl.dt_dpa >= i_dt_dpa AND wtl.dt_dpb <= i_dt_dpa) OR
                          (wtl.dt_dpb <= i_dt_dpb AND wtl.dt_dpa <= i_dt_dpa AND wtl.dt_dpa >= i_dt_dpb))
                         -- clinical_services
                       AND (l_count = 0 OR (l_count > 0 AND ar.id_dep_clin_serv IN
                          (SELECT *
                                                              FROM TABLE(i_ids_dcs))))
                          ORDER BY prof_name);
        ELSIF i_wl_type = pk_wtl_prv_core.g_wtlist_type_both
        THEN
            OPEN o_result FOR
                SELECT t_wl_prof(id_prof, prof_name)
                  FROM (SELECT DISTINCT wprf.id_prof,
                                         pk_prof_utils.get_name_signature(i_lang, i_prof, wprf.id_prof) prof_name
                           FROM waiting_list wtl
                          INNER JOIN wtl_epis wtle
                             ON wtle.id_waiting_list = wtl.id_waiting_list
                           LEFT JOIN wtl_prof wprf
                             ON wtl.id_waiting_list = wprf.id_waiting_list
                            AND wprf.flg_status = pk_alert_constant.g_active
                           LEFT JOIN wtl_dep_clin_serv wdcs
                             ON wtl.id_waiting_list = wdcs.id_waiting_list
                            AND wdcs.flg_status = pk_alert_constant.g_active
                          WHERE
                         -- wl status
                          wtl.flg_status IN
                          (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
                         -- only entries with 'both'
                       AND wtl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_both)
                         -- at least one of the episodes not scheduled
                       AND wtle.flg_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
                         -- dpa & dpb
                       AND ((i_dt_dpb IS NULL AND i_dt_dpa IS NULL) OR (i_dt_dpb IS NULL AND wtl.dt_dpa <= i_dt_dpa) OR
                          (i_dt_dpa IS NULL AND wtl.dt_dpb >= i_dt_dpb) OR
                          (wtl.dt_dpb >= l_dpb AND wtl.dt_dpa <= i_dt_dpa) OR
                          (wtl.dt_dpb <= i_dt_dpb AND wtl.dt_dpa >= i_dt_dpa) OR
                          (wtl.dt_dpb >= i_dt_dpb AND wtl.dt_dpa >= i_dt_dpa AND wtl.dt_dpb <= i_dt_dpa) OR
                          (wtl.dt_dpb <= i_dt_dpb AND wtl.dt_dpa <= i_dt_dpa AND wtl.dt_dpa >= i_dt_dpb))
                         -- dcs
                       AND (l_count = 0 OR (l_count > 0 AND wdcs.id_dep_clin_serv IN
                          (SELECT *
                                                              FROM TABLE(i_ids_dcs))))
                       AND wprf.flg_status = pk_alert_constant.g_active
                       AND wprf.id_prof IS NOT NULL
                          ORDER BY prof_name);
        
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
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_wl_profs;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        patient identifier
    *  @param  i_id_adm_indication Indication for admission identifier
    *  @param  i_flg_schedule      If this function should return scheduled episodes ('Y' - Return scheduled episodes; 'N' - Do not return scheduled episodes)
    *  @param  o_epis_data         output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      01-07-2010
    *
    ******************************************************************************/
    FUNCTION get_episode_like_inp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_flg_schedule      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_epis_data         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPISODE_LIKE_INP';
    BEGIN
        OPEN o_epis_data FOR
            SELECT inp_match_episodes.id_episode,
                   inp_match_episodes.id_epis_type,
                   nvl(inp_match_episodes.dt_schedule_begin, inp_match_episodes.dt_proposed_begin) dt_init,
                   nvl(inp_match_episodes.dt_schedule_end, inp_match_episodes.dt_proposed_end) dt_end
              FROM (SELECT epi.id_episode,
                           epi.id_epis_type,
                           we.id_waiting_list,
                           wl.dt_dpb            dt_proposed_begin,
                           wl.dt_dpa            dt_proposed_end,
                           ar.id_adm_request,
                           ar.id_adm_indication,
                           sch.dt_begin_tstz    dt_schedule_begin,
                           sch.dt_end_tstz      dt_schedule_end
                      FROM episode epi
                     INNER JOIN wtl_epis we
                        ON (we.id_episode = epi.id_episode AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient)
                     INNER JOIN adm_request ar
                        ON (ar.id_dest_episode = we.id_episode)
                     INNER JOIN waiting_list wl
                        ON (wl.id_waiting_list = we.id_waiting_list)
                      LEFT JOIN schedule sch
                        ON (sch.id_schedule = we.id_schedule)
                     WHERE epi.id_patient = i_id_patient
                       AND epi.flg_status NOT IN (pk_alert_constant.g_flg_status_c)
                       AND epi.flg_ehr = 'S'
                       AND (we.flg_status IN ('N') OR
                           we.flg_status IN (CASE i_flg_schedule WHEN pk_alert_constant.g_yes THEN 'S' ELSE 'N' END))
                       AND ar.id_adm_indication = nvl(i_id_adm_indication, ar.id_adm_indication)) inp_match_episodes;
        --
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
            pk_types.open_my_cursor(o_epis_data);
            RETURN FALSE;
    END get_episode_like_inp;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        patient identifier
    *  @param  i_id_sr_intervention table_number of surgery interventions identifier's
    *  @param  i_flg_schedule      If this function should return scheduled episodes ('Y' - Return scheduled episodes; 'N' - Do not return scheduled episodes)
    *  @param  o_epis_data         output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      01-07-2010
    *
    ******************************************************************************/
    FUNCTION get_episode_like_oris
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_sr_intervention IN table_number,
        i_flg_schedule       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_epis_data          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_EPISODE_LIKE_ORIS';
    
    BEGIN
    
        OPEN o_epis_data FOR
            SELECT sr_match_episodes.id_episode,
                   sr_match_episodes.id_epis_type,
                   nvl(sr_match_episodes.dt_schedule_begin, sr_match_episodes.dt_proposed_begin) dt_init,
                   nvl(sr_match_episodes.dt_schedule_end, sr_match_episodes.dt_proposed_end) dt_end
              FROM (SELECT DISTINCT e.id_episode,
                                    e.id_epis_type,
                                    we.id_waiting_list,
                                    wtl.dt_dpb         dt_proposed_begin,
                                    wtl.dt_dpa         dt_proposed_end,
                                    sch.dt_begin_tstz  dt_schedule_begin,
                                    sch.dt_end_tstz    dt_schedule_end
                      FROM episode e
                     INNER JOIN wtl_epis we
                        ON (we.id_episode = e.id_episode AND we.id_epis_type = pk_alert_constant.g_epis_type_operating)
                     INNER JOIN waiting_list wtl
                        ON wtl.id_waiting_list = we.id_waiting_list
                     INNER JOIN sr_epis_interv sei
                        ON sei.id_episode_context = e.id_episode
                      LEFT JOIN schedule sch
                        ON (sch.id_schedule = we.id_schedule)
                     WHERE e.id_patient = i_id_patient
                       AND e.flg_status NOT IN (pk_alert_constant.g_flg_status_c)
                       AND e.flg_ehr = 'S'
                       AND (we.flg_status IN ('N') OR
                           we.flg_status IN (CASE i_flg_schedule WHEN pk_alert_constant.g_yes THEN 'S' ELSE 'N' END))
                       AND sei.id_sr_intervention IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                                        FROM TABLE(i_id_sr_intervention) t)) sr_match_episodes;
    
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
            pk_types.open_my_cursor(o_epis_data);
            RETURN FALSE;
    END get_episode_like_oris;

    /******************************************************************************
    *  returns list of dcs for this waiting list entry.
    *  If id_episode is passed then return list is filtered by episode also.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_patient        patient identifier
    *  @param  i_id_adm_indication Indication for admission identifier
    *  @param  i_id_sr_intervention table_number of surgery interventions identifier's
    *  @param  i_flg_schedule      If this function should return scheduled episodes ('Y' - Return scheduled episodes; 'N' - Do not return scheduled episodes)
    *  @param  o_epis_data         output    
    *  @param  o_error             error data 
    *
    *  @return                     boolean
    *
    *  @author                     Luís Maia
    *  @version                    2.6.0.3
    *  @since                      01-07-2010
    *
    ******************************************************************************/
    FUNCTION get_episode_like_inp_oris
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_adm_indication  IN adm_indication.id_adm_indication%TYPE,
        i_id_sr_intervention IN table_number,
        i_flg_schedule       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_epis_data          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPISODE_LIKE_INP_ORIS';
    BEGIN
        OPEN o_epis_data FOR
            SELECT t.id_episode,
                   t.id_epis_type,
                   t.id_waiting_list,
                   nvl(t.dt_schedule_begin, t.dt_proposed_begin) dt_init,
                   nvl(t.dt_schedule_end, t.dt_proposed_end) dt_end
              FROM (SELECT epi.id_episode,
                           epi.id_epis_type,
                           we.id_waiting_list,
                           wtl.dt_dpb         dt_proposed_begin,
                           wtl.dt_dpa         dt_proposed_end,
                           sch.dt_begin_tstz  dt_schedule_begin,
                           sch.dt_end_tstz    dt_schedule_end
                      FROM waiting_list wtl
                     INNER JOIN wtl_epis we
                        ON (wtl.id_waiting_list = we.id_waiting_list)
                     INNER JOIN episode epi
                        ON (epi.id_episode = we.id_episode)
                      LEFT JOIN schedule sch
                        ON (sch.id_schedule = we.id_schedule)
                     WHERE wtl.id_waiting_list IN
                           (SELECT match_wtl.id_waiting_list
                              FROM (SELECT all_epis.id_waiting_list, COUNT(1) num_epis
                                      FROM (SELECT DISTINCT we.id_waiting_list, we.id_episode
                                              FROM episode epi
                                             INNER JOIN wtl_epis we
                                                ON (we.id_episode = epi.id_episode AND
                                                   we.id_epis_type = pk_alert_constant.g_epis_type_operating)
                                             INNER JOIN sr_epis_interv sei
                                                ON sei.id_episode_context = epi.id_episode
                                             WHERE epi.id_patient = i_id_patient
                                               AND epi.flg_status != pk_alert_constant.g_flg_status_c
                                               AND epi.flg_ehr = 'S'
                                               AND (we.flg_status = 'N' OR
                                                   we.flg_status IN
                                                   (CASE i_flg_schedule WHEN pk_alert_constant.g_yes THEN 'S' ELSE 'N' END))
                                               AND sei.id_sr_intervention IN
                                                   (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                                      FROM TABLE(i_id_sr_intervention) t)
                                            UNION
                                            SELECT we.id_waiting_list, we.id_episode
                                              FROM episode epi
                                             INNER JOIN wtl_epis we
                                                ON (we.id_episode = epi.id_episode AND
                                                   we.id_epis_type = pk_alert_constant.g_epis_type_inpatient)
                                             INNER JOIN adm_request ar
                                                ON (ar.id_dest_episode = we.id_episode)
                                             WHERE epi.id_patient = i_id_patient
                                               AND epi.flg_status NOT IN (pk_alert_constant.g_flg_status_c)
                                               AND epi.flg_ehr = 'S'
                                               AND (we.flg_status IN ('N') OR
                                                   we.flg_status IN
                                                   (CASE i_flg_schedule WHEN pk_alert_constant.g_yes THEN 'S' ELSE 'N' END))
                                               AND ar.id_adm_indication = nvl(i_id_adm_indication, ar.id_adm_indication)) all_epis
                                     GROUP BY all_epis.id_waiting_list) match_wtl
                             WHERE match_wtl.num_epis > 1)) t;
    
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
            pk_types.open_my_cursor(o_epis_data);
            RETURN FALSE;
    END get_episode_like_inp_oris;

    /********************************************************************************************
    *  Get waiting list ID of an episode
    *
    * @param    I_LANG          Preferred language ID
    * @param    I_PROF          Object (ID of professional, ID of institution, ID of software)
    * @param    I_EPISODE       Episode ID
    * @param    O_WTL           Waiting list ID
    * @param    O_ERROR         Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Tiago Silva
    * @since    2010/08/12
    ********************************************************************************************/
    FUNCTION get_episode_wtl
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_wtl     OUT waiting_list.id_waiting_list%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wtl waiting_list.id_waiting_list%TYPE;
    BEGIN
        g_error := 'GET EPISODE WAITING LIST ID';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT we.id_waiting_list
          INTO l_wtl
          FROM wtl_epis we
         WHERE we.id_episode = i_episode;
    
        o_wtl := l_wtl;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPISODE_WTL',
                                              o_error);
            RETURN FALSE;
    END get_episode_wtl;

    /********************************************************************************************
    *  Clear waiting list data for a group of episodes
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_TABLE_ID_EPISODES  Table containing episodes to remove from the waiting list tables
    * @param    O_ERROR              Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Sergio Dias
    * @since    2010/09/1
    ********************************************************************************************/
    FUNCTION clear_waiting_list_reset
    (
        i_lang              IN NUMBER,
        i_table_id_episodes IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CLEAR_WAITING_LIST_RESET';
        l_runtime_error   EXCEPTION;
        l_id_waiting_list waiting_list.id_waiting_list%TYPE;
        l_result          NUMBER;
    BEGIN
        g_error := 'i_lang:' || i_lang || '; i_table_id_episodes.COUNT: ' || i_table_id_episodes.count;
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        -- call to alert_reset.check_environment to validate operation
        g_error := 'CALL CHECK_ENVIRONMENT';
        EXECUTE IMMEDIATE 'SELECT alert_reset.check_environment FROM dual'
            INTO l_result;
    
        IF l_result = -1
        THEN
            RAISE l_runtime_error;
        END IF;
    
        FOR i IN i_table_id_episodes.first .. i_table_id_episodes.last
        LOOP
            BEGIN
                g_error := 'GET ID_WAITING_LIST';
                SELECT we.id_waiting_list
                  INTO l_id_waiting_list
                  FROM wtl_epis we
                 WHERE we.id_episode = i_table_id_episodes(i);
            
                --delete ORIS data
                g_error := 'CALL CLEAR_WAITING_LIST_ORIS';
                IF NOT
                    clear_waiting_list_oris(i_lang => i_lang, i_id_waiting_list => l_id_waiting_list, o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                --delete INP data
                g_error := 'CALL CLEAR_WAITING_LIST_INPATIENT';
                IF NOT clear_waiting_list_inpatient(i_lang       => i_lang,
                                                    i_id_episode => i_table_id_episodes(i),
                                                    o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                --delete waiting list data
                g_error := 'DELETE WAITING_LIST DATA';
            
                ts_schedule_bed_hist.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_schedule_bed.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_documentation.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_unav.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_dep_clin_serv.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_epis.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_pref_time.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_prof.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_wtl_ptreason_wtlist.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_waiting_list_hist.del_by(where_clause_in => ' id_waiting_list = ' || l_id_waiting_list);
            
                ts_waiting_list.del(id_waiting_list_in => l_id_waiting_list);
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'No waiting list data for episode: ' || i_table_id_episodes(i);
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                WHEN too_many_rows THEN
                    g_error := 'Too many values in ''wtl_epis'' for id_episode: ' || i_table_id_episodes(i);
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            END;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_runtime_error THEN
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
    END clear_waiting_list_reset;

    /********************************************************************************************
    *  Clear waiting list data in ORIS tables
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_ID_WAITING_LIST    Identificador da waiting list a ser removida
    * @param    O_ERROR              Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Sergio Dias
    * @since    2010/09/1
    ********************************************************************************************/
    FUNCTION clear_waiting_list_oris
    (
        i_lang            IN NUMBER,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CLEAR_WAITING_LIST_ORIS';
        l_id_schedule_sr table_number;
        l_rows           table_varchar;
    BEGIN
    
        g_error := 'i_lang:' || i_lang || '; i_id_waiting_list: ' || i_id_waiting_list;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        --get schedule id to delete
    
        g_error := 'GET ID_SCHEDULE_SR';
        SELECT ss.id_schedule_sr
          BULK COLLECT
          INTO l_id_schedule_sr
          FROM schedule_sr ss
         WHERE ss.id_waiting_list = i_id_waiting_list;
    
        FOR i IN 1 .. l_id_schedule_sr.count
        LOOP
            -- delete references to waiting list from ORIS' tables
            ts_schedule_sr.upd(id_schedule_sr_in   => l_id_schedule_sr(i),
                               id_waiting_list_in  => NULL,
                               id_waiting_list_nin => FALSE,
                               rows_out            => l_rows);
        END LOOP;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN too_many_rows THEN
            g_error := 'Too many rows in table ''schedule_sr'' for id_waiting_list: ' || i_id_waiting_list;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
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
    END clear_waiting_list_oris;

    /********************************************************************************************
    *  Clear waiting list data in INPATIENT tables
    *
    * @param    I_LANG          Preferred language ID
    * @param    I_ID_EPISODE    Episode ID
    * @param    O_ERROR         Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Sergio Dias
    * @since    2010/09/1
    ********************************************************************************************/
    FUNCTION clear_waiting_list_inpatient
    (
        i_lang       IN NUMBER,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(40) := 'CLEAR_WAITING_LIST_INPATIENT';
        l_id_adm_request table_number;
    
    BEGIN
    
        g_error := 'i_lang:' || i_lang || '; i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'GET ID_ADM_REQUEST';
    
        --get adm_request id to delete
        SELECT ar.id_adm_request
          BULK COLLECT
          INTO l_id_adm_request
          FROM adm_request ar
         WHERE ar.id_dest_episode = i_id_episode;
    
        IF (l_id_adm_request IS NOT NULL AND l_id_adm_request.exists(1))
        THEN
            FOR i IN 1 .. l_id_adm_request.count
            LOOP
                ts_adm_req_diagnosis.del_by(where_clause_in => ' id_adm_request = ' || l_id_adm_request(i));
            
                ts_adm_request_hist.del_by(where_clause_in => ' id_adm_request = ' || l_id_adm_request(i));
            
                ts_adm_request.del(id_adm_request_in => l_id_adm_request(i));
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN too_many_rows THEN
            g_error := 'Too many rows in table ''adm_request'' for id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
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
    END clear_waiting_list_inpatient;

    /* private function to wrap the decision and retrieving parts of patients search
    */
    FUNCTION get_patient_ids_bfs
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_gender  IN v_patient_all_markets.gender%TYPE,
        i_min_age IN NUMBER DEFAULT NULL,
        i_max_age IN NUMBER DEFAULT NULL,
        o_ids     OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_PATIENT_IDS_BFS';
    
    BEGIN
    
        g_error := l_func_name || ' - CALL SEARCH_PATIENT';
        IF NOT search_patient(i_lang          => i_lang,
                              i_prof          => i_prof,
                              i_bsn           => NULL,
                              i_ssn           => NULL,
                              i_nhn           => NULL,
                              i_recnum        => NULL,
                              i_birthdate     => NULL,
                              i_gender        => TRIM(i_gender),
                              i_surnameprefix => NULL,
                              i_surnamemaiden => NULL,
                              i_names         => NULL,
                              i_initials      => NULL,
                              i_min_age       => i_min_age,
                              i_max_age       => i_max_age,
                              o_list          => o_ids,
                              o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_patient_ids_bfs;

    /*
    * slave function for use by get_wtlist_search_* functions.
    * It is public because it is also used by pk_Schedule_api_downstream.get_wl_req_data.
    * returns search results in the final specification, wich is a collection of t_wl_search_row. 
    */
    FUNCTION get_output_bfs
    (
        i_wl_type      IN VARCHAR2,
        i_ids          IN table_number,
        i_order_clause IN VARCHAR2
    ) RETURN t_wl_search_row_coll AS
        ret t_wl_search_row_coll;
    BEGIN
        -- tive de usar sql dinamico porque a order by clause e' dinamica
        IF i_order_clause IS NULL
        THEN
            IF i_wl_type = pk_wtl_prv_core.g_wtlist_type_surgery
            THEN
                EXECUTE IMMEDIATE 'SELECT t_wl_search_row(IdRequisition, ' || --
                                  '                       flgType, ' || --
                                  '                       qtl_flg_type, ' || --
                                  '                       flg_status, ' || --
                                  '                       idPatient, ' || --
                                  '                       relative_urgency, ' || --
                                  '                       dtCreation, ' || --
                                  '                       idUserCreation, ' || --
                                  '                       IdInstitution, ' || --
                                  '                       idService, ' || --
                                  '                       idResource, ' || --
                                  '                       ResourceType, ' || --
                                  '                       dtBeginMin, ' || --
                                  '                       dtBeginMax, ' || --
                                  '                       flgContactType, ' || --
                                  '                       priority, ' || -- 
                                  '                       urgencyLevel, ' || --
                                  '                       idLanguage, ' || --
                                  '                       idMotive, ' || --
                                  '                       motiveType, ' || --
                                  '                       motiveDescription, ' || --
                                  '                       sessionNumber, ' || --
                                  '                       frequencyUnit, ' || -- 
                                  '                       frequency, ' || --
                                  '                       idDepclinserv, ' || --
                                  '                       idSpeciality, ' || --
                                  '                       expectedDuration, ' || --
                                  '                       hasRequisitionToSchedule, ' || --
                                  '                       sk_relative_urgency, ' || --
                                  '                       sk_absolute_urgency, ' || --
                                  '                       sk_waiting_time, ' || --
                                  '                       sk_urgency_level, ' || --
                                  '                       sk_barthel, ' || --
                                  '                       sk_gender, ' || --
                                  '                       IdContent, ' || --
                                  '                       dtSugested, ' || -- 
                                  '                       admissionNeeded, ' || --
                                  '                       ids_pref_surgeons, ' || --
                                  '                       icuNeeded, ' || --
                                  '                       pos, ' || --
                                  '                       IdRoomType, ' || --
                                  '                       IdBedType, ' || --
                                  '                       IdPreferedRoom, ' || --
                                  '                       nurseIntakeNeed, ' || -- 
                                  '                       mixedNursing, ' || --
                                  '                       AdmIndic, ' || --
                                  '                       unavailabilityDateBegin, ' || --
                                  '                       unavailabilityDateEnd, ' || --
                                  '                       dangerOfContamination, ' || -- 
                                  '                       idAdmWard, ' || --
                                  '                       idAdmClinServ, ' || --
                                  '                       ProcDiagnosis, ' || --
                                  '                       ProcSurgeon, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL) ' || --
                                  '  FROM v_wl_search_data_surg v ' || --
                                  ' WHERE v.idrequisition IN (SELECT * ' || --
                                  '                             FROM TABLE(:1)) ' --
                                  BULK COLLECT
                    INTO ret
                    USING IN i_ids;
            ELSIF i_wl_type = pk_wtl_prv_core.g_wtlist_type_bed
            THEN
                EXECUTE IMMEDIATE 'SELECT t_wl_search_row(IdRequisition, ' || --
                                  '                       flgType, ' || --
                                  '                       qtl_flg_type, ' || --
                                  '                       flg_status, ' || --
                                  '                       idPatient, ' || --
                                  '                       relative_urgency, ' || --
                                  '                       dtCreation, ' || --
                                  '                       idUserCreation, ' || --
                                  '                       IdInstitution, ' || --
                                  '                       idService, ' || --
                                  '                       idResource, ' || --
                                  '                       ResourceType, ' || --
                                  '                       dtBeginMin, ' || --
                                  '                       dtBeginMax, ' || --
                                  '                       flgContactType, ' || --
                                  '                       priority, ' || -- 
                                  '                       urgencyLevel, ' || --
                                  '                       idLanguage, ' || --
                                  '                       idMotive, ' || --
                                  '                       motiveType, ' || --
                                  '                       motiveDescription, ' || --
                                  '                       sessionNumber, ' || --
                                  '                       frequencyUnit, ' || -- 
                                  '                       frequency, ' || --
                                  '                       idDepclinserv, ' || --
                                  '                       idSpeciality, ' || --
                                  '                       expectedDuration, ' || --
                                  '                       hasRequisitionToSchedule, ' || --
                                  '                       sk_relative_urgency, ' || --
                                  '                       sk_absolute_urgency, ' || --
                                  '                       sk_waiting_time, ' || --
                                  '                       sk_urgency_level, ' || --
                                  '                       sk_barthel, ' || --
                                  '                       sk_gender, ' || --
                                  '                       IdContent, ' || --
                                  '                       dtSugested, ' || -- 
                                  '                       admissionNeeded, ' || --
                                  '                       ids_pref_surgeons, ' || --
                                  '                       icuNeeded, ' || --
                                  '                       pos, ' || --
                                  '                       IdRoomType, ' || --
                                  '                       IdBedType, ' || --
                                  '                       IdPreferedRoom, ' || --
                                  '                       nurseIntakeNeed, ' || -- 
                                  '                       mixedNursing, ' || --
                                  '                       AdmIndic, ' || --
                                  '                       unavailabilityDateBegin, ' || --
                                  '                       unavailabilityDateEnd, ' || --
                                  '                       dangerOfContamination, ' || -- 
                                  '                       idAdmWard, ' || --
                                  '                       idAdmClinServ, ' || --
                                  '                       ProcDiagnosis, ' || --
                                  '                       ProcSurgeon, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL) ' || --
                                  '  FROM v_wl_search_data_adm v ' || --
                                  ' WHERE v.idrequisition IN (SELECT * ' || --
                                  '                             FROM TABLE(:1)) ' --
                                  BULK COLLECT
                    INTO ret
                    USING IN i_ids;
            END IF;
        ELSE
            IF i_wl_type = pk_wtl_prv_core.g_wtlist_type_surgery
            THEN
                EXECUTE IMMEDIATE 'SELECT t_wl_search_row(IdRequisition, ' || --
                                  '                       flgType, ' || --
                                  '                       qtl_flg_type, ' || --
                                  '                       flg_status, ' || --
                                  '                       idPatient, ' || --
                                  '                       relative_urgency, ' || --
                                  '                       dtCreation, ' || --
                                  '                       idUserCreation, ' || --
                                  '                       IdInstitution, ' || --
                                  '                       idService, ' || --
                                  '                       idResource, ' || --
                                  '                       ResourceType, ' || --
                                  '                       dtBeginMin, ' || --
                                  '                       dtBeginMax, ' || --
                                  '                       flgContactType, ' || --
                                  '                       priority, ' || -- 
                                  '                       urgencyLevel, ' || --
                                  '                       idLanguage, ' || --
                                  '                       idMotive, ' || --
                                  '                       motiveType, ' || --
                                  '                       motiveDescription, ' || --
                                  '                       sessionNumber, ' || --
                                  '                       frequencyUnit, ' || -- 
                                  '                       frequency, ' || --
                                  '                       idDepclinserv, ' || --
                                  '                       idSpeciality, ' || --
                                  '                       expectedDuration, ' || --
                                  '                       hasRequisitionToSchedule, ' || --
                                  '                       sk_relative_urgency, ' || --
                                  '                       sk_absolute_urgency, ' || --
                                  '                       sk_waiting_time, ' || --
                                  '                       sk_urgency_level, ' || --
                                  '                       sk_barthel, ' || --
                                  '                       sk_gender, ' || --
                                  '                       IdContent, ' || --
                                  '                       dtSugested, ' || -- 
                                  '                       admissionNeeded, ' || --
                                  '                       ids_pref_surgeons, ' || --
                                  '                       icuNeeded, ' || --
                                  '                       pos, ' || --
                                  '                       IdRoomType, ' || --
                                  '                       IdBedType, ' || --
                                  '                       IdPreferedRoom, ' || --
                                  '                       nurseIntakeNeed, ' || -- 
                                  '                       mixedNursing, ' || --
                                  '                       AdmIndic, ' || --
                                  '                       unavailabilityDateBegin, ' || --
                                  '                       unavailabilityDateEnd, ' || --
                                  '                       dangerOfContamination, ' || -- 
                                  '                       idAdmWard, ' || --
                                  '                       idAdmClinServ, ' || --
                                  '                       ProcDiagnosis, ' || --
                                  '                       ProcSurgeon, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL) ' || --
                                  '  FROM v_wl_search_data_surg v ' || --
                                  ' WHERE v.idrequisition IN (SELECT * ' || --
                                  '                             FROM TABLE(:1)) ' || --
                                  ' ORDER BY ' || i_order_clause -- o order clause nao pode ser bind variable - deixa de ordenar
                                  BULK COLLECT
                    INTO ret
                    USING IN i_ids;
            ELSIF i_wl_type = pk_wtl_prv_core.g_wtlist_type_bed
            THEN
                EXECUTE IMMEDIATE 'SELECT t_wl_search_row(IdRequisition, ' || --
                                  '                       flgType, ' || --
                                  '                       qtl_flg_type, ' || --
                                  '                       flg_status, ' || --
                                  '                       idPatient, ' || --
                                  '                       relative_urgency, ' || --
                                  '                       dtCreation, ' || --
                                  '                       idUserCreation, ' || --
                                  '                       IdInstitution, ' || --
                                  '                       idService, ' || --
                                  '                       idResource, ' || --
                                  '                       ResourceType, ' || --
                                  '                       dtBeginMin, ' || --
                                  '                       dtBeginMax, ' || --
                                  '                       flgContactType, ' || --
                                  '                       priority, ' || -- 
                                  '                       urgencyLevel, ' || --
                                  '                       idLanguage, ' || --
                                  '                       idMotive, ' || --
                                  '                       motiveType, ' || --
                                  '                       motiveDescription, ' || --
                                  '                       sessionNumber, ' || --
                                  '                       frequencyUnit, ' || -- 
                                  '                       frequency, ' || --
                                  '                       idDepclinserv, ' || --
                                  '                       idSpeciality, ' || --
                                  '                       expectedDuration, ' || --
                                  '                       hasRequisitionToSchedule, ' || --
                                  '                       sk_relative_urgency, ' || --
                                  '                       sk_absolute_urgency, ' || --
                                  '                       sk_waiting_time, ' || --
                                  '                       sk_urgency_level, ' || --
                                  '                       sk_barthel, ' || --
                                  '                       sk_gender, ' || --
                                  '                       IdContent, ' || --
                                  '                       dtSugested, ' || -- 
                                  '                       admissionNeeded, ' || --
                                  '                       ids_pref_surgeons, ' || --
                                  '                       icuNeeded, ' || --
                                  '                       pos, ' || --
                                  '                       IdRoomType, ' || --
                                  '                       IdBedType, ' || --
                                  '                       IdPreferedRoom, ' || --
                                  '                       nurseIntakeNeed, ' || -- 
                                  '                       mixedNursing, ' || --
                                  '                       AdmIndic, ' || --
                                  '                       unavailabilityDateBegin, ' || --
                                  '                       unavailabilityDateEnd, ' || --
                                  '                       dangerOfContamination, ' || -- 
                                  '                       idAdmWard, ' || --
                                  '                       idAdmClinServ, ' || --
                                  '                       ProcDiagnosis, ' || --
                                  '                       ProcSurgeon, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL, ' || --
                                  '                       NULL) ' || --
                                  '  FROM v_wl_search_data_adm v ' || --
                                  ' WHERE v.idrequisition IN (SELECT * ' || --
                                  '                             FROM TABLE(:1)) ' || --
                                  ' ORDER BY ' || i_order_clause -- o order clause nao pode ser bind variable - deixa de ordenar
                                  BULK COLLECT
                    INTO ret
                    USING IN i_ids;
            END IF;
        END IF;
    
        RETURN ret;
    
    END get_output_bfs;

    /*
    *  Private function that trims a t_wl_search_row_coll collection at both ends.
    *  used by search_wl_* functions.
    */
    FUNCTION trim_coll_bfs
    (
        i_coll          IN OUT NOCOPY t_wl_search_row_coll,
        i_page          IN NUMBER DEFAULT 1,
        i_rows_per_page IN NUMBER DEFAULT 20
    ) RETURN BOOLEAN AS
    
        l_func_name VARCHAR2(30) := 'TRIM_COLL_BFS';
        l_start     NUMBER := ((i_page - 1) * i_rows_per_page) + 1;
    
    BEGIN
    
        -- trim inferior
        g_error := l_func_name || ' - LOWER TRIM';
        i_coll.delete(1, l_start - 1);
        -- trim superior
        g_error := l_func_name || ' - UPPER TRIM';
        IF nvl(i_rows_per_page, 20) <= i_coll.count
        THEN
            i_coll.trim(i_coll.count - i_rows_per_page);
        END IF;
    
        RETURN TRUE;
    
    END trim_coll_bfs;

    /******************************************************************************
    *  universal waiting list search for surgery entries. Market independent
    *
    *  @param  i_lang                            Language ID
    *  @param  i_prof                            Professional ID/Institution ID/Software ID
    *  @param  i_idsInstitutions -> i_PatName    search criteria
    *  @param  i_page                            pagination info. page is a relative number to the rows per page value
    *  @param  i_rows_per_page                   pagination info. page size
    *  @param  o_result                          output. its a collection of t_wl_search_row
    *  @param  o_rowcount                        absolute row count. Indepedent of pagination
    *  @param  o_error                           error info  
    *
    *  @return                     boolean
    *  @author                     Telmo
    *  @version                    2.6.1.2
    *  @since                      13-01-2012
    ******************************************************************************/
    FUNCTION search_wl_surg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_idsinstitutions     IN table_number,
        i_iddepartment        IN NUMBER,
        i_idclinicalservice   IN NUMBER,
        i_idsprocedures       IN table_number,
        i_idsprefsurgeons     IN table_number,
        i_dtbeginmin          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dtbeginmax          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_idscancelreason     IN table_number,
        i_flgsstatus          IN table_varchar,
        i_minexpectedduration IN NUMBER,
        i_maxexpectedduration IN NUMBER,
        i_flgpos              IN VARCHAR2,
        i_patminage           IN NUMBER,
        i_patmaxage           IN NUMBER,
        i_patgender           IN VARCHAR2,
        i_idpatient           IN NUMBER,
        i_page                IN NUMBER DEFAULT 1,
        i_rows_per_page       IN NUMBER DEFAULT 20,
        o_result              OUT t_wl_search_row_coll,
        o_rowcount            OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'SEARCH_WL_SURG';
        l_id_wtlist table_number;
        l_inst      institution.id_institution%TYPE;
        l_query     VARCHAR2(4000 CHAR);
        l_dummy     BOOLEAN;
    
        l_minduration             schedule_sr.duration%TYPE;
        l_maxduration             schedule_sr.duration%TYPE;
        l_pos                     VARCHAR2(1);
        l_ids_surgeons_count      NUMBER := 0;
        l_ids_procs_count         NUMBER := 0;
        l_flg_status_count        NUMBER := 0;
        l_ids_cancel_reason_count NUMBER := 0;
        l_ids_pat                 table_number; -- Do not initialize this var
        l_ids_pat_count           NUMBER := 0;
        l_wtl_inst_count          NUMBER := 0;
    
        --sorting criteria
        l_sk           t_table_wtl_skis := t_table_wtl_skis();
        l_wtlsk_gender wtl_sort_key.id_wtl_sort_key%TYPE := 6; --gender
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- convert ids surgeons - OK
        g_error := l_func_name || ' - CONVERT SURGEONS';
        IF i_idsprefsurgeons IS NOT NULL
        THEN
            l_ids_surgeons_count := i_idsprefsurgeons.count;
        END IF;
    
        -- convert ids procedures - OK
        g_error := l_func_name || ' - CONVERT PROCEDURES';
        IF i_idsprocedures IS NOT NULL
        THEN
            l_ids_procs_count := i_idsprocedures.count;
        END IF;
    
        -- convert ids schedule cancel reasons OK
        g_error := l_func_name || ' - CONVERT SCHEDULE CANCEL REASONS';
        IF i_idscancelreason IS NOT NULL
        THEN
            l_ids_cancel_reason_count := i_idscancelreason.count;
        END IF;
    
        -- convert search status  OK
        g_error := l_func_name || ' - CONVERT SEARCH STATUS';
        IF i_flgsstatus IS NOT NULL
        THEN
            l_flg_status_count := i_flgsstatus.count;
        END IF;
    
        -- convert ids institutions - OK
        g_error := l_func_name || ' - CONVERT INSTITUTIONS LIST IDS';
        IF i_idsinstitutions IS NOT NULL
        THEN
            l_wtl_inst_count := i_idsinstitutions.count;
        END IF;
    
        -- get patients that match given criteria  OK
        IF i_idpatient IS NOT NULL
        THEN
            l_ids_pat       := table_number(i_idpatient);
            l_ids_pat_count := 1;
        ELSE
            g_error := l_func_name || ' - SEARCH PATIENTS';
            IF NOT get_patient_ids_bfs(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_gender  => i_patgender,
                                       i_min_age => i_patminage,
                                       i_max_age => i_patmaxage,
                                       o_ids     => l_ids_pat,
                                       o_error   => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_ids_pat IS NULL
            THEN
                l_ids_pat_count := 0;
            ELSE
                l_ids_pat_count := l_ids_pat.count;
            END IF;
        END IF;
    
        -- expected min duration  OK
        g_error := l_func_name || ' - CONVERT MIN DURATION TO MINUTES';
        IF i_minexpectedduration IS NOT NULL
        THEN
            l_minduration := i_minexpectedduration * 60;
        END IF;
    
        -- expected max duration  OK
        g_error := l_func_name || ' - CONVERT MAX DURATION TO MINUTES';
        IF i_maxexpectedduration IS NOT NULL
        THEN
            l_maxduration := i_maxexpectedduration * 60;
        END IF;
    
        -- POS existence  OK
        g_error := l_func_name || ' - CONVERT DURATION TO MINUTES';
        l_pos   := TRIM(i_flgpos);
    
        -- SEARCH QUERY STARTS HERE
        g_error := l_func_name || ' - SEARCH WAITING LIST';
        SELECT DISTINCT wtl.id_waiting_list
          BULK COLLECT
          INTO l_id_wtlist
          FROM waiting_list wtl
         INNER JOIN wtl_epis wtle
            ON wtle.id_waiting_list = wtl.id_waiting_list
         INNER JOIN schedule_sr ssr
            ON wtl.id_waiting_list = ssr.id_waiting_list
          LEFT JOIN sr_epis_interv si
            ON ssr.id_episode = si.id_episode_context
          LEFT JOIN wtl_dep_clin_serv wdcs
            ON ssr.id_waiting_list = wdcs.id_waiting_list
           AND wdcs.flg_status = pk_alert_constant.g_active
          LEFT JOIN wtl_prof wprf
            ON ssr.id_waiting_list = wprf.id_waiting_list
           AND wprf.flg_status = pk_alert_constant.g_active
         WHERE
        --waiting list status
         wtl.flg_status IN (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
        --only surgery episodes
         AND wtle.id_epis_type = pk_alert_constant.g_epis_type_operating
         AND wtl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_surgery, pk_wtl_prv_core.g_wtlist_type_both)
        --surgery episode not scheduled
         AND wtle.flg_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
        -- institutions
         AND (l_wtl_inst_count = 0 OR wtl.flg_type = pk_wtl_prv_core.g_wtlist_type_surgery OR -- se for do tipo S nao tem adm_request. esta aqui para impedir chegar a' terceira condicao
          (SELECT ar.id_dest_inst
              FROM wtl_epis we
             INNER JOIN adm_request ar
                ON ar.id_dest_episode = we.id_episode
             WHERE we.id_waiting_list = wtl.id_waiting_list
               AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient
               AND rownum = 1) IN (SELECT column_value
                                      FROM TABLE(i_idsinstitutions)))
        --waiting list episodes status
         AND ((l_flg_status_count = 0) OR
         --all status
         (g_wtl_search_st_all IN (SELECT *
                                     FROM TABLE(i_flgsstatus))) OR
         --schedule
         (g_wtl_search_st_schedule IN (SELECT *
                                          FROM TABLE(i_flgsstatus)) AND
         wtl.id_waiting_list IN (SELECT id_waiting_list
                                     FROM wtl_epis
                                    WHERE id_epis_type = pk_alert_constant.g_epis_type_inpatient
                                      AND flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule)) OR
         --not schedule
         (g_wtl_search_st_not_schedule IN (SELECT *
                                              FROM TABLE(i_flgsstatus)) AND
         wtl.id_waiting_list IN
         (SELECT id_waiting_list
              FROM wtl_epis
             WHERE id_epis_type = pk_alert_constant.g_epis_type_inpatient
               AND flg_status IN
                   (pk_wtl_prv_core.g_wtl_epis_st_not_schedule, pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule))) OR
         --temporary schedule
         (g_wtl_search_st_schedule IN (SELECT *
                                          FROM TABLE(i_flgsstatus)) AND
         wtl.id_waiting_list IN
         (SELECT id_waiting_list
              FROM wtl_epis we2
             WHERE we2.id_epis_type = pk_alert_constant.g_epis_type_inpatient
               AND we2.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule
               AND pk_alert_constant.g_yes IN (SELECT nvl(sb.flg_temporary, pk_alert_constant.g_no)
                                                 FROM schedule_bed sb
                                                WHERE sb.id_schedule = we2.id_schedule))))
        --dpb & dpa
         AND ((i_dtbeginmin IS NULL AND i_dtbeginmax IS NULL) OR (i_dtbeginmin IS NULL AND wtl.dt_dpa <= i_dtbeginmax) OR
         (i_dtbeginmax IS NULL AND wtl.dt_dpb >= i_dtbeginmin) OR
         (wtl.dt_dpb >= i_dtbeginmin AND wtl.dt_dpa <= i_dtbeginmax) OR
         (wtl.dt_dpb <= i_dtbeginmin AND wtl.dt_dpa >= i_dtbeginmax) OR
         (wtl.dt_dpb >= i_dtbeginmin AND wtl.dt_dpa >= i_dtbeginmax AND wtl.dt_dpb <= i_dtbeginmax) OR
         (wtl.dt_dpb <= i_dtbeginmin AND wtl.dt_dpa <= i_dtbeginmax AND wtl.dt_dpa >= i_dtbeginmin))
        -- dep_clin_servs por intermedio do id_department e id_clinical_service
         AND (wdcs.id_dep_clin_serv IN
         (SELECT dcs.id_dep_clin_serv
             FROM dep_clin_serv dcs
             JOIN department d
               ON dcs.id_department = d.id_department
            WHERE (l_wtl_inst_count = 0 OR
                  d.id_institution IN (SELECT *
                                          FROM TABLE(i_idsinstitutions)))
              AND dcs.id_clinical_service = nvl(i_idclinicalservice, dcs.id_clinical_service)
              AND dcs.id_department = nvl(i_iddepartment, dcs.id_department)))
        -- surgeons 
         AND (l_ids_surgeons_count = 0 OR
         wprf.id_prof IN (SELECT *
                             FROM TABLE(i_idsprefsurgeons)))
        -- surgery procedures
         AND (l_ids_procs_count = 0 OR
         si.id_sr_intervention IN (SELECT *
                                      FROM TABLE(i_idsprocedures)))
        -- patients
         AND (l_ids_pat_count = 0 OR wtl.id_patient IN (SELECT *
                                                      FROM TABLE(l_ids_pat)))
        -- schedule cancel reasons 
         AND (l_ids_cancel_reason_count = 0 OR
         (wtle.flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule AND EXISTS
          (SELECT 1
              FROM schedule s
             WHERE s.id_schedule = wtle.id_schedule
               AND s.id_cancel_reason IN (SELECT *
                                            FROM TABLE(i_idscancelreason)))))
        -- min duration
         AND (l_minduration IS NULL OR nvl(ssr.duration, l_minduration) >= l_minduration)
        -- max duration
         AND (l_maxduration IS NULL OR (nvl(ssr.duration, l_maxduration) <= l_maxduration))
        -- POS
         AND (l_pos IS NULL OR (l_pos = pk_alert_constant.g_no AND NOT EXISTS
          (SELECT 1
                               FROM sr_pos_schedule sps
                              WHERE sps.id_schedule_sr = ssr.id_schedule_sr
                                AND sps.flg_status = 'A')) OR l_pos = pk_alert_constant.g_yes AND EXISTS
          (SELECT 1
             FROM sr_pos_schedule sps
            WHERE sps.id_schedule_sr = ssr.id_schedule_sr
              AND sps.flg_status = 'A'));
    
        --get parent institution
        g_error := l_func_name || ' - GET PARENT INSTITUTION';
        IF NOT pk_utils.get_institution_parent(i_lang   => i_lang,
                                               i_prof   => i_prof,
                                               i_inst   => i_prof.institution,
                                               o_parent => l_inst,
                                               o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --sk
        g_error := l_func_name || ' - GET SORTING KEYS';
        l_sk    := pk_wtl_prv_core.get_sort_keys_core(i_lang => i_lang, i_prof => i_prof, i_inst => l_inst);
    
        FOR i IN 1 .. l_sk.count
        LOOP
            l_query := l_query || CASE
                           WHEN i = 1 THEN
                            ''
                           ELSE
                            ', '
                       END || 'sk_' || l_sk(i).internal_name;
        END LOOP;
    
        g_error := l_func_name || ' - REPLACE BIND VARIABLES';
        pk_context_api.set_parameter('i_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof', i_prof.id);
        pk_context_api.set_parameter('i_software', i_prof.software);
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('l_inst', l_inst);
        pk_context_api.set_parameter('l_wtlsk_gender', l_wtlsk_gender);
        pk_context_api.set_parameter('g_wtl_prof_type_adm_phys', g_wtl_prof_type_adm_phys);
        pk_context_api.set_parameter('g_wtl_dcs_type_specialty', g_wtl_dcs_type_specialty);
        pk_context_api.set_parameter('g_wtl_dcs_type_ext_disc', g_wtl_dcs_type_ext_disc);
    
        -- set output rowcount
        o_rowcount := l_id_wtlist.count;
    
        -- next step is retrieve and return all the data for the ids coming out of the search
        g_error  := l_func_name || ' - GET_OUTPUT_BFS';
        o_result := get_output_bfs(pk_wtl_prv_core.g_wtlist_type_surgery, l_id_wtlist, l_query);
    
        -- now trim the collection. From now on we'll only work with the requested range i_start -> i_start + i_offset
        -- this trim does not happen before inside get_output_bfs because of the order clause
        g_error := l_func_name || ' - TRIM_COLL_BFS';
        l_dummy := trim_coll_bfs(o_result, i_page, i_rows_per_page);
    
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
    END search_wl_surg;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_idsInstitutions -> i_PatName    search criteria
    *  @param i_page               pagination info. page is a relative number to the rows per page value
    *  @param i_rows_per_page      pagination info. page size
    *  @param  o_result            output. its a collection of t_wl_search_row
    *  @param  o_rowcount          absolute row count. Indepedent of pagination
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Telmo Castro
    *  @version                    2.6.1.2
    *  @since                      13-01-2012
    ******************************************************************************/
    FUNCTION search_wl_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_idsinstitutions     IN table_number,
        i_iddepartment        IN NUMBER,
        i_idclinicalservice   IN NUMBER,
        i_idsadmphys          IN table_number,
        i_dtbeginmin          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dtbeginmax          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_idscancelreason     IN table_number,
        i_flgsstatus          IN table_varchar,
        i_idsindicadm         IN table_number,
        i_minexpectedduration IN NUMBER,
        i_maxexpectedduration IN NUMBER,
        i_patminage           IN NUMBER,
        i_patmaxage           IN NUMBER,
        i_patgender           IN VARCHAR2,
        i_idpatient           IN NUMBER,
        i_page                IN NUMBER DEFAULT 1,
        i_rows_per_page       IN NUMBER DEFAULT 20,
        o_result              OUT t_wl_search_row_coll,
        o_rowcount            OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'SEARCH_WL_ADM';
        l_id_wtlist table_number;
        l_inst      institution.id_institution%TYPE;
        l_query     VARCHAR2(1000 CHAR);
        l_dummy     BOOLEAN;
    
        -- search vars
        l_ids_adm_phys_count      NUMBER := 0;
        l_ids_ind_adm_count       NUMBER := 0;
        l_ids_cancel_reason_count NUMBER := 0;
        l_surg_status_count       NUMBER := 0;
        l_ids_pat                 table_number; -- Do not initialize this var
        l_ids_pat_count           NUMBER := 0;
        l_wtl_inst_count          NUMBER := 0;
    
        --sorting criteria
        l_sk           t_table_wtl_skis := t_table_wtl_skis();
        l_wtlsk_gender wtl_sort_key.id_wtl_sort_key%TYPE := 6; --gender
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- convert ids physicians OK
        g_error := l_func_name || ' - CONVERT ADM PHYSICIANS';
        IF i_idsadmphys IS NOT NULL
        THEN
            l_ids_adm_phys_count := i_idsadmphys.count;
        END IF;
    
        -- convert ids admission indications OK
        g_error := l_func_name || ' - CONVERT ADMISSION INDICATIONS';
        IF i_idsindicadm IS NOT NULL
        THEN
            l_ids_ind_adm_count := i_idsindicadm.count;
        END IF;
    
        -- convert ids cancel reasons OK
        g_error := l_func_name || ' - CONVERT CANCEL REASONS';
        IF i_idscancelreason IS NOT NULL
        THEN
            l_ids_cancel_reason_count := i_idscancelreason.count;
        END IF;
    
        -- convert search status  OK
        g_error := l_func_name || ' - CONVERT SEARCH STATUS';
        IF i_flgsstatus IS NOT NULL
        THEN
            l_surg_status_count := i_flgsstatus.count;
        END IF;
    
        -- convert ids institutions  OK
        g_error := l_func_name || ' - CONVERT INSTITUTION IDS';
        IF i_idsinstitutions IS NOT NULL
        THEN
            l_wtl_inst_count := i_idsinstitutions.count;
        END IF;
    
        -- get patients that match given criteria OK
        g_error := l_func_name || ' - SEARCH PATIENTS';
        IF i_idpatient IS NOT NULL
        THEN
            l_ids_pat       := table_number(i_idpatient);
            l_ids_pat_count := 1;
        ELSE
            g_error := l_func_name || ' - SEARCH PATIENTS';
            IF NOT get_patient_ids_bfs(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_gender  => i_patgender,
                                       i_min_age => i_patminage,
                                       i_max_age => i_patmaxage,
                                       o_ids     => l_ids_pat,
                                       o_error   => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_ids_pat IS NULL
            THEN
                l_ids_pat_count := 0;
            ELSE
                l_ids_pat_count := l_ids_pat.count;
            END IF;
        END IF;
    
        -- SEARCH QUERY STARTS HERE
        g_error := l_func_name || ' - SEARCH WAITING LIST';
        SELECT DISTINCT x.id_waiting_list
          BULK COLLECT
          INTO l_id_wtlist
          FROM (SELECT wtl.flg_status,
                        wtle.id_epis_type,
                        wtl.flg_type,
                        wtle.flg_status AS f_status,
                        ar.id_dest_inst,
                        wtl.id_waiting_list,
                        wtl.dt_dpb,
                        wtl.dt_dpa,
                        ar.id_dep_clin_serv,
                        wprf.id_prof,
                        ar.id_adm_indication,
                        ar.expected_duration,
                        wtle.id_schedule
                   FROM waiting_list wtl
                  INNER JOIN wtl_epis wtle
                     ON wtle.id_waiting_list = wtl.id_waiting_list
                  INNER JOIN adm_request ar
                     ON wtle.id_episode = ar.id_dest_episode
                  INNER JOIN adm_indication ai
                     ON ai.id_adm_indication = ar.id_adm_indication
                   LEFT JOIN adm_ind_dep_clin_serv aidcs
                     ON ar.id_adm_indication = aidcs.id_adm_indication
                    AND aidcs.flg_available = pk_alert_constant.g_yes
                   LEFT JOIN escape_department ed
                     ON aidcs.id_adm_indication = ed.id_adm_indication
                    AND ai.flg_escape = pk_alert_constant.g_active
                   LEFT JOIN wtl_prof wprf
                     ON wtl.id_waiting_list = wprf.id_waiting_list
                    AND wprf.flg_status = pk_alert_constant.g_active
                    AND wprf.flg_type = pk_alert_constant.g_active
                  WHERE
                 -- patients
                  (wtl.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                       *
                                        FROM TABLE(l_ids_pat) t))
               AND rownum > 0) x
         WHERE
        --waiting list status
         x.flg_status IN (pk_wtl_prv_core.g_wtlist_status_active, pk_wtl_prv_core.g_wtlist_status_partial)
        --only inpatient episodes
         AND x.id_epis_type = pk_alert_constant.g_epis_type_inpatient
         AND x.flg_type IN (pk_wtl_prv_core.g_wtlist_type_bed, pk_wtl_prv_core.g_wtlist_type_both)
        --inpatient episode not scheduled
         AND x.f_status NOT IN (pk_wtl_prv_core.g_wtl_epis_st_schedule)
        -- institutions
         AND (l_wtl_inst_count = 0 OR
         x.id_dest_inst IN (SELECT column_value
                               FROM TABLE(i_idsinstitutions)))
        --waiting list episodes status
         AND (l_surg_status_count = 0 OR
         --all status
         (g_wtl_search_st_all IN (SELECT *
                                     FROM TABLE(i_flgsstatus))) OR
         --schedule
         (g_wtl_search_st_schedule IN (SELECT *
                                          FROM TABLE(i_flgsstatus)) AND
         x.id_waiting_list IN (SELECT wep.id_waiting_list
                                   FROM wtl_epis wep
                                  WHERE wep.id_epis_type = pk_alert_constant.g_epis_type_operating
                                    AND wep.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule)) OR
         --not schedule
         (g_wtl_search_st_not_schedule IN (SELECT *
                                              FROM TABLE(i_flgsstatus)) AND
         x.id_waiting_list IN
         (SELECT wep.id_waiting_list
              FROM wtl_epis wep
             WHERE wep.id_epis_type = pk_alert_constant.g_epis_type_operating
               AND wep.flg_status IN
                   (pk_wtl_prv_core.g_wtl_epis_st_not_schedule, pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule))) OR
         --no surgery
         (g_wtl_search_st_no_surgery IN (SELECT *
                                            FROM TABLE(i_flgsstatus)) AND
         x.flg_type = pk_wtl_prv_core.g_wtlist_type_bed) OR
         --temporary schedule
         (g_wtl_search_st_schedule_temp IN (SELECT *
                                               FROM TABLE(i_flgsstatus)) AND
         x.id_waiting_list IN
         (SELECT wep.id_waiting_list
              FROM wtl_epis wep
             WHERE wep.id_epis_type = pk_alert_constant.g_epis_type_operating
               AND wep.flg_status = pk_wtl_prv_core.g_wtl_epis_st_schedule
               AND wep.id_schedule IN (SELECT DISTINCT ssr.id_schedule
                                         FROM schedule_sr ssr
                                        WHERE ssr.flg_temporary = pk_alert_constant.g_yes))))
        --dpb & dpa
         AND ((i_dtbeginmin IS NULL AND i_dtbeginmax IS NULL) OR (i_dtbeginmin IS NULL AND x.dt_dpa <= i_dtbeginmax) OR
         (i_dtbeginmax IS NULL AND x.dt_dpb >= i_dtbeginmin) OR
         (x.dt_dpb >= i_dtbeginmin AND x.dt_dpa <= i_dtbeginmax) OR
         (x.dt_dpb <= i_dtbeginmin AND x.dt_dpa >= i_dtbeginmax) OR
         (x.dt_dpb >= i_dtbeginmin AND x.dt_dpa >= i_dtbeginmax AND x.dt_dpb <= i_dtbeginmax) OR
         (x.dt_dpb <= i_dtbeginmin AND x.dt_dpa <= i_dtbeginmax AND x.dt_dpa >= i_dtbeginmin))
        -- dcs por intermedio do id_department + id_clinical_service
         AND (x.id_dep_clin_serv IN
         (SELECT dcs.id_dep_clin_serv
             FROM dep_clin_serv dcs
             JOIN department d
               ON dcs.id_department = d.id_department
            WHERE (l_wtl_inst_count = 0 OR
                  d.id_institution IN (SELECT *
                                          FROM TABLE(i_idsinstitutions)))
              AND (i_idclinicalservice IS NULL OR dcs.id_clinical_service = i_idclinicalservice)
              AND (i_iddepartment IS NULL OR dcs.id_department = i_iddepartment)))
        -- admiting physicians
         AND (l_ids_adm_phys_count = 0 OR
         (x.id_prof IN (SELECT *
                           FROM TABLE(i_idsadmphys))))
        -- indication admissions
         AND (l_ids_ind_adm_count = 0 OR
         (x.id_adm_indication IN (SELECT *
                                     FROM TABLE(i_idsindicadm))))
        -- min admission duration
         AND (i_minexpectedduration IS NULL OR (nvl(x.expected_duration, i_minexpectedduration) >= i_minexpectedduration))
        -- max admission duration
         AND (i_maxexpectedduration IS NULL OR (nvl(x.expected_duration, i_maxexpectedduration) <= i_maxexpectedduration))
        -- cancel reasons
         AND (l_ids_cancel_reason_count = 0 OR
         (x.f_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule AND EXISTS
          (SELECT 1
              FROM schedule s
             WHERE s.id_schedule = x.id_schedule
               AND s.id_cancel_reason IN (SELECT *
                                            FROM TABLE(i_idscancelreason)))));
    
        -- get parent institution
        g_error := l_func_name || ' - GET PARENT INSTITUTION';
        IF NOT pk_utils.get_institution_parent(i_lang   => i_lang,
                                               i_prof   => i_prof,
                                               i_inst   => i_prof.institution,
                                               o_parent => l_inst,
                                               o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --sk
        g_error := l_func_name || ' - GET SORTING KEYS';
        l_sk    := pk_wtl_prv_core.get_sort_keys_core(i_lang => i_lang, i_prof => i_prof, i_inst => l_inst);
    
        FOR i IN 1 .. l_sk.count
        LOOP
            l_query := l_query || CASE
                           WHEN i = 1 THEN
                            ''
                           ELSE
                            ', '
                       END || 'sk_' || l_sk(i).internal_name;
        END LOOP;
    
        g_error := l_func_name || ' - REPLACE BIND VARIABLES';
        pk_context_api.set_parameter('i_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof', i_prof.id);
        pk_context_api.set_parameter('i_software', i_prof.software);
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('g_id_epis_type_surgery', pk_wtl_prv_core.g_id_epis_type_surgery);
        pk_context_api.set_parameter('g_id_epis_type_inpatient', pk_wtl_prv_core.g_id_epis_type_inpatient);
        pk_context_api.set_parameter('l_inst', l_inst);
        pk_context_api.set_parameter('l_wtlsk_gender', l_wtlsk_gender);
    
        -- set output rowcount
        o_rowcount := l_id_wtlist.count;
    
        -- next step is retrieve and return all the data for the ids coming out of the search
        g_error  := l_func_name || ' - GET_OUTPUT_BFS';
        o_result := get_output_bfs(pk_wtl_prv_core.g_wtlist_type_bed, l_id_wtlist, l_query);
    
        -- now trim the collection. From now on we'll only work with the requested range i_start -> i_start + i_offset
        -- this trim does not happen before inside get_output_bfs because of the order clause
        g_error := l_func_name || ' - TRIM_COLL_BFS';
        l_dummy := trim_coll_bfs(o_result, i_page, i_rows_per_page);
    
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
    END search_wl_adm;

    FUNCTION get_procedure_diagnosis_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
    
        l_diagnosis table_varchar;
    
    BEGIN
    
        g_error := 'PROCEDURE DIAGNOSIS';
        SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                          i_id_diagnosis        => d.id_diagnosis,
                                          i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                          i_code                => d.code_icd,
                                          i_flg_other           => d.flg_other,
                                          i_flg_std_diag        => ad.flg_icd9) diagnosis
          BULK COLLECT
          INTO l_diagnosis
          FROM sr_epis_interv srei
          JOIN epis_diagnosis ed
            ON ed.id_epis_diagnosis = srei.id_epis_diagnosis
         INNER JOIN diagnosis d
            ON d.id_diagnosis = ed.id_diagnosis
         INNER JOIN alert_diagnosis ad
            ON ed.id_alert_diagnosis = ad.id_alert_diagnosis
         INNER JOIN wtl_epis wtle
            ON wtle.id_episode = srei.id_episode_context
         WHERE srei.flg_type = pk_sr_planning.g_epis_interv_type_p
           AND srei.flg_status <> pk_wtl_prv_core.g_sr_epis_interv_status_c
           AND wtle.id_waiting_list = i_id_waiting_list;
    
        IF l_diagnosis.exists(1)
        THEN
            RETURN l_diagnosis(1);
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_diagnosis_string;

    FUNCTION get_proc_main_surgeon_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2 IS
    
        l_professional table_number;
    
    BEGIN
    
        g_error := 'GET TEAM PROF';
        SELECT srpt.id_prof_team_leader
          BULK COLLECT
          INTO l_professional
          FROM sr_epis_interv srei
          JOIN sr_prof_team_det srpt
            ON srpt.id_sr_epis_interv = srei.id_sr_epis_interv
         INNER JOIN wtl_epis wtle
            ON wtle.id_episode = srei.id_episode_context
         WHERE srei.flg_type = pk_sr_planning.g_epis_interv_type_p
           AND srei.flg_status <> pk_wtl_prv_core.g_sr_epis_interv_status_c
           AND wtle.id_waiting_list = i_id_waiting_list;
    
        IF l_professional.exists(1)
        THEN
            RETURN pk_prof_utils.get_name_signature(i_lang, i_prof, l_professional(1));
        ELSE
            g_error := 'GET MAIN SURGEON';
            SELECT wtlp.id_prof
              BULK COLLECT
              INTO l_professional
              FROM wtl_epis wtle
              JOIN wtl_prof wtlp
                ON wtle.id_waiting_list = wtlp.id_waiting_list
             WHERE wtle.id_waiting_list = i_id_waiting_list
               AND wtlp.flg_type = pk_wtl_pbl_core.g_wtl_prof_type_surgeon
               AND wtlp.flg_status = pk_alert_constant.g_active;
        
            IF l_professional.exists(1)
            THEN
                RETURN pk_prof_utils.get_name_signature(i_lang, i_prof, l_professional(1));
            ELSE
                RETURN NULL;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_proc_main_surgeon_string;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_wtl_pbl_core;
/
