/*-- Last Change Revision: $Rev: 1988130 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-05-05 15:53:57 +0100 (qua, 05 mai 2021) $*/

CREATE OR REPLACE PACKAGE pk_cancel_reason_ux IS

    /**
    * Checks if the cancel reason is to be shown or not.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           The professional record.
    * @param i_tbl_task_type  The array of task types related with the areas.
    *
    * @param o_flg_mandatory  Y - Cancel reason is mandatory, will be shown in cancel screen; N - Isn't mandatory.
    * @param o_error          Error
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    16-03-2015
    */
    FUNCTION check_cancel_reason_mandatory
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_task_type IN table_number,
        i_action        IN NUMBER DEFAULT NULL,
        o_flg_mandatory OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the priority field is to be shown and returns the corresponding default value.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           The professional record.
    * @param i_tbl_task_type  The array of task types related with the areas.
    *
    * @param o_flg_mandatory  Y - Priority field is mandatory, will be shown in cancel screen; N - Isn't mandatory.
    * @param o_default_value  Y - Checked; N- Otherwise.
    * @param o_error          Error
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    16-03-2015
    */
    FUNCTION check_configurations
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_tbl_task_type    IN table_number,
        i_action           IN NUMBER DEFAULT NULL,
        o_flg_mandatory    OUT VARCHAR2,
        o_default_value    OUT VARCHAR2,
        o_flg_date_visible OUT VARCHAR2,
        o_date_mandatory   OUT VARCHAR2,
        o_min_date         OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_content_by_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE
    ) RETURN cancel_reason.id_content%TYPE;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

END pk_cancel_reason_ux;
/
