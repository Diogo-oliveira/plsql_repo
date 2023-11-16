/*-- Last Change Revision: $Rev: 1965628 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2020-10-09 09:22:44 +0100 (sex, 09 out 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_json_utils IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION to_json_list(i_table_number IN table_number) RETURN json_array_t IS
        l_json_lst json_array_t;
    BEGIN
        l_json_lst := json_array_t();
        IF i_table_number IS NOT empty
        THEN
            FOR i IN 1 .. i_table_number.count()
            LOOP
                l_json_lst.append(i_table_number(i));
            END LOOP;
        END IF;
        RETURN l_json_lst;
    END to_json_list;

    FUNCTION to_json_list(i_table_varchar IN table_varchar) RETURN json_array_t IS
        l_json_lst json_array_t;
    BEGIN
        l_json_lst := json_array_t();
        IF i_table_varchar IS NOT empty
        THEN
            FOR i IN 1 .. i_table_varchar.count()
            LOOP
                l_json_lst.append(i_table_varchar(i));
            END LOOP;
        END IF;
        RETURN l_json_lst;
    END to_json_list;

    FUNCTION to_json_list(i_table_table_number IN table_table_number) RETURN json_array_t IS
        l_json_lst json_array_t;
    BEGIN
        l_json_lst := json_array_t();
        IF i_table_table_number IS NOT empty
        THEN
            FOR i IN 1 .. i_table_table_number.count()
            LOOP
                l_json_lst.append(to_json_list(i_table_table_number(i)));
            END LOOP;
        END IF;
        RETURN l_json_lst;
    END to_json_list;

    FUNCTION to_json_list(i_table_table_varchar IN table_table_varchar) RETURN json_array_t IS
        l_json_lst json_array_t;
    BEGIN
        l_json_lst := json_array_t();
        IF i_table_table_varchar IS NOT empty
        THEN
            FOR i IN 1 .. i_table_table_varchar.count()
            LOOP
                l_json_lst.append(to_json_list(i_table_table_varchar(i)));
            END LOOP;
        END IF;
        RETURN l_json_lst;
    END to_json_list;

    FUNCTION get_table_number
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_number IS
        l_json_array_t json_array_t;
        l_lst_number   table_number;
        l_e            json_element_t;
    BEGIN
        IF i_obj IS NOT NULL
        THEN
            l_json_array_t := json_array_t.parse(i_obj.get(i_pair_name).to_string);
        
            IF l_json_array_t IS NOT NULL
            THEN
                l_lst_number := table_number();
                FOR i IN 1 .. l_json_array_t.get_size()
                LOOP
                    l_lst_number.extend(1);
                    l_lst_number(i) := l_json_array_t.get_number(i);
                END LOOP;
            END IF;
        END IF;
        RETURN l_lst_number;
    END get_table_number;

    FUNCTION get_table_varchar
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_varchar IS
        l_json_array_t json_array_t;
        l_lst_varchar  table_varchar;
    BEGIN
        IF i_obj IS NOT NULL
        THEN
            l_json_array_t := json_array_t.parse(i_obj.get(i_pair_name).to_string);
            IF l_json_array_t IS NOT NULL
            THEN
                l_lst_varchar := table_varchar();
                FOR i IN 1 .. l_json_array_t.get_size
                LOOP
                    l_lst_varchar.extend(1);
                    l_lst_varchar(i) := l_json_array_t.get_string(i);
                END LOOP;
            END IF;
        
        END IF;
        RETURN l_lst_varchar;
    END get_table_varchar;

    FUNCTION get_table_table_number
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_table_number IS
        l_lst_lst_number table_table_number;
        l_json_array_t   json_array_t;
        l_json           json_object_t;
        k_inner_pair_name CONSTANT pk_types.t_internal_name_byte := 'row';
    BEGIN
        /*IF i_obj IS NOT NULL
        THEN
            l_json_array_t := json_ext.get_json_array_t(i_obj, i_pair_name);
            IF l_json_array_t IS NOT NULL
            THEN
                l_lst_lst_number := table_table_number();
                FOR i IN 1 .. l_json_array_t.count
                LOOP
                    l_json := json();
                    l_json.put(k_inner_pair_name, l_json_array_t.get(i));
                
                    l_lst_lst_number.extend(1);
                    l_lst_lst_number(i) := get_table_number(i_obj => l_json, i_pair_name => k_inner_pair_name);
                END LOOP;
            END IF;
        END IF;*/
        RETURN l_lst_lst_number;
    END get_table_table_number;

    FUNCTION get_table_table_varchar
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_table_varchar IS
        l_lst_lst_varchar table_table_varchar;
        l_json            json_object_t;
        l_json_array_t    json_array_t;
        k_inner_pair_name CONSTANT pk_types.t_internal_name_byte := 'row';
    BEGIN
        /*IF i_obj IS NOT NULL
        THEN
            l_json_array_t := json_ext.get_json_array_t(i_obj, i_pair_name);
            IF l_json_array_t IS NOT NULL
            THEN
                l_lst_lst_varchar := table_table_varchar();
                FOR i IN 1 .. l_json_array_t.count
                LOOP
                    l_json := json();
                    l_json.put(k_inner_pair_name, l_json_array_t.get(i));
                
                    l_lst_lst_varchar.extend(1);
                    l_lst_lst_varchar(i) := get_table_varchar(i_obj => l_json, i_pair_name => k_inner_pair_name);
                END LOOP;
            END IF;
        END IF;*/
        RETURN l_lst_lst_varchar;
    END get_table_table_varchar;

    FUNCTION get_clob
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN CLOB IS
        l_temp json_element_t;
        l_clob CLOB;
    BEGIN
        IF i_obj IS NOT NULL
        THEN
            l_temp := i_obj.get(i_pair_name);
            IF (l_temp IS NULL OR NOT l_temp.is_string)
            THEN
                l_clob := NULL;
            ELSE
                dbms_lob.createtemporary(lob_loc => l_clob, cache => TRUE);
                l_temp.to_clob(l_clob);
            END IF;
        END IF;
        RETURN l_clob;
    END get_clob;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_json_utils;
/
