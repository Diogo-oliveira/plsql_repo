/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_area_key_nextval IS

    /**
    * Returns and updated the next value for the area and key given as parameters.
    * If the parameter min_value is greater than the stored value returns min_value + 1
    *
    * @param i_area The area for the sequence.
    * @param i_area The key for the sequence.
    * @param i_min_val The min value this function will return.
    *
    * @return  The next value.
    *
    * @author   Eduardo Lourenço
    * @version  2.5
    * @since    2009/03/28
    */
    FUNCTION get_next_value
    (
        i_area    IN area_key_nextval.area%TYPE,
        i_key     IN NUMBER,
        i_min_val IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(64) := 'GET_NEXT_VALUE';
        l_number    NUMBER;
        l_exist     BOOLEAN := TRUE;
    BEGIN
        g_error := 'get_next_value(' || i_area || ', ' || i_key || ')';
        pk_alertlog.log_debug(g_error);
    
        BEGIN
            g_error := 'select into l_number from area_key_nextval';
            pk_alertlog.log_debug(g_error);
            SELECT cur_value + 1
              INTO l_number
              FROM area_key_nextval aknv
             WHERE aknv.area = i_area
               AND aknv.key = i_key
               FOR UPDATE;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'key ' || i_key || ' for area ' || i_area || ' does not exist';
                pk_alertlog.log_debug(g_error);
                l_exist  := FALSE;
                l_number := 1;
        END;
        IF i_min_val >= l_number
        THEN
            l_number := i_min_val + 1;
        END IF;
        IF l_exist
        THEN
            g_error := 'UPDATE area_key_nextval';
            pk_alertlog.log_debug(g_error);
            ts_area_key_nextval.upd(area_in => i_area, key_in => i_key, cur_value_in => l_number);
        ELSE
            g_error := 'INSERT INTO area_key_nextval';
            ts_area_key_nextval.ins(area_in => i_area, key_in => i_key, cur_value_in => l_number);
        END IF;
        RETURN l_number;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;

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
    FUNCTION get_next_account_number(i_id_institution IN institution.id_institution%TYPE) RETURN NUMBER IS
        l_func_name   VARCHAR2(64) := 'GET_NEXT_ACCOUNT_NUMBER';
        l_min_val     NUMBER := NULL;
        l_min_val_str sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config(g_sys_config_account_num_min,
                                                                                 profissional(0, i_id_institution, 0));
    BEGIN
        g_error := 'get_next_account_number(' || i_id_institution || ')';
        pk_alertlog.log_debug(g_error);
        IF l_min_val_str IS NOT NULL
        THEN
            l_min_val := to_number(l_min_val_str);
        END IF;
        RETURN get_next_value(g_area_key_nextval_account, i_id_institution, l_min_val);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_area_key_nextval;
/
