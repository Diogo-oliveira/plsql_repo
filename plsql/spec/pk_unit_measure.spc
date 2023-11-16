/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_unit_measure IS

    --ID unit measure
    g_um_kilogram CONSTANT VARCHAR2(2 CHAR) := 10;

    g_error         VARCHAR2(32767);
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /**
    * This function returns true if the two units are convertible
    *
    * @param i_unit_meas           Unit measure to convert.
    * @param i_unit_meas_def       Default unit measure
    *
    * @author   Fábio Oliveira
    * @version  1.0
    * @since    2009/11/05
    */
    FUNCTION are_convertible
    (
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN;

    /**
    * This function returns 0 if the two units aren't convertible
    * or 1 if are convertible from i_unit_meas to i_unit_meas_def
    * or 2 if at least they are convertible from i_unit_meas_def to i_unit_meas
    *
    * @param i_unit_meas           Unit measure to convert.
    * @param i_unit_meas_def       Default unit measure
    *
    * @return number
    *
    * @author   Vitor Reis
    * @version  2.6.5.0
    * @since    08/05/2015
    */
    FUNCTION get_conversion_direction
    (
        i_unit_meas_1 IN unit_measure.id_unit_measure%TYPE,
        i_unit_meas_2 IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER;

    /**
    * This function returns the conversion value between diferent measure units
    *
    * @param i_value               Value to convert.
    * @param i_unit_meas           Unit measure to convert.
    * @param i_unit_meas_def       Default unit measure
    *
    * @author   Emilia Taborda
    * @version  1.0
    * @since    2006/08/24
    */

    FUNCTION get_unit_mea_conversion
    (
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the Unit of Measure abbreviation
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_unit_measure              Unit of measure ID
    * @return                            Unit of measure abbreviation
    *
    * @author  ARIEL.MACHADO
    * @version 2.5
    * @since   25-Jun-09
    **********************************************************************************************/
    FUNCTION get_uom_abbreviation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the unit measure description
    *
    * @param    i_lang              Preferred language ID
    * @param    i_prof              Object (ID of professional, ID of institution, ID of software)
    * @param    i_unit_measure      Unit measure ID
    *
    * @return   varchar2            Unit of measure abbreviation
    *
    * @author  Tiago Silva
    * @since   02/07/2010
    **********************************************************************************************/
    FUNCTION get_unit_measure_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns info about all the available units of measurement
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_unit_measure_type         Unit of Measures types
    * @param o_unit_measure_subtype      Unit of Measures subtypes
    * @param o_unit_measure              Unit of Measures info
    
    * @param o_error                     Error message
    
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5
    * @since   26-Jun-09
    **********************************************************************************************/
    FUNCTION get_all_unit_measures
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_unit_measure_type    OUT pk_types.cursor_type,
        o_unit_measure_subtype OUT pk_types.cursor_type,
        o_unit_measure         OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options given the unit measure id
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_unit_measure   Unit measure id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/28
    */

    FUNCTION get_unit_measure
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    -- CMF 
    /*
        FUNCTION get_dyn_um_main
        (
            i_lang                 IN NUMBER,
            i_prof                 IN profissional,
            i_ds_component         IN NUMBER,
            i_unit_measure         IN NUMBER,
            i_unit_measure_subtype IN NUMBER
        ) RETURN t_tbl_dyn_umea;
    */
    FUNCTION get_dyn_only_umea
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN t_tbl_dyn_umea;

    FUNCTION get_dyn_only_umea_type
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_ds_component         IN NUMBER,
        i_unit_measure_subtype IN NUMBER
    ) RETURN t_tbl_dyn_umea;

    FUNCTION get_umea_type_ds
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_unit_measure_subtype IN NUMBER,
        i_unit_measure         IN NUMBER,
        o_list                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_unit_mea_conversion
    (
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE,
        i_decimals      IN NUMBER
    ) RETURN NUMBER;

    FUNCTION tf_get_unit_measure_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_area IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_unit_measure_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_area  IN VARCHAR2,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

END pk_unit_measure;
/
