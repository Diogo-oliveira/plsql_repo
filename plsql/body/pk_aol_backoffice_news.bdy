/*-- Last Change Revision: $Rev: 2026652 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_aol_backoffice_news IS

    FUNCTION get_institutions
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        o_institutions OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- TODO Falta testar
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_institutions(aol.t_user(:i_prof_id,
                                                                      :i_prof_institution,
                                                                      :i_prof_software,
                                                                      :i_lang),
                                                           :o_institutions,
                                                           :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_institutions, OUT o_error;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_INSTITUTIONS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_institutions);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_languages
    (
        i_prof      IN profissional,
        i_lang      IN language.id_language%TYPE,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT
            aol.pk_aol_backoffice_news.get_languages(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                     :o_languages,
                                                     :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_languages, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_LANGUAGES');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_languages);
                RETURN FALSE;
            END;
    END;

    /**********************************************************************************************************/
    FUNCTION get_latest_news
    (
        i_prof        IN profissional,
        i_lang        IN language.id_language%TYPE,
        o_latest_news OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT
            aol.pk_aol_backoffice_news.get_latest_news(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                       :o_latest_news,
                                                       :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_latest_news, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_LATEST_NEWS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_latest_news);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_news_archive
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        o_news_archive OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_news_archive(aol.t_user(:i_prof_id,
                                                                      :i_prof_institution,
                                                                      :i_prof_software,
                                                                      :i_lang),
                                                           :o_news_archive,
                                                           :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_news_archive, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_NEWS_ARCHIVE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_news_archive);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_news
    (
        i_prof       IN profissional,
        i_lang       IN language.id_language%TYPE,
        i_id_news    IN NUMBER,
        o_news       OUT pk_types.cursor_type,
        o_news_text  OUT pk_types.cursor_type,
        o_theme_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_news(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                   :i_id_news,
                                                   :o_news,
                                                   :o_news_text,
                                                   :o_theme_list,
                                                   :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_id_news, OUT o_news, OUT o_news_text, OUT o_theme_list, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'GET_NEWS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_news);
                pk_types.open_my_cursor(o_news_text);
                pk_types.open_my_cursor(o_theme_list);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION set_news
    (
        i_prof                    IN profissional,
        i_lang                    IN language.id_language%TYPE,
        i_id_news                 IN NUMBER,
        i_flg_available           IN VARCHAR2,
        i_id_institution          IN NUMBER,
        i_id_image                IN NUMBER,
        i_id_style                IN NUMBER,
        i_flg_type                IN VARCHAR2,
        i_id_related_content_type IN NUMBER,
        i_id_content              IN NUMBER,
        i_date_desc               IN VARCHAR2,
        o_id_news                 OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.set_news(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                   :i_id_news,
                                                   :i_flg_available,
                                                   :i_id_institution,
                                                   :i_id_image,
                                                   :i_id_style,
                                                   :i_flg_type,
                                                   :i_id_related_content_type,
                                                   :i_id_content,
                                                   :i_date_desc,
                                                   :o_id_news,
                                                   :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_id_news, IN i_flg_available, IN i_id_institution, IN i_id_image, IN i_id_style, IN i_flg_type, IN i_id_related_content_type, IN i_id_content, IN i_date_desc, OUT o_id_news, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'SET_NEWS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION set_news_text
    (
        i_prof               IN profissional,
        i_lang               IN language.id_language%TYPE,
        i_id_news_text       IN NUMBER,
        i_id_news            IN NUMBER,
        i_flg_available      IN VARCHAR2,
        i_id_language        IN NUMBER,
        i_desc_news_title    IN VARCHAR2,
        i_desc_news_subtitle IN VARCHAR2,
        i_desc_news_text     IN VARCHAR2,
        i_date_desc          IN VARCHAR2,
        o_id_news_text       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT
            aol.pk_aol_backoffice_news.set_news_text(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                     :i_id_news_text,
                                                     :i_id_news,
                                                     :i_flg_available,
                                                     :i_id_language,
                                                     :i_desc_news_title,
                                                     :i_desc_news_subtitle,
                                                     :i_desc_news_text,
                                                     :i_date_desc,
                                                     :o_id_news_text,
                                                     :o_error)
        THEN
             RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_id_news_text, IN i_id_news, IN i_flg_available, IN i_id_language, IN i_desc_news_title, IN i_desc_news_subtitle, IN i_desc_news_text, IN i_date_desc, OUT o_id_news_text, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'SET_NEWS_TEXT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION set_image
    (
        i_prof      IN profissional,
        i_lang      IN language.id_language%TYPE,
        i_id_image  IN NUMBER,
        i_mime_type IN VARCHAR2,
        i_file_name IN VARCHAR2,
        o_id_image  OUT NUMBER,
        o_file_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.set_image(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                    :i_id_image,
                                                    :i_mime_type,
                                                    :i_file_name,
                                                    :o_id_image,
                                                    :o_file_name,
                                                    :o_error)
        THEN
             RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_id_image, IN i_mime_type, IN i_file_name, OUT o_id_image, OUT o_file_name, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'SET_IMAGE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_theme
    (
        i_prof  IN profissional,
        i_lang  IN language.id_language%TYPE,
        o_theme OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_theme(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                    :o_theme,
                                                    :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_theme, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'GET_THEME');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_theme);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_content_type
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        o_content_type OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_content_type(aol.t_user(:i_prof_id,
                                                                      :i_prof_institution,
                                                                      :i_prof_software,
                                                                      :i_lang),
                                                           :o_content_type,
                                                           :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_content_type, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_CONTENT_TYPE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_content_type);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_content
    (
        i_prof             IN profissional,
        i_lang             IN language.id_language%TYPE,
        i_flg_content_type IN VARCHAR2,
        o_content          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_content(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                      :i_flg_content_type,
                                                      :o_content,
                                                      :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_flg_content_type, OUT o_content, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'GET_CONTENT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_content);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION get_style
    (
        i_prof  IN profissional,
        i_lang  IN language.id_language%TYPE,
        o_style OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_style(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                    :o_style,
                                                    :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, OUT o_style, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'GET_STYLE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_style);
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************************/

    FUNCTION set_theme
    (
        i_prof          IN profissional,
        i_lang          IN language.id_language%TYPE,
        i_id_news       IN NUMBER,
        i_theme_list    IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.set_theme(aol.t_user(:i_prof_id, :i_prof_institution, :i_prof_software, :i_lang),
                                                    :i_id_news,
                                                    :i_theme_list,
                                                    :i_flg_available,
                                                    :o_error)
        THEN
            RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_id_news, IN i_theme_list, IN i_flg_available, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_AOL_BACKOFFICE_NEWS', 'SET_THEME');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END;
    /******************************************************************************************************/

    FUNCTION get_news_archive_search
    (
        i_prof          IN profissional,
        i_lang          IN language.id_language%TYPE,
        i_language      IN language.id_language%TYPE,
        i_init_date     IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_search_string IN VARCHAR2,
        i_flg_location  IN VARCHAR2,
        o_news          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_news_archive_search(aol.t_user(:i_prof_id,
                                                                             :i_prof_institution,
                                                                             :i_prof_software,
                                                                             :i_lang),
                                                                  :i_language,
                                                                  :i_init_date,
                                                                  :i_end_date,
                                                                  :i_search_string,
                                                                  :i_flg_location,
                                                                  :o_news,
                                                                  :o_error)
        THEN
             RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_language, IN i_init_date, IN i_end_date, IN i_search_string, IN i_flg_location, OUT o_news, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_NEWS_ARCHIVE_SEARCH');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_news);
                RETURN FALSE;
            END;
    END;

    /***************************************************************************************************/

    FUNCTION get_latest_news_search
    (
        i_prof          IN profissional,
        i_lang          IN language.id_language%TYPE,
        i_language      IN language.id_language%TYPE,
        i_init_date     IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_search_string IN VARCHAR2,
        i_flg_location  IN VARCHAR2,
        o_news          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE 'declare
        g_exception EXCEPTION;
        begin
        IF NOT aol.pk_aol_backoffice_news.get_latest_news_search(aol.t_user(:i_prof_id,
                                                                            :i_prof_institution,
                                                                            :i_prof_software,
                                                                            :i_lang),
                                                                 :i_language,
                                                                 :i_init_date,
                                                                 :i_end_date,
                                                                 :i_search_string,
                                                                 :i_flg_location,
                                                                 :o_news,
                                                                 :o_error)
        THEN
             RAISE g_exception;
        END IF;
        END;'
            USING IN i_prof.id, IN i_prof.institution, IN i_prof.software, IN i_lang, IN i_language, IN i_init_date, IN i_end_date, IN i_search_string, IN i_flg_location, OUT o_news, OUT o_error;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_AOL_BACKOFFICE_NEWS',
                                   'GET_LATEST_NEWS_SEARCH');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_news);
                RETURN FALSE;
            END;
    END;
    --BEGIN
/*******************************************************************************************************/
END;
/
