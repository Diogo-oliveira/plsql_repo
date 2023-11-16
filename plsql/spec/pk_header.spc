/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_header IS

    /**
    * Returns the list of headers available for the logged professional.
    *
    * @param i_lang              Language identifier
    * @param i_prof              Professional
    *
    * @param o_headers           The list of headers available for the logged professional
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_header_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_headers OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the header and the list of values to be filled in it.
    *
    * @param i_lang              Language identifier
    * @param i_prof              Professional
    *
    * @param i_id_episode        Episode Id
    * @param i_id_patient        Patient Id
    * @param i_id_schedule       Schedule Id
    * @param i_screen_mode       Screen mode [N-Normal, F-Fullscreen]
    * @param i_flg_area          System application area flag
    * @param i_id_keys           List of additional keys
    * @param i_id_values         List of values to be mapped with the list of keys
    *
    * @param o_id_header         The header Id to be shown
    * @param o_data              List of tags and values to be replaced in the header.
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_screen_mode IN header.flg_screen_mode%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        i_id_keys     IN table_varchar,
        i_id_values   IN table_varchar,
        o_id_header   OUT header.id_header%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Generates the dml for a new header (inserts in the header table with the corresponding tags in the hea_header_tags table)
    * (the tags are read and validated from the xml provided)
    * (for development use only)
    *
    * @param i_lang              Language identifier
    * @param [i_id_header]       Header id - default null
    * @param i_internal_name     Header internal name
    * @param i_internal_desc     Header internal description
    * @param i_xml_format        XML used to construct the header
    * @param i_flg_screen_mode   Screen mode (Normal, Full-Screen)
    *
    * @param o_sql               The generated SQL script
    * @param o_id_header         The header id (created or updated)
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/03/07
    */
    FUNCTION insert_into_header
    (
        i_lang            IN language.id_language%TYPE,
        i_id_header       IN header.id_header%TYPE DEFAULT NULL,
        i_internal_name   IN header.internal_name%TYPE,
        i_internal_desc   IN header.internal_desc%TYPE,
        i_xml_format      IN LONG,
        i_flg_screen_mode IN header.flg_screen_mode%TYPE,
        o_sql             OUT LONG,
        o_id_header       OUT header.id_header%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;

END pk_header;
/
