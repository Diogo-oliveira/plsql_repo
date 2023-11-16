/*-- Last Change Revision: $Rev: 858015 $*/
/*-- Last Change by: $Author: filipe.sousa $*/
/*-- Date of last change: $Date: 2011-01-21 19:22:46 +0000 (sex, 21 jan 2011) $*/

CREATE OR REPLACE PACKAGE pk_rehab_plan_team IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-12-2010 17:07:39
    -- Purpose : funtions for table REHAB_PLAN_TEAM

    -- Public type declarations
    --TYPE < typename > IS < datatype >;

    -- Public constant declarations
    --< constantname > CONSTANT < datatype > := < VALUE >;

    -- Public variable declarations
    --< variablename > < datatype >;

    -- Public function and procedure declarations
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
    * @since   06-12-2010 17:08:15
    */

    FUNCTION get_prof_by_cat
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_category IN category.id_category%TYPE DEFAULT NULL,
        o_curs        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_plan_team;
/