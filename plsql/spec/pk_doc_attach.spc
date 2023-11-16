/*-- Last Change Revision: $Rev: 2028619 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:56 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc_attach AS

    FUNCTION get_attachment_oid
    (
        i_prof          IN profissional,
        i_id_attachment IN doc_image.id_doc_image%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_mime_type(i_extension IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_extension(i_mime_type IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_file_name
    (
        i_name      IN VARCHAR2,
        i_mime_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_external_doc_blob
    (
        i_prof         IN profissional,
        i_external_doc IN external_doc.id_external_doc%TYPE,
        o_doc_jpeg_ext OUT external_doc.doc_jpeg_ext%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_emptyblob
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_doc           IN NUMBER,
        i_file_name        IN VARCHAR2,
        i_server_file_name IN VARCHAR2,
        i_thumb_file_name  IN VARCHAR2,
        i_page_num         IN NUMBER,
        i_title            IN VARCHAR2,
        o_id_doc_img       OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upload_blob
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc_img IN NUMBER,
        o_img        OUT BLOB,
        o_thumb      OUT BLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * update do registo de uma imagem. Desactiva a imagem com o id fornecido e cria novo registo.
    * Nao actualiza os campos blob. 
    * 
    * @param i_lang            IN id da lingua
    * @param i_prof            IN profissional data
    * @param i_id_doc_image    IN id da imagem a tratar
    * @param i_rank            IN novo rank
    * @param i_file_name       IN novo filename
    * @param i_flg_import      IN nova flg_import
    * @param i_serverfilename  IN novo server filename
    * @param i_flg_img_thumb   IN nova flg_img_thumb
    * @param i_title           IN novo titulo
    * @param o_id_doc_img      OUT id do novo registo
    * @param o_error           OUT mensagem de erro (se result = 0)
    *
    * @return true (sucess), false (error)
    * @created 19-12-2007
    * @author Telmo Castro
    * @version 1.0
    */
    FUNCTION update_image
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_doc_image   IN doc_image.id_doc_image%TYPE,
        i_rank           IN doc_image.rank%TYPE,
        i_file_name      IN doc_image.file_name%TYPE,
        i_flg_import     IN doc_image.flg_import%TYPE,
        i_serverfilename IN doc_image.server_file_name%TYPE,
        i_flg_img_thumb  IN doc_image.flg_img_thumbnail%TYPE,
        i_title          IN doc_image.title%TYPE,
        o_id_doc_img     OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Actualizar os campos FLG_IMPORT e DT_IMPORT e FLG_IMG_THUMBNAIL
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_img        id em doc_image
    * @param i_flg_thumb         Y se tem miniatura, N no caso contrário.
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 04-Out-2006
    * @author João Sá
    */
    FUNCTION update_date
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc_img IN NUMBER,
        i_flg_thumb  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Actualizar os campos FLG_IMPORT e DT_IMPORT e FLG_IMG_THUMBNAIL
    * ESTA FUNÇÂO É SUBSTITUIDA PELA VERSÂO ACIMA. 
    * MANTIDA APENAS PARA COMPATIBILIDADE EM DESENVOLVIMENTO NA TRANSIÇÃO
    * PARA VERSÃO 2.3.6
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_img        id em doc_image
    * @param i_flg_thumb         Y se tem miniatura, N no caso contrário.
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 04-Out-2006
    * @author João Sá
    */
    FUNCTION update_date
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc_img IN NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Inserts an attachment in doc_image
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids          
    * @param i_id_doc            document id (doc_external.id_doc_external)
    * @param i_oid               attachment oid
    * @param i_title             attachment title
    * @param i_date              attachment creation date
    * @param i_file_name         attachment file name
    * @param i_mime_type         attachment mime type
    * @param o_id                attachment id
    
    * @param o_attachment        attachment blob to be filled
    * @param o_attachment_thumb  attachment thumbnail blob to be filled
    * @param o_error             error structure returned in case of an error
    *
    * @return true (sucess), false (error)
    * @created 30-Apr-2014
    * @author Paulo Silva
    */
    FUNCTION insert_attachment
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_doc           IN doc_external.id_doc_external%TYPE,
        i_oid              IN doc_image.oid%TYPE,
        i_title            IN doc_image.title%TYPE,
        i_date             IN doc_image.dt_img_tstz%TYPE,
        i_file_name        IN doc_image.file_name%TYPE,
        i_mime_type        IN doc_image.mime_type%TYPE,
        o_id               OUT doc_image.id_doc_image%TYPE,
        o_attachment       OUT doc_image.doc_img%TYPE,
        o_attachment_thumb OUT doc_image.doc_img_thumbnail%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000); -- Localização do erro 
    g_found BOOLEAN;

    g_img_active   doc_image.flg_status%TYPE;
    g_img_inactive doc_image.flg_status%TYPE;

    l_page_num NUMBER;

    g_exception EXCEPTION;
END;
/
