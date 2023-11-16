/*-- Last Change Revision: $Rev: 2027561 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_protocol_attach IS
    /**
    * Public Function. Create context image
    *
    * @param      I_LANG                        Prefered language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_protocol                 Protocol ID
    * @param      I_FILE_NAME                   File name of file to upload
    * @param      I_IMG_DESC                    Image description
    * @param      O_ID_PROTOCOL_CONTEXT_IMAGE   ID of Context image
    * @param      O_ERROR                       Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/20
    */
    FUNCTION create_context_image
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_protocol               IN protocol.id_protocol%TYPE,
        i_file_name                 IN protocol_context_image.file_name%TYPE,
        i_img_desc                  IN protocol_context_image.img_desc%TYPE,
        o_id_protocol_context_image OUT protocol_context_image.id_protocol_context_image%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'INSERT INTO PROTOCOL CONTEXT IMAGE';
        pk_alertlog.log_debug(g_error);
    
        INSERT INTO protocol_context_image
            (id_protocol_context_image, id_protocol, file_name, img_desc, dt_img, img, img_thumbnail, flg_status)
        VALUES
            (seq_protocol_context_image.nextval,
             i_id_protocol,
             i_file_name,
             i_img_desc,
             NULL,
             empty_blob(),
             empty_blob(),
             g_img_inactive)
        RETURNING id_protocol_context_image INTO o_id_protocol_context_image;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CREATE_CONTEXT_IMAGE',
                                              o_error);
            -- rollback
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
    END create_context_image;
    /**
    * Public Function. Upload images to database
    *
    * @param      I_LANG                        Prefered language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_CONTEXT_IMAGE   Protocol context image  ID
    * @param      O_IMG                         Image Blob
    * @param      O_IMG_THUMBNAIL               Image thumbnail Blob
    * @param      O_ERROR                       Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/20
    */
    FUNCTION upload_context_image
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_protocol_context_image IN protocol_context_image.id_protocol_context_image%TYPE,
        o_img                       OUT BLOB,
        o_img_thumbnail             OUT BLOB,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET BLOB DATA';
        pk_alertlog.log_debug(g_error);
    
        SELECT guid_ctx_img.img, guid_ctx_img.img_thumbnail
          INTO o_img, o_img_thumbnail
          FROM protocol_context_image guid_ctx_img
         WHERE guid_ctx_img.id_protocol_context_image = i_id_protocol_context_image
           FOR UPDATE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_SPECIALTY_LIST',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
    END upload_context_image;
    /**
    * Public Function. Update date of context image insert
    *
    * @param      I_LANG                        Prefered language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_CONTEXT_IMAGE   Protocol context image  ID
    * @param      O_ERROR                       Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/20
    */
    FUNCTION update_date_context_image
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_protocol_context_image IN protocol_context_image.id_protocol_context_image%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SELECT';
        pk_alertlog.log_debug(g_error);
    
        UPDATE protocol_context_image
           SET dt_img = current_timestamp, flg_status = g_img_active
         WHERE id_protocol_context_image = i_id_protocol_context_image
           AND flg_status = g_img_inactive;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'UPDATE_DATE_CONTEXT_IMAGE',
                                              o_error);
            -- rollback
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
    END update_date_context_image;

    /**
    * Public Function. Get list of images for a specific protocol
    *
    * @param      I_LANG                        Prefered language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_CONTEXT_IMAGE  ID of protocol image
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_CONTEXT_IMAGES
    * @param      O_ERROR                       error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/20
    */

    FUNCTION get_context_images
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_protocol_context_image IN protocol_context_image.id_protocol_context_image%TYPE,
        i_id_protocol               IN protocol_context_image.id_protocol%TYPE,
        o_context_images            OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_url VARCHAR2(2000);
    
    BEGIN
    
        g_error := 'GET CONTEXT IMAGES';
        pk_alertlog.log_debug(g_error);
    
        l_url := pk_sysconfig.get_config(g_url_context_image, i_prof);
    
        OPEN o_context_images FOR
            SELECT gci.id_protocol_context_image,
                   gci.id_protocol,
                   gci.file_name,
                   gci.img_desc,
                   gci.dt_img,
                   gci.flg_status,
                   --                   gci.img,
                   --                   gci.img_thumbnail,
                   REPLACE(REPLACE(REPLACE(l_url, '@1', gci.id_protocol), '@2', gci.id_protocol_context_image),
                           '@3',
                           '0') url,
                   REPLACE(REPLACE(REPLACE(l_url, '@1', gci.id_protocol), '@2', gci.id_protocol_context_image),
                           '@3',
                           '1') url_thumb
              FROM protocol_context_image gci
             WHERE gci.id_protocol_context_image = nvl(i_id_protocol_context_image, gci.id_protocol_context_image)
               AND gci.id_protocol = i_id_protocol
               AND gci.flg_status = g_active;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_CONTEXT_IMAGES',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_context_images);
            -- return failure of function
            RETURN FALSE;
    END get_context_images;

    /**
    * Public Function. Get image for a specific protocol
    *
    * @param      I_LANG                        Prefered language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                 ID of protocol.
    * @param      I_ID_PROTOCOL_CONTEXT_IMAGE   ID of protocol image
    * @param      I_THUMB                       0 - Image 1- Thumbnail
    * @param      O_CONTEXT_IMAGES              Image
    * @param      O_ERROR                       error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/20
    */
    FUNCTION get_blob
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_protocol               IN NUMBER,
        i_id_protocol_context_image IN NUMBER,
        i_thumb                     IN NUMBER,
        o_context_img               OUT BLOB,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_thumb = 0
        THEN
            g_error := 'GET IMAGE';
            pk_alertlog.log_debug(g_error);
        
            SELECT img
              INTO o_context_img
              FROM protocol_context_image
             WHERE id_protocol_context_image = i_id_protocol_context_image
               AND id_protocol = i_id_protocol;
        
            o_context_img := pk_tech_utils.set_empty_blob(o_context_img);
        ELSE
            g_error := 'GET IMAGE THUMBNAIL';
            pk_alertlog.log_debug(g_error);
        
            SELECT img_thumbnail
              INTO o_context_img
              FROM protocol_context_image
             WHERE id_protocol_context_image = i_id_protocol_context_image
               AND id_protocol = i_id_protocol;
        
            o_context_img := pk_tech_utils.set_empty_blob(o_context_img);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_BLOB',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
    END get_blob;

    /**
    * Public Function. Cancels an image or groups of images
    *
    * @param      I_LANG                        Prefered language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_CONTEXT_IMAGE  ID of protocol image
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_ERROR                       error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/20
    */

    FUNCTION cancel_context_image
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_protocol_context_image IN protocol_context_image.id_protocol_context_image%TYPE,
        i_id_protocol               IN protocol_context_image.id_protocol%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CONTEXT IMAGES';
        pk_alertlog.log_debug(g_error);
    
        UPDATE protocol_context_image
           SET flg_status = g_inactive
         WHERE id_protocol_context_image = i_id_protocol_context_image
           AND id_protocol = nvl(i_id_protocol, id_protocol);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_CONTEXT_IMAGE',
                                              o_error);
            -- rollback
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
    END cancel_context_image;

    /**
    * Return the parameters needed for the documents upload
    *
    * @param   I_LANG                       language associated to the professional executing the request
    * @param   I_PROF                       professional, institution and software ids
    * @param   O_CONTEXT_PATH               init path, path to copy files and max file size allowed
    * @param   O_ERROR                      an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Barros
    * @version 1.0
    * @since   2007/07/20
    */

    FUNCTION get_context_path
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        o_context_img_path OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_PROTOCOL_PATH';
        pk_alertlog.log_debug(g_error);
        OPEN o_context_img_path FOR
            SELECT pk_sysconfig.get_config(g_init, i_prof) path_doc_init,
                   pk_sysconfig.get_config(g_import, i_prof) path_doc_dest,
                   pk_sysconfig.get_config(g_file_max_size, i_prof) max_size
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_CONTEXT_PATH',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_context_img_path);
            -- return failure of function
            RETURN FALSE;
    END get_context_path;

BEGIN
    -- Generic
    g_available     := 'Y';
    g_not_available := 'N';
    g_active        := 'A';
    g_inactive      := 'I';

    -- Logging Mechanism
    pk_alertlog.who_am_i(g_log_object_owner, g_log_object_name);
    pk_alertlog.log_init(g_log_object_name);

    -- Image status
    g_img_inactive      := 'I';
    g_img_active        := 'A';
    g_url_context_image := 'URL_PROTOCOL_IMAGE';
    g_init              := 'PATH_PROTOCOL_INIT';
    g_import            := 'PATH_PROTOCOL_IMPORT';
    g_file_max_size     := 'DOC_FILE_MAX_SIZE';

END pk_protocol_attach;
/
