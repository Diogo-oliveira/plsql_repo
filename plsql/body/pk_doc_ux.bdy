/*-- Last Change Revision: $Rev: 2047816 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-19 17:31:52 +0100 (qua, 19 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_ux IS

    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc_list   IN table_number,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_detail';
        IF NOT pk_doc.get_doc_detail(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_doc_list   => i_doc_list,
                                     o_doc_detail => o_doc_detail,
                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_doc_detail);
            RETURN FALSE;
    END get_doc_detail;

    FUNCTION get_doc_list_all
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'pk_doc.get_doc_list_all';
        IF NOT pk_doc.get_doc_list_all(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_episode => i_episode,
                                       i_ext_req => i_ext_req,
                                       i_btn     => i_btn,
                                       o_list    => o_list,
                                       o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_LIST_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_list_all;

    FUNCTION get_doc_comments
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_comments';
        IF NOT pk_doc.get_doc_comments(i_lang   => i_lang,
                                       i_prof   => i_prof,
                                       i_id_doc => i_id_doc,
                                       o_list   => o_list,
                                       o_error  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_COMMENTS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_comments;

    FUNCTION get_doc_images
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN NUMBER,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_images';
        IF NOT pk_doc.get_doc_images(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_id_doc     => i_id_doc,
                                     o_doc_images => o_doc_images,
                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_IMAGES',
                                              o_error);
            pk_types.open_my_cursor(o_doc_images);
            RETURN FALSE;
    END get_doc_images;

    FUNCTION get_doc_path
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_btn       IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_path  OUT pk_types.cursor_type,
        o_doc_files OUT pk_types.cursor_type,
        o_send_by   OUT pk_types.cursor_type,
        o_received  OUT pk_types.cursor_type,
        o_send_perm OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_path';
        IF NOT pk_doc.get_doc_path(i_lang      => i_lang,
                                   i_prof      => i_prof,
                                   i_btn       => i_btn,
                                   o_doc_path  => o_doc_path,
                                   o_doc_files => o_doc_files,
                                   o_send_by   => o_send_by,
                                   o_received  => o_received,
                                   o_send_perm => o_send_perm,
                                   o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_PATH',
                                              o_error);
            pk_types.open_my_cursor(o_doc_path);
            pk_types.open_my_cursor(o_doc_files);
            pk_types.open_my_cursor(o_send_by);
            pk_types.open_my_cursor(o_received);
            pk_types.open_my_cursor(o_send_perm);
            RETURN FALSE;
    END get_doc_path;

    FUNCTION get_doc_details
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_details';
        IF NOT pk_doc.get_doc_details(i_lang   => i_lang,
                                      i_prof   => i_prof,
                                      i_id_doc => i_id_doc,
                                      o_list   => o_list,
                                      o_error  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_DETAILS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_details;

    /**
    * Inicializar novo documento. Serve apenas para gerar um id_doc_external (chave da doc_external).
    * O registo com esse id e' usado pela top tier para ir armazenando as imagens. Os dados sao gravados
    * apenas quando se carrega no ok, o que vai chamar o update_closedoc. Ver mais info no create_savedoc.
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_ID_GRUPO  id que identifica as versoes deste documento
    * @param   I_INTERNAL_COMMIT commit/rollback is performed in this function
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   17-12-2007
    */
    FUNCTION create_initdoc
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN doc_external.id_patient%TYPE,
        i_episode         IN doc_external.id_episode%TYPE,
        i_ext_req         IN doc_external.id_external_request%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE,
        i_id_grupo        IN doc_external.id_grupo%TYPE,
        i_internal_commit IN BOOLEAN,
        o_id_doc          OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_doc.create_initdoc';
        IF NOT pk_doc.create_initdoc(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_patient         => i_patient,
                                     i_episode         => i_episode,
                                     i_ext_req         => i_ext_req,
                                     i_btn             => i_btn,
                                     i_id_grupo        => i_id_grupo,
                                     i_internal_commit => i_internal_commit,
                                     o_id_doc          => o_id_doc,
                                     o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_INITDOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_initdoc;

    FUNCTION cancel_images
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_ids_images IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_doc.cancel_images';
        IF NOT
            pk_doc.cancel_images(i_lang => i_lang, i_prof => i_prof, i_ids_images => i_ids_images, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_IMAGES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_images;

    FUNCTION cancel_image
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_img IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.cancel_image';
        IF NOT pk_doc.cancel_image(i_lang => i_lang, i_prof => i_prof, i_id_img => i_id_img, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_IMAGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_image;

    FUNCTION create_doc
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_doc_type          IN NUMBER,
        i_desc_doc_type     IN VARCHAR2,
        i_num_doc           IN VARCHAR2,
        i_dt_doc            IN DATE,
        i_dt_expire         IN DATE,
        i_orig_dest         IN NUMBER,
        i_desc_ori_dest     IN VARCHAR2,
        i_orig_type         IN NUMBER,
        i_desc_ori_doc_type IN VARCHAR2,
        i_notes             IN VARCHAR2,
        i_sent_by           IN doc_external.flg_sent_by%TYPE,
        i_original          IN NUMBER,
        i_desc_original     IN VARCHAR2,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        o_id_doc            OUT NUMBER,
        o_create_doc_msg    OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.create_doc';
        IF NOT pk_doc.create_doc(i_lang              => i_lang,
                                 i_prof              => i_prof,
                                 i_patient           => i_patient,
                                 i_episode           => i_episode,
                                 i_ext_req           => i_ext_req,
                                 i_doc_type          => i_doc_type,
                                 i_desc_doc_type     => i_desc_doc_type,
                                 i_num_doc           => i_num_doc,
                                 i_dt_doc            => i_dt_doc,
                                 i_dt_expire         => i_dt_expire,
                                 i_orig_dest         => i_orig_dest,
                                 i_desc_ori_dest     => i_desc_ori_dest,
                                 i_orig_type         => i_orig_type,
                                 i_desc_ori_doc_type => i_desc_ori_doc_type,
                                 i_notes             => i_notes,
                                 i_sent_by           => i_sent_by,
                                 i_original          => i_original,
                                 i_desc_original     => i_desc_original,
                                 i_btn               => i_btn,
                                 o_id_doc            => o_id_doc,
                                 o_create_doc_msg    => o_create_doc_msg,
                                 o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_doc;

    FUNCTION get_doc_options
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_types     OUT pk_types.cursor_type,
        o_doc_specs     OUT pk_types.cursor_type,
        o_doc_originals OUT pk_types.cursor_type,
        o_doc_dest      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_options';
        IF NOT pk_doc.get_doc_options(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => i_episode,
                                      i_ext_req       => i_ext_req,
                                      i_btn           => i_btn,
                                      o_doc_types     => o_doc_types,
                                      o_doc_specs     => o_doc_specs,
                                      o_doc_originals => o_doc_originals,
                                      o_doc_dest      => o_doc_dest,
                                      o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_OPTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_doc_types);
            pk_types.open_my_cursor(o_doc_specs);
            pk_types.open_my_cursor(o_doc_originals);
            pk_types.open_my_cursor(o_doc_dest);
            RETURN FALSE;
    END get_doc_options;

    FUNCTION cancel_doc
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.cancel_doc';
        IF NOT pk_doc.cancel_doc(i_lang => i_lang, i_prof => i_prof, i_id_doc => i_id_doc, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_doc;

    FUNCTION get_doc_archive_area
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_doc_archive_areas   OUT pk_types.cursor_type,
        o_doc_archive_area_op OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_archive_area';
        IF NOT pk_doc.get_doc_archive_area(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           o_doc_archive_areas   => o_doc_archive_areas,
                                           o_doc_archive_area_op => o_doc_archive_area_op,
                                           o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_ARCHIVE_AREA',
                                              o_error);
            pk_types.open_my_cursor(o_doc_archive_areas);
            pk_types.open_my_cursor(o_doc_archive_area_op);
            RETURN FALSE;
    END get_doc_archive_area;

    FUNCTION get_categories
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_categories';
        IF NOT pk_doc.get_categories(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CATEGORIES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_categories;

    FUNCTION get_doc_images_list
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN table_number,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_images_list';
        IF NOT pk_doc.get_doc_images_list(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_doc     => i_id_doc,
                                          o_doc_images => o_doc_images,
                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_IMAGES_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_doc_images);
            RETURN FALSE;
    END get_doc_images_list;

    FUNCTION cancel_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_comments IN doc_comments.id_doc_comment%TYPE,
        i_type_reg        IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.cancel_comments';
        IF NOT pk_doc.cancel_comments(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_doc_comments => i_id_doc_comments,
                                      i_type_reg        => i_type_reg,
                                      o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_COMMENTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_comments;

    FUNCTION get_document_count_by_category
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_document_count_by_category';
        IF NOT pk_doc.get_document_count_by_category(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_pat     => i_pat,
                                                     i_episode => i_episode,
                                                     i_ext_req => i_ext_req,
                                                     i_btn     => i_btn,
                                                     o_list    => o_list,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCUMENT_COUNT_BY_CATEGORY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_document_count_by_category;

    FUNCTION set_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_id_image        IN doc_image.id_doc_image%TYPE,
        i_desc_comment    IN doc_comments.desc_comment%TYPE,
        i_date_comment    IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_doc.set_comments';
        IF NOT pk_doc.set_comments(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_id_doc_external => i_id_doc_external,
                                   i_id_image        => i_id_image,
                                   i_desc_comment    => i_desc_comment,
                                   i_date_comment    => i_date_comment,
                                   o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_COMMENTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_comments;

    FUNCTION validate_doc_upload
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_docs_info  IN table_table_varchar,
        o_doc_upload OUT table_table_varchar,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'pk_doc.validate_doc_upload';
        IF NOT pk_doc.validate_doc_upload(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_docs_info  => i_docs_info,
                                          o_doc_upload => o_doc_upload,
                                          o_flg_show   => o_flg_show,
                                          o_msg        => o_msg,
                                          o_msg_title  => o_msg_title,
                                          o_button     => o_button,
                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'VALIDATE_DOC_UPLOAD',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END validate_doc_upload;

    FUNCTION update_titles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_ids_images IN table_number,
        i_titles     IN table_varchar,
        o_ids_images OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.update_titles';
        IF NOT pk_doc.update_titles(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_ids_images => i_ids_images,
                                    i_titles     => i_titles,
                                    o_ids_images => o_ids_images,
                                    o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TITLES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_titles;

    FUNCTION get_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_types';
        IF NOT pk_doc.get_doc_types(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_patient      => i_patient,
                                    i_episode      => i_episode,
                                    i_ext_req      => i_ext_req,
                                    i_btn          => i_btn,
                                    i_doc_ori_type => i_doc_ori_type,
                                    o_list         => o_list,
                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_TYPES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_types;

    FUNCTION create_savedoc
    (
        i_id_doc             IN doc_external.id_doc_external%TYPE,
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN doc_external.id_patient%TYPE,
        i_episode            IN doc_external.id_episode%TYPE,
        i_ext_req            IN doc_external.id_external_request%TYPE,
        i_doc_type           IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type      IN doc_external.desc_doc_type%TYPE,
        i_num_doc            IN doc_external.num_doc%TYPE,
        i_dt_doc             IN doc_external.dt_emited%TYPE,
        i_dt_expire          IN doc_external.dt_expire%TYPE,
        i_dest               IN doc_external.id_doc_destination%TYPE,
        i_desc_dest          IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type       IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type  IN doc_external.desc_doc_ori_type%TYPE,
        i_original           IN doc_external.id_doc_original%TYPE,
        i_desc_original      IN doc_external.desc_doc_original%TYPE,
        i_btn                IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title              IN doc_external.title%TYPE,
        i_flg_sent_by        IN doc_external.flg_sent_by%TYPE,
        i_flg_received       IN doc_external.flg_received%TYPE,
        i_prof_perf_by       IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by       IN doc_external.desc_perf_by%TYPE,
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_desc_language      IN doc_external.desc_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_local_emitted      IN doc_external.local_emited%TYPE,
        i_doc_oid            IN doc_external.doc_oid%TYPE,
        i_internal_commit    IN BOOLEAN,
        i_notes              IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_doc.create_savedoc';
        IF NOT pk_doc.create_savedoc(i_id_doc             => i_id_doc,
                                     i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_patient            => i_patient,
                                     i_episode            => i_episode,
                                     i_ext_req            => i_ext_req,
                                     i_doc_type           => i_doc_type,
                                     i_desc_doc_type      => i_desc_doc_type,
                                     i_num_doc            => i_num_doc,
                                     i_dt_doc             => i_dt_doc,
                                     i_dt_expire          => i_dt_expire,
                                     i_dest               => i_dest,
                                     i_desc_dest          => i_desc_dest,
                                     i_ori_doc_type       => i_ori_doc_type,
                                     i_desc_ori_doc_type  => i_desc_ori_doc_type,
                                     i_original           => i_original,
                                     i_desc_original      => i_desc_original,
                                     i_btn                => i_btn,
                                     i_title              => i_title,
                                     i_flg_sent_by        => i_flg_sent_by,
                                     i_flg_received       => i_flg_received,
                                     i_prof_perf_by       => i_prof_perf_by,
                                     i_desc_perf_by       => i_desc_perf_by,
                                     i_author             => i_author,
                                     i_specialty          => i_specialty,
                                     i_doc_language       => i_doc_language,
                                     i_desc_language      => i_desc_language,
                                     i_flg_publish        => i_flg_publish,
                                     i_conf_code          => i_conf_code,
                                     i_desc_conf_code     => i_desc_conf_code,
                                     i_code_coding_schema => i_code_coding_schema,
                                     i_conf_code_set      => i_conf_code_set,
                                     i_desc_conf_code_set => i_desc_conf_code_set,
                                     i_local_emitted      => i_local_emitted,
                                     i_doc_oid            => i_doc_oid,
                                     i_internal_commit    => i_internal_commit,
                                     i_notes              => i_notes,
                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SAVEDOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_savedoc;

    FUNCTION create_document
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_doc               IN doc_external.id_doc_external%TYPE,
        i_ext_req              IN doc_external.id_external_request%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_DOC.CREATE_DOCUMENT';
        IF NOT pk_doc.create_document(i_lang                 => i_lang,
                                      i_prof                 => i_prof,
                                      i_id_episode           => i_id_episode,
                                      i_id_patient           => i_id_patient,
                                      i_id_doc               => i_id_doc,
                                      i_ext_req              => i_ext_req,
                                      i_tbl_ds_internal_name => i_tbl_ds_internal_name,
                                      i_tbl_val              => i_tbl_val,
                                      i_tbl_real_val         => i_tbl_real_val,
                                      o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DOCUMENT',
                                              o_error);
            RETURN FALSE;
    END create_document;

    FUNCTION update_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_doc             IN NUMBER,
        i_doc_type           IN NUMBER,
        i_desc_doc_type      IN VARCHAR2,
        i_num_doc            IN VARCHAR2,
        i_dt_doc             IN DATE,
        i_dt_expire          IN DATE,
        i_orig_dest          IN NUMBER,
        i_desc_ori_dest      IN VARCHAR2,
        i_orig_type          IN NUMBER,
        i_desc_ori_doc_type  IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_sent_by            IN doc_external.flg_sent_by%TYPE,
        i_received           IN doc_external.flg_received%TYPE,
        i_original           IN NUMBER,
        i_desc_original      IN VARCHAR2,
        i_btn                IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title              IN doc_external.title%TYPE,
        i_prof_perf_by       IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by       IN doc_external.desc_perf_by%TYPE,
        i_author             IN doc_external.author%TYPE,
        i_specialty          IN doc_external.id_specialty%TYPE,
        i_doc_language       IN doc_external.id_language%TYPE,
        i_flg_publish        IN VARCHAR2,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_notes_upd          IN VARCHAR2,
        o_id_doc_external    OUT doc_external.id_doc_external%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_doc.update_doc';
        IF NOT pk_doc.update_doc(i_lang               => i_lang,
                                 i_prof               => i_prof,
                                 i_id_doc             => i_id_doc,
                                 i_doc_type           => i_doc_type,
                                 i_desc_doc_type      => i_desc_doc_type,
                                 i_num_doc            => i_num_doc,
                                 i_dt_doc             => i_dt_doc,
                                 i_dt_expire          => i_dt_expire,
                                 i_orig_dest          => i_orig_dest,
                                 i_desc_ori_dest      => i_desc_ori_dest,
                                 i_orig_type          => i_orig_type,
                                 i_desc_ori_doc_type  => i_desc_ori_doc_type,
                                 i_notes              => i_notes,
                                 i_sent_by            => i_sent_by,
                                 i_received           => i_received,
                                 i_original           => i_original,
                                 i_desc_original      => i_desc_original,
                                 i_btn                => i_btn,
                                 i_title              => i_title,
                                 i_prof_perf_by       => i_prof_perf_by,
                                 i_desc_perf_by       => i_desc_perf_by,
                                 i_author             => i_author,
                                 i_specialty          => i_specialty,
                                 i_doc_language       => i_doc_language,
                                 i_desc_language      => NULL,
                                 i_flg_publish        => i_flg_publish,
                                 i_conf_code          => i_conf_code,
                                 i_desc_conf_code     => i_desc_conf_code,
                                 i_code_coding_schema => i_code_coding_schema,
                                 i_conf_code_set      => i_conf_code_set,
                                 i_desc_conf_code_set => i_desc_conf_code_set,
                                 i_notes_upd          => i_notes_upd,
                                 o_id_doc_external    => o_id_doc_external,
                                 o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DOC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_doc;

    FUNCTION update_document
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_doc               IN doc_external.id_doc_external%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_DOC.UPDATE_DOCUMENT';
        IF NOT pk_doc.update_document(i_lang                 => i_lang,
                                      i_prof                 => i_prof,
                                      i_id_doc               => i_id_doc,
                                      i_tbl_ds_internal_name => i_tbl_ds_internal_name,
                                      i_tbl_val              => i_tbl_val,
                                      i_tbl_real_val         => i_tbl_real_val,
                                      o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DOCUMENT',
                                              o_error);
            RETURN FALSE;
    END update_document;

    FUNCTION get_blob
    (
        i_id_doc  IN NUMBER,
        i_id_page IN NUMBER,
        i_thumb   IN NUMBER,
        i_prof    IN profissional,
        o_doc_img OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_DOC.GET_BLOB';
        IF NOT pk_doc.get_blob(i_id_doc  => i_id_doc,
                               i_id_page => i_id_page,
                               i_thumb   => i_thumb,
                               i_prof    => i_prof,
                               o_doc_img => o_doc_img,
                               o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_blob;

    FUNCTION get_doc_image_props
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_img        IN NUMBER,
        o_doc_img_props OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_DOC.GET_DOC_IMAGE_PROPS';
        IF NOT pk_doc.get_doc_image_props(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_id_img        => i_id_img,
                                          o_doc_img_props => o_doc_img_props,
                                          o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_IMAGE_PROPS',
                                              o_error);
            pk_types.open_my_cursor(o_doc_img_props);
        
            RETURN FALSE;
    END get_doc_image_props;

    FUNCTION get_doc_images_subset
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_doc_list       IN table_number,
        i_start_point       IN NUMBER,
        i_quantity          IN NUMBER,
        o_doc_images_subset OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'pk_doc.get_doc_images_subset';
        IF NOT pk_doc.get_doc_images_subset(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_doc_list       => i_id_doc_list,
                                            i_start_point       => i_start_point,
                                            i_quantity          => i_quantity,
                                            o_doc_images_subset => o_doc_images_subset,
                                            o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_IMAGES_SUBSET',
                                              o_error);
            pk_types.open_my_cursor(o_doc_images_subset);
            RETURN FALSE;
    END get_doc_images_subset;

    /**
    * lista de opçoes para o multi-choice do novo documento
    *
    * @param   i_lang      id da lingua
    * @param   o_val       lista das opcoes
    * @param   o_error     mensagem de erro
    *
    * @RETURN  TRUE sucesso ou FALSE erro
    * @author  Telmo Castro
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_doc_add
    (
        i_lang  IN language.id_language%TYPE,
        o_val   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_add';
        IF NOT pk_doc.get_doc_add(i_lang => i_lang, o_val => o_val, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_ADD',
                                              o_error);
            pk_types.open_my_cursor(o_val);
            RETURN FALSE;
    END get_doc_add;

    FUNCTION get_tl_doc_ori_types
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_patient      IN doc_external.id_patient%TYPE,
        i_id_episode      IN doc_external.id_episode%TYPE,
        i_id_sys_btn_prop IN doc_types_config.id_sys_button_prop%TYPE,
        o_result          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_tl_doc_ori_types';
        IF NOT pk_doc.get_tl_doc_ori_types(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_id_patient,
                                           i_id_episode      => i_id_episode,
                                           i_id_sys_btn_prop => i_id_sys_btn_prop,
                                           o_result          => o_result,
                                           o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TL_DOC_ORI_TYPES',
                                              o_error);
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_tl_doc_ori_types;

    FUNCTION get_tl_scale
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_patient        IN doc_external.id_patient%TYPE,
        i_id_episode        IN doc_external.id_episode%TYPE,
        i_ids_doc_ori_types IN table_number,
        o_scale             OUT pk_types.cursor_type,
        o_patient_info      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_tl_scale';
        IF NOT pk_doc.get_tl_scale(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_id_patient        => i_id_patient,
                                   i_id_episode        => i_id_episode,
                                   i_ids_doc_ori_types => i_ids_doc_ori_types,
                                   o_scale             => o_scale,
                                   o_patient_info      => o_patient_info,
                                   o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TL_SCALE',
                                              o_error);
            pk_types.open_my_cursor(o_scale);
            pk_types.open_my_cursor(o_patient_info);
            RETURN FALSE;
    END get_tl_scale;

    FUNCTION get_tl_grid
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_tl_scale      IN tl_scale.id_tl_scale%TYPE,
        i_block_req_number IN NUMBER,
        i_request_date     IN VARCHAR2,
        i_direction        IN VARCHAR2 DEFAULT 'B',
        o_x_data           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_tl_grid';
        IF NOT pk_doc.get_tl_grid(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_id_tl_scale      => i_id_tl_scale,
                                  i_block_req_number => i_block_req_number,
                                  i_request_date     => i_request_date,
                                  i_direction        => i_direction,
                                  o_x_data           => o_x_data,
                                  o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TL_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_x_data);
            RETURN FALSE;
    END get_tl_grid;

    FUNCTION get_tl_data
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_patient        IN doc_external.id_patient%TYPE,
        i_id_episode        IN doc_external.id_episode%TYPE,
        i_ids_doc_ori_types IN table_number,
        i_id_tl_scale       IN tl_scale.id_tl_scale%TYPE,
        o_result            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_tl_data';
        IF NOT pk_doc.get_tl_data(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_id_patient        => i_id_patient,
                                  i_id_episode        => i_id_episode,
                                  i_ids_doc_ori_types => i_ids_doc_ori_types,
                                  i_id_tl_scale       => i_id_tl_scale,
                                  o_result            => o_result,
                                  o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TL_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_tl_data;

    FUNCTION get_doc_type_groups
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_doc_types_groups OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_type_groups';
        IF NOT pk_doc.get_doc_type_groups(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_patient          => i_patient,
                                          i_episode          => i_episode,
                                          o_doc_types_groups => o_doc_types_groups,
                                          o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_TYPE_GROUPS',
                                              o_error);
            pk_types.open_my_cursor(o_doc_types_groups);
            RETURN FALSE;
    END get_doc_type_groups;

    FUNCTION get_doc_in_type_groups
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_doc          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_in_type_groups';
        IF NOT pk_doc.get_doc_in_type_groups(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_episode      => i_episode,
                                             i_doc_ori_type => i_doc_ori_type,
                                             o_doc          => o_doc,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_IN_TYPE_GROUPS',
                                              o_error);
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END get_doc_in_type_groups;

    /**
    * Get detail list for the viewer 'with me' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    */
    FUNCTION get_doc_list_me
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_list_me';
        IF NOT pk_doc.get_doc_list_me(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_patient => i_patient,
                                      i_episode => i_episode,
                                      i_ext_req => i_ext_req,
                                      i_btn     => i_btn,
                                      o_list    => o_list,
                                      o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_LIST_ME',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_list_me;

    FUNCTION get_doc_list_epis
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_list_epis';
        IF NOT pk_doc.get_doc_list_epis(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => i_patient,
                                        i_episode => i_episode,
                                        i_ext_req => i_ext_req,
                                        i_btn     => i_btn,
                                        o_list    => o_list,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_LIST_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_list_epis;

    FUNCTION get_doc_list_last10
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        i_quant   IN NUMBER DEFAULT 10,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_list_last10';
        IF NOT pk_doc.get_doc_list_last10(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          i_patient => i_patient,
                                          i_episode => i_episode,
                                          i_ext_req => i_ext_req,
                                          i_btn     => i_btn,
                                          i_quant   => i_quant,
                                          o_list    => o_list,
                                          o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_LIST_LAST10',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_list_last10;

    FUNCTION get_doc_viewer_all
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_viewer_all';
        IF NOT pk_doc.get_doc_viewer_all(i_lang    => i_lang,
                                         i_prof    => i_prof,
                                         i_patient => i_patient,
                                         i_episode => i_episode,
                                         i_ext_req => i_ext_req,
                                         i_btn     => i_btn,
                                         o_list    => o_list,
                                         o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_VIEWER_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_viewer_all;

    FUNCTION get_doc_viewer_epis
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_viewer_epis';
        IF NOT pk_doc.get_doc_viewer_epis(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          i_patient => i_patient,
                                          i_episode => i_episode,
                                          i_ext_req => i_ext_req,
                                          i_btn     => i_btn,
                                          o_list    => o_list,
                                          o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_VIEWER_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_viewer_epis;

    FUNCTION get_doc_viewer_last10
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        i_quant   IN NUMBER DEFAULT 10,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_viewer_last10';
        IF NOT pk_doc.get_doc_viewer_last10(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_episode => i_episode,
                                            i_ext_req => i_ext_req,
                                            i_btn     => i_btn,
                                            i_quant   => i_quant,
                                            o_list    => o_list,
                                            o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_VIEWER_LAST10',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_viewer_last10;

    FUNCTION get_doc_viewer_me
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_doc_viewer_me';
        IF NOT pk_doc.get_doc_viewer_me(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => i_patient,
                                        i_episode => i_episode,
                                        i_ext_req => i_ext_req,
                                        i_btn     => i_btn,
                                        o_list    => o_list,
                                        o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_VIEWER_ME',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_doc_viewer_me;

    FUNCTION get_viewer_doc_archive_cat
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        i_id_doc_type     IN doc_type.id_doc_type%TYPE,
        io_current_level  IN OUT NUMBER,
        o_viewer_info     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_viewer_doc_archive_cat';
        IF NOT pk_doc.get_viewer_doc_archive_cat(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_patient         => i_patient,
                                                 i_episode         => i_episode,
                                                 i_id_doc_ori_type => i_id_doc_ori_type,
                                                 i_id_doc_type     => i_id_doc_type,
                                                 io_current_level  => io_current_level,
                                                 o_viewer_info     => o_viewer_info,
                                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VIEWER_DOC_ARCHIVE_CAT',
                                              o_error);
            pk_types.open_my_cursor(o_viewer_info);
            RETURN FALSE;
    END get_viewer_doc_archive_cat;

    FUNCTION get_viewer_doc_archive
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        io_current_level  IN OUT NUMBER,
        o_viewer_info     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_viewer_doc_archive';
        IF NOT pk_doc.get_viewer_doc_archive(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_patient         => i_patient,
                                             i_episode         => i_episode,
                                             i_id_doc_ori_type => i_id_doc_ori_type,
                                             io_current_level  => io_current_level,
                                             o_viewer_info     => o_viewer_info,
                                             o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VIEWER_DOC_ARCHIVE',
                                              o_error);
            pk_types.open_my_cursor(o_viewer_info);
            RETURN FALSE;
    END get_viewer_doc_archive;

    FUNCTION get_default_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        o_doc_ori_type OUT NUMBER,
        o_doc_type     OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_doc.get_default_doc_types';
        IF NOT pk_doc.get_default_doc_types(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_area         => i_area,
                                            o_doc_type     => o_doc_type,
                                            o_doc_ori_type => o_doc_ori_type,
                                            o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEFAULT_DOC_TYPES',
                                              o_error);
            RETURN FALSE;
    END get_default_doc_types;

    FUNCTION get_main_thumb_url
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_id_doc    IN NUMBER,
        o_thumb_url OUT VARCHAR2,
        o_count_img OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error     := 'pk_doc.get_main_thumb_url';
        o_thumb_url := pk_doc.get_main_thumb_url(i_lang => i_lang, i_prof => i_prof, i_id_doc => i_id_doc);
    
        g_error     := 'pk_doc.get_main_thumb_url';
        o_count_img := pk_doc.get_count_image(i_lang => i_lang, i_prof => i_prof, i_doc_external => i_id_doc);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MAIN_THUMB_URL',
                                              o_error);
            RETURN FALSE;
    END get_main_thumb_url;

    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        i_flg_action IN VARCHAR2,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_DOC.GET_DOC_DETAIL';
        IF NOT pk_doc.get_document_detail(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_doc        => i_doc,
                                          o_doc_detail => o_doc_detail,
                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_doc_detail);
            RETURN FALSE;
    END get_doc_detail;

    FUNCTION get_cda_reconciliation_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_codes             IN table_varchar,
        i_doc_oid           IN VARCHAR2,
        i_doc_source        IN VARCHAR2,
        o_msg_array         OUT pk_types.cursor_type,
        o_patient_info      OUT VARCHAR2,
        o_doc_sections      OUT pk_types.cursor_type,
        o_id_reconciliation OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_DOC.GET_CDA_RECONCILIATION_INFO';
        IF NOT pk_doc.get_cda_reconciliation_info(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_patient        => i_id_patient,
                                                  i_codes             => i_codes,
                                                  i_doc_oid           => i_doc_oid,
                                                  i_doc_source        => i_doc_source,
                                                  o_msg_array         => o_msg_array,
                                                  o_patient_info      => o_patient_info,
                                                  o_doc_sections      => o_doc_sections,
                                                  o_id_reconciliation => o_id_reconciliation,
                                                  o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CDA_RECONCILIATION_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_msg_array);
            pk_types.open_my_cursor(o_doc_sections);
            RETURN FALSE;
    END get_cda_reconciliation_info;

BEGIN

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);

    pk_alertlog.log_init(owner => g_package_owner, object_name => g_package_name);

END pk_doc_ux;
/
