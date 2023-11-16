/*-- Last Change Revision: $Rev: 1777655 $*/
/*-- Last Change by: $Author: joao.sa $*/
/*-- Date of last change: $Date: 2017-03-31 10:22:14 +0100 (sex, 31 mar 2017) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_label IS

    /**
    * Returns the label value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_tag                 Tag to be replaced
    * @param o_data_rec            Tag's data  
    *
    * @return                      The value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_tag      IN header_tag.internal_name%TYPE,
        o_data_rec OUT t_rec_header_data
    ) RETURN BOOLEAN;

    /**
    * Returns the label value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_tag                 Tag to be replaced
    *
    * @return                      The value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_tag  IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_found BOOLEAN;
    g_exception EXCEPTION;
    g_hea_epis_conf CONSTANT sys_config.id_sys_config%TYPE := 'HEA_EPIS_CONF';
    g_retval BOOLEAN;

END;
/
