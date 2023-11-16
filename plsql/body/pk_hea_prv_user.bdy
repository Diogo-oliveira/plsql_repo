/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_user IS

    /**
    * Returns the photo for the user.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    *
    * @return                    The photo
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_prof.get_value(i_lang, i_prof, i_prof.id, NULL, 'PROF_PHOTO');
    END;

    /**
    * Returns the name of the user.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    *
    * @return                    The name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_name
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_prof.get_value(i_lang, i_prof, i_prof.id, NULL, 'PROF_NAME');
    END;

    /**
    * Returns the specialty of the user.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    *
    * @return                    The specialty
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_specialty
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_hea_prv_prof.get_value(i_lang, i_prof, i_prof.id, NULL, 'PROF_SPECIALITY');
    END;

    /**
    * Returns the full name of the user.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    *
    * @return                    The full name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_fullname
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        -- In the tools area for the referral software, the fullname won't be visible.
        IF i_prof.software = 4
           AND i_flg_area = 'T'
        THEN
            RETURN NULL;
        END IF;
        RETURN pk_hea_prv_prof.get_value(i_lang, i_prof, i_prof.id, NULL, 'PROF_FULLNAME');
    END;

    /**
    * Returns the specialty and institution of the user.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    *
    * @return                    The specialty and institution
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_spec_inst
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
        l_spec VARCHAR2(1000);
        l_inst VARCHAR2(1000);
    BEGIN
        l_spec := pk_hea_prv_prof.get_value(i_lang, i_prof, i_prof.id, NULL, 'PROF_SPECIALTY');
        IF l_spec IS NOT NULL
        THEN
            l_inst := pk_hea_prv_inst.get_value(i_lang, i_prof, i_prof.institution, 'INST_ACRONYM');
            RETURN '(' || l_spec || '; ' || l_inst || ')';
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the value for the tag given as parameter.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    * @param i_flg_area          System application area flag
    * @param i_tag               Tag to be replaced
    * @param o_data_rec          Tag's data   
    *
    * @return                    The value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE,
        i_tag      IN header_tag.internal_name%TYPE,
        o_data_rec OUT t_rec_header_data
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
        CASE i_tag
            WHEN 'USER_PHOTO' THEN
                l_data_rec.source := get_photo(i_lang, i_prof);
            WHEN 'USER_NAME' THEN
                l_data_rec.text         := get_name(i_lang, i_prof);
                l_data_rec.tooltip_text := get_fullname(i_lang, i_prof, i_flg_area);
            WHEN 'USER_SPECIALTY' THEN
                l_data_rec.text := get_specialty(i_lang, i_prof);
            WHEN 'USER_SPEC_INST' THEN
                l_data_rec.text := get_spec_inst(i_lang, i_prof);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the value for the tag given as parameter.
    *
    * @param i_lang              Language Id
    * @param i_prof              Professional Id
    * @param i_flg_area          System application area flag
    * @param i_tag               Tag to be replaced
    *
    * @return                    The value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_area IN sys_application_area.flg_area%TYPE,
        i_tag      IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_tag       header_tag.internal_name%TYPE;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
    
        -- Translate old tags to html version
        CASE i_tag
            WHEN 'USER_FULLNAME' THEN
                l_tag := 'USER_NAME';
            ELSE
                l_tag := i_tag;
        END CASE;
    
        l_ret := get_value_html(i_lang, i_prof, i_flg_area, l_tag, l_data_rec);
    
        CASE i_tag
            WHEN 'USER_PHOTO' THEN
                RETURN l_data_rec.source;
            WHEN 'USER_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'USER_SPECIALTY' THEN
                RETURN l_data_rec.text;
            WHEN 'USER_FULLNAME' THEN
                RETURN l_data_rec.tooltip_text;
            WHEN 'USER_SPEC_INST' THEN
                RETURN l_data_rec.text;
            ELSE
                NULL;
        END CASE;
        RETURN 'user_' || i_tag;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
