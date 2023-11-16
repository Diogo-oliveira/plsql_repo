/*-- Last Change Revision: $Rev: 2028513 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_disposition IS

    -- Author  : SERGIO.CUNHA
    -- Created : 05-03-2009 10:48:45
    -- Purpose : Manage disposition management backoffice

    /********************************************************************************************
    * Get an list of external professionals for the institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_category                 Category ID
    * @param i_id_institution              Institution ID
    * @param o_professional_ext            External professional info list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_professional
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_category      IN category.id_category%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        o_professional_ext OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get an external professional's detail
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_professional_ext         External professional ID
    * @param o_professional_ext            External professional info
    * @param o_prof_ext_accounts           Accounts
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_prof_detail
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        o_professional_ext    OUT pk_types.cursor_type,
        o_prof_ext_accounts   OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel external professional
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_professional_ext            Array of External professional ID
    * @param o_id_professional_ext         External professional canceled ID's list
    * @param o_id_professional_ext_hist    External professional history updated ID's list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION cancel_ext_professional
    (
        i_lang                     IN LANGUAGE.id_language%TYPE,
        i_prof                     IN profissional,
        i_professional_ext         IN table_number,
        o_id_professional_ext      OUT table_number,
        o_id_professional_ext_hist OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get an external professional info for editing
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_professional_ext         External professional ID
    * @param o_professional_ext            External professional info to edit
    * @param o_prof_ext_accounts           External professional accounts
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION edit_ext_professional
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        o_professional_ext    OUT pk_types.cursor_type,
        o_prof_ext_accounts   OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set an external professional
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_professional_ext         External professional ID
    * @param i_id_institution              Institution ID
    * @param i_title                       Professional's title
    * @param i_first_name                  First name
    * @param i_last_name                   Last name
    * @param i_gender                      Flag gender
    * @param i_id_speciality               Professional's speciality
    * @param i_id_category                 Professional's category
    * @param i_id_category_sub             Professional's surgery category
    * @param i_id_language                 Professional's prefered language
    * @param i_address                     Address
    * @param i_city                        City
    * @param i_district                    District
    * @param i_zip_code                    Zip code
    * @param i_id_country                  Country ID
    * @param i_work_phone                  Work phone number
    * @param i_fax                         Fax
    * @param i_website                     Website address
    * @param i_email                       E-mail
    * @param i_cell_phone                  Cell phone number
    * @param i_dt_birth                    Birth date
    * @param i_num_contact                 Contact number
    * @param i_marital_status              Marital status flag
    * @param i_initials                    Initials
    * @param i_middle_name                 Middle name
    * @param i_office_name                 Offices name
    * @param o_id_professional_ext         External professional's ID updated/inserted
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION set_ext_professional
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        i_id_institution      IN professional_ext.id_institution%TYPE,
        i_title               IN professional_ext.title%TYPE,
        i_first_name          IN professional_ext.first_name%TYPE,
        i_last_name           IN professional_ext.last_name%TYPE,
        i_gender              IN professional_ext.gender%TYPE,
        i_id_speciality       IN professional_ext.id_speciality%TYPE,
        i_id_category         IN professional_ext.id_category%TYPE,
        i_id_category_sub     IN professional_ext.id_category_sub%TYPE,
        i_id_language         IN professional_ext.id_language%TYPE,
        i_address             IN professional_ext.address%TYPE,
        i_city                IN professional_ext.city%TYPE,
        i_district            IN professional_ext.district%TYPE,
        i_zip_code            IN professional_ext.zip_code%TYPE,
        i_id_country          IN professional_ext.id_country%TYPE,
        i_work_phone          IN professional_ext.work_phone%TYPE,
        i_fax                 IN professional_ext.fax%TYPE,
        i_website             IN professional_ext.website%TYPE,
        i_email               IN professional_ext.email%TYPE,
        i_cell_phone          IN professional_ext.cell_phone%TYPE,
        i_dt_birth            IN professional_ext.dt_birth%TYPE,
        i_num_contact         IN professional_ext.num_contact%TYPE,
        i_marital_status      IN professional_ext.marital_status%TYPE,
        i_initials            IN professional_ext.initials%TYPE,
        i_middle_name         IN professional_ext.middle_name%TYPE,
        i_office_name         IN professional_ext.office_name%TYPE,
        o_id_professional_ext OUT professional_ext.id_professional_ext%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a list of external institutions for the institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_flg_type                    External institution's flag type (O-Office; C-Clinic)
    * @param i_id_institution              Institution ID
    * @param o_institution_ext             External institution's info list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_institution
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN institution_ext.flg_type%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_institution_ext OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get an external institution's detail
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_institution_ext          External institution ID
    * @param o_institution_ext             External institution info
    * @param o_instit_ext_accounts         External institution's accounts info
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_inst_detail
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_institution_ext  IN institution_ext.id_institution_ext%TYPE,
        o_institution_ext     OUT pk_types.cursor_type,
        o_instit_ext_accounts OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel external institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_institution_ext             Array of external institution ID's
    * @param o_id_institution_ext          Array of canceled external institution's ID
    * @param o_id_institution_ext_hist     Array of external institution history updated ID's list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION cancel_ext_institution
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_institution_ext         IN table_number,
        o_id_institution_ext      OUT table_number,
        o_id_institution_ext_hist OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get an external institution info for editing
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_institution_ext          External institution ID
    * @param o_institution_ext             External institution info
    * @param o_instit_ext_accounts         External institution acccounts info
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION edit_ext_institution
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_institution_ext  IN institution_ext.id_institution_ext%TYPE,
        o_institution_ext     OUT pk_types.cursor_type,
        o_instit_ext_accounts OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set an external institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution_ext          External institution ID
    * @param i_id_institution              Institution ID
    * @param i_flg_type                    External institution flag type
    * @param i_institution_name            External institution name
    * @param i_id_language                 External institution prefered language
    * @param i_address                     Address
    * @param i_location                    Location
    * @param i_district                    District
    * @param i_zip_code                    Zip code
    * @param i_id_country                  Country ID
    * @param i_work_phone                  Work phone number
    * @param i_fax                         Fax number
    * @param i_website                     Website address
    * @param i_email                       E-mail
    * @param i_specialities                Array of clinical services
    * @param o_id_institution_ext          External institution ID inserted/updated
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION set_ext_institution
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_institution_ext IN institution_ext.id_institution_ext%TYPE,
        i_id_institution     IN institution_ext.id_institution%TYPE,
        i_flg_type           IN institution_ext.flg_type%TYPE,
        i_institution_name   IN institution_ext.institution_name%TYPE,
        i_id_language        IN institution_ext.id_language%TYPE,
        i_address            IN institution_ext.address%TYPE,
        i_location           IN institution_ext.location%TYPE,
        i_district           IN institution_ext.district%TYPE,
        i_zip_code           IN institution_ext.zip_code%TYPE,
        i_id_country         IN institution_ext.id_country%TYPE,
        i_work_phone         IN institution_ext.work_phone%TYPE,
        i_fax                IN institution_ext.fax%TYPE,
        i_website            IN institution_ext.website%TYPE,
        i_email              IN institution_ext.email%TYPE,
        i_specialities       IN table_number,
        o_id_institution_ext OUT institution_ext.id_institution_ext%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set external institution affiliations values
    *
    * @param i_lang                        Language
    * @param i_id_institution_ext          External institution ID
    * @param i_accounts                    Affiliations ID's
    * @param i_values                      Affiliations Values
    * @param o_error                       Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   SC
    * @version                  0.1
    * @since                    2009/03/05
    ********************************************************************************************/
    FUNCTION set_inst_ext_affiliations
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_id_institution_ext IN institution.id_institution%TYPE,
        i_accounts           IN table_number,
        i_values             IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set external professional affiliations values
    *
    * @param i_lang                        Language
    * @param i_id_professional_ext         Professional ID
    * @param i_id_institution              Institution ID
    * @param i_accounts                    Affiliations ID's
    * @param i_values                      Affiliations Values
    * @param o_error                       Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   SC
    * @version                  0.1
    * @since                    2009/03/05
    ********************************************************************************************/
    FUNCTION set_prof_ext_affiliations
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        i_institution         IN table_number,
        i_accounts            IN table_number,
        i_values              IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get external institutions country affiliations
    *
    * @param i_lang                        Language
    * @param i_id_institution_ext          Institution ID
    * @param i_id_country                  Country ID
    * @param o_inst_ext_affiliations       Affiliations cursor
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_inst_ext_ctry_affiliations
    (
        i_lang                  IN LANGUAGE.id_language%TYPE,
        i_id_institution_ext    IN institution_ext.id_institution_ext%TYPE,
        i_id_country            IN country.id_country%TYPE,
        o_inst_ext_affiliations OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get external professional category affiliations
    *
    * @param i_lang                        Language
    * @param i_id_professional_ext         Professional ID
    * @param i_id_category                 Category ID
    * @param i_id_institution              Institution ID
    * @param o_prof_ext_affiliations       Affiliations cursor
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_prof_ext_cat_affiliations
    (
        i_lang                  IN LANGUAGE.id_language%TYPE,
        i_id_professional_ext   IN professional.id_professional%TYPE,
        i_id_category           IN category.id_category%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        o_prof_ext_affiliations OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get title list
    *
    * @param i_lang                        Language
    * @param o_title                       Title list
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_prof_ext_title_list
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get gender list
    *
    * @param i_lang                        Language
    * @param o_gender                      Gender list
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get country list
    *
    * @param i_lang                        Language
    * @param o_country                     Country list
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_country_list
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);
    g_physician_cat CONSTANT category.id_category%TYPE := 1;

END pk_backoffice_disposition;
/
