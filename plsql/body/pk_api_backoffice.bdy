/*-- Last Change Revision: $Rev: 2045487 $*/
/*-- Last Change by: $Author: andre.silva $*/
/*-- Date of last change: $Date: 2022-09-19 08:42:35 +0100 (seg, 19 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_backoffice IS

    /********************************************************************************************
    * Set Institution Professional state
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_flg_state             Professional state
    * @param i_num_mecan             Mecan. Number
    * @param o_flg_state             Professional state
    * @param o_icon                  Professional state icon
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/06/02
    ********************************************************************************************/
    FUNCTION set_prof_institution_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN prof_institution.id_professional%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_flg_state       IN prof_institution.flg_state%TYPE,
        i_num_mecan       IN prof_institution.num_mecan%TYPE,
        o_flg_state       OUT prof_institution.flg_state%TYPE,
        o_icon            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_backoffice.set_prof_institution_state(i_lang,
                                                        i_id_professional,
                                                        i_id_institution,
                                                        i_flg_state,
                                                        i_num_mecan,
                                                        o_flg_state,
                                                        o_icon,
                                                        o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_PROF_INSTITUTION_STATE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_prof_institution_state;

    /********************************************************************************************
    * Update/insert information for an user
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_first_name            Professional ID
    * @param i_title                 Professional Title
    * @param i_nickname              Professional Nickname
    * @param i_gender                Professioanl gender
    * @param i_category              Professional category
    * @param i_dt_birth              Professional Date of Birth
    * @param i_email                 Professional email
    * @param i_phone                 Professional phone
    * @param i_fax                   Professional fax
    * @param i_mobile_phone          Professional mobile phone
    * @param i_id_inst               Institution ID for a professional
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      S?rgio Monteiro
    * @version                     0.1
    * @since                       2008/11/14
    ********************************************************************************************/

    FUNCTION intf_set_profissional
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_inst        IN institution.id_institution%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nickname       IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN professional.dt_birth%TYPE,
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_category       IN prof_cat.id_category%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_upin           IN professional.upin%TYPE,
        i_dea            IN professional.dea%TYPE,
        i_id_cat_surgery IN category.id_category%TYPE,
        i_num_mecan      IN prof_institution.num_mecan%TYPE,
        i_id_lang        IN prof_preferences.id_language%TYPE,
        i_flg_state      IN prof_institution.flg_state%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE,
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_phone          IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_mobile_phone   IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_suffix         IN professional.suffix%TYPE,
        i_contact_det    IN prof_institution.contact_detail%TYPE,
        i_county         IN professional.county%TYPE DEFAULT NULL,
        i_other_adress   IN professional.address_other_name%TYPE DEFAULT NULL,
        o_professional   OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_profissional NUMBER;
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROFESSIONAL: ' || g_error);
        IF NOT pk_backoffice_api_ui.set_professional(i_lang                    => i_lang,
                                                     i_id_institution          => i_id_inst,
                                                     i_id_prof                 => i_id_prof,
                                                     i_middle_name             => i_middle_name,
                                                     i_initials                => i_initials,
                                                     i_dt_birth                => to_char(i_dt_birth, 'YYYYMMDDhh24miss'),
                                                     i_marital_status          => i_marital_status,
                                                     i_id_category             => i_category, /*deprecated*/
                                                     i_id_speciality           => i_id_speciality,
                                                     i_num_order               => i_num_order,
                                                     i_upin                    => i_upin,
                                                     i_dea                     => i_dea,
                                                     i_id_cat_surgery          => i_id_cat_surgery, /*deprecated*/
                                                     i_num_mecan               => i_num_mecan,
                                                     i_id_lang                 => i_id_lang,
                                                     i_flg_state               => i_flg_state,
                                                     i_address                 => i_address,
                                                     i_city                    => i_city,
                                                     i_district                => i_district,
                                                     i_zip_code                => i_zip_code,
                                                     i_id_country              => i_id_country,
                                                     i_work_phone              => i_phone,
                                                     i_num_contact             => i_num_contact,
                                                     i_cell_phone              => i_mobile_phone,
                                                     i_fax                     => i_fax,
                                                     i_email                   => i_email,
                                                     i_commit_at_end           => FALSE,
                                                     o_id_prof                 => l_id_profissional,
                                                     i_first_name              => i_first_name,
                                                     i_last_name               => i_last_name,
                                                     i_title                   => i_title,
                                                     i_gender                  => i_gender,
                                                     i_nick_name               => i_nickname,
                                                     i_adress_type             => NULL,
                                                     i_id_scholarship          => NULL,
                                                     i_bleep_num               => NULL,
                                                     i_suffix                  => i_suffix,
                                                     i_contact_det             => i_contact_det,
                                                     i_county                  => i_county,
                                                     i_other_adress            => i_other_adress,
                                                     i_id_road                 => NULL,
                                                     i_entity                  => NULL,
                                                     i_jurisdiction            => NULL,
                                                     i_municip                 => NULL,
                                                     i_localidad               => NULL,
                                                     i_id_postal_code_rb       => NULL,
                                                     i_parent_name             => NULL,
                                                     i_first_name_sa           => NULL,
                                                     i_parent_name_sa          => NULL,
                                                     i_middle_name_sa          => NULL,
                                                     i_last_name_sa            => NULL,
                                                     i_agrupacion              => NULL,
                                                     i_doc_ident_type          => NULL,
                                                     i_doc_ident_num           => NULL,
                                                     i_doc_ident_val           => NULL,
                                                     i_tin                     => NULL,
                                                     i_clinical_name           => NULL,
                                                     i_prof_spec_id            => NULL,
                                                     i_prof_spec_ballot        => NULL,
                                                     i_prof_spec_id_university => NULL,
                                                     i_agrupacion_instit_id    => NULL,
                                                     o_error                   => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        o_professional := l_id_profissional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_profissional;

    /********************************************************************************************
    * Update/insert information for an institution
    *
    * @param i_lang                  Prefered language ID
    * @param i_flg_type_inst         Flag type for institution - H - Hospital, C - Primary Care, P - Private Practice
    * @param i_id_country            Institution ID country
    * @param i_inst_name             Institution name
    * @param i_inst_address          Institution address
    * @param i_inst_zipcode          Institution zipcode
    * @param i_inst_phone            Institution phone
    * @param i_inst_fax              Institution fax
    * @param i_inst_email            Institution email
    * @param i_inst_currency         Institution prefered currency
    * @param i_inst_timezone         Institution timezendo ID
    * @param i_inst_acronym          Institution acronym
    * @param i_market                Market id
    * @param o_id_institution        institution ID created
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      S?rgio Monteiro
    * @version                     0.1
    * @since                       2008/11/14
    ********************************************************************************************/

    FUNCTION intf_set_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_flg_type_inst  IN institution.flg_type%TYPE,
        i_id_country     IN inst_attributes.id_country%TYPE,
        i_inst_name      IN pk_translation.t_desc_translation,
        i_inst_address   IN institution.address%TYPE,
        i_inst_zipcode   IN institution.zip_code%TYPE,
        i_inst_phone     IN institution.phone_number%TYPE,
        i_inst_fax       IN institution.fax_number%TYPE,
        i_inst_email     IN inst_attributes.email%TYPE,
        i_inst_currency  IN inst_attributes.id_currency%TYPE,
        i_inst_timezone  IN institution.id_timezone_region%TYPE,
        i_inst_acronym   IN institution.abbreviation%TYPE,
        i_market         IN market.id_market%TYPE,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_id_institution NUMBER;
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE INSTITUTION';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_INSTITUTION: ' || g_error);
        IF NOT pk_backoffice.set_institution_data_online(i_lang           => i_lang,
                                                         i_flg_type_inst  => i_flg_type_inst,
                                                         i_id_country     => i_id_country,
                                                         i_inst_name      => i_inst_name,
                                                         i_inst_address   => i_inst_address,
                                                         i_inst_zipcode   => i_inst_zipcode,
                                                         i_inst_phone     => i_inst_phone,
                                                         i_inst_fax       => i_inst_fax,
                                                         i_inst_email     => i_inst_email,
                                                         i_inst_currency  => i_inst_currency,
                                                         i_inst_timezone  => i_inst_timezone,
                                                         i_inst_acronym   => i_inst_acronym,
                                                         i_market         => i_market,
                                                         o_id_institution => l_id_institution,
                                                         o_error          => l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        o_id_institution := l_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_institution;

    /********************************************************************************************
    * SET TEMPORARY PROFESSIONAL
    *
    * @param i_lang                  Prefered language ID
    * @param i_login                 Professional Login
    * @param i_pass                  Professional pass
    * @param i_name                  Professional name
    * @param i_nick_name             Professional nick name
    * @param i_gender                Professional gender
    * @param i_secret_answ           Professional secret answer
    * @param i_secret_quest          Professional secret question
    * @param o_id_professional       Professional ID
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        S?rgio Monteiro
    * @version                       0.1
    * @since                         2008/11/15
    ********************************************************************************************/

    FUNCTION intf_set_temporary_user
    (
        i_lang            IN language.id_language%TYPE,
        i_login           IN VARCHAR2,
        i_pass            IN VARCHAR2,
        i_name            IN professional.name%TYPE,
        i_nick_name       IN professional.nick_name%TYPE,
        i_gender          IN professional.gender%TYPE,
        i_secret_answ     IN VARCHAR2,
        i_secret_quest    IN VARCHAR2,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
    
        g_error := 'CREATE TEMPORARY USER: login = ' || i_login;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_TEMPORARY_USER: ' || g_error);
        IF NOT pk_backoffice.set_temporary_user(i_lang            => i_lang,
                                                i_login           => i_login,
                                                i_pass            => i_pass,
                                                i_name            => i_name,
                                                i_nick_name       => i_nick_name,
                                                i_gender          => i_gender,
                                                i_secret_answ     => i_secret_answ,
                                                i_secret_quest    => i_secret_quest,
                                                i_commit_at_end   => FALSE,
                                                o_id_professional => o_id_professional,
                                                o_error           => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error || ' / ' || o_error.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_TEMPORARY_USER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_TEMPORARY_USER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_temporary_user;

    /********************************************************************************************
    * API FOR LICENSES
    *
    * @param i_id_institution             id institution
    * @param i_id_product_purchasable     id for product purchasable
    * @param i_flg_status                 license status
    * @param i_payment_schedule           A - annual ; B -biannual
    * @param i_expire_date                expire date
    * @param i_purchase_date              license purchase date
    * @param i_notes_license              license notes
    * @param i_id_profile_template_desc   id profile template
    * @param o_error                      error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      S?rgio Monteiro
    * @version                     0.1
    * @since                       2008/11/14
    ********************************************************************************************/

    FUNCTION intf_set_licenses
    (
        i_id_institution           IN license.id_institution%TYPE,
        i_id_product_purchasable   IN license.id_product_purchasable%TYPE,
        i_flg_status               IN license.flg_status%TYPE,
        i_payment_schedule         IN license.payment_schedule%TYPE,
        i_expire_date              IN license.dt_expire_tstz%TYPE,
        i_purchase_date            IN license.dt_purchase_tstz%TYPE,
        i_notes_license            IN license.notes_license%TYPE,
        i_id_profile_template_desc IN license.id_profile_template_desc%TYPE,
        o_error                    OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE Licenses: id_institution = ' || i_id_institution;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_LICENSES: ' || g_error);
        IF NOT pk_backoffice.set_licenses(i_lang                     => 1,
                                          i_id_institution           => i_id_institution,
                                          i_id_product_purchasable   => i_id_product_purchasable,
                                          i_id_professional          => NULL,
                                          i_dt_expire                => NULL,
                                          i_flg_status               => i_flg_status,
                                          i_payment_schedule         => i_payment_schedule,
                                          i_notes_license            => i_notes_license,
                                          i_dt_purchase              => NULL,
                                          i_id_profile_template_desc => i_id_profile_template_desc,
                                          i_dt_expire_tstz           => i_expire_date,
                                          i_dt_purchase_tstz         => i_purchase_date,
                                          o_error                    => l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_LICENSES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_LICENSES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * attribute profiles to a software and to an institution
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_profissional       Id_professional
    * @param i_institution_list      list of institutions
    * @param i_software_list         list of softwares
    * @param i_template_list         list of templates
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      S?rgio Monteiro
    * @version                     0.1
    * @since                       2008/12/02
    ********************************************************************************************/

    FUNCTION intf_set_template_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_profissional  IN professional.id_professional%TYPE,
        i_institution_list IN table_number,
        i_software_list    IN table_number,
        i_template_list    IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL PROFILES: id_professional = ' || i_id_profissional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_TEMPLATE_LIST: ' || g_error);
        IF NOT pk_backoffice.set_template_list(i_lang             => i_lang,
                                               i_id_prof          => i_id_profissional,
                                               i_inst             => i_institution_list,
                                               i_soft             => i_software_list,
                                               i_id_dep_clin_serv => NULL,
                                               i_templ            => i_template_list,
                                               i_commit_at_end    => FALSE,
                                               o_error            => l_error_out)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_TEMPLATE_LIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_TEMPLATE_LIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Find a professional based on accounts values
    *
    * @param i_lang                  Prefered language ID
    * @param i_accounts              Accounts ID's
    * @param i_accounts_val          Accounts values
    * @param o_professional          Professional ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     0.1
    * @since                       2009/12/12
    ********************************************************************************************/

    FUNCTION intf_get_professional
    (
        i_lang         IN language.id_language%TYPE,
        i_accounts     IN table_number,
        i_accounts_val IN table_varchar,
        o_professional OUT professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_profissional NUMBER;
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'GET PROFESIONAL ID FROM ACCOUNTS VALUES';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_GET_PROFESSIONAL: ' || g_error);
        IF NOT pk_backoffice.get_id_professional(i_lang         => i_lang,
                                                 i_accounts     => i_accounts,
                                                 i_accounts_val => i_accounts_val,
                                                 o_professional => l_id_profissional,
                                                 o_error        => l_error_out)
        
        THEN
            RAISE l_exception;
        
        END IF;
    
        o_professional := l_id_profissional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_get_professional;

    /********************************************************************************************
    * Find an institution based on accounts values
    *
    * @param i_lang                  Prefered language ID
    * @param i_accounts              Accounts ID's
    * @param i_accounts_val          Accounts values
    * @param o_institution           Institution ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     0.1
    * @since                       2009/12/12
    ********************************************************************************************/

    FUNCTION intf_get_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_accounts     IN table_number,
        i_accounts_val IN table_varchar,
        o_institution  OUT professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_institution NUMBER;
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE INSTITUTION ID FROM ACCOUNTS VALUES';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTITUTION: ' || g_error);
        IF NOT pk_backoffice.get_id_institution(i_lang         => i_lang,
                                                i_accounts     => i_accounts,
                                                i_accounts_val => i_accounts_val,
                                                o_institution  => l_id_institution,
                                                o_error        => l_error_out)
        
        THEN
            RAISE l_exception;
        
        END IF;
    
        o_institution := l_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_get_institution;

    /********************************************************************************************
    * Set Professional affiliations values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/12/12
    ********************************************************************************************/
    FUNCTION intf_set_prof_accounts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_institution     IN table_number,
        i_accounts        IN table_number,
        i_values          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL ACCOUNTS: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
        IF NOT pk_backoffice.set_prof_affiliations(i_lang            => i_lang,
                                                   i_id_professional => i_id_professional,
                                                   i_institution     => i_institution,
                                                   i_accounts        => i_accounts,
                                                   i_values          => i_values,
                                                   o_error           => l_error_out)
        
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_ACCOUNTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_ACCOUNTS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_prof_accounts;

    /********************************************************************************************
    * Set institution affiliations values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/12/12
    ********************************************************************************************/
    FUNCTION intf_set_inst_accounts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_accounts       IN table_number,
        i_values         IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE INSTITUTION ACCOUNTS: id_institution = ' || i_id_institution;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_INST_ACCOUNTS: ' || g_error);
        IF NOT pk_backoffice.set_inst_affiliations(i_lang           => i_lang,
                                                   i_id_institution => i_id_institution,
                                                   i_accounts       => i_accounts,
                                                   i_values         => i_values,
                                                   o_error          => l_error_out)
        
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_INST_ACCOUNTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_INST_ACCOUNTS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_inst_accounts;

    /********************************************************************************************
    * Update/insert information for an external user
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_title                 Professional Title
    * @param i_first_name            Professional first name
    * @param i_middle_name           Professional middle name
    * @param i_last_name             Professional last name
    * @param i_nickname              Professional Nickname
    * @param i_initials              Professional initials
    * @param i_dt_birth              Professional Date of Birth
    * @param i_gender                Professioanl gender
    * @param i_marital_status        Professional marital status
    * @param i_id_speciality         Professional specialty
    * @param i_num_order             Professional license number
    * @param i_address               Professional adress
    * @param i_city                  Professional city
    * @param i_district              Professional district
    * @param i_zip_code              Professional zip code
    * @param i_id_country            Professional cpuntry
    * @param i_phone                 Professional phone
    * @param i_mobile_phone          Professional mobile phone
    * @param i_fax                   Professional fax
    * @param i_email                 Professional email
    * @param o_professional          Professional ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION intf_set_ext_profissional
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nickname       IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN professional.dt_birth%TYPE,
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE,
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_phone          IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_mobile_phone   IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        o_professional   OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE EXTERNAL PROFESIONAL';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_EXT_PROFESSIONAL: ' || g_error);
        IF NOT pk_backoffice.set_ext_professional(i_lang           => i_lang,
                                                  i_id_prof        => i_id_prof,
                                                  i_title          => i_title,
                                                  i_first_name     => i_first_name,
                                                  i_parent_name    => NULL,
                                                  i_middle_name    => i_middle_name,
                                                  i_last_name      => i_last_name,
                                                  i_nickname       => i_nickname,
                                                  i_initials       => i_initials,
                                                  i_dt_birth       => i_dt_birth,
                                                  i_gender         => i_gender,
                                                  i_marital_status => i_marital_status,
                                                  i_id_speciality  => i_id_speciality,
                                                  i_num_order      => i_num_order,
                                                  i_address        => i_address,
                                                  i_city           => i_city,
                                                  i_district       => i_district,
                                                  i_zip_code       => i_zip_code,
                                                  i_id_country     => i_id_country,
                                                  i_phone          => i_phone,
                                                  i_num_contact    => i_num_contact,
                                                  i_mobile_phone   => i_mobile_phone,
                                                  i_fax            => i_fax,
                                                  i_email          => i_email,
                                                  i_id_institution => i_id_institution,
                                                  i_commit_at_end  => FALSE,
                                                  o_professional   => o_professional,
                                                  o_error          => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_PROFISSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_ext_profissional;

    /********************************************************************************************
    * Create/Update external institution
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_inst_att           Institution Attibutes ID
    * @param i_desc                  Institution name
    * @param i_id_parent             Parent Institution ID
    * @param i_flg_type              Flag type for institution - H - Hospital, C - Primary Care, P - Private Practice
    * @param i_abbreviation          Institution abbreviation
    * @param i_phone_number          Institution phone
    * @param i_fax                   Institution fax
    * @param i_email                 Institution email
    * @param i_ext_code              Institution Code
    * @param i_adress                Institution address
    * @param i_location              Institution location
    * @param i_district              Institution district
    * @param i_zip_code              Institution zip code
    * @param i_country               Institution Country ID
    * @param i_flg_available         Available - Y - Yes, N - No
    * @param i_id_tz_region          Institution timezone ID
    * @param i_id_market             Institution Market id
    * @param i_commit_at_end         Commit changes in this function - Y - Yes, N - No
    * @param o_id_institution        institution ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION intf_set_ext_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_desc           IN VARCHAR2,
        i_id_parent      IN institution.id_parent%TYPE,
        i_flg_type       IN institution.flg_type%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_phone_number   IN institution.phone_number%TYPE,
        i_fax            IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_ext_code       IN institution.ext_code%TYPE,
        i_adress         IN institution.address%TYPE,
        i_location       IN institution.location%TYPE,
        i_district       IN institution.district%TYPE,
        i_zip_code       IN institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_id_tz_region   IN institution.id_timezone_region%TYPE,
        i_id_market      IN market.id_market%TYPE,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE EXTERNAL INSTITUTION';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_EXT_INSTITUTION: ' || g_error);
        IF NOT pk_backoffice.set_ext_institution(i_lang           => i_lang,
                                                 i_id_institution => i_id_institution,
                                                 i_id_inst_att    => i_id_inst_att,
                                                 i_desc           => i_desc,
                                                 i_id_parent      => i_id_parent,
                                                 i_flg_type       => i_flg_type,
                                                 i_abbreviation   => i_abbreviation,
                                                 i_phone_number   => i_phone_number,
                                                 i_fax            => i_fax,
                                                 i_email          => i_email,
                                                 i_ext_code       => i_ext_code,
                                                 i_adress         => i_adress,
                                                 i_location       => i_location,
                                                 i_district       => i_district,
                                                 i_zip_code       => i_zip_code,
                                                 i_country        => i_country,
                                                 i_flg_available  => i_flg_available,
                                                 i_id_tz_region   => i_id_tz_region,
                                                 i_id_market      => i_id_market,
                                                 i_commit_at_end  => FALSE,
                                                 o_id_institution => o_id_institution,
                                                 o_error          => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_ext_institution;

    /********************************************************************************************
    * Set Institution Professional state
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_flg_state             Professional state
    * @param i_num_mecan             Mecan. Number
    * @param o_flg_state             Professional state in the institution
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION intf_set_prof_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN prof_institution.id_professional%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_flg_state       IN prof_institution.flg_state%TYPE,
        i_num_mecan       IN prof_institution.num_mecan%TYPE,
        o_flg_state       OUT prof_institution.flg_state%TYPE,
        o_icon            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_institution NUMBER;
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        SELECT COUNT(pi.id_prof_institution)
          INTO l_prof_institution
          FROM prof_institution pi
         WHERE pi.id_professional = i_id_professional
           AND pi.id_institution = i_id_institution;
    
        g_error := 'ASSOCIATE A PROFESIONAL TO AN INSTITUTION : id_professional = ' || i_id_professional ||
                   ' , id_institution = ' || i_id_institution;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_INSTITUTION: ' || g_error);
        IF l_prof_institution = 0
        THEN
        
            IF NOT pk_backoffice.set_prof_institution(i_lang            => i_lang,
                                                      i_id_professional => i_id_professional,
                                                      i_id_institution  => i_id_institution,
                                                      i_flg_state       => i_flg_state,
                                                      i_num_mecan       => i_num_mecan,
                                                      o_flg_state       => o_flg_state,
                                                      o_error           => l_error_out)
            THEN
                RAISE l_exception;
            
            END IF;
        
        ELSE
        
            IF NOT pk_backoffice.set_prof_institution_state(i_lang            => i_lang,
                                                            i_id_professional => i_id_professional,
                                                            i_id_institution  => i_id_institution,
                                                            i_flg_state       => i_flg_state,
                                                            i_num_mecan       => i_num_mecan,
                                                            o_flg_state       => o_flg_state,
                                                            o_icon            => o_icon,
                                                            o_error           => l_error_out)
            THEN
                RAISE l_exception;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_institution;

    /********************************************************************************************
    * Set Institution Professional Specialties
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_id_institution        Institution ID
    * @param i_id_dep_clin_serv      Professional Specialties
    * @param i_flg                   Y - Insert specialty, N - Remove specialty
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION intf_set_prof_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg              IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL SPECIALTIES: id_professional = ' || i_id_prof;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_DCS: ' || g_error);
        IF NOT pk_backoffice.set_prof_specialties(i_lang             => i_lang,
                                                  i_id_prof          => i_id_prof,
                                                  i_id_institution   => i_id_institution,
                                                  i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                  i_flg              => i_flg,
                                                  o_error            => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_DCS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_DCS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_dcs;

    /********************************************************************************************
    * Set Institution Professional Category
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_id_institution        Institution ID
    * @param i_id_category           Professional Category
    * @param i_id_cat_surgery        Professional Category In Surgery
    * @param o_id_prof               Professional state
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION intf_set_prof_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_cat_surgery IN category.id_category%TYPE,
        o_id_prof        OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL CATEGORY: id_professional = ' || i_id_prof;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_CAT: ' || g_error);
        IF NOT pk_backoffice.set_prof_cat(i_lang           => i_lang,
                                          i_id_prof        => i_id_prof,
                                          i_id_institution => i_id_institution,
                                          i_id_category    => i_id_category,
                                          i_id_cat_surgery => i_id_cat_surgery,
                                          i_commit_at_end  => FALSE,
                                          o_id_prof        => o_id_prof,
                                          o_error          => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_CAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_CAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_cat;

    /********************************************************************************************
    * Set Professional Rooms association
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_room                  Room ID's
    * @param i_room_select           Rooms selection
    * @param i_room_pref             Selection of preferencial room
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION intf_set_prof_room
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room        IN table_number,
        i_room_select IN table_varchar,
        i_room_pref   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL ROOMS ASSOCIATION: id_professional = ' || i_prof.id;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ROOM: ' || g_error);
        IF NOT pk_tools.create_prof_room(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_room        => i_room,
                                         i_room_select => i_room_select,
                                         i_room_pref   => i_room_pref,
                                         o_error       => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_room;

    /********************************************************************************************
    * Set Professional Photo
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_photo_dir             Directory that contains the photo
    * @param i_photo_name            Photo file name
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/15
    ********************************************************************************************/
    FUNCTION intf_set_prof_photo
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_photo_name      IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bfile BFILE;
        l_blob  BLOB;
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'GET PROFESIONAL PHOTO: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_PHOTO: ' || g_error);
        IF pk_profphoto.check_blob(i_prof => i_id_professional) = 'N'
        THEN
        
            IF NOT pk_profphoto.insert_emptyblob(i_prof      => i_id_professional,
                                                 i_prof_user => profissional(i_id_professional, 0, 0),
                                                 o_error     => l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'SET PROFESIONAL PHOTO: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_PHOTO: ' || g_error);
        l_bfile := bfilename('PROF_PHOTOS', i_photo_name);
    
        SELECT pp.img_photo
          INTO l_blob
          FROM prof_photo pp
         WHERE pp.id_professional = i_id_professional
           FOR UPDATE;
    
        dbms_lob.fileopen(l_bfile, dbms_lob.file_readonly);
        dbms_lob.loadfromfile(l_blob, l_bfile, dbms_lob.getlength(l_bfile));
        dbms_lob.close(l_bfile);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_PHOTO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_PHOTO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_photo;

    /********************************************************************************************
    * Set Professional Photo
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_photo_file            Photo file
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/15
    ********************************************************************************************/
    FUNCTION intf_set_prof_photo
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_photo_file      IN prof_photo.img_photo%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'GET PROFESIONAL PHOTO: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_PHOTO: ' || g_error);
        IF pk_profphoto.check_blob(i_prof => i_id_professional) = 'N'
        THEN
        
            IF NOT pk_profphoto.insert_emptyblob(i_prof      => i_id_professional,
                                                 i_prof_user => profissional(i_id_professional, 0, 0),
                                                 o_error     => l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'SET PROFESIONAL PHOTO: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_PHOTO: ' || g_error);
        UPDATE prof_photo pp
           SET pp.img_photo = i_photo_file
         WHERE pp.id_professional = i_id_professional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_PHOTO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_PROF_PHOTO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_photo;

    /********************************************************************************************
    * get Professional identification
    *
    * @param i_lang                  Prefered language ID
    * @param i_initials              Professional Initials
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                     SMSS
    * @version                    2.5.0.7.4.1
    * @since                       2010/01/15
    ********************************************************************************************/
    FUNCTION get_prof_identification
    (
        i_lang     IN language.id_language%TYPE,
        i_initials IN professional.initials%TYPE,
        o_error    OUT t_error_out
    ) RETURN NUMBER IS
    
        l_id_professional professional.id_professional%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFESSIONAL IDENTIFICATION initials = ' || i_initials;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_IDENTIFICATION: ' || g_error);
    
        SELECT nvl((SELECT id_professional
                     FROM (SELECT p.id_professional
                             FROM professional p
                            WHERE upper(p.initials) = upper(i_initials)
                            ORDER BY p.id_professional ASC)
                    WHERE rownum = 1),
                   0)
          INTO l_id_professional
          FROM dual;
    
        RETURN l_id_professional;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_IDENTIFICATION',
                                              o_error);
            RETURN 0;
        
    END get_prof_identification;

    /********************************************************************************************
    * Set Staging Area files
    *
    * @param i_lang                Prefered language ID
    * @param i_file_name           File name
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param o_id_stg_files        Staging area file ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/21
    ********************************************************************************************/
    FUNCTION set_stg_files
    (
        i_lang            IN language.id_language%TYPE,
        i_file_name       IN stg_files.file_name%TYPE,
        i_id_professional IN stg_files.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_id_stg_files    OUT stg_files.id_stg_files%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'DELETE ALL DATA IN STG_AREA FROM ID_INSTITUTION = ' || i_id_institution;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_FILES: ' || g_error);
        DELETE FROM stg_professional_field_data pfd
         WHERE pfd.id_institution = i_id_institution;
        DELETE FROM stg_prof_institution pi
         WHERE pi.id_institution = i_id_institution;
        DELETE FROM stg_professional p
         WHERE p.id_institution = i_id_institution;
        DELETE FROM stg_institution_field_data ifd
         WHERE ifd.id_institution = i_id_institution;
        DELETE FROM stg_institution i
         WHERE i.id_institution = i_id_institution;
    
        g_error := 'GET ID_STG_FILES TO INSERT';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_FILES: ' || g_error);
        SELECT decode(MAX(sf.id_stg_files), NULL, 1, MAX(sf.id_stg_files) + 1)
          INTO o_id_stg_files
          FROM stg_files sf;
    
        g_error := 'NEW FILE INSERTED IN STG_AREA by id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_FILES: ' || g_error);
        INSERT INTO stg_files
            (file_name, id_professional, file_upload_time, id_stg_files)
        VALUES
            (i_file_name, i_id_professional, current_timestamp, o_id_stg_files);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_FILES',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_files;

    /********************************************************************************************
    * Set Staging Area Professional
    *
    * @param i_lang                Prefered language ID
    * @param i_id_stg_professional Professional ID
    * @param i_title               Title
    * @param i_name                Full name
    * @param i_first_name          First name
    * @param i_middle_name         Middle name
    * @param i_last_name           Last name
    * @param i_short_name          Short name
    * @param i_initials            Initials
    * @param i_dt_birth            Date of birth
    * @param i_gender              Gender
    * @param i_marital_status      Marital status
    * @param i_num_order           License number
    * @param i_id_ext_prof_cat     External professional category id
    * @param i_specialty_desc      Description of the specialty
    * @param i_adress              Adress
    * @param i_city                City
    * @param i_district            District
    * @param i_zip_code            Zip Code
    * @param i_id_country          Country ID
    * @param i_work_phne           Work phone number
    * @param i_num_contact         Phone number
    * @param i_cell_phone          Cell phone number
    * @param i_fax                 Fax number
    * @param i_email               E-mail
    * @param i_id_stg_files        Staging Area file ID
    * @param i_id_institution      Institution ID
    * @param o_id_stg_professional Professional ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/21
    ********************************************************************************************/
    FUNCTION set_stg_professional
    (
        i_lang                IN language.id_language%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_title               IN stg_professional.title%TYPE,
        i_name                IN stg_professional.name%TYPE,
        i_first_name          IN stg_professional.first_name%TYPE,
        i_middle_name         IN stg_professional.middle_name%TYPE,
        i_last_name           IN stg_professional.last_name%TYPE,
        i_short_name          IN stg_professional.short_name%TYPE,
        i_initials            IN stg_professional.initials%TYPE,
        i_dt_birth            IN stg_professional.dt_birth%TYPE,
        i_gender              IN stg_professional.gender%TYPE,
        i_marital_status      IN stg_professional.marital_status%TYPE,
        i_num_order           IN stg_professional.num_order%TYPE,
        i_id_ext_prof_cat     IN stg_professional.id_ext_prof_cat%TYPE,
        i_specialty_desc      IN stg_professional.speciality_desc%TYPE,
        i_adress              IN stg_professional.address%TYPE,
        i_city                IN stg_professional.city%TYPE,
        i_district            IN stg_professional.district%TYPE,
        i_zip_code            IN stg_professional.zip_code%TYPE,
        i_id_country          IN stg_professional.id_country%TYPE,
        i_work_phne           IN stg_professional.work_phone%TYPE,
        i_num_contact         IN stg_professional.num_contact%TYPE,
        i_cell_phone          IN stg_professional.cell_phone%TYPE,
        i_fax                 IN stg_professional.fax%TYPE,
        i_email               IN stg_professional.email%TYPE,
        i_id_stg_files        IN stg_files.id_stg_files%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        o_id_stg_professional OUT stg_professional.id_stg_professional%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_stg_professional IS NULL
        THEN
        
            g_error := 'GET ID_STG_FILES TO INSERT';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_FILES: ' || g_error);
            SELECT decode(MAX(sp.id_stg_professional), NULL, 1, MAX(sp.id_stg_professional) + 1)
              INTO o_id_stg_professional
              FROM stg_professional sp;
        
            g_error := 'NEW EXTERNAL PROFESSIONAL INSERTED IN STG_AREA: ' || i_name;
            pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_PROFESSIONAL: ' || g_error);
            INSERT INTO stg_professional
                (id_stg_professional,
                 title,
                 name,
                 first_name,
                 middle_name,
                 last_name,
                 short_name,
                 initials,
                 dt_birth,
                 gender,
                 marital_status,
                 num_order,
                 id_ext_prof_cat,
                 speciality_desc,
                 address,
                 city,
                 district,
                 zip_code,
                 id_country,
                 work_phone,
                 num_contact,
                 cell_phone,
                 fax,
                 email,
                 id_stg_files,
                 id_institution)
            VALUES
                (o_id_stg_professional,
                 i_title,
                 i_name,
                 i_first_name,
                 i_middle_name,
                 i_last_name,
                 i_short_name,
                 i_initials,
                 i_dt_birth,
                 i_gender,
                 i_marital_status,
                 i_num_order,
                 i_id_ext_prof_cat,
                 i_specialty_desc,
                 i_adress,
                 i_city,
                 i_district,
                 i_zip_code,
                 i_id_country,
                 i_work_phne,
                 i_num_contact,
                 i_cell_phone,
                 i_fax,
                 i_email,
                 i_id_stg_files,
                 i_id_institution);
        
        ELSE
        
            o_id_stg_professional := i_id_stg_professional;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_PROFESSIONAL',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_professional;

    /********************************************************************************************
    * Set Staging Area Professionals Categories
    *
    * @param i_lang                Prefered language ID
    * @param i_id_stg_professional Professional ID
    * @param i_id_ext_prof_cat     External professional category id
    * @param i_id_stg_files        Staging Area file ID
    * @param i_id_institution      Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/22
    ********************************************************************************************/
    FUNCTION set_stg_prof_cat
    (
        i_lang                IN language.id_language%TYPE,
        i_id_stg_professional IN stg_prof_institution.id_stg_professional%TYPE,
        i_id_ext_prof_cat     IN stg_professional.id_ext_prof_cat%TYPE,
        i_id_stg_files        IN stg_files.id_stg_files%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'EXTERNAL PROFESSIONAL CATEGORY, id_stg_professional: ' || i_id_stg_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_PROF_CAT: ' || g_error);
        UPDATE stg_professional stgp
           SET stgp.id_ext_prof_cat = i_id_ext_prof_cat
         WHERE stgp.id_stg_professional = i_id_stg_professional
           AND stgp.id_stg_files = i_id_stg_files
           AND stgp.id_institution = i_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_PROF_CAT',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_prof_cat;

    /********************************************************************************************
    * Set Staging Area Intitution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_stg_institution  Staging area Institution ID
    * @param i_institution_name    Institution name
    * @param i_flg_type            Institution type
    * @param i_abbreviation        Abbreviation
    * @param i_adress              Adress
    * @param i_city                City
    * @param i_district            District
    * @param i_zip_code            Zip Code
    * @param i_id_country          Country ID
    * @param i_id_market           Market ID
    * @param i_phone_number        Phone number
    * @param i_fax                 Fax number
    * @param i_email               E-mail
    * @param i_id_stg_files        Staging Area file ID
    * @param i_id_institution      Institution ID
    * @param o_id_stg_institution  Staging area Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/21
    ********************************************************************************************/
    FUNCTION set_stg_institution
    (
        i_lang               IN language.id_language%TYPE,
        i_id_stg_institution IN stg_institution.id_stg_institution%TYPE,
        i_institution_name   IN stg_institution.institution_name%TYPE,
        i_flg_type           IN stg_institution.flg_type%TYPE,
        i_abbreviation       IN stg_institution.abbreviation%TYPE,
        i_adress             IN stg_institution.address%TYPE,
        i_city               IN stg_institution.city%TYPE,
        i_district           IN stg_institution.district%TYPE,
        i_zip_code           IN stg_institution.zip_code%TYPE,
        i_id_country         IN stg_institution.id_country%TYPE,
        i_id_market          IN stg_institution.id_market%TYPE,
        i_phone_number       IN stg_institution.phone_number%TYPE,
        i_fax                IN stg_institution.fax_number%TYPE,
        i_email              IN stg_institution.email%TYPE,
        i_id_stg_files       IN stg_files.id_stg_files%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        o_id_stg_institution OUT stg_institution.id_stg_institution%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_stg_institution IS NULL
        THEN
        
            g_error := 'GET ID_STG_FILES TO INSERT';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_FILES: ' || g_error);
            SELECT decode(MAX(si.id_stg_institution), NULL, 1, MAX(si.id_stg_institution) + 1)
              INTO o_id_stg_institution
              FROM stg_institution si;
        
            g_error := 'NEW EXTERNAL INSTITUTION INSERTED IN STG_AREA: ' || i_institution_name;
            pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_INSTITUTION: ' || g_error);
            INSERT INTO stg_institution
                (id_stg_institution,
                 institution_name,
                 flg_type,
                 abbreviation,
                 address,
                 city,
                 district,
                 zip_code,
                 id_country,
                 id_market,
                 phone_number,
                 fax_number,
                 email,
                 id_stg_files,
                 id_institution)
            VALUES
                (o_id_stg_institution,
                 i_institution_name,
                 i_flg_type,
                 i_abbreviation,
                 i_adress,
                 i_city,
                 i_district,
                 i_zip_code,
                 i_id_country,
                 i_id_market,
                 i_phone_number,
                 i_fax,
                 i_email,
                 i_id_stg_files,
                 i_id_institution);
        
        ELSE
        
            o_id_stg_institution := i_id_stg_institution;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_INSTITUTION',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_institution;

    /********************************************************************************************
    * Set Staging Area associations between Professionals and Intitution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_stg_professional Professional ID
    * @param i_id_stg_institution  Institution ID
    * @param i_flg_state           Status
    * @param i_dt_begin            Begin date
    * @param i_dt_end              End date
    * @param i_id_stg_files        Staging Area file ID
    * @param i_id_institution      Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/21
    ********************************************************************************************/
    FUNCTION set_stg_prof_institution
    (
        i_lang                IN language.id_language%TYPE,
        i_id_stg_professional IN stg_prof_institution.id_stg_professional%TYPE,
        i_id_stg_institution  IN stg_prof_institution.id_stg_institution%TYPE,
        i_flg_state           IN stg_prof_institution.flg_state%TYPE,
        i_dt_begin            IN stg_prof_institution.dt_begin_tstz%TYPE,
        i_dt_end              IN stg_prof_institution.dt_end_tstz%TYPE,
        i_id_stg_files        IN stg_files.id_stg_files%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'NEW EXTERNAL RELATION BETWEEN PROFESSIONAL AND INSTITUTION IN STG_AREA: id_stg_professional = ' ||
                   i_id_stg_professional || ', id_stg_institution = ' || i_id_stg_institution;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_PROF_INSTITUTION: ' || g_error);
        INSERT INTO stg_prof_institution
            (id_stg_professional,
             id_stg_institution,
             flg_state,
             dt_begin_tstz,
             dt_end_tstz,
             id_stg_files,
             id_institution)
        VALUES
            (i_id_stg_professional,
             i_id_stg_institution,
             i_flg_state,
             i_dt_begin,
             i_dt_end,
             i_id_stg_files,
             i_id_institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_PROF_INSTITUTION',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_prof_institution;

    /********************************************************************************************
    * Set Staging Area Professionals Fields data
    *
    * @param i_lang                Prefered language ID
    * @param i_id_stg_professional Professional ID
    * @param i_fields              Fields array
    * @param i_values              Fields values array
    * @param i_id_stg_files        Staging Area file ID
    * @param i_id_institution      Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/22
    ********************************************************************************************/
    FUNCTION set_stg_prof_fields_data
    (
        i_lang                IN language.id_language%TYPE,
        i_id_stg_professional IN stg_professional_field_data.id_stg_professional%TYPE,
        i_fields              IN table_number,
        i_values              IN table_varchar,
        i_id_stg_files        IN stg_files.id_stg_files%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'EXTERNAL PROFESSIONAL FIELDS VALUES IN STG_AREA: id_stg_professional = ' || i_id_stg_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_PROF_FIELDS_DATA: ' || g_error);
        FOR i IN 1 .. i_fields.count
        LOOP
        
            INSERT INTO stg_professional_field_data
                (id_stg_professional, id_field, VALUE, id_stg_files, id_institution)
            VALUES
                (i_id_stg_professional, i_fields(i), i_values(i), i_id_stg_files, i_id_institution);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_PROF_FIELDS_DATA',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_prof_fields_data;

    /********************************************************************************************
    * Set Staging Area Institution Fields data
    *
    * @param i_lang                Prefered language ID
    * @param i_id_stg_professional Professional ID
    * @param i_fields              Fields array
    * @param i_values              Fields values array
    * @param i_id_stg_files        Staging Area file ID
    * @param i_id_institution      Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/06/22
    ********************************************************************************************/
    FUNCTION set_stg_instit_fields_data
    (
        i_lang               IN language.id_language%TYPE,
        i_id_stg_institution IN stg_institution_field_data.id_stg_institution%TYPE,
        i_fields             IN table_number,
        i_values             IN table_varchar,
        i_id_stg_files       IN stg_files.id_stg_files%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'EXTERNAL INSTITUTION FIELDS VALUES IN STG_AREA: id_stg_institution = ' || i_id_stg_institution;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_STG_INSTIT_FIELDS_DATA: ' || g_error);
        FOR i IN 1 .. i_fields.count
        LOOP
        
            INSERT INTO stg_institution_field_data
                (id_stg_institution, id_field, VALUE, id_stg_files, id_institution)
            VALUES
                (i_id_stg_institution, i_fields(i), i_values(i), i_id_stg_files, i_id_institution);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_STG_INSTIT_FIELDS_DATA',
                                              o_error);
            RETURN FALSE;
        
    END set_stg_instit_fields_data;

    /********************************************************************************************
    * Set Professional fields values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_id_market        Market ID
    * @param i_institution      Institution ID's
    * @param i_fields           Fields ID's
    * @param i_values           Fields Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   JTS
    * @version                  2.6.0.3
    * @since                    2010/06/30
    ********************************************************************************************/
    FUNCTION intf_set_prof_fields
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_market       IN market.id_market%TYPE,
        i_institution     IN table_number,
        i_fields          IN table_number,
        i_values          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_field_market field_market.id_field_market%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF i_id_market IS NULL
           OR i_id_market = 0
        THEN
        
            RAISE l_exception;
        
        ELSE
        
            g_error := 'CREATE PROFESIONAL FIELDS: id_professional = ' || i_id_professional;
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_FIELDS: ' || g_error);
        
            FOR i IN 1 .. i_institution.count
            LOOP
            
                SELECT nvl((SELECT fm.id_field_market
                             FROM field_market fm
                            WHERE fm.id_field = i_fields(i)
                              AND fm.id_market = i_id_market),
                           0)
                  INTO l_field_market
                  FROM dual;
            
                IF l_field_market = 0
                THEN
                    RAISE l_exception;
                ELSE
                
                    g_error := 'MERGE INTO PROF_FIELD_DATA';
                    MERGE INTO professional_field_data pfd
                    USING (SELECT i_institution(i) inst, l_field_market field, i_values(i) val
                             FROM dual) t
                    ON (pfd.id_professional = i_id_professional AND pfd.id_field_market = t.field AND pfd.id_institution = t.inst)
                    WHEN MATCHED THEN
                        UPDATE
                           SET pfd.value = t.val
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_professional, id_field_market, VALUE, id_institution)
                        VALUES
                            (i_id_professional, t.field, t.val, t.inst);
                
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / MARKET NO DEFINED OR FIELD NOT DEFINED FOR THE MARKET',
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_prof_fields;

    /********************************************************************************************
    * Set Professional fields values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_id_institution   Professional institution ID
    * @param i_institution      Institution ID's
    * @param i_fields           Fields ID's
    * @param i_values           Fields Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   JTS
    * @version                  2.6.0.3
    * @since                    2010/06/30
    ********************************************************************************************/
    FUNCTION intf_set_prof_fields
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_institution     IN table_number,
        i_fields          IN table_number,
        i_values          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market market.id_market%TYPE;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_market
          FROM dual;
    
        RETURN intf_set_prof_fields(i_lang            => i_lang,
                                    i_id_professional => i_id_professional,
                                    i_id_market       => l_market,
                                    i_institution     => i_institution,
                                    i_fields          => i_fields,
                                    i_values          => i_values,
                                    o_error           => o_error);
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / MARKET NO DEFINED OR FIELD NOT DEFINED FOR THE MARKET',
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END intf_set_prof_fields;

    /********************************************************************************************
    * Set Professional fields values
    *
    * @param i_lang             Preferred language ID
    
    * @param i_id_institution   Institution ID
    * @param i_fields           Fields ID's
    * @param i_values           Fields Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   JTS
    * @version                  2.6.0.3
    * @since                    2010/06/30
    ********************************************************************************************/
    FUNCTION intf_set_inst_fields
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_fields         IN table_number,
        i_values         IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market       market.id_market%TYPE;
        l_field_market field_market.id_field_market%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_market
          FROM dual;
    
        IF l_market = 0
        THEN
        
            RAISE l_exception;
        
        ELSE
        
            g_error := 'CREATE INSTITUTION FIELDS: i_id_institution = ' || i_id_institution;
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_INST_FIELDS: ' || g_error);
        
            FOR i IN 1 .. i_fields.count
            LOOP
            
                SELECT nvl((SELECT fm.id_field_market
                             FROM field_market fm
                            WHERE fm.id_field = i_fields(i)
                              AND fm.id_market = l_market),
                           0)
                  INTO l_field_market
                  FROM dual;
            
                IF l_field_market = 0
                THEN
                    RAISE l_exception;
                ELSE
                
                    g_error := 'MERGE INTO PROF_FIELD_DATA';
                    MERGE INTO institution_field_data ifd
                    USING (SELECT l_field_market field, i_values(i) val
                             FROM dual) t
                    ON (ifd.id_institution = i_id_institution AND ifd.id_field_market = t.field)
                    WHEN MATCHED THEN
                        UPDATE
                           SET ifd.value = t.val
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_institution, id_field_market, VALUE)
                        VALUES
                            (i_id_institution, t.field, t.val);
                
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_INST_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_inst_fields;

    /********************************************************************************************
    * Update/insert information anf fields values for an external professional for one or more instituitions
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_title                 Professional Title
    * @param i_first_name            Professional first name
    * @param i_middle_name           Professional middle name
    * @param i_last_name             Professional last name
    * @param i_nickname              Professional Nickname
    * @param i_initials              Professional initials
    * @param i_dt_birth              Professional Date of Birth
    * @param i_gender                Professioanl gender
    * @param i_marital_status        Professional marital status
    * @param i_id_speciality         Professional specialty
    * @param i_num_order             Professional license number
    * @param i_address               Professional adress
    * @param i_city                  Professional city
    * @param i_district              Professional district
    * @param i_zip_code              Professional zip code
    * @param i_id_country            Professional cpuntry
    * @param i_phone                 Professional phone
    * @param i_mobile_phone          Professional mobile phone
    * @param i_fax                   Professional fax
    * @param i_email                 Professional email
    * @param i_institution           List of institutions where the Professional is external
    * @param i_fields_institution    Fields Institution ID's
    * @param i_fields                Fields ID's
    * @param i_values                Fields Values
    * @param o_professional          Professional ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     2.6.0.3
    * @since                       2010/06/30
    ********************************************************************************************/
    FUNCTION intf_set_ext_prof
    (
        i_lang               IN language.id_language%TYPE,
        i_id_prof            IN professional.id_professional%TYPE,
        i_title              IN professional.title%TYPE,
        i_first_name         IN professional.first_name%TYPE,
        i_middle_name        IN professional.middle_name%TYPE,
        i_last_name          IN professional.last_name%TYPE,
        i_nickname           IN professional.nick_name%TYPE,
        i_initials           IN professional.initials%TYPE,
        i_dt_birth           IN professional.dt_birth%TYPE,
        i_gender             IN professional.gender%TYPE,
        i_marital_status     IN professional.marital_status%TYPE,
        i_id_speciality      IN professional.id_speciality%TYPE,
        i_num_order          IN professional.num_order%TYPE,
        i_address            IN professional.address%TYPE,
        i_city               IN professional.city%TYPE,
        i_district           IN professional.district%TYPE,
        i_zip_code           IN professional.zip_code%TYPE,
        i_id_country         IN professional.id_country%TYPE,
        i_phone              IN professional.work_phone%TYPE,
        i_num_contact        IN professional.num_contact%TYPE,
        i_mobile_phone       IN professional.cell_phone%TYPE,
        i_fax                IN professional.fax%TYPE,
        i_email              IN professional.email%TYPE,
        i_institution        IN table_number,
        i_fields_institution IN table_number,
        i_fields             IN table_number,
        i_values             IN table_varchar,
        o_professional       OUT professional.id_professional%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
        -- l_id_professional professional.id_professional%TYPE := NULL;
    
    BEGIN
    
        FOR i IN 1 .. i_institution.count
        LOOP
        
            g_error := 'CREATE PROFESIONAL ACCOUNTS: id_professional = ' || i_id_prof;
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
            IF NOT pk_api_backoffice.intf_set_ext_profissional(i_lang,
                                                               i_id_prof,
                                                               i_title,
                                                               i_first_name,
                                                               i_middle_name,
                                                               i_last_name,
                                                               i_nickname,
                                                               i_initials,
                                                               i_dt_birth,
                                                               i_gender,
                                                               i_marital_status,
                                                               i_id_speciality,
                                                               i_num_order,
                                                               i_address,
                                                               i_city,
                                                               i_district,
                                                               i_zip_code,
                                                               i_id_country,
                                                               i_phone,
                                                               i_num_contact,
                                                               i_mobile_phone,
                                                               i_fax,
                                                               i_email,
                                                               i_institution(i),
                                                               o_professional,
                                                               l_error_out)
            
            THEN
                RAISE l_exception;
            
            END IF;
        
            IF NOT pk_api_backoffice.intf_set_prof_fields(i_lang            => i_lang,
                                                          i_id_professional => o_professional,
                                                          i_id_institution  => i_institution(i),
                                                          i_institution     => i_fields_institution,
                                                          i_fields          => i_fields,
                                                          i_values          => i_values,
                                                          o_error           => l_error_out)
            
            THEN
                RAISE l_exception;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_ext_prof;

    /********************************************************************************************
    * Find a professional based on field values
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_fields                Fields ID's
    * @param i_fields_val            Field values
    * @param o_professional          Professional ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     2.6.0.3
    * @since                       2010/07/01
    ********************************************************************************************/
    FUNCTION intf_get_ext_prof_id
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_fields         IN table_number,
        i_fields_val     IN table_varchar,
        o_professional   OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_profissional NUMBER;
    
        l_market       market.id_market%TYPE;
        l_field_market field_market.id_field_market%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        o_professional := NULL;
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_market
          FROM dual;
    
        IF l_market = 0
        THEN
        
            RAISE l_exception;
        
        ELSE
        
            FOR i IN 1 .. i_fields.count
            LOOP
            
                SELECT nvl((SELECT fm.id_field_market
                             FROM field_market fm
                            WHERE fm.id_field = i_fields(i)
                              AND fm.id_market = l_market),
                           0)
                  INTO l_field_market
                  FROM dual;
            
                IF l_field_market = 0
                THEN
                    RAISE l_exception;
                ELSE
                
                    g_error := 'SELECT PROFESSIONAL BY FIELD VALUE: ' || to_char(i_fields(i)) || ' -> ' ||
                               i_fields_val(i);
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_EXT_PROF_ID: ' || g_error);
                    SELECT nvl((SELECT pfd.id_professional
                                 FROM professional_field_data pfd
                                WHERE pfd.id_field_market = l_field_market
                                  AND pfd.value = i_fields_val(i)
                                  AND pfd.id_institution = 0
                                  AND rownum = 1),
                               NULL)
                      INTO l_id_profissional
                      FROM dual;
                
                    IF o_professional IS NOT NULL
                       AND l_id_profissional IS NOT NULL
                    THEN
                    
                        IF o_professional != l_id_profissional
                        THEN
                            o_professional := NULL;
                            EXIT;
                        END IF;
                    
                    ELSIF o_professional IS NULL
                          AND l_id_profissional IS NOT NULL
                    THEN
                    
                        o_professional := l_id_profissional;
                    
                    END IF;
                
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_EXT_PROF_ID',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_get_ext_prof_id;

    /********************************************************************************************
    * Find an Institution based on field values
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_fields                Fields ID's
    * @param i_fields_val            Field values
    * @param o_institution           Institution ID
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     2.6.0.3
    * @since                       2010/07/01
    ********************************************************************************************/
    FUNCTION intf_get_ext_inst_id
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_fields         IN table_number,
        i_fields_val     IN table_varchar,
        o_institution    OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_institution NUMBER;
    
        l_market       market.id_market%TYPE;
        l_field_market field_market.id_field_market%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        o_institution := NULL;
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_market
          FROM dual;
    
        IF l_market = 0
        THEN
        
            RAISE l_exception;
        
        ELSE
        
            FOR i IN 1 .. i_fields.count
            LOOP
            
                SELECT nvl((SELECT fm.id_field_market
                             FROM field_market fm
                            WHERE fm.id_field = i_fields(i)
                              AND fm.id_market = l_market),
                           0)
                  INTO l_field_market
                  FROM dual;
            
                IF l_field_market = 0
                THEN
                    RAISE l_exception;
                ELSE
                
                    g_error := 'SELECT PROFESSIONAL BY FIELD VALUE: ' || to_char(i_fields(i)) || ' -> ' ||
                               i_fields_val(i);
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_EXT_PROF_ID: ' || g_error);
                    SELECT nvl((SELECT ifd.id_institution
                                 FROM institution_field_data ifd
                                WHERE ifd.id_field_market = l_field_market
                                  AND ifd.value = i_fields_val(i)
                                  AND rownum = 1),
                               NULL)
                      INTO l_id_institution
                      FROM dual;
                
                    IF o_institution IS NOT NULL
                       AND l_id_institution IS NOT NULL
                    THEN
                    
                        IF o_institution != l_id_institution
                        THEN
                            o_institution := NULL;
                            EXIT;
                        END IF;
                    
                    ELSIF o_institution IS NULL
                          AND l_id_institution IS NOT NULL
                    THEN
                    
                        o_institution := l_id_institution;
                    
                    END IF;
                
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_EXT_INST_ID',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_get_ext_inst_id;

    /********************************************************************************************
    * Find external professionals (Scheduler)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param i_licence_number      Professional license number
    * @param i_gender              Professional gender
    * @param i_name                Professional name
    * @param i_dt_birth            Date of birth
    * @param i_street              Street
    * @param i_house_number        House number
    * @param i_postal_code         Postal code
    * @param i_city                City
    * @param i_phone_number        Phone number
    * @param i_email               E-mail
    * @param i_flg_external        External Professionals (Y - Yes, N - No)
    * @param o_professionals       Professionals list
    * @param o_error               error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      T?rcio Soares
    * @version                     2.6.0.3.2
    * @since                       2010/08/31
    ********************************************************************************************/
    FUNCTION intf_get_sch_ext_prof
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_licence_number  IN professional.num_order%TYPE,
        i_gender          IN professional.gender%TYPE,
        i_name            IN professional.name%TYPE,
        i_dt_birth        IN professional.dt_birth%TYPE,
        i_street          IN professional.address%TYPE,
        i_house_number    IN VARCHAR2,
        i_postal_code     IN professional.zip_code%TYPE,
        i_city            IN professional.city%TYPE,
        i_phone_number    IN professional.num_contact%TYPE,
        i_email           IN professional.email%TYPE,
        i_flg_external    IN prof_institution.flg_external%TYPE,
        o_professionals   OUT t_table_sch_prof,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF i_id_professional IS NOT NULL
        THEN
        
            IF l_id_market = 5
            THEN
            
                g_error := 'GET EXTERNAL PROFESSIONAL INFORMATION, ID_PROFESSIONAL = ' || to_char(i_id_professional);
                pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
                SELECT t_rec_sch_prof(id_professional,
                                      name,
                                      professional_type,
                                      license_number,
                                      postal_code,
                                      city,
                                      gender,
                                      dt_birth,
                                      address,
                                      house_number,
                                      phone_number,
                                      email,
                                      flg_state)
                  BULK COLLECT
                  INTO o_professionals
                  FROM (SELECT p.id_professional,
                               p.name,
                               pk_backoffice_ext_prof.get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) professional_type,
                               pk_backoffice_ext_prof.get_ext_prof_license_number(i_lang,
                                                                                  p.id_professional,
                                                                                  NULL,
                                                                                  l_id_market) license_number,
                               p.zip_code postal_code,
                               p.city,
                               p.gender,
                               p.dt_birth,
                               p.address,
                               nvl((SELECT pfd.value
                                     FROM professional_field_data pfd
                                     JOIN field_market fm
                                       ON pfd.id_field_market = fm.id_field_market
                                    WHERE pfd.id_professional = p.id_professional
                                      AND fm.id_field = 21
                                      AND fm.id_market = l_id_market
                                      AND pfd.id_institution = 0
                                      AND rownum = 1),
                                   NULL) house_number,
                               p.num_contact phone_number,
                               p.email,
                               pi.flg_state
                          FROM professional p, prof_institution pi
                         WHERE p.id_professional = i_id_professional
                           AND pi.id_professional = p.id_professional
                           AND pi.id_institution = i_id_institution
                           AND pi.dt_end_tstz IS NULL);
            
            END IF;
        ELSE
        
            IF l_id_market = 5
            THEN
            
                g_error := 'GET EXTERNAL PROFESSIONALS LIST OF ID_INSTITUTION = ' || to_char(i_id_institution);
                pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
                SELECT t_rec_sch_prof(id_professional,
                                      name,
                                      professional_type,
                                      license_number,
                                      postal_code,
                                      city,
                                      gender,
                                      dt_birth,
                                      address,
                                      house_number,
                                      phone_number,
                                      email,
                                      flg_state)
                  BULK COLLECT
                  INTO o_professionals
                  FROM (SELECT p.id_professional,
                                p.name,
                                pk_backoffice_ext_prof.get_ext_prof_category(i_lang, p.id_professional, NULL, l_id_market) professional_type,
                                pk_backoffice_ext_prof.get_ext_prof_license_number(i_lang,
                                                                                   p.id_professional,
                                                                                   NULL,
                                                                                   l_id_market) license_number,
                                p.zip_code postal_code,
                                p.city,
                                p.gender,
                                p.dt_birth,
                                p.address,
                                nvl((SELECT pfd.value
                                      FROM professional_field_data pfd
                                      JOIN field_market fm
                                        ON pfd.id_field_market = fm.id_field_market
                                     WHERE pfd.id_professional = p.id_professional
                                       AND fm.id_field = 21
                                       AND fm.id_market = l_id_market
                                       AND pfd.id_institution = 0
                                       AND rownum = 1),
                                    NULL) house_number,
                                p.num_contact phone_number,
                                p.email,
                                pi.flg_state
                           FROM professional p, prof_institution pi
                          WHERE
                         --flg_external
                          pi.flg_external = i_flg_external
                       AND pi.dt_end_tstz IS NULL
                         --institution
                       AND pi.id_institution = i_id_institution
                       AND pi.id_professional = p.id_professional
                       AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                         --gender
                       AND (p.gender = i_gender OR i_gender IS NULL)
                         --dt_birth
                       AND (p.dt_birth = i_dt_birth OR i_dt_birth IS NULL)
                         --name
                       AND (i_name IS NULL OR
                          (translate(upper(p.name), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' || translate(upper(i_name), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --license_number
                       AND (i_licence_number IS NULL OR
                          (translate(upper(pk_backoffice_ext_prof.get_ext_prof_license_number(i_lang,
                                                                                               p.id_professional,
                                                                                               NULL,
                                                                                               l_id_market)),
                                      ' ???????????????????????? ',
                                      ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' || translate(upper(i_licence_number),
                                              ' ???????????????????????? ',
                                              ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --city
                       AND (i_city IS NULL OR
                          (translate(upper(p.city), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' || translate(upper(i_city), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --street
                       AND (i_street IS NULL OR
                          (translate(upper(p.address), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' ||
                          translate(upper(i_street), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --house_number
                       AND (i_house_number IS NULL OR
                          (translate(upper(nvl((SELECT pfd.value
                                                  FROM professional_field_data pfd
                                                  JOIN field_market fm
                                                    ON pfd.id_field_market = fm.id_field_market
                                                 WHERE pfd.id_professional = p.id_professional
                                                   AND fm.id_field = 21
                                                   AND fm.id_market = l_id_market
                                                   AND pfd.id_institution = 0
                                                   AND rownum = 1),
                                                NULL)),
                                      ' ???????????????????????? ',
                                      ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' ||
                          translate(upper(i_house_number), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --phone_number
                       AND (i_phone_number IS NULL OR
                          (translate(upper(p.num_contact), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' ||
                          translate(upper(i_phone_number), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --postal_code
                       AND (i_postal_code IS NULL OR
                          (translate(upper(p.zip_code), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' ||
                          translate(upper(i_postal_code), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%')))
                         --e_mail
                       AND (i_email IS NULL OR
                          (translate(upper(p.email), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun ') LIKE
                          ('%' ||
                          translate(upper(i_email), ' ???????????????????????? ', ' aeiouaeiouaeiouaocaeioun% ') || '%'))));
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_SCH_EXT_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_get_sch_ext_prof;

    /********************************************************************************************
    * Set Institution Professional Preferences
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_id_language           Language ID
    * @param o_id_professional       Professional ID
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3.4
    * @since                       2010/10/15
    ********************************************************************************************/
    FUNCTION intf_set_prof_preferences
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_language     IN prof_preferences.id_language%TYPE,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100) := 'INTF_SET_PROF_PREFERENCES';
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE PROFESIONAL PREFERENCES: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_PREFERENCES: ' || g_error);
        IF NOT pk_backoffice.set_prof_preferences(i_lang            => i_lang,
                                                  i_id_professional => i_id_professional,
                                                  i_id_institution  => i_id_institution,
                                                  i_id_language     => i_id_language,
                                                  i_commit_at_end   => FALSE,
                                                  o_id_professional => o_id_professional,
                                                  o_error           => l_error_out)
        
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_preferences;

    /********************************************************************************************
    * Set Professional affiliations values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_id_institution   Institution ID
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   T?rcio Soares
    * @version                  2.6.0.3.4
    * @since                    2010/10/15
    ********************************************************************************************/
    FUNCTION intf_set_prof_accounts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_accounts        IN table_number,
        i_values          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100) := 'INTF_SET_PROF_ACCOUNTS';
    
        l_institution     table_number := table_number();
        l_index           NUMBER := 1;
        l_flg_institution accounts_category.flg_institution%TYPE;
        l_id_category     accounts_category.id_category%TYPE := 0;
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'GET PROFESIONAL CATEGORY: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
        SELECT nvl((SELECT prc.id_category
                     FROM prof_cat prc
                    WHERE prc.id_professional = i_id_professional
                      AND prc.id_institution = i_id_institution),
                   g_acc_cat_none)
          INTO l_id_category
          FROM dual;
    
        FOR i IN 1 .. i_accounts.count
        LOOP
        
            IF l_id_category != g_acc_cat_none
            THEN
            
                g_error := 'GET ACCOUNT TYPE';
                pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
                SELECT nvl((SELECT ac.flg_institution
                             FROM accounts_category ac
                            WHERE ac.id_account = i_accounts(i)
                              AND ac.id_category = l_id_category),
                           g_acc_cat_flg_inst_no)
                  INTO l_flg_institution
                  FROM dual;
            
                IF l_flg_institution = g_acc_cat_flg_inst_yes
                THEN
                    g_error := 'ACCOUNT VALUE VALID ONLY FOR INSTITUTION: id_institution = ' || i_id_institution;
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
                    l_institution.extend;
                    l_institution(l_index) := i_id_institution;
                
                ELSE
                    g_error := 'ACCOUNT VALUE VALID FOR ALL INSTITUTIONS';
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
                    l_institution.extend;
                    l_institution(l_index) := g_acc_inst_all;
                
                END IF;
            
            ELSE
                g_error := 'ACCOUNT VALUE VALID FOR ALL INSTITUTIONS';
                pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
                l_institution.extend;
                l_institution(l_index) := g_acc_inst_all;
            
            END IF;
        
            l_index := l_index + 1;
        
        END LOOP;
    
        g_error := 'CREATE PROFESIONAL ACCOUNTS: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_ACCOUNTS: ' || g_error);
        IF NOT pk_backoffice.set_prof_affiliations(i_lang            => i_lang,
                                                   i_id_professional => i_id_professional,
                                                   i_institution     => l_institution,
                                                   i_accounts        => i_accounts,
                                                   i_values          => i_values,
                                                   o_error           => l_error_out)
        
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_set_prof_accounts;

    /********************************************************************************************
    * Set Professional institution relations (internal or external)
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_institutions          Institution ID's
    * @param i_flg_state             Professional status in institutions
    * @param i_num_mecan             Mecan. Number's
    * @param i_dt_begin_tstz         Begin dates
    * @param i_dt_end_tstz           End dates
    * @param i_flg_external          External relation? Y - External, N- interal
    * @param o_prof_institutions     Professional/institution relation id's
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3.4
    * @since                       2010/11/22
    ********************************************************************************************/
    FUNCTION intf_set_prof_institutions
    (
        i_lang              IN language.id_language%TYPE,
        i_id_professional   IN prof_institution.id_professional%TYPE,
        i_institutions      IN table_number,
        i_flg_state         IN table_varchar,
        i_num_mecan         IN table_varchar,
        i_dt_begin_tstz     IN table_timestamp,
        i_dt_end_tstz       IN table_timestamp,
        i_flg_external      IN prof_institution.flg_external%TYPE,
        o_prof_institutions OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100) := 'INTF_SET_PROF_INSTITUTIONS';
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'ASSOCIATE PROFESIONAL TO INSTITUTIONS: id_professional = ' || i_id_professional;
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_PROF_INSTITUTIONS: ' || g_error);
        IF NOT pk_backoffice.set_prof_institutions(i_lang              => i_lang,
                                                   i_id_professional   => i_id_professional,
                                                   i_institutions      => i_institutions,
                                                   i_flg_state         => i_flg_state,
                                                   i_num_mecan         => i_num_mecan,
                                                   i_dt_begin_tstz     => i_dt_begin_tstz,
                                                   i_dt_end_tstz       => i_dt_end_tstz,
                                                   i_flg_external      => i_flg_external,
                                                   i_commit_at_end     => FALSE,
                                                   o_prof_institutions => o_prof_institutions,
                                                   o_error             => l_error_out)
        THEN
            RAISE l_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_prof_institutions;
    /********************************************************************************************
    * Get Institution Tax Identification Number
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution Identifier
    * @param o_error                 error
    *
    * @return                        TIN Nr on success or 0 when false
    *
    * @author                        MESS
    * @version                       2.6.1
    * @since                         2011/01/24
    ********************************************************************************************/
    FUNCTION get_instit_tin_number
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        l_instit_account_tin inst_attributes.social_security_number%TYPE;
    
    BEGIN
    
        g_error := 'GET INSTITUTION TAX IDENTIFICATION NUMBER';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_INSTIT_TIN_NUMBER: ' || g_error);
        SELECT nvl((SELECT ia.social_security_number
                     FROM inst_attributes ia
                    WHERE ia.id_institution = i_id_institution
                      AND rownum = 1),
                   0)
          INTO l_instit_account_tin
          FROM dual;
    
        RETURN l_instit_account_tin;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_INSTIT_TIN_NUMBER',
                                              o_error);
            RETURN 0;
        
    END get_instit_tin_number;
    /********************************************************************************************
    * Get Professional Report Disclosure - Y/N
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional Array Identifier
    * @param i_id_report             Report Identifier
    * @param i_screen_name           Screen Name
    * @param o_error                 error
    *
    * @return                        Is the Report Disclosure? - Y/N
    *
    * @author                        Mauro Sousa
    * @version                       2.6.1
    * @since                         2011/02/10
    ********************************************************************************************/
    FUNCTION get_prof_rep_disclosure
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_report       IN rep_profile_template_det.id_reports%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_flg_area_report IN rep_profile_template_det.flg_area_report%TYPE
    ) RETURN VARCHAR2 IS
    
        l_disclosure rep_profile_template_det.flg_disclosure%TYPE;
        l_error      t_error_out;
    BEGIN
    
        g_error := 'GET PROFESSIONAL REPORT DISCLOSURE';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_REP_DISCLOSURE: ' || g_error);
        SELECT nvl(rptd.flg_disclosure, g_no)
          INTO l_disclosure
          FROM prof_profile_template ppt
          JOIN rep_prof_templ_access rpta
            ON rpta.id_profile_template = ppt.id_profile_template
          JOIN rep_profile_template_det rptd
            ON rptd.id_rep_profile_template = rpta.id_rep_profile_template
           AND rptd.id_reports = i_id_report
           AND rptd.flg_area_report = i_flg_area_report
          JOIN rep_screen rs
            ON rs.id_rep_screen = rptd.id_rep_screen
           AND rs.screen_name = i_screen_name
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software
        UNION ALL
        SELECT nvl(rptd.flg_disclosure, g_no)
          FROM prof_profile_template ppt
          JOIN rep_prof_templ_access rpta
            ON rpta.id_profile_template = ppt.id_profile_template
          JOIN rep_profile_template_det rptd
            ON rptd.id_rep_profile_template = rpta.id_rep_profile_template
           AND rptd.id_rep_screen IS NULL
           AND rptd.flg_area_report = i_flg_area_report
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software;
    
        RETURN l_disclosure;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_REP_DISCLOSURE',
                                              l_error);
            RETURN NULL;
        
    END get_prof_rep_disclosure;
    /********************************************************************************************
    * Count How many Professional Report Disclosure = Y
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional Array Identifier
    * @param i_screen_name           Screen Name
    * @param o_error                 error
    *
    * @return                        Number of Reports Disclosure - Y
    *
    * @author                        Mauro Sousa
    * @version                       2.6.1
    * @since                         2011/02/10
    ********************************************************************************************/
    FUNCTION get_prof_has_rep_disclosure
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_flg_area_report IN rep_profile_template_det.flg_area_report%TYPE
    ) RETURN table_number IS
    
        l_error      t_error_out;
        l_id_reports rep_profile_template_det.id_reports%TYPE;
        l_index      NUMBER := 1;
        o_id_reports table_number := table_number();
        l_count      NUMBER;
    
        CURSOR c_reports(c_id_institution institution.id_institution%TYPE) IS
            SELECT rptd.id_reports
              FROM prof_profile_template ppt
              JOIN rep_prof_templ_access rpta
                ON rpta.id_profile_template = ppt.id_profile_template
              JOIN rep_profile_template_det rptd
                ON rptd.id_rep_profile_template = rpta.id_rep_profile_template
               AND rptd.flg_disclosure = g_flg_available
               AND rptd.flg_area_report = i_flg_area_report
              JOIN rep_screen rs
                ON rs.id_rep_screen = rptd.id_rep_screen
               AND rs.screen_name = i_screen_name
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
            UNION ALL
            SELECT rptd.id_reports
              FROM prof_profile_template ppt
              JOIN rep_prof_templ_access rpta
                ON rpta.id_profile_template = ppt.id_profile_template
              JOIN rep_profile_template_det rptd
                ON rptd.id_rep_profile_template = rpta.id_rep_profile_template
               AND rptd.flg_disclosure = g_flg_available
               AND rptd.id_rep_screen IS NULL
               AND rptd.flg_area_report = i_flg_area_report
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software;
    
        CURSOR c_count_reports IS
            SELECT (SELECT COUNT(rptd.id_reports)
                      FROM prof_profile_template ppt
                      JOIN rep_prof_templ_access rpta
                        ON rpta.id_profile_template = ppt.id_profile_template
                      JOIN rep_profile_template_det rptd
                        ON rptd.id_rep_profile_template = rpta.id_rep_profile_template
                       AND rptd.flg_disclosure = g_flg_available
                       AND rptd.flg_area_report = i_flg_area_report
                      JOIN rep_screen rs
                        ON rs.id_rep_screen = rptd.id_rep_screen
                       AND rs.screen_name IS NULL
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software) +
                   (SELECT COUNT(rptd.id_reports)
                      FROM prof_profile_template ppt
                      JOIN rep_prof_templ_access rpta
                        ON rpta.id_profile_template = ppt.id_profile_template
                      JOIN rep_profile_template_det rptd
                        ON rptd.id_rep_profile_template = rpta.id_rep_profile_template
                       AND rptd.flg_disclosure = g_flg_available
                       AND rptd.id_rep_screen IS NULL
                       AND rptd.flg_area_report = i_flg_area_report
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software)
              FROM dual;
    
    BEGIN
    
        g_error := 'OPEN C_COUNT_REPORTS CURSOR';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
        OPEN c_count_reports;
        LOOP
            g_error := 'FETCH C_COUNT_REPORTS CURSOR';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
            FETCH c_count_reports
                INTO l_count;
            EXIT WHEN c_count_reports%NOTFOUND;
        
            IF l_count > 0
            THEN
                g_error := 'OPEN C_REPORTS CURSOR';
                pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
                OPEN c_reports(i_prof.institution);
                LOOP
                    g_error := 'FETCH C_REPORTS CURSOR';
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
                
                    FETCH c_reports
                        INTO l_id_reports;
                    EXIT WHEN c_reports%NOTFOUND;
                
                    o_id_reports.extend;
                    o_id_reports(l_index) := l_id_reports;
                    l_index := l_index + 1;
                
                END LOOP;
            
                g_error := 'CLOSE C_REPORTS CURSOR';
                pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
                CLOSE c_reports;
            
            ELSE
                g_error := 'OPEN C_REPORTS CURSOR';
                pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
                OPEN c_reports(0);
                LOOP
                    g_error := 'FETCH C_REPORTS CURSOR';
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
                
                    FETCH c_reports
                        INTO l_id_reports;
                    EXIT WHEN c_reports%NOTFOUND;
                
                    o_id_reports.extend;
                    o_id_reports(l_index) := l_id_reports;
                    l_index := l_index + 1;
                
                END LOOP;
            
                g_error := 'CLOSE C_REPORTS CURSOR';
                pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
                CLOSE c_reports;
            
            END IF;
        
        END LOOP;
    
        g_error := 'CLOSE C_COUNT_REPORTS CURSOR';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE: ' || g_error);
        CLOSE c_count_reports;
    
        RETURN o_id_reports;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_HAS_REP_DISCLOSURE',
                                              l_error);
            RETURN NULL;
        
    END get_prof_has_rep_disclosure;

    /********************************************************************************************
    * Get sis pre natal series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  Series List
    * @param o_msg                   Message of % available
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_pre_natal_series_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_msg   OUT sys_message.desc_message%TYPE,
        o_mask  OUT sys_config.value%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_backoffice.get_pre_natal_series_list(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       o_list  => o_list,
                                                       o_msg   => o_msg,
                                                       o_mask  => o_mask,
                                                       o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PRE_NATAL_SERIES_LIST',
                                              o_error);
            RETURN FALSE;
    END get_pre_natal_series_list;

    /********************************************************************************************
    * Get sis pre natal active serie
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_pre_natal_serie
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_rec_serie IS
        l_rec_serie t_rec_serie;
    BEGIN
    
        l_rec_serie := pk_backoffice.get_pre_natal_serie(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
        RETURN l_rec_serie;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PRE_NATAL_SERIE',
                                              o_error);
            RETURN NULL;
    END get_pre_natal_serie;

    /********************************************************************************************
    * Get sis pre natal active serie
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  Series List
    * @param o_msg                   Message of % available
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_pre_natal_serie
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT
            pk_backoffice.get_pre_natal_serie(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PRE_NATAL_SERIE',
                                              o_error);
            RETURN FALSE;
    END get_pre_natal_serie;

    /********************************************************************************************
    * Checks if a number is contained inside one of the institution series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_current_number        Series number that will be assessed
    * @param i_code_state            State code
    * @param i_geo_state             State ID
    *
    * @return                        this sisprenatal code is contained in the serie? (Y)es or (N)o
    *
    * @author                        Jos? Silva
    * @version                       2.5.1.9
    * @since                         2011/11/17
    ********************************************************************************************/
    FUNCTION check_inst_serie_number
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_current_number IN series.current_number%TYPE,
        i_code_state     IN geo_state.code_state%TYPE,
        i_geo_state      IN geo_state.id_geo_state%TYPE,
        i_code_year      IN series.series_year%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_backoffice.check_inst_serie_number(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_current_number => i_current_number,
                                                     i_code_state     => i_code_state,
                                                     i_geo_state      => i_geo_state,
                                                     i_code_year      => i_code_year);
    END check_inst_serie_number;

    /********************************************************************************************
    * Get sis pre natal active serie current number
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_serie_current_number
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_state      IN geo_state.code_state%TYPE,
        i_year            IN series.series_year%TYPE,
        i_starting_number IN series.starting_number%TYPE,
        i_ending_number   IN series.ending_number%TYPE
    ) RETURN series.current_number%TYPE IS
    BEGIN
    
        RETURN pk_backoffice.get_serie_current_number(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_code_state      => i_code_state,
                                                      i_year            => i_year,
                                                      i_starting_number => i_starting_number,
                                                      i_ending_number   => i_ending_number);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
            RETURN NULL;
    END get_serie_current_number;

    /********************************************************************************************
    * Set sis pre natal active serie current number
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_code_state            Country state code
    * @param i_year                  Series year
    * @param i_current_number        Series current number
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION set_serie_current_number
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_code_state     IN geo_state.code_state%TYPE,
        i_year           IN series.series_year%TYPE,
        i_current_number IN series.current_number%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_backoffice.set_serie_current_number(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_code_state     => i_code_state,
                                                      i_year           => i_year,
                                                      i_current_number => i_current_number,
                                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_SERIE_CURRENT_NUMBER',
                                              o_error);
            RETURN FALSE;
    END set_serie_current_number;

    /********************************************************************************************
    * Get states of a country
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_backoffice.get_state_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_STATE_LIST',
                                              o_error);
            RETURN FALSE;
    END get_state_list;

    /********************************************************************************************
    * Creates/Edit a new series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_id_series             Series ID
    * @param i_code_state            Official code state
    * @param i_year                  Series Year
    * @param i_starting_number       Series starting number
    * @param i_ending_number         Series ending number
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION set_pre_natal_serie
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_series       IN series.id_series%TYPE,
        i_id_geo_state    IN geo_state.id_geo_state%TYPE,
        i_year            IN series.series_year%TYPE,
        i_starting_number IN series.starting_number%TYPE,
        i_current_number  IN series.current_number%TYPE,
        i_ending_number   IN series.ending_number%TYPE,
        o_msg             OUT sys_message.desc_message%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INVOKING PK_BACKOFFICE.SET_PRE_NATAL_SERIE';
        IF NOT pk_backoffice.set_pre_natal_serie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_series       => i_id_series,
                                                 i_id_geo_state    => i_id_geo_state,
                                                 i_year            => i_year,
                                                 i_starting_number => i_starting_number,
                                                 i_current_number  => i_current_number,
                                                 i_ending_number   => i_ending_number,
                                                 o_msg             => o_msg,
                                                 o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_PRE_NATAL_SERIE',
                                              o_error);
            RETURN FALSE;
    END set_pre_natal_serie;

    /********************************************************************************************
    * Sets pre natal series status
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_id_series             Series ID
    * @param i_flg_status            Series status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION set_pre_natal_serie_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_series  IN series.id_series%TYPE,
        i_flg_status IN series.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INVOKING PK_BACKOFFICE.SET_PRE_NATAL_SERIE_STATUS';
        IF NOT pk_backoffice.set_pre_natal_serie_status(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_series  => i_id_series,
                                                        i_flg_status => i_flg_status,
                                                        o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_PRE_NATAL_SERIE_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_pre_natal_serie_status;

    /********************************************************************************************
    * Get next series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_next_id_series        Series next ID
    * @param o_current_year          Current year
    * @param o_msg_atributed         Message attributed numbers (N/A)
    * @param o_msg_available         Message available numbers (N/A)
    * @param o_flg_status            Series flag status
    * @param o_desc_status           Series desc status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_next_pre_natal_serie
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_next_id_series OUT series.id_series%TYPE,
        o_current_year   OUT series.series_year%TYPE,
        o_msg_atributed  OUT sys_message.desc_message%TYPE,
        o_msg_available  OUT sys_message.desc_message%TYPE,
        o_code_state     OUT geo_state.code_state%TYPE,
        o_desc_state     OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INVOKING PK_BACKOFFICE.GET_NEXT_PRE_NATAL_SERIE';
        IF NOT pk_backoffice.get_next_pre_natal_serie(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      o_next_id_series => o_next_id_series,
                                                      o_current_year   => o_current_year,
                                                      o_msg_atributed  => o_msg_atributed,
                                                      o_msg_available  => o_msg_available,
                                                      o_code_state     => o_code_state,
                                                      o_desc_state     => o_desc_state,
                                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_NEXT_PRE_NATAL_SERIE',
                                              o_error);
            RETURN FALSE;
    END get_next_pre_natal_serie;

    /********************************************************************************************
    * Get pre natal series available status
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  List of status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_series_available_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_series  IN series.id_series%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INVOKING PK_BACKOFFICE.GET_PRE_NATAL_AVAILABLE_STATUS';
        IF NOT pk_backoffice.get_series_available_status(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_series  => i_id_series,
                                                         i_subject    => i_subject,
                                                         i_from_state => i_from_state,
                                                         o_list       => o_list,
                                                         o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PRE_NATAL_AVAILABLE_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_series_available_status;

    /********************************************************************************************
    * Get pre natal series available actions
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  List of actions
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_series_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_series  IN series.id_series%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INVOKING PK_BACKOFFICE.GET_SERIES_ACTIONS';
        IF NOT pk_backoffice.get_series_actions(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_series  => i_id_series,
                                                i_subject    => i_subject,
                                                i_from_state => i_from_state,
                                                o_actions    => o_actions,
                                                o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_SERIES_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_series_actions;

    /********************************************************************************************
    * Get geo_state table id
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_code_state            List of actions
    *
    * @return                        id_geo_state
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_geo_state_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_code_state IN geo_state.code_state%TYPE
    ) RETURN geo_state.id_geo_state%TYPE IS
    BEGIN
    
        RETURN pk_backoffice.get_geo_state_id(i_lang => i_lang, i_prof => i_prof, i_code_state => i_code_state);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
            RETURN NULL;
    END get_geo_state_id;

    /********************************************************************************************
    * Get code_state from geo_state table
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_id_geo_state          Geo state ID
    *
    * @return                        code_state
    *
    * @author                        ?lvaro Vasconcelos
    * @version                       2.5.1.5
    * @since                         2011/04/29
    ********************************************************************************************/
    FUNCTION get_code_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_geo_state IN geo_state.code_state%TYPE
    ) RETURN geo_state.code_state%TYPE IS
    BEGIN
    
        RETURN pk_backoffice.get_code_state(i_lang => i_lang, i_prof => i_prof, i_id_geo_state => i_id_geo_state);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END get_code_state;
    /********************************************************************************************
    * Returns True and the new state of the professional configuration
    *
    * @param i_lang                 Language id
    * @param i_id_professional      Professional identifier
    * @param i_id_institution       Professional identifier
    * @param i_state                Professional Institution State
    * @param i_num_mec              Professional Institution Mec Number
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/09/06
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION intf_set_prof_inst_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_state           IN prof_institution.flg_state%TYPE,
        i_num_mec         IN prof_institution.num_mecan%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(100 CHAR) := 'intf_set_prof_inst_state';
        l_code_name     VARCHAR2(100 CHAR) := 'PROFESSIONAL.FLG_STATE';
        l_exception EXCEPTION;
        l_icon      VARCHAR2(1000) := NULL;
        l_new_state prof_institution.flg_state%TYPE := NULL;
    
        -- auxiliar validation
        l_valid_prof NUMBER(24) := 0;
        l_valid_flg  NUMBER(24) := 0;
    BEGIN
        -- professional validation
        g_error := 'GET PROFESSIONAL VALIDATION RESULT ';
        SELECT nvl(COUNT(*), 0)
          INTO l_valid_prof
          FROM professional p
         WHERE p.id_professional = i_id_professional;
        -- state validation
        g_error := 'GET STATE VALIDATION RESULT ';
        SELECT nvl(COUNT(*), 0)
          INTO l_valid_flg
          FROM sys_domain sd
         WHERE sd.code_domain = l_code_name
           AND sd.domain_owner = pk_sysdomain.k_default_schema
           AND sd.val = i_state
           AND sd.id_language = i_lang;
    
        IF (l_valid_flg > 0 AND l_valid_prof > 0)
        THEN
            g_error := 'CALL PK_BACKOFFICE.SET_INTF_PROF_INST_STATE ';
            IF NOT pk_backoffice.set_intf_prof_inst_state(i_lang,
                                                          i_id_professional,
                                                          i_id_institution,
                                                          i_state,
                                                          i_num_mec,
                                                          l_new_state,
                                                          l_icon,
                                                          o_error)
            THEN
                g_error := 'PK_BACKOFFICE.SET_PROF_INSTITUTION_STATE ' || i_id_professional || ', ' || i_id_institution;
                RAISE l_exception;
            END IF;
        
            IF l_new_state = i_state
            THEN
                RETURN TRUE;
            ELSE
                g_error := 'CALL PK_BACKOFFICE.SET_PROF_INSTITUTION_STATE DIFFERENT STATES ' || i_state || ' - ' ||
                           l_new_state;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'PROFESSIONAL OR PROFESSIONAL STATE NOT VALID ' || i_state || ' , ' || i_id_professional;
            RAISE l_exception;
        END IF;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END intf_set_prof_inst_state;
    /********************************************************************************************
    * Set Professional institution relations (internal or external)
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_institutions          Institution ID's
    * @param i_flg_state             Professional status list
    * @param i_num_mecan             Mecan. Number's lists
    * @param i_dt_begin_tstz         Begin dates list
    * @param i_dt_end_tstz           End dates list
    * @param i_flg_external          External relation? Y - External, N- interal list
    * @param o_prof_institutions     Professional/institution relation id's
    * @param o_error                 t_error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.0.5.10
    * @since                       2011/07/11
    ********************************************************************************************/
    FUNCTION intf_set_all_prof_instits
    (
        i_lang              IN language.id_language%TYPE,
        i_id_professional   IN prof_institution.id_professional%TYPE,
        i_institutions      IN table_number,
        i_flg_state         IN table_varchar,
        i_num_mecan         IN table_varchar,
        i_dt_begin_tstz     IN table_timestamp,
        i_dt_end_tstz       IN table_timestamp,
        i_flg_external      IN table_varchar,
        o_prof_institutions OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100) := 'INTF_SET_ALL_PROF_INSTITS';
    
        l_exception EXCEPTION;
        l_error_out         t_error_out;
        l_prof_institutions prof_institution.id_prof_institution%TYPE;
        l_count             NUMBER;
        l_idx               NUMBER := 1;
    
    BEGIN
        o_prof_institutions := table_number();
    
        FOR i IN 1 .. i_institutions.count
        LOOP
            g_error := 'CHECK ASSOCIATION PROFESIONAL TO INSTITUTIONS: id_professional = ' || i_id_professional ||
                       ' ID_Institution ' || i_institutions(i);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_ALL_PROF_INSTITS: ' || g_error);
            SELECT nvl(COUNT(*), 0)
              INTO l_count
              FROM prof_institution pi
             WHERE pi.id_professional = i_id_professional
               AND pi.id_institution = i_institutions(i)
               AND pi.dt_end_tstz IS NULL;
        
            IF l_count = 0
            THEN
                g_error := 'ASSOCIATE PROFESIONAL TO INSTITUTIONS: ' || i_id_professional || ', ' || i_institutions(i);
                pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_ALL_PROF_INSTITS: ' || g_error);
                IF NOT pk_backoffice.set_prof_institution(i_lang,
                                                          i_id_professional,
                                                          i_institutions(i),
                                                          i_flg_state(i),
                                                          i_num_mecan(i),
                                                          i_dt_begin_tstz(i),
                                                          i_dt_end_tstz(i),
                                                          i_flg_external(i),
                                                          l_prof_institutions,
                                                          l_error_out)
                THEN
                    RAISE l_exception;
                
                END IF;
            ELSE
                SELECT pi.id_prof_institution
                  INTO l_prof_institutions
                  FROM prof_institution pi
                 WHERE pi.id_professional = i_id_professional
                   AND pi.id_institution = i_institutions(i)
                   AND pi.dt_end_tstz IS NULL
                   AND rownum = 1;
            END IF;
            g_error := 'EXTEND ARRAYS ' || l_prof_institutions;
            o_prof_institutions.extend;
            o_prof_institutions(l_idx) := l_prof_institutions;
            l_idx := l_idx + 1;
        END LOOP;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_all_prof_instits;
    /********************************************************************************************
    * Update/insert information for an external user and configure to all institutions with same ADT service
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_title                 Professional Title
    * @param i_first_name            Professional first name
    * @param i_middle_name           Professional middle name
    * @param i_last_name             Professional last name
    * @param i_nickname              Professional Nickname
    * @param i_initials              Professional initials
    * @param i_dt_birth              Professional Date of Birth
    * @param i_gender                Professioanl gender
    * @param i_marital_status        Professional marital status
    * @param i_id_speciality         Professional specialty
    * @param i_num_order             Professional license number
    * @param i_address               Professional adress
    * @param i_city                  Professional city
    * @param i_district              Professional district
    * @param i_zip_code              Professional zip code
    * @param i_id_country            Professional cpuntry
    * @param i_phone                 Professional phone
    * @param i_mobile_phone          Professional mobile phone
    * @param i_fax                   Professional fax
    * @param i_email                 Professional email
    * @param o_professional          Professional ID
    * @param o_prof_insts            Professional Institutions Configuration ID list
    * @param o_error                 error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Rui.gomes
    * @version                     0.1
    * @since                       2011/07/12
    ********************************************************************************************/
    FUNCTION intf_set_ext_prof_insts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nickname       IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN professional.dt_birth%TYPE,
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE,
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_phone          IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_mobile_phone   IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        o_professional   OUT professional.id_professional%TYPE,
        o_prof_insts     OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        flg_adt         VARCHAR2(50) := 'ADT';
        l_institutions  table_number := table_number();
        l_flg_state     table_varchar := table_varchar();
        l_num_mecan     table_varchar := table_varchar();
        l_dt_begin_tstz table_timestamp := table_timestamp();
        l_dt_end_tstz   table_timestamp := table_timestamp();
        l_flg_external  table_varchar := table_varchar();
    
        -- error handling
        l_exception EXCEPTION;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'CREATE EXTERNAL PROFESIONAL';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_EXT_PROF_INSTS: ' || g_error);
        IF NOT pk_backoffice.set_ext_professional(i_lang           => i_lang,
                                                  i_id_prof        => i_id_prof,
                                                  i_title          => i_title,
                                                  i_first_name     => i_first_name,
                                                  i_parent_name    => NULL,
                                                  i_middle_name    => i_middle_name,
                                                  i_last_name      => i_last_name,
                                                  i_nickname       => i_nickname,
                                                  i_initials       => i_initials,
                                                  i_dt_birth       => i_dt_birth,
                                                  i_gender         => i_gender,
                                                  i_marital_status => i_marital_status,
                                                  i_id_speciality  => i_id_speciality,
                                                  i_num_order      => i_num_order,
                                                  i_address        => i_address,
                                                  i_city           => i_city,
                                                  i_district       => i_district,
                                                  i_zip_code       => i_zip_code,
                                                  i_id_country     => i_id_country,
                                                  i_phone          => i_phone,
                                                  i_num_contact    => i_num_contact,
                                                  i_mobile_phone   => i_mobile_phone,
                                                  i_fax            => i_fax,
                                                  i_email          => i_email,
                                                  i_id_institution => i_id_institution,
                                                  i_commit_at_end  => FALSE,
                                                  o_professional   => o_professional,
                                                  o_error          => l_error_out)
        THEN
            RAISE l_exception;
        ELSE
            g_error        := 'FETCH ALL PROFESIONAL INSTITUTIONS';
            l_institutions := pk_list.tf_get_all_inst_group(i_id_institution, flg_adt);
        
            FOR x IN 1 .. l_institutions.last
            LOOP
                l_flg_state.extend;
                l_num_mecan.extend;
                l_dt_begin_tstz.extend;
                l_dt_end_tstz.extend;
                l_flg_external.extend;
            
                l_flg_state(x) := 'A';
                l_num_mecan(x) := NULL;
                l_dt_begin_tstz(x) := current_timestamp;
                l_dt_end_tstz(x) := NULL;
                l_flg_external(x) := 'Y';
            END LOOP;
            g_error := 'CREATE PROFESIONAL IN ALL INSTITUTIONS';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_SET_EXT_PROF_INSTS: ' || g_error);
            IF NOT intf_set_all_prof_instits(i_lang,
                                             o_professional,
                                             l_institutions,
                                             l_flg_state,
                                             l_num_mecan,
                                             l_dt_begin_tstz,
                                             l_dt_end_tstz,
                                             l_flg_external,
                                             o_prof_insts,
                                             l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_PROF_INSTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_SET_EXT_PROF_INSTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_set_ext_prof_insts;
    /********************************************************************************************
    * Find external professionals (Scheduler)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param i_licence_number      Professional license number
    * @param i_gender              Professional gender
    * @param i_name                Professional name
    * @param i_dt_birth            Date of birth
    * @param i_street              Street
    * @param i_postal_code         Postal code
    * @param i_city                City
    * @param i_phone_number        Phone number
    * @param i_email               E-mail
    * @param i_flg_external        External Professionals (Y - Yes, N - No)
    * @param i_fields              array of fields id's
    * @param i_fields_value        array of fields value strings
    * @param o_professionals       Professionals list
    * @param o_prof_fields         Professionals list of specific market fields
    * @param o_error               error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.2
    * @since                       2010/08/16
    ********************************************************************************************/
    FUNCTION intf_get_prof
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_licence_number  IN professional.num_order%TYPE,
        i_gender          IN professional.gender%TYPE,
        i_name            IN professional.name%TYPE,
        i_dt_birth        IN professional.dt_birth%TYPE,
        i_street          IN professional.address%TYPE,
        i_postal_code     IN professional.zip_code%TYPE,
        i_city            IN professional.city%TYPE,
        i_phone_number    IN professional.num_contact%TYPE,
        i_email           IN professional.email%TYPE,
        i_flg_external    IN prof_institution.flg_external%TYPE,
        i_fields          IN table_number,
        i_fields_value    IN table_varchar,
        i_start_val       IN NUMBER DEFAULT 0,
        i_range           IN NUMBER DEFAULT 50,
        o_professionals   OUT t_table_prof_common,
        o_count           OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name  VARCHAR2(100 CHAR) := 'INTF_GET_SCH_EXT_PROF';
        l_id_market      market.id_market%TYPE;
        l_prof_id_common table_number := table_number();
        l_prof_id_dinm   table_number := table_number();
    
        l_prof_ids    table_number := table_number();
        l_orderer_id  table_number := table_number();
        o_prof_fields t_table_prof_fields;
    
        l_start NUMBER := 0;
        l_range NUMBER := 10;
    
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF i_id_professional IS NOT NULL
        THEN
        
            g_error := 'GET EXTERNAL PROFESSIONAL DINAMIC INFORMATION, ID_PROFESSIONAL = ' ||
                       to_char(i_id_professional);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
            -- get specific market fields related with the professional
            SELECT t_rec_prof_fields(id_professional, id_field_market, field_name, field_value, id_market)
              BULK COLLECT
              INTO o_prof_fields
              FROM (SELECT pfd.id_professional,
                           pfd.id_field_market,
                           pk_translation.get_translation(i_lang, f.code_field) field_name,
                           pfd.value field_value,
                           fm.id_market
                      FROM professional_field_data pfd
                     INNER JOIN field_market fm
                        ON (fm.id_field_market = pfd.id_field_market)
                     INNER JOIN field f
                        ON (f.id_field = fm.id_field)
                     INNER JOIN professional p
                        ON (p.id_professional = pfd.id_professional)
                     INNER JOIN prof_institution pi
                        ON (pi.id_professional = pfd.id_professional AND pi.id_institution = i_id_institution AND
                           pi.flg_external = i_flg_external AND pi.dt_end_tstz IS NULL AND
                           pi.flg_state = pk_alert_constant.g_active)
                     WHERE pfd.id_professional = i_id_professional
                       AND fm.id_market = l_id_market);
        
            g_error := 'GET EXTERNAL PROFESSIONAL INFORMATION, ID_PROFESSIONAL = ' || to_char(i_id_professional);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
            -- professional common static fields colection
            SELECT t_rec_prof_common(id_professional,
                                     name,
                                     license_number,
                                     postal_code,
                                     city,
                                     gender,
                                     dt_birth,
                                     address,
                                     phone_number,
                                     email,
                                     flg_state,
                                     o_prof_fields)
              BULK COLLECT
              INTO o_professionals
              FROM (SELECT p.id_professional,
                           p.name,
                           pk_backoffice_ext_prof.get_ext_prof_license_number(i_lang,
                                                                              p.id_professional,
                                                                              NULL,
                                                                              l_id_market) license_number,
                           p.zip_code postal_code,
                           p.city,
                           p.gender,
                           p.dt_birth,
                           p.address,
                           p.num_contact phone_number,
                           p.email,
                           pi.flg_state
                      FROM professional p
                     INNER JOIN prof_institution pi
                        ON (pi.id_professional = p.id_professional AND pi.id_institution = i_id_institution AND
                           pi.dt_end_tstz IS NULL)
                     WHERE p.id_professional = i_id_professional
                       AND pi.flg_external = i_flg_external
                       AND pi.flg_state = pk_alert_constant.g_active);
        
            o_count := 1;
        ELSE
            g_error := 'PAGING RANGE OR START VALUE NOT FILLED';
            IF (i_start_val IS NULL OR i_range IS NULL)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'GET EXTERNAL PROFESSIONAL ID LIST SEARCHING COMMON LIST OF FIELDS';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
            -- get professional ids in common fields through search
            SELECT p.id_professional
              BULK COLLECT
              INTO l_prof_id_common
              FROM professional p
             INNER JOIN prof_institution pi
                ON (pi.id_professional = p.id_professional AND pi.id_institution = i_id_institution AND
                   pi.dt_end_tstz IS NULL)
             WHERE
            --flg_external
             pi.flg_external = i_flg_external
             AND pi.flg_state = pk_alert_constant.g_active
             AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
            --gender
             AND (p.gender = i_gender OR i_gender IS NULL)
            --dt_birth
             AND (p.dt_birth = i_dt_birth OR i_dt_birth IS NULL)
            --name
             AND (i_name IS NULL OR
             (translate(upper(p.name), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_name), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
            --license_number
             AND (i_licence_number IS NULL OR
             (translate(upper(pk_backoffice_ext_prof.get_ext_prof_license_number(i_lang,
                                                                                  p.id_professional,
                                                                                  NULL,
                                                                                  l_id_market)),
                         '????????????????????????? ',
                         'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_licence_number), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
            --city
             AND (i_city IS NULL OR
             (translate(upper(p.city), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_city), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
            --street
             AND (i_street IS NULL OR
             (translate(upper(p.address), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_street), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
            --phone_number
             AND (i_phone_number IS NULL OR
             (translate(upper(p.num_contact), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_phone_number), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
            --postal_code
             AND (i_postal_code IS NULL OR
             (translate(upper(p.zip_code), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_postal_code), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
            --e_mail
             AND (i_email IS NULL OR
             (translate(upper(p.email), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
             ('%' || translate(upper(i_email), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')));
        
            g_error := 'GET EXTERNAL PROFESSIONAL ID LIST SEARCHING DINAMIC LIST OF FIELDS ';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
            --l_count := i_fields.count;
        
            IF i_fields.count > 0
            THEN
                IF l_prof_id_common.count > 0
                THEN
                    -- get professional ids in dinamic fields through search
                    SELECT DISTINCT prof_field.id_professional
                      BULK COLLECT
                      INTO l_prof_id_dinm
                      FROM (SELECT pfd.id_professional, pfd.value, fm.id_field, fm.id_field_market
                               FROM professional_field_data pfd
                              INNER JOIN prof_institution pi
                                 ON (pi.id_professional = pfd.id_professional AND pi.dt_end_tstz IS NULL AND
                                    pi.flg_external = i_flg_external AND pi.flg_state = pk_alert_constant.g_active)
                              INNER JOIN professional p
                                 ON (p.id_professional = pfd.id_professional AND nvl(p.flg_prof_test, 'N') = 'N')
                              INNER JOIN field_market fm
                                 ON (fm.id_field_market = pfd.id_field_market AND
                                    fm.flg_available = pk_alert_constant.get_available)
                              WHERE
                             --flg_external
                              pi.flg_external = i_flg_external
                             --institution
                           AND pi.id_institution = i_id_institution
                           AND fm.id_market = l_id_market
                           AND pfd.id_professional IN
                              (SELECT column_value val
                                 FROM TABLE(CAST(l_prof_id_common AS table_number)))
                           AND fm.id_field_market IN (SELECT column_value val
                                                       FROM TABLE(CAST(i_fields AS table_number)))) prof_field,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields AS table_number))) ids,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields_value AS table_varchar))) vals
                     WHERE prof_field.id_field_market = ids.val
                       AND ids.idx = vals.idx
                       AND translate(upper(prof_field.value),
                                     '????????????????????????? ',
                                     'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           '%' ||
                           translate(upper(vals.val), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
                ELSE
                    SELECT DISTINCT prof_field.id_professional
                      BULK COLLECT
                      INTO l_prof_id_dinm
                      FROM (SELECT pfd.id_professional, pfd.value, fm.id_field
                               FROM professional_field_data pfd
                              INNER JOIN prof_institution pi
                                 ON (pi.id_professional = pfd.id_professional AND pi.dt_end_tstz IS NULL AND
                                    pi.flg_external = i_flg_external AND pi.flg_state = pk_alert_constant.g_active)
                              INNER JOIN professional p
                                 ON (p.id_professional = pfd.id_professional AND nvl(p.flg_prof_test, 'N') = 'N')
                              INNER JOIN field_market fm
                                 ON (fm.id_field_market = pfd.id_field_market AND
                                    fm.flg_available = pk_alert_constant.get_available)
                              WHERE
                             --flg_external
                              pi.flg_external = i_flg_external
                             --institution
                           AND pi.id_institution = i_id_institution
                           AND fm.id_market = l_id_market
                           AND fm.id_field_market IN (SELECT column_value val
                                                       FROM TABLE(CAST(i_fields AS table_number)))) prof_field,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields AS table_number))) ids,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields_value AS table_varchar))) vals
                     WHERE prof_field.id_field = ids.val
                       AND ids.idx = vals.idx
                       AND translate(upper(prof_field.value),
                                     '????????????????????????? ',
                                     'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           '%' ||
                           translate(upper(vals.val), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
                END IF;
                l_prof_ids := l_prof_id_dinm;
            ELSE
                l_prof_ids := l_prof_id_common;
            END IF;
            -- l_prof_ids := l_prof_id_common MULTISET UNION l_prof_id_dinm;
            -- order array
            SELECT profs_ordered.id_professional
              BULK COLLECT
              INTO l_orderer_id
              FROM (SELECT p.id_professional, p.name
                      FROM professional p
                     WHERE p.id_professional IN (SELECT column_value
                                                   FROM TABLE(CAST(l_prof_ids AS table_number)))) profs_ordered
             ORDER BY profs_ordered.name;
        
            -- count professionals
            SELECT nvl(COUNT(*), 0)
              INTO o_count
              FROM (SELECT p.id_professional, p.name
                      FROM professional p
                     INNER JOIN prof_institution pi
                        ON (pi.id_professional = p.id_professional AND pi.id_institution = i_id_institution AND
                           pi.dt_end_tstz IS NULL)
                     WHERE pi.flg_external = i_flg_external
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pi.id_professional IN
                           (SELECT column_value
                              FROM TABLE(CAST(l_orderer_id AS table_number)))
                       AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                     ORDER BY p.name) profs;
        
            -- get professional common fields details
            g_error := 'GET EXTERNAL PROFESSIONALS LIST OF ID_INSTITUTION = ' || to_char(i_id_institution);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_SCH_EXT_PROF: ' || g_error);
            SELECT t_rec_prof_common(profs.id_professional,
                                     profs.name,
                                     profs.license_number,
                                     profs.postal_code,
                                     profs.city,
                                     profs.gender,
                                     profs.dt_birth,
                                     profs.address,
                                     profs.phone_number,
                                     profs.email,
                                     profs.flg_state,
                                     profs.prof_fields)
              BULK COLLECT
              INTO o_professionals
              FROM (SELECT rownum rn,
                            p.id_professional,
                            p.name,
                            pk_backoffice_ext_prof.get_ext_prof_license_number(i_lang,
                                                                               p.id_professional,
                                                                               NULL,
                                                                               l_id_market) license_number,
                            p.zip_code postal_code,
                            p.city,
                            p.gender,
                            p.dt_birth,
                            p.address,
                            p.num_contact phone_number,
                            p.email,
                            pi.flg_state,
                            CAST(MULTISET
                                 (SELECT t_rec_prof_fields(pfd.id_professional,
                                                           pfd.id_field_market,
                                                           pk_translation.get_translation(i_lang, f.code_field),
                                                           pfd.value,
                                                           fm.id_market)
                                    FROM professional_field_data pfd
                                   INNER JOIN field_market fm
                                      ON (fm.id_field_market = pfd.id_field_market)
                                   INNER JOIN field f
                                      ON (f.id_field = fm.id_field)
                                   INNER JOIN professional p1
                                      ON (p1.id_professional = pfd.id_professional)
                                   INNER JOIN prof_institution pi1
                                      ON (pi1.id_professional = pfd.id_professional AND
                                         pi1.id_institution = i_id_institution AND pi1.flg_external = i_flg_external AND
                                         pi1.dt_end_tstz IS NULL AND pi1.flg_state = pk_alert_constant.g_active)
                                   WHERE pfd.id_professional = pi.id_professional
                                     AND fm.id_market = l_id_market) AS t_table_prof_fields) prof_fields
                       FROM professional p
                      INNER JOIN prof_institution pi
                         ON (pi.id_professional = p.id_professional AND pi.id_institution = i_id_institution AND
                            pi.dt_end_tstz IS NULL)
                      WHERE
                     --flg_external
                      pi.flg_external = i_flg_external
                   AND pi.flg_state = pk_alert_constant.g_active
                     --institution
                   AND pi.id_professional IN (SELECT column_value
                                               FROM TABLE(CAST(l_orderer_id AS table_number)))
                   AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
                      ORDER BY p.name) profs
             WHERE rn BETWEEN nvl(i_start_val, l_start) AND nvl(i_start_val, l_start) + nvl(i_range, l_range);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_get_prof;
    /********************************************************************************************
    * Find external institutions (Scheduler)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_inst_search      Institution to search ID
    * @param i_id_institution      logged Institution ID
    * @param i_instit_name         Institution name
    * @param i_instit_type         Institution type
    * @param i_acronym             Institution acronym
    * @param i_address             Institution adress
    * @param i_postal_code         Postal code
    * @param i_city                City
    * @param i_phone_number        Phone number
    * @param i_fax_num             Fax number
    * @param i_email               E-mail
    * @param i_flg_external        External Professionals (Y - Yes, N - No)
    * @param i_fields              array of fields id's
    * @param i_fields_value        array of fields value strings
    * @param o_institution         Professionals list
    * @param o_error               error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.2
    * @since                       2010/09/02
    ********************************************************************************************/
    FUNCTION intf_get_instit
    (
        i_lang           IN language.id_language%TYPE,
        i_id_inst_search IN institution.id_institution%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_instit_name    IN translation.desc_lang_1%TYPE,
        i_instit_type    IN sys_domain.desc_val%TYPE,
        i_acronym        IN institution.abbreviation%TYPE,
        i_address        IN institution.address%TYPE,
        i_postcode       IN institution.zip_code%TYPE,
        i_city           IN institution.location%TYPE,
        i_phone_num      IN institution.phone_number%TYPE,
        i_fax_num        IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_flg_external   IN institution.flg_external%TYPE,
        i_fields         IN table_number,
        i_fields_value   IN table_varchar,
        o_institution    OUT t_table_inst_common,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name  VARCHAR2(100 CHAR) := 'INTF_GET_INSTIT';
        l_id_market      market.id_market%TYPE;
        l_inst_id_common table_number := table_number();
        l_inst_id_dinm   table_number := table_number();
    
        l_inst_ids table_number := table_number();
    
        l_t_table_inst_fields t_table_inst_fields;
    BEGIN
    
        g_error := 'GET INSTITUTION MARKET';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTIT: ' || g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF i_id_inst_search IS NOT NULL
        THEN
            g_error := 'GET EXTERNAL INSTITUTION DINAMIC INFORMATION, ID_INSTITUTION = ' || to_char(i_id_inst_search);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTIT: ' || g_error);
            -- get specific market fields related with the institution
            SELECT t_rec_inst_fields(id_institution, id_field_market, field_name, field_value, id_market)
              BULK COLLECT
              INTO l_t_table_inst_fields
              FROM (SELECT ifd.id_institution,
                           ifd.id_field_market,
                           pk_translation.get_translation(i_lang, f.code_field) field_name,
                           ifd.value field_value,
                           fm.id_market
                      FROM institution_field_data ifd
                     INNER JOIN field_market fm
                        ON (fm.id_field_market = ifd.id_field_market)
                     INNER JOIN field f
                        ON (f.id_field = fm.id_field)
                     INNER JOIN institution i
                        ON (i.id_institution = ifd.id_institution AND i.flg_available = pk_alert_constant.get_available)
                     WHERE ifd.id_institution = i_id_inst_search
                       AND i.flg_external = i_flg_external
                       AND fm.id_market = l_id_market);
        
            g_error := 'GET EXTERNAL INSTITUTION INFORMATION, ID_INSTITUTION = ' || to_char(i_id_inst_search);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTIT: ' || g_error);
            -- institution common static fields colection
            SELECT t_rec_inst_common(instit.id_institution,
                                     instit.instit_name,
                                     instit.instit_type,
                                     instit.abbreviation,
                                     instit.address,
                                     instit.zip_code,
                                     instit.location,
                                     instit.phone_number,
                                     instit.fax_number,
                                     instit.country_name,
                                     instit.email,
                                     l_t_table_inst_fields)
              BULK COLLECT
              INTO o_institution
              FROM (SELECT i.id_institution,
                           pk_translation.get_translation(i_lang, i.code_institution) instit_name,
                           pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) instit_type,
                           i.abbreviation,
                           i.address,
                           i.zip_code,
                           i.location,
                           i.phone_number,
                           i.fax_number,
                           pk_translation.get_translation(i_lang, c.code_country) country_name,
                           ia.email
                      FROM institution i
                     INNER JOIN inst_attributes ia
                        ON (ia.id_institution = i.id_institution AND ia.flg_available = pk_alert_constant.get_available)
                     INNER JOIN country c
                        ON (c.id_country = ia.id_country AND c.flg_available = pk_alert_constant.get_available)
                     WHERE i.id_institution = i_id_inst_search
                       AND i.flg_available = pk_alert_constant.get_available
                       AND i.id_market = l_id_market
                       AND i.flg_external = i_flg_external) instit;
        ELSE
            g_error := 'GET EXTERNAL INSTITUTION ID LIST SEARCHING COMMON LIST OF FIELDS';
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTIT: ' || g_error);
            -- get institution ids in common fields through search
            SELECT i.id_institution
              BULK COLLECT
              INTO l_inst_id_common
              FROM institution i
             INNER JOIN inst_attributes ia
                ON (ia.id_institution = i.id_institution AND ia.flg_available = pk_alert_constant.get_available)
             INNER JOIN country c
                ON (c.id_country = ia.id_country AND c.flg_available = pk_alert_constant.get_available)
             WHERE i.flg_available = pk_alert_constant.get_available
               AND i.id_market = l_id_market
               AND i.flg_external = i_flg_external
                  -- institution name
               AND (i_instit_name IS NULL OR
                   (translate(upper(pk_translation.get_translation(i_lang, i.code_institution)),
                               '????????????????????????? ',
                               'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' ||
                   translate(upper(i_instit_name), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- institution type
               AND (i_instit_type IS NULL OR
                   (translate(upper(pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang)),
                               '????????????????????????? ',
                               'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' ||
                   translate(upper(i_instit_type), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- acronym
               AND (i_acronym IS NULL OR
                   (translate(upper(i.abbreviation), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_acronym), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- address
               AND (i_address IS NULL OR
                   (translate(upper(i.address), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_address), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- zip code
               AND (i_postcode IS NULL OR
                   (translate(upper(i.zip_code), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_postcode), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- city
               AND (i_city IS NULL OR
                   (translate(upper(i.location), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_city), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- phone number
               AND (i_phone_num IS NULL OR
                   (translate(upper(i.phone_number), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_phone_num), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- fax number
               AND (i_fax_num IS NULL OR
                   (translate(upper(i.fax_number), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_fax_num), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')))
                  -- email
               AND (i_email IS NULL OR
                   (translate(upper(ia.email), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                   ('%' || translate(upper(i_email), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%')));
        
            IF i_fields.count > 0
            THEN
                -- check if the search is from colection or by single fields
                IF l_inst_id_common.count > 0
                THEN
                    g_error := 'GET EXTERNAL INSTITUTION ID LIST SEARCHING DINAMIC LIST OF FIELDS';
                    pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTIT: ' || g_error);
                    -- get institution ids in dinamic fields through search
                    SELECT DISTINCT inst_field.id_institution
                      BULK COLLECT
                      INTO l_inst_id_dinm
                      FROM (SELECT ifd.id_institution, ifd.value, fm.id_field
                               FROM institution_field_data ifd
                              INNER JOIN field_market fm
                                 ON (fm.id_field_market = ifd.id_field_market AND
                                    fm.flg_available = pk_alert_constant.get_available)
                              INNER JOIN institution i
                                 ON (i.id_institution = ifd.id_institution AND i.id_market = fm.id_market AND
                                    i.flg_available = pk_alert_constant.get_available)
                              WHERE
                             --flg_external
                              i.flg_external = i_flg_external
                             --institution
                           AND fm.id_market = l_id_market
                             -- 30/09/2011: filter results from common search
                           AND ifd.id_institution IN
                              (SELECT column_value
                                 FROM TABLE(CAST(l_inst_id_common AS table_number)))
                           AND fm.id_field IN (SELECT column_value val
                                                FROM TABLE(CAST(i_fields AS table_number)))) inst_field,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields AS table_number))) ids,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields_value AS table_varchar))) vals
                     WHERE inst_field.id_field = ids.val
                       AND ids.idx = vals.idx
                       AND translate(upper(inst_field.value),
                                     '????????????????????????? ',
                                     'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           '%' ||
                           translate(upper(vals.val), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
                ELSE
                    SELECT DISTINCT inst_field.id_institution
                      BULK COLLECT
                      INTO l_inst_id_dinm
                      FROM (SELECT ifd.id_institution, ifd.value, fm.id_field
                               FROM institution_field_data ifd
                              INNER JOIN field_market fm
                                 ON (fm.id_field_market = ifd.id_field_market AND
                                    fm.flg_available = pk_alert_constant.get_available)
                              INNER JOIN institution i
                                 ON (i.id_institution = ifd.id_institution AND i.id_market = fm.id_market AND
                                    i.flg_available = pk_alert_constant.get_available)
                              WHERE
                             --flg_external
                              i.flg_external = i_flg_external
                             --institution
                           AND fm.id_market = l_id_market
                           AND fm.id_field IN (SELECT column_value val
                                                FROM TABLE(CAST(i_fields AS table_number)))) inst_field,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields AS table_number))) ids,
                           (SELECT column_value val, rownum idx
                              FROM TABLE(CAST(i_fields_value AS table_varchar))) vals
                     WHERE inst_field.id_field = ids.val
                       AND ids.idx = vals.idx
                       AND translate(upper(inst_field.value),
                                     '????????????????????????? ',
                                     'AEIOUAEIOUAEIOUAOCAEIOUNY%') LIKE
                           '%' ||
                           translate(upper(vals.val), '????????????????????????? ', 'AEIOUAEIOUAEIOUAOCAEIOUNY%') || '%';
                END IF;
            END IF;
            -- create single array with all results
        
            l_inst_ids := l_inst_id_common MULTISET UNION DISTINCT l_inst_id_dinm;
            -- get INSTITUTION common fields details
            g_error := 'GET EXTERNAL INSTITUTIONS LIST OF ID_INSTITUTION = ' || to_char(i_id_institution);
            pk_alertlog.log_debug('PK_API_BACKOFFICE.INTF_GET_INSTIT: ' || g_error);
            SELECT t_rec_inst_common(instit.id_institution,
                                     instit.instit_name,
                                     instit.instit_type,
                                     instit.abbreviation,
                                     instit.address,
                                     instit.zip_code,
                                     instit.location,
                                     instit.phone_number,
                                     instit.fax_number,
                                     instit.country_name,
                                     instit.email,
                                     instit.instit_fields)
              BULK COLLECT
              INTO o_institution
              FROM (SELECT i.id_institution,
                           pk_translation.get_translation(i_lang, i.code_institution) instit_name,
                           pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) instit_type,
                           i.abbreviation,
                           i.address,
                           i.zip_code,
                           i.location,
                           i.phone_number,
                           i.fax_number,
                           pk_translation.get_translation(i_lang, c.code_country) country_name,
                           ia.email,
                           CAST(MULTISET (SELECT ifd.id_institution,
                                        ifd.id_field_market,
                                        pk_translation.get_translation(i_lang, f.code_field) field_name,
                                        ifd.value field_value,
                                        fm.id_market
                                   FROM institution_field_data ifd
                                  INNER JOIN field_market fm
                                     ON (fm.id_field_market = ifd.id_field_market)
                                  INNER JOIN field f
                                     ON (f.id_field = fm.id_field)
                                  INNER JOIN institution i1
                                     ON (i1.id_institution = ifd.id_institution AND
                                        i1.flg_available = pk_alert_constant.get_available)
                                  WHERE ifd.id_institution = i.id_institution
                                    AND i1.flg_external = i.flg_external
                                    AND fm.id_market = i.id_market) AS t_table_inst_fields) instit_fields
                      FROM institution i
                     INNER JOIN inst_attributes ia
                        ON (ia.id_institution = i.id_institution AND ia.flg_available = pk_alert_constant.get_available)
                     INNER JOIN country c
                        ON (c.id_country = ia.id_country AND c.flg_available = pk_alert_constant.get_available)
                     WHERE i.id_institution IN (SELECT column_value
                                                  FROM TABLE(CAST(l_inst_ids AS table_number)))
                       AND i.flg_available = pk_alert_constant.get_available
                       AND i.id_market = l_id_market
                       AND i.flg_external = i_flg_external) instit;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END intf_get_instit;
    /********************************************************************************************
    * Returns Health Plan Entity created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_health_plan_entity_desc      Health Plan Entity name
    * @param i_flg_available                Health Plan status
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param i_short_name                   Health Plan Entity short name
    * @param i_street                       Health Plan Entity Street
    * @param i_city                         Health Plan Entity City
    * @param i_telephone                    Health Plan Entity Phone number
    * @param i_fax                          Health Plan Entity Fax number
    * @param i_email                        Health Plan Entity E-mail
    * @param i_postal_code                  Health Plan Entity Postal Code
    * @param i_postal_code_city             Health Plan Entity Postal Code City
    * @param o_id_health_plan_entity        Health Plan Entity id
    * @param o_id_health_plan_entity_instit Health Plan Entity Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/10/27
    * @version                       2.6.1.4
    ********************************************************************************************/
    FUNCTION set_health_plan_entity_ext
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_institution               IN institution.id_institution%TYPE,
        i_id_health_plan_entity        IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan_entity_desc      IN VARCHAR2,
        i_flg_available                IN health_plan_entity.flg_available%TYPE,
        i_national_identifier_number   IN health_plan_entity.national_identifier_number%TYPE,
        i_short_name                   IN health_plan_entity.short_name%TYPE,
        i_street                       IN health_plan_entity.street%TYPE,
        i_city                         IN health_plan_entity.city%TYPE,
        i_telephone                    IN health_plan_entity.telephone%TYPE,
        i_fax                          IN health_plan_entity.fax%TYPE,
        i_email                        IN health_plan_entity.email%TYPE,
        i_postal_code                  IN health_plan_entity.postal_code%TYPE,
        i_postal_code_city             IN health_plan_entity.postal_code_city%TYPE,
        o_id_health_plan_entity        OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_id_health_plan_entity_instit OUT health_plan_entity_instit.id_health_plan_entity_instit%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL ADT SET HEALTH_PLAN_ENTITY';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_HEALTH_PLAN_ENTITY_EXT ' || g_error);
    
        IF NOT pk_adt.set_health_plan_entity_ext(i_lang                         => i_lang,
                                                 i_prof                         => i_prof,
                                                 i_id_institution               => i_id_institution,
                                                 i_id_health_plan_entity        => i_id_health_plan_entity,
                                                 i_health_plan_entity_desc      => i_health_plan_entity_desc,
                                                 i_flg_available                => i_flg_available,
                                                 i_national_identifier_number   => i_national_identifier_number,
                                                 i_short_name                   => i_short_name,
                                                 i_street                       => i_street,
                                                 i_city                         => i_city,
                                                 i_telephone                    => i_telephone,
                                                 i_fax                          => i_fax,
                                                 i_email                        => i_email,
                                                 i_postal_code                  => i_postal_code,
                                                 i_postal_code_city             => i_postal_code_city,
                                                 o_id_health_plan_entity        => o_id_health_plan_entity,
                                                 o_id_health_plan_entity_instit => o_id_health_plan_entity_instit,
                                                 o_error                        => o_error)
        THEN
            g_error := 'CALL ADT SET HEALTH_PLAN_ENTITY';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_HEALTH_PLAN_ENTITY_EXT',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_HEALTH_PLAN_ENTITY_EXT',
                                              o_error);
            RETURN FALSE;
    END set_health_plan_entity_ext;
    /********************************************************************************************
    * Returns Health Plan created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan               Health Plan id
    * @param i_health_plan_desc             Health Plan name
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_id_health_plan_type          Health Plan type
    * @param i_flg_available                Health Plan status
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param o_id_health_plan_entity        Health Plan id
    * @param o_id_health_plan_entity_instit Health Plan Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/10/27
    * @version                       2.6.1.4
    ********************************************************************************************/
    FUNCTION set_health_plan_ext
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_institution             IN institution.id_institution%TYPE,
        i_id_health_plan             IN health_plan.id_health_plan%TYPE,
        i_health_plan_desc           IN VARCHAR2,
        i_id_health_plan_entity      IN health_plan.id_health_plan_type%TYPE,
        i_id_health_plan_type        IN health_plan.id_health_plan_type%TYPE,
        i_flg_available              IN health_plan.flg_available%TYPE,
        i_national_identifier_number IN health_plan_entity.national_identifier_number%TYPE,
        o_id_health_plan             OUT health_plan.id_health_plan%TYPE,
        o_id_health_plan_instit      OUT health_plan_instit.id_health_plan_instit%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL ADT SET HEALTH_PLAN';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.SET_HEALTH_PLAN_EXT ' || g_error);
    
        IF NOT pk_adt.set_health_plan_ext(i_lang                       => i_lang,
                                          i_prof                       => i_prof,
                                          i_id_institution             => i_id_institution,
                                          i_id_health_plan             => i_id_health_plan,
                                          i_health_plan_desc           => i_health_plan_desc,
                                          i_id_health_plan_entity      => i_id_health_plan_entity,
                                          i_id_health_plan_type        => i_id_health_plan_type,
                                          i_flg_available              => i_flg_available,
                                          i_national_identifier_number => i_national_identifier_number,
                                          o_id_health_plan             => o_id_health_plan,
                                          o_id_health_plan_instit      => o_id_health_plan_instit,
                                          o_error                      => o_error)
        THEN
            g_error := 'CALL ADT SET HEALTH_PLAN';
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_HEALTH_PLAN_EXT',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_HEALTH_PLAN_EXT',
                                              o_error);
            RETURN FALSE;
    END set_health_plan_ext;
    /************************************************************************************************************
    * Returns True or False
    *
    * @param       i_lang                     Log Language
    * @param      i_id_professional     Professional id (if null update all in the institution)
    * @param      i_id_institution      Institution Id (mandatory)
    * @param      o_profs               output cursor with professional ids
    * @param      o_error               error
    *
    * @return     Boolean 1-true; 2-false;
    * @author     RMGM
    * @version    2.6.0.5
    * @since      2012/01/11
    ***********************************************************************************************************/
    FUNCTION migra_prof_name_formated
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_profs           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call Method';
        IF NOT pk_backoffice.set_prof_name_formated(i_lang, i_id_professional, i_id_institution, o_profs, o_error)
        THEN
            g_error := 'set_prof_name_formated Not OK' || o_error.log_id;
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'migra_prof_name_formated',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'migra_prof_name_formated',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END migra_prof_name_formated;
    /********************************************************************************************
    * Set Professional fields values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_id_institution   Professional institution ID
    * @param i_institution      Institution ID's
    * @param i_fields_market    Fields_market ID's
    * @param i_values           Fields Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  2.6.1.6.1
    * @since                    2012/01/20
    ********************************************************************************************/
    FUNCTION intf_set_prof_fields
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_institution     IN table_number,
        i_fields_market   IN table_number,
        i_values          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market   market.id_market%TYPE;
        l_id_field field_market.id_field_market%TYPE;
        l_fields   table_number := table_number();
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_market
          FROM dual;
    
        FOR a IN 1 .. i_fields_market.count
        LOOP
            SELECT fm.id_field
              INTO l_id_field
              FROM field_market fm
             WHERE fm.id_field_market = i_fields_market(a);
            l_fields.extend;
            l_fields(a) := l_id_field;
        END LOOP;
    
        RETURN intf_set_prof_fields(i_lang            => i_lang,
                                    i_id_professional => i_id_professional,
                                    i_id_market       => l_market,
                                    i_institution     => i_institution,
                                    i_fields          => l_fields,
                                    i_values          => i_values,
                                    o_error           => o_error);
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / MARKET NO DEFINED OR FIELD NOT DEFINED FOR THE MARKET',
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'INTF_SET_PROF_FIELDS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END intf_set_prof_fields;
    /********************************************************************************************
    * Get Institution Health Region for ACSS
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution Identifier
    * @param o_error                 error
    *
    * @return                        Institution Health Region (account to ACSS)
    *
    * @author                        Rui Gomes
    * @version                       2.5.1.7
    * @since                         2011/08/18
    ********************************************************************************************/
    FUNCTION get_instit_ars
    (
        i_lang  IN language.id_language%TYPE,
        i_inst  IN institution.id_institution%TYPE,
        o_error OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_ars_code    VARCHAR2(100);
        l_account_ars accounts.id_account%TYPE := 52;
    
        l_iaccount_res NUMBER;
    BEGIN
        g_error := 'GET INSTITUTION ARS FOR REPORTS AND MCDT REFERRAL';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_INSTIT_ARS: ' || g_error);
    
        SELECT nvl(COUNT(*), 0)
          INTO l_iaccount_res
          FROM institution_accounts ia
         INNER JOIN accounts a
            ON (a.id_account = ia.id_account AND a.flg_available = pk_alert_constant.g_available)
         WHERE ia.id_account = l_account_ars
           AND ia.id_institution = i_inst;
    
        IF l_iaccount_res > 0
        THEN
        
            SELECT ia.value
              INTO l_ars_code
              FROM institution_accounts ia
             INNER JOIN accounts a
                ON (a.id_account = ia.id_account AND a.flg_available = pk_alert_constant.g_available)
             WHERE ia.id_account = l_account_ars
               AND ia.id_institution = i_inst;
        ELSE
            l_ars_code := '0';
        END IF;
    
        RETURN l_ars_code;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_INSTIT_ARS',
                                              o_error);
            RETURN NULL;
    END get_instit_ars;
    /********************************************************************************************
    * Get Professional account values
    *
    * @param i_lang             Preferred language ID
    * @param i_prof_id          Professional ID
    * @param i_institution      Institution ID
    * @param i_accounts         Affiliations ID
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2012/02/17
    ********************************************************************************************/
    FUNCTION get_prof_account_val
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_account     IN accounts.id_account%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_backoffice.get_prof_account_val(i_lang, i_prof_id, i_institution, i_account, o_error);
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_ACCOUNT_VAL',
                                              o_error);
            RETURN NULL;
    END get_prof_account_val;
    /********************************************************************************************
    * Get Institution accounts values
    *
    * @param i_lang             Preferred language ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2012/02/17
    ********************************************************************************************/
    FUNCTION get_inst_account_val
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_account     IN accounts.id_account%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_backoffice.get_inst_account_val(i_lang, i_institution, i_account, o_error);
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_INST_ACCOUNT_VAL',
                                              o_error);
            RETURN NULL;
    END get_inst_account_val;
    /** @headcom
    * Public Function. Associate Specialties to a Professional
    *
    *
    * @param      I_LANG                     Language identification
    * @param      I_ID_PROF                  Professional identification
    * @param      i_id_institution           Institution identification
    * @param      i_id_dep_clin_serv         Relation between departments and clinical services list
    * @param      i_flg                      Flag showing if is to remove or insert new prof dcs
    * @param      O_ERROR                    Error
    *
    * @value      i_flg                      {*} 'Y' yes {*} 'N' No
    *
    * @return     boolean
    * @author     RMGM
    * @version    0.1
    * @since      2013/01/31
    */
    FUNCTION set_prof_specialties
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg              IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT
            pk_backoffice.set_prof_specialties(i_lang, i_id_prof, i_id_institution, i_id_dep_clin_serv, i_flg, o_error)
        THEN
            g_error := 'ENABLE TO SET PROF_DEP_CLIN_SERV DUE TO ERROR ' || o_error.log_id;
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_PROF_SPECIALTIES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_prof_specialties;
    /********************************************************************************************
    * Get professional work phone
    *
    * @param i_lang              Language id (log)
    * @param i_id_professional   Professional identifier
    * @param o_work_phone        Professional work phone
    * @param o_error             Error
    *
    * @return boolean
    *
    * @author                    JTS
    * @version                   26371
    * @since                     2013/08/06
    ********************************************************************************************/
    FUNCTION get_prof_work_phone
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_work_phone      OUT professional.work_phone%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET WORK PHONE FROM PROFESSIONAL';
        SELECT p.work_phone
          INTO o_work_phone
          FROM professional p
         WHERE p.id_professional = i_id_professional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_WORK_PHONE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_work_phone;
    /********************************************************************************************
    * Get Professional CBO ID
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional Type Identifier
    * @param o_error                 error
    *
    * @return                        CBO code
    *
    * @author                        Rui Gomes
    * @version                       2.5.2.7
    * @since                         2013/01/28
    ********************************************************************************************/
    FUNCTION get_prof_cbo_id
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'GET PROFESSIONAL CBO CODE FOR REPORTS AND MCDT REFERRAL';
        RETURN pk_backoffice.get_prof_cbo_id(i_lang, i_prof, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_CBO_ID',
                                              o_error);
            dbms_output.put_line(o_error.log_id);
            RETURN NULL;
    END get_prof_cbo_id;
    FUNCTION set_institution_administrator
    (
        i_lang          IN language.id_language%TYPE,
        i_software      IN software.id_software%TYPE,
        i_id_prof       IN professional.id_professional%TYPE,
        i_id_inst       IN institution.id_institution%TYPE,
        i_name          IN professional.name%TYPE,
        i_title         IN professional.title%TYPE,
        i_nick_name     IN professional.nick_name%TYPE,
        i_gender        IN professional.gender%TYPE,
        i_dt_birth      IN VARCHAR2,
        i_email         IN professional.email%TYPE,
        i_work_phone    IN professional.num_contact%TYPE,
        i_cell_phone    IN professional.cell_phone%TYPE,
        i_fax           IN professional.fax%TYPE,
        i_first_name    IN professional.first_name%TYPE,
        i_middle_name   IN professional.middle_name%TYPE,
        i_last_name     IN professional.last_name%TYPE,
        i_id_cat        IN category.id_category%TYPE,
        i_commit_at_end IN BOOLEAN,
        o_id_prof       OUT professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        my_exception EXCEPTION;
    BEGIN
        IF NOT pk_backoffice.set_institution_administrator(i_lang,
                                                           i_software,
                                                           i_id_prof,
                                                           i_id_inst,
                                                           i_name,
                                                           i_title,
                                                           i_nick_name,
                                                           i_gender,
                                                           i_dt_birth,
                                                           i_email,
                                                           i_work_phone,
                                                           i_cell_phone,
                                                           i_fax,
                                                           i_first_name,
                                                           NULL,
                                                           i_middle_name,
                                                           i_last_name,
                                                           i_id_cat,
                                                           i_commit_at_end,
                                                           o_id_prof,
                                                           o_error)
        THEN
            g_error := 'ERROR SETTING SYSTEM ADMINISTRATOR';
            RAISE my_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'SET_INST_ADM',
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_INSTITUTION_ADMINISTRATOR',
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_API_BACKOFFICE',
                                   'SET_INSTITUTION_ADMINISTRATOR');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_institution_administrator;
    /* create user profile*/
    FUNCTION set_admin_template_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_inst             IN table_number,
        i_soft             IN table_number,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_templ            IN table_number,
        i_commit_at_end    IN BOOLEAN,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_backoffice.set_template_list(i_lang,
                                               i_id_prof,
                                               i_inst,
                                               i_soft,
                                               i_id_dep_clin_serv,
                                               i_templ,
                                               i_commit_at_end,
                                               o_error)
        THEN
            g_error := 'PK_BACKOFFICE ERROR ' || o_error.log_id;
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_ADMIN_TEMPLATE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'SET_ADMIN_TEMPLATE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_admin_template_list;
    /********************************************************************************************
    * Get Service information for reports presentation (Phone and fax number, responsible physicians)
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_institution            Institution ID
    * @param i_id_department          Service ID
    * @param o_fax_number             Fax Number
    * @param o_phone_number           Phone Number
    * @param o_prof_id_list           List of professionals ids
    * @param o_prof_desc_list         list of professional names concatenated
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/12
    **********************************************************************************************/
    FUNCTION get_service_detail_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_department           IN department.id_department%TYPE,
        o_fax_number              OUT department.fax_number%TYPE,
        o_phone_number            OUT department.phone_number%TYPE,
        o_prof_id_list            OUT table_number,
        o_prof_name_list          OUT table_varchar,
        o_prof_desc_list          OUT VARCHAR2,
        o_prof_aff_list           OUT table_varchar,
        o_desc_prof_aff           OUT VARCHAR2,
        o_service_name            OUT VARCHAR2,
        o_prof_id_not_resp_list   OUT table_number,
        o_prof_name_not_resp_list OUT table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        --l_temp_desc table_varchar := table_varchar();
    BEGIN
        o_prof_aff_list := table_varchar();
        BEGIN
            g_error := 'GET CONTACTS FOR SERVICE ' || i_id_department;
            SELECT d.phone_number, d.fax_number, pk_translation.get_translation(i_lang, d.code_department) service_name
              INTO o_phone_number, o_fax_number, o_service_name
              FROM department d
             WHERE d.id_department = i_id_department;
        EXCEPTION
            WHEN no_data_found THEN
                o_phone_number := NULL;
                o_fax_number   := NULL;
        END;
        g_error := 'GET RESPONSIBLE LIST FOR SERVICE ' || i_id_department;
        IF NOT pk_backoffice.get_serv_prof_responsible(i_lang,
                                                       i_id_institution,
                                                       i_id_department,
                                                       'C',
                                                       o_prof_id_list,
                                                       o_prof_name_list,
                                                       o_error)
        THEN
            RAISE l_exception;
        ELSE
            o_prof_desc_list := pk_utils.concat_table(o_prof_name_list, chr(10));
            o_desc_prof_aff  := pk_backoffice.get_prof_resp_af_data(i_lang, o_prof_id_list, i_id_institution);
            FOR i IN 1 .. o_prof_id_list.count
            LOOP
                o_prof_aff_list.extend;
                o_prof_aff_list(i) := pk_backoffice.get_prof_account_val(i_lang,
                                                                         o_prof_id_list(i),
                                                                         i_id_institution,
                                                                         88,
                                                                         o_error);
            END LOOP;
        END IF;
    
        g_error := 'Fetching list of professional not responsible for i_id_department - ' || i_id_department;
        IF NOT pk_backoffice.get_serv_prof_not_responsible(i_lang,
                                                           i_id_institution,
                                                           i_id_department,
                                                           o_prof_id_not_resp_list,
                                                           o_prof_name_not_resp_list,
                                                           o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'get_service_detail_info',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'get_service_detail_info',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_service_detail_info;
    /*
    Method that set prof functionalities
    */
    FUNCTION intf_set_prof_func_all
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN prof_func.id_professional%TYPE,
        i_institution     IN table_number,
        i_func            IN table_number,
        i_change          IN table_varchar,
        o_id_prof_func    OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_id_prof_func := table_number();
        RETURN pk_backoffice.set_prof_func_all(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_id_professional => i_id_professional,
                                               i_institution     => i_institution,
                                               i_func            => i_func,
                                               i_change          => i_change,
                                               i_commit_at_end   => FALSE,
                                               o_id_prof_func    => o_id_prof_func,
                                               o_error           => o_error);
    END intf_set_prof_func_all;
    /********************************************************************************************
    * Set Professional BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2014/04/23
    ********************************************************************************************/
    FUNCTION intf_set_professional_br
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_prof            IN professional.id_professional%TYPE,
        i_title              IN professional.title%TYPE,
        i_first_name         IN professional.first_name%TYPE,
        i_middle_name        IN professional.middle_name%TYPE,
        i_last_name          IN professional.last_name%TYPE,
        i_nick_name          IN professional.nick_name%TYPE,
        i_initials           IN professional.initials%TYPE,
        i_dt_birth           IN VARCHAR2,
        i_gender             IN professional.gender%TYPE,
        i_marital_status     IN professional.marital_status%TYPE,
        i_id_category        IN category.id_category%TYPE,
        i_id_speciality      IN professional.id_speciality%TYPE,
        i_num_order          IN professional.num_order%TYPE,
        i_upin               IN professional.upin%TYPE,
        i_dea                IN professional.dea%TYPE,
        i_id_cat_surgery     IN category.id_category%TYPE,
        i_num_mecan          IN prof_institution.num_mecan%TYPE,
        i_id_lang            IN prof_preferences.id_language%TYPE,
        i_flg_state          IN prof_institution.flg_state%TYPE,
        i_address            IN professional.address%TYPE,
        i_city               IN professional.city%TYPE,
        i_district           IN professional.district%TYPE,
        i_zip_code           IN professional.zip_code%TYPE,
        i_id_country         IN professional.id_country%TYPE,
        i_work_phone         IN professional.work_phone%TYPE,
        i_num_contact        IN professional.num_contact%TYPE,
        i_cell_phone         IN professional.cell_phone%TYPE,
        i_fax                IN professional.fax%TYPE,
        i_email              IN professional.email%TYPE,
        i_adress_type        IN professional.adress_type%TYPE,
        i_id_cpf             IN professional.id_cpf%TYPE,
        i_id_cns             IN professional.id_cns%TYPE,
        i_mother_name        IN professional.mother_name%TYPE,
        i_father_name        IN professional.father_name%TYPE,
        i_id_gstate_birth    IN professional.id_geo_state_birth%TYPE,
        i_id_city_birth      IN professional.id_district_birth%TYPE,
        i_code_race          IN professional.code_race%TYPE,
        i_code_school        IN professional.code_scoolarship%TYPE,
        i_flg_in_school      IN professional.flg_in_school%TYPE,
        i_code_logr          IN professional.code_logr_type%TYPE,
        i_door_num           IN professional.door_number%TYPE,
        i_address_ext        IN professional.address_extension%TYPE,
        i_id_gstate_adress   IN professional.id_geo_state_adress%TYPE,
        i_id_city_adress     IN professional.id_district_adress%TYPE,
        i_adress_area        IN professional.adress_area%TYPE,
        i_code_banq          IN professional.code_banq%TYPE,
        i_desc_agency        IN professional.desc_banq_ag%TYPE,
        i_banq_account       IN professional.id_banq_account%TYPE,
        i_code_certif        IN professional.code_certificate%TYPE,
        i_balcon_certif      IN professional.desc_balcony%TYPE,
        i_book_certif        IN professional.desc_book%TYPE,
        i_page_certif        IN professional.desc_page%TYPE,
        i_term_certif        IN professional.desc_term%TYPE,
        i_date_certif        IN VARCHAR2,
        i_id_document        IN professional.id_document%TYPE,
        i_balcon_doc         IN professional.code_emitant_cert%TYPE,
        i_id_gstate_doc      IN professional.id_geo_state_doc%TYPE,
        i_date_doc           IN VARCHAR2,
        i_code_crm           IN professional.code_emitant_crm%TYPE,
        i_id_gstate_crm      IN professional.id_geo_state_crm%TYPE,
        i_code_family_status IN professional.code_family_status%TYPE,
        i_code_doc_type      IN professional.code_doc_type%TYPE,
        i_prof_ocp           IN professional.id_prof_formation%TYPE,
        i_bond               IN prof_institution.id_professional_bond%TYPE,
        i_work_amb           IN prof_institution.work_schedule_amb%TYPE,
        i_work_inp           IN prof_institution.work_schedule_inp%TYPE,
        i_work_oth           IN prof_institution.work_schedule_other%TYPE,
        i_flg_sus            IN prof_institution.flg_sus_app%TYPE,
        i_other_doc_desc     IN professional.other_doc_desc%TYPE,
        i_healht_plan        IN professional.id_health_plan%TYPE,
        i_suffix             IN professional.suffix%TYPE,
        i_contact_det        IN prof_institution.contact_detail%TYPE,
        i_county             IN professional.county%TYPE,
        i_other_adress       IN professional.address_other_name%TYPE,
        o_id_prof            OUT professional.id_professional%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_backoffice_api_ui.set_professional_br(i_lang,
                                                        i_id_institution,
                                                        i_id_prof,
                                                        i_title,
                                                        i_first_name,
                                                        i_middle_name,
                                                        i_last_name,
                                                        i_nick_name,
                                                        i_initials,
                                                        i_dt_birth,
                                                        i_gender,
                                                        i_marital_status,
                                                        i_id_category,
                                                        i_id_speciality,
                                                        NULL,
                                                        i_num_order,
                                                        i_upin,
                                                        i_dea,
                                                        i_id_cat_surgery,
                                                        i_num_mecan,
                                                        i_id_lang,
                                                        i_flg_state,
                                                        i_address,
                                                        i_city,
                                                        i_district,
                                                        i_zip_code,
                                                        i_id_country,
                                                        i_work_phone,
                                                        i_num_contact,
                                                        i_cell_phone,
                                                        i_fax,
                                                        i_email,
                                                        FALSE,
                                                        i_adress_type,
                                                        i_id_cpf,
                                                        i_id_cns,
                                                        i_mother_name,
                                                        i_father_name,
                                                        i_id_gstate_birth,
                                                        i_id_city_birth,
                                                        i_code_race,
                                                        i_code_school,
                                                        i_flg_in_school,
                                                        i_code_logr,
                                                        i_door_num,
                                                        i_address_ext,
                                                        i_id_gstate_adress,
                                                        i_id_city_adress,
                                                        i_adress_area,
                                                        i_code_banq,
                                                        i_desc_agency,
                                                        i_banq_account,
                                                        i_code_certif,
                                                        i_balcon_certif,
                                                        i_book_certif,
                                                        i_page_certif,
                                                        i_term_certif,
                                                        i_date_certif,
                                                        i_id_document,
                                                        i_balcon_doc,
                                                        i_id_gstate_doc,
                                                        i_date_doc,
                                                        i_code_crm,
                                                        i_id_gstate_crm,
                                                        i_code_family_status,
                                                        i_code_doc_type,
                                                        i_prof_ocp,
                                                        i_bond,
                                                        i_work_amb,
                                                        i_work_inp,
                                                        i_work_oth,
                                                        i_flg_sus,
                                                        i_other_doc_desc,
                                                        i_healht_plan,
                                                        NULL,
                                                        i_suffix,
                                                        i_contact_det,
                                                        i_county,
                                                        i_other_adress,
                                                        o_id_prof,
                                                        o_error);
    
    END intf_set_professional_br;
    /* Method that returns CDA team members information */
    FUNCTION get_cda_team_member
    (
        i_lang         IN language.id_language%TYPE,
        io_prof_id     IN OUT table_number,
        i_inst_id      IN institution.id_institution%TYPE,
        o_prof_name    OUT table_varchar,
        o_prof_phone   OUT table_varchar,
        o_prof_cat     OUT table_varchar,
        o_inst_name    OUT translation.desc_lang_1%TYPE,
        o_inst_npi     OUT institution_accounts.value%TYPE,
        o_inst_address OUT institution.address%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        o_prof_name  := table_varchar();
        o_prof_phone := table_varchar();
        o_prof_cat   := table_varchar();
        FOR i IN 1 .. io_prof_id.count
        LOOP
            o_prof_name.extend;
            o_prof_phone.extend;
            o_prof_cat.extend;
        
            g_error := 'GET PROFESSIONAL NAME ' || io_prof_id(i);
            o_prof_name(i) := pk_prof_utils.get_name(i_lang, io_prof_id(i));
        
            g_error := 'GET PROFESSIONAL PHONE NUMBER ' || io_prof_id(i);
            o_prof_phone(i) := pk_prof_utils.get_work_phone(i_lang, io_prof_id(i));
        
            g_error := 'GET PROFESSIONAL CATEGORY ' || io_prof_id(i);
            o_prof_cat(i) := pk_prof_utils.get_desc_category(i_lang, profissional(0, 0, 0), io_prof_id(i), i_inst_id);
        END LOOP;
    
        g_error := 'GET INSTITUTION NAME ' || i_inst_id;
        IF NOT pk_utils.get_institution_name(i_lang, i_inst_id, o_inst_name, o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error    := 'GET INSTITUTION NPI ' || i_inst_id;
        o_inst_npi := pk_api_backoffice.get_inst_account_val(i_lang, i_inst_id, g_account_npi, o_error);
    
        g_error        := 'GET INSTITUTION ADDRESS ' || i_inst_id;
        o_inst_address := pk_utils.get_institution_address(i_lang, i_inst_id);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'get_cda_team_member',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'get_cda_team_member',
                                              o_error);
            RETURN FALSE;
    END get_cda_team_member;
    /*Save zipped report file, go to next status and generate alert*/
    FUNCTION save_req_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        i_file       IN BLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_backoffice_cda.save_req_report(i_lang, i_prof, i_id_cda_req, i_prof.institution, i_file, o_error);
    END save_req_report;
    /********************************************************************************************
    * Cancel CDA requests
    *
    * @param i_lang
    * @param i_id_cda_req
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION cancel_cda_req
    (
        i_lang       IN language.id_language%TYPE,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CANCEL REQUEST ' || i_id_cda_req;
        RETURN pk_backoffice_cda.cancel_cda_req(i_lang, i_id_cda_req, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_CDA_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_cda_req;
    /** @headcom
    * Public Function. Get certification identifiers
    *
    * @param      I_LANG                   Identifica??o do Idioma
    * @param      i_id_institution         Identificador da institui??o
    * @param      io_id_software           Lista de modulos de identificadores de software
    * @param      o_cert_id                Valor do identificador de certifica??o
    * @param      o_error                  tipifica??o de Erro
    *
    * @return     boolean
    * @author     RMGM
    * @version    2.6.4.0.2
    * @since      2014/05/19
    */
    FUNCTION get_cms_ehr_id
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        io_id_software   IN OUT table_number,
        o_cert_id        OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice_cda.get_cms_ehr_id(i_lang, i_id_institution, io_id_software, o_cert_id, o_error);
    END get_cms_ehr_id;
    /** @headcom
    * Public Function. Get CDA request current status
    *
    * @param      i_id_cda_req             CDA request identifier
    *
    * @return     Varchar Status ([P]rocessing,R[eady],C[anceled],F[Finished])
    * @author     RMGM
    * @version    2.6.4.0.2
    * @since      2014/05/19
    */
    FUNCTION get_cda_req_status(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_backoffice_cda.get_cda_req_det_status(i_id_cda_req => i_id_cda_req);
    END get_cda_req_status;
    /********************************************************************************************
    * Change message status
    *
    * @param i_lang                                      Prefered language ID
    * @param i_id_msg                                    Message identifier
    * @param i_new_status                                New message status
    * @param o_error                                     Error type identifier
    *
    *
    * @return                  Boolean (true or false)
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/20
    ********************************************************************************************/
    FUNCTION intf_change_msg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_id_msg     IN pending_issue_message.id_pending_issue_message%TYPE,
        i_new_status IN pending_issue_sender.flg_status_sender%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_sender   pending_issue_sender.flg_sender%TYPE := NULL;
        l_msg_location VARCHAR2(1 CHAR) := NULL;
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_backoffice_pending_issues.get_message_sender(i_id_msg, l_msg_sender)
        THEN
            RETURN FALSE;
        ELSE
            SELECT decode(l_msg_sender, g_patient_sender, 'O', 'I')
              INTO l_msg_location
              FROM dual;
            IF i_new_status = g_read_status
            THEN
                IF NOT pk_backoffice_pending_issues.set_status_read(i_lang, i_id_msg, l_msg_location, o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSIF i_new_status = g_reply_status
            THEN
                IF NOT pk_backoffice_pending_issues.set_status_reply(i_lang, i_id_msg, l_msg_location, o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSIF i_new_status = g_sent_status
            THEN
                IF NOT pk_backoffice_pending_issues.set_status_sent(i_lang, i_id_msg, l_msg_location, o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSIF i_new_status = g_cancel_status
            THEN
                IF NOT pk_backoffice_pending_issues.set_status_cancel(i_lang, i_id_msg, l_msg_location, o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_CHANGE_MSG_STATUS',
                                              o_error);
            RETURN FALSE;
    END intf_change_msg_status;
    /********************************************************************************************
    * Set New Messages messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_flg_from                                     DEfinition for message sender (F - facility professional or P - patient)
    * @param i_rep_str                                     Legal representative text
    * @param i_id_prof                                     profissional type
    * @param i_id_patient                                  Patient ID
    * @param i_msg_subject                                 Mesage title or subject
    * @param i_msg_body                                    MEssage body or text max 1000 char
    * @param i_id_msg_rep                                  If reply need message parent id
    * @param i_id_thread                                   If reply need message thread id
    * @param o_new_msg_id                                  New message identification
    * @param o_error                                     Error type identifier
    *
    *
    * @return                  Boolean (true or false)
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/20
    ********************************************************************************************/
    FUNCTION intf_set_message
    (
        i_lang        IN language.id_language%TYPE,
        i_flg_from    IN VARCHAR2,
        i_rep_str     IN VARCHAR2,
        i_id_prof     IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_msg_subject IN VARCHAR2,
        i_msg_body    IN CLOB,
        i_id_msg_rep  IN pending_issue_message.id_pending_issue_message%TYPE,
        i_id_thread   IN OUT pending_issue_message.id_pending_issue%TYPE,
        i_commit      IN VARCHAR2,
        o_new_msg_id  OUT pending_issue_message.id_pending_issue_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_backoffice_pending_issues.set_message(i_lang,
                                                        i_flg_from,
                                                        i_rep_str,
                                                        i_id_prof,
                                                        i_id_patient,
                                                        i_msg_subject,
                                                        i_msg_body,
                                                        i_id_msg_rep,
                                                        i_id_thread,
                                                        i_commit,
                                                        o_new_msg_id,
                                                        o_error);
    
    END intf_set_message;
    /********************************************************************************************
    * Get Message Boxes
    *
    * @param i_lang                                      Prefered language ID
    * @param i_patient                                   Patient identifier
    * @param i_msg_type                                  type of request (inbox, outbox or cancelbox)
    * @param o_ret_val                                   taboel of t_tbl_msg type
    * @param o_error                                     Error type identifier
    *
    *
    * @return                  Boolean (true or false)
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/20
    ********************************************************************************************/
    FUNCTION intf_get_pat_messages
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_msg_type IN VARCHAR2,
        o_ret_val  OUT t_tbl_msg,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_temp_inb  t_tbl_msg;
        l_temp_outb t_tbl_msg;
    BEGIN
        IF lower(i_msg_type) = lower('inbox')
        THEN
            SELECT t_rec_msg(msg.thread_id,
                             msg.msg_id,
                             msg.msg_subject,
                             msg.msg_body,
                             msg.id_sender,
                             msg.name_sender,
                             msg.id_receiver,
                             msg.name_receiver,
                             msg.thread_status,
                             msg.msg_status_sender,
                             msg.msg_status_receiver,
                             msg.thread_level,
                             msg.msg_date,
                             msg.flg_sender,
                             msg.repr_str)
              BULK COLLECT
              INTO o_ret_val
              FROM TABLE(pk_backoffice_pending_issues.get_patient_inbox(i_lang, i_patient)) msg
             WHERE msg.msg_status_receiver != g_cancel_status;
        ELSIF lower(i_msg_type) = lower('outbox')
        THEN
            SELECT t_rec_msg(msg.thread_id,
                             msg.msg_id,
                             msg.msg_subject,
                             msg.msg_body,
                             msg.id_sender,
                             msg.name_sender,
                             msg.id_receiver,
                             msg.name_receiver,
                             msg.thread_status,
                             msg.msg_status_sender,
                             msg.msg_status_receiver,
                             msg.thread_level,
                             msg.msg_date,
                             msg.flg_sender,
                             msg.repr_str)
              BULK COLLECT
              INTO o_ret_val
              FROM TABLE(pk_backoffice_pending_issues.get_patient_outbox(i_lang, i_patient)) msg
             WHERE msg.msg_status_sender != g_cancel_status;
        ELSIF lower(i_msg_type) = lower('cancelbox')
        THEN
        
            SELECT t_rec_msg(msg.thread_id,
                             msg.msg_id,
                             msg.msg_subject,
                             msg.msg_body,
                             msg.id_sender,
                             msg.name_sender,
                             msg.id_receiver,
                             msg.name_receiver,
                             msg.thread_status,
                             msg.msg_status_sender,
                             msg.msg_status_receiver,
                             msg.thread_level,
                             msg.msg_date,
                             msg.flg_sender,
                             msg.repr_str)
              BULK COLLECT
              INTO l_temp_inb
              FROM (SELECT *
                      FROM TABLE(pk_backoffice_pending_issues.get_patient_inbox(i_lang, i_patient)) t
                     WHERE t.msg_status_receiver = g_cancel_status) msg;
        
            SELECT t_rec_msg(msg.thread_id,
                             msg.msg_id,
                             msg.msg_subject,
                             msg.msg_body,
                             msg.id_sender,
                             msg.name_sender,
                             msg.id_receiver,
                             msg.name_receiver,
                             msg.thread_status,
                             msg.msg_status_sender,
                             msg.msg_status_receiver,
                             msg.thread_level,
                             msg.msg_date,
                             msg.flg_sender,
                             msg.repr_str)
              BULK COLLECT
              INTO l_temp_outb
              FROM (SELECT *
                      FROM TABLE(pk_backoffice_pending_issues.get_patient_outbox(i_lang, i_patient)) t
                     WHERE t.msg_status_sender = g_cancel_status) msg;
        
            o_ret_val := l_temp_outb MULTISET UNION l_temp_inb;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'INTF_GET_PAT_MESSAGES',
                                              o_error);
            RETURN FALSE;
    END intf_get_pat_messages;
    /********************************************************************************************
    * Get message thread
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_thread                                 Thread message identifier
    * @param i_thread_level                               maximum thread level (message being seen)
    * @param o_ret_val                               table of results
    *
    * @return                 table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_message_thread
    (
        i_lang         IN language.id_language%TYPE,
        i_id_thread    IN pending_issue_message.id_pending_issue%TYPE,
        i_thread_level IN pending_issue_message.thread_level%TYPE,
        o_ret_val      OUT t_tbl_msg,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT t_rec_msg(msg.thread_id,
                         msg.msg_id,
                         msg.msg_subject,
                         msg.msg_body,
                         msg.id_sender,
                         msg.name_sender,
                         msg.id_receiver,
                         msg.name_receiver,
                         msg.thread_status,
                         msg.msg_status_sender,
                         msg.msg_status_receiver,
                         msg.thread_level,
                         msg.msg_date,
                         msg.flg_sender,
                         msg.repr_str)
          BULK COLLECT
          INTO o_ret_val
          FROM TABLE(pk_backoffice_pending_issues.get_message_thread(i_lang, i_id_thread, i_thread_level)) msg;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_MESSAGE_THREAD',
                                              o_error);
            RETURN FALSE;
    END get_message_thread;
    /********************************************************************************************
    * Get Inbox number of unread messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_flg_inbox                                   P (patient) or F (facility professionals)
    * @param i_id_receiver                                Patient or professional context id
    *
    * @return                  Number of unread messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_inbox_count
    (
        i_lang        IN language.id_language%TYPE,
        i_id_receiver IN pending_issue.id_professional%TYPE,
        o_count       OUT NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
        o_count := pk_backoffice_pending_issues.get_inbox_count(i_lang, 'P', i_id_receiver);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_inbox_count;
    /********************************************************************************************
    * Get Institution FINESS identifier
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    *
    * @return                   Value
    *
    * @author                   RMGM
    * @version                  2.6.4.2
    * @since                    2014/09/23
    ********************************************************************************************/
    FUNCTION get_inst_finess
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_backoffice.get_inst_finess(i_lang, i_prof);
    END get_inst_finess;
    /********************************************************************************************
    * Get VHIF data
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    * @param i_inst_nat_prefix  National institution Id context
    * @param i_prof_nat_prefix  National Professional Id context
    * @o_prof_name              professional name
    * @o_prof_spec              professional Speciality
    * @o_prof_role              professional Role
    * @o_prof_idnat             professional National identifier
    * @o_inst_type              Institution Type
    * @o_inst_serial            Institution Serial
    * @o_inst_idnat             Institution National identifier
    * @o_prod_vers              alert version
    * @o_sw_name                software Name,
    * @o_sw_cert_id             Software certification identifier
    *
    * @return                   True or False
    *
    * @author                   RMGM
    * @version                  2.6.4.2
    * @since                    2014/09/23
    ********************************************************************************************/
    FUNCTION get_prof_vhif_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_prof_name   OUT professional.name%TYPE,
        o_prof_spec   OUT speciality.id_content%TYPE,
        o_prof_role   OUT category.id_content%TYPE,
        o_prof_idnat  OUT table_varchar,
        o_inst_type   OUT institution.flg_type%TYPE,
        o_inst_serial OUT institution.id_institution%TYPE,
        o_inst_idnat  OUT table_varchar,
        o_prod_vers   OUT alert_version.version%TYPE,
        o_sw_name     OUT software.intern_name%TYPE,
        o_sw_cert_id  OUT sys_config.value%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_prof_vhif_data(i_lang,
                                                i_prof,
                                                o_prof_name,
                                                o_prof_spec,
                                                o_prof_role,
                                                o_prof_idnat,
                                                o_inst_type,
                                                o_inst_serial,
                                                o_inst_idnat,
                                                o_prod_vers,
                                                o_sw_name,
                                                o_sw_cert_id,
                                                o_error);
    END get_prof_vhif_data;

    /********************************************************************************************
    * Get all professionals allocated for a department
    *
    * @param i_lang            Prefered language ID
    * @param i_prof            Professional Array Identifier
    * @param i_id_department   Department identifier
    *
    * @o_list                  List of professionals
    * @o_error                 Error object
    *
    * @author                  GS
    * @version                 2.6.5
    * @since                   2015/05/12
    ********************************************************************************************/
    PROCEDURE get_prof_list_by_department
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) IS
    BEGIN
        g_error := 'Fetching list of professional for i_id_department - ' || i_id_department;
        OPEN o_list FOR
            SELECT pdcs.id_professional,
                   pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => pdcs.id_professional) prof_name
              FROM prof_dep_clin_serv pdcs
             WHERE pdcs.id_institution = i_prof.institution
               AND EXISTS (SELECT 1
                      FROM dep_clin_serv dcs
                     WHERE dcs.id_department = i_id_department
                       AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                       AND dcs.flg_available = pk_alert_constant.g_yes);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_LIST_BY_DEPARTMENT',
                                              o_error);
    END get_prof_list_by_department;

    /********************************************************************************************
    * Collect all professionals sharing the same hierarchical group of institutions
    *
    * @param i_lang            Prefered language ID
    * @param i_prof            Professional Array Identifier
    * @param i_prof_type       Type of professional
    *
    * @o_result                  List of professionals
    * @o_error                 Error object
    *
    * @version                 2.6.5
    * @since                   2016-07-01
    ********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_type IN VARCHAR2 DEFAULT 'P',
        o_result    OUT prof_all_inst_list,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_instit_master institution.id_institution%TYPE;
        l_insti_list    table_number := table_number();
    BEGIN
        -- get institution master (tree root)
        SELECT i.id_institution
          INTO l_instit_master
          FROM institution i
         WHERE i.flg_available = 'Y'
           AND i.id_parent IS NULL
         START WITH i.id_institution = i_prof.institution
        CONNECT BY nocycle i.id_institution = PRIOR i.id_parent;
    
        -- get complete tree from root identifier
        SELECT i.id_institution
          BULK COLLECT
          INTO l_insti_list
          FROM institution i
         WHERE i.flg_available = 'Y'
         START WITH i.id_institution = l_instit_master
        CONNECT BY nocycle PRIOR i.id_institution = i.id_parent;
    
        OPEN o_result FOR
            SELECT p.id_professional,
                   p.name,
                   pk_backoffice.get_prof_photo_url(i_lang, p.id_professional) photo,
                   p.id_speciality,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE s.id_speciality = p.id_speciality) desc_speciality,
                   ui.login username
              FROM professional p
              JOIN ab_user_info ui
                ON (ui.id_ab_user_info = p.id_professional)
             WHERE ui.login IS NOT NULL
               AND EXISTS
             (SELECT 0
                      FROM prof_institution pi
                     INNER JOIN prof_profile_template ppt
                        ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
                     INNER JOIN profile_template pt
                        ON (pt.id_profile_template = ppt.id_profile_template)
                     WHERE pi.id_professional = p.id_professional
                       AND pi.id_institution IN (SELECT /*+ opt_estimate (inst rows = 1)*/
                                                  column_value
                                                   FROM TABLE(l_insti_list) inst)
                       AND pi.dt_end_tstz IS NULL
                       AND pi.flg_state = 'A'
                       AND pi.flg_external = 'N'
                       AND (pt.flg_group = i_prof_type OR i_prof_type IS NULL));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_EXT_PROF',
                                              'GET_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_prof_list;
	
	/********************************************************************************************
    * Get professional from username
    *
    * @param i_lang            Prefered language ID
    * @param i_prof            Professional Array Identifier
    * @param i_username        Username of professional
    *
    * @o_id_prof               Id Professional
    * @o_error                 Error object
    *
    * @version                 2.8.4.0
    * @since                   2022-09-19
    ********************************************************************************************/
    FUNCTION get_prof_by_username
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_username  IN VARCHAR2,
        o_id_prof   OUT sys_user.id_user%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
      
        SELECT su.id_user
        INTO o_id_prof
        FROM sys_user su
        WHERE su.desc_user = i_username;
        
        RETURN TRUE;
        
     EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_BY_USERNAME',
                                              o_error);
            RETURN FALSE;
    END get_prof_by_username;

    /**
    * Public Function. Get all dep_clin_serv id to a Professional
    *
    * @param i_lang                     Language identification
    * @param i_id_prof                  Professional identification
    * @param i_id_institution           Institution identification
    * @param o_id_dep_clin_serv         dep_clin_serv id list
    * @param o_error                    Error
    *
    * @return                           True or False
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/05
    */
    FUNCTION get_prof_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        o_id_dep_clin_serv OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_prof_dcs(i_lang             => i_lang,
                                          i_id_prof          => i_id_prof,
                                          i_id_institution   => i_id_institution,
                                          o_id_dep_clin_serv => o_id_dep_clin_serv,
                                          o_error            => o_error);
    END get_prof_dcs;

    /**
    * Public Function. Associate Specialties to a Professional without commit
    *
    * @param I_LANG                     Language identification
    * @param I_ID_PROF                  Professional identification
    * @param i_id_institution           Institution identification
    * @param i_id_dep_clin_serv         Relation between departments and clinical services
    * @param i_flg                      Flag
    * @param O_ERROR                    Error
    *
    * @value i_flg                      {*} 'Y' yes {*} 'N' No
    *
    * @return                           boolean
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/15
    */
    FUNCTION set_prof_specialties_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg              IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_prof_specialties_no_commit(i_lang             => i_lang,
                                                            i_id_prof          => i_id_prof,
                                                            i_id_institution   => i_id_institution,
                                                            i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                            i_flg              => i_flg,
                                                            o_error            => o_error);
    END set_prof_specialties_no_commit;

    /**
    * Public Function. Insert New Institution Service OR Update Institution Service Information
    *
    * @param i_lang                     Language identification
    * @param i_id_department            Service identification
    * @param i_id_institution           Institution identification
    * @param i_desc                     Service description
    * @param i_abbreviation             Abreviation
    * @param i_flg_type                 Flg type
    * @param i_id_dept                  Daepartment identification
    * @param i_flg_default              Default department: Y - Yes; N - No
    * @param i_def_priority             (U)rgent/CITO; (N)on Urgent (Deprecated)
    * @param i_collection_by            (L)aboratory or (D)epartment (Deprecated)
    * @param i_flg_available            Available in this implementation? Y/N
    * @param i_floors_institution       Floor institution identifier
    * @param i_change                   Change floor_department
    * @param i_id_admission_type        Type of admission
    * @param i_admission_time           Time of admission
    * @param o_id_department            Department identification
    * @param o_id_floors_department     Floor_department id list
    * @param o_error                    Error
    *
    * @value i_flg_type                 {*} 'C' Outpatient {*} 'U' Emergency department {*} 'I' Inpatient {*} 'S' Operating Room 
    *                                   {*} 'A' Analysis lab. {*} 'P' Clinical patalogy lab. {*} 'T' Pathological anatomy lab 
    *                                   {*} 'R' Radiology {*} 'F' Pharmacy. It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    * @value i_flg_default              {*} 'Y' Yes {*} 'N' No                                     
    * @value i_def_priority             {*} 'U' Urgent/CITO {*} 'N' Non Urgent 
    * @value i_collection_by            {*} 'L' Laboratory {*} 'D' Department
    * @value i_flg_available            {*} 'Y' Yes {*} 'N' No
    * @value i_change                   {*} 'Y' Yes {*} 'N' No            
    *
    * @return                           True or False
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/15
    */
    FUNCTION set_department_no_commit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_department        IN department.id_department%TYPE,
        i_id_institution       IN department.id_institution%TYPE,
        i_desc                 IN VARCHAR2,
        i_abbreviation         IN department.abbreviation%TYPE,
        i_flg_type             IN department.flg_type%TYPE,
        i_id_dept              IN department.id_dept%TYPE,
        i_flg_default          IN department.flg_default%TYPE,
        i_def_priority         IN department.flg_priority%TYPE,
        i_collection_by        IN department.flg_collection_by%TYPE,
        i_flg_available        IN department.flg_available%TYPE DEFAULT NULL,
        i_floors_institution   IN table_number,
        i_change               IN table_varchar,
        i_id_admission_type    IN admission_type.id_admission_type%TYPE,
        i_admission_time       IN VARCHAR2,
        o_id_department        OUT department.id_department%TYPE,
        o_id_floors_department OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_department department.id_department%TYPE := i_id_department;
    
    BEGIN
    
        IF l_id_department IS NULL
        THEN
            l_id_department := ts_department.next_key;
        END IF;
    
        RETURN pk_backoffice.set_department_no_commit(i_lang                 => i_lang,
                                                      i_id_department        => l_id_department,
                                                      i_id_institution       => i_id_institution,
                                                      i_desc                 => i_desc,
                                                      i_abbreviation         => i_abbreviation,
                                                      i_flg_type             => i_flg_type,
                                                      i_id_dept              => i_id_dept,
                                                      i_flg_default          => i_flg_default,
                                                      i_def_priority         => i_def_priority,
                                                      i_collection_by        => i_collection_by,
                                                      i_flg_available        => i_flg_available,
                                                      i_floors_institution   => i_floors_institution,
                                                      i_change               => i_change,
                                                      i_id_admission_type    => i_id_admission_type,
                                                      i_admission_time       => i_admission_time,
                                                      o_id_department        => o_id_department,
                                                      o_id_floors_department => o_id_floors_department,
                                                      o_error                => o_error);
    END set_department_no_commit;

    /**
    * Public Function. get_floors_institution
    * 
    * @param i_lang                    Language identification
    * @param i_id_department           Department id
    * @param o_id_floors_institution   id_floors_institution list
    * @param o_error                   Error
    *
    * @return                          True or False
    *
    * @raises                          PL/SQL generic error "OTHERS"
    *
    * @author                          Amanda Lee
    * @version                         2.7.3.6
    * @since                           2018/06/20
    */
    FUNCTION get_floors_institution
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_department         IN floors_department.id_department%TYPE,
        o_id_floors_institution OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_floors_institution(i_lang                  => i_lang,
                                                    i_id_department         => i_id_department,
                                                    o_id_floors_institution => o_id_floors_institution,
                                                    o_error                 => o_error);
    
    END get_floors_institution;

    /********************************************************************************************
    * Public Function. Create or update room
    *
    * @param i_lang                      Language identification
    * @param i_prof                      Professional data
    * @param i_id_room                   Room ID (not null only for the edit operation)
    * @param i_room_name                 Room name
    * @param i_abbreviation              Room abbreviation
    * @param i_category                  Room category
    * @param i_room_type                 Room type
    * @param i_room_service              select room service
    * @param i_room_specialties          list of specialties
    * @param i_flg_selected_spec         Flag that indicates the type of selection of specialties
    * @param i_floors_department         Floors_department id
    * @param i_state                     Room's state
    * @param i_capacity                  Room's patient capacity
    * @param i_rank                      Room's rank
    * @param o_id_room                   Room's id
    * @param o_error                     Error
    *
    * @value i_category                 {*} 'P' l_flg_prof=Y {*} 'R' l_flg_recovery=Y
    *                                   {*} 'L' l_flg_lab=Y  {*} 'W' l_flg_wait=Y
    *                                   {*} 'C' l_flg_wl=Y   {*} 'T' l_flg_transp=Y
    *                                   {*} 'I' l_flg_icu=Y
    * @value i_flg_selected_spec        {*} 'A' All {*} 'N' None {*} 'O' Other
    * @value i_state                    {*} 'A' Active {*} 'I' Inactive
    * 
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/05
    */
    FUNCTION set_room
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_room           IN room.id_room%TYPE,
        i_room_name         IN VARCHAR2,
        i_abbreviation      IN VARCHAR2,
        i_category          IN table_varchar,
        i_room_type         IN room_type.id_room_type%TYPE,
        i_room_service      IN room.id_department%TYPE,
        i_flg_selected_spec IN room.flg_selected_specialties%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        i_state             IN room.flg_available%TYPE,
        i_capacity          IN room.capacity%TYPE,
        i_rank              IN room.rank%TYPE,
        o_id_room           OUT room.id_room%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_room(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_room           => i_id_room,
                                      i_room_name         => i_room_name,
                                      i_abbreviation      => i_abbreviation,
                                      i_category          => i_category,
                                      i_room_type         => i_room_type,
                                      i_room_service      => i_room_service,
                                      i_flg_selected_spec => i_flg_selected_spec,
                                      i_floors_department => i_floors_department,
                                      i_state             => i_state,
                                      i_capacity          => i_capacity,
                                      i_rank              => i_rank,
                                      o_id_room           => o_id_room,
                                      o_error             => o_error);
    END set_room;

    /********************************************************************************************
    * Insert room history record
    *
    * @param i_lang                      Language identification
    * @param i_prof                      Professional data
    * @param i_id_room                   Room ID (not null only for the edit operation)
    * @param i_room_name                 Room name
    * @param i_abbreviation              Room abbreviation
    * @param i_category                  Room category
    * @param i_room_type                 Room type
    * @param i_room_service              select room service
    * @param i_flg_selected_spec         Flag that indicates the type of selection of specialties
    * @param i_floors_department         Floors_department id
    * @param i_state                     Room's state
    * @param i_capacity                  Room's patient capacity
    * @param i_rank                      Room's rank
    * @param o_id_room_hist              Room's change_hist id
    * @param o_error                     Error
    *
    * @value i_category                 {*} 'P' l_flg_prof=Y {*} 'R' l_flg_recovery=Y
    *                                   {*} 'L' l_flg_lab=Y  {*} 'W' l_flg_wait=Y
    *                                   {*} 'C' l_flg_wl=Y   {*} 'T' l_flg_transp=Y
    *                                   {*} 'I' l_flg_icu=Y
    * 
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/05
    */
    FUNCTION set_room_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_room           IN room.id_room%TYPE,
        i_room_name         IN VARCHAR2,
        i_abbreviation      IN VARCHAR2,
        i_category          IN table_varchar,
        i_room_type         IN room_type.id_room_type%TYPE,
        i_room_service      IN room.id_department%TYPE,
        i_flg_selected_spec IN room.flg_selected_specialties%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        i_state             IN room.flg_available%TYPE,
        i_capacity          IN room.capacity%TYPE,
        i_rank              IN room.rank%TYPE,
        o_id_room_hist      OUT room_hist.id_room_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_room_hist(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_room           => i_id_room,
                                           i_room_name         => i_room_name,
                                           i_abbreviation      => i_abbreviation,
                                           i_category          => i_category,
                                           i_room_type         => i_room_type,
                                           i_room_service      => i_room_service,
                                           i_flg_selected_spec => i_flg_selected_spec,
                                           i_floors_department => i_floors_department,
                                           i_state             => i_state,
                                           i_capacity          => i_capacity,
                                           i_rank              => i_rank,
                                           o_id_room_hist      => o_id_room_hist,
                                           o_error             => o_error);
    END set_room_hist;

    /**
    * Public Function. Insert New Relation Department/Clinical Service Room OR Update Relation Department/Clinical Service Room Information
    *
    * @param i_lang                               Language identification
    * @param i_id_room                            Room identification
    * @param i_id_dep_clin_serv                   Department/clinical service identification 
    * @param o_id_room_dep_clin_serv              Cursor with rooms of departments/clinical services information
    * @param o_error                              Error 
    *
    * @return                                     True or False
    *
    * @author                                     Amanda Lee
    * @version                                    2.7.3.6
    * @since                                      2018/06/20
    */
    FUNCTION set_room_dcs_no_commit
    (
        i_lang               IN language.id_language%TYPE,
        i_id_room            IN room_dep_clin_serv.id_room%TYPE,
        i_dep_clin_serv      IN table_number,
        o_room_dep_clin_serv OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_room_dcs_no_commit(i_lang               => i_lang,
                                                    i_id_room            => i_id_room,
                                                    i_dep_clin_serv      => i_dep_clin_serv,
                                                    o_room_dep_clin_serv => o_room_dep_clin_serv,
                                                    o_error              => o_error);
    END set_room_dcs_no_commit;

    /**
    * Insert the history of the room
    *
    * @param i_lang                     Preferred language ID for this professional
    * @param i_id_room_hist             Room ID History
    * @param i_id_room                  Room ID
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS"
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.6
    * @since                            2018/06/14
    */
    FUNCTION set_room_dcs_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_id_room_hist IN room_hist.id_room_hist%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice_adm_surgery.insert_room_hist(i_lang         => i_lang,
                                                          i_id_room_hist => i_id_room_hist,
                                                          i_id_room      => i_id_room,
                                                          o_error        => o_error);
    END set_room_dcs_hist;

    /**
    * Get current id_room_hist
    *
    * @param i_id_room                   Room id
    * 
    * @return                            Number
    *
    * @author                            Amanda Lee
    * @version                           2.7.3.5
    * @since                             2018/06/14
    */
    FUNCTION get_current_id_room_hist(i_id_room IN room.id_room%TYPE) RETURN NUMBER IS
    BEGIN
        RETURN pk_backoffice.get_current_id_room_hist(i_id_room => i_id_room);
    END get_current_id_room_hist;

    /**
    * Create or update a bed.
    *
    * @param i_lang                      Preferred language ID for this professional
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_id_room                   Room ID (not null only for the edit operation)
    * @param i_bed_name                  Bed name
    * @param i_bed_type                  Bed type
    * @param i_bed_specialties           Array with bed specialties
    * @param i_bed_flg_selected_spec     Flg indicating the type of selection of specialties
    * @param i_bed_flg_available         flg_available
    * @param i_bed_date                  Bed date
    * @param i_dep_clin_serv             dep_clin_serv list
    * @param o_id_bed                    Bed id lists
    * @param o_error                     Error
    *
    * @value i_flg_selected_spec        {*} 'A' All {*} 'N' None {*} 'O' Other
    * @value i_bed_flg_available        {*} 'Y' Yes {*} 'N' No
    *
    * @return                           true or false on success or error
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.6
    * @since                            2018/06/14
    */
    FUNCTION set_bed
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_room               IN room.id_room%TYPE,
        i_id_bed                IN bed.id_bed%TYPE,
        i_bed_name              IN pk_translation.t_desc_translation,
        i_bed_type              IN bed_type.id_bed_type%TYPE,
        i_bed_flg_selected_spec IN VARCHAR2,
        i_bed_flg_available     IN bed.flg_available%TYPE,
        i_bed_date              IN VARCHAR2 DEFAULT NULL,
        o_id_bed                OUT bed.id_bed%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_bed(i_lang                  => i_lang,
                                     i_prof                  => i_prof,
                                     i_id_room               => i_id_room,
                                     i_id_bed                => i_id_bed,
                                     i_bed_name              => i_bed_name,
                                     i_bed_type              => i_bed_type,
                                     i_bed_flg_selected_spec => i_bed_flg_selected_spec,
                                     i_bed_flg_available     => i_bed_flg_available,
                                     i_bed_date              => i_bed_date,
                                     o_id_bed                => o_id_bed,
                                     o_error                 => o_error);
    END set_bed;

    /**
    * Public Function. Insert New Relation Room/Dep Clinical Service
    *
    * @param i_lang                         Preferred language ID for this professional
    * @param i_id_bed                       Bed id
    * @param i_dep_clin_serv                Dep_clin_serv id list
    * @param o_bed_dep_clin_serv            Dep_clin_serv id list
    * @param o_error                        error
    *
    * @return                               true or false on success or error
    *
    * @raises                               PL/SQL generic error "OTHERS"
    *
    * @author                               Amanda Lee
    * @version                              2.7.3.6
    * @since                                2018/06/14
    */
    FUNCTION set_bed_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_id_bed        IN bed_dep_clin_serv.id_bed%TYPE,
        i_dep_clin_serv IN table_number,
        --o_bed_dep_clin_serv OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_bed_dep_clin_serv(i_lang          => i_lang,
                                                   i_id_bed        => i_id_bed,
                                                   i_dep_clin_serv => i_dep_clin_serv,
                                                   --o_bed_dep_clin_serv => o_bed_dep_clin_serv,
                                                   o_error => o_error);
    END set_bed_dep_clin_serv;

    /**
    * Public Function. Insert New Relation Room/Dep Clinical Service
    *
    * @param i_lang                         Preferred language ID for this professional
    * @param i_prof                         Object (professional ID, institution ID, software ID)
    * @param i_id_room                      Room id
    * @param i_id_room_hist                 Room hist id
    * @param i_bed                          Bed id
    * @param i_bed_name                     Bed name
    * @param i_bed_type                     Bed type
    * @param i_bed_flg_selected_spec        Flg indicating the type of selection of specialties
    * @param i_flg_bed_status               Flg_bed_status
    * @param i_flg_parameterization_type
    *
    * @return                               true or false on success or error
    *
    * @raises                               PL/SQL generic error "OTHERS"
    *
    * @author                               Amanda Lee
    * @version                              2.7.3.6
    * @since                                2018/06/14
    */
    FUNCTION set_bed_hist
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_room                   IN room.id_room%TYPE,
        i_id_room_hist              IN room_hist.id_room_hist%TYPE,
        i_id_bed                    IN bed.id_bed%TYPE,
        i_bed_name                  IN pk_translation.t_desc_translation,
        i_bed_type                  IN bed_type.id_bed_type%TYPE,
        i_bed_flg_selected_spec     IN VARCHAR2,
        i_bed_flg_available         IN bed.flg_available%TYPE,
        i_flg_bed_status            IN VARCHAR2,
        i_flg_parameterization_type IN bed.flg_parameterization_type%TYPE,
        o_id_bed_hist               OUT bed_hist.id_bed_hist%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_bed_hist(i_lang                      => i_lang,
                                          i_prof                      => i_prof,
                                          i_id_room                   => i_id_room,
                                          i_id_room_hist              => i_id_room_hist,
                                          i_id_bed                    => i_id_bed,
                                          i_bed_name                  => i_bed_name,
                                          i_bed_type                  => i_bed_type,
                                          i_bed_flg_selected_spec     => i_bed_flg_selected_spec,
                                          i_bed_flg_available         => i_bed_flg_available,
                                          i_flg_bed_status            => i_flg_bed_status,
                                          i_flg_parameterization_type => i_flg_parameterization_type,
                                          o_id_bed_hist               => o_id_bed_hist,
                                          o_error                     => o_error);
    END set_bed_hist;

    /**
    * Insert the history of the bed_dep_clin_serv
    *
    * @param i_lang                     Preferred language ID for this professional
    * @param i_id_bed_hist              Bed ID History
    * @param i_id_bed                   Bed ID
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.6
    * @since                            2018/06/14
    */
    FUNCTION set_bed_dcs_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_id_bed        IN bed.id_bed%TYPE,
        i_dep_clin_serv IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_bed_dcs_hist(i_lang          => i_lang,
                                              i_id_bed        => i_id_bed,
                                              i_dep_clin_serv => i_dep_clin_serv,
                                              o_error         => o_error);
    END set_bed_dcs_hist;

    /**
    * Public Function. Public Function. Get all available clinical service
    * 
    * @param i_lang                       Language identification
    * @param o_id_clinical_service_list   Clinical service list  
    * @param o_error                      Error
    *
    * @return                             True or False
    *
    * @raises                             PL/SQL generic error "OTHERS"
    *
    * @author                             Amanda Lee
    * @version                            2.7.3.6
    * @since                              2018/06/27
    */
    FUNCTION get_clinical_service_list
    (
        i_lang                     IN language.id_language%TYPE,
        o_id_clinical_service_list OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_clinical_service_list(i_lang                     => i_lang,
                                                       o_id_clinical_service_list => o_id_clinical_service_list,
                                                       o_error                    => o_error);
    END get_clinical_service_list;

    /**
    * Public Function. set dep_clin_serv
    * 
    * @param i_lang                    Language identification
    * @param i_id_department           Insert department id
    * @param i_id_clin_service         Insert clinical service id list
    * @param o_id_dep_clin_serv        dep_clin_serv id list
    * @param o_error                   Error
    *
    * @return                          True or False
    *
    * @raises                          PL/SQL generic error "OTHERS"
    *
    * @author                          Amanda Lee
    * @version                         2.7.3.6
    * @since                           2018/06/20
    */
    FUNCTION set_dep_clin_serv_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_clin_service  IN table_number,
        o_id_dep_clin_serv OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_dep_clin_serv_no_commit(i_lang             => i_lang,
                                                         i_id_department    => i_id_department,
                                                         i_id_clin_service  => i_id_clin_service,
                                                         o_id_dep_clin_serv => o_id_dep_clin_serv,
                                                         o_error            => o_error);
    END set_dep_clin_serv_no_commit;

    /**
    * Public Function. Create or update dept
    *
    * @param i_lang                      Language identification
    * @param i_id_dept                   Dept id
    * @param i_dept_desc                 Dept name
    * @param i_id_institution            Institution identification
    * @param i_abbreviation              Department abbreviation
    * @param i_flg_available             Record availability
    * @param i_software                  Software identification
    * @param i_change                    Change
    * @param o_id_dept                   Dept id
    * @param o_error                     Error
    *
    * @value i_change                    {*} 'Y' Yes {*} 'N' No
    * @value i_flg_available             {*} 'Y' yes {*} 'N' No
    *
    * @return                            true or false on success or error
    *
    * @raises                            PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                            Kelsey Lai
    * @version                           2.7.3.6
    * @since                             2018/06/19
    */
    FUNCTION set_dept_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN dept.id_dept%TYPE,
        i_dept_desc      IN VARCHAR2,
        i_id_institution IN dept.id_institution%TYPE,
        i_abbreviation   IN dept.abbreviation%TYPE,
        i_flg_available  IN dept.flg_available%TYPE DEFAULT NULL,
        i_software       IN table_number,
        i_change         IN table_varchar,
        o_id_dept        OUT dept.id_dept%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_dept_no_commit(i_lang           => i_lang,
                                                i_id_dept        => i_id_dept,
                                                i_dept_desc      => i_dept_desc,
                                                i_id_institution => i_id_institution,
                                                i_abbreviation   => i_abbreviation,
                                                i_flg_available  => i_flg_available,
                                                i_software       => i_software,
                                                i_change         => i_change,
                                                o_id_dept        => o_id_dept,
                                                o_error          => o_error);
    END set_dept_no_commit;

    /**
    * Public Function. Create or update building
    *
    * @param i_lang                      Language identification
    * @param i_id_building               Building id
    * @param i_building_desc             Building name
    * @param i_id_institution            Institution id
    * @param i_flg_available             Record availability
    * @param o_id_building               Building id
    * @param o_error                     Error
    *
    * @value i_flg_available             {*} 'Y' yes {*} 'N' No
    *
    * @return                            true or false on success or error
    *
    * @raises                            PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                            Kelsey Lai
    * @version                           2.7.3.6
    * @since                             2018/06/19
    */
    FUNCTION set_building
    
    (
        i_lang           IN language.id_language%TYPE,
        i_id_building    IN building.id_building%TYPE,
        i_building_desc  IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_available  IN building.flg_available%TYPE DEFAULT NULL,
        o_id_building    OUT building.id_building%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_building(i_lang           => i_lang,
                                          i_id_building    => i_id_building,
                                          i_building_desc  => i_building_desc,
                                          i_id_institution => i_id_institution,
                                          i_flg_available  => i_flg_available,
                                          o_id_building    => o_id_building,
                                          o_error          => o_error);
    
    END set_building;

    /**
    * Public Function. Create or update floors
    *
    * @param i_lang                     Language identification
    * @param i_id_floors                Floors id
    * @param i_rank                     Rank
    * @param i_image_plant              Contains imagem plant swf file
    * @param i_floors_desc              Floors description
    * @param i_id_institution           Institution id
    * @param i_id_building              Building id
    * @param i_flg_available            Record availability
    * @param o_id_floors                Floors's id
    * @param o_id_floors_institution    Floors_institution id
    * @param o_error                    Error
    *
    * @value i_flg_available            {*} 'Y' yes {*} 'N' No
    *
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Kelsey Lai
    * @version                          2.7.3.6
    * @since                            2018/06/19
    */
    FUNCTION set_floors
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_floors             IN floors.id_floors%TYPE,
        i_rank                  IN floors.rank%TYPE DEFAULT 0,
        i_image_plant           IN floors.image_plant%TYPE,
        i_floors_desc           IN VARCHAR2,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_building           IN building.id_building%TYPE,
        i_flg_available         IN floors.flg_available%TYPE DEFAULT NULL,
        o_id_floors             OUT floors.id_floors%TYPE,
        o_id_floors_institution OUT floors_institution.id_floors_institution%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_backoffice.set_floors(i_lang                  => i_lang,
                                        i_id_floors             => i_id_floors,
                                        i_rank                  => i_rank,
                                        i_image_plant           => i_image_plant,
                                        i_floors_desc           => i_floors_desc,
                                        i_id_institution        => i_id_institution,
                                        i_id_building           => i_id_building,
                                        i_flg_available         => i_flg_available,
                                        o_id_floors             => o_id_floors,
                                        o_id_floors_institution => o_id_floors_institution,
                                        o_error                 => o_error);
    
    END set_floors;

    /**
    * Public Function. insert or update floors_institution
    *
    * @param i_lang                     Language identification
    * @param i_id_floors_institution    Floors_institution id
    * @param i_id_floors                Floors id
    * @param i_id_institution           Institution id
    * @param i_id_building              Building id
    * @param i_flg_available            Record availability
    * @param o_id_floors_institution    Floors_institution id
    * @param o_error                    Error
    *
    * @value i_flg_available            {*} 'Y' yes {*} 'N' No
    *
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Kelsey Lai
    * @version                          2.7.3.5
    * @since                            2018/06/19
    */
    FUNCTION set_floors_institution
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_floors_institution IN floors_institution.id_floors_institution%TYPE,
        i_id_floors             IN floors.id_floors%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_building           IN floors_institution.id_building%TYPE,
        i_flg_available         IN floors_institution.flg_available%TYPE DEFAULT NULL,
        o_id_floors_institution OUT floors_institution.id_floors_institution%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_floors_institution(i_lang                  => i_lang,
                                                    i_id_floors_institution => i_id_floors_institution,
                                                    i_id_floors             => i_id_floors,
                                                    i_id_institution        => i_id_institution,
                                                    i_id_building           => i_id_building,
                                                    i_flg_available         => i_flg_available,
                                                    o_id_floors_institution => o_id_floors_institution,
                                                    o_error                 => o_error);
    END set_floors_institution;

    /********************************************************************************************
    * Get Professional Prescriber Category for ACSS
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution Identifier
    * @param o_error                 error
    *
    * @return                        Prescriber Category + Order Prescriber Num
    *
    * @author                        Rui Gomes   
    * @version                       2.5.1.3.2
    * @since                         2011/02/28
    ********************************************************************************************/
    FUNCTION get_prof_prescriber_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN alert.profissional,
        o_prescriber_cat OUT prof_accounts.value%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_account_type accounts.sys_domain_identifier%TYPE := 'ACCOUNTS.PRESCRIBER_CATEGORY';
    
    BEGIN
    
        g_error := 'GET PROFESSIONAL PRESCRIBER CATEGORY';
        pk_alertlog.log_debug('PK_API_BACKOFFICE.GET_PROF_PRESCRIBER_CAT: ' || g_error);
        SELECT pa.value
          INTO o_prescriber_cat
          FROM prof_accounts pa
          JOIN accounts a
            ON a.id_account = pa.id_account
           AND a.sys_domain_identifier = l_account_type
           AND a.flg_available = g_flg_available
          JOIN accounts_country ac
            ON ac.id_account = a.id_account
          JOIN inst_attributes ia
            ON ia.id_country = ac.id_country
           AND ia.id_institution = i_prof.institution
          JOIN accounts_category aac
            ON aac.id_account = a.id_account
          JOIN prof_cat pc
            ON pc.id_professional = pa.id_professional
           AND pc.id_category = aac.id_category
           AND pc.id_institution = ia.id_institution
          JOIN professional p
            ON p.id_professional = pa.id_professional
           AND p.flg_state = g_status_a
         WHERE pa.id_professional = i_prof.id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE',
                                              'GET_PROF_PRESCRIBER_CAT',
                                              o_error);
            RETURN FALSE;
        
    END get_prof_prescriber_cat;

    FUNCTION get_prof_func_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_func OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_prof_func_all(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               o_prof_func => o_prof_func,
                                               o_error     => o_error);
    END get_prof_func_all;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

    g_sysdate_tstz := current_timestamp;
    g_sysdate      := SYSDATE;

    g_flg_available := 'Y';
    g_no            := 'N';
    g_yes           := 'Y';

    g_status_i := 'I';
    g_status_a := 'A';

    g_account_type_p      := 'P';
    g_account_type_i      := 'I';
    g_account_type_b      := 'B';
    g_account_multichoice := 'M';

    -- BR
    g_account_cnes := 55;
    g_account_ap   := 57;
    g_account_ibge := 54;
    g_account_uf   := 53;
    g_account_cbo  := 56;
    -- PT
    g_account_ars := 52;

    --Messages
    g_patient_sender      := 'P';
    g_professional_sender := 'F';
    g_unread_status       := 'U';
    g_read_status         := 'C';
    g_reply_status        := 'R';
    g_cancel_status       := 'X';
    g_sent_status         := 'S';

END pk_api_backoffice;
/
