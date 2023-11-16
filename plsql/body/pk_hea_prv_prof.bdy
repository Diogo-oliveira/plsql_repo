/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_prof IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_row                 := NULL;
        g_row.id_professional := NULL;
    END;

    /**
    * Fetchs all the variables for the professional if they have not been fetched yet.
    *
    * @param i_id_professional Professional Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var(i_id_professional IN professional.id_professional%TYPE) IS
    BEGIN
        IF i_id_professional IS NULL
        THEN
            reset_var;
            RETURN;
        END IF;
        IF g_row.id_professional IS NULL
           OR g_row.id_professional != i_id_professional
        THEN
            g_error := 'SELECT * INTO g_row FROM professioanl';
            pk_alertlog.log_debug(g_error);
            SELECT *
              INTO g_row
              FROM professional p
             WHERE p.id_professional = i_id_professional;
        END IF;
    END;

    /**
    * Returns the professional photo.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_institution       Institution Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_aux.get_photo(i_lang, i_prof, i_id_professional);
    END;

    /**
    * Returns the professional name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_institution       Institution Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_name
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_professional);
        RETURN g_row.nick_name;
    END;

    /**
    * Returns the professional fullname.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_fullname
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_professional);
        RETURN g_row.name;
    END;

    /**
    * Returns the professional title.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_professional);
        RETURN pk_backoffice.get_prof_title_desc(i_lang, g_row.title);
    END;

    /**
    * Returns the professional category.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_institution       Institution Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_instituttion IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_aux.get_category(i_lang, i_prof, i_id_professional, i_id_instituttion);
    END;

    /**
    * Returns the professional specialty.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_institution       Institution Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_speciality
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        check_var(i_id_professional);
        RETURN pk_translation.get_translation_dtchk(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || g_row.id_speciality);
    END;

    /**
    * Returns the institution and professional name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_institution       Institution Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prof_inst_names
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
        l_acronym institution.abbreviation%TYPE;
    BEGIN
        IF i_id_institution IS NULL
        THEN
            RETURN NULL;
        END IF;
        l_acronym := pk_hea_prv_inst.get_acronym(i_lang, i_prof, i_id_institution);
        IF i_id_professional IS NULL
        THEN
            RETURN l_acronym;
        ELSE
            RETURN l_acronym || ', ' || get_name(i_lang, i_prof, i_id_professional);
        END IF;
    END;

    /**
    * Returns the professional photo timestamp.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_institution       Institution Id
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo_timestamp
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_aux.get_photo_timestamp(i_lang, i_prof, i_id_professional);
    END;

    /**
    * Returns the professional value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_prof              Professional Id
    * @param i_id_institution       Institution Id
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data  
    *
    * @return                       The professional value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_tag             IN header_tag.internal_name%TYPE,
        o_data_rec        OUT t_rec_header_data
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
        g_error := l_func_name;
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        IF i_id_professional IS NULL
           AND i_tag NOT IN ('PROF_INST_NAMES')
        THEN
            RETURN FALSE;
        END IF;
        CASE i_tag
            WHEN 'PROF_PHOTO' THEN
                l_data_rec.source      := get_photo(i_lang, i_prof, i_id_professional);
                l_data_rec.description := get_photo_timestamp(i_lang, i_prof, i_id_professional);
            WHEN 'PROF_NAME' THEN
                l_data_rec.text         := get_name(i_lang, i_prof, i_id_professional);
                l_data_rec.tooltip_text := get_fullname(i_lang, i_prof, i_id_professional);
            WHEN 'PROF_TITLE' THEN
                l_data_rec.text := get_title(i_lang, i_prof, i_id_professional);
            WHEN 'PROF_CATEGORY' THEN
                l_data_rec.text := get_category(i_lang, i_prof, i_id_professional, i_id_institution);
            WHEN 'PROF_SPECIALTY' THEN
                l_data_rec.text := get_speciality(i_lang, i_prof, i_id_professional);
            WHEN 'PROF_INST_NAMES' THEN
                l_data_rec.text := get_prof_inst_names(i_lang, i_prof, i_id_professional, i_id_institution);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the professional value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_prof              Professional Id
    * @param i_id_institution       Institution Id
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The professional value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_tag             IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_tag       header_tag.internal_name%TYPE;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := l_func_name;
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        IF i_id_professional IS NULL
           AND i_tag NOT IN ('PROF_INST_NAMES')
        THEN
            RETURN NULL;
        END IF;
    
        -- Translate old tags to html version
        CASE i_tag
            WHEN 'PROF_FULLNAME' THEN
                l_tag := 'PROF_NAME';
            WHEN 'PROF_PHOTO_TIMESTAMP' THEN
                l_tag := 'PROF_PHOTO';
            ELSE
                l_tag := i_tag;
        END CASE;
    
        l_ret := get_value_html(i_lang, i_prof, i_id_professional, i_id_institution, l_tag, l_data_rec);
    
        CASE i_tag
            WHEN 'PROF_PHOTO' THEN
                RETURN l_data_rec.source;
            WHEN 'PROF_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'PROF_FULLNAME' THEN
                RETURN l_data_rec.tooltip_text;
            WHEN 'PROF_TITLE' THEN
                RETURN l_data_rec.text;
            WHEN 'PROF_CATEGORY' THEN
                RETURN l_data_rec.text;
            WHEN 'PROF_SPECIALTY' THEN
                RETURN l_data_rec.text;
            WHEN 'PROF_INST_NAMES' THEN
                RETURN l_data_rec.text;
            WHEN 'PROF_PHOTO_TIMESTAMP' THEN
                RETURN l_data_rec.description;
            ELSE
                NULL;
        END CASE;
        RETURN 'prof_' || i_tag;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
