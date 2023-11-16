/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_inst IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_row.id_institution := NULL;
    END;

    /**
    * Fetchs all the variables for the professional if they have not been fetched yet.
    *
    * @param i_id_institution Institution Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var(i_id_institution IN institution.id_institution%TYPE) IS
    BEGIN
        IF g_row.id_institution IS NULL
           OR g_row.id_institution != i_id_institution
        THEN
            g_error := 'SELECT * INTO g_row_inst FROM institution';
            pk_alertlog.log_debug(g_error);
            SELECT *
              INTO g_row
              FROM institution i
             WHERE i.id_institution = i_id_institution;
        END IF;
    END;

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
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_institution);
        RETURN pk_translation.get_translation(i_lang, g_row.code_institution);
    END;

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
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_institution);
        RETURN g_row.abbreviation;
    END;

    /**
    * Returns the institution administrator.
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
    FUNCTION get_admin
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_prof.get_value(i_lang, i_prof, i_prof.id, i_id_institution, 'PROF_FULL_NAME');
    END;

    /**
    * Returns the institution type.
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
    FUNCTION get_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_institution);
        RETURN pk_sysdomain.get_domain('INSTITUTION.FLG_TYPE', g_row.flg_type, i_lang);
    END;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_data_rec  t_rec_header_data := t_rec_header_data(NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL);
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_institution IS NULL
        THEN
            RETURN NULL;
        END IF;
        CASE i_tag
            WHEN 'INST_NAME' THEN
                l_data_rec.text := get_name(i_lang, i_prof, i_id_institution);
            WHEN 'INST_ACRONYM' THEN
                l_data_rec.text := get_acronym(i_lang, i_prof, i_id_institution);
            WHEN 'INST_ADMIN' THEN
                l_data_rec.text := get_admin(i_lang, i_prof, i_id_institution);
            WHEN 'INST_TYPE' THEN
                l_data_rec.text := get_type(i_lang, i_prof, i_id_institution);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

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
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_institution IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_ret := get_value_html(i_lang, i_prof, i_id_institution, i_tag, l_data_rec);
    
        CASE i_tag
            WHEN 'INST_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'INST_ACRONYM' THEN
                RETURN l_data_rec.text;
            WHEN 'INST_ADMIN' THEN
                RETURN l_data_rec.text;
            WHEN 'INST_TYPE' THEN
                RETURN l_data_rec.text;
            ELSE
                NULL;
        END CASE;
        RETURN 'institution_' || i_tag;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
