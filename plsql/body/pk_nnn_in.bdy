/*-- Last Change Revision: $Rev: 1658139 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:24:35 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_nnn_in IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION get_terminology_information(i_terminology_version IN terminology_version.id_terminology_version%TYPE)
        RETURN t_terminology_info_rec IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_terminology_information';
        l_terminology_info t_terminology_info_rec;
    BEGIN
        g_error := 'Call PK_API_TERMIN_SERVER_FUNC.GET_TERMINOLOGY_INFORMATION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_terminology_info := pk_api_termin_server_func.get_terminology_information(i_terminology_version => i_terminology_version);
    
        RETURN l_terminology_info;
    END get_terminology_information;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nnn_in;
/
