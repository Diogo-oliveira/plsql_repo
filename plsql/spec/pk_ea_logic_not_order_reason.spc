/*-- Last Change Revision: $Rev: 1595575 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2014-05-27 16:08:26 +0100 (ter, 27 mai 2014) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_not_order_reason IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 24-04-2014 17:39:51
    -- Purpose : Reasons not ordered easy access database package

    -- Public type declarations
    SUBTYPE t_huge_byte IS pk_types.t_huge_byte; --32767
    SUBTYPE t_big_byte IS pk_types.t_big_byte; --4000

    SUBTYPE t_big_char IS pk_types.t_big_char; --1000
    SUBTYPE t_med_char IS pk_types.t_med_char; --500
    SUBTYPE t_low_char IS pk_types.t_low_char; --100
    SUBTYPE t_flg_char IS pk_types.t_flg_char; --1

    SUBTYPE t_low_num IS pk_types.t_low_num; --NUMBER(06);
    SUBTYPE t_med_num IS pk_types.t_med_num; --NUMBER(12);
    SUBTYPE t_big_num IS pk_types.t_big_num; --NUMBER(24);

    -- Public constant declarations
    k_yes                CONSTANT t_low_char := 'Y';
    k_no                 CONSTANT t_low_char := 'N';
    k_pref_term_str      CONSTANT t_low_char := 'PREFERRED_TERM';
    k_category_minus_one CONSTANT t_low_num := -1;
    k_lang               CONSTANT t_low_num := 2;
    k_task_type_list     CONSTANT table_number := table_number(42, 43, 44, 12, 50, 27, 88, 89);
    -- 42 - Patient Education, 43 - Procedures, 44 - Dressings - wound treatment, 12 - Medication, 50 - Rehabilitation, 27 - Surgical procedures, 88 - Vaccine, 89 - Vaccine dose
    k_concept_type_list CONSTANT table_varchar := table_varchar('CLINICAL_INTERVENTION_NOT_ORDERED');

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Function to return concept types ids for reasons not ordered
    *
    * @return  concept types ids list
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.6.4
    * @since   28-04-2014
    */
    FUNCTION get_concept_type_list_ids RETURN table_number;

    /**
    * Procedure to populate EA table
    *
    * @param   i_inst institution indentifier (0 - populates all)
    *
    * @author  CRISTINA.OLIVEIRA
    * @version 2.6.4
    * @since   24-04-2014
    */
    PROCEDURE populate_ea(i_inst IN institution.id_institution%TYPE);
END pk_ea_logic_not_order_reason;
/
