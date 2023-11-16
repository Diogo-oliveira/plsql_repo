/*-- Last Change Revision: $Rev: 2027529 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_prof_follow IS

    -- Author  : JORGE.SILVA
    -- Created : 17-09-2012 11:01:04
    -- Purpose : Amb Team development 

    /**
    * Add a patient in the grid 'My Patient'
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_id_schedule        The schedule id
    * @param i_flag_active        Active identifier Y/N
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Jorge Silva
    * @version               2.6.2
    * @since                 2012/09/17
    */
    FUNCTION set_follow_episode_by_me
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_info.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flag_active IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_FOLLOW_EPISODE_BY_ME';
        l_count     NUMBER := NULL;
    
        l_rowids table_varchar;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => g_package_name, --g_package_name
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_episode: ' || i_id_episode || ' | i_id_schedule: ' || i_id_schedule ||
                             ' | i_flag_active: ' || i_flag_active);
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_flag_active IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- check type of operation insert/update
        g_error := 'ERROR IN COUNT OF PROF_FOLLOW_EPISODE';
        SELECT COUNT(1)
          INTO l_count
          FROM prof_follow_episode pfe
         WHERE pfe.id_professional = i_prof.id
           AND pfe.id_episode = i_id_episode
           AND pfe.id_schedule = i_id_schedule;
    
        IF l_count = 0
        THEN
            g_error := 'INSERT PROF_FOLLOW_EPISODE';
            ts_prof_follow_episode.ins(id_professional_in => i_prof.id,
                                       id_episode_in      => i_id_episode,
                                       id_schedule_in     => i_id_schedule,
                                       flg_active_in      => i_flag_active,
                                       rows_out           => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PROF_FOLLOW_EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
        
            g_error := 'UPDATE PROF_FOLLOW_EPISODE';
            ts_prof_follow_episode.upd(flg_active_in => i_flag_active,
                                       where_in      => ' id_professional = ' || i_prof.id || ' AND id_episode = ' ||
                                                        i_id_episode || ' AND id_schedule = ' || i_id_schedule,
                                       rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'PROF_FOLLOW_EPISODE', l_rowids, o_error);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_follow_episode_by_me;

    /**
     * Returns flg_active field of prof_follow_episode
     *
     * @param i_prof               Professional identifier
     * @param i_id_episode         Episode id
     * @param i_id_schedule        Schedule id
     *
     * @return                flg_active field of prof_follow_episode
    *
     * @author                Jorge Silva
     * @version               2.6.2
     * @since                 2012/09/17
     */

    FUNCTION get_follow_episode_by_me
    (
        i_prof        IN profissional,
        i_id_episode  IN epis_info.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name  VARCHAR2(32 CHAR) := 'GET_FOLLOW_EPISODE_BY_ME';
        l_flg_active professional_record.flg_active%TYPE;
    BEGIN
        /*pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_prof: ' || pk_utils.to_string(i_prof) || ' | i_id_episode: ' || i_id_episode ||
                             ' | i_id_schedule: ' || i_id_schedule);*/
    
        g_error := 'get flg_active';
        -- returns flg_active from professional_record table for the input parameters
        SELECT flg_active
          INTO l_flg_active
          FROM prof_follow_episode pfe
         WHERE pfe.id_professional = i_prof.id
           AND pfe.id_episode = i_id_episode
           AND pfe.id_schedule = i_id_schedule;
    
        RETURN l_flg_active;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_follow_episode_by_me;

    /**
    * Add a patient in the grid 'List of my follow-up requests'
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_id_opinion         The opinion id
    * @param i_flag_active        Active identifier Y/N
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Jorge Silva
    * @version               2.6.2
    * @since                 2012/09/18
    */
    FUNCTION set_follow_opinion_by_me
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_opinion  IN opinion.id_opinion%TYPE,
        i_flag_active IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_FOLLOW_OPINION_BY_ME';
        l_count     NUMBER := NULL;
    
        l_rowids table_varchar;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => g_package_name, --g_package_name
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) ||
                             ' | i_id_opinion: ' || i_id_opinion || ' | i_flag_active: ' || i_flag_active);
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_flag_active IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- check type of operation insert/update
        g_error := 'ERROR IN COUNT OF PROF_FOLLOW_OPINION';
        SELECT COUNT(1)
          INTO l_count
          FROM prof_follow_opinion pfo
         WHERE pfo.id_professional = i_prof.id
           AND pfo.id_opinion = i_id_opinion;
    
        IF l_count = 0
        THEN
        
            g_error := 'INSERT PROF_FOLLOW_OPINION';
            ts_prof_follow_opinion.ins(id_professional_in => i_prof.id,
                                       id_opinion_in      => i_id_opinion,
                                       flg_active_in      => i_flag_active,
                                       rows_out           => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PROF_FOLLOW_OPINION',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
        
            g_error := 'UPDATE PROF_FOLLOW_OPINION';
            ts_prof_follow_opinion.upd(id_professional_in => i_prof.id,
                                       id_opinion_in      => i_id_opinion,                      
                                       flg_active_in => i_flag_active,
                                       rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'PROF_FOLLOW_OPINION', l_rowids, o_error);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_follow_opinion_by_me;

    /**
     * Returns flg_active field of prof_follow_opinion table
     *
     * @param i_prof               Professional identifier
     * @param i_id_opinion         Opinion id
     *
     * @return                flg_active field of prof_follow_episode
    *
     * @author                Jorge Silva
     * @version               2.6.2
     * @since                 2012/09/18
     */
    FUNCTION get_follow_opinion_by_me
    (
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name  VARCHAR2(32 CHAR) := 'GET_FOLLOW_EPISODE_BY_ME';
        l_flg_active professional_record.flg_active%TYPE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => g_package_name,
                             sub_object_name => l_func_name);
    
        pk_alertlog.log_info('i_prof: ' || pk_utils.to_string(i_prof) || ' | i_id_opinion: ' || i_id_opinion);
    
        g_error := 'get flg_active';
        -- returns flg_active from professional_record table for the input parameters
        SELECT flg_active
          INTO l_flg_active
          FROM prof_follow_opinion pfo
         WHERE pfo.id_professional = i_prof.id
           AND pfo.id_opinion = i_id_opinion;
    
        RETURN l_flg_active;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_follow_opinion_by_me;
END pk_prof_follow;
/
