/*-- Last Change Revision: $Rev: 2029049 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_wizards_core IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 04-12-2010 07:11:27
    -- Purpose : Alert wizards logic

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Verifies if i_screen_name is in a wizard for the current i_prof profile and if so returns a shortcut
    * otherwise returns NULL
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_patient       Patient id
    * @param   i_screen_name   Screen name
    *
    * @param   o_shortcut      Shortcut for the next screen if in a wizard, otherwise NULL
    * @param   o_doc_area      Doc area id
    * @param   o_short_btn_lbl Shortcut button label
    * @param   o_error         Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.5
    * @since   04-12-2010
    */
    FUNCTION get_shortcut
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_screen_name   IN wizard_comp_screens.screen_name%TYPE,
        o_shortcut      OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_doc_area      OUT doc_area.id_doc_area%TYPE,
        o_short_btn_lbl OUT pk_translation.t_desc_translation,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if some professional with the same category of i_prof already inserted data in screen component
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_screen_name  Screen name
    *
    * @param   o_flg_has_data Component already has data?
    * @param   o_error        Error information
    *
    * @value   o_flg_has_data {*} 'Y' Yes
    *                         {*} 'N' No
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.5
    * @since   28-01-2011
    *
    * @changed Alexandre Santos
    * @version 2.5.1.3
    * @since   16-02-2011
    * @motive  Verify in vital_sign component if data was previously inserted in triage, 
    *          if so considered as if no data has been entered
    */
    FUNCTION check_profcat_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_screen_name  IN wizard_comp_screens.screen_name%TYPE,
        o_flg_has_data OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
END pk_wizards_core;
/
