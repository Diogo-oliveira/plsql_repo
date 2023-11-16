/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE pk_api_unit_measure IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

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

    FUNCTION intf_get_unit_mea_conversion
    (
        i_value         IN vital_sign_read.VALUE%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER;

    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';
    g_owner   VARCHAR2(100);
    g_package VARCHAR2(100);
END pk_api_unit_measure;
/
