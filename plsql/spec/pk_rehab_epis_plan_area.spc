/*-- Last Change Revision: $Rev: 858015 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-21 19:22:46 +0000 (sex, 21 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_rehab_epis_plan_area IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 12:11:21
    -- Purpose : funtions for table REHAB_EPIS_PLAN_AREA

    -- Public type declarations

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
    * @since   06-12-2010 15:05:15
    */
    FUNCTION ins
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        id_rehab_epis_plan_in       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE DEFAULT NULL,
        id_rehab_plan_area_in       IN rehab_epis_plan_area.id_rehab_plan_area%TYPE DEFAULT NULL,
        current_situation_in        IN rehab_epis_plan_area.current_situation%TYPE DEFAULT NULL,
        goals_in                    IN rehab_epis_plan_area.goals%TYPE DEFAULT NULL,
        methodology_in              IN rehab_epis_plan_area.methodology%TYPE DEFAULT NULL,
        time_in                     IN rehab_epis_plan_area.TIME%TYPE DEFAULT NULL,
        flg_time_unit_in            IN rehab_epis_plan_area.flg_time_unit%TYPE DEFAULT NULL,
        id_professional_in          IN rehab_epis_plan_area.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_area_in  IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
        id_rehab_epis_plan_area_out OUT rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        o_error                     OUT t_error_out
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
    * @since   06-12-2010 15:05:32
    */
    FUNCTION upd
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        id_rehab_epis_plan_area_in IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        current_situation_in       IN rehab_epis_plan_area.current_situation%TYPE DEFAULT NULL,
        goals_in                   IN rehab_epis_plan_area.goals%TYPE DEFAULT NULL,
        methodology_in             IN rehab_epis_plan_area.methodology%TYPE DEFAULT NULL,
        time_in                    IN rehab_epis_plan_area.TIME%TYPE DEFAULT NULL,
        flg_time_unit_in           IN rehab_epis_plan_area.flg_time_unit%TYPE DEFAULT NULL,
        id_professional_in         IN rehab_epis_plan_area.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_area_in IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
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
    * @since   15-12-2010 08:30:15
    */
    FUNCTION cancel_area
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area       IN rehab_epis_plan_area.id_rehab_plan_area%TYPE,
        dt_rehab_epis_plan_area_in IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
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
    * @since   15-12-2010 09:38:37
    */
    FUNCTION cancel_objective
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan_area  IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        dt_rehab_epis_plan_area_in IN rehab_epis_plan_area.dt_rehab_epis_plan_area%TYPE DEFAULT NULL,
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_epis_plan_area;
/