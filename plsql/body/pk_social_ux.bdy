/*-- Last Change Revision: $Rev: 2027726 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_social_ux IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_sw_generic_exception EXCEPTION;

    /********************************************************************************************
    * Get patient's home characteristics 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET HOME INFORMATION';
        IF NOT pk_social.get_home_2(i_lang          => i_lang,
                                    i_id_pat        => i_id_pat,
                                    i_prof          => i_prof,
                                    o_pat_home      => o_pat_home,
                                    o_pat_home_prof => o_pat_home_prof,
                                    o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOME',
                                                     o_error);
        
    END get_home;
    --

    /********************************************************************************************
    * Get patient's home characteristics history
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET HOME LOCATION HISTORY LIST';
        IF NOT pk_social.get_home_new(i_lang          => i_lang,
                                      i_id_pat        => i_id_pat,
                                      i_prof          => i_prof,
                                      i_history       => pk_alert_constant.get_yes,
                                      i_show_inactive => pk_alert_constant.get_yes,
                                      o_pat_home      => o_pat_home,
                                      o_pat_home_prof => o_pat_home_prof,
                                      o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOME_HIST',
                                                     o_error);
        
    END get_home_hist;
    --

    /********************************************************************************************
    * Get patient's home characteristics to edit 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home_edit
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_home OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET HOME LOCATION HISTORY LIST';
        IF NOT pk_social.get_home_edit(i_lang     => i_lang,
                                       i_id_pat   => i_id_pat,
                                       i_prof     => i_prof,
                                       o_pat_home => o_pat_home,
                                       o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOME_EDIT',
                                                     o_error);
        
    END get_home_edit;
    --
    /********************************************************************************************
    * Get patient's home characteristics to edit 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_home               Family grid
    * @param o_id_home                id_home out
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          paulo teixeira
    * @version                         0.1
    * @since                           2011/08/25
    **********************************************************************************************/
    FUNCTION get_home_edit_new
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_home OUT pk_types.cursor_type,
        o_id_home  OUT home.id_home%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'call get_home_edit_new';
        IF NOT pk_social.get_home_edit_new(i_lang     => i_lang,
                                           i_id_pat   => i_id_pat,
                                           i_prof     => i_prof,
                                           o_pat_home => o_pat_home,
                                           o_id_home  => o_id_home,
                                           o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOME_EDIT_NEW',
                                                     o_error);
        
    END get_home_edit_new;
    /********************************************************************************************
    * Get patient's Social status. This includes information of:
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --house hold
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_social.get_social_status(i_lang,
                                           i_prof,
                                           NULL,
                                           i_id_pat,
                                           o_pat_home,
                                           o_pat_home_prof,
                                           o_pat_social_class,
                                           o_pat_social_class_prof,
                                           o_pat_financial,
                                           o_pat_financial_prof,
                                           o_pat_household,
                                           o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_STATUS',
                                                     o_error);
        
    END get_social_status;
    --

    /********************************************************************************************
    * Get patient's Social status. This includes information of:
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_id_pat                 Patient ID 
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --house hold
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_social.get_social_status(i_lang,
                                           i_prof,
                                           i_episode,
                                           i_id_pat,
                                           o_pat_home,
                                           o_pat_home_prof,
                                           o_pat_social_class,
                                           o_pat_social_class_prof,
                                           o_pat_financial,
                                           o_pat_financial_prof,
                                           o_pat_household,
                                           o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_STATUS',
                                                     o_error);
        
    END get_social_status;
    --

    /********************************************************************************************
    * Get the social status menu 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_status_menu     Menu options for the social status screen 
    * @param o_social_status_actions  Actions options for the social status screen 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_menus
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_social_status_menu    OUT pk_types.cursor_type,
        o_social_status_actions OUT pk_types.cursor_type,
        o_social_status_labels  OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SOCIAL STATUS MENU';
        IF NOT pk_social.get_social_status_menu(i_lang, i_prof, o_social_status_menu, o_social_status_actions, o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT pk_social.get_social_status_labels(i_lang, i_prof, o_social_status_labels, o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_status_menu);
            pk_types.open_my_cursor(o_social_status_actions);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_STATUS_MENUS',
                                                     o_error);
        
    END get_social_status_menus;
    --

    /********************************************************************************************
    * Get domains values for the home fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_home_location_domain  Home location domain
    * @ param o_home_type_domain      Home type domain
    * @ param o_home_owner_domain     Owner domain
    * @ param o_home_conserv_domain   Home maintenance status domain
    * @ param o_home_water_domain     Water domain
    * @ param o_home_wc_domain        WC domain
    * @ param o_home_light_domain     Light domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_home_domains
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_home_location_domain OUT pk_types.cursor_type,
        o_home_type_domain     OUT pk_types.cursor_type,
        o_home_owner_domain    OUT pk_types.cursor_type,
        o_home_conserv_domain  OUT pk_types.cursor_type,
        o_home_water_domain    OUT pk_types.cursor_type,
        o_home_wc_domain       OUT pk_types.cursor_type,
        o_home_light_domain    OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET HOME LOCATION LIST';
        IF NOT pk_social.get_social_status_home_domains(i_lang,
                                                        i_prof,
                                                        o_home_location_domain,
                                                        o_home_type_domain,
                                                        o_home_owner_domain,
                                                        o_home_conserv_domain,
                                                        o_home_water_domain,
                                                        o_home_wc_domain,
                                                        o_home_light_domain,
                                                        o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_home_location_domain);
            pk_types.open_my_cursor(o_home_type_domain);
            pk_types.open_my_cursor(o_home_owner_domain);
            pk_types.open_my_cursor(o_home_conserv_domain);
            pk_types.open_my_cursor(o_home_water_domain);
            pk_types.open_my_cursor(o_home_wc_domain);
            pk_types.open_my_cursor(o_home_light_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_STATUS_LABELS',
                                                     o_error);
        
    END get_social_status_home_domains;
    --

    /********************************************************************************************
     * Save family home conditions.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_flg_hab_location        Home location
     * @param i_flg_hab_type            Home type
     * @param i_flg_owner               Home owner
     * @param i_flg_conserv             Home state
     * @param i_flg_light               Home light 
     * @param i_flg_water_origin        Water origin
     * @param i_flg_water_distrib       Water distribution
     * @param i_flg_wc_location         WC location
     * @param i_num_rooms               Number of rooms
     * @param i_arquitect_barrier       Barriers
     * @param i_notes                   Notes
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/21
    **********************************************************************************************/

    FUNCTION set_home
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_id_home           IN home.id_home%TYPE,
        i_prof              IN profissional,
        i_flg_hab_location  IN home.flg_hab_location%TYPE,
        i_flg_hab_type      IN home.flg_hab_type%TYPE,
        i_flg_owner         IN home.flg_owner%TYPE,
        i_flg_conserv       IN home.flg_conserv%TYPE,
        i_flg_light         IN home.flg_light%TYPE,
        i_flg_water_origin  IN home.flg_water_origin%TYPE,
        i_flg_water_distrib IN home.flg_water_distrib%TYPE,
        i_flg_wc_location   IN home.flg_wc_location%TYPE,
        i_num_rooms         IN home.num_rooms%TYPE,
        i_arquitect_barrier IN home.arquitect_barrier%TYPE,
        i_notes             IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET HOME';
        IF NOT pk_social.set_home(i_lang,
                                  i_id_pat,
                                  i_id_home,
                                  i_prof,
                                  i_flg_hab_location,
                                  i_flg_hab_type,
                                  i_flg_owner,
                                  i_flg_conserv,
                                  i_flg_light,
                                  i_flg_water_origin,
                                  i_flg_water_distrib,
                                  i_flg_wc_location,
                                  i_num_rooms,
                                  i_arquitect_barrier,
                                  i_notes,
                                  o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_HOME',
                                                     o_error);
        
    END set_home;
    /********************************************************************************************
     * Save family home conditions.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_flg_hab_location        Home location
     * @param i_flg_hab_type            Home type
     * @param i_flg_owner               Home owner
     * @param i_flg_conserv             Home state
     * @param i_flg_light               Home light 
     * @param i_flg_water_origin        Water origin
     * @param i_flg_water_distrib       Water distribution
     * @param i_flg_wc_location         WC location
     * @param i_num_rooms               Number of rooms
     * @param i_arquitect_barrier       Barriers
     * @param i_notes                   Notes
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/21
    **********************************************************************************************/
    FUNCTION set_home_new
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_home       IN home.id_home%TYPE,
        i_id_home_field IN table_number,
        i_table_flg     IN table_varchar,
        i_table_desc    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET HOME_NEW';
        IF NOT pk_social.set_home_new(i_lang          => i_lang,
                                      i_id_pat        => i_id_pat,
                                      i_id_home       => i_id_home,
                                      i_prof          => i_prof,
                                      i_id_home_field => i_id_home_field,
                                      i_table_flg     => i_table_flg,
                                      i_table_desc    => i_table_desc,
                                      o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_HOME_NEW',
                                                     o_error);
        
    END set_home_new;
    --

    /********************************************************************************************
     * Cancel home.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     * @param i_notes                   Cancel notes
     * @param i_cancel_reason           Cancel reason ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/21
    **********************************************************************************************/
    FUNCTION set_cancel_home
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_home_hist  IN home_hist.id_home_hist%TYPE,
        i_notes         IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CANCEL HOME - Flash Layer';
        IF NOT pk_social.set_cancel_home(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_pat        => i_id_pat,
                                         i_id_home_hist  => i_id_home_hist,
                                         i_notes         => i_notes,
                                         i_cancel_reason => i_cancel_reason,
                                         o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_HOME',
                                                     o_error);
        
    END set_cancel_home;
    --

    /**
    * Get social worker's appointments.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_dt             date
    * @param i_prof_cat       logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error          error
    *
    * @returns                false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/01/29
    */
    FUNCTION get_appointments
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt          IN VARCHAR2,
        i_type        IN VARCHAR2,
        i_prof_cat    IN category.flg_type%TYPE,
        o_doc         OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_body_title  OUT VARCHAR2,
        o_body_detail OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_grid_amb.social_efectiv(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_dt            => i_dt,
                                          i_type          => i_type,
                                          i_prof_cat_type => i_prof_cat,
                                          o_doc           => o_doc,
                                          o_flg_show      => o_flg_show,
                                          o_msg_title     => o_msg_title,
                                          o_body_title    => o_body_title,
                                          o_body_detail   => o_body_detail,
                                          o_error         => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_APPOINTMENTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END get_appointments;

    /********************************************************************************************
     * Get the household information for the create/edit screen. If no information exists 
     * for the given patient the cursor returns only the screen's labels, otherwise it 
     * returns the information previously created.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode ID
     * @param i_pat_origin             "Original" patient ID - real patient  (not the one that was selected)
     * @param i_id_pat                 Selected patient ID 
     * @param o_pat_household          Household information
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_household_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_id_pat_household IN patient.id_patient%TYPE,
        o_pat_household    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_HOUSEHOLD_EDIT';
        IF NOT pk_social.get_household_edit(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_episode          => i_episode,
                                            i_id_pat           => i_id_pat,
                                            i_id_pat_household => i_id_pat_household,
                                            o_pat_household    => o_pat_household,
                                            o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOUSEHOLD_EDIT',
                                                     o_error);
        
    END get_household_edit;
    --

    /********************************************************************************************
     * Get the household information for the create/edit screen. If no information exists 
     * for the given patient the cursor returns only the screen's labels, otherwise it 
     * returns the information previously created.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_pat_origin             "Original" patient ID - real patient  (not the one that was selected)
     * @param i_id_pat                 Selected patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_household          Household information
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_household_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat           IN patient.id_patient%TYPE,
        i_id_pat_household IN patient.id_patient%TYPE,
        o_pat_household    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_HOUSEHOLD_EDIT';
        IF NOT pk_social_ux.get_household_edit(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_episode          => NULL,
                                               i_id_pat           => i_id_pat,
                                               i_id_pat_household => i_id_pat_household,
                                               o_pat_household    => o_pat_household,
                                               o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOUSEHOLD_EDIT',
                                                     o_error);
        
    END get_household_edit;
    --

    /********************************************************************************************
    * Get domains values for the social class fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_ocupation_domain      Occupation domain list
    * @ param o_education_level_domain Education domain list
    * @ param o_income_domain          Income domain list
    * @ param o_house_domain           House domain list
    * @ param o_house_location_domain  House location list
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_domains
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        o_ocupation_domain       OUT pk_types.cursor_type,
        o_education_level_domain OUT pk_types.cursor_type,
        o_income_domain          OUT pk_types.cursor_type,
        o_house_domain           OUT pk_types.cursor_type,
        o_house_location_domain  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_SOCIAL_CLASS_DOMAINS';
        IF NOT pk_social.get_social_class_domains(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  o_ocupation_domain       => o_ocupation_domain,
                                                  o_education_level_domain => o_education_level_domain,
                                                  o_income_domain          => o_income_domain,
                                                  o_house_domain           => o_house_domain,
                                                  o_house_location_domain  => o_house_location_domain,
                                                  o_error                  => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_CLASS_DOMAINS',
                                                     o_error);
        
    END get_social_class_domains;
    --

    /********************************************************************************************
     * Get the social class information for the create/edit screen. If no information exists 
     * for the given patient the cursor returns only the screen's labels, otherwise it 
     * returns the information previously created.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Selected patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_social_class           Social class information
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat       IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        o_social_class OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET HOME';
        IF NOT pk_social.get_social_class_edit(i_lang         => i_lang,
                                               i_id_pat       => i_id_pat,
                                               i_prof         => i_prof,
                                               o_social_class => o_social_class,
                                               o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_CLASS_EDIT',
                                                     o_error);
        
    END get_social_class_edit;
    --

    /********************************************************************************************
    * Create patient's social class
    * 
    * @ param i_lang 
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    * @param i_id_pat                 Patient ID 
    * @ param i_epis                  Episode ID
    * @ param i_occupation_val        Occupation
    * @ param i_education_level_val   Education level
    * @ param i_income_val            Patient's income
    * @ param i_house_val             Patient's house
    * @ param i_house_location_val    Patient's house location
    * @param i_notes                  Social class notes
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION set_pat_social_class
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        --i_id_pat_graf_crit IN pat_graffar_crit.id_pat_graffar_crit%TYPE,
        i_occupation_val      IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_education_level_val IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_income_val          IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_house_val           IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_house_location_val  IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET_PAT_SOCIAL_CLASS';
        IF NOT pk_social.set_pat_social_class(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_pat              => i_id_pat,
                                              i_epis                => i_epis,
                                              i_occupation_val      => i_occupation_val,
                                              i_education_level_val => i_education_level_val,
                                              i_income_val          => i_income_val,
                                              i_house_val           => i_house_val,
                                              i_house_location_val  => i_house_location_val,
                                              i_notes               => i_notes,
                                              o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_PAT_SOCIAL_CLASS',
                                                     o_error);
        
    END set_pat_social_class;
    --

    /********************************************************************************************
    * Get patient's household financial information for the create/edit screen
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_id_pat                 Patient ID 
    * @param o_pat_financial          Financial information cursor
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_household_financial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        o_pat_financial OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_HOUSEHOLD_FINANCIAL_EDIT';
        IF NOT pk_social.get_household_financial_edit(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_pat        => i_id_pat,
                                                      o_pat_financial => o_pat_financial,
                                                      o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_financial);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOUSEHOLD_FINANCIAL_EDIT',
                                                     o_error);
        
    END get_household_financial_edit;
    --

    /********************************************************************************************
    * This function allows the creation (i_id_fam_money is null) or the update of household 
    * financial information.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    * @ param i_id_fam_money          Id family money
    * @ param i_allowance_family      Allowance family value
    * @ param i_currency_allow_family Allowance family currency id
    * @ param i_allowance_complementary Allowance complementary value
    * @ param i_currency_allow_comp     Allowance complementary currency id
    * @ param i_other                   Other incomes value
    * @ param i_currency_other          Other incomes currency id
    * @ param i_subsidy                 Allowance value
    * @ param i_currency_subsidy        Allowance currency id
    * @ param i_fixed_expenses          Fixed expenses value
    * @ param i_currency_fixed_exp      Fixed expenses currency id
    * @ param i_total_fam_members       Number of family members
    * @ param i_notes                   Notes
    * @ param i_epis                    ID episode
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/05
    **********************************************************************************************/

    FUNCTION set_household_financial
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat                  IN patient.id_patient%TYPE,
        i_id_fam_money            IN family_monetary.id_family_monetary%TYPE,
        i_allowance_family        IN family_monetary.allowance_family%TYPE,
        i_currency_allow_family   IN currency.id_currency%TYPE,
        i_allowance_complementary IN family_monetary.allowance_complementary%TYPE,
        i_currency_allow_comp     IN currency.id_currency%TYPE,
        i_other                   IN family_monetary.other%TYPE,
        i_currency_other          IN currency.id_currency%TYPE,
        i_subsidy                 IN family_monetary.subsidy%TYPE,
        i_currency_subsidy        IN currency.id_currency%TYPE,
        i_fixed_expenses          IN family_monetary.fixed_expenses%TYPE,
        i_currency_fixed_exp      IN currency.id_currency%TYPE,
        i_total_fam_members       IN patient.total_fam_members%TYPE,
        i_notes                   IN VARCHAR2,
        i_epis                    IN episode.id_episode%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_social.set_household_financial(i_lang,
                                                 i_prof,
                                                 i_id_pat,
                                                 i_id_fam_money,
                                                 i_allowance_family,
                                                 i_currency_allow_family,
                                                 i_allowance_complementary,
                                                 i_currency_allow_comp,
                                                 i_other,
                                                 i_currency_other,
                                                 i_subsidy,
                                                 i_currency_subsidy,
                                                 i_fixed_expenses,
                                                 i_currency_fixed_exp,
                                                 i_total_fam_members,
                                                 i_notes,
                                                 i_epis,
                                                 o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        
    END set_household_financial;
    --

    /********************************************************************************************
    * Get domains values for the household financial fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_currency_domain       Currency domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/05
    **********************************************************************************************/
    FUNCTION get_household_fin_domains
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_currency_domain OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_social.get_household_fin_domains(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   o_currency_domain => o_currency_domain,
                                                   o_error           => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        
    END get_household_fin_domains;
    --

    /********************************************************************************************
     * Cancel the household financial information.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_fam_money            Financial info ID
     * @param i_notes                   Cancel notes
     * @param i_cancel_reason           Cancel reason ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/21
    **********************************************************************************************/
    FUNCTION set_cancel_household_financial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_fam_money  IN family_monetary.id_family_monetary%TYPE,
        i_notes         IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_CANCEL_HOUSEHOLD_FINANCIAl - Flash Layer';
        IF NOT pk_social.set_cancel_household_financial(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_pat        => i_id_pat,
                                                        i_id_fam_money  => i_id_fam_money,
                                                        i_notes         => i_notes,
                                                        i_cancel_reason => i_cancel_reason,
                                                        o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        
    END set_cancel_household_financial;
    --

    /********************************************************************************************
     * Cancel a member of the household.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_pat_fam_member       Family member ID
     * @param i_notes                   Cancel notes
     * @param i_cancel_reason           Cancel reason ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/02/11
    **********************************************************************************************/
    FUNCTION set_cancel_household
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_pat            IN patient.id_patient%TYPE,
        i_id_pat_fam_member IN family_monetary.id_family_monetary%TYPE,
        i_notes             IN VARCHAR2,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_CANCEL_HOUSEHOLD - Flash Layer';
        IF NOT pk_social.set_cancel_household(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_pat            => i_id_pat,
                                              i_id_pat_fam_member => i_id_pat_fam_member,
                                              i_notes             => i_notes,
                                              i_cancel_reason     => i_cancel_reason,
                                              o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_HOUSEHOLD',
                                                     o_error);
        
    END set_cancel_household;

    /********************************************************************************************
     * Cancel the Social class for the givem patient
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_notes                   Cancel notes
     * @param i_cancel_reason           Cancel reason ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/02/11
    **********************************************************************************************/
    FUNCTION set_cancel_social_class
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_notes         IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_CANCEL_SOCIAL_CLASS - Flash Layer';
        IF NOT pk_social.set_cancel_social_class(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_id_pat        => i_id_pat,
                                                 i_notes         => i_notes,
                                                 i_cancel_reason => i_cancel_reason,
                                                 o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_SOCIAL_CLASS',
                                                     o_error);
        
    END set_cancel_social_class;
    --

    /********************************************************************************************
    * Get patient's household financial information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_financial          Financial information cursor
    * @param o_pat_financial_prof     Professional that inputs the financial information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_financial_hist
    
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_FINANCIAL_HIST - Flash Layer';
    
        IF NOT pk_social.get_household_financial_hist(i_lang               => i_lang,
                                                      i_id_pat             => i_id_pat,
                                                      i_prof               => i_prof,
                                                      o_pat_financial      => o_pat_financial,
                                                      o_pat_financial_prof => o_pat_financial_prof,
                                                      o_error              => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_FINANCIAL_HIST',
                                                     o_error);
        
    END get_financial_hist;
    --

    /********************************************************************************************
    * Get patient's family social class history information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_social_class       Social Class information cursor
    * @param o_pat_social_class_prof  Professional that inputs the social class information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/12
    **********************************************************************************************/
    FUNCTION get_social_class_hist
    
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_pat                IN patient.id_patient%TYPE,
        i_prof                  IN profissional,
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_FINANCIAL_HIST - Flash Layer';
    
        IF NOT pk_social.get_social_class_hist(i_lang                  => i_lang,
                                               i_id_pat                => i_id_pat,
                                               i_prof                  => i_prof,
                                               o_pat_social_class      => o_pat_social_class,
                                               o_pat_social_class_prof => o_pat_social_class_prof,
                                               o_error                 => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_CLASS_HIST',
                                                     o_error);
        
    END get_social_class_hist;
    --

    /*
    * Get an episode's follow up notes list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_followup_notes';
        IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_mng_followup   => i_mng_followup,
                                                           i_show_cancelled => pk_alert_constant.g_yes,
                                                           o_follow_up_prof => o_follow_up_prof,
                                                           o_follow_up      => o_follow_up,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
    END get_followup_notes;

    /*
    * Get follow up notes data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up      follow up notes
    * @param o_time_units     time units
    * @param o_domain         option of end of follow up
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up    OUT pk_types.cursor_type,
        o_time_units   OUT pk_types.cursor_type,
        o_domain       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_edit_followup_notes';
        IF NOT pk_paramedical_prof_core.get_followup_notes_edit(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_episode      => i_episode,
                                                                i_mng_followup => i_mng_followup,
                                                                o_follow_up    => o_follow_up,
                                                                o_time_units   => o_time_units,
                                                                o_domain       => o_domain,
                                                                o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_time_units);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOWUP_NOTES_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_time_units);
            RETURN FALSE;
    END get_followup_notes_edit;

    /*
    * Set follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_notes          follow up notes
    * @param i_start_dt       start date
    * @param i_time_spent     time spent
    * @param i_unit_time      time spent unit measure
    * @param i_next_dt        next date
    * @param i_flg_end_followup flagend of followup  Y/N  
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_mng_followup          IN management_follow_up.id_management_follow_up%TYPE,
        i_episode               IN management_follow_up.id_episode%TYPE,
        i_notes                 IN management_follow_up.notes%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.set_followup_notes';
        IF NOT pk_paramedical_prof_core.set_followup_notes(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_mng_followup          => i_mng_followup,
                                                           i_episode               => i_episode,
                                                           i_notes                 => i_notes,
                                                           i_start_dt              => i_start_dt,
                                                           i_time_spent            => i_time_spent,
                                                           i_unit_time             => i_unit_time,
                                                           i_next_dt               => i_next_dt,
                                                           i_flg_end_followup      => i_flg_end_followup,
                                                           i_dt_next_enc_precision => i_dt_next_enc_precision,
                                                           o_mng_followup          => o_mng_followup,
                                                           o_error                 => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EDIT_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_followup_notes;

    /*
    * Cancel follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancellation reason
    * @param i_notes          cancellation notes
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/18
    */
    FUNCTION set_cancel_followup_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_mng_followup  IN management_follow_up.id_management_follow_up%TYPE,
        i_episode       IN management_follow_up.id_episode%TYPE,
        i_cancel_reason IN management_follow_up.id_cancel_reason%TYPE,
        i_notes         IN management_follow_up.notes_cancel%TYPE,
        o_mng_followup  OUT management_follow_up.id_management_follow_up%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_case_management.cancel_mng_followup';
        IF NOT pk_case_management.cancel_mng_followup(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_mng_plan_followup => i_mng_followup,
                                                      i_episode           => i_episode,
                                                      i_epis_encounter    => NULL,
                                                      i_cancel_reason     => i_cancel_reason,
                                                      i_notes             => i_notes,
                                                      o_mng_plan_followup => o_mng_followup,
                                                      o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_CANCEL_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cancel_followup_notes;
    --

    /********************************************************************************************
    * Get patient's Social Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *    - Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @ param o_social_report         Social report
    * @ param o_social_report_prof    Professional that creates/edit the social report
    * @ param o_social_request        Social request
    * @ param o_social_request_prof   Professional that creates/edit the social request
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --diagnosis
        o_diagnosis      OUT pk_types.cursor_type,
        o_diagnosis_prof OUT pk_types.cursor_type,
        --intervention_plan
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        --followup notes
        o_follow_up      OUT pk_types.cursor_type,
        o_follow_up_prof OUT pk_types.cursor_type,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --household
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        --report
        o_social_report      OUT pk_types.cursor_type,
        o_social_report_prof OUT pk_types.cursor_type,
        --request
        o_social_request      OUT pk_types.cursor_type,
        o_social_request_prof OUT pk_types.cursor_type,
        --
        o_request_origin OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        IF NOT pk_social.get_social_summary(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_id_pat  => i_id_pat,
                                            i_episode => i_episode,
                                            --
                                            o_diagnosis      => o_diagnosis,
                                            o_diagnosis_prof => o_diagnosis_prof,
                                            
                                            o_interv_plan      => o_interv_plan,
                                            o_interv_plan_prof => o_interv_plan_prof,
                                            
                                            o_follow_up      => o_follow_up,
                                            o_follow_up_prof => o_follow_up_prof,
                                            --
                                            o_pat_home              => o_pat_home,
                                            o_pat_home_prof         => o_pat_home_prof,
                                            o_pat_social_class      => o_pat_social_class,
                                            o_pat_social_class_prof => o_pat_social_class_prof,
                                            o_pat_financial         => o_pat_financial,
                                            o_pat_financial_prof    => o_pat_financial_prof,
                                            o_pat_household         => o_pat_household,
                                            o_pat_household_prof    => o_pat_household_prof,
                                            o_social_report         => o_social_report,
                                            o_social_report_prof    => o_social_report_prof,
                                            o_social_request        => o_social_request,
                                            o_social_request_prof   => o_social_request_prof,
                                            o_error                 => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := ('GET_SOCIAL_EPISODE_TYPE');
        IF pk_social.get_social_epis_type(i_lang, i_prof, i_episode) = 'R'
        THEN
            o_request_origin := pk_alert_constant.g_yes;
        ELSE
            o_request_origin := pk_alert_constant.g_no;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_diagnosis_prof);
            --
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            --
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_follow_up_prof);
            --
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            --
            pk_types.open_my_cursor(o_social_report);
            pk_types.open_my_cursor(o_social_report_prof);
        
            pk_types.open_my_cursor(o_social_request);
            pk_types.open_my_cursor(o_social_request_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SOCIAL_SUMMARY',
                                                     o_error);
        
    END get_social_summary;
    --

    /********************************************************************************************
    * Get all parametrizations for the social worker software
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations (name/value)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_social_parametrizations
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        o_social_parametrizations OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_social_parametrizations';
    
        IF NOT pk_paramedical_prof_core.get_paramedical_param(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              o_paramedical_param => o_social_parametrizations,
                                                              o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_parametrizations);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_SOCIAL_PARAMETRIZATIONS',
                                                     o_error    => o_error);
    END get_social_parametrizations;
    --

    /********************************************************************************************
    * Get all parametrizations for the social worker software
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations (name/value)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_parametrizations
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_parametrizations OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_configs CONSTANT table_varchar := table_varchar('SUMMARY_VIEW_ALL',
                                                          'GRID_NAVIGATION',
                                                          'PARAMEDICAL_REQUESTS_SHOW_PATIENT_AREA',
                                                          'FREE_TEXT_ID');
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_parametrizations';
    
        IF NOT pk_paramedical_prof_core.get_parametrizations(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_configs           => l_configs,
                                                             o_paramedical_param => o_parametrizations,
                                                             o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_parametrizations);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_PARAMETRIZATIONS',
                                                     o_error    => o_error);
    END get_parametrizations;

    /********************************************************************************************
    * Get the social summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_social_summary_labels
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_social_summary_labels OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_social_summary_labels';
        IF NOT pk_social.get_social_summary_labels(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   o_social_summary_labels => o_social_summary_labels,
                                                   o_error                 => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_summary_labels);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => o_error.ora_sqlcode,
                                                     i_sqlerrm  => o_error.ora_sqlerrm,
                                                     i_message  => o_error.err_desc,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_SOCIAL_SUMMARY_LABELS',
                                                     o_error    => o_error);
    END get_social_summary_labels;

    /*
    * Check if new social assistance request can be created.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param o_create         create flag
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION check_create_request
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.check_create_request';
        IF NOT pk_social.check_create_request(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => i_patient,
                                              o_create  => o_create,
                                              o_error   => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_CREATE_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_create_request;

    /*
    * Get social services requests list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/23
    */
    FUNCTION get_social_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN episode.id_patient%TYPE,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_social_requests';
        IF NOT pk_social.get_social_requests(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_prof_cat => i_prof_cat,
                                             i_episode  => i_episode,
                                             i_patient  => i_patient,
                                             o_requests => o_requests,
                                             o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SOCIAL_REQUESTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_social_requests;

    /*
    * Get a social assitance request detail.
    * Used in the clinical profiles.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_request        request identifier
    * @param o_req_data       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_request_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_request  IN social_epis_request.id_social_epis_request%TYPE,
        o_req_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_request_detail';
        IF NOT pk_social.get_request_detail(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_request  => i_request,
                                            o_req_data => o_req_data,
                                            o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REQUEST_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_req_data);
            RETURN FALSE;
    END get_request_detail;

    /*
    * Get the request that originated the given episode.
    * Used in the Social worker's profiles.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_request        request cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/23
    */
    FUNCTION get_request
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_request OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_request';
        IF NOT pk_social.get_request(i_lang    => i_lang,
                                     i_episode => i_episode,
                                     i_prof    => i_prof,
                                     o_request => o_request,
                                     o_error   => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_request);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_request);
            RETURN FALSE;
    END get_request;

    /*
    * Create a social assistance request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_notes          request notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/23
    */
    FUNCTION create_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_notes           IN social_epis_request.notes%TYPE,
        o_id_soc_epis_req OUT social_epis_request.id_social_epis_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.create_request';
        IF NOT pk_social.create_request(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_episode         => i_episode,
                                        i_patient         => i_patient,
                                        i_notes           => i_notes,
                                        o_id_soc_epis_req => o_id_soc_epis_req,
                                        o_error           => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CREATE_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_request;

    /*
    * Create a social assistance request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_request        request identifier
    * @param i_cancel_reason  cancellation reason identifier
    * @param i_notes          cancellation notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION cancel_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_request       IN social_epis_request.id_social_epis_request%TYPE,
        i_cancel_reason IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_long%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.cancel_request';
        IF NOT pk_social.cancel_request(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_request       => i_request,
                                        i_cancel_reason => i_cancel_reason,
                                        i_notes         => i_notes,
                                        o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_request;

    /*
    * Answer a social assistance request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_request        request identifier
    * @param i_answer         answer flag
    * @param i_notes          answer notes
    * @param o_episode        episode identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION set_request_answer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_request IN social_epis_request.id_social_epis_request%TYPE,
        i_answer  IN social_epis_request.flg_status%TYPE,
        i_notes   IN social_epis_request.notes_answer%TYPE,
        o_episode OUT episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.set_request_answer';
        IF NOT pk_social.set_request_answer(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_request => i_request,
                                            i_answer  => i_answer,
                                            i_notes   => i_notes,
                                            o_episode => o_episode,
                                            o_error   => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REQUEST_ANSWER',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_request_answer;

    /*
    * Get the list of possible request answers.
    *
    * @param i_lang           language identifier
    * @param o_options        list of options
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_req_ans_options
    (
        i_lang    IN language.id_language%TYPE,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_req_ans_options';
        IF NOT pk_social.get_req_ans_options(i_lang => i_lang, o_options => o_options, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REQ_ANS_OPTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_req_ans_options;

    /*
    * Get a social worker's answered requests.
    * Used to show the data on the requests grid.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_self_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_grid_requests';
        IF NOT pk_social.get_grid_requests(i_lang     => i_lang,
                                           i_prof     => i_prof,
                                           i_show_all => pk_alert_constant.g_no,
                                           o_requests => o_requests,
                                           o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SELF_REQUESTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_self_requests;

    /*
    * Get all social assistance requests.
    * Used to show the data on the requests grid.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_all_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_grid_requests';
        IF NOT pk_social.get_grid_requests(i_lang     => i_lang,
                                           i_prof     => i_prof,
                                           i_show_all => pk_alert_constant.g_yes,
                                           o_requests => o_requests,
                                           o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ALL_REQUESTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_all_requests;

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'searchable'.
    * This function is prepared to return categories or plans hierarchy, where either 
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans             
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_LIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_list(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_plan_cat  => i_interv_plan_cat,
                                                             i_interv_plan      => i_interv_plan,
                                                             i_inter_type       => 1,
                                                             o_interv_plan_info => o_interv_plan_info,
                                                             o_header_label     => o_header_label,
                                                             o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_info);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_LIST',
                                                     o_error);
    END get_interv_plan_list;
    --

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'more frequents'.
    * This function is prepared to return categories or plans hierarchy, where either 
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no 
    *                                 category is selected. 
    * @ param i_interv_plan           ID intervention plan. Can be null, if no 
    *                                 intervention plan is selected. 
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans             
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_freq_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_FREQ_LIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_freq_list(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_interv_plan_cat  => i_interv_plan_cat,
                                                                  i_interv_plan      => i_interv_plan,
                                                                  i_inter_type       => 1,
                                                                  o_interv_plan_info => o_interv_plan_info,
                                                                  o_header_label     => o_header_label,
                                                                  o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_info);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_FREQ_LIST',
                                                     o_error);
    END get_interv_plan_freq_list;
    --

    /********************************************************************************************
    * Get the list of intervention plans for a given episode
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN';
        IF NOT pk_paramedical_prof_core.get_interv_plan(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_epis       => i_id_epis,
                                                        o_interv_plan   => o_interv_plan,
                                                        o_screen_labels => o_screen_labels,
                                                        o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN',
                                                     o_error);
    END get_interv_plan;
    --

    /********************************************************************************************
    * Set one or more intervention plans for a given episode. This function can be used either to 
    * create new intervention plans or to edit existing ones. When editing intervention plans
    * the parameter i_id_epis_interv_plan must be not null.
    *
    * @param i_lang                   Preferred language ID for this professional     
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   List of IDs for the existing intervention plans to edit
    * @ param i_id_interv_plan        List of IDs for the intervention plans
    * @ param i_desc_other_interv_plan List of description of free text intervention plans
    * @ param i_dt_begin               List of begin dates for the intervention plans
    * @ param i_dt_end                 List of end dates for the intervention plans
    * @ param i_interv_plan_state      List of current states for the intervention plans
    * @ param i_notes                  List of notes for the intervention plans
    * @ param i_tb_tb_diag             table with id_diagnosis to associate
    * @ param i_tb_tb_desc_diag        table with diagnosis desctiptions to associate
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_interv_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        i_id_epis_interv_plan IN table_number,
        i_id_interv_plan      IN table_number,
        --
        i_desc_other_interv_plan IN table_varchar,
        i_dt_begin               IN table_varchar,
        i_dt_end                 IN table_varchar,
        i_interv_plan_state      IN table_varchar,
        i_notes                  IN table_varchar,
        i_tb_tb_diag             IN table_table_number,
        i_tb_tb_alert_diag       IN table_table_number,
        i_tb_tb_desc_diag        IN table_table_varchar,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_INTERV_PLAN';
        IF NOT pk_paramedical_prof_core.set_interv_plan(i_lang                   => i_lang,
                                                        i_prof                   => i_prof,
                                                        i_id_epis                => i_id_epis,
                                                        i_id_epis_interv_plan    => i_id_epis_interv_plan,
                                                        i_id_interv_plan         => i_id_interv_plan,
                                                        i_desc_other_interv_plan => i_desc_other_interv_plan,
                                                        i_dt_begin               => i_dt_begin,
                                                        i_dt_end                 => i_dt_end,
                                                        i_interv_plan_state      => i_interv_plan_state,
                                                        i_notes                  => i_notes,
                                                        i_tb_tb_diag             => i_tb_tb_diag,
                                                        i_tb_tb_alert_diag       => i_tb_tb_alert_diag,
                                                        i_tb_tb_desc_diag        => i_tb_tb_desc_diag,
                                                        o_error                  => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_INTERV_PLAN',
                                                     o_error);
    END set_interv_plan;
    --

    /********************************************************************************************
    * Get domains values for the intervention plan states. 
    * If the parameter i_current_state is null then all available states will be returned, 
    * otherwise the function returns only the states that are different form the current one.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state
    *
    * @ param o_interv_plan_state     List with available states
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_state_domains
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_state     IN VARCHAR2,
        o_interv_plan_state OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_STATE_DOMAINS';
        IF NOT pk_paramedical_prof_core.get_interv_plan_state_domains(i_lang              => i_lang,
                                                                      i_prof              => i_prof,
                                                                      i_current_state     => i_current_state,
                                                                      o_interv_plan_state => o_interv_plan_state,
                                                                      o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_STATE_DOMAINS',
                                                     o_error);
    END get_interv_plan_state_domains;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_id_epis_interv_plan   List of intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_EDIT_POPUP';
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit_popup(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_epis             => i_id_epis,
                                                                   i_id_epis_interv_plan => i_id_epis_interv_plan,
                                                                   o_interv_plan         => o_interv_plan,
                                                                   o_screen_labels       => o_screen_labels,
                                                                   o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_epis  IN episode.id_episode%TYPE,
        i_dt_begin IN table_varchar,
        i_dt_end   IN table_varchar,
        i_state    IN table_varchar,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_EDIT_POPUP';
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit_popup(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_id_epis       => i_id_epis,
                                                                   i_dt_begin      => i_dt_begin,
                                                                   i_dt_end        => i_dt_end,
                                                                   i_state         => i_state,
                                                                   o_interv_plan   => o_interv_plan,
                                                                   o_screen_labels => o_screen_labels,
                                                                   o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a 
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_id_interv_plan        List of IDs of the selected intervention plans
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_id_interv_plan IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_state          IN table_varchar,
        i_notes          IN table_varchar,
        i_epis_diag      IN table_table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_EDIT_POPUP';
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit_popup(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_epis        => i_id_epis,
                                                                   i_id_interv_plan => i_id_interv_plan,
                                                                   i_dt_begin       => i_dt_begin,
                                                                   i_dt_end         => i_dt_end,
                                                                   i_state          => i_state,
                                                                   i_notes          => i_notes,
                                                                   o_interv_plan    => o_interv_plan,
                                                                   o_screen_labels  => o_screen_labels,
                                                                   i_epis_diag      => i_epis_diag,
                                                                   o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get labels and domains for the edit screen
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    
    * @ param o_interv_plan           State domains
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_state_domains OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_EDIT';
        IF NOT pk_paramedical_prof_core.get_interv_plan_edit(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_epis       => i_id_epis,
                                                             o_state_domains => o_state_domains,
                                                             o_screen_labels => o_screen_labels,
                                                             o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT',
                                                     o_error);
    END get_interv_plan_edit;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_hist(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_epis             => i_id_epis,
                                                             i_id_epis_interv_plan => i_id_epis_interv_plan,
                                                             o_interv_plan         => o_interv_plan,
                                                             o_interv_plan_prof    => o_interv_plan_prof,
                                                             o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_HIST',
                                                     o_error);
    END get_interv_plan_hist;
    --

    /********************************************************************************************
    * Set(change) a new intervention plan state 
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   Intervention plan ID
    * @ param i_new_interv_plan_state New state for the existing plan
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_new_interv_plan_state
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_id_epis_interv_plan   IN epis_interv_plan.id_epis_interv_plan%TYPE,
        i_new_interv_plan_state IN epis_interv_plan.flg_status%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET_NEW_INTERV_PLAN_STATE';
        IF NOT pk_paramedical_prof_core.set_new_interv_plan_state(i_lang                  => i_lang,
                                                                  i_prof                  => i_prof,
                                                                  i_id_epis               => i_id_epis,
                                                                  i_id_epis_interv_plan   => table_number(i_id_epis_interv_plan),
                                                                  i_new_interv_plan_state => i_new_interv_plan_state,
                                                                  o_error                 => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_NEW_INTERV_PLAN_STATE',
                                                     o_error);
    END set_new_interv_plan_state;
    --

    /********************************************************************************************
    * Cancel Intervention plans.
    *
    * @param i_lang                    Preferred language ID for this professional
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_epis                 Episode ID
    * @ param i_id_epis_interv_plan     Intervention plan ID
    * @ param i_notes                   Cancel notes
    * @ param i_cancel_reason           Cancel reason
    *
    * @ param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                           Orlando Antunes
    * @version                          2.6.0.1
    * @since                            2010/02/25
    **********************************************************************************************/
    FUNCTION set_cancel_interv_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        i_notes               IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'set_cancel_interv_plan';
        IF NOT pk_paramedical_prof_core.set_cancel_interv_plan(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_epis             => i_id_epis,
                                                               i_id_epis_interv_plan => table_number(i_id_epis_interv_plan),
                                                               i_notes               => i_notes,
                                                               i_cancel_reason       => i_cancel_reason,
                                                               o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_INTERV_PLAN',
                                                     o_error);
    END set_cancel_interv_plan;
    --

    /********************************************************************************************
    * Get Intervention plans available actiosn 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state     
    * @param o_interv_plan_actions    List of actions 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_current_state       IN action.from_state%TYPE,
        o_interv_plan_actions OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_ACTIONS';
        IF NOT pk_paramedical_prof_core.get_interv_plan_actions(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_current_state       => table_varchar(i_current_state),
                                                                o_interv_plan_actions => o_interv_plan_actions,
                                                                o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_ACTIONS',
                                                     o_error);
    END get_interv_plan_actions;
    --

    /*
    * Get an episode's paramedical service reports list. Specify the report
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_report         report identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info 
    * @param o_report         reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION get_paramed_report
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN paramed_report.id_episode%TYPE,
        i_report      IN paramed_report.id_paramed_report%TYPE,
        o_report_prof OUT pk_types.cursor_type,
        o_report      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report';
        IF NOT pk_paramedical_prof_core.get_paramed_report(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => table_number(i_episode),
                                                           i_report         => i_report,
                                                           i_show_cancelled => pk_alert_constant.g_yes,
                                                           o_report_prof    => o_report_prof,
                                                           o_report         => o_report,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_prof);
            pk_types.open_my_cursor(o_report);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARAMED_REPORT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_prof);
            pk_types.open_my_cursor(o_report);
            RETURN FALSE;
    END get_paramed_report;
    /*
    * Get an episode's paramedical service reports list. Specify the report
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_report         report identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info 
    * @param o_report         reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION get_paramed_report2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN paramed_report.id_episode%TYPE,
        i_report      IN paramed_report.id_paramed_report%TYPE,
        o_report_prof OUT pk_types.cursor_type,
        o_report      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report_list_report';
        pk_paramedical_prof_core.get_paramed_report_list_report(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_episode        => table_number(i_episode),
                                                                i_show_cancelled => pk_alert_constant.g_yes,
                                                                o_report_prof    => o_report_prof,
                                                                o_report         => o_report);
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_prof);
            pk_types.open_my_cursor(o_report);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARAMED_REPORT2',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_prof);
            pk_types.open_my_cursor(o_report);
            RETURN FALSE;
    END get_paramed_report2;

    /*
    * Set paramedical service report.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_report         report identifier
    * @param i_episode        episode identifier
    * @param i_text           report text
    * @param o_report         created report identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION set_paramed_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_report  IN paramed_report.id_paramed_report%TYPE,
        i_episode IN paramed_report.id_episode%TYPE,
        i_text    IN paramed_report.text%TYPE,
        o_report  OUT paramed_report.id_paramed_report%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.set_paramed_report';
        IF NOT pk_paramedical_prof_core.set_paramed_report(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_report  => i_report,
                                                           i_episode => i_episode,
                                                           i_text    => i_text,
                                                           o_report  => o_report,
                                                           o_error   => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PARAMED_REPORT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_paramed_report;

    /********************************************************************************************
    * Create new household members
    *
    * @param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_pat                 Patient ID
    * @ param i_epis                   Episode ID
    * @ param i_name                   New household member name
    * @ param i_gender                 New household member gender
    * @ param i_dt_birth               New household member birth date
    * @ param i_id_family_relationship Household member family relationship
    * @ param i_marital_status         New household member marital status
    * @ param i_scholarship            New household member scholarship
    * @ param i_pension                New household member pension
    * @ param i_net_wage               New household member wage
    * @ param i_unemployment_subsidy   New household member subsidy
    * @ param i_occupation             New household member occupation 
    * @ param i_free_text_occupation_desc New household member free_text_occupation
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/03/04
    **********************************************************************************************/
    FUNCTION set_household_member
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_pat                    IN patient.id_patient%TYPE,
        i_id_pat_household          IN patient.id_patient%TYPE,
        i_epis                      IN episode.id_episode%TYPE,
        i_name                      IN patient.name%TYPE,
        i_gender                    IN patient.gender%TYPE,
        i_dt_birth                  IN VARCHAR2,
        i_id_family_relationship    IN pat_family_member.id_family_relationship%TYPE,
        i_marital_status            IN pat_soc_attributes.marital_status%TYPE,
        i_scholarship               IN pat_soc_attributes.id_scholarship%TYPE,
        i_pension                   IN pat_soc_attributes.pension%TYPE,
        i_net_wage                  IN pat_soc_attributes.net_wage%TYPE,
        i_unemployment_subsidy      IN pat_soc_attributes.unemployment_subsidy%TYPE,
        i_occupation                IN pat_job.id_occupation%TYPE,
        i_free_text_occupation_desc IN pat_job.occupation_desc%TYPE,
        i_dependecy                 IN patient.flg_dependence_level%TYPE,
        i_fam_doctor                IN pat_professional.id_professional%TYPE,
        i_free_text_fam_doctor      IN pat_professional.desc_professional%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_SOCIAL.SET_HOUSEHOLD_MEMBER';
        IF NOT pk_social.set_household_member(i_lang                      => i_lang,
                                              i_prof                      => i_prof,
                                              i_id_pat                    => i_id_pat,
                                              i_id_pat_household          => i_id_pat_household,
                                              i_epis                      => i_epis,
                                              i_name                      => i_name,
                                              i_gender                    => i_gender,
                                              i_dt_birth                  => i_dt_birth,
                                              i_id_family_relationship    => i_id_family_relationship,
                                              i_marital_status            => i_marital_status,
                                              i_scholarship               => i_scholarship,
                                              i_pension                   => i_pension,
                                              i_net_wage                  => i_net_wage,
                                              i_unemployment_subsidy      => i_unemployment_subsidy,
                                              i_occupation                => i_occupation,
                                              i_free_text_occupation_desc => i_free_text_occupation_desc,
                                              i_dependecy                 => i_dependecy,
                                              i_fam_doctor                => i_fam_doctor,
                                              i_free_text_fam_doctor      => i_free_text_fam_doctor,
                                              o_error                     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'SET_HOUSEHOLD_MEMBER',
                                                     o_error);
    END set_household_member;
    --

    /********************************************************************************************
    * Get domains values for the household fields (gender, marital status, relationship, occupation).
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_currency_domain       Currency domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/03/05
    **********************************************************************************************/
    FUNCTION get_household_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_gender_domain       OUT pk_types.cursor_type,
        o_marital_domain      OUT pk_types.cursor_type,
        o_relationship_domain OUT pk_types.cursor_type,
        o_occupation_domain   OUT pk_types.cursor_type,
        o_currency_domain     OUT pk_types.cursor_type,
        o_dependency          OUT pk_types.cursor_type,
        o_prof_list_domain    OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_HOUSEHOLD_DOMAINS';
        IF NOT pk_social.get_household_domains(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               o_gender_domain       => o_gender_domain,
                                               o_marital_domain      => o_marital_domain,
                                               o_relationship_domain => o_relationship_domain,
                                               o_occupation_domain   => o_occupation_domain,
                                               o_currency_domain     => o_currency_domain,
                                               o_dependency          => o_dependency,
                                               o_prof_list_domain    => o_prof_list_domain,
                                               o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_gender_domain);
            pk_types.open_my_cursor(o_marital_domain);
            pk_types.open_my_cursor(o_relationship_domain);
            pk_types.open_my_cursor(o_occupation_domain);
            pk_types.open_my_cursor(o_currency_domain);
            pk_types.open_my_cursor(o_dependency);
            pk_types.open_my_cursor(o_prof_list_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_HOUSEHOLD_DOMAINS',
                                                     o_error);
        
    END get_household_domains;
    --
    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge';
        IF NOT pk_discharge_amb.get_discharge(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_discharge      => i_discharge,
                                              i_show_cancelled => pk_alert_constant.g_yes,
                                              o_discharge      => o_discharge,
                                              o_discharge_prof => o_discharge_prof,
                                              o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            RETURN FALSE;
    END get_discharge;

    /*
    * Get discharge data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharge
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_edit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge_edit';
        IF NOT pk_discharge_amb.get_discharge_edit(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_episode   => i_episode,
                                                   i_discharge => i_discharge,
                                                   o_discharge => o_discharge,
                                                   o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            RETURN FALSE;
    END get_discharge_edit;

    /*
    * Check if the CREATE button must be enabled
    * in the discharge screen.
    *
    * @param i_lang           language identifier
    * @param i_episode        episode identifier
    * @param o_create         'Y' to enable create, 'N' otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_create
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type episode.id_epis_type%TYPE;
    BEGIN
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF (l_epis_type NOT IN (pk_alert_constant.g_epis_type_social, pk_alert_constant.g_epis_type_home_health_care))
        THEN
            o_create := pk_alert_constant.g_no;
        ELSE
        
            g_error := 'CALL pk_discharge_amb.get_discharge_create';
            IF NOT pk_discharge_amb.get_discharge_create(i_lang    => i_lang,
                                                         i_episode => i_episode,
                                                         o_create  => o_create,
                                                         o_error   => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_CREATE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_discharge_create;

    /*
    * Get necessary domains for discharge registration.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_destiny        discharge destinies
    * @param o_time_unit      time units
    * @param o_type_closure   type of closure
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_domains
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_destiny      OUT pk_types.cursor_type,
        o_time_unit    OUT pk_types.cursor_type,
        o_type_closure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_domains';
        IF NOT pk_discharge_amb.get_domains(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            o_destiny      => o_destiny,
                                            o_time_unit    => o_time_unit,
                                            o_type_closure => o_type_closure,
                                            o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_destiny);
            pk_types.open_my_cursor(o_time_unit);
            pk_types.open_my_cursor(o_type_closure);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_DOMAINS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_destiny);
            pk_types.open_my_cursor(o_time_unit);
            pk_types.open_my_cursor(o_type_closure);
            RETURN FALSE;
    END get_discharge_domains;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date
    * @param i_disch_dest     discharge reason destiny identifier
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_disch_dest       IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.set_discharge';
        IF NOT pk_paramedical_prof_core.set_discharge(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_prof_cat         => i_prof_cat,
                                                      i_discharge        => i_discharge,
                                                      i_episode          => i_episode,
                                                      i_dt_end           => i_dt_end,
                                                      i_disch_dest       => i_disch_dest,
                                                      i_notes            => i_notes,
                                                      i_time_spent       => i_time_spent,
                                                      i_unit_measure     => i_unit_measure,
                                                      i_print_report     => i_print_report,
                                                      i_flg_type_closure => i_flg_type_closure,
                                                      o_reports_pat      => o_reports_pat,
                                                      o_flg_show         => o_flg_show,
                                                      o_msg_title        => o_msg_title,
                                                      o_msg_text         => o_msg_text,
                                                      o_button           => o_button,
                                                      o_id_episode       => o_id_episode,
                                                      o_discharge        => o_discharge,
                                                      o_disch_detail     => o_disch_detail,
                                                      o_disch_hist       => o_disch_hist,
                                                      o_disch_det_hist   => o_disch_det_hist,
                                                      o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_discharge;

    /*
    * Cancels a discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.set_discharge_cancel';
        IF NOT pk_paramedical_prof_core.set_discharge_cancel(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_discharge      => i_discharge,
                                                             i_episode        => i_episode,
                                                             i_cancel_reason  => i_cancel_reason,
                                                             i_cancel_notes   => i_cancel_notes,
                                                             o_disch_hist     => o_disch_hist,
                                                             o_disch_det_hist => o_disch_det_hist,
                                                             o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_CANCEL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_discharge_cancel;
    --

    /********************************************************************************************
     * Get patient's household history information.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professionals
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/03/11
    **********************************************************************************************/
    FUNCTION get_household_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pat             IN patient.id_patient%TYPE,
        i_id_pat_household   IN patient.id_patient%TYPE,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_HOUSEHOLD_HIST';
        IF NOT pk_social_ux.get_household_hist(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_episode            => NULL,
                                               i_id_pat             => i_id_pat,
                                               i_id_pat_household   => i_id_pat_household,
                                               o_pat_household      => o_pat_household,
                                               o_pat_household_prof => o_pat_household_prof,
                                               o_error              => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HOUSEHOLD_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_household_hist;
    --

    /********************************************************************************************
     * Get patient's household history information.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_id_pat_household       Household member ID (can have the same value of i_id_pat) 
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professionals
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/03/11
    **********************************************************************************************/
    FUNCTION get_household_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_id_pat_household   IN patient.id_patient%TYPE,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_HOUSEHOLD_HIST';
        IF NOT pk_social.get_household_hist(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_episode            => i_episode,
                                            i_id_pat             => i_id_pat,
                                            i_id_pat_household   => i_id_pat_household,
                                            o_pat_household      => o_pat_household,
                                            o_pat_household_prof => o_pat_household_prof,
                                            o_error              => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_HOUSEHOLD_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_household_hist;
    --

    /********************************************************************************************
    * Get patient's EHR Social Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * 
    * @ param  o_screen_labels        Labels
    * @ param  o_episodes_det         List of patient's episodes
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_follow_up             Follow up notes list
    * @ param o_social_report         Social report list
    * @ param o_social_request        Social request list
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_social_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --diagnosis
        o_diagnosis OUT pk_types.cursor_type,
        --intervention_plan
        o_interv_plan OUT pk_types.cursor_type,
        --followup notes
        o_follow_up OUT pk_types.cursor_type,
        --report
        o_social_report OUT pk_types.cursor_type,
        --request
        o_social_request OUT pk_types.cursor_type,
        --
        o_request_origin OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_SOCIAL_SUMMARY_EHR';
        IF NOT pk_social.get_social_summary_ehr(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_id_pat         => i_id_pat,
                                                i_episode        => i_episode,
                                                o_screen_labels  => o_screen_labels,
                                                o_episodes_det   => o_episodes_det,
                                                o_diagnosis      => o_diagnosis,
                                                o_interv_plan    => o_interv_plan,
                                                o_follow_up      => o_follow_up,
                                                o_social_report  => o_social_report,
                                                o_social_request => o_social_request,
                                                o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := ('GET_SOCIAL_EPISODE_TYPE');
        IF pk_social.get_social_epis_type(i_lang, i_prof, i_episode) = 'R'
        THEN
            o_request_origin := pk_alert_constant.g_yes;
        ELSE
            o_request_origin := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_episodes_det);
            --
            pk_types.open_my_cursor(o_diagnosis);
            --
            pk_types.open_my_cursor(o_interv_plan);
            --
            pk_types.open_my_cursor(o_follow_up);
            --
            --
            pk_types.open_my_cursor(o_social_report);
            --
            pk_types.open_my_cursor(o_social_request);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SOCIAL_SUMMARY_EHR',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_social_summary_ehr;
    --

    /********************************************************************************************
     * Get total and per capita family budget.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_allowance_family        Abonos
     * @param i_allowance_complementary Abonos complementares ID
     * @param i_subsidy                 Subsídios
     * @param i_other                   Outros
     * @param i_fixed_expenses          Despesas fixas
     * @param i_total                   Total do rendimento do agregado familiar do paciente
     * @param i_tot_person              Nº de pessoas do agragado familiar do paciente
     * @param o_tots                    Total and per capita family budget
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           ET
     * @version                          0.1
     * @since                            2006/05/08
    **********************************************************************************************/

    FUNCTION get_tot_money
    (
        i_lang                    IN language.id_language%TYPE,
        i_allowance_family        IN family_monetary.allowance_family%TYPE,
        i_allowance_complementary IN family_monetary.allowance_complementary%TYPE,
        i_subsidy                 IN family_monetary.subsidy%TYPE,
        i_other                   IN family_monetary.other%TYPE,
        i_fixed_expenses          IN family_monetary.fixed_expenses%TYPE,
        i_total                   IN family_monetary.subsidy%TYPE,
        i_tot_person              IN NUMBER,
        o_tots                    OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_tot_money';
        IF NOT pk_social.get_tot_money(i_lang                    => i_lang,
                                       i_allowance_family        => i_allowance_family,
                                       i_allowance_complementary => i_allowance_complementary,
                                       i_subsidy                 => i_subsidy,
                                       i_other                   => i_other,
                                       i_fixed_expenses          => i_fixed_expenses,
                                       i_total                   => i_total,
                                       i_tot_person              => i_tot_person,
                                       o_tots                    => o_tots,
                                       o_error                   => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TOT_MONEY',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_tots);
            RETURN FALSE;
    END get_tot_money;

    /*
    * Get data for the social requests grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_show_all       'Y' to show all requests,
    *                         'N' to show a specific SW requests.
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.0.1
    * @since                  07-04-2010
    */
    FUNCTION get_paramedical_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramedical_requests';
        IF NOT pk_paramedical_prof_core.get_paramedical_requests(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_show_all => i_show_all,
                                                                 o_requests => o_requests,
                                                                 o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARAMEDICAL_REQUESTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        
    END get_paramedical_requests;

    /********************************************************************************************
    * Get the history of a given intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_report
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST';
        IF NOT pk_paramedical_prof_core.get_interv_plan_hist_report(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_epis             => table_number(i_id_epis),
                                                                    i_id_epis_interv_plan => i_id_epis_interv_plan,
                                                                    o_interv_plan         => o_interv_plan,
                                                                    o_interv_plan_prof    => o_interv_plan_prof,
                                                                    o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'get_interv_plan_hist_report',
                                                     o_error);
    END get_interv_plan_hist_report;
    /*
    * Get an episode's follow up notes list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_followup_notes';
        IF NOT pk_paramedical_prof_core.get_followup_notes_report(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_episode        => i_episode,
                                                                  i_mng_followup   => i_mng_followup,
                                                                  i_show_cancelled => pk_alert_constant.g_yes,
                                                                  o_follow_up_prof => o_follow_up_prof,
                                                                  o_follow_up      => o_follow_up,
                                                                  o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_followup_notes_report',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
    END get_followup_notes_report;

    /********************************************************************************************
    * Get patient's Social status. This includes information of:
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_id_pat                 Patient ID 
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --house hold
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_social.get_social_status_report(i_lang,
                                                  i_prof,
                                                  i_episode,
                                                  i_id_pat,
                                                  o_pat_home,
                                                  o_pat_home_prof,
                                                  o_pat_social_class,
                                                  o_pat_social_class_prof,
                                                  o_pat_financial,
                                                  o_pat_financial_prof,
                                                  o_pat_household,
                                                  o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'get_social_status_report',
                                                     o_error);
        
    END get_social_status_report;
    /********************************************************************************************
     * Get patient's household history information.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_id_pat_household       Household member ID (can have the same value of i_id_pat) 
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professionals
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/03/11
    **********************************************************************************************/
    FUNCTION get_household_hist_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_id_pat_household   IN patient.id_patient%TYPE,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get_household_hist_report';
        IF NOT pk_social.get_household_hist_report(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_episode            => i_episode,
                                                   i_id_pat             => i_id_pat,
                                                   i_id_pat_household   => i_id_pat_household,
                                                   o_pat_household      => o_pat_household,
                                                   o_pat_household_prof => o_pat_household_prof,
                                                   o_error              => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_household_hist_report',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_household_hist_report;
    --
    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_episode                                  episode identifier
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_interv_plan_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diag       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_paramedical_prof_core.get_interv_plan_diag(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_episode => i_id_episode,
                                                             o_diag       => o_diag,
                                                             o_error      => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INTERV_PLAN_DIAG',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
    END get_interv_plan_diag;

    /********************************************************************************************
    * get all patients button grid data. 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_software            software id for filtering purpose
    * @param o_data                   output cursor
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                          Telmo
    * @version                         2.6.1.2
    * @since                           19-09-2011
    **********************************************************************************************/
    FUNCTION get_all_patient_grid_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_social.get_all_patient_grid_data(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_software => i_id_software,
                                                   o_data        => o_data,
                                                   o_error       => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ALL_PATIENT_GRID_DATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_all_patient_grid_data;

    /********************************************************************************************
    * create a follow-up request and sets it as accepted. To be used in the All patient button when
    * the user presses OK in a valid episode (those without follow-up). 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             episode that will be followed
    * @param i_id_patient             episode patient
    * @param i_id_dcs                 episode's dcs
    * @param i_id_prof                professional that is creating this follow up
    * @param o_id_opinion             resulting follow up request id
    * @param o_id_episode             resulting follow-up episode id 
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                         Telmo
    * @version                        2.6.1.2
    * @since                          21-09-2011
    **********************************************************************************************/
    FUNCTION set_accepted_follow_up
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof    IN opinion.id_prof_questioned%TYPE,
        o_id_opinion OUT opinion.id_opinion%TYPE,
        o_id_episode OUT opinion.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_id_cat  prof_cat.id_category%TYPE;
        l_opinion_type opinion_type.id_opinion_type%TYPE;
        l_epis_type    episode.id_epis_type%TYPE;
    BEGIN
    
        l_prof_id_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        BEGIN
            SELECT ot.id_opinion_type
              INTO l_opinion_type
              FROM opinion_type ot
             INNER JOIN opinion_type_category otc
                ON otc.id_opinion_type = ot.id_opinion_type
             WHERE otc.id_category = l_prof_id_cat
               AND ((l_epis_type IN
                   (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
                   ot.id_opinion_type <> pk_opinion.g_ot_social_worker) OR
                   (l_epis_type NOT IN
                   (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
                   ot.id_opinion_type <> pk_opinion.g_ot_social_worker_ds));
        EXCEPTION
            WHEN no_data_found THEN
                l_opinion_type := pk_opinion.g_ot_social_worker;
        END;
    
        RETURN pk_social.set_accepted_follow_up(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_episode      => i_id_episode,
                                                i_id_patient      => i_id_patient,
                                                i_id_dcs          => i_id_dcs,
                                                i_id_prof         => i_id_prof,
                                                i_id_opinion_type => l_opinion_type,
                                                o_id_opinion      => o_id_opinion,
                                                o_id_episode      => o_id_episode,
                                                o_error           => o_error);
    END set_accepted_follow_up;

    /*************************************************
    * Check if button create is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_create_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_active OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_paramedical_prof_core.get_create_active(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_episode    => i_episode,
                                                          o_flg_active => o_flg_active);
    
    END get_create_active;

    /*************************************************
    * Checks if the episode has followup requests
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode idendifier
    * @param o_followup_access        returns if exists a followup request and his current status
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                 Teresa Coutinho 
    * @version                2.6.4.2.1
    * @since                  2014/10/16
    ***********************************************/
    FUNCTION get_followup_access
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_followup_access OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_paramedical_prof_core.get_followup_access(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_episode         => i_episode,
                                                            o_followup_access => o_followup_access,
                                                            o_error           => o_error);
    
    END get_followup_access;
    
        /********************************************************************************************
    * Get the list of intervention plans for a patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_patient               Patient ID 
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Jorge Silva
    * @version                         0.1
    * @since                           2014/01/20
    **********************************************************************************************/
    FUNCTION get_interv_ehr_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_EHR_PLAN';
        IF NOT pk_paramedical_prof_core.get_interv_ehr_plan(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_id_patient    => i_id_patient,
                                                            o_interv_plan   => o_interv_plan,
                                                            o_screen_labels => o_screen_labels,
                                                            o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_EHR_PLAN',
                                                     o_error);
    END get_interv_ehr_plan;

BEGIN

    -- Initialization
    g_owner   := 'ALERT';
    g_package := 'PK_SOCIAL_UX';

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_social_ux;
/
