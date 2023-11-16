/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE pk_area_key_nextval IS

    /**
    * Returns the next account number for the institution given as parameter.
    *
    * @param i_id_institution Institution Id.
    *
    * @return  The next account number.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2009/03/28
    */
    FUNCTION get_next_account_number(i_id_institution IN institution.id_institution%TYPE) RETURN NUMBER;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;
    g_area_key_nextval_account   CONSTANT area_key_nextval.area%TYPE := 'ACCOUNT_NUMBER';
    g_sys_config_account_num_min CONSTANT area_key_nextval.area%TYPE := 'ACCOUNT_NUMBER_MIN_VALUE';

END pk_area_key_nextval;
/
