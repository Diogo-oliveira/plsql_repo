/*-- Last Change Revision: $Rev: 1976403 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-01-15 12:10:51 +0000 (sex, 15 jan 2021) $*/
CREATE OR REPLACE PACKAGE pk_bdnp IS

    -- Author  : JOANA.BARROSO
    -- Created : 10-07-2012 16:16:05
    -- Purpose : 

    FUNCTION check_referral_home
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_type        IN p1_external_request.flg_type%TYPE,
        o_home_active OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Returns the information of the prescription light license of an user/institution                                                         *
    *                                                                                                                                          *
    * @param i_lang            LANGUAGE                                                                                                        *
    * @param i_prof            PROFESSIONAL ARRAY                                                                                              *
    * @param o_licenses_left   Licenses remaining (for PRE only)                                                                               *
    *                                                                                                                                          *
    * @param o_error           Message error to be shown to the user.                                                                          *
    *                                                                                                                                          *
    * @return  TRUE if succeeded. FALSE otherwise.                                                                                             *
    *                                                                                                                                          *
    * @author                         Nuno Antunes                                                                                             *
    * @version                        1.0                                                                                                      *
    * @since                          2011/03/23                                                                                               *
    *                                                                                                                                          *
    ********************************************************************************************************************************************/
    FUNCTION presc_light_get_license_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_licenses_left         OUT NUMBER,
        o_flg_show_almost_empty OUT VARCHAR2,
        o_almost_empty_msg      OUT VARCHAR2,
        o_flg_show_warning      OUT VARCHAR2,
        o_warning_msg           OUT VARCHAR2,
        o_header_msg            OUT VARCHAR2,
        o_show_warnings         OUT VARCHAR2,
        o_shortcut              OUT NUMBER,
        o_buttons               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Set table set_bdnp_presc_detail
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode
    * @param i_type                   M - Medication, R - Referral
    * @param i_presc                  Referral Id or Medication Id
    * @param i_flg_isencao            Y- Insento, N - Não isento (Just for referral)
    * @param i_mcdt_nature            MCDT_NATURE (Just for referral)
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/11/16    
    **********************************************************************************************/

    FUNCTION set_bdnp_presc_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_type        IN bdnp_presc_detail.flg_presc_type%TYPE,
        i_presc       IN bdnp_presc_detail.id_presc%TYPE,
        i_flg_isencao IN VARCHAR2 DEFAULT NULL,
        i_mcdt_nature IN VARCHAR2 DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bdnp_presc_tracking
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_bdnp_presc_tracking IN bdnp_presc_tracking%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_patient_rules
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN alert.profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_type           IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

-- Public variable declarations

END pk_bdnp;
/
