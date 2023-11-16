/*-- Last Change Revision: $Rev: 2045487 $*/
/*-- Last Change by: $Author: andre.silva $*/
/*-- Date of last change: $Date: 2022-09-19 08:42:35 +0100 (seg, 19 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_backoffice IS

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate      VARCHAR2(50);
    g_error        VARCHAR2(2000);

    g_flg_available VARCHAR2(1);
    g_no            VARCHAR2(1);
    g_yes           VARCHAR2(1);

    g_status_i VARCHAR2(1);
    g_status_a VARCHAR2(1);

    --Fields for external institutions
    g_field_inst_agb CONSTANT field.id_field%TYPE := 40;

    --Fields for external institutions
    g_field_prof_agb CONSTANT field.id_field%TYPE := 20;

    --Accounts
    g_account_type_p      accounts.flg_type%TYPE;
    g_account_type_i      accounts.flg_type%TYPE;
    g_account_type_b      accounts.flg_type%TYPE;
    g_account_multichoice accounts.fill_type%TYPE;
    --Accounts ids
    g_account_npi CONSTANT accounts.id_account%TYPE := 1;
    g_account_agb CONSTANT accounts.id_account%TYPE := 13;
    g_account_cnes accounts.id_account%TYPE;
    g_account_ap   accounts.id_account%TYPE;
    g_account_ibge accounts.id_account%TYPE;
    g_account_uf   accounts.id_account%TYPE;
    g_account_cbo  accounts.id_account%TYPE;
    g_account_ars  accounts.id_account%TYPE;

    --Accounts category
    g_acc_cat_flg_inst_yes CONSTANT accounts_category.flg_institution%TYPE := 'Y';
    g_acc_cat_flg_inst_no  CONSTANT accounts_category.flg_institution%TYPE := 'N';
    g_acc_cat_none         CONSTANT NUMBER := 0;
    g_acc_inst_all         CONSTANT NUMBER := 0;
    -- messaging globals
    g_patient_sender      VARCHAR2(1 CHAR);
    g_professional_sender VARCHAR2(1 CHAR);
    g_unread_status       VARCHAR2(1 CHAR);
    g_read_status         VARCHAR2(1 CHAR);
    g_reply_status        VARCHAR2(1 CHAR);
    g_cancel_status       VARCHAR2(1 CHAR);
    g_sent_status         VARCHAR2(1 CHAR);

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_API_BACKOFFICE';

    -- Author  : TERCIO.SOARES
    -- Created : 03-06-2008 8:52:22
    -- Purpose : API for INTER_ALERT
    SUBTYPE t_rec_serie IS pk_backoffice.t_rec_serie;
    -- prof info record type    
    TYPE prof_all_inst_rec IS RECORD(
        id_professional NUMBER(24),
        name            VARCHAR2(1000),
        photo           VARCHAR2(1000),
        id_speciality   NUMBER(24),
        desc_speciality VARCHAR2(1000),
        username        VARCHAR2(200));
    -- ref cursor type
    TYPE prof_all_inst_list IS REF CURSOR RETURN prof_all_inst_rec;
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN NUMBER;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Professional fields values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_id_institution   Progfessional Institution ID
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    * @version                     2.6.0.4
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
    ) RETURN BOOLEAN;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN table_number;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get sis pre natal current serie
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
    ) RETURN t_rec_serie;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN series.current_number%TYPE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN geo_state.id_geo_state%TYPE;

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
    ) RETURN geo_state.code_state%TYPE;
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
    ) RETURN BOOLEAN;
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
    * @version                     2.6.1.2
    * @since                       2011/09/14
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
    ) RETURN BOOLEAN;
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
    * @version                     2.6.1.2
    * @since                       2011/09/14
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
    /*Save zipped report file, go to next status and generate alert*/
    FUNCTION save_req_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        i_file       IN BLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    FUNCTION get_cda_req_status(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN VARCHAR2;
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
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set New Messages
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get VHIF data
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    * @o_prof_name              professional name
    * @o_prof_spec              professional Speciality
    * @o_prof_role              professional Role
    * @o_prof_idnat             List of professional National identifier
    * @o_inst_type              Institution Type
    * @o_inst_serial            Institution Serial
    * @o_inst_idnat             List of Institution National identifiers
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
    ) RETURN BOOLEAN;

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
    );

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
    ) RETURN BOOLEAN;
	
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
    ) RETURN BOOLEAN;

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
    * @raises                           PL/SQL generic error "OTHERS"
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    FUNCTION get_current_id_room_hist(i_id_room IN room.id_room%TYPE) RETURN NUMBER;

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
    ) RETURN BOOLEAN;

    FUNCTION set_room_dcs_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_id_room_hist IN room_hist.id_room_hist%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION set_bed_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_id_bed        IN bed_dep_clin_serv.id_bed%TYPE,
        i_dep_clin_serv IN table_number,
        --o_bed_dep_clin_serv OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_service_list
    (
        i_lang                     IN language.id_language%TYPE,
        o_id_clinical_service_list OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dep_clin_serv_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_clin_service  IN table_number,
        o_id_dep_clin_serv OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_lang        IN language.id_language%TYPE,
        i_id_bed      IN bed.id_bed%TYPE,
		i_dep_clin_serv IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
	
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
    ) RETURN BOOLEAN;

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
    * @version                           2.7.3.5
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
    ) RETURN BOOLEAN;

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
    * @version                          2.7.3.5
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
    
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
    ) RETURN BOOLEAN;

    FUNCTION get_prof_func_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_func OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
END pk_api_backoffice;
/
