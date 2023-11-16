/*-- Last Change Revision: $Rev: 2027470 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patphoto AS

    /** 
    *  Verify if photo blob is empty
    *
    * @param i_pat   Patient
    * @param i_prof  Professional
    *
    * @return     Y if is empty and N if not
    * @author     Rui Spratley
    * @version    2.5.0.7
    * @since      2009/11/04
    */
    
      FUNCTION is_blob_empty
      (
          i_pat  IN pat_photo.id_patient%TYPE,
          i_prof IN profissional
    
      ) RETURN VARCHAR2 IS
          l_compare NUMBER;
      BEGIN
      
          SELECT COUNT(1)
            INTO l_compare
            FROM pat_photo pp
           WHERE pp.id_patient = i_pat
             AND dbms_lob.compare(pp.img_photo, empty_blob()) = 0;
      
          IF l_compare > 0
          THEN
              --The BLOB is EMPTY
              RETURN pk_alert_constant.g_yes;
          ELSE
              --The BLOB is not EMPTY
              RETURN pk_alert_constant.g_no;
          END IF;
      EXCEPTION
          WHEN OTHERS THEN
              RETURN pk_alert_constant.g_no;
      END;
    

    /******************************************************************************
       OBJECTIVO:   Retornar foto do doente
       PARAMETROS:  Entrada: I_PAT - ID do doente
          Saida:   O_IMG - foto
           O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/02/24
      NOTAS:
      
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION get_blob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_img   OUT BLOB,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang sys_config.value%TYPE;
        l_tmp  BLOB;
        CURSOR xpp_c IS
            SELECT img_photo
            --INTO o_img
              FROM pat_photo
             WHERE id_patient = i_pat;
    
        TYPE xpp_c_type IS TABLE OF xpp_c%ROWTYPE;
        tbl_photo xpp_c_type;
    
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof);
    
        OPEN xpp_c;
        FETCH xpp_c BULK COLLECT
            INTO tbl_photo;
        CLOSE xpp_c;
    
        o_img := NULL;
        IF tbl_photo.count > 0
        THEN
            l_tmp := tbl_photo(1).img_photo;
            o_img := pk_tech_utils.set_empty_blob(l_tmp);
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
                                              'GET_BLOB',
                                              o_error);
            RETURN FALSE;
    END get_blob;

    -- ******************************************************************************
    -- OBJECTIVO:   Retornar Y / N conforme encontra ou ñ foto para o doente
    -- PARAMETROS:  Entrada: I_PAT - ID do doente
    --   Saida:
    -- 
    -- CRIAÇÃO: CRS 2005/04/13
    -- NOTAS:
    -- *********************************************************************************

    FUNCTION check_blob(i_pat IN pat_photo.id_patient%TYPE) RETURN VARCHAR2 IS
        l_flg   VARCHAR2(0001 CHAR);
        l_count NUMBER;
    BEGIN
    
        l_flg := pk_alert_constant.g_no;
    
        SELECT COUNT(*)
          INTO l_count
          FROM pat_photo
         WHERE id_patient = i_pat;
    
        IF l_count > 0
        THEN
            l_flg := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_flg;
    
    END check_blob;

    /******************************************************************************
       OBJECTIVO:   Guardar foto do doente
       PARAMETROS:  Entrada: I_PAT - ID do doente
          Saida:   O_IMG - foto
           O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/02/24
      NOTAS: insere um empty BLOB caso o BLOB não exista
      
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION insert_emptyblob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_seq pat_photo.id_pat_photo%TYPE;
        l_lang   sys_config.value%TYPE;
    
        l_count NUMBER;
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof);
    
        g_error := 'GET CURSOR C_PHOTO';
        SELECT COUNT(*)
          INTO l_count
          FROM pat_photo
         WHERE id_patient = i_pat;
    
        IF l_count = 0
        THEN
            g_error  := 'GET SEQ_PAT_PHOTO.NEXTVAL';
            l_id_seq := seq_pat_photo.nextval;
        
            g_error := 'INSERT';
            INSERT INTO pat_photo
                (id_pat_photo, id_patient, img_photo, dt_photo_tstz)
            VALUES
                (l_id_seq, i_pat, empty_blob(), current_timestamp);
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END insert_emptyblob;

    /******************************************************************************
       OBJECTIVO:   Reservar registo para actualização
       PARAMETROS:  Entrada: I_PAT - ID do doente
          Saida:   O_IMG - foto
           O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/02/24
      NOTAS:
          
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION upload_blob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_img   OUT BLOB,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang sys_config.value%TYPE;
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof);
    
        SELECT img_photo
          INTO o_img
          FROM pat_photo
         WHERE id_patient = i_pat
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
            RETURN FALSE;
    END upload_blob;

    /******************************************************************************
       OBJECTIVO:   ARTIMANHA PARA CORRIGIR O ERRO DO UPDATE DO BLOB (QUANDO FAÇO SÓ O UPDATE DO BLOB O TRIGUER ON_UPDATE NÃO DISPARA)
       NO JAVA DEPOIS DE CHMAR O UPLOAD_PHOT CHAMO SEMPRE ESTA FUNÇÃO
       PARAMETROS:  Entrada: I_PAT - ID do doente
          Saida:   O_IMG - foto
           O_ERROR - erro
    
      CRIAÇÃO: RPP 2005/02/24
      NOTAS:
          
      * UPDATED: ALERT-19390
      * @author  Telmo Castro
      * @date    09-03-2009
      * @version 2.5
    *********************************************************************************/
    FUNCTION update_date
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang sys_config.value%TYPE;
    
    BEGIN
    
        l_lang := pk_sysconfig.get_config('LANGUAGE', i_prof);
        UPDATE pat_photo
           SET dt_photo_tstz = current_timestamp
         WHERE id_patient = i_pat;
    
        --Notify intf_alert with patient photo update
        pk_ia_event_common.patient_update(i_id_patient => i_pat, i_id_institution => i_prof.institution);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DATE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_date;

    /******************************************************************************
       OBJECTIVO:   Retornar directoria onde se encrontra a foto do doente
       PARAMETROS:  Entrada: I_ID_PAT - ID do doente
          Saida:
    
      CRIAÇÃO: RPP 2005/04/08
      NOTAS:
    *********************************************************************************/
    FUNCTION get_pat_foto
    (
        i_id_pat IN NUMBER,
        i_prof   IN profissional
    ) RETURN VARCHAR2 IS
        l_path  sys_config.value%TYPE;
        tbl_pat table_number;
        --l_id_photo pat_photo.id_pat_photo%TYPE;
        l_bool BOOLEAN;
    
    BEGIN
    
        g_error := 'GET CURSOR C_PAT_PHOTO';
    
        SELECT id_pat_photo
          BULK COLLECT
          INTO tbl_pat
          FROM pat_photo
         WHERE id_patient = i_id_pat;
    
        IF tbl_pat.count > 0
        THEN
        
            l_bool := pk_sysconfig.get_config(i_code_cf => 'URL_PAT_PHOTO_READ', i_prof => i_prof, o_msg_cf => l_path);
        
            IF l_bool
            THEN
                l_path := l_path || i_id_pat;
            END IF;
        
        END IF;
    
        RETURN l_path;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_foto;

    /******************************************************************************
       OBJECTIVO:   Retornar directoria onde se encontra a foto do doente
       PARAMETROS:  Entrada: I_ID_PAT - ID do doente
          Saida:
    
      CRIAÇÃO: RPP 2006/01/17
      NOTAS:
    *********************************************************************************/
    FUNCTION get_pat_foto
    (
        i_id_pat IN NUMBER,
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_path sys_config.value%TYPE;
        --l_id_photo pat_photo.id_pat_photo%TYPE;
    BEGIN
    
        l_path := get_pat_foto(i_id_pat => i_id_pat, i_prof => profissional(0, i_inst, i_soft));
    
        RETURN l_path;
    
    END get_pat_foto;

    /**
    * Gives the patient photo url.
    * When the patient has no photo null is returned in url.
    *
    * @param i_lang      The language id
    * @param i_id_pat    The patient id
    * @param i_prof      Ids about professional, institution and software executing the function
    * @param o_url       The patient photo url. Null if the patient has no photo.
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
    FUNCTION get_pat_foto_url
    (
        i_lang   language.id_language%TYPE,
        i_id_pat IN NUMBER,
        i_prof   IN profissional,
        o_url    OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_url   := NULL;
        g_error := 'CHECK_BLOB';
        IF (check_blob(i_id_pat) = pk_alert_constant.g_yes)
        THEN
            g_error := 'GET_PAT_PHOTO';
            o_url   := get_pat_foto(i_id_pat, i_prof);
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
                                              'GET_PAT_FOTO_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_foto_url;

    FUNCTION get_pat_foto_url
    (
        i_lang            language.id_language%TYPE,
        i_id_pat          IN NUMBER,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        o_url             OUT VARCHAR2,
        o_photo_read_only OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool           BOOLEAN;
        l_is_prof_resp   NUMBER;
        l_is_prof_resp_1 NUMBER;
    BEGIN
    
        o_url             := NULL;
        g_error           := 'CHECK_BLOB';
        o_photo_read_only := pk_alert_constant.g_yes;
    
        l_is_prof_resp := pk_patient.get_prof_resp(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_patient  => i_id_pat,
                                                   i_episode  => i_id_episode,
                                                   i_schedule => i_id_schedule);
    
        IF l_is_prof_resp = 0
        THEN
            IF i_id_episode IS NOT NULL
            THEN
                l_is_prof_resp_1 := pk_hand_off_core.is_prof_responsible_current(i_lang          => i_lang,
                                                                                 i_prof          => i_prof,
                                                                                 i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                               i_prof => i_prof),
                                                                                 i_id_episode    => i_id_episode,
                                                                                 i_hand_off_type => NULL);
            
                IF l_is_prof_resp_1 > -1
                THEN
                    l_is_prof_resp := 1;
                ELSE
                    l_is_prof_resp := 0;
                END IF;
            END IF;
        END IF;
    
        l_bool := pk_adt.show_patient_info(i_lang => i_lang, i_patient => i_id_pat, i_is_prof_resp => l_is_prof_resp);
    
        IF l_bool
        THEN
        
            l_bool := get_pat_foto_url(i_lang   => i_lang,
                                       i_id_pat => i_id_pat,
                                       i_prof   => i_prof,
                                       o_url    => o_url,
                                       o_error  => o_error);
        
            IF l_bool
            THEN
                o_photo_read_only := pk_alert_constant.g_no;
            END IF;
        
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
                                              'GET_PAT_FOTO_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_foto_url;

    FUNCTION get_pat_foto_url
    (
        i_lang        language.id_language%TYPE,
        i_id_pat      IN NUMBER,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_dummy   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_bool           BOOLEAN;
        l_is_prof_resp   NUMBER;
        l_is_prof_resp_1 NUMBER;
        l_url            VARCHAR2(200 CHAR);
        l_error          t_error_out;
    BEGIN
    
        l_url   := NULL;
        g_error := 'CHECK_BLOB';
    
        l_is_prof_resp := pk_patient.get_prof_resp(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_patient  => i_id_pat,
                                                   i_episode  => i_id_episode,
                                                   i_schedule => i_id_schedule);
    
        IF l_is_prof_resp = 0
        THEN
            IF i_id_episode IS NOT NULL
            THEN
                l_is_prof_resp_1 := pk_hand_off_core.is_prof_responsible_current(i_lang          => i_lang,
                                                                                 i_prof          => i_prof,
                                                                                 i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                               i_prof => i_prof),
                                                                                 i_id_episode    => i_id_episode,
                                                                                 i_hand_off_type => NULL);
            
                IF l_is_prof_resp_1 > -1
                THEN
                    l_is_prof_resp := 1;
                ELSE
                    l_is_prof_resp := 0;
                END IF;
            END IF;
        END IF;
    
        l_bool := pk_adt.show_patient_info(i_lang => i_lang, i_patient => i_id_pat, i_is_prof_resp => l_is_prof_resp);
    
        IF l_bool
        THEN
        
            l_bool := get_pat_foto_url(i_lang   => i_lang,
                                       i_id_pat => i_id_pat,
                                       i_prof   => i_prof,
                                       o_url    => l_url,
                                       o_error  => l_error);
        
        END IF;
    
        RETURN l_url;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_FOTO_URL',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_pat_foto_url;

    /**
    * Returns the patient photo or silhuette.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id   
    *
    * @return                       The patient s photo
    *
    * @author   BM
    * @version  2.6
    * @since    2010/03/12
    */

    FUNCTION get_pat_alias(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
        tbl_alias table_varchar;
        l_return  VARCHAR2(1000 CHAR);
    BEGIN
    
        SELECT alias
          BULK COLLECT
          INTO tbl_alias
          FROM patient
         WHERE id_patient = i_id_patient;
    
        IF tbl_alias.count > 0
        THEN
            l_return := tbl_alias(1);
        END IF;
    
        RETURN l_return;
    
    END get_pat_alias;

    --******************************************************************************
    FUNCTION get_pat_photo_base
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_return0     IN VARCHAR2,
        i_return1     IN VARCHAR2,
        i_return2     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        vpatalias patient.alias%TYPE;
        l_contact VARCHAR2(1 CHAR);
        l_return  VARCHAR2(1000 CHAR);
        l_bool    BOOLEAN;
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
        
            vpatalias := get_pat_alias(i_id_patient => i_id_patient);
        
            l_contact := pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => i_id_patient);
        
            IF l_contact = pk_alert_constant.g_yes
            THEN
                l_return := i_return0;
            ELSE
            
                l_bool := pk_patphoto.check_blob(i_id_patient) = pk_alert_constant.g_no;
            
                l_bool := l_bool OR
                          (vpatalias IS NOT NULL AND
                          pk_patient.get_prof_resp(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule) != 1);
            
                IF l_bool
                THEN
                    l_return := i_return1;
                ELSE
                    l_return := i_return2;
                END IF;
            
            END IF;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_photo_base;

    FUNCTION get_pat_photo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        k_contact_01 CONSTANT VARCHAR2(0050 CHAR) := 'ContactCreation';
        l_return1 VARCHAR2(1000 CHAR);
        l_return2 VARCHAR2(1000 CHAR);
        l_return  VARCHAR2(1000 CHAR);
    BEGIN
    
        l_return1 := pk_hea_prv_pat.get_silhouette(i_prof, i_id_patient);
        l_return2 := pk_patphoto.get_pat_foto(i_id_patient, i_prof);
    
        l_return := get_pat_photo_base(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_id_patient  => i_id_patient,
                                       i_id_episode  => i_id_episode,
                                       i_id_schedule => i_id_schedule,
                                       i_return0     => k_contact_01,
                                       i_return1     => l_return1,
                                       i_return2     => l_return2);
    
        RETURN l_return;
    
    END get_pat_photo;

    FUNCTION get_pat_photo_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_patphoto.get_pat_foto_url(i_lang, i_id_patient, i_prof, i_id_episode, i_id_schedule, 'Y');
    
        RETURN l_return;
    
    END get_pat_photo_header;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
