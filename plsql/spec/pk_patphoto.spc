/*-- Last Change Revision: $Rev: 2028855 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patphoto AS

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
    ) RETURN VARCHAR2;
    

    FUNCTION get_blob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_img   OUT BLOB,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_blob(i_pat IN pat_photo.id_patient%TYPE --,
                        /*I_PROF IN PROFISSIONAL*/) RETURN VARCHAR2;

    FUNCTION insert_emptyblob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upload_blob
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_img   OUT BLOB,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_date
    (
        i_pat   IN pat_photo.id_patient%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_foto
    (
        i_id_pat IN NUMBER,
        i_prof   IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_pat_foto
    (
        i_id_pat IN NUMBER,
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the patient photo according with VIP requirements.
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
    FUNCTION get_pat_photo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

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
    */
    FUNCTION get_pat_foto_url
    (
        i_lang   language.id_language%TYPE,
        i_id_pat IN NUMBER,
        i_prof   IN profissional,
        o_url    OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gives the patient photo url with VIP requirements.
    * When the patient has no photo null is returned in url.
    *
    * @param i_lang      The language id
    * @param i_id_pat    The patient id
    * @param i_prof      Ids about professional, institution and software executing the function
    * @param i_id_episode      Id context episode
    * @param i_id_schedule      Id context schedule (ambulatory products)
    * @param o_url       The patient photo url. Null if the patient has no photo.
    * @param o_photo_read_only       Boolean to put photo deepnav in read only mode.
    * @param o_error     An error message in case of an error condition
    *
    * @ret A boolean value. True if success, false otherwise
    *
    * @author Bruno Martins
    * @ver    2010-06-17
    */
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
    ) RETURN BOOLEAN;

    FUNCTION get_pat_foto_url
    (
        i_lang        language.id_language%TYPE,
        i_id_pat      IN NUMBER,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_dummy   IN VARCHAR2
    ) RETURN VARCHAR2;

    --    FUNCTION photo_transfer RETURN BOOLEAN;

    FUNCTION get_pat_photo_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    g_error VARCHAR2(4000); -- Localização do erro
    g_found BOOLEAN;

    /* Tipos e variáveis usados pelos triggers de PAT_PHOTO usados para transferir
    as fotografias dos pacientes para o ER */

    TYPE newpatphotoarray IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    TYPE updpatphotoarray IS TABLE OF NUMBER(24) INDEX BY BINARY_INTEGER;

    /* Variaveis usadas pelo trigger que transfere fotos para o ER*/
    --newRows newPatPhotoArray;
    --emptyNewRows newPatPhotoArray;
    updrows      updpatphotoarray;
    emptyupdrows updpatphotoarray;

    g_package_name  VARCHAR2(200);
    g_package_owner VARCHAR2(200);

END;
/
