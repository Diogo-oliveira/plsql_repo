/*-- Last Change Revision: $Rev: 858015 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-21 19:22:46 +0000 (sex, 21 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_rehab_epis_plan_area_team IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 12:12:18
    -- Purpose : functions for table REHAB_EPIS_PLAN_AREA_TEAM

    -- Public type declarations
    --TYPE < typename > IS < datatype >;

    -- Public constant declarations
    --< constantname > CONSTANT < datatype > := < VALUE >;

    -- Public variable declarations
    --< variablename > < datatype >;

    -- Public function and procedure declarations

    /**
    * INS
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 15:29:14
    */
    FUNCTION ins
    (
        i_lang                         IN LANGUAGE.id_language%TYPE,
        i_prof                         IN profissional,
        id_rehab_epis_plan_area_in     IN rehab_ep_pl_ar_team.id_rehab_epis_plan_area%TYPE DEFAULT NULL,
        id_prof_cat_in                 IN rehab_ep_pl_ar_team.id_prof_cat%TYPE DEFAULT NULL,
        id_professional_in             IN rehab_ep_pl_ar_team.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_team_in     IN rehab_ep_pl_ar_team.dt_rehab_epis_plan_team%TYPE DEFAULT NULL,
        id_rehab_epis_plan_area_team_i IN rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * UPD
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 15:29:49
    */
    FUNCTION upd
    (
        i_lang                         IN LANGUAGE.id_language%TYPE,
        i_prof                         IN profissional,
        id_rehab_epis_plan_area_team_i IN rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE,
        id_prof_cat_in                 IN rehab_ep_pl_ar_team.id_prof_cat%TYPE DEFAULT NULL,
        id_professional_in             IN rehab_ep_pl_ar_team.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_team_in     IN rehab_ep_pl_ar_team.dt_rehab_epis_plan_team%TYPE DEFAULT NULL,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * update_plan_area
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 14:30:13
    */
    FUNCTION update_plan_area
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_ep_pl_ar_team.id_rehab_epis_plan_area%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN rehab_ep_pl_ar_team.id_rehab_ep_pl_ar_team%TYPE;

    /**
    * get_hist_list_string
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_hist_list_string
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_ep_pl_ar_team.id_rehab_epis_plan_area%TYPE,
        i_dt_rehab_epis_plan_team IN rehab_ep_pl_ar_team.dt_rehab_epis_plan_team%TYPE
    ) RETURN VARCHAR2;

    /**
    * get_all_profs
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_all_profs
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_obj_profs          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_epis_plan_area_team;
/