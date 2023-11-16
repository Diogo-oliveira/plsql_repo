/*-- Last Change Revision: $Rev: 2027877 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wizards_ux IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SHORTCUT';
    BEGIN
        g_error := 'CALL TO PK_WIZARDS_CORE.GET_SHORTCUT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_wizards_core.get_shortcut(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_patient       => i_patient,
                                            i_screen_name   => i_screen_name,
                                            o_shortcut      => o_shortcut,
                                            o_doc_area      => o_doc_area,
                                            o_short_btn_lbl => o_short_btn_lbl,
                                            o_error         => o_error);
    END get_shortcut;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SHORTCUT';
    BEGIN
        g_error := 'CALL TO PK_WIZARDS_CORE.GET_SHORTCUT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_wizards_core.check_profcat_data(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode      => i_episode,
                                                  i_screen_name  => i_screen_name,
                                                  o_flg_has_data => o_flg_has_data,
                                                  o_error        => o_error);
    END check_profcat_data;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_wizards_ux;
/
