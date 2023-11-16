/*-- Last Change Revision: $Rev: 2027527 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_profphoto AS

    /******************************************************************************
       OBJECTIVO:   Retornar foto do PROFISSIONAL
       PARAMETROS:  Entrada: I_PPROF - ID do PROFESSIONAL
              Saida:   O_IMG - foto
                 O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/04/08
      NOTAS:
      
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION get_blob
    (
        i_prof      IN prof_photo.id_professional%TYPE,
        i_prof_user IN profissional,
        o_img       OUT BLOB,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang   sys_config.value%TYPE := 2; --lang default for errors
        tbl_blob table_blob;
    BEGIN
    
        g_error := 'GET PHOTO';
        SELECT img_photo
          BULK COLLECT
          INTO tbl_blob
          FROM prof_photo
         WHERE id_professional = i_prof;
    
        IF tbl_blob.count > 0
        THEN
            o_img := tbl_blob(1);
        END IF;
    
        o_img := pk_tech_utils.set_empty_blob(o_img);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BLOB',
                                              o_error);
            RETURN FALSE;
    END get_blob;

    /******************************************************************************
       OBJECTIVO:   Guardar foto do PROFISSIONAL
       PARAMETROS:  Entrada: I_PAT - ID do PROF
              Saida:   O_IMG - foto
                 O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/04/08
      NOTAS: insere um empty BLOB caso o BLOB não exista
      
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION insert_emptyblob
    (
        i_prof      IN prof_photo.id_professional%TYPE,
        i_prof_user IN profissional,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER(24);
        l_lang  sys_config.value%TYPE;
    
    BEGIN
    
        l_lang  := pk_sysconfig.get_config('LANGUAGE', i_prof_user);
        g_error := 'GET CURSOR C_PHOTO';
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_photo
         WHERE id_professional = i_prof;
    
        IF l_count = 0
        THEN
        
            g_error := 'INSERT ' || i_prof;
            INSERT INTO prof_photo
                (id_prof_photo, id_professional, dt_photo_tstz, img_photo)
            VALUES
                (seq_prof_photo.nextval, i_prof, current_timestamp, empty_blob());
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_EMPTYBLOB',
                                              o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
    END insert_emptyblob;

    /******************************************************************************
       OBJECTIVO:   Reservar registo para actualização
       PARAMETROS:  Entrada: I_PROF- ID do PROFESSIONAL
              Saida:   O_IMG - foto
                 O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/04/08
      NOTAS:
    
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION upload_blob
    (
        i_prof      IN prof_photo.id_professional%TYPE,
        i_prof_user IN profissional,
        o_img       OUT BLOB,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang sys_config.value%TYPE;
    
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof_user);
    
        SELECT img_photo
          INTO o_img
          FROM prof_photo
         WHERE id_professional = i_prof
           FOR UPDATE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPLOAD_BLOB',
                                              o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
    END upload_blob;

    /******************************************************************************
       OBJECTIVO:   Retornar directoria onde se encrontra a foto do doente
       PARAMETROS:  Entrada: I_ID_PROF - PROFESSIONAL
              Saida:
    
      CRIAÇÃO: RPP 2005/04/08
      NOTAS:
    *********************************************************************************/
    FUNCTION get_prof_photo(i_id_prof IN profissional) RETURN VARCHAR2 IS
    
        l_path     sys_config.value%TYPE;
        l_id_photo prof_photo.id_prof_photo%TYPE;
        tbl_photo  table_number;
    
    BEGIN
    
        SELECT id_prof_photo
          BULK COLLECT
          INTO tbl_photo
          FROM prof_photo
         WHERE id_professional = i_id_prof.id;
    
        IF tbl_photo.count > 0
        THEN
            IF i_id_prof.id != 0
            THEN
            
                IF NOT
                    pk_sysconfig.get_config(i_code_cf => 'URL_PROF_PHOTO_READ', i_prof => i_id_prof, o_msg_cf => l_path)
                THEN
                    RETURN NULL;
                END IF;
                l_path := l_path || i_id_prof.id;
            END IF;
        END IF;
    
        RETURN l_path;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_photo;

    /******************************************************************************
       OBJECTIVO:   Retornar Y / N conforme encontra ou ñ foto para o doente
       PARAMETROS:  Entrada: I_PROF - ID do profissional
              Saida:
    
      CRIAÇÃO: SS 2006/06/27
      NOTAS:
    *********************************************************************************/
    FUNCTION check_blob(i_prof IN prof_photo.id_professional%TYPE) RETURN VARCHAR2 IS
    
        l_count NUMBER(24);
        l_char  VARCHAR2(1 CHAR);
        l_flg   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_photo
         WHERE id_professional = i_prof;
    
        IF l_count > 0
        THEN
            l_flg := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_flg;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_blob;

    /**
    * Gives the professional photo url.
    * When the professional has no photo null is returned in url.
    * 
    * @param i_lang      The language id
    * @param i_id_prof   The professional id to which we want to know about the photo.
    * @param i_prof      Ids about professional, institution and software executing the function
    * @param o_url       The professional photo url. Null if it has no photo.
    * @param o_error     An error message in case of an error condition
    * 
    * @ret A boolean value. True if success, false otherwise
    * 
    * @author Luís Gaspar
    * @ver    2007-Mar-13
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    */
    FUNCTION get_prof_photo_url
    (
        i_lang    language.id_language%TYPE,
        i_id_prof professional.id_professional%TYPE,
        i_prof    IN profissional,
        o_url     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional;
    
    BEGIN
    
        o_url   := NULL;
        g_error := 'CHECK_BLOB';
    
        IF (check_blob(i_id_prof) = pk_alert_constant.g_yes)
        THEN
            l_prof  := profissional(i_id_prof, i_prof.institution, i_prof.software);
            g_error := 'GET_PAT_PHOTO';
            o_url   := get_prof_photo(l_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_url := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_PHOTO_URL',
                                              o_error);
            pk_utils.undo_changes();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_photo_url;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_profphoto;
/
