/*-- Last Change Revision: $Rev: 858015 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-21 19:22:46 +0000 (sex, 21 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_rehab_epis_plan IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 12:09:21
    -- Purpose : functions for table REHAB_EPIS_PLAN

    -- Public type declarations
    --TYPE <TypeName> IS <Datatype>;

    -- Public constant declarations
    --<ConstantName> CONSTANT <Datatype> := <Value>;

    -- Public variable declarations
    --<VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * insert
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
    * @since   06-12-2010
    */
    FUNCTION ins
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        id_episode_in          IN rehab_epis_plan.id_episode%TYPE DEFAULT NULL,
        flg_status_in          IN rehab_epis_plan.flg_status%TYPE DEFAULT NULL,
        id_professional_in     IN rehab_epis_plan.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_in  IN rehab_epis_plan.dt_rehab_epis_plan%TYPE DEFAULT NULL,
        dt_last_update_in      IN rehab_epis_plan.dt_last_update%TYPE DEFAULT NULL,
        id_rehab_epis_plan_out OUT rehab_epis_plan.id_rehab_epis_plan%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * update
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
    * @since   06-12-2010 12:31:31
    */
    FUNCTION upd
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        id_rehab_epis_plan_in IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        id_episode_in         IN rehab_epis_plan.id_episode%TYPE DEFAULT NULL,
        flg_status_in         IN rehab_epis_plan.flg_status%TYPE DEFAULT NULL,
        id_professional_in    IN rehab_epis_plan.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_in IN rehab_epis_plan.dt_rehab_epis_plan%TYPE DEFAULT NULL,
        dt_last_update_in     IN rehab_epis_plan.dt_last_update%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_general_info
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
    FUNCTION get_general_info
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_list_by_pat_ep
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
    FUNCTION get_list_by_pat_ep
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_epis_plan.id_episode%TYPE,
        i_id_patient IN episode.id_patient%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_plan
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
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        dt_last_update_in    IN rehab_epis_plan.dt_last_update%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_history_info
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
    FUNCTION get_history_info
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_epis_plan;
/