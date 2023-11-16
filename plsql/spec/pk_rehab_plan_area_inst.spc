/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_rehab_plan_area_inst IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 17:37:54
    -- Purpose : funtions for table REHAB_PLAN_AREA_INST

    -- Public type declarations
    --TYPE < typename > IS < datatype >;

    -- Public constant declarations
    --< constantname > CONSTANT < datatype > := < VALUE >;

    -- Public variable declarations
    --< variablename > < datatype >;

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
    * @since   06-12-2010 17:38:26
    */
    FUNCTION get_rehab_menu_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_plan_area_inst;
/
