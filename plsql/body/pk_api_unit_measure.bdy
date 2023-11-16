/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_unit_measure IS

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
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_unit_measure.get_unit_mea_conversion(i_value         => i_value,
                                                       i_unit_meas     => i_unit_meas,
                                                       i_unit_meas_def => i_unit_meas_def);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
    END error_handling;

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION error_handling
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alert_exceptions.process_error(i_lang,
                                          SQLCODE,
                                          SQLERRM,
                                          g_error,
                                          g_owner,
                                          g_package,
                                          'ERROR_HANDLING',
                                          o_error);
        RETURN FALSE;
    END error_handling;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    pk_alertlog.who_am_i(g_owner, g_package);

    pk_alertlog.who_am_i(g_owner, g_package);

    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_api_unit_measure;
/
