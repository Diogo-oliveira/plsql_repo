CREATE OR REPLACE PACKAGE pk_backoffice_api_ui IS

    -- Author  : MAURO.SOUSA
    -- Created : 29-06-2010 15:57:45
    -- Purpose : To be facilitate Java Service Generation Request for UX layer

    /********************************************************************************************
    * Shows all available Languages
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_language               Languages list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Mauro.Sousa
    * @version                        2.6.0.4
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_language OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns bollean (true or false)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional identifier
    * @param i_id_professional       Professional to search
    * @param o_def_lang              default id_language to return
    * @param o_def_cat               default id_category to return
    * @param o_error               error to process
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/09/12
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_wizard_defvals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_def_lang        OUT language.id_language%TYPE,
        o_def_cat         OUT category.id_category%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns bollean (true or false)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional identifier
    * @param o_title               default id_category to return
    * @param o_error               error to process
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/11/21
    * @version                       2.6.1.5.1
    ********************************************************************************************/
    FUNCTION get_prof_title_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns bollean (true or false)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional identifier
    * @param i_flg_profinst          Professional or institution edition area
    * @param o_at_list               returns adress type list
    * @param o_error                 error to process
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/01/24
    * @version                       2.6.2.0.6
    ********************************************************************************************/
    FUNCTION get_adress_type_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_profinst IN VARCHAR2,
        o_at_list      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_professional
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_prof           IN professional.id_professional%TYPE,
        i_title             IN professional.title%TYPE,
        i_first_name        IN professional.first_name%TYPE,
        i_middle_name       IN professional.middle_name%TYPE,
        i_last_name         IN professional.last_name%TYPE,
        i_nick_name         IN professional.nick_name%TYPE,
        i_initials          IN professional.initials%TYPE,
        i_dt_birth          IN VARCHAR2,
        i_gender            IN professional.gender%TYPE,
        i_marital_status    IN professional.marital_status%TYPE,
        i_id_category       IN category.id_category%TYPE,
        i_id_speciality     IN professional.id_speciality%TYPE,
        i_num_order         IN professional.num_order%TYPE,
        i_upin              IN professional.upin%TYPE,
        i_dea               IN professional.dea%TYPE,
        i_id_cat_surgery    IN category.id_category%TYPE,
        i_num_mecan         IN prof_institution.num_mecan%TYPE,
        i_id_lang           IN prof_preferences.id_language%TYPE,
        i_flg_state         IN prof_institution.flg_state%TYPE,
        i_address           IN professional.address%TYPE,
        i_city              IN professional.city%TYPE,
        i_district          IN professional.district%TYPE,
        i_zip_code          IN professional.zip_code%TYPE,
        i_id_country        IN professional.id_country%TYPE,
        i_work_phone        IN professional.work_phone%TYPE,
        i_num_contact       IN professional.num_contact%TYPE,
        i_cell_phone        IN professional.cell_phone%TYPE,
        i_fax               IN professional.fax%TYPE,
        i_email             IN professional.email%TYPE,
        i_adress_type       IN professional.adress_type%TYPE,
        i_id_scholarship    IN professional.id_scholarship%TYPE,
        i_agrupacion        IN professional.id_agrupacion%TYPE,
        i_id_road           IN professional.id_road%TYPE,
        i_entity            IN professional.id_entity%TYPE,
        i_jurisdiction      IN professional.id_jurisdiction%TYPE,
        i_municip           IN professional.id_municip%TYPE,
        i_localidad         IN professional.id_localidad%TYPE,
        i_id_postal_code_rb IN professional.id_postal_code_rb%TYPE,
        i_bleep_num         IN professional.bleep_number%TYPE,
        i_suffix            IN professional.suffix%TYPE,
        i_contact_det       IN prof_institution.contact_detail%TYPE,
        i_county            IN professional.county%TYPE,
        i_other_adress      IN professional.address_other_name%TYPE,
        i_commit_at_end     IN BOOLEAN,
        i_parent_name       IN professional.parent_name%TYPE,
        i_first_name_sa     IN professional.first_name_sa%TYPE,
        i_parent_name_sa    IN professional.parent_name_sa%TYPE,
        i_middle_name_sa    IN professional.middle_name_sa%TYPE,
        i_last_name_sa      IN professional.last_name_sa%TYPE,
        i_doc_ident_type    IN prof_doc.id_doc_type%TYPE,
        i_doc_ident_num     IN prof_doc.value%TYPE,
        i_doc_ident_val     IN VARCHAR2,
        o_id_prof           OUT professional.id_professional%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the professional id created or updated
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_PROF                  Identificação do Profissional
    * @param      --I_NAME                     Nome
    * @param      I_TITLE                    Título
    * @param      I_FIRST_NAME               Primeiro nome
    * @param      I_MIDDLE_NAME              Nomes do meio
    * @param      I_LAST_NAME                Último nome
    * @param      I_NICK_NAME                Nome abreviado
    * @param      I_INITIALS                 Iniciais do nome
    * @param      I_DT_BIRTH                 Data de nascimento
    * @param      I_GENDER                   Sexo
    * @param      I_MARITAL_STATUS           Estado civil
    * @param      I_ID_CATEGORY              Identificador da categoria
    * @param      I_ID_SPECIALITY            Identificador da especialidade
    * @param      I_NUM_ORDER                Número da ordem
    * @param      I_UPIN                     UPIN
    * @param      I_DEA                      DEA
    * @param      I_ID_CAT_SURGERY           Identificador da categoria em cirurgia
    * @param      I_NUM_MECAN                Número mecanográfico
    * @param      I_ID_LANG                  Identificador da língua
    * @param      I_FLG_STATE                Estado
    * @param      I_ADDRESS                  Morada
    * @param      I_CITY                     Localidade
    * @param      I_DISTRICT                 Concelho
    * @param      I_ZIP_CODE                 Código postal
    * @param      I_ID_COUNTRY               Identificador do país
    * @param      I_WORK_PHONE               Telefone do trabalho
    * @param      I_NUM_CONTACT              Telefone de casa
    * @param      I_CELL_PHONE               Telemóvel
    * @param      I_FAX                      Fax
    * @param      I_EMAIL                    E-mail
    * @param      I_ADRESS_TYPE              Adress_type
    * @param      O_ERROR                    Erro
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/01/24
    * @version                       2.6.2.0.6
    ********************************************************************************************/
    FUNCTION set_professional
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_prof                 IN professional.id_professional%TYPE,
        i_title                   IN professional.title%TYPE,
        i_first_name              IN professional.first_name%TYPE,
        i_middle_name             IN professional.middle_name%TYPE,
        i_last_name               IN professional.last_name%TYPE,
        i_nick_name               IN professional.nick_name%TYPE,
        i_initials                IN professional.initials%TYPE,
        i_dt_birth                IN VARCHAR2,
        i_gender                  IN professional.gender%TYPE,
        i_marital_status          IN professional.marital_status%TYPE,
        i_id_category             IN category.id_category%TYPE,
        i_id_speciality           IN professional.id_speciality%TYPE,
        i_num_order               IN professional.num_order%TYPE,
        i_upin                    IN professional.upin%TYPE,
        i_dea                     IN professional.dea%TYPE,
        i_id_cat_surgery          IN category.id_category%TYPE,
        i_num_mecan               IN prof_institution.num_mecan%TYPE,
        i_id_lang                 IN prof_preferences.id_language%TYPE,
        i_flg_state               IN prof_institution.flg_state%TYPE,
        i_address                 IN professional.address%TYPE,
        i_city                    IN professional.city%TYPE,
        i_district                IN professional.district%TYPE,
        i_zip_code                IN professional.zip_code%TYPE,
        i_id_country              IN professional.id_country%TYPE,
        i_work_phone              IN professional.work_phone%TYPE,
        i_num_contact             IN professional.num_contact%TYPE,
        i_cell_phone              IN professional.cell_phone%TYPE,
        i_fax                     IN professional.fax%TYPE,
        i_email                   IN professional.email%TYPE,
        i_adress_type             IN professional.adress_type%TYPE,
        i_id_scholarship          IN professional.id_scholarship%TYPE,
        i_agrupacion              IN professional.id_agrupacion%TYPE,
        i_id_road                 IN professional.id_road%TYPE,
        i_entity                  IN professional.id_entity%TYPE,
        i_jurisdiction            IN professional.id_jurisdiction%TYPE,
        i_municip                 IN professional.id_municip%TYPE,
        i_localidad               IN professional.id_localidad%TYPE,
        i_id_postal_code_rb       IN professional.id_postal_code_rb%TYPE,
        i_bleep_num               IN professional.bleep_number%TYPE,
        i_suffix                  IN professional.suffix%TYPE,
        i_contact_det             IN prof_institution.contact_detail%TYPE,
        i_county                  IN professional.county%TYPE,
        i_other_adress            IN professional.address_other_name%TYPE,
        i_commit_at_end           IN BOOLEAN,
        i_parent_name             IN professional.parent_name%TYPE,
        i_first_name_sa           IN professional.first_name_sa%TYPE,
        i_parent_name_sa          IN professional.parent_name_sa%TYPE,
        i_middle_name_sa          IN professional.middle_name_sa%TYPE,
        i_last_name_sa            IN professional.last_name_sa%TYPE,
        i_doc_ident_type          IN prof_doc.id_doc_type%TYPE,
        i_doc_ident_num           IN prof_doc.value%TYPE,
        i_doc_ident_val           IN VARCHAR2,
        i_tin                     IN professional.taxpayer_number%TYPE,
        i_clinical_name           IN professional.clinical_name%TYPE,
        i_prof_spec_id            IN table_number,
        i_prof_spec_ballot        IN table_varchar,
        i_prof_spec_id_university IN table_number,
        i_agrupacion_instit_id    IN professional.id_agrupacion_instit%TYPE,
        o_id_prof                 OUT professional.id_professional%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Insert New Institution OR Update Institution Information
     *
     * @param      I_LANG                               Language identification
     * @param      I_ID_INSTITUTION                     Institution identification
     * @param      i_id_inst_att                        Institution attributes
     * @param      i_id_inst_lang                       Institution language
     * @param      I_DESC                               Institution description
     * @param      i_id_parent                          Institution parent
     * @param      I_FLG_TYPE                           Institution type: H - Hospital, C - Primary Care, P - Private Practice
     * @param      i_tax                                Social security number
     * @param      I_ABBREVIATION                       Abreviation
     * @param      i_pref_lang                          Institution language
     * @param      i_currency                           Currency
     * @param      I_PHONE_NUMBER                       Phone number
     * @param      i_fax                                Fax
     * @param      i_email                              Email
     * @param      i_adress                             Adress
     * @param      I_LOCATION                           Location
     * @param      i_geo_state                          District
     * @param      i_zip_code                           Zip code
     * @param      i_country                            Country
     * @param      i_location_tax                       Location tax
     * @param      i_lic_model                          Licence model
     * @param      i_pay_sched                          Payment schedule
     * @param      i_pay_opt                            Payment options
     * @param      I_FLG_AVAILABLE                      Flag available
     * @param      I_ADRESS_TYPE                        Adress_type
     * @param      i_id_tz_region                       id timezone region
     * @param      i_commit_at_end                      Commit at end
     * @param      O_ID_INSTITUTION                     Institution identification
     * @param      o_id_inst_attributes                 Institution attributes id
     * @param      o_id_inst_lang                       Institution Language identification
     * @param      O_ERROR
     *
     * @return                        true (sucess), false (error)
     *
     * @author                        RMGM
     * @since                         2012/01/24
     * @version                       2.6.2.0.6
     ********************************************************************************************/
    FUNCTION set_institution_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang   IN institution_language.id_institution_language%TYPE,
        i_desc           IN VARCHAR2,
        i_id_parent      IN institution.id_parent%TYPE,
        i_flg_type       IN institution.flg_type%TYPE,
        i_tax            IN inst_attributes.social_security_number%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_pref_lang      IN institution_language.id_language%TYPE,
        i_currency       IN inst_attributes.id_currency%TYPE,
        i_phone_number   IN institution.phone_number%TYPE,
        i_fax            IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_adress         IN institution.address%TYPE,
        i_location       IN institution.location%TYPE,
        i_geo_state      IN institution.district%TYPE,
        i_zip_code       IN institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_location_tax   IN inst_attributes.id_location_tax%TYPE,
        i_lic_model      IN inst_attributes.license_model%TYPE,
        i_pay_sched      IN inst_attributes.payment_schedule%TYPE,
        i_pay_opt        IN inst_attributes.payment_options%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_id_tz_region   IN institution.id_timezone_region%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_adress_type    IN institution.adress_type%TYPE,
        i_contact_det    IN ab_institution.contact_detail%TYPE,
        
        i_county       IN ab_institution.county%TYPE,
        i_other_adress IN ab_institution.address_other_name%TYPE,
        
        i_commit_at_end IN BOOLEAN,
        
        i_clues              IN inst_attributes.clues%TYPE,
        i_health_license     IN inst_attributes.health_license%TYPE,
        i_flg_street_type    IN inst_attributes.flg_street_type%TYPE,
        i_street_name        IN inst_attributes.street_name%TYPE,
        i_outdoor_number     IN inst_attributes.outdoor_number%TYPE,
        i_indoor_number      IN inst_attributes.indoor_number%TYPE,
        i_id_settlement_type IN inst_attributes.id_settlement_type%TYPE,
        i_id_settlement_name IN inst_attributes.id_settlement_name%TYPE,
        i_id_entity          IN inst_attributes.id_entity%TYPE,
        i_id_municip         IN inst_attributes.id_municip%TYPE,
        i_id_localidad       IN inst_attributes.id_localidad%TYPE,
        i_id_postal_code     IN inst_attributes.id_postal_code%TYPE,
        i_jurisdiction       IN inst_attributes.jurisdiction%TYPE,
        i_website            IN inst_attributes.website%TYPE,
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_inst_and_admin
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_clues              IN inst_attributes.clues%TYPE,
        i_id_inst_att        IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang       IN institution_language.id_institution_language%TYPE,
        i_desc               IN VARCHAR2,
        i_id_parent          IN institution.id_parent%TYPE,
        i_flg_type           IN institution.flg_type%TYPE,
        i_tax                IN inst_attributes.social_security_number%TYPE,
        i_abbreviation       IN institution.abbreviation%TYPE,
        i_pref_lang          IN institution_language.id_language%TYPE,
        i_currency           IN inst_attributes.id_currency%TYPE,
        i_phone_number       IN institution.phone_number%TYPE,
        i_fax                IN institution.fax_number%TYPE,
        i_email              IN inst_attributes.email%TYPE,
        i_health_license     IN inst_attributes.health_license%TYPE,
        i_adress_type        IN institution.adress_type%TYPE,
        i_address            IN institution.address%TYPE,
        i_location           IN institution.location%TYPE,
        i_geo_state          IN institution.district%TYPE,
        i_zip_code           IN institution.zip_code%TYPE,
        i_country            IN inst_attributes.id_country%TYPE,
        i_flg_street_type    IN inst_attributes.flg_street_type%TYPE,
        i_street_name        IN inst_attributes.street_name%TYPE,
        i_outdoor_number     IN inst_attributes.outdoor_number%TYPE,
        i_indoor_number      IN inst_attributes.indoor_number%TYPE,
        i_id_settlement_type IN inst_attributes.id_settlement_type%TYPE,
        i_id_settlement_name IN inst_attributes.id_settlement_name%TYPE,
        i_id_entity          IN inst_attributes.id_entity%TYPE,
        i_jurisdiction       IN inst_attributes.jurisdiction%TYPE,
        i_id_municip         IN inst_attributes.id_municip%TYPE,
        i_id_localidad       IN inst_attributes.id_localidad%TYPE,
        i_id_postal_code     IN inst_attributes.id_postal_code%TYPE,
        i_location_tax       IN inst_attributes.id_location_tax%TYPE,
        i_lic_model          IN inst_attributes.license_model%TYPE,
        i_pay_sched          IN inst_attributes.payment_schedule%TYPE,
        i_pay_opt            IN inst_attributes.payment_options%TYPE,
        i_flg_available      IN institution.flg_available%TYPE,
        i_id_tz_region       IN institution.id_timezone_region%TYPE,
        i_id_market          IN market.id_market%TYPE,
        i_contact_det        IN ab_institution.contact_detail%TYPE,
        i_county             IN ab_institution.county%TYPE,
        i_other_adress       IN ab_institution.address_other_name%TYPE,
        i_software           IN software.id_software%TYPE,
        i_id_prof            IN professional.id_professional%TYPE,
        i_id_inst            IN institution.id_institution%TYPE,
        i_name               IN professional.name%TYPE,
        i_title              IN professional.title%TYPE,
        i_nick_name          IN professional.nick_name%TYPE,
        i_gender             IN professional.gender%TYPE,
        i_dt_birth           IN VARCHAR2,
        i_prof_email         IN professional.email%TYPE,
        i_work_phone         IN professional.num_contact%TYPE,
        i_cell_phone         IN professional.cell_phone%TYPE,
        i_prof_fax           IN professional.fax%TYPE,
        i_first_name         IN professional.first_name%TYPE,
        i_middle_name        IN professional.middle_name%TYPE,
        i_last_name          IN professional.last_name%TYPE,
        i_id_cat             IN category.id_category%TYPE,
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_id_prof            OUT professional.id_professional%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional Names
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param o_prof_name           Cursor with profissional NAME
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.1.6
    * @since                       2011/12/19
    ********************************************************************************************/
    FUNCTION get_prof_names
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_name       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Institution Software List (with available functionality map)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_context             Screen Context
    * @param o_software            Software List Output Cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.2.1
    * @since                       2012/03/29
    ********************************************************************************************/
    FUNCTION get_institution_software
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_context  IN VARCHAR2,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Department configured Software List (with available functionality map)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_context             Screen Context
    * @param o_software              Software List Output Cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.2.1
    * @since                       2012/03/29
    ********************************************************************************************/
    FUNCTION get_software_dcs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_context  IN VARCHAR2,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Save Service Information
    *
    * @param i_lang                Prefered language ID
    * @param i_id_department       Service ID
    * @param i_id_institution      Institution ID
    * @param i_desc                Service description
    * @param i_abbreviation        Service abbreviation
    * @param i_flg_type            Type of service
    * @param i_id_dept             Department ID
    * @param i_flg_default         Default service in a department
    * @param i_def_priority        Lab Tests priority
    * @param i_collection_by       Collection by
    * @param i_floors_institution  Floors where the service is located
    * @param i_change              Flg signaling changed
    * @param i_commit_stg          Flg showing to save data previous stored in staging area
    * @param i_change_profs        Flg indicating if all professional alert list must be reset
    * @param o_id_department       Service Id
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/10/25
    ********************************************************************************************/
    FUNCTION set_department
    (
        i_lang               IN language.id_language%TYPE,
        i_id_department      IN department.id_department%TYPE,
        i_id_institution     IN department.id_institution%TYPE,
        i_desc               IN VARCHAR2,
        i_abbreviation       IN department.abbreviation%TYPE,
        i_flg_type           IN department.flg_type%TYPE,
        i_id_dept            IN department.id_dept%TYPE,
        i_flg_default        IN department.flg_default%TYPE,
        i_def_priority       IN department.flg_priority%TYPE,
        i_collection_by      IN department.flg_collection_by%TYPE,
        i_floors_institution IN table_number,
        i_change             IN table_varchar,
        i_id_admission_type  IN admission_type.id_admission_type%TYPE,
        i_admission_time     IN VARCHAR2,
        i_commit_stg         IN VARCHAR,
        i_change_profs       IN VARCHAR,
        i_template_list      IN table_number,
        i_phone_number       IN VARCHAR2,
        i_fax_number         IN VARCHAR2,
        i_prof_resp_add      IN table_number,
        i_prof_resp_rem      IN table_number,
        i_prof_service_add   IN table_number,
        i_prof_service_rem   IN table_number,
        o_id_department      OUT department.id_department%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get software list filtered by profile and category
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_institution            Institution ID
    * @param i_id_professional        Professional ID
    * @param o_list                   Cursor with software information
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/14
    **********************************************************************************************/
    FUNCTION get_software_instit_w_pt
    (
        i_lang            IN language.id_language%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Boolean
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param o_inst_type             List of values for institution type field
    * @param o_error                 Error Id
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/05/29
    * @version                       2.5.2
    ********************************************************************************************/
    FUNCTION get_institution_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_inst_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Boolean
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_country            Country identifier (mandatory)
    * @param i_geo_state             Geo State identifier
    * @param o_geo_stat_list         List of states filtered by country
    * @param o_error                 Error Id
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/14
    * @version                       2.5.1
    ********************************************************************************************/

    FUNCTION get_city_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_country   IN country.id_country%TYPE,
        i_geo_state IN geo_state.id_geo_state%TYPE,
        o_city_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Boolean
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param o_geo_stat_list         List of states filtered by country
    * @param o_error                 Error Id
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/14
    * @version                       2.5.1
    ********************************************************************************************/
    FUNCTION get_geo_state_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_country        IN country.id_country%TYPE,
        o_geo_state_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional Bond domain BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional array ID
    * @param o_res_list         cursor with ordered results
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/14
    ********************************************************************************************/
    FUNCTION get_bond_value
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_level    IN NUMBER DEFAULT 1,
        i_bond_id  IN NUMBER DEFAULT NULL,
        o_res_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Professional BR Fields (SBIS)
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
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION set_professional_br
    (
        i_lang           IN language.id_language%TYPE, --1
        i_id_institution IN institution.id_institution%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE, --5
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nick_name      IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN VARCHAR2, --10
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_id_scholarship IN professional.id_scholarship%TYPE, --15
        i_num_order      IN professional.num_order%TYPE,
        i_upin           IN professional.upin%TYPE,
        i_dea            IN professional.dea%TYPE,
        i_id_cat_surgery IN category.id_category%TYPE,
        i_num_mecan      IN prof_institution.num_mecan%TYPE, --20
        i_id_lang        IN prof_preferences.id_language%TYPE,
        i_flg_state      IN prof_institution.flg_state%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE, --25
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_work_phone     IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_cell_phone     IN professional.cell_phone%TYPE, --30
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_commit_at_end  IN BOOLEAN,
        i_adress_type    IN professional.adress_type%TYPE,
        -- professional BR fields
        i_id_cpf             IN professional.id_cpf%TYPE, --35
        i_id_cns             IN professional.id_cns%TYPE,
        i_mother_name        IN professional.mother_name%TYPE,
        i_father_name        IN professional.father_name%TYPE,
        i_id_gstate_birth    IN professional.id_geo_state_birth%TYPE,
        i_id_city_birth      IN professional.id_district_birth%TYPE, --40
        i_code_race          IN professional.code_race%TYPE,
        i_code_school        IN professional.code_scoolarship%TYPE,
        i_flg_in_school      IN professional.flg_in_school%TYPE,
        i_code_logr          IN professional.code_logr_type%TYPE,
        i_door_num           IN professional.door_number%TYPE, --45
        i_address_ext        IN professional.address_extension%TYPE,
        i_id_gstate_adress   IN professional.id_geo_state_adress%TYPE,
        i_id_city_adress     IN professional.id_district_adress%TYPE,
        i_adress_area        IN professional.adress_area%TYPE,
        i_code_banq          IN professional.code_banq%TYPE, --50
        i_desc_agency        IN professional.desc_banq_ag%TYPE,
        i_banq_account       IN professional.id_banq_account%TYPE,
        i_code_certif        IN professional.code_certificate%TYPE,
        i_balcon_certif      IN professional.desc_balcony%TYPE,
        i_book_certif        IN professional.desc_book%TYPE, --55
        i_page_certif        IN professional.desc_page%TYPE,
        i_term_certif        IN professional.desc_term%TYPE,
        i_date_certif        IN VARCHAR2,
        i_id_document        IN professional.id_document%TYPE,
        i_balcon_doc         IN professional.code_emitant_cert%TYPE, --60
        i_id_gstate_doc      IN professional.id_geo_state_doc%TYPE,
        i_date_doc           IN VARCHAR2,
        i_code_crm           IN professional.code_emitant_crm%TYPE,
        i_id_gstate_crm      IN professional.id_geo_state_crm%TYPE,
        i_code_family_status IN professional.code_family_status%TYPE, --65
        i_code_doc_type      IN professional.code_doc_type%TYPE,
        i_prof_ocp           IN professional.id_prof_formation%TYPE,
        -- prof_institution fields
        i_bond     IN prof_institution.id_professional_bond%TYPE,
        i_work_amb IN prof_institution.work_schedule_amb%TYPE,
        i_work_inp IN prof_institution.work_schedule_inp%TYPE, --70
        o_work_oth IN prof_institution.work_schedule_other%TYPE,
        i_flg_sus  IN prof_institution.flg_sus_app%TYPE,
        -- end prof_institution fields
        i_other_doc_desc IN professional.other_doc_desc%TYPE,
        i_healht_plan    IN professional.id_health_plan%TYPE,
        --end br fields
        i_bleep_num    IN professional.bleep_number%TYPE, --75
        i_suffix       IN professional.suffix%TYPE,
        i_contact_det  IN prof_institution.contact_detail%TYPE,
        i_county       IN professional.county%TYPE,
        i_other_adress IN professional.address_other_name%TYPE,
        o_id_prof      OUT professional.id_professional%TYPE, --80
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional BR Fields (SBIS)
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
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION get_professional_br
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_br         OUT pk_types.cursor_type,
        o_prof_inst_br    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_occupation_list
    (
        i_lang  IN language.id_language%TYPE,
        o_occup OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of professional physicians in a service context to turn as responsible
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/11
    **********************************************************************************************/
    FUNCTION get_serv_physician_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        o_prof_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get list of professional physicians in a service context to turn as responsible
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/11
    **********************************************************************************************/
    FUNCTION get_service_responsible_map
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        i_id_professional IN department.id_department%TYPE,
        o_result_list     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set list of responsible professionals in a service context
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION set_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Delete responsible professional in a service context
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION delete_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get detailed CDA request history
    *
    * @param i_lang
    * @param i_id_cda_req
    * @param o_results
    * @param o_results_prof
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_id_cda_req   IN cda_req.id_cda_req%TYPE,
        o_results      OUT pk_types.cursor_type,
        o_results_prof OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get detailed CDA request table
    *
    * @param i_lang
    * @param i_id_institution
    * @param o_results
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_results        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set a Complete CDA request
    *
    * @param i_lang
    * @param i_prof
    * @param i_id_institution
    * @param i_flg_type
    * @param i_dt_start
    * @param i_dt_end
    * @param i_qrda_type
    * @param i_qrda_stype
    * @param i_sw_list
    * @param o_cda_req
    * @param o_cda_req_det
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN cda_req.flg_type%TYPE,
        i_dt_start       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_qrda_type      IN cda_req_det.id_report%TYPE,
        i_qrda_stype     IN cda_req_det.qrda_type%TYPE,
        i_sw_list        IN cda_req.id_software%TYPE,
        o_cda_req        OUT cda_req.id_cda_req%TYPE,
        o_cda_req_det    OUT cda_req_det.id_cda_req_det%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Measures list
    *
    * @param i_lang
    * @param i_prof
    * @param o_tab_emeasure
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_qrda_measures
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_tab_emeasure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get software CDA request list
    *
    * @param i_lang
    * @param i_flg_cda_req_type
    * @param i_flg_type_qrda
    * @param o_result_sw
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_software_list
    (
        i_lang             IN language.id_language%TYPE,
        i_flg_cda_req_type IN cda_req.flg_type%TYPE,
        i_flg_type_qrda    IN cda_req_det.qrda_type%TYPE,
        o_result_sw        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get CDA Report ID
    *
    * @param o_id_report
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_report_id
    (
        i_id_software IN software.id_software%TYPE,
        o_id_report   OUT report_software.id_report%TYPE
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Retrieve file to servlet in order to be sent to ux for download
    *
    * @param i_cda_req
    * @param o_file
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_file
    (
        i_cda_req IN cda_req.id_cda_req%TYPE,
        o_file    OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set report next logical status
    *
    * @param i_lang
    * @param i_id_cda_req
    * @param i_id_institution
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_cda_next_status
    (
        i_lang           IN language.id_language%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE,
        o_error          OUT t_error_out
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

    FUNCTION get_scholarship_mkt
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_scholarship_group
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_scholarship_group IN professional.id_agrupacion%TYPE,
        o_list                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get CDA requests Detail or History
    *
    * @param i_lang                 Application current language
    * @param i_prof                 Professional Information array
    * @param i_id_cda_req           CDA request identified
    * @param i_screen_flg           Flg showing the screen request (H or D)
    * @param o_results              Cursor with returned information
    * @param o_error                Error information type
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/07/15
    * @version                       2.6.4.1
    ********************************************************************************************/
    FUNCTION get_cda_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        i_screen_flg IN VARCHAR2,
        o_results    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
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
    * Get message thread
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_thread                                 Thread message identifier
    * @param i_thread_level                               maximum thread level (message being seen)
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
        o_messages     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @since                   2014/10/17
    ********************************************************************************************/
    FUNCTION set_message
    (
        i_lang        IN language.id_language%TYPE,
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
    * Set message as cancelled
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message as Read
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_read
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /* Method to return message domains*/
    FUNCTION get_message_domain
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_res_cur OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message in previous status
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.2
    * @since                   2014/10/27
    ********************************************************************************************/
    FUNCTION set_msg_prev_status
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_professional
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_prof           IN professional.id_professional%TYPE,
        i_title             IN professional.title%TYPE,
        i_first_name        IN professional.first_name%TYPE,
        i_middle_name       IN professional.middle_name%TYPE,
        i_last_name         IN professional.last_name%TYPE,
        i_nick_name         IN professional.nick_name%TYPE,
        i_initials          IN professional.initials%TYPE,
        i_dt_birth          IN VARCHAR2,
        i_gender            IN professional.gender%TYPE,
        i_marital_status    IN professional.marital_status%TYPE,
        i_id_category       IN category.id_category%TYPE,
        i_id_speciality     IN professional.id_speciality%TYPE,
        i_id_scholarship    IN professional.id_scholarship%TYPE,
        i_num_order         IN professional.num_order%TYPE,
        i_upin              IN professional.upin%TYPE,
        i_dea               IN professional.dea%TYPE,
        i_id_cat_surgery    IN category.id_category%TYPE,
        i_num_mecan         IN prof_institution.num_mecan%TYPE,
        i_id_lang           IN prof_preferences.id_language%TYPE,
        i_flg_state         IN prof_institution.flg_state%TYPE,
        i_address           IN professional.address%TYPE,
        i_city              IN professional.city%TYPE,
        i_district          IN professional.district%TYPE,
        i_zip_code          IN professional.zip_code%TYPE,
        i_id_country        IN professional.id_country%TYPE,
        i_work_phone        IN professional.work_phone%TYPE,
        i_num_contact       IN professional.num_contact%TYPE,
        i_cell_phone        IN professional.cell_phone%TYPE,
        i_fax               IN professional.fax%TYPE,
        i_email             IN professional.email%TYPE,
        i_commit_at_end     IN BOOLEAN,
        i_id_road           IN professional.id_road%TYPE,
        i_entity            IN professional.id_entity%TYPE,
        i_jurisdiction      IN professional.id_jurisdiction%TYPE,
        i_municip           IN professional.id_municip%TYPE,
        i_localidad         IN professional.id_localidad%TYPE,
        i_id_postal_code_rb IN professional.id_postal_code_rb%TYPE,
        o_id_prof           OUT professional.id_professional%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_name_translation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_name       IN name_translation.ocidental_name%TYPE,
        i_type       IN NUMBER,
        o_name_trans OUT name_translation.ocidental_name%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_agrupacion
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_doc_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    g_flg_available VARCHAR2(1);
    --
    g_id_country_br  CONSTANT market.id_market%TYPE := 76;
    g_others_message CONSTANT sys_message.code_message%TYPE := 'COMMON_M096';

END pk_backoffice_api_ui;
/
