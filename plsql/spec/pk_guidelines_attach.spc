/*-- Last Change Revision: $Rev: 2028707 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_guidelines_attach IS
    /**
    * Public Function - Create context image
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                Guideline ID
    * @param      I_FILE_NAME                   File name of file to upload
    * @param      I_IMG_DESC                    Image description
    * @param      O_ID_GUIDELINE_CONTEXT_IMAGE  ID of Context image
    * @param      O_ERROR                       Error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION create_context_image
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_id_guideline               IN guideline.id_guideline%TYPE,
        i_file_name                  IN guideline_context_image.file_name%TYPE,
        i_img_desc                   IN guideline_context_image.img_desc%TYPE,
        o_id_guideline_context_image OUT guideline_context_image.id_guideline_context_image%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function - Upload images to database
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_CONTEXT_IMAGE  Guideline context image  ID
    * @param      O_IMG                         Image Blob
    * @param      O_IMG_THUMBNAIL               Image thumbnail Blob
    * @param      O_ERROR                       Error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION upload_context_image
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_id_guideline_context_image IN guideline_context_image.id_guideline_context_image%TYPE,
        o_img                        OUT BLOB,
        o_img_thumbnail              OUT BLOB,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function - Update date of context image insert
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_CONTEXT_IMAGE  Guideline context image  ID
    * @param      O_ERROR                       Error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION update_date_context_image
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_id_guideline_context_image IN guideline_context_image.id_guideline_context_image%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function - Get list of images for a specific guideline
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_CONTEXT_IMAGE  ID of guideline image
    * @param      I_ID_GUIDELINE                ID of guideline.
    * @param      O_CONTEXT_IMAGES              Image
    * @param      O_ERROR                       error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/04/12
    */

    FUNCTION get_context_images
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_id_guideline_context_image IN guideline_context_image.id_guideline_context_image%TYPE,
        i_id_guideline               IN guideline_context_image.id_guideline%TYPE,
        o_context_images             OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function - Get image for a specific guideline
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                ID of guideline.
    * @param      I_ID_GUIDELINE_CONTEXT_IMAGE  ID of guideline image
    * @param      I_THUMB                       0 - Image 1- Thumbnail
    * @param      O_CONTEXT_IMAGES              Image
    * @param      O_ERROR                       error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/04/12
    */
    FUNCTION get_blob
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_id_guideline               IN NUMBER,
        i_id_guideline_context_image IN NUMBER,
        i_thumb                      IN NUMBER,
        o_context_img                OUT BLOB,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function - Cancels an image or groups of images
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_CONTEXT_IMAGE  ID of guideline image
    * @param      I_ID_GUIDELINE                ID of guideline.
    * @param      O_ERROR                       error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/04/12
    */
    FUNCTION cancel_context_image
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_id_guideline_context_image IN guideline_context_image.id_guideline_context_image%TYPE,
        i_id_guideline               IN guideline_context_image.id_guideline%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return the parameters needed for the documents upload
    * 
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids
    * @param   O_CONTEXT_PATH init path, path to copy files and max file size allowed
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise (BOOLEAN)
    * @author  Sérgio Barros
    * @version 1.0 
    * @since   2007/04/16
    */
    FUNCTION get_context_path
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        o_context_img_path OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

    -- Generic
    g_active        VARCHAR2(1);
    g_inactive      VARCHAR2(1);
    g_available     VARCHAR2(1);
    g_not_available VARCHAR2(1);

    -- log mechanism
    g_log_object_owner VARCHAR2(50);
    g_log_object_name  VARCHAR2(50);

    -- Image status
    g_img_inactive VARCHAR2(1);
    g_img_active   VARCHAR2(1);

    g_url_context_image sys_config.id_sys_config%TYPE;
    g_init              sys_config.id_sys_config%TYPE;
    g_import            sys_config.id_sys_config%TYPE;
    g_file_max_size     sys_config.id_sys_config%TYPE;

END pk_guidelines_attach;
/
