/*-- Last Change Revision: $Rev: 865341 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-28 17:24:35 +0000 (sex, 28 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_rehab_plan IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 19:12:20
    -- Purpose : functions for Rehabilitation Plan

    -- Public type declarations
    --TYPE <TypeName> IS <Datatype>;

    -- Public constant declarations
    --<ConstantName> CONSTANT <Datatype> := <Value>;

    -- Public variable declarations
    --<VariableName> <Datatype>;

    -- Public function and procedure declarations

    /**
    * get_rehab_menu_plans
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
    * @since   06-12-2010 19:14:35
    */
    FUNCTION get_rehab_menu_plans
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_prof_by_cat
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
    * @since   06-12-2010 19:18:44
    */
    FUNCTION get_prof_by_cat
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_category IN category.id_category%TYPE DEFAULT NULL,
        o_curs        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_team
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
    * @since   06-12-2010 19:22:18
    */
    FUNCTION get_team
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
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
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_epis_plan.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_team       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * set_plan_areas
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
    * @since   07-12-2010 11:18:28
    */
    FUNCTION set_plan_areas
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        I_NOTES                    in TABLE_VARCHAR,
        i_current_timestamp        in TIMESTAMP WITH LOCAL TIME ZONE default current_timestamp,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * set_general_info
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
    * @since   07-12-2010 15:06:12
    */
    FUNCTION set_general_info
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        i_id_prof_cat        IN table_number,
        I_CREAT_DATE         in varchar2,
        i_current_timestamp  in TIMESTAMP WITH LOCAL TIME ZONE default current_timestamp,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_all_plan
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION get_all_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_obj_profs          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_gen_prof_info
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
    FUNCTION get_gen_prof_info
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_team               OUT pk_types.cursor_type,
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
        o_teams      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_domains
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
    * @since   14-12-2010 12:12:32
    */
    FUNCTION get_domains
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        o_domain      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
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
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_area
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
    FUNCTION cancel_area
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area IN rehab_epis_plan_area.id_rehab_plan_area%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_objective
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
    FUNCTION cancel_objective
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_notes
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
    FUNCTION cancel_notes
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan_notes IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_all_hist_plan
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
    * @since   07-12-2010 17:23:09
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_gen_info           OUT pk_types.cursor_type,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) return BOOLEAN;
    
    /**
    * set_plan_info
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
    * @since   07-12-2010 17:23:09
    */
     FUNCTION set_plan_info
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        I_PROF                     in PROFISSIONAL,
        I_ID_REHAB_EPIS_PLAN       in REHAB_EPIS_PLAN.ID_REHAB_EPIS_PLAN%type,
        I_ID_PROF_CAT_pl           in TABLE_NUMBER,
        I_ID_EPISODE               in REHAB_EPIS_PLAN.ID_EPISODE%type,
				i_creat_date               IN VARCHAR2,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        O_ERROR                    OUT T_ERROR_OUT
    ) RETURN BOOLEAN;
    

END pk_rehab_plan;
/