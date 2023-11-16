/*-- Last Change Revision: $Rev: 2028922 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_rehab_external_api_db IS

    FUNCTION get_rehab_list_to_be_scheduled
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * gets all rehab episodes for a specific time interval elegible in        *
    * crisis machine generation                                               *
    *                                                                         *
    * @param  i_lang                preferred language id                     *
    * @param  i_prof                Professional struture                     *
    * @param  i_dt_begin            Begin date interval                       *
    * @param  i_dt_end              End date interval                         *
    *                                                                         *
    * @return t_tbl_cm_episodes     collection                                *
    *                                                                         *
    * @author                       Gustavo Serrano                           *
    * @version                      v2.6.1                                    *
    * @since                        2012/05/21                                *
    **************************************************************************/
    FUNCTION tf_cm_rehab_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes;

    /**************************************************************************
    * gets all rehab episodes for a specific time interval elegible in        *
    * crisis machine generation                                               *
    *                                                                         *
    * @param  i_lang                preferred language id                     *
    * @param  i_prof                Professional struture                     *
    * @param  i_episode             Episode identifier                        *
    *                                                                         *
    * @return t_tbl_rehab_episodes  collection                                *
    *                                                                         *
    * @author                       Gustavo Serrano                           *
    * @version                      v2.6.1                                    *
    * @since                        2012/05/21                                *
    **************************************************************************/
    FUNCTION tf_cm_rehab_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_rehab_episodes;

    FUNCTION inactivate_rehab_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    -- para viewer
    FUNCTION get_ordered_list
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN NUMBER,
        i_episode      IN NUMBER,
        i_viewer_area  IN VARCHAR2,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

END pk_rehab_external_api_db;
/
