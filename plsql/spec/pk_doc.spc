/*-- Last Change Revision: $Rev: 2047816 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-19 17:31:52 +0100 (qua, 19 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc IS
    TYPE p_doc_list_rec IS RECORD(
        id_doc_ori_type  doc_ori_type.id_doc_ori_type%TYPE,
        oritypedesc      pk_translation.t_desc_translation,
        typedesc         pk_translation.t_desc_translation,
        title            doc_external.title%TYPE,
        id_doc_external  doc_external.id_doc_external%TYPE,
        numcomments      VARCHAR2(200),
        numimages        NUMBER,
        dt_emited        VARCHAR2(200),
        lastupdateddate  VARCHAR2(200),
        lastupdatedby    VARCHAR2(200),
        url_thumb        VARCHAR2(200),
        flg_status       doc_external.flg_status%TYPE,
        flg_comment_type doc_ori_type.flg_comment_type%TYPE);

    TYPE p_doc_list_rec_cur IS REF CURSOR RETURN p_doc_list_rec;

    /****************************************************************************************
    PK CREATED BY   : JOAO SA
    PK DATE CREATION: 03-2006
    PK GOAL         : THIS PACKAGE INCLUDES ALL FUNCTIONS RELATED TO THE DOCUMENTS AREA.
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Gets professional profile_template
    * Assumes that there's only ibe profile_template for user/software/institution.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   o_pt an error message, set when return=false
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    *
    * UPDATED - esta funcao passou a ser publica porque o pk_doc_internal precisa dela
    * @author  Telmo Castro
    * @date    21-12-2007
    */
    FUNCTION get_profile_template
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_pt    OUT profile_template.id_profile_template%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets value from doc_config
    *
    * @param   i_code_cf doc_config code
    * @param   i_prof professional, institution and software ids
    *
    * @RETURN
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_config
    (
        i_code_cf IN VARCHAR2,
        i_prof    IN profissional,
        i_pt      IN profile_template.id_profile_template%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets doc_types_config.flg_view for the parameters providede
    *
    * @param   i_doc_type id doc_type (can be null)
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt proile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config_visible
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets doc_types_config.flg_other for the parameters provided
    *
    * @param   i_doc_type id doc_type (can be null)
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt proile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config_other
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2;
    /* Gets doc_types_config.flg_insert for the parameters provided
    *
    * @param   i_doc_type id doc_type (can be null)
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_doc_destination id doc_destination (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt profile template id
    * @param   i_btn sys_button_prop id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_types_config_insert
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2;
    /**
    * Gets the primary key (id_doc_types_config) of doc_types_config for the parameters provided
    *
    * @param   i_doc_type id doc_type (can be null)
    * @param   i_doc_ori_type id doc_ori_type (can be null)
    * @param   i_doc_original id doc_original (can be null)
    * @param   i_doc_destination id doc_destination (can be null)
    * @param   i_prof professional, institution and software ids
    * @param   i_pt profile template id
    * @param   i_btn sys_button id
    *
    * @RETURN  id_doc_types_config
    * @author  Telmo Castro
    * @version 1.0
    * @since   12-12-2007
    */
    FUNCTION get_types_config_id
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER;

    FUNCTION get_types_config_ori_type
    (
        i_doc_type        IN doc_type.id_doc_type%TYPE,
        i_doc_ori_type    IN doc_ori_type.id_doc_ori_type%TYPE,
        i_doc_original    IN doc_original.id_doc_original%TYPE,
        i_doc_destination IN doc_destination.id_doc_destination%TYPE,
        i_prof            IN profissional,
        i_pt              IN profile_template.id_profile_template%TYPE,
        i_btn             IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER;

    -- LIST OF ALL DOCS FOR ONE EXTERNAL_REQUEST
    FUNCTION get_doc_list
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_style   OUT VARCHAR2,
        o_docs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- DETAILS OF ONE DOCUMENT
    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --DETAILS OF MULTIPLE DOCUMENTS
    FUNCTION get_doc_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc_list   IN table_number,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
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
    * UTILIZADA NOS EXAMES dá o detalhe de uma lista de documentos, mas agora na forma de 1 lista com todas as versoes deste documento
    * ordenadas cronologicamente. O primeiro da lista deve estar activo e por isso ser a versao actual.
    * @param i_lang     linguagem pedida
    * @param i_prof     ids do profissional
    * @param i_id_doc   array_de ids
    * @param o_list     lista do resultado
    * @param o_error    error message, if any
    *
    * @return TRUE if sucess, FALSE otherwise
    * @author  Rita Lopes
    * @version 1.0
    * @date    16-07-2009
    */
    FUNCTION get_doc_details_exam
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN table_number,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
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
    * Gets doc_ori_types list - Alterado para se existe parametrizacao especifica para esse software, usar essa
    *
    * @param   i_lang language
    * @param   i_prof professional, institution and software ids
    * @param   i_btn sys_button id
    * @param   o_doc_ori_types list of doc_ori_types
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_doc_original_types
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_ori_types OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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
    * lista de opçoes para o multi-choice do novo documento
    *
    * @param   i_lang      id da lingua
    * @param   o_val       lista das opcoes
    * @param   o_error     mensagem de erro
    *
    * @RETURN  TRUE (sucesso), FALSE(error)
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

    -- INSERT NEW DOCUMENT
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
        --
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
        --
        o_id_doc         OUT NUMBER,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- INSERT NEW DOCUMENT
    FUNCTION create_doc_internal
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
        --
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
        --
        o_id_doc         OUT NUMBER,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
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

    -- UPDATE DOCUMENT
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
        i_desc_language      IN doc_external.desc_language%TYPE,
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

    FUNCTION update_doc_internal
    (
        i_lang               IN NUMBER,
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
        i_desc_language      IN doc_external.desc_language%TYPE,
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

    -- CANCEL DOCUMENT
    FUNCTION cancel_doc
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_doc_internal
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtain file extension
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_img            image id
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 14-Jun-2007
    * @author João Sá
    */
    FUNCTION get_doc_image_extension
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_img IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Retornar lista de imagens do documento
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
    FUNCTION get_doc_images_internal
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_doc_list IN table_number,
        i_start_point IN NUMBER,
        i_quantity    IN NUMBER,
        o_doc_images  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
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
    * Returns a images from a list of documents
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 26-11-2010
    * @author Rui Spratley
    */
    FUNCTION get_doc_images_list
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc     IN table_number,
        o_doc_images OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Devolve lista de notas/interpretacoes dum documento
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id do qual se pretende obter as notas
    * @param o_list              lista das notas
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

    FUNCTION get_doc_last_comment
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN VARCHAR2;

    -- CANCEL IMAGE
    FUNCTION cancel_image
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_img IN NUMBER,
        o_error  OUT t_error_out
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
    * Return the parameters needed for the documents upload
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_DOC_PATH init path, path to copy files and max file size allowed
    * @param   O_DOC_FILES allowed files types (name and file extensions)
    * @param   O_SEND_BY list of sending modes
    * @param   O_RECEIVED list of receiving status
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

    -- GET IMAGE
    FUNCTION get_blob
    (
        i_id_doc  IN NUMBER,
        i_id_page IN NUMBER,
        i_thumb   IN NUMBER,
        i_prof    IN profissional,
        o_doc_img OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_num_episode_images
    (
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Get doc_image detail (file name, extension, etc)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_img            image id
    * @param o_doc_img_detail    image details
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 01-Jun-2007
    * @author Luís Gaspar
    */
    FUNCTION get_doc_image_props
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_img        IN NUMBER,
        o_doc_img_props OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return 'Y' if there's one document with the same doc_type already registered
    * for the context provided (patient, episode, external_request)and that doc_type can't
    * be duplicated (FLG_DUPLICATE = 'Y').
    * If the doc_type can be duplicated (FLG_DUPLICATE = 'N') the result is allways 'N'.
    *
    * @param i_lang         language id
    * @param i_prof         professional, software and institution ids
    * @param i_id_patient   the patient id
    * @param i_episode      episode id
    * @param i_ext_req      external request id
    * @param i_doc_type     doc type id
    * @param i_btn          is sys_button_prop
    * @param o_doc_external resulting document id
    * @param o_error        error message
    *
    * @return true (sucess), false (error)
    * @created 24-Oct-2007
    * @author Joao Sa
    */
    FUNCTION is_doc_type_registered
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_doc_type IN NUMBER,
        i_btn      IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2;

    /**
    * inserir/actualizar preferencia do profissional sobre o ori_type presente em doc_types_config
    * dado pelo parametro i_id_doc_types_config.
    
    * @param i_lang       lingua
    * @param i_idtcs      vector com os ids das configs a dar preferencia (ou nao) - pode ser 1 doc_type ou 1 doc_ori_type ou 1 original ou 1 destination
    * @param i_pref       valor da preferencia. pode ser Y ou N
    * @param i_prof       professional que esta a configurar suas preferencias
    * @param o_error      error output
    
    * @return true (sucess), false (error)
    
    * @author Telmo Castro
    * @created 13-12-2007
    * @version 1.0
    */

    FUNCTION update_pref_prof
    (
        i_lang  IN NUMBER,
        i_idtcs IN table_number,
        i_pref  IN VARCHAR DEFAULT 'Y',
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * TEMPORARIO - RETIRAR DA SPEC
    * Telmo
    */
    FUNCTION get_pref_prof
    (
        i_id_doc_types_config IN doc_types_config_prof.id_doc_types_config%TYPE,
        i_prof                IN profissional
    ) RETURN VARCHAR2;

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
      NOTAS:
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

    /**
    * Get ori type list for the viewer 'all' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
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
    * Get ori type list for the viewer 'last 10' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
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
    * Get ori type list for the viewer 'episode' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_EPISODE episode id
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
    * Get ori type list for the viewer 'with me' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
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

    /******************************************************************************
       OBJECTIVO:   cancelar um comentario
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios
                             I_ID_DOC_COMMENTS   - Id do comentario a cancelar
                             I_Type_Reg          - Tipo de cancelamento: E - Editar, C - Cancelar
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/17
      NOTAS:
    *********************************************************************************/
    FUNCTION cancel_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_comments IN doc_comments.id_doc_comment%TYPE,
        i_type_reg        IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   editar um comentario
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios
                             I_ID_DOC_EXTERNAL   - ID do documento
                             I_ID_IMAGE          - ID da imagem
                             I_DESC_COMMENT      - Descritivo do comentario
                             I_ID_DOC_COMMENTS   - Id do comentario a cancelar
                             I_Type_Reg          - Tipo de cancelamento: E - Editar, C - Cancelar
    
                Saida:   O_ERROR       - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/17
      NOTAS:
    *********************************************************************************/
    FUNCTION update_comments
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_comments.id_doc_external%TYPE,
        i_id_image        IN doc_comments.id_doc_image%TYPE,
        i_desc_comment    IN doc_comments.desc_comment%TYPE,
        i_id_doc_comments IN doc_comments.id_doc_comment%TYPE,
        i_type_reg        IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Detalhe de comentarios de um documento
       PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                             I_PROF              - Profissional que altera comentarios
                             I_ID_DOC_EXTERNAL   - ID do documento
    
                Saida:  o_comments_det  - cursor com o detalhe
                        O_ERROR         - erro
    
      CRIAÇÃO:
      CRIAÇÃO: Rita Lopes 2007/12/18
      NOTAS:
    *********************************************************************************/
    FUNCTION get_comments_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_external IN doc_comments.id_doc_external%TYPE,
        o_comments_det    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
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

    FUNCTION create_savedoc_internal
    (
        i_id_doc            IN doc_external.id_doc_external%TYPE,
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN doc_external.id_patient%TYPE,
        i_episode           IN doc_external.id_episode%TYPE,
        i_ext_req           IN doc_external.id_external_request%TYPE,
        i_doc_type          IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type     IN doc_external.desc_doc_type%TYPE,
        i_num_doc           IN doc_external.num_doc%TYPE,
        i_dt_doc            IN doc_external.dt_emited%TYPE,
        i_dt_expire         IN doc_external.dt_expire%TYPE,
        i_dest              IN doc_external.id_doc_destination%TYPE,
        i_desc_dest         IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type      IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type IN doc_external.desc_doc_ori_type%TYPE,
        i_original          IN doc_external.id_doc_original%TYPE,
        i_desc_original     IN doc_external.desc_doc_original%TYPE,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_flg_sent_by       IN doc_external.flg_sent_by%TYPE,
        i_flg_received      IN doc_external.flg_received%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        --
        i_author             IN doc_external.author%TYPE := NULL,
        i_specialty          IN doc_external.id_specialty%TYPE := NULL,
        i_doc_language       IN doc_external.id_language%TYPE := NULL,
        i_desc_language      IN doc_external.desc_language%TYPE := NULL,
        i_flg_publish        IN VARCHAR2 := NULL,
        i_conf_code          IN table_varchar := table_varchar(),
        i_desc_conf_code     IN table_varchar := table_varchar(),
        i_code_coding_schema IN table_varchar := table_varchar(),
        i_conf_code_set      IN table_varchar := table_varchar(),
        i_desc_conf_code_set IN table_varchar := table_varchar(),
        i_local_emitted      IN doc_external.local_emited%TYPE := NULL,
        i_doc_oid            IN doc_external.doc_oid%TYPE := NULL,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna URL para o thumbnail principal de 1 doc.
    * O thumbnail principal esta na imagem com o rank mais baixo.
    * Funçao local para ser usada nos get_doc_list_xxxx
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    *
    * @return varchar2 (sucesso), null (erro ou nao existente)
    * @created 27-12-2007
    * @author Telmo Castro
    */
    FUNCTION get_main_thumb_url
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Returns MIME_TYPE for docs main thumbnail
    * Main thumbnail is the image with the lowest rank.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    *
    * @return varchar2 (sucess), null (error or non existent)
    * @created 2010-10-28
    * @author Rui Spratley
    */
    FUNCTION get_main_thumb_mime_type
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Returns MIME_TYPE for docs main extension
    * Main thumbnail is the image with the lowest rank.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    *
    * @return varchar2 (sucess), null (error or non existent)
    * @created 2010-11-02
    * @author Rui Spratley
    */

    FUNCTION get_main_thumb_extension
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_doc IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Retorna a designacao formal para os comentarios nos get_doc_list_...
    * A designacao pode ser 'notas' ou 'interpretacoes', dependendo do flg_comm_type.
    *
    * @param i_lang              language id
    * @param i_flg_comm_type      tipo do comentario
    *
    * @return varchar2 (sucesso ou erro)
    *
    * @created 28-12-2007
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION get_comments_line
    (
        i_lang          IN NUMBER,
        i_flg_comm_type IN doc_ori_type.flg_comment_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Retorna frase '<designacao>: <valor>' para os get_doc_list_...
    * <designacao> pode ser 'notas' ou 'interpretacoes', dependendo do flg_comm_type.
    * <valor> é o numero de comentarios activos para o documento dado por i_id_doc_external.
    * Funçao local para ser usada nos get_doc_list_xxxx
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param i_flg_comm_type      tipo do comentario
    *
    * @return varchar2 (sucesso ou erro)
    * @created 28-12-2007
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION get_comments_line_with_count
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_doc        IN doc_comments.id_doc_external%TYPE,
        i_flg_comm_type IN doc_ori_type.flg_comment_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get detail list (central pane) for the viewer 'all' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   20-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
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
    * Get detail list (central pane) for the viewer 'last 10' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   I_QUANT   considera apenas os ultimos I_QUANT episodios
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
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
    * Get detail list for the viewer 'episode' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
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
    * Get detail list for the viewer 'with me' filter
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo Castro
    * @version 1.0
    * @since   21-12-2007
    *
    * UPDATED passa a contar com os docs inactivos (nao confundir com os oldversion)
    * @author Telmo Castro
    * @since  11-01-2008
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
    * Gets the last active document of a specified type
    *
    * @param   I_LANG     language associated to the professional executing the request
    * @param   I_PROF     professional, institution and software ids
    * @param   I_PATIENT  patient id
    * @param   I_EPISODE  episode id
    * @param   I_DOC_TYPE document type ID
    * @param   O_LIST     output list
    * @param   O_ERROR    an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2009
    */
    FUNCTION get_doc_list_type
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_type IN doc_type.id_doc_type%TYPE,
        i_btn      IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list     OUT p_doc_list_rec_cur,
        o_error    OUT t_error_out
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

    /**
    * delete dos documentos pendentes criados ha mais de i_lifetime.
    * Isto e' usado por um job para limpar regularmente a tabela doc_external
    *
    * @param i_lifetime          IN numero de horas minimo que o documento deve ter para poder ser apagado
    *
    * @return true (sucess), false (error)
    * @created 09.01.2008
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION delete_docs(i_lifetime IN NUMBER DEFAULT 72) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the total size already used for documents upload
    *
    * @ param i_lang                  Preferred language ID for this professional
    * @ param i_prof                  Object (professional ID, institution ID, software ID)
    * @ param o_used_quota            Quota size already used, in a given institution
    * @ param o_error                 Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/18
    **********************************************************************************************/
    FUNCTION get_used_quota
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_used_quota OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Validate the if maximum quota size for documents upload is exceeded
    *
    * @ param i_lang                  Preferred language ID for this professional
    * @ param i_prof                  Object (professional ID, institution ID, software ID)
    * @ param i_new_docs_size         Total size of documents to upload
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
    FUNCTION validate_used_quota
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_new_docs_size IN NUMBER,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

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
    --

    /**
    * Documents list and count
    *
    * @param   i_lang     language associated to the professional executing the request
    * @param   i_prof     professional, institution and software ids
    * @param   i_pat      patient identifier
    * @param   i_episode  episode Id.
    * @param   i_ext_req  P1 external request.
    * @param   i_btn      sys_button used to allow diferent behaviours depending on the button being used.
    * @param   o_list     cursor
    * @param   o_error    an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   23-09-2010
    */
    FUNCTION get_documents_list_count
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_pat        IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_btn        IN sys_button_prop.id_sys_button_prop%TYPE,
        i_flg_status IN table_varchar,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Documents list details
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_pat             patient identifier
    * @param   i_episode         episode Id.
    * @param   i_ext_req         P1 external request.
    * @param   i_btn             sys_button used to allow diferent behaviours depending on the button being used.
    * @param   i_doc_ori_type    document type
    * @param   o_list            cursor
    * @param   o_error           an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   21-10-2010
    */
    FUNCTION get_documents_list_details
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert EPIS_REPORT information in DOC_EXTERNAL table and afterwards UPDATES EPIS_REPORT with DOC_EXTERNALs new ID
    *
    * @param   i_lang             language associated to the professional executing the request
    * @param   i_prof             professional, institution and software ids
    * @param   i_epis_report      epis_report id
    * @param   o_error            an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   27-09-2010
    */
    FUNCTION create_report_document
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_epis_report     IN epis_report.id_epis_report%TYPE,
        i_flg_share_grid  IN VARCHAR2,
        o_error           OUT t_error_out,
        o_id_doc_external OUT epis_report.id_doc_external%TYPE
    ) RETURN BOOLEAN;

    /**
    * Get file mime type -- This is used in a view so we do not have the i_lang and i_prof variables
    *
    * @param   i_doc_imag         doc_image id
    *
    * @RETURN  mime type
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   28-09-2010
    */
    FUNCTION get_doc_image_mime_type(i_doc_imag IN doc_image.id_doc_image%TYPE) RETURN VARCHAR2;

    /**
    * Get DOC_EXTERNAL original OID
    *
    * @param   i_lang          language associated to the professional executing the request
    * @param   i_prof          professional, institution and software ids
    * @param   i_doc_external  id from doc_external table
    * @param   o_oid           OID from DOC_EXTERNAL table
    * @param   o_error         an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_original_oid
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_oid          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Internal function to get number of document images
    *
    * @param   i_lang          language associated to the professional executing the request
    * @param   i_prof          professional, institution and software ids
    * @param   i_doc_external  document id
    *
    * @RETURN  number of documento images
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   01-10-2010
    */
    FUNCTION get_count_image
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN NUMBER;

    /**
    * Internal function to check if document has blobs
    *
    * @param   i_lang          language associated to the professional executing the request
    * @param   i_prof          professional, institution and software ids
    * @param   i_doc_external  document id
    *
    * @RETURN  Y if document has blobs, N otherwise
    *
    * @author  Andre Silva
    * @version 2.7.5.2
    * @since   14-03-2019
    */
    FUNCTION has_blob
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * Internal function to get number of documento images
    *
    * @param   i_lang          language associated to the professional executing the request
    * @param   i_prof          professional, institution and software ids
    * @param   i_doc_external  list of document ids
    *
    * @RETURN  number of documento images
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   01-10-2010
    */
    FUNCTION get_count_image_list
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN table_number
    ) RETURN NUMBER;

    FUNCTION get_doc_list_by_category
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        i_id_doc_type  IN doc_type.id_doc_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_list_by_category_tbl
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        i_id_doc_type  IN doc_type.id_doc_type%TYPE
    ) RETURN t_tbl_rec_document;

    /**
    * Get detail list (central pane) for the viewer 'all' filter
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @param   i_episode        episode id
    * @param   i_ext_req        referral id
    * @param   i_btn            sys_button used to allow diferent behaviours depending on the button being used.
    * @param   i_doc_ori_type   document type - Can be ALL if NULL or a specific one
    * @param   o_list           output list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   06-10-2010
    */
    FUNCTION get_doc_list_by_type
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

    /**
    * Get documents list for the main grid
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @param   i_episode        episode id
    * @param   i_ext_req        referral id
    * @param   i_btn            sys_button used to allow diferent behaviours depending on the button being used.
    * @param   i_doc_ori_type   document type - Can be ALL if NULL or a specific one
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Daniel Silva
    * @version 2.6.3
    * @since  2013.09.19
    */
    FUNCTION get_doc_list_by_type
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE
    ) RETURN t_tbl_rec_document;

    /******************************************************************************
      OBJECTIVO:   Actualizar, no reset, os pacientes de um episódio
      PARAMETROS:  Entrada: I_LANG              - Língua registada como preferência do profissional
                            I_PROF              - Profissional que altera comentarios
                            I_table_episode     - Id episodios
    
               Saida:   O_ERROR       - erro
    
     CRIAÇÃO: Rita Lopes 2010/10/14
     NOTAS:
    *********************************************************************************/
    FUNCTION clear_documents_reset
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_clear_admin_docs IN VARCHAR2,
        i_table_episodes   IN table_number,
        i_table_patients   IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get default id_doc_original
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   o_dest           output value
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   27-10-2010
    */

    FUNCTION get_default_original
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_dest  OUT doc_original.id_doc_original%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get document types by doc ori type
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @param   i_episode        episode id
    * @param   i_ext_req        referral id
    * @param   i_btn            sys_button used to allow diferent behaviours depending on the button being used.
    * @param   i_doc_ori_type   document type - Can be ALL if NULL or a specific one
    * @param   o_list           output list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   25-11-2010
    */

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

    FUNCTION get_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE
    ) RETURN t_tbl_core_domain;

    /**
    * Get document publishing information
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_id_doc_external document id
    * @param   o_list           output list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Guilherme
    * @version 2.6.0.4
    * @since   09-12-2010
    */
    FUNCTION get_doc_publishing_data
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if Doc_Type is Publishable
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_doc_type        document type
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Guilherme
    * @version 2.6.0.4
    * @since   09-12-2010
    */
    FUNCTION is_doc_type_publishable
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_doc_type IN doc_ori_type.id_doc_ori_type%TYPE
        --o_error        OUT t_error_out
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the categories of which the professional has visibility
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   o_list           output list
    * @param   o_error          an error message, set when return=false
    *
    * @return   the biggest of the values
    *
    * @author  Carlos Guilherme
    * @version 2.6.0.5
    * @since   04-Jan-2011
    **********************************************************************************************/
    FUNCTION get_categories
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_categories
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    /**
    * Check if documents with this doc type is downloadable
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_doc_type        document type
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Guilherme
    * @version 2.6.1
    * @since   12-04-2011
    */
    FUNCTION is_doc_type_download
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_doc_type IN doc_type.id_doc_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get a patient's document number.
    *
    * @param i_patient      patient identifier
    * @param i_doc_type     document type identifier
    *
    * @return               document number
    *
    * @author               Pedro Carneiro
    * @version               2.5.2.1
    * @since                2012/02/03
    */
    FUNCTION get_pat_doc_num
    (
        i_patient  IN patient.id_patient%TYPE,
        i_doc_type IN doc_type.id_doc_type%TYPE
    ) RETURN doc_external.num_doc%TYPE;

    /*
    * returns list of all doc_ori_types available for professional i_prof.
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

    /* data to fill the grid.
    *
    * @param i_lang              language associated to the professional executing the request
    * @param i_prof              professional, institution and software ids
    * @param i_id_patient        patient id
    * @param i_id_episode        episode id. can be null. If not null, only documents related to this episode are considered
    * @param i_ids_doc_ori_types list of doc_ori_types that will filter the visible documents in the grid
    * @param i_id_tl_scale       smallest time block. Can be decade, year, etc.
    * @param o_result            output
    * @param o_error             error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.6
    * @since   22-12-2011
    */
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

    /**
    * Get body diagrams
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @parama  i_first_run
    * @param   o_body_diagrams           output body diagrams list
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Daniel Silva
    * @version 2.6.2
    * @since   2012-04-03
    */
    FUNCTION get_body_diagrams_as_document
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_body_diagrams OUT t_tbl_rec_document,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get body diagrams
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient        patient id
    * @parama  i_first_run
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Daniel Silva
    * @version 2.6.3
    * @since   2012-09-12
    */
    FUNCTION get_body_diagrams_as_document
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_rec_document;

    /**
    * Documents count by category
    *
    * @param   i_lang     language associated to the professional executing the request
    * @param   i_prof     professional, institution and software ids
    * @param   i_pat      patient identifier
    * @param   i_episode  episode Id.
    * @param   i_ext_req  P1 external request.
    * @param   i_btn      sys_button used to allow diferent behaviours depending on the button being used.
    * @param   o_list     cursor
    * @param   o_error    an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Daniel Silva
    * @version 2.6.2
    * @since   2012-04-03
    */
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

    /**
    * Get attached documents for a specific external request (URLs to P1_ATTACHED_DOCUMENT servlet).
    *
    * @param i_external_request      external request
    *
    * @return               doc_image urls
    *
    * @author               Daniel Silva
    * @version              2.6.1
    * @since                2013/05/28
    * reason                ALERT-258767
    */
    FUNCTION get_ext_req_doc_urls
    (
        i_lang             IN NUMBER,
        i_external_request IN doc_external.id_external_request%TYPE,
        o_ext_req_doc_urls OUT pk_types.cursor_type,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**
    * Get hash value for a given string. (Used as a token to validate P1 servlet requests for attached documents.)
    *
    * @param i_src      input string
    *
    * @return               hash value
    *
    * @author               Daniel Silva
    * @version              2.6.1
    * @since                2013/05/28
    * reason                ALERT-258767
    */
    FUNCTION get_hash(i_src IN VARCHAR2) RETURN VARCHAR2;

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

    PROCEDURE get_archive_list_filter
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_institutions_sib
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_inst IN institution.id_institution%TYPE
        
    ) RETURN table_number;

    /**
    * Returns the document archive cover cell for the viewer.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           id episode
    * @param o_viewer_info       data for viewer
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION get_viewer_doc_archive_cover
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_viewer_info OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns TRUE if documents archive must show body diagrams.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION is_arch_including_body_diag
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN BOOLEAN;

    /**
    * Returns the number of body diagrams for the patient (Returns 0 (zero) if doc archive is not configured to include body diagrams.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           patient id
    *
    * @return true (sucess), false (error)
    * @created 2013.09.19
    * @author daniel.silva
    */
    FUNCTION get_body_diagrams_count
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN NUMBER;

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
    )
    
     RETURN BOOLEAN;

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
    )
    
     RETURN BOOLEAN;

    /********************************************************************************************
    * This procedure updates viewer_ea archives
    *
    * @author  Mário Mineiro
    * @since   2014-03-06
    *
    ********************************************************************************************/

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_TABLE_ID_PATIENTS      Table of id patients to be clean.
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.x
    * @since                          06-03-2014
    ********************************************************************************************/
    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
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

    PROCEDURE get_doc_section_import
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_doc_section OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    );

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

    FUNCTION insert_area
    (
        i_code_area     IN VARCHAR2,
        i_ux_class_name IN VARCHAR2,
        i_flg_available IN VARCHAR2,
        i_rank          IN NUMBER
    ) RETURN NUMBER;

    FUNCTION insert_operation_conf
    (
        i_operation_name IN VARCHAR2,
        i_target_name    IN VARCHAR2,
        i_source_name    IN VARCHAR2,
        i_flg_available  IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION insert_area_operation
    (
        i_id_doc_archive_area   IN NUMBER,
        i_id_doc_operation_conf IN NUMBER,
        i_id_action             IN NUMBER,
        i_flg_available         IN NUMBER
    ) RETURN NUMBER;

    FUNCTION is_first_version(i_doc_external IN doc_external.id_doc_external%TYPE) RETURN VARCHAR2;

    FUNCTION get_doc_oid
    (
        i_prof   IN profissional,
        i_id_doc IN doc_external.id_doc_external%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_doc_comments_as_text
    (
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_delimiter       IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_doc_types_tbl
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        --i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_error OUT t_error_out
    ) RETURN table_number;

    FUNCTION get_categories_tbl
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    )
    
     RETURN table_number;

    /**
    * GET doc type rank
    *
    * @param i_lang           Language identifier
    * @param i_prof           Logged professional structure
    * @param i_doc_ori_type     Doc ori type id
    *
    * @return                 rank number
    *
    * @raises                 PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.4.0
    * @since                2018-09-10
    */
    FUNCTION get_doc_rank
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_ori_type IN doc_external.id_doc_external%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    *  This fuction will update the episode of a given document
    *
    * @param i_lang                   The id language
    * @param i_prof                   Professional (id, institution, software)
    * @param i_id_doc_external        Document to update
    * @param i_id_episode             Episode to set
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Andre Silva
    * @version                        2.7.4.4
    * @since                          03-10-2018
    ********************************************************************************************/
    FUNCTION set_epis_in_doc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_external IN doc_external.id_doc_external%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return number of migrant doc 
    * Isto e' usado por um job para limpar regularmente a tabela doc_external
    * 
    * @param i_lang            IN id da lingua
    * @param i_prof            IN profissional data
    * @param i_id_patient      IN id_patient
    * @param o_num_doc      OUT document number    
    * @param o_doc_exist      OUT Y - if document exists, N
    * @param o_error           OUT mensagem de erro (se result = 0)
    *
    *
    * @return true (sucess), false (error)
    * @created 09.01.2008
    * @version 1.0
    */
    FUNCTION get_migrant_doc
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        o_num_doc             OUT doc_external.num_doc%TYPE,
        o_exist_doc           OUT VARCHAR2,
        o_dt_expire           OUT doc_external.dt_expire%TYPE,
        o_doc_type            OUT doc_external.id_doc_type%TYPE,
        o_id_content_doc_type OUT doc_type.id_content%TYPE,
        o_error               OUT t_error_out
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

    /**
    * Returns TRUE if the documents are associated to lab_tests
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_external      id of external document  
    *
    * @return true (sucess), false (error)
    */
    FUNCTION is_lab_test_result
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_document_detail
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_document_detail_hist
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_doc        IN NUMBER,
        o_doc_detail OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_archive_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_doc_originals
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_btn  IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_doc_destinations
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_btn  IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN t_tbl_core_domain;

    /*
    * VARS INTERNAS
    */
    g_found BOOLEAN;
    g_error VARCHAR2(2000);

    g_sysdatec     VARCHAR2(16);
    g_sysdate      TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_sysdated     DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_doc_active     CONSTANT doc_external.flg_status%TYPE := 'A';
    g_doc_inactive   CONSTANT doc_external.flg_status%TYPE := 'I';
    g_doc_pendente   CONSTANT doc_external.flg_status%TYPE := 'P';
    g_doc_oldversion CONSTANT doc_external.flg_status%TYPE := 'O';

    g_img_active   CONSTANT doc_image.flg_status%TYPE := 'A';
    g_img_inactive CONSTANT doc_image.flg_status%TYPE := 'I';

    g_doc_type_id                VARCHAR2(50);
    g_doc_destination_patient_id VARCHAR2(50);
    g_doc_original_patient_id    VARCHAR2(50);

    g_flg_img_thumbnail_n VARCHAR2(1);
    g_flg_type_d          doc_comments.flg_type%TYPE;
    g_flg_type_i          doc_comments.flg_type%TYPE;

    g_flg_cancel_y doc_comments.flg_cancel%TYPE;
    g_flg_cancel_n doc_comments.flg_cancel%TYPE;

    --
    g_doc_config_y CONSTANT VARCHAR(1) := 'Y';
    g_doc_config_n CONSTANT VARCHAR(1) := 'N';

    g_doc_type_available_y        doc_type.flg_available%TYPE;
    g_doc_ori_type_available_y    doc_type.flg_available%TYPE;
    g_doc_original_available_y    doc_type.flg_available%TYPE;
    g_doc_destination_available_y doc_type.flg_available%TYPE;

    g_yes VARCHAR2(1);
    g_no  VARCHAR2(1);

    g_epis_flg_status_canc episode.flg_status%TYPE;

    g_flg_comm_type_i doc_ori_type.flg_comment_type%TYPE;
    g_flg_comm_type_n doc_ori_type.flg_comment_type%TYPE;

    g_doc_ori_type_identific_y doc_ori_type.flg_identification%TYPE;

    g_referral CONSTANT software.id_software%TYPE := 4;

    -- These variables are deprecated since the log error revision
    g_owner_name CONSTANT VARCHAR2(5) := 'ALERT';
    g_pck_name   CONSTANT VARCHAR2(12) := 'PK_DOC';

    g_flg_submission_status_p CONSTANT VARCHAR2(1) := 'P'; --Pending
    g_flg_submission_status_r CONSTANT VARCHAR2(1) := 'R'; --Ready
    g_flg_submission_status_c CONSTANT VARCHAR2(1) := 'C'; --Canceled
    g_flg_submission_status_s CONSTANT VARCHAR2(1) := 'S'; --Sent
    g_flg_submission_status_x CONSTANT VARCHAR2(1) := 'X'; --Error

    g_report_default_extension CONSTANT VARCHAR2(3) := 'pdf';
    g_epis_report_flg_status_n CONSTANT VARCHAR(1) := 'N';

    c_tl_docs CONSTANT tl_timeline.id_tl_timeline%TYPE := 6;

    g_area_lab_test VARCHAR2(10) := 'LAB_TEST';

    g_doc_ori_type_lab_test NUMBER := 15;

    -- Log variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_doc;
/
