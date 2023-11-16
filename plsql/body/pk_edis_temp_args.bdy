/*-- Last Change Revision: $Rev: 2027090 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_temp_args IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    PROCEDURE clean_table(i_namespace IN VARCHAR2) IS
    BEGIN
        DELETE FROM v_edis_temp_args e
         WHERE e.namespace = i_namespace;
    
        COMMIT;
    END clean_table;

    PROCEDURE reset_namespace(i_namespace IN VARCHAR2) IS
        l_func_name CONSTANT VARCHAR2(200) := 'RESET_NAMESPACE';
    BEGIN
        g_error := 'EMPTY ARGS OF NAMESPACE: ' || i_namespace;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        DELETE FROM v_edis_temp_args e
         WHERE e.namespace = i_namespace;
    END reset_namespace;

    FUNCTION is_namespace_already_init(i_namespace IN VARCHAR2) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM v_edis_temp_args e
         WHERE e.namespace = i_namespace;
    
        RETURN(l_count > 0);
    END is_namespace_already_init;

    PROCEDURE reset_attribute
    (
        i_namespace IN VARCHAR2,
        i_attribute IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(200) := 'RESET_ATTRIBUTE';
    BEGIN
        g_error := 'EMPTY ARGS OF NAMESPACE: ' || i_namespace || '; ATTRIBUTE: ' || i_attribute;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        DELETE FROM v_edis_temp_args e
         WHERE e.namespace = i_namespace
           AND e.attribute = i_attribute;
    END reset_attribute;

    PROCEDURE add_argument
    (
        i_namespace       IN VARCHAR2,
        i_attribute       IN VARCHAR2,
        i_value           IN VARCHAR2,
        i_reset_attribute IN BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name CONSTANT VARCHAR2(200) := 'ADD_ARGUMENT';
    BEGIN
        IF i_reset_attribute
        THEN
            g_error := 'CALL RESET_ATTRIBUTE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            reset_attribute(i_namespace => i_namespace, i_attribute => i_attribute);
        END IF;
    
        g_error := 'ADD ATTRIBUTE - NAMESPACE: ' || i_namespace || ' ; ATTRIBUTE: ' || i_attribute || '; VALUE: ' ||
                   i_value;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        INSERT INTO v_edis_temp_args
            (namespace, attribute, attr_value)
        VALUES
            (i_namespace, i_attribute, i_value);
    END add_argument;

    PROCEDURE add_argument
    (
        i_namespace       IN VARCHAR2,
        i_attribute       IN VARCHAR2,
        i_value           IN table_varchar,
        i_reset_attribute IN BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name CONSTANT VARCHAR2(200) := 'ADD_ARGUMENT';
    BEGIN
        IF i_reset_attribute
        THEN
            g_error := 'CALL RESET_ATTRIBUTE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            reset_attribute(i_namespace => i_namespace, i_attribute => i_attribute);
        END IF;
    
        g_error := 'ADD ATTRIBUTE - NAMESPACE: ' || i_namespace || ' ; ATTRIBUTE: ' || i_attribute;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        INSERT INTO v_edis_temp_args
            SELECT /*+ DYNAMIC_SAMPLING(t 1) */
             i_namespace namespace, i_attribute attribute, column_value attr_value
              FROM TABLE(i_value) t;
    END add_argument;

    PROCEDURE add_argument
    (
        i_namespace       IN VARCHAR2,
        i_attribute       IN VARCHAR2,
        i_value           IN table_number,
        i_reset_attribute IN BOOLEAN DEFAULT TRUE
    ) IS
        l_func_name CONSTANT VARCHAR2(200) := 'ADD_ARGUMENT';
    BEGIN
        IF i_reset_attribute
        THEN
            g_error := 'CALL RESET_ATTRIBUTE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            reset_attribute(i_namespace => i_namespace, i_attribute => i_attribute);
        END IF;
    
        g_error := 'ADD ATTRIBUTE - NAMESPACE: ' || i_namespace || ' ; ATTRIBUTE: ' || i_attribute;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        INSERT INTO v_edis_temp_args
            SELECT /*+ DYNAMIC_SAMPLING(t 1) */
             i_namespace namespace, i_attribute attribute, column_value attr_value
              FROM TABLE(i_value) t;
    END add_argument;

    FUNCTION get_argument
    (
        i_namespace IN VARCHAR2,
        i_attribute IN VARCHAR2
    ) RETURN v_edis_temp_args.attr_value%TYPE IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_ARGUMENT';
        --
        l_ret v_edis_temp_args.attr_value%TYPE;
    BEGIN
        g_error := 'GET ATTRIBUTE - NAMESPACE: ' || i_namespace || ' ; ATTRIBUTE: ' || i_attribute;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT e.attr_value
          INTO l_ret
          FROM v_edis_temp_args e
         WHERE e.namespace = i_namespace
           AND e.attribute = i_attribute;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN too_many_rows THEN
            RETURN NULL;
    END get_argument;

    FUNCTION get_arguments
    (
        i_namespace IN VARCHAR2,
        i_attribute IN VARCHAR2
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_ARGUMENTS';
        --
        l_ret table_varchar;
    BEGIN
        g_error := 'GET ATTRIBUTES - NAMESPACE: ' || i_namespace || ' ; ATTRIBUTE: ' || i_attribute;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT e.attr_value BULK COLLECT
          INTO l_ret
          FROM v_edis_temp_args e
         WHERE e.namespace = i_namespace
           AND e.attribute = i_attribute;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN table_varchar();
    END get_arguments;
BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_edis_temp_args;
/
