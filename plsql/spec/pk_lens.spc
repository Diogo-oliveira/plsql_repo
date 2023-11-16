/*-- Last Change Revision: $Rev: 2028777 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lens IS

    FUNCTION is_lens_available
    (
        i_lens lens.id_lens%TYPE,
        i_prof profissional
    ) RETURN lens_soft_inst.rank%TYPE;

    /**
    * Gets the list of lens available.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_lens      The parent id_lens.
    *
    * @param o_lens         The list of lens available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION get_lens_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_lens IN lens.id_lens%TYPE,
        o_lens    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of advanced inputs available for the given id_lens.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_lens      The lens Id.
    *
    * @param o_adv_inp      The list of advanced inputs and respctive fields.
    * @param o_adv_inp_form The format of the description of each advanced input.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION get_adv_inp_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_lens      IN lens.id_lens%TYPE,
        o_adv_inp      OUT pk_types.cursor_type,
        o_adv_inp_form OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a list of new lens prescriptions.
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_episode           Episode Id.
    * @param i_id_patient           Patient Id.
    * @param i_id_lens              Array of lens Id.
    * @param i_id_adv_inp           Array of Array of advanced input Ids.
    * @param i_id_adv_inp_field_det Array of Array of advanced input field Ids.
    * @param i_values               Array of Array of values.
    * @param i_notes                Array of notes.
    *
    * @param o_id_lens_presc        The created prescrition Ids.
    * @param o_error                Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION create_presc_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_lens              IN table_number,
        i_id_adv_inp           IN table_table_number,
        i_id_adv_inp_field_det IN table_table_number,
        i_values               IN table_table_varchar,
        i_notes                IN table_varchar,
        o_id_lens_presc        OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates lens prescriptions state to printed.
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_id_episode    The episode Id.
    * @param i_id_patient    The patient Id.
    * @param i_id_lens_presc The list of lens prescription Id.
    *
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/14
    */

    FUNCTION set_presc_list_print
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN lens_presc.id_episode%TYPE,
        i_id_lens_presc IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates lens prescriptions state to cancelled.
    *
    * @param i_lang             Language identifier.
    * @param i_prof             The professional record.
    * @param i_id_lens_presc    The lens prescription Id.
    * @param i_id_episode       The episode Id.
    * @param i_id_cancel_reason Cancel reason Id.
    * @param i_notes            Cancelling notes.
    * @param i_confirmation     If the user has confirmed the cancellation.
    *
    * @param o_flg_show         If the confirmation window will show up.
    * @param o_msg_title        The title of the confirmation window.
    * @param o_msg              The text message of the confirmation window.
    * @param o_button           The buttons within the confirmation window.
    * @param o_cursor           The list of lens prescription types.
    * @param o_error            Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/14
    */

    FUNCTION set_presc_list_cancel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN lens_presc.id_episode%TYPE,
        i_id_lens_presc    IN table_number,
        i_id_cancel_reason IN NUMBER,
        i_notes            IN VARCHAR2,
        i_confirmation     IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_cursor           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates lens prescriptions values.
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_episode           The episode Id.
    * @param i_id_lens_presc        The list of lens prescription Id.
    * @param i_id_lens              The list of lens Id.
    * @param i_id_adv_inp           The list of list of advanced input Id.
    * @param i_id_adv_inp_field_det The list of list of advanced input field Id.
    * @param i_values               The list of list of values.
    * @param i_notes                Notes.
    *
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/14
    */

    FUNCTION set_presc_list_values
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN lens_presc.id_episode%TYPE,
        i_id_lens_presc        IN table_number,
        i_id_lens              IN table_number,
        i_id_adv_inp           IN table_table_number,
        i_id_adv_inp_field_det IN table_table_number,
        i_values               IN table_table_varchar,
        i_notes                IN table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the degrees of a glasses prescription.
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_lens_presc        The lens prescription Id.
    * @param i_id_lens_presc_hist   The historical lens prescription Id.
    * @param i_flg_type             Lens type - (L)ens or (G)lasses.
    * @param i_flg_adv_inp          L-Left eye; R-Right eye.
    * @param i_flg_show_not_printed Show (Y) or Do not show (N) degrees for not printed prescriptions.
    *
    * @return  the degrees of a glasses prescription.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/21
    */

    FUNCTION get_degrees
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_lens_presc      IN lens_presc.id_lens_presc%TYPE,
        i_id_lens_presc_hist IN lens_presc_hist.id_lens_presc_hist%TYPE,
        i_flg_type           IN lens.flg_type%TYPE,
        i_flg_adv_inp        IN VARCHAR2
    ) RETURN VARCHAR;

    /**
    * Gets the information of a lens prescription.
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_lens_presc        The lens prescription Id.
    * @param i_id_lens_presc_hist   The historical lens prescription Id.
    * @param i_flg_type             Lens type - (L)ens or (G)lasses.
    * @param i_flg_adv_inp          L-Left eye; R-Right eye; O-Other field.
    * @param i_ign_perm             Ignore permanent fields - Y/N.
    *
    * @return  the information of a lens prescription.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/21
    */

    FUNCTION get_presc_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_lens_presc      IN lens_presc.id_lens_presc%TYPE,
        i_id_lens_presc_hist IN lens_presc_hist.id_lens_presc_hist%TYPE,
        i_flg_type           IN lens.flg_type%TYPE,
        i_flg_adv_inp        IN VARCHAR2,
        i_ign_perm           IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR;

    /**
    * Checks whether permanent field is to be ignored or not.
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    *
    * @return  Y - if permanent field is to be ignored. N - otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/21
    */

    FUNCTION get_ignore_perm
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /**
    * Gets the list of lens prescriptions.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   The episode Id.
    * @param i_id_patient   The patient Id.
    *
    * @param o_grid         The list of lens prescritions.
    * @param o_details      The data of the list of lens prescritions.
    *
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION get_presc_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN lens.id_lens%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_grid       OUT pk_types.cursor_type,
        o_details    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the details of a lens prescription.
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_id_lens_presc Lens prescription Id.
    * @param i_flg_show_hist Y-Show historical data. N-Do not show historical data.
    *
    * @param o_presc_det     The list of lens prescritions.
    *
    * @param o_error         Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION get_presc_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_lens_presc IN lens_presc.id_lens_presc%TYPE,
        i_flg_show_hist IN VARCHAR2,
        o_presc_det     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves the data from the template of the physical exam section.
    * WARNING - DUMMY FUNCTION!
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_id_episode    Episode Id.
    *
    * @param o_data          The template data.
    *
    * @param o_error         Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION get_physical_exam_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the lens prescriptions within the patient's EHR.
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_id_patient    Patient Id.
    *
    * @param o_cursor        The list of lens prescriptions.
    *
    * @param o_error         Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */

    FUNCTION get_ehr_presc_lens
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the lens prescriptions within a single episode.
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_id_episode    Episode Id.
    * @param i_id_epis_type  Episode type Id.
    *
    * @return  the lens prescriptions within a single episode.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2008/12/24
    */
    FUNCTION get_ehr_presc_lens_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN table_varchar;

    /**
    * Gets the details of a lens prescription to be used by the reports engine.
    *
    * @param i_lang          Language identifier.
    * @param i_prof          The professional record.
    * @param i_id_lens_presc Lens prescription Id.
    *
    * @param o_presc_det_rep     The details of the lens prescrition.
    * @param o_data              Additional data.
    *
    * @param o_error         Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/04/14
    */

    FUNCTION get_presc_det_rep
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_lens_presc IN lens_presc.id_lens_presc%TYPE,
        o_presc_det_rep OUT pk_types.cursor_type,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the information of a lens prescription.
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param i_id_lens_presc        The lens prescription Id.
    * @param i_id_lens_presc_hist   The historical lens prescription Id.
    * @param i_flg_type             Lens type - (L)ens or (G)lasses.
    * @param i_flg_adv_inp          L-Left eye; R-Right eye; O-Other field.
    * @param i_ign_perm             Ignore permanent fields - Y/N.
    *
    * @return  the information of a lens prescription.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/21
    */

    FUNCTION get_presc_info_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_lens_presc      IN lens_presc.id_lens_presc%TYPE,
        i_id_lens_presc_hist IN lens_presc_hist.id_lens_presc_hist%TYPE,
        i_flg_type           IN lens.flg_type%TYPE,
        i_flg_adv_inp        IN VARCHAR2,
        i_ign_perm           IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR;

    g_package_owner VARCHAR2(50 CHAR);
    g_package_name  VARCHAR2(50 CHAR);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);
    g_error_code      VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;

    g_msg_invalid   CONSTANT VARCHAR2(3) := '---';
    g_msg_sign_mult CONSTANT VARCHAR2(3) := 'x';
    g_msg_sign_plus CONSTANT VARCHAR2(3) := ' +';

    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

END pk_lens;
/
