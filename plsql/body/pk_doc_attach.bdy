/*-- Last Change Revision: $Rev: 2026995 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_attach AS

    FUNCTION get_extension(i_file_name IN VARCHAR2) RETURN VARCHAR2 IS
        l_pos       NUMBER;
        l_extension VARCHAR(200) := NULL;
    BEGIN
        l_pos := instr(i_file_name, '.', -1);
        IF l_pos > 0
        THEN
            l_extension := substr(i_file_name, l_pos + 1);
        END IF;
    
        RETURN l_extension;
    END;

    FUNCTION get_mime_type(i_extension IN VARCHAR2) RETURN VARCHAR2 IS
        l_extension VARCHAR(200);
        l_mime_type doc_image.mime_type%TYPE;
    BEGIN
        BEGIN
            l_extension := get_extension(i_file_name => i_extension);
            IF l_extension IS NULL
            THEN
                l_extension := i_extension;
            END IF;
        
            SELECT dft.mime_type
              INTO l_mime_type
              FROM doc_file_type dft
             WHERE dft.extension = l_extension;
        EXCEPTION
            WHEN OTHERS THEN
                SELECT dft.mime_type
                  INTO l_mime_type
                  FROM doc_file_type dft
                 WHERE dft.extension = '*'; -- gets default mime_type
        END;
        RETURN l_mime_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_extension(i_mime_type IN VARCHAR2) RETURN VARCHAR2 IS
        l_extension VARCHAR2(10);
    BEGIN
        SELECT decode(dft.extension, '*', NULL, dft.extension)
          INTO l_extension
          FROM doc_file_type dft
         WHERE dft.mime_type = i_mime_type;
    
        RETURN l_extension;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_file_name
    (
        i_name      IN VARCHAR2,
        i_mime_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_extension VARCHAR2(200);
        l_file_name VARCHAR2(1024);
    BEGIN
        l_extension := get_extension(i_file_name => i_name);
        IF l_extension IS NULL
        THEN
            -- no extension found in i_name?
            l_extension := get_extension(i_mime_type => i_mime_type);
            IF l_extension IS NOT NULL
            THEN
                l_file_name := i_name || '.' || l_extension;
            END IF;
        ELSE
            l_file_name := i_name; -- i_name already has an extension
        END IF;
    
        RETURN l_file_name;
    END;

    FUNCTION get_attachment_oid
    (
        i_prof          IN profissional,
        i_id_attachment IN doc_image.id_doc_image%TYPE
    ) RETURN VARCHAR2 IS
        l_oid doc_image.oid%TYPE := NULL;
    BEGIN
        -- Get OID from doc_image   
        BEGIN
            SELECT di.oid
              INTO l_oid
              FROM doc_image di
             WHERE di.id_doc_image = i_id_attachment;
        
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- ignore it
        END;
    
        IF l_oid IS NULL
        THEN
            l_oid := pk_utils.create_oid(i_prof, 'ALERT_OID_HIE_DOC_IMAGE', i_id_attachment);
        END IF;
    
        RETURN l_oid;
    END get_attachment_oid;

    FUNCTION get_external_doc_blob
    (
        i_prof         IN profissional,
        i_external_doc IN external_doc.id_external_doc%TYPE,
        o_doc_jpeg_ext OUT external_doc.doc_jpeg_ext%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang sys_config.value%TYPE;
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof);
    
        g_error := 'GET PHOTO';
        SELECT doc_jpeg_ext
          INTO o_doc_jpeg_ext
          FROM external_doc
         WHERE id_external_doc = i_external_doc;
    
        o_doc_jpeg_ext := pk_tech_utils.set_empty_blob(o_doc_jpeg_ext);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DOC_ATTACH',
                                              'GET_EXTERNAL_DOC_BLOB',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_external_doc_blob;

    /**
    * Attaches files to the document
    * 
    * @param   i_lang language associated to the professional executing the request 
    * @param   i_prof  professional, institution and software ids
    * @param   i_id_doc  document id
    * @param   i_oid  file/attachment id
    * @param   i_file_name file name
    * @param   i_server_file_name server file name
    * @param   i_title file title/desc
    * @param   i_mime_type file mime type
    * @param   o_id_doc_img file id
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  João Sá 
    * @version 1.0 
    * @since   15-03-2006 
    *
    * UPDATED - novo parametro i_title
    * @author Telmo Castro
    * @version 1.1
    * @since  19-12-2007
    *
    * UPDATED - new params: i_oid, i_mime_type
    * @author Paulo Silva
    * @version 2.6.3.x
    * @since  30-04-2014
    */
    FUNCTION insert_emptyblob
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_doc           IN doc_image.id_doc_external%TYPE,
        i_oid              IN doc_image.oid%TYPE := NULL,
        i_dt_img           IN doc_image.dt_img_tstz%TYPE := current_timestamp,
        i_file_name        IN doc_image.file_name%TYPE,
        i_server_file_name IN doc_image.server_file_name%TYPE := NULL,
        i_title            IN doc_image.title%TYPE := NULL,
        i_mime_type        IN doc_image.mime_type%TYPE := NULL,
        o_id_doc_img       OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids    table_varchar;
        l_mime_type doc_image.mime_type%TYPE;
    BEGIN
        g_error := 'INSERT INTO DOC_IMAGE';
        SELECT seq_doc_image.nextval
          INTO o_id_doc_img
          FROM dual;
    
        -- Infer mime type from file extension (if needed)
        IF i_mime_type IS NULL
        THEN
            SELECT dft.mime_type
              INTO l_mime_type
              FROM doc_file_type dft
             WHERE upper(dft.extension) = upper(substr(i_file_name, instr(i_file_name, '.', -1) + 1));
        ELSE
            l_mime_type := i_mime_type;
        END IF;
    
        -- ACtualizar FLG_IMPORT e DT_IMPORT depois da importação 
        INSERT INTO doc_image
            (id_doc_image,
             id_doc_external,
             rank,
             file_name,
             server_file_name,
             dt_img_tstz,
             doc_img,
             doc_img_thumbnail,
             flg_import,
             dt_import_tstz,
             flg_status,
             id_professional,
             title,
             OID,
             mime_type,
             id_institution)
        VALUES
            (o_id_doc_img,
             i_id_doc,
             0,
             i_file_name,
             i_server_file_name,
             i_dt_img,
             empty_blob(),
             empty_blob(),
             'Y',
             current_timestamp,
             g_img_inactive,
             i_prof.id,
             i_title,
             nvl(i_oid, get_attachment_oid(i_prof, o_id_doc_img)),
             l_mime_type,
             i_prof.institution);
        -- TODO: USAR NUMERO DE PAGINAs
    
        -- update da data e id_prof no documento
        -- UPDATE doc_external
        --  SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
        --  WHERE id_doc_external = i_id_doc
        --  AND flg_status <> pk_doc.g_doc_pendente;
    
        l_rowids := table_varchar();
        g_error  := 'Call ts_doc_external.upd / ID_DOC_EXTERNAL_IN=' || i_id_doc;
        ts_doc_external.upd(dt_updated_in          => current_timestamp,
                            id_professional_upd_in => i_prof.id,
                            where_in               => 'id_doc_external =' || i_id_doc || 'AND flg_status <> ''' ||
                                                      pk_doc.g_doc_pendente || '''',
                            rows_out               => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_DOC_ATTACH', 'INSERT_EMPTYBLOB');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
    END insert_emptyblob;

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
    ) RETURN BOOLEAN IS
        l_mime_type doc_image.mime_type%TYPE;
    BEGIN
    
        RETURN insert_emptyblob(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_doc           => i_id_doc,
                                i_file_name        => i_file_name,
                                i_server_file_name => i_server_file_name,
                                i_title            => i_title,
                                o_id_doc_img       => o_id_doc_img,
                                o_error            => o_error);
    END insert_emptyblob;

    /******************************************************************************
       OBJECTIVO: Reservar registo para actualização
       PARAMETROS:  Entrada: 
          I_LANG - Idioma  
          I_PROF - Terno do profissional
          I_ID_DOC_IMG - Identificador do registo em DOC_IMAGE
       I_PROF- ID do PROFESSIONAL
          Saida:
          O_IMG   - Apontador para o refisto DOC_IMG (ficheiro)
          O_THUMB - Apontador para o refisto DOC_IMG_THUMBNAIL (miniatura)
          O_ERROR - erro
      CRIAÇÃO: JOAO SA 2006/10/04
      NOTAS:
    *********************************************************************************/
    FUNCTION upload_blob
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_doc_img IN NUMBER,
        o_img        OUT BLOB,
        o_thumb      OUT BLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'SELECT';
        SELECT doc_img, doc_img_thumbnail
          INTO o_img, o_thumb
          FROM doc_image
         WHERE id_doc_image = i_id_doc_img
           FOR UPDATE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_DOC', 'UPLOAD_BLOB');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END upload_blob;

    /**
    * update do registo de uma imagem. Desactiva a imagem com o id fornecido e cria novo registo.
    * Nao actualiza os campos blob. Para isso usar novamente o upload_blob.
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
    ) RETURN BOOLEAN IS
    
        l_id_doc_external   doc_image.id_doc_external%TYPE;
        l_flg_status        doc_external.flg_status%TYPE;
        l_filename          doc_image.file_name%TYPE;
        l_rank              doc_image.rank%TYPE;
        l_flg_import        doc_image.flg_import%TYPE;
        l_server_filename   doc_image.server_file_name%TYPE;
        l_flg_img_thumbnail doc_image.flg_img_thumbnail%TYPE;
        l_dt_import_tstz    doc_image.dt_img_tstz%TYPE;
        l_error             t_error_out;
    
        l_rowids table_varchar;
    
    BEGIN
        -- pegar o id do documento e seu estado, necessarios para o proximo passo
        g_error := 'SELECT ID_DOC_EXTERNAL';
        SELECT di.id_doc_external,
               de.flg_status,
               di.file_name,
               di.rank,
               di.flg_import,
               di.server_file_name,
               di.flg_img_thumbnail,
               di.dt_import_tstz
          INTO l_id_doc_external,
               l_flg_status,
               l_filename,
               l_rank,
               l_flg_import,
               l_server_filename,
               l_flg_img_thumbnail,
               l_dt_import_tstz
          FROM doc_image di
         INNER JOIN doc_external de
            ON di.id_doc_external = de.id_doc_external
         WHERE di.id_doc_image = i_id_doc_image;
    
        -- se o documento esta pendente vamos actualizar directamente; senao segue-se a rotina habitual
        IF l_flg_status = pk_doc.g_doc_pendente
        THEN
        
            UPDATE doc_image
               SET rank             = nvl(i_rank, rank),
                   file_name        = nvl(i_file_name, file_name),
                   server_file_name = nvl(i_serverfilename, server_file_name),
                   -- o titulo fica mesmo sem nvl para assumir o input incondicionalmente
                   title = i_title
             WHERE id_doc_image = i_id_doc_image;
        
            o_id_doc_img := i_id_doc_image;
        
        ELSE
            -- cancelar esta imagem
            IF NOT
                pk_doc.cancel_image(i_lang => i_lang, i_prof => i_prof, i_id_img => i_id_doc_image, o_error => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- inserir a nova
            IF NOT insert_emptyblob(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_doc           => l_id_doc_external,
                                    i_file_name        => l_filename,
                                    i_server_file_name => i_serverfilename,
                                    i_thumb_file_name  => NULL,
                                    i_page_num         => NULL,
                                    i_title            => i_title,
                                    o_id_doc_img       => o_id_doc_img,
                                    o_error            => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- copiar blobs e restantes dados para nova
            g_error := 'UPDATE DOC_IMAGE';
            UPDATE doc_image
               SET doc_img          =
                   (SELECT doc_img
                      FROM doc_image
                     WHERE id_doc_image = i_id_doc_image),
                   doc_img_thumbnail =
                   (SELECT doc_img_thumbnail
                      FROM doc_image
                     WHERE id_doc_image = i_id_doc_image),
                   flg_status        = l_flg_status,
                   file_name         = nvl(file_name, l_filename),
                   rank              = l_rank,
                   flg_import        = l_flg_import,
                   server_file_name  = nvl(server_file_name, l_server_filename),
                   flg_img_thumbnail = l_flg_img_thumbnail,
                   dt_import_tstz    = l_dt_import_tstz,
                   img_size         =
                   (SELECT dbms_lob.getlength(doc_img)
                      FROM doc_image
                     WHERE id_doc_image = i_id_doc_image)
             WHERE id_doc_image = o_id_doc_img;
        
            -- update da data e id_prof no documento
            -- UPDATE doc_external
            --   SET dt_updated = current_timestamp, id_professional_upd = i_prof.id
            -- WHERE id_doc_external = l_id_doc_external
            --   AND flg_status <> pk_doc.g_doc_pendente;
        
            l_rowids := table_varchar();
            g_error  := 'Call ts_doc_external.upd / ID_DOC_EXTERNAL_IN=' || l_id_doc_external;
            ts_doc_external.upd(dt_updated_in          => current_timestamp,
                                id_professional_upd_in => i_prof.id,
                                where_in               => 'id_doc_external =' || l_id_doc_external ||
                                                          'AND flg_status <> ''' || pk_doc.g_doc_pendente || '''',
                                rows_out               => l_rowids);
        
            g_error := 'Call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_EXTERNAL',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_DOC_ATTACH', 'UPDATE_IMAGE');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END update_image;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'UPDATE doc_image';
        UPDATE doc_image
           SET flg_import        = 'Y',
               dt_import_tstz    = current_timestamp,
               flg_status        = g_img_active,
               flg_img_thumbnail = i_flg_thumb,
               img_size         =
               (SELECT dbms_lob.getlength(doc_img)
                  FROM doc_image
                 WHERE id_doc_image = i_id_doc_img)
         WHERE id_doc_image = i_id_doc_img;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_DOC_ATTACH', 'UPDATE_DATE');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END update_date;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'UPDATE doc_image';
        UPDATE doc_image
           SET flg_import = 'Y', dt_import_tstz = current_timestamp, flg_status = g_img_active
         WHERE id_doc_image = i_id_doc_img;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_DOC_ATTACH', 'UPDATE_DATE');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END update_date;

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
    ) RETURN BOOLEAN IS
        l_result BOOLEAN;
    BEGIN
        l_result := insert_emptyblob(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_id_doc           => i_id_doc,
                                     i_oid              => i_oid,
                                     i_dt_img           => i_date,
                                     i_file_name        => i_file_name,
                                     i_server_file_name => NULL,
                                     i_title            => i_title,
                                     i_mime_type        => i_mime_type,
                                     o_id_doc_img       => o_id,
                                     o_error            => o_error);
    
        IF l_result
        THEN
            l_result := upload_blob(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_doc_img => o_id,
                                    o_img        => o_attachment,
                                    o_thumb      => o_attachment_thumb,
                                    o_error      => o_error);
        END IF;
    
        RETURN l_result;
    END;

BEGIN

    g_img_active   := 'A';
    g_img_inactive := 'I';

END;
/
