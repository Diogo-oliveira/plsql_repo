/*-- Last Change Revision: $Rev: 858015 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-21 19:22:46 +0000 (sex, 21 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_rehab_epis_plan_notes IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 12:13:13
    -- Purpose : funtions for table REHAB_EPIS_PLAN_NOTES

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
    * @since   06-12-2010 15:53:19
    */
    FUNCTION ins
    (
        i_lang                       IN LANGUAGE.id_language%TYPE,
        i_prof                       IN profissional,
        id_rehab_epis_plan_in        IN rehab_epis_plan_notes.id_rehab_epis_plan%TYPE DEFAULT NULL,
        flg_type_in                  IN rehab_epis_plan_notes.flg_type%TYPE DEFAULT NULL,
        notes_in                     IN rehab_epis_plan_notes.notes%TYPE DEFAULT NULL,
        id_professional_in           IN rehab_epis_plan_notes.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_notes_in  IN rehab_epis_plan_notes.dt_rehab_epis_plan_notes%TYPE DEFAULT NULL,
        id_rehab_epis_plan_notes_out OUT rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        o_error                      OUT t_error_out
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
    * @since   06-12-2010 15:59:59
    */
    FUNCTION upd
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        id_rehab_epis_plan_notes_in IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        flg_type_in                 IN rehab_epis_plan_notes.flg_type%TYPE DEFAULT NULL,
        notes_in                    IN rehab_epis_plan_notes.notes%TYPE DEFAULT NULL,
        id_professional_in          IN rehab_epis_plan_notes.id_prof_create%TYPE DEFAULT NULL,
        dt_rehab_epis_plan_notes_in IN rehab_epis_plan_notes.dt_rehab_epis_plan_notes%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
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
        i_notes_type         IN rehab_epis_plan_notes.flg_type%TYPE,
        o_notes              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
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
    * @since   15-12-2010 08:30:15
    */
    FUNCTION cancel_notes
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_rehab_epis_plan_notes  IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        dt_rehab_epis_plan_notes_in IN rehab_epis_plan_notes.dt_rehab_epis_plan_notes%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
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
    * @since   07-12-2010 17:27:25
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_notes_type         IN rehab_epis_plan_notes.flg_type%TYPE,
        o_notes              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_epis_plan_notes;
/