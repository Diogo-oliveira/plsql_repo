/*-- Last Change Revision: $Rev: 2028885 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prof_follow_ux IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);
    g_exception EXCEPTION;

    g_error VARCHAR2(4000); -- Localização do erro 

END pk_prof_follow_ux;
/
