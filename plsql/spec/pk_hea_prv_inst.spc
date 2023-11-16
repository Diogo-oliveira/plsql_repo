/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_inst IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var;

    /**
    * Returns the institution name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_institution       Institution Id
    *
    * @return                       The institution value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the institution acronym.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_institution       Institution Id
    *
    * @return                       The institution value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_acronym
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the institution value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_institution       Institution Id
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data
    *
    * @return                       The institution value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_tag            IN header_tag.internal_name%TYPE,
        o_data_rec       OUT t_rec_header_data
    ) RETURN BOOLEAN;

    /**
    * Returns the institution value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_institution       Institution Id
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The institution value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_tag            IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_found BOOLEAN;
    g_exception EXCEPTION;
    g_row institution%ROWTYPE := NULL;

END;
/
