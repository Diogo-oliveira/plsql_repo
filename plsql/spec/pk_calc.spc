/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_calc IS

    /**
    * Gets the calculator Id for the calculator name given as input
    *
    * @param i_prof          The professional record.
    * @param i_calc_name     The calculator name
    *
    * @return  The calculator Id.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculator_id
    (
        i_prof      IN profissional,
        i_calc_name IN calculator.internal_name%TYPE
    ) RETURN NUMBER;

    /**
    * Gets the parameters for the calculator given as input
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_calc_name     The calculator name
    *
    * @param o_cursor        The list of parameters of the calc.
    *
    * @param o_error         Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calc_details
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_calc_name IN calculator.internal_name%TYPE,
        o_cursor    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates the results using the fields and the unit measures given as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_id_calculator   The calculator Id
    * @param i_id_fields_in    The list of input field Ids for the calculator
    * @param i_id_fields_out   The list of output field Ids for the calculator
    * @param i_id_unit_mea_in  The list of input unit measure Ids for the calculator
    * @param i_id_unit_mea_out The list of output unit measure Ids for the calculator
    * @param i_values          The values of the input fields to be calculated
    *
    * @param o_results         The list of values given as result of the calculation.
    *
    * @param o_error           Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_calculator   IN calculator.id_calculator%TYPE,
        i_id_fields_in    IN table_number,
        i_id_fields_out   IN table_number,
        i_id_unit_mea_in  IN table_number,
        i_id_unit_mea_out IN table_number,
        i_format_out      IN table_varchar,
        i_values          IN table_varchar,
        o_results         OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates the results using the fields and the unit measures given as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_id_calculator   The calculator Id
    * @param i_id_fields_in    The list of input field Ids for the calculator
    * @param i_id_fields_out   The list of output field Ids for the calculator
    * @param i_id_unit_mea_in  The list of input unit measure Ids for the calculator
    * @param i_id_unit_mea_out The list of output unit measure Ids for the calculator
    * @param i_format_out      The list of formats to be applied to the output results
    * @param i_values          The values of the input fields to be calculated
    *
    * @return  The list of values given as result of the calculation.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_calculator   IN calculator.id_calculator%TYPE,
        i_id_fields_in    IN table_number,
        i_id_fields_out   IN table_number,
        i_id_unit_mea_in  IN table_number,
        i_id_unit_mea_out IN table_number,
        i_format_out      IN table_varchar,
        i_values          IN table_varchar
    ) RETURN table_varchar;

    /**
    * Calculates the results using the fields and the unit measures given as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_id_calculator   The calculator Id
    * @param i_id_fields_in    The list of input field Ids for the calculator
    * @param i_id_field_out    The output field Id for the calculator
    * @param i_id_unit_mea_in  The list of input unit measure Ids for the calculator
    * @param i_id_unit_mea_out The list of output unit measure Ids for the calculator
    * @param i_format_out      The list of formats to be applied to the output results
    * @param i_values          The values of the input fields to be calculated
    *
    * @return  The list of values given as result of the calculation.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2008/03/02
    */
    FUNCTION get_calculation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_calculator   IN calculator.id_calculator%TYPE,
        i_id_fields_in    IN table_number,
        i_id_field_out    IN calc_field.id_calc_field%TYPE,
        i_id_unit_mea_in  IN table_number,
        i_id_unit_mea_out IN NUMBER,
        i_format_out      IN calc_field_soft_inst.format%TYPE,
        i_values          IN table_varchar
    ) RETURN VARCHAR;

    /************************************************************************************************************
    * Calculates the Body Mass Index (BMI) given the weight and the height as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_weight          The weight
    * @param i_weight_um       The unit measure assigned to the weight
    * @param i_height          The height
    * @param i_height_um       The unit measure assigned to the height
    *
    * @return                  Returns BMI value.
    * 
    * @author                  Luís Maia
    * @version                 2.6.1
    * @since                   02-Jan-2012
    ************************************************************************************************************/
    FUNCTION get_bmi
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weight    IN VARCHAR2,
        i_weight_um IN unit_measure.id_unit_measure%TYPE,
        i_height    IN VARCHAR2,
        i_height_um IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR;

    /************************************************************************************************************
    * Calculates the Body Surface Area (BSA) given the weight and the height as parameters.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            The professional record.
    * @param i_weight          The weight
    * @param i_weight_um       The unit measure assigned to the weight
    * @param i_height          The height
    * @param i_height_um       The unit measure assigned to the height
    *
    * @return                  Returns BSA value.
    * 
    * @author                  Luís Maia
    * @version                 2.6.1
    * @since                   02-Jan-2012
    ************************************************************************************************************/
    FUNCTION get_bsa
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weight    IN VARCHAR2,
        i_weight_um IN unit_measure.id_unit_measure%TYPE,
        i_height    IN VARCHAR2,
        i_height_um IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR;

    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_lst_imc                Last active values of Weight and Height Vital Signs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @since                          29-Set-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_imc_values
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN vital_signs_ea.id_patient%TYPE,
        o_lst_imc OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    /* Stores the BMI calculator name. */
    g_calc_name_bmi CONSTANT VARCHAR2(32) := 'BMI';
    g_calc_name_bsa CONSTANT VARCHAR2(32) := 'BSA';

    g_fmt_str     CONSTANT VARCHAR2(32) := '999999990D999999999';
    g_fmt_num     CONSTANT VARCHAR2(32) := '999999999.999999999';
    g_nls         CONSTANT VARCHAR2(32) := 'NLS_NUMERIC_CHARACTERS=''. ''';
    g_default_fmt CONSTANT VARCHAR2(32) := '990.99';

    g_found BOOLEAN;
    g_exception EXCEPTION;

END pk_calc;
/
