/*-- Last Change Revision: $Rev: 2028701 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_func_help IS

    -- Author  : CARLOS.FERREIRA
    -- Created : 19-08-2009
    -- Purpose : Package used for functionality helps
    g_error VARCHAR2(4000);

    g_package_owner VARCHAR2(200);
    g_package_name  VARCHAR2(200);
    g_func_name     VARCHAR2(200);

    g_yes  CONSTANT VARCHAR2(1) := 'Y';
    g_lf   CONSTANT VARCHAR2(1) := chr(10);
    g_null CONSTANT VARCHAR2(0050) := 'NULL';

    PROCEDURE insert_into_functionality_help
    (
        i_lang                  language.id_language%TYPE,
        i_code_help             functionality_help.code_help%TYPE,
        i_desc_help             functionality_help.desc_help%TYPE,
        i_software              software.id_software%TYPE DEFAULT 0,
        i_id_functionality_help functionality_help.id_functionality_help%TYPE DEFAULT NULL,
        i_module                functionality_help.module%TYPE DEFAULT NULL
    );

    FUNCTION get_help_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_help IN functionality_help.code_help%TYPE,
        o_text      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_help_text_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_help IN functionality_help.code_help%TYPE,
        o_text      OUT pk_types.cursor_type,
        o_icons     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE insert_into_fh_icon_screen
    (
        i_lang               language.id_language%TYPE,
        i_fh_icon_group      func_help_icon_group.internal_name%TYPE,
        i_fh_icon_group_desc VARCHAR2 DEFAULT NULL,
        i_fh_icon_name       VARCHAR2,
        i_fh_icon_name_desc  VARCHAR2 DEFAULT NULL,
        i_fh_icon_bg_color   func_help_icon.icon_bg_color%TYPE DEFAULT g_null,
        i_fh_icon_fg_color   func_help_icon.icon_fg_color%TYPE DEFAULT g_null,
        i_fh_screen_name     func_help_icon_screen.screen_name%TYPE DEFAULT NULL,
        i_software           software.id_software%TYPE DEFAULT 0,
        i_rank               func_help_icon_screen.rank%TYPE
    );

    PROCEDURE delete_fh_icon_screen
    (
        i_lang           language.id_language%TYPE,
        i_fh_icon_group  func_help_icon_group.internal_name%TYPE,
        i_fh_icon_name   VARCHAR2,
        i_fh_screen_name func_help_icon_screen.screen_name%TYPE,
        i_software       software.id_software%TYPE
    );

END pk_func_help;
/
