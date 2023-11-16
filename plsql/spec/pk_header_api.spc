/*-- Last Change Revision: $Rev: 1884407 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2019-01-08 10:52:18 +0000 (ter, 08 jan 2019) $*/

CREATE OR REPLACE PACKAGE pk_header_api IS

    /**
    * Returns the header id for the context set by the variables given as parameters
    */
    FUNCTION get_id_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_screen_mode IN header.flg_screen_mode%TYPE,
        o_id_header   OUT header.id_header%TYPE
    ) RETURN BOOLEAN;

    /**
    * Returns the data to be shown in the header
    *
    * @param i_arr_tag           List of tags     
    * @param i_lang              Language identifier
    * @param i_prof              Professional
    * @param i_id_episode        Episode Id
    * @param i_id_patient        Patient Id
    * @param i_id_schedule       Schedule Id
    * @param i_flg_area          System application area flag
    * @param i_id_keys           List of additional keys
    * @param i_id_values         List of values to be mapped with the list of keys
    *
    * @param o_data              List of tags and values to be replaced in the header.
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/07
    */
    FUNCTION get_header_data
    (
        i_arr_tag     IN table_varchar,
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        i_id_keys     IN table_varchar,
        i_id_values   IN table_varchar,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);

END pk_header_api;
/
