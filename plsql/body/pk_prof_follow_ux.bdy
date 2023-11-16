/*-- Last Change Revision: $Rev: 2027531 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_prof_follow_ux IS

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
    
    BEGIN
    
        IF NOT pk_prof_follow.set_follow_episode_by_me(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_episode  => i_id_episode,
                                                       i_id_schedule => i_id_schedule,
                                                       i_flag_active => i_flag_active,
                                                       o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_follow_episode_by_me;

    /**
    * Add a patient in the grid 'List of my follow-up requests'
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
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
    
    BEGIN
    
        IF NOT pk_prof_follow.set_follow_opinion_by_me(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_opinion  => i_id_opinion,
                                                       i_flag_active => i_flag_active,
                                                       o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_follow_opinion_by_me;

END pk_prof_follow_ux;
/
