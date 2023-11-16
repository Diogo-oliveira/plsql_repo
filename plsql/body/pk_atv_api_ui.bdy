/*-- Last Change Revision: $Rev: 1922766 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2019-10-29 10:35:08 +0000 (ter, 29 out 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_atv_api_ui AS

    ---------------------------------- Private Package Constants ------------------------------
    g_flg_type_a     CONSTANT VARCHAR2(1) := 'A'; -- Galleries and Videos ALERT
    g_flg_type_i     CONSTANT VARCHAR2(1) := 'I'; -- Galleries and Videos managed by each Institution
    g_flg_type_title CONSTANT VARCHAR2(1) := 'T'; -- Flag Title
    g_flg_type_desc  CONSTANT VARCHAR2(1) := 'D'; -- Flag Description
    g_yes            CONSTANT VARCHAR2(1) := 'Y'; -- Flag YES
    g_video_path     CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'ALERTTV_VIDEO_PATH',
                                                                               i_prof    => profissional(0, 0, 0));
    ---------------------------------- Private Packages Variables ------------------------------

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(30);
    /* Stores the package owner. */
    g_package_owner VARCHAR2(30);

    ---------------------------------- Auxiliar Functions ------------------------------

    FUNCTION error_handling
    (
        i_lang              IN language.id_language%TYPE,
        i_sqlcode           IN VARCHAR2,
        i_sqlerrm           IN VARCHAR2,
        i_message           IN VARCHAR2,
        i_owner             IN VARCHAR2,
        i_package           IN VARCHAR2,
        i_function          IN VARCHAR2,
        i_undo_changes      IN BOOLEAN DEFAULT FALSE,
        i_reset_error_state IN BOOLEAN DEFAULT FALSE,
        o_error             IN OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => i_sqlcode,
                                          i_sqlerrm  => i_sqlerrm,
                                          i_message  => i_message,
                                          i_owner    => i_owner,
                                          i_package  => i_package,
                                          i_function => i_function,
                                          o_error    => o_error);
        -- If function called by FLASH
        IF i_reset_error_state
        THEN
            pk_alert_exceptions.reset_error_state;
        END IF;
    
        -- Rollback transaction
        IF i_undo_changes
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    FUNCTION get_config
    (
        i_code_cf   IN VARCHAR2,
        i_prof_inst IN NUMBER,
        i_prof_soft IN NUMBER
    ) RETURN VARCHAR2 IS
        l_internal_name  skin_soft_inst.internal_name%TYPE;
        l_file_name      application_file.file_name%TYPE;
        l_file_extension application_file.file_extension%TYPE;
    BEGIN
    
        SELECT internal_name
          INTO l_internal_name
          FROM (SELECT internal_name,
                       row_number() over(PARTITION BY internal_name ORDER BY id_institution DESC, id_software DESC) rn
                  FROM skin_soft_inst
                 WHERE internal_name = i_code_cf
                   AND id_institution IN (i_prof_inst, 0)
                   AND id_software IN (i_prof_soft, 0))
         WHERE rn = 1;
    
        SELECT file_name, file_extension
          INTO l_file_name, l_file_extension
          FROM application_file af
         WHERE af.internal_name = l_internal_name;
    
        RETURN l_file_name || '.' || l_file_extension;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_config;

    FUNCTION get_translation
    (
        i_lang             IN NUMBER,
        i_code_translation IN VARCHAR2,
        i_trans_type       IN VARCHAR2,
        i_id_tv_media      IN NUMBER,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_translation pk_translation.t_desc_translation;
    BEGIN
    
        IF i_flg_type = g_flg_type_a
        THEN
            l_translation := pk_translation.get_translation(i_lang, i_code_translation);
        ELSE
            SELECT CASE
                       WHEN i_trans_type = g_flg_type_title THEN
                        title
                       ELSE
                        description
                   END
              INTO l_translation
              FROM tv_user_media
             WHERE id_tv_media = i_id_tv_media
               AND flg_type = g_flg_type_i
               AND id_language = i_lang;
        END IF;
    
        RETURN l_translation;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN ' ';
    END;

    FUNCTION get_prof_template
    (
        i_lang                IN language.id_language%TYPE,
        i_id_entity           IN NUMBER,
        i_id_inst             IN NUMBER,
        i_id_soft             IN NUMBER,
        o_id_profile_template OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROF_TEMPLATE';
    BEGIN
        g_error := 'GET o_id_profile_template VALUE';
        SELECT pt.id_profile_template
          INTO o_id_profile_template
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_id_entity
           AND ppt.id_institution = i_id_inst
           AND ppt.id_software = i_id_soft
           AND ppt.id_profile_template = pt.id_profile_template
           AND ppt.id_software = pt.id_software
           AND pt.flg_available = g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_profile_template := 0;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            o_id_profile_template := 0;
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_prof_template;

    FUNCTION get_id_market
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN NUMBER,
        o_id_market      OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ID_MARKET';
    BEGIN
        g_error := 'GET o_id_profile_template VALUE';
        SELECT id_market
          INTO o_id_market
          FROM institution
         WHERE id_institution = i_id_institution;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_id_market := 0;
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => FALSE,
                                  o_error             => o_error);
    END get_id_market;

    /********************************************************************************************
    * Function for return BLOB for JAVA servlet
    *
    * @param i_lang          Language ID
    * @param i_id_entity     Input professional, citizen or user ID
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_blob
    (
        i_lang        IN language.id_language%TYPE,
        i_id_entity   IN NUMBER,
        i_id_tv_image IN NUMBER,
        i_flg_type    IN VARCHAR,
        o_img         OUT BLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_BLOB';
    BEGIN
        g_error := 'CALL pk_atv_pbl_core.GET_BLOB';
        pk_atv_pbl_core.get_blob(i_id_tv_image => i_id_tv_image, i_flg_type => i_flg_type, o_image => o_img);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_blob;

    /********************************************************************************************
    * Function for build http call for JAVA servlet
    *
    * @param i_lang          Language ID
    * @param i_id_entity     Input professional, citizen or user ID
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    * @param <table columns>
    *
    * @return                http string
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_media_thumb
    (
        i_lang           IN NUMBER,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        i_id_tv_image    IN NUMBER,
        i_flg_type       IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_path sys_config.value%TYPE;
    BEGIN
    
        l_path := pk_sysconfig.get_config(i_code_cf => 'URL_ALERTTV_THUMBS',
                                          i_prof    => profissional(0, i_id_institution, i_id_software));
        l_path := REPLACE(l_path, '@1', i_lang);
        l_path := REPLACE(l_path, '@2', i_id_entity);
        l_path := REPLACE(l_path, '@3', i_id_tv_image);
        l_path := REPLACE(l_path, '@4', i_flg_type);
    
        RETURN l_path;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_media_thumb;

    /********************************************************************************************
    * Function for get video file name
    *
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    *
    * @return                video file name
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_video_filename
    (
        i_id_tv_image IN NUMBER,
        i_flg_type    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_video_url VARCHAR2(4000);
    BEGIN
        l_video_url := g_video_path || '/' ||
                       pk_atv_pbl_core.get_video_filename(i_id_tv_image => i_id_tv_image, i_flg_type => i_flg_type);
    
        RETURN l_video_url;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_video_filename;

    /********************************************************************************************
    * Function for format video duration
    *
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    *
    * @return                video file name
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION format_video_duration
    (
        i_lang     language.id_language%TYPE,
        i_duration NUMBER,
        i_inst     NUMBER,
        i_soft     NUMBER
    ) RETURN VARCHAR2 IS
        l_h         NUMBER;
        l_m_aux     NUMBER;
        l_m         NUMBER;
        l_s         NUMBER;
        l_ret       VARCHAR2(200);
        l_hour_mask sys_config.value%TYPE;
    BEGIN
        l_h     := trunc(i_duration / 3600);
        l_m_aux := MOD(i_duration, 3600);
        l_m     := trunc(l_m_aux / 60);
        l_s     := MOD(l_m_aux, 60);
    
        IF l_h > 0
        THEN
            l_hour_mask := pk_sysconfig.get_config('HOUR_FORMAT', i_inst, i_soft);
            l_ret       := to_char(l_h, 'FM00') || ':' || to_char(l_m, 'FM00');
            l_ret       := to_char(to_date(l_ret, 'HH24:MI'), l_hour_mask);
        ELSE
            l_ret := to_char(l_m, 'FM00') || ':' || to_char(l_s, 'FM00');
            l_ret := to_char(to_date(l_ret, 'MI:SS'), 'MI:SS"m"');
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END format_video_duration;

    FUNCTION get_tv_config
    (
        i_lang   IN NUMBER,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'GET_TV_CONFIG';
        l_skin_popup  VARCHAR2(4000);
        l_skin_player VARCHAR2(4000);
    BEGIN
        l_skin_popup  := get_config(i_code_cf => 'ALERT_TV_MAINWINDOWSKIN', i_prof_inst => 0, i_prof_soft => 0);
        l_skin_player := get_config(i_code_cf => 'ALERT_TV_PLAYERSKIN', i_prof_inst => 0, i_prof_soft => 0);
    
        OPEN o_cursor FOR
            SELECT l_skin_popup skin_popup, l_skin_player skin_player
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cursor);
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_tv_config;

    FUNCTION get_count_video_review
    (
        i_id_product  IN VARCHAR2,
        i_id_entity   IN NUMBER,
        i_id_tv_video IN NUMBER,
        i_flg_type    IN VARCHAR2
    ) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
        l_count := pk_atv_pbl_core.get_count_video_review(i_id_product  => i_id_product,
                                                          i_id_entity   => i_id_entity,
                                                          i_id_tv_video => i_id_tv_video,
                                                          i_flg_type    => i_flg_type);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_count_video_review;

    /********************************************************************************************
    * This function increments video reviews
    * For repetitive videos (like happy birthday) the begin date is added repeat defined interval
    *
    * @param i_lang          Language ID
    * @param i_language      Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_tv_video   Input video ID
    * @param i_flg_type      Input flag type: A-Alert; I-Institutional
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION inc_video_reviews
    (
        i_lang        IN NUMBER,
        i_id_product  IN VARCHAR2,
        i_id_entity   IN NUMBER,
        i_id_tv_video IN NUMBER,
        i_flg_type    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'INC_VIDEO_REVIEWS';
    BEGIN
        g_error := 'CALL pk_atv_pbl_core.INC_VIDEO_REVIEWS';
        pk_atv_pbl_core.inc_video_reviews(i_id_product  => i_id_product,
                                          i_id_entity   => nvl(i_id_entity, 0),
                                          i_id_tv_video => i_id_tv_video,
                                          i_flg_type    => i_flg_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END inc_video_reviews;

    /********************************************************************************************
    * This function returns media IDs and flg_type for galleries/videos with permissions for id_entity
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_tv_video   Input video ID
    * @param i_flg_type      Input flag type: A-Alert; I-Institutional
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_galleries
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        o_galleries      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_GALLERIES';
        l_id_profile_template NUMBER;
        l_id_market           NUMBER;
    BEGIN
        g_error := 'CALL get_prof_template FUNCTION';
        IF NOT get_prof_template(i_lang                => i_lang,
                                 i_id_entity           => to_number(i_id_entity),
                                 i_id_inst             => i_id_institution,
                                 i_id_soft             => i_id_software,
                                 o_id_profile_template => l_id_profile_template,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_id_market FUNCTION';
        IF NOT get_id_market(i_lang           => i_lang,
                             i_id_institution => i_id_institution,
                             o_id_market      => l_id_market,
                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR O_GALLERIES';
        OPEN o_galleries FOR
            SELECT id_tv_media,
                   flg_type,
                   get_translation(i_lang, code_title, g_flg_type_title, id_tv_media, flg_type) title,
                   get_translation(i_lang, code_description, g_flg_type_desc, id_tv_media, flg_type) description,
                   get_media_thumb(i_lang,
                                   i_id_entity,
                                   i_id_institution,
                                   i_id_software,
                                   tvm.id_image_thumb,
                                   tvm.flg_type) thumb_url,
                   rank
              FROM tv_media tvm
             WHERE (tvm.id_tv_media, tvm.flg_type) IN
                   (SELECT id_tv_gallery, flg_gallery_type
                      FROM TABLE(pk_atv_pbl_core.get_galleries(i_lang,
                                                               i_id_product,
                                                               i_id_entity,
                                                               l_id_market,
                                                               i_id_institution,
                                                               i_id_software,
                                                               l_id_profile_template)))
             ORDER BY nvl(rank, 999999999999999999999999), title, description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_galleries;

    /********************************************************************************************
    * This function returns videos for a gallery ID
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_gallery    Input gallery ID
    * @param i_flg_gallery_type Input gallery type: A-Alert; I-Institutional
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_videos
    (
        i_lang             IN NUMBER,
        i_id_product       IN VARCHAR2,
        i_id_entity        IN NUMBER,
        i_id_institution   IN NUMBER DEFAULT 0,
        i_id_software      IN NUMBER DEFAULT 0,
        i_id_gallery       IN NUMBER,
        i_flg_gallery_type IN VARCHAR2,
        o_videos           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_VIDEOS';
        l_id_profile_template NUMBER;
        l_id_market           NUMBER;
    BEGIN
        g_error := 'CALL get_prof_template FUNCTION';
        IF NOT get_prof_template(i_lang                => i_lang,
                                 i_id_entity           => to_number(i_id_entity),
                                 i_id_inst             => i_id_institution,
                                 i_id_soft             => i_id_software,
                                 o_id_profile_template => l_id_profile_template,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_id_market FUNCTION';
        IF NOT get_id_market(i_lang           => i_lang,
                             i_id_institution => i_id_institution,
                             o_id_market      => l_id_market,
                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR O_VIDEOS';
        OPEN o_videos FOR
            SELECT tvm.id_tv_media,
                   tvm.flg_type,
                   get_translation(i_lang, tvm.code_title, g_flg_type_title, tvm.id_tv_media, tvm.flg_type) title,
                   get_translation(i_lang, tvm.code_description, g_flg_type_desc, tvm.id_tv_media, tvm.flg_type) description,
                   get_media_thumb(i_lang,
                                   i_id_entity,
                                   i_id_institution,
                                   i_id_software,
                                   tvm.id_image_thumb,
                                   tvm.flg_type) thumb_url,
                   tvm.video_id_language,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, tvm.video_date, i_id_institution, i_id_software) video_date,
                   format_video_duration(i_lang, nvl(tvm.video_duration, 0), i_id_institution, i_id_software) video_duration,
                   tvm.video_cue_points,
                   tvm.video_reviews,
                   tvm.rank,
                   get_video_filename(tvm.id_image_file, tvm.flg_type) file_name,
                   get_count_video_review(i_id_product, i_id_entity, tvm.id_tv_media, tvm.flg_type) user_video_reviews
              FROM tv_media tvm
             WHERE (tvm.id_tv_media, tvm.flg_type) IN
                   (SELECT id_tv_video, flg_video_type
                      FROM TABLE(pk_atv_pbl_core.get_videos(i_lang,
                                                            i_id_product,
                                                            i_id_entity,
                                                            l_id_market,
                                                            i_id_institution,
                                                            i_id_software,
                                                            l_id_profile_template,
                                                            i_id_gallery,
                                                            i_flg_gallery_type)))
             ORDER BY nvl(rank, 999999999999999999999999), title, description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_videos;

    /********************************************************************************************
    * This function returns new videos for a entity ID
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_new_videos
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        o_videos         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_NEW_VIDEOS';
        l_id_profile_template NUMBER;
        l_id_market           NUMBER;
    BEGIN
        g_error := 'CALL get_prof_template FUNCTION';
        IF NOT get_prof_template(i_lang                => i_lang,
                                 i_id_entity           => i_id_entity,
                                 i_id_inst             => i_id_institution,
                                 i_id_soft             => i_id_software,
                                 o_id_profile_template => l_id_profile_template,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_id_market FUNCTION';
        IF NOT get_id_market(i_lang           => i_lang,
                             i_id_institution => i_id_institution,
                             o_id_market      => l_id_market,
                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR O_VIDEOS';
        OPEN o_videos FOR
            SELECT tvm.id_tv_media,
                   tvm.flg_type,
                   get_translation(i_lang, tvm.code_title, g_flg_type_title, tvm.id_tv_media, tvm.flg_type) title,
                   get_translation(i_lang, tvm.code_description, g_flg_type_desc, tvm.id_tv_media, tvm.flg_type) description,
                   get_media_thumb(i_lang,
                                   i_id_entity,
                                   i_id_institution,
                                   i_id_software,
                                   tvm.id_image_thumb,
                                   tvm.flg_type) thumb_url,
                   tvm.video_id_language,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, tvm.video_date, i_id_institution, i_id_software) video_date,
                   format_video_duration(i_lang, nvl(tvm.video_duration, 0), i_id_institution, i_id_software) video_duration,
                   tvm.video_cue_points,
                   tvm.video_reviews,
                   tvm.rank,
                   get_video_filename(tvm.id_image_file, tvm.flg_type) file_name,
                   0 user_video_reviews
              FROM tv_media tvm
             WHERE (tvm.id_tv_media, tvm.flg_type) IN
                   (SELECT id_tv_video, flg_video_type
                      FROM TABLE(pk_atv_pbl_core.get_new_videos(i_lang,
                                                                i_id_product,
                                                                i_id_entity,
                                                                l_id_market,
                                                                i_id_institution,
                                                                i_id_software,
                                                                l_id_profile_template)))
             ORDER BY tvm.video_date DESC, nvl(rank, 999999999999999999999999), title, description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_new_videos;

    /********************************************************************************************
    * This function returns the number of new videos for a entity ID
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Vítor Sá
    * @version               V.2.7.4.5
    * @since                 2018/11/09
    ********************************************************************************************/
    FUNCTION get_new_videos_count
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        o_count          OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_NEW_VIDEOS';
        l_id_profile_template NUMBER;
        l_id_market           NUMBER;
        l_count               NUMBER;
    BEGIN
        g_error := 'CALL get_prof_template FUNCTION';
        IF NOT get_prof_template(i_lang                => i_lang,
                                 i_id_entity           => i_id_entity,
                                 i_id_inst             => i_id_institution,
                                 i_id_soft             => i_id_software,
                                 o_id_profile_template => l_id_profile_template,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_id_market FUNCTION';
        IF NOT get_id_market(i_lang           => i_lang,
                             i_id_institution => i_id_institution,
                             o_id_market      => l_id_market,
                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR O_VIDEOS';
        BEGIN
            SELECT /*tvm.id_tv_media,
                                                                   tvm.flg_type,
                                                                   get_translation(i_lang, tvm.code_title, g_flg_type_title, tvm.id_tv_media, tvm.flg_type) title,
                                                                   get_translation(i_lang, tvm.code_description, g_flg_type_desc, tvm.id_tv_media, tvm.flg_type) description,
                                                                   get_media_thumb(i_lang,
                                                                                   i_id_entity,
                                                                                   i_id_institution,
                                                                                   i_id_software,
                                                                                   tvm.id_image_thumb,
                                                                                   tvm.flg_type) thumb_url,
                                                                   tvm.video_id_language,
                                                                   pk_date_utils.date_chr_short_read_tsz(i_lang, tvm.video_date, i_id_institution, i_id_software) video_date,
                                                                   format_video_duration(i_lang, nvl(tvm.video_duration, 0), i_id_institution, i_id_software) video_duration,
                                                                   tvm.video_cue_points,
                                                                   tvm.video_reviews,
                                                                   tvm.rank,
                                                                   get_video_filename(tvm.id_image_file, tvm.flg_type) file_name,
                                                                   0 user_video_reviews*/
             COUNT(*)
              INTO l_count
              FROM tv_media tvm
            
             WHERE (tvm.id_tv_media, tvm.flg_type) IN
                   (SELECT id_tv_video, flg_video_type
                      FROM TABLE(pk_atv_pbl_core.get_new_videos(i_lang,
                                                                i_id_product,
                                                                i_id_entity,
                                                                l_id_market,
                                                                i_id_institution,
                                                                i_id_software,
                                                                l_id_profile_template)));
        
        END;
    
        o_count := l_count;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_new_videos_count;

    /********************************************************************************************
    * This function returns videos for a entity ID and for a search expression based on video tags,
    * titles and descriptions
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_video      Input video ID for search related viedos
    * @param i_flg_type      Input video type (A-Alert; I-Institutional) for search related viedos
    * @param i_search_expr   Input search expression text
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_search_videos
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        i_search_expr    IN VARCHAR2,
        o_search_result  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_SEARCH_VIDEOS';
        l_id_profile_template NUMBER;
        l_id_market           NUMBER;
        l_search_expr         pk_translation.t_desc_translation;
    BEGIN
        g_error := 'VALIDATE SEARCH EXPRESSION';
        IF i_search_expr IS NULL
           OR TRIM(i_search_expr) IS NULL
        THEN
            pk_types.open_my_cursor(o_search_result);
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL get_prof_template FUNCTION';
        IF NOT get_prof_template(i_lang                => i_lang,
                                 i_id_entity           => to_number(i_id_entity),
                                 i_id_inst             => i_id_institution,
                                 i_id_soft             => i_id_software,
                                 o_id_profile_template => l_id_profile_template,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_id_market FUNCTION';
        IF NOT get_id_market(i_lang           => i_lang,
                             i_id_institution => i_id_institution,
                             o_id_market      => l_id_market,
                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Init variabels / Prepare search_expression
        l_search_expr := TRIM(i_search_expr);
        l_search_expr := regexp_replace(l_search_expr, '( ){2,}', ' ');
        l_search_expr := translate(upper(l_search_expr), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN');
    
        -- Search for video tags
        g_error := 'CALL pk_atv_pbl_core.GET_SEARCH_VIDEOS PROCEDURE';
        OPEN o_search_result FOR
            SELECT DISTINCT id_tv_media,
                            flg_type,
                            title,
                            description,
                            thumb_url,
                            video_id_language,
                            video_date,
                            video_duration,
                            video_cue_points,
                            video_reviews,
                            rank,
                            file_name,
                            user_video_reviews
              FROM (SELECT aux.score,
                           tvm.id_tv_media,
                           tvm.flg_type,
                           get_translation(i_lang, tvm.code_title, g_flg_type_title, tvm.id_tv_media, tvm.flg_type) title,
                           get_translation(i_lang, tvm.code_description, g_flg_type_desc, tvm.id_tv_media, tvm.flg_type) description,
                           get_media_thumb(i_lang,
                                           i_id_entity,
                                           i_id_institution,
                                           i_id_software,
                                           tvm.id_image_thumb,
                                           tvm.flg_type) thumb_url,
                           tvm.video_id_language,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, tvm.video_date, i_id_institution, i_id_software) video_date,
                           format_video_duration(i_lang, nvl(tvm.video_duration, 0), i_id_institution, i_id_software) video_duration,
                           tvm.video_cue_points,
                           tvm.video_reviews,
                           tvm.rank,
                           get_video_filename(tvm.id_image_file, tvm.flg_type) file_name,
                           get_count_video_review(i_id_product, i_id_entity, tvm.id_tv_media, tvm.flg_type) user_video_reviews
                      FROM tv_media tvm
                     INNER JOIN TABLE(pk_atv_pbl_core.get_search_videos(i_lang, i_id_product, i_id_entity, l_id_market, i_id_institution, i_id_software, l_id_profile_template, NULL, NULL, l_search_expr)) aux
                        ON tvm.id_tv_media = aux.id_tv_video
                    
                    UNION ALL
                    
                    -- Optimization: do not compare on TRANSLATION Table
                    SELECT *
                      FROM (SELECT -1 score,
                                   tvm.id_tv_media,
                                   tvm.flg_type,
                                   get_translation(i_lang,
                                                   tvm.code_title,
                                                   g_flg_type_title,
                                                   tvm.id_tv_media,
                                                   tvm.flg_type) title,
                                   get_translation(i_lang,
                                                   tvm.code_description,
                                                   g_flg_type_desc,
                                                   tvm.id_tv_media,
                                                   tvm.flg_type) description,
                                   get_media_thumb(i_lang,
                                                   i_id_entity,
                                                   i_id_institution,
                                                   i_id_software,
                                                   tvm.id_image_thumb,
                                                   tvm.flg_type) thumb_url,
                                   tvm.video_id_language,
                                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                         tvm.video_date,
                                                                         i_id_institution,
                                                                         i_id_software) video_date,
                                   format_video_duration(i_lang,
                                                         nvl(tvm.video_duration, 0),
                                                         i_id_institution,
                                                         i_id_software) video_duration,
                                   tvm.video_cue_points,
                                   tvm.video_reviews,
                                   tvm.rank,
                                   get_video_filename(tvm.id_image_file, tvm.flg_type) file_name,
                                   get_count_video_review(i_id_product, i_id_entity, tvm.id_tv_media, tvm.flg_type) user_video_reviews
                              FROM tv_media tvm
                             WHERE (tvm.id_tv_media, tvm.flg_type) IN
                                   (SELECT id_tv_video, flg_video_type
                                      FROM TABLE(pk_atv_pbl_core.get_videos(i_lang,
                                                                            i_id_product,
                                                                            i_id_entity,
                                                                            l_id_market,
                                                                            i_id_institution,
                                                                            i_id_software,
                                                                            l_id_profile_template)))) aux2
                     WHERE translate(upper(aux2.title), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || l_search_expr || '%'
                        OR translate(upper(aux2.description), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || l_search_expr || '%'
                     ORDER BY score, title, description) aaaa;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_search_videos;

    /********************************************************************************************
    * This function returns videos with tags related with i_id_video/i_flg_type video
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_video      Input video ID
    * @param i_flg_type      Input video type (A-Alert; I-Institutional)
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_related_videos
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        i_id_video       IN NUMBER,
        i_flg_type       IN VARCHAR2,
        o_search_result  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_RELATED_VIDEOS';
        l_id_profile_template NUMBER;
        l_id_market           NUMBER;
    BEGIN
        g_error := 'CALL get_prof_template FUNCTION';
        IF NOT get_prof_template(i_lang                => i_lang,
                                 i_id_entity           => to_number(i_id_entity),
                                 i_id_inst             => i_id_institution,
                                 i_id_soft             => i_id_software,
                                 o_id_profile_template => l_id_profile_template,
                                 o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL get_id_market FUNCTION';
        IF NOT get_id_market(i_lang           => i_lang,
                             i_id_institution => i_id_institution,
                             o_id_market      => l_id_market,
                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR O_SEARCH_RESULT';
        OPEN o_search_result FOR
            SELECT tvm.id_tv_media,
                   tvm.flg_type,
                   get_translation(i_lang, tvm.code_title, g_flg_type_title, tvm.id_tv_media, tvm.flg_type) title,
                   get_translation(i_lang, tvm.code_description, g_flg_type_desc, tvm.id_tv_media, tvm.flg_type) description,
                   get_media_thumb(i_lang,
                                   i_id_entity,
                                   i_id_institution,
                                   i_id_software,
                                   tvm.id_image_thumb,
                                   tvm.flg_type) thumb_url,
                   tvm.video_id_language,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, tvm.video_date, i_id_institution, i_id_software) video_date,
                   format_video_duration(i_lang, nvl(tvm.video_duration, 0), i_id_institution, i_id_software) video_duration,
                   tvm.video_cue_points,
                   tvm.video_reviews,
                   tvm.rank,
                   get_video_filename(tvm.id_image_file, tvm.flg_type) file_name,
                   get_count_video_review(i_id_product, i_id_entity, tvm.id_tv_media, tvm.flg_type) user_video_reviews
              FROM tv_media tvm
             WHERE (tvm.id_tv_media, tvm.flg_type) IN
                   (SELECT id_tv_video, flg_video_type
                      FROM TABLE(pk_atv_pbl_core.get_related_videos(i_lang,
                                                                    i_id_product,
                                                                    i_id_entity,
                                                                    l_id_market,
                                                                    i_id_institution,
                                                                    i_id_software,
                                                                    l_id_profile_template,
                                                                    i_id_video,
                                                                    i_flg_type)))
             ORDER BY nvl(rank, 999999999999999999999999), title, description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang              => i_lang,
                                  i_sqlcode           => SQLCODE,
                                  i_sqlerrm           => SQLERRM,
                                  i_message           => g_error,
                                  i_owner             => g_package_owner,
                                  i_package           => g_package_name,
                                  i_function          => l_func_name,
                                  i_reset_error_state => TRUE,
                                  o_error             => o_error);
    END get_related_videos;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_atv_api_ui;
/
