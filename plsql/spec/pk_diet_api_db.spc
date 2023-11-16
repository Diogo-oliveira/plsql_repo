/*-- Last Change Revision: $Rev: 2028605 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_diet_api_db IS

    -- Author  : JORGE.SILVA
    -- Created : 26-02-2013 15:01:35
    -- Purpose : 

    /*
    * Returns a list of  diets for the crisis machine
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_search_interval   Search interval
    
    * @author    Jorge Silva
    * @version   2.6.1
    * @since     2013/02/26
    */
    FUNCTION tf_cm_diet_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes;

    /*
    * Returns a list of details diets for the crisis machine
    *
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_episode    Episode id
    * @param     i_schedule   Schedule id
    
    * @author    Jorge Silva
    * @version   2.6.1
    * @since     2013/02/26
    */
    FUNCTION tf_cm_diet_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_diet_episodes;

    FUNCTION inactivate_diet_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

END pk_diet_api_db;
/
