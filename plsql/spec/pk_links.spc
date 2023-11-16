/*-- Last Change Revision: $Rev: 2049318 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-11-08 08:27:45 +0000 (ter, 08 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_links IS

    /*
    * Called when the user clinks on a link to be possible to be audited
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_patient   Patient id
    * @param     i_episode   Episode id
    * @param     i_link      Link url
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.8.4
    * @since     2022/11/04
    */

    FUNCTION set_link
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_link    IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get links
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_parent              parent link identifier
    * @param i_id_patient             patient identifier
    * @param i_id_episode             episode identifier
    * @param o_links                  cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo teixeira
    * @version                        2.6.1.2
    * @since                          2011/07/27
    */

    FUNCTION get_links
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_parent  IN external_link.id_parent%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_links      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_links
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_parent  IN external_link.id_parent%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN table_varchar,
        o_links      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_google_map_link
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_link           OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_links_label
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_links IN external_link.id_external_link%TYPE,
        i_sep      IN VARCHAR2 DEFAULT '<br>'
    ) RETURN VARCHAR2;

    FUNCTION get_links_val
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_content IN external_link.id_content%TYPE
    ) RETURN VARCHAR2;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);
    g_error_code      VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_flg_folder   external_link.flg_type%TYPE := 'F';
    g_flg_link     external_link.flg_type%TYPE := 'L';
    g_flg_link_api external_link.flg_type%TYPE := 'LAPI';
    g_flg_link_ia  external_link.flg_type%TYPE := 'LIA';

    g_normal_link  CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_context_link CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_google_maps_url     CONSTANT VARCHAR2(50 CHAR) := 'https://www.google.com/maps/search/?api=1&query=';
    g_pat_address_min_len CONSTANT NUMBER := 7;

END pk_links;
/
