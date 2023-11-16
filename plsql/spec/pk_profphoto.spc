/*-- Last Change Revision: $Rev: 2028883 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_profphoto AS

    FUNCTION get_blob
    (
        i_prof      IN prof_photo.id_professional%TYPE,
        i_prof_user IN profissional,
        o_img       OUT BLOB,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_emptyblob
    (
        i_prof      IN prof_photo.id_professional%TYPE,
        i_prof_user IN profissional,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upload_blob
    (
        i_prof      IN prof_photo.id_professional%TYPE,
        i_prof_user IN profissional,
        o_img       OUT BLOB,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_photo(i_id_prof IN /*NUMBER*/ profissional) RETURN VARCHAR2;

    FUNCTION check_blob(i_prof IN prof_photo.id_professional%TYPE) RETURN VARCHAR2;

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
    */
    FUNCTION get_prof_photo_url
    (
        i_lang    LANGUAGE.id_language%TYPE,
        i_id_prof professional.id_professional%TYPE,
        i_prof    IN profissional,
        o_url     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000); -- Localização do erro 
    g_found BOOLEAN;

    g_package_name  VARCHAR2(200 CHAR);
    g_package_owner VARCHAR2(200 CHAR);
END pk_profphoto;
/
