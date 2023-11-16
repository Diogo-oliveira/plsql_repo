/*-- Last Change Revision: $Rev: 2047816 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-19 17:31:52 +0100 (qua, 19 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc_ux IS

    -- Log variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_exception     EXCEPTION;
    g_error         VARCHAR2(1000 CHAR);

    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc_list   IN table_number,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get detail list (central pane) for the viewer 'all' filter
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
    * @since   20-12-2007
    */
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
    ) RETURN BOOLEAN;

    /**
    * Devolve lista de notas/interpretacoes dum documento
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id do qual se pretende obter as notas
    * @param o_list             lista das notas
    * @param o_error             an error message
    *
    * @version 1.0
    * @author Telmo Castro
    * @date   26-12-2007 
    */
    FUNCTION get_doc_comments
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retornar lista de imagens do documento
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    *
    * UPDATED - title incluido no output
    * @author Telmo Castro
    * @date   20-12-2007 
    *
    * UPDATED - created an internal to return a subset of results from a list of documents (from a requirment from JG to the coverflow).
    * @author Daniel Silva
    * @date  2013.09.05 
    */
    FUNCTION get_doc_images
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN NUMBER,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return the parameters needed for the documents upload
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_DOC_PATH init path, path to copy files and max file size allowed
    * @param   O_DOC_FILES allowed files types (name and file extensions)
    * @param   O_SEND_BY list of sending modes
    * @param   O_RECEIVE list of receiving status    
    * @param   O_SEND_PERM sending permissions for this profile
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   16-03-2006
    */
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
    ) RETURN BOOLEAN;

    /**
    * dá o detalhe do documento, mas agora na forma de 1 lista com todas as versoes deste documento
    * ordenadas cronologicamente. O primeiro da lista deve estar activo e por isso ser a versao actual.
    * @param i_lang     linguagem pedida
    * @param i_prof     ids do profissional
    * @param i_id_doc   id do documento pretendido
    * @param o_list     lista do resultado
    * @param o_error    error message, if any
    *
    * @return TRUE if sucess, FALSE otherwise 
    * @author  Telmo Castro
    * @version 1.0
    * @date    08-01-2007
    */
    FUNCTION get_doc_details
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /**
    * Cancelar lista de imagens
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ids_images lista com ids das imagens
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   24-12-2007
    */
    FUNCTION cancel_images
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_ids_images IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a image
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_IMG  image id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   22-11-2006
    *
    * UPDATED - novos campos dt_cancel e id_prof_cancel. Delete no caso do documento estar pendente
    * @author  Telmo Castro
    * @date    19-12-2007
    *
    * UPDATED - invocar pk_visit.set_first_obs
    * @author Telmo Castro
    * @date   18-01-2008
    */
    FUNCTION cancel_image
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_img IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Inserir documento
       PARAMETROS:  Entrada: I_LANG      - Língua registada como preferência do profissional
                             I_PROF  - Profissional, instituição, software
                             I_CODE  - Id do P1
                             I_DOC_TYPE  - Id da caracterização do documento
                             I_NUM_DOC   - Numero do documento
                             I_DT_DOC  - Data do documento
                             I_ORIG_DEST - Destino do documento original
                             I_ORIG_TYPE - Id do Tipo do documento
                             I_ORIGINAL - Id do tipo de original,
                             I_DESC_ORIGINAL - Descrição manual do tipo de original.
    
                Saida:   O_ERROR   - erro
    
      CRIAÇÃO: JS 2006/03/15
      CORRECÇÕES: LG 2007/fev/03 - adição de novo campo doc_original
      NOTAS:
    *********************************************************************************/
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
    ) RETURN BOOLEAN;

    /**
    * Gets doc_ori_types list
    * 
    * @param   i_lang language 
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_types list of doc types
    * @param   o_doc_ori_types list of doc_ori_types    
    * @param   o_doc_originals list of doc_originals    
    * @param   o_doc_dest list of destinations    
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
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
    ) RETURN BOOLEAN;

    /**
    * Cancels a document
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_DOC  document id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   22-11-2006
    *
    * UPDATED  invocar pk_visit.set_first_obs
    * @author  Telmo Castro
    * @date    18-01-2008
    */
    FUNCTION cancel_doc
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_PROF                   Professional (id, institution, software)
    * @param O_DOC_ARCHIVE_AREAS      Areas available for professionals
    * @param O_DOC_ARCHIVE_AREA_OP    Operations available in each area by professional
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jorge Costa
    * @version                        2.6.4.2
    * @since                          10-09-2014
    ********************************************************************************************/
    FUNCTION get_doc_archive_area
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_doc_archive_areas   OUT pk_types.cursor_type,
        o_doc_archive_area_op OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_categories
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_images_list
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN table_number,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   cancelar um comentario
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios 
                             I_ID_DOC_COMMENTS   - Id do comentario a cancelar
                             I_Type_Reg          - Tipo de cancelamento: E - Editar, C - Cancelar
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/17
      
      * UPDATED - invocacao do pk_visit.set_first_obs
      * @author   Telmo Castro
      * @date     18-01-2008
    *********************************************************************************/
    FUNCTION cancel_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_comments IN doc_comments.id_doc_comment%TYPE,
        i_type_reg        IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Inserir comentarios a um documento ou imagem
       Neste momento as imagens nao tem comentarios mas o codigo fica preparado para se nalgum momento
       passarem a existir comentarios a imagens especificas
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios 
                             I_ID_DOC_EXTERNAL   - Id do documento
                             I_DOC_IMAGE         - Id da imagem
    
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/17
    
      * UPDATED: invocacao da pk_visit.set_first_obs
      * @author  Telmo Castro
      * @date    18-01-2008 
    *********************************************************************************/
    FUNCTION set_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_id_image        IN doc_image.id_doc_image%TYPE,
        i_desc_comment    IN doc_comments.desc_comment%TYPE,
        i_date_comment    IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate the upload of selected documents. In this case, two diferent validations are being done:
    *          1 - maximun document size, per document
    *          2 - maximum quota size for documents upload, per institution
    *
    * @ param i_lang                  Preferred language ID for this professional 
    * @ param i_prof                  Object (professional ID, institution ID, software ID)
    * @ param i_docs_info             List of documents to upload (id, name, size)
    * @ param o_doc_upload            Documents uploaded (id, Y/N) - indicates if the documents 
    *                                 were successfully uploaded
    * @ param o_flg_show              Indication of Warning message              
    * @ param o_msg                   Warning message text
    * @ param o_msg_title             Warning message title
    * @ param o_button                Warning message buttons
    * @ param o_error                 Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/18
    **********************************************************************************************/
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
    ) RETURN BOOLEAN;

    /**
    * update do titulo em varias imagens. Para ser usado pelo botao Apply title to all images.
    * 
    * @param i_lang            IN id da lingua
    * @param i_prof            IN profissional data
    * @param i_ids_images      IN ids das imagens
    * @param i_titles          IN novos titulos
    * @param o_ids_images      OUT id do novo registo
    * @param o_error           OUT mensagem de erro (se result = 0)
    *
    * @return true (sucess), false (error)
    * @created 28-12-2007
    * @author Telmo Castro
    * @version 1.0
    *
    * @updated 31-12-2007
    * @author Telmo Castro 
    * i_title passa a ser uma table_varchar. O indice das nested tables une i_ids_images com i_titles
    */
    FUNCTION update_titles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_ids_images IN table_number,
        i_titles     IN table_varchar,
        o_ids_images OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION update_document
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_doc               IN doc_external.id_doc_external%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return a subset of images from a document list (lazy loading)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_list       list of document ids
    * @param i_start_point       subset starting point
    * @param i_quantity          number of results to return
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 2013.09.05
    * @author daniel.silva
    */
    FUNCTION get_doc_images_subset
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_doc_list       IN table_number,
        i_start_point       IN NUMBER,
        i_quantity          IN NUMBER,
        o_doc_images_subset OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * OBJECTIVO:   Retornar imagem do documento
    * PARAMETROS:  
    *   Entrada: 
    *        I_LANG - Idioma
    *        I_ID_DOC - Id do documento
    *        I_ID_PAGE - Numero de pagina
    *   Saida: 
    *        O_DOC_IMG - imagem
    *        O_ERROR - erro
    *   
    *  CRIAÇÃO: JS 2006/03/16
    *  NOTAS:
    */

    FUNCTION get_blob
    (
        i_id_doc  IN NUMBER,
        i_id_page IN NUMBER,
        i_thumb   IN NUMBER,
        i_prof    IN profissional,
        o_doc_img OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get doc_image properties (file_name, mime_type)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_img            image id
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    */

    FUNCTION get_doc_image_props
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_img        IN NUMBER,
        o_doc_img_props OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*
    * returns list of all doc_ori_types visible to professional i_prof.
    * For each type there's also a counter that tells how many documents belonging to patient i_id_patient exist.
    *
    * @param i_lang            language associated to the professional executing the request
    * @param i_prof            professional, institution and software ids
    * @param i_id_patient      patient id
    * @param i_id_episode      episode id. If supplied then the doc count is narrowed to id_patient AND id_episode. If not, only by id_patient
    * @param i_id_sys_btn_prop screen where this function is called influences which doc ori types are visible
    * @param o_result          output cursor
    * @param o_error           error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   19-12-2011
    */
    FUNCTION get_tl_doc_ori_types
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_patient      IN doc_external.id_patient%TYPE,
        i_id_episode      IN doc_external.id_episode%TYPE,
        i_id_sys_btn_prop IN doc_types_config.id_sys_button_prop%TYPE,
        o_result          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns scale info to build the screen background grid, the lower scale buttons(decade, year, month, etc.).
    * Also returns other info like lowest date patient doc and system date.
    * This is a wrapper for pk_timeline.get_tasks_time_scale.
    *
    * @param i_lang            language associated to the professional executing the request
    * @param i_prof            professional, institution and software ids
    * @param i_id_patient      patient id
    * @param i_id_episode      episode id. can be null. If not null, only documents related to this episode are considered
    * @param i_ids_doc_ori_types list of doc_ori_types that are currently selected 
    * @param o_scale           data to build the background, its scale, grid lines, etc.
    * @param o_patient_info    other useful data
    * @param o_error           error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   20-12-2011
    */
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
    ) RETURN BOOLEAN;

    /* this carries all data needed to draw the grid lines, columns and its headers. 
    * This is a wrapper for pk_timeline_core.get_timeline_data.
    *
    * @param i_lang            language associated to the professional executing the request
    * @param i_prof            professional, institution and software ids
    * @param i_id_tl_scale     smallest time block. Can be decade, year, etc.
    * @param i_block_req_number how many blocks of tl_scale are needed
    * @param i_request_date    
    * @param i_direction       default B (both)
    * @param o_result          output
    * @param o_error           error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   21-12-2011
    */
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_doc_type_groups
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_doc_types_groups OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_in_type_groups
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_doc          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /**
    * Get detail list for the viewer 'episode' filter
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
    ) RETURN BOOLEAN;

    /**
    * Get detail list (central pane) for the viewer 'last 10' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_QUANT   considera apenas os ultimos I_QUANT episodios
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    */
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
    ) RETURN BOOLEAN;

    /**
    * Get ori type list for the viewer 'all' filter
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
    * @since   17-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
    */
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
    ) RETURN BOOLEAN;

    /**
     * Get ori type list for the viewer 'episode' filter
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
     * @since   17-12-2007
     *
     * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
     * @author Telmo Castro
     * @since  11-01-2008
    */
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
    ) RETURN BOOLEAN;

    /**
    * Get ori type list for the viewer 'last 10' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_QUANT   quantos devolver
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   17-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
    */
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
    ) RETURN BOOLEAN;

    /**
    * Get ori type list for the viewer 'with me' filter
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
    * @since   17-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
    */
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /**
    * Returns the menu structure to present the document archive in the viewer.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           patient id
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
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
    ) RETURN BOOLEAN;

    FUNCTION get_default_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        o_doc_ori_type OUT NUMBER,
        o_doc_type     OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_main_thumb_url
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_id_doc    IN NUMBER,
        o_thumb_url OUT VARCHAR2,
        o_count_img OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        i_flg_action IN VARCHAR2,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

END pk_doc_ux;
/
