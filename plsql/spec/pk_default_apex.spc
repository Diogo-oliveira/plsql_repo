/*-- Last Change Revision: $Rev: 1790427 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2017-07-14 16:27:32 +0100 (sex, 14 jul 2017) $*/

CREATE OR REPLACE PACKAGE pk_default_apex IS

    -- public methods

    FUNCTION get_lov_id_format(i_id_string IN table_varchar) RETURN VARCHAR2;

    PROCEDURE get_valid_dcs_for_softwares
    (
        i_lang        IN VARCHAR2,
        i_institution IN NUMBER,
        i_soft        IN table_number,
        i_dcs         IN table_number,
        o_dcs         OUT table_number
    );
    /********************************************************************************************
    * Pre Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.1
    * @since                         2011/04/28
    ********************************************************************************************/
    FUNCTION pre_default_content
    (
        i_lang        IN language.id_language%TYPE,
        i_sync_lucene IN VARCHAR2 DEFAULT 'N',
        i_drop_lucene IN VARCHAR2 DEFAULT 'N',
        i_drop_lang   IN VARCHAR2 DEFAULT 'N',
        i_sequence    IN VARCHAR2 DEFAULT 'N',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Post Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.1
    * @since                         2011/04/28
    ********************************************************************************************/
    FUNCTION post_default_content
    (
        i_create_lucene_all   IN VARCHAR2 DEFAULT 'N',
        i_create_lucene_byjob IN VARCHAR2 DEFAULT 'N',
        i_start_bylang        IN NUMBER DEFAULT NULL,
        i_sync_lucene         IN VARCHAR2 DEFAULT 'N',
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    PROCEDURE set_system_admin
    (
        i_lang        IN language.id_language%TYPE,
        i_id_prof     IN professional.id_professional%TYPE,
        i_id_inst     IN institution.id_institution%TYPE,
        i_id_country  IN country.id_country%TYPE,
        i_title       IN professional.title%TYPE,
        i_nick_name   IN professional.nick_name%TYPE,
        i_gender      IN professional.gender%TYPE,
        i_dt_birth    IN VARCHAR2,
        i_email       IN professional.email%TYPE,
        i_work_phone  IN professional.num_contact%TYPE,
        i_cell_phone  IN professional.cell_phone%TYPE,
        i_fax         IN professional.fax%TYPE,
        i_first_name  IN professional.first_name%TYPE,
        i_middle_name IN professional.middle_name%TYPE,
        i_last_name   IN professional.last_name%TYPE,
        i_id_cat      IN category.id_category%TYPE,
        i_templ       IN profile_template.id_profile_template%TYPE,
        i_user        IN VARCHAR,
        i_pass        IN VARCHAR,
        o_id_prof     OUT professional.id_professional%TYPE,
        o_error       OUT t_error_out
    );
    PROCEDURE associate_system_admin
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_inst        IN institution.id_institution%TYPE,
        i_id_origin_inst IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    );
    FUNCTION get_inst_admins_lov
    (
        i_lang        language.id_language%TYPE,
        i_institution institution.id_institution%TYPE
    ) RETURN t_coll_professional;
    FUNCTION get_profs_all_lov
    (
        i_lang        language.id_language%TYPE,
        i_institution institution.id_institution%TYPE
    ) RETURN t_coll_professional;
    /********************************************************************************************
    * Fix sequences related to Default Process
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/06/28
    ********************************************************************************************/
    PROCEDURE fix_default_sequences
    (
        i_lang      IN language.id_language%TYPE,
        o_tables    OUT table_varchar,
        o_actions   OUT table_varchar,
        o_positions OUT table_number,
        o_error     OUT t_error_out
    );
    /********************************************************************************************
    * Fix a sequence related to Default Process
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/06/28
    ********************************************************************************************/
    PROCEDURE fix_default_sequences
    (
        i_lang            IN language.id_language%TYPE,
        i_seq_name        IN VARCHAR2,
        i_table_name      IN VARCHAR2,
        i_use_past_values IN VARCHAR2 DEFAULT 'N',
        i_range           IN NUMBER DEFAULT 30000,
        o_tables          OUT table_varchar,
        o_actions         OUT table_varchar,
        o_positions       OUT table_number,
        o_error           OUT t_error_out
    );
    /********************************************************************************************
    * Get display for apex LOV (Main Method)
    *
    * @param i_lang                Log Language ID
    * @param i_institution         id_institution to configure
    * @param i_software            id_software array
    * @param i_dcs                 id_dcs id
    * @param i_profile_templ       profile template id
    * @param i_lov_type            LOV type (procedure name)
    * @param i_scfg_type           System configuration id
    * @param i_flg_null            Add option to array (A - ALL, N - Null, I - Ignore)
    * @param o_error               error output
    *
    * @result                      table of apex display type
    *
    * @author                      RMGM
    * @version                     2.6.3
    * @since                       2013/07/24
    ********************************************************************************************/
    FUNCTION build_alert_lov
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_lov_type      IN VARCHAR,
        i_software      IN table_number DEFAULT table_number(),
        i_dcs           IN NUMBER DEFAULT NULL,
        i_profile_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_domain_type   IN VARCHAR2 DEFAULT NULL,
        i_condition     IN table_varchar DEFAULT table_varchar(),
        i_flg_null      IN VARCHAR2 DEFAULT NULL,
        i_null_desc     IN VARCHAR2 DEFAULT NULL,
        i_search        IN VARCHAR2 DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN t_tbl_lov;

    FUNCTION get_profile_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN VARCHAR2,
        i_category    IN VARCHAR2
    ) RETURN t_tbl_lov;
    --
    FUNCTION get_cs_id_from_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_dcs  IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_sysconfig_value
    (
        i_lang        IN language.id_language%TYPE,
        i_sysconfig   IN VARCHAR2,
        i_institution IN NUMBER,
        i_software    IN NUMBER
    ) RETURN sys_config.value%TYPE;
    FUNCTION get_rooms_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mcdt_type   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields;
    FUNCTION get_triage_serv_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields;
    FUNCTION set_bulk_analysis_room
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN table_number,
        i_software_list IN table_number,
        i_type          IN VARCHAR2,
        i_flg_default   IN NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_bulk_exam_room
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN table_number,
        i_software_list IN table_number,
        i_type          IN VARCHAR2,
        i_flg_default   IN NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_bulk_epis_type_room
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN table_number,
        i_software_list IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_mcdt_def_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_context     IN VARCHAR2,
        i_room        IN table_number,
        i_software    IN table_number,
        i_flg_default IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_mcdt_def_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_context     IN VARCHAR2,
        i_room        IN NUMBER,
        i_mcdt        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_triage_department
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_service     IN table_number,
        i_triage_type IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_triage_department
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_service     IN NUMBER,
        i_triage_type IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_content_report_view
    (
        i_query  IN VARCHAR2,
        l_struct OUT pk_tool_utils.t_tbl_struct
    );
    FUNCTION get_pks_and_others
    (
        i_table   IN VARCHAR2,
        o_columns OUT table_varchar
    ) RETURN VARCHAR2;

    FUNCTION get_trans_col(i_desc_table IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_desc_col(i_desc_table IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_all_trans_cols(i_desc_table IN VARCHAR2) RETURN table_varchar;

    FUNCTION check_field
    (
        i_table IN VARCHAR2,
        i_field IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_table_schema(i_table IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_table_fk_tree
    (
        i_table         IN dba_tables.table_name%TYPE,
        o_ptbl_list     OUT table_varchar,
        o_pcns_list     OUT table_varchar,
        o_pcnstype_list OUT table_varchar,
        o_powner_list   OUT table_varchar,
        o_tbl_list      OUT table_varchar,
        o_tblcns_list   OUT table_varchar,
        o_level_list    OUT table_varchar,
        o_tblcol_list   OUT table_varchar,
        o_ptblcol_list  OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set New Institution (Main Method)
    *
    * @param i_lang                Log Language ID
    * @param i_id_institution      id_institution to configure Null if new
    * @param i_id_inst_att         id_institution attributes to update null if new
    * @param i_id_inst_lang        id_institution languate to update null if new
    * @param i_desc                Institution Name
    * @param i_id_parent           Institution parent id
    * @param i_flg_type            Institution Type
    * @param i_tax                 Institution Tax Id
    * @param i_abbreviation        Institution shortname
    * @param i_pref_lang           Institution predefined language
    * @param i_currency            Institution currency
    * @param i_phone_number        Institution phone number
    * @param i_fax                 Institution fax number
    * @param i_email               Institution email adress
    * @param i_adress              Institution adress
    * @param i_location            Institution adress city
    * @param i_geo_state           Institution adress state
    * @param i_zip_code            Institution zip code
    * @param i_country             Institution country
    * @param i_id_tz_region        Institution Timezone
    * @param i_id_market           Institution market
    * @param o_id_institution      Output id institution created or updated
    * @param o_error               error output
    *
    * @result                      true or false
    *
    * @author                      RMGM
    * @version                     2.6.3
    * @since                       2013/12/10
    ********************************************************************************************/
    FUNCTION set_institution_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN ab_institution.id_ab_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang   IN institution_language.id_institution_language%TYPE,
        i_desc           IN translation.desc_lang_1%TYPE,
        i_id_parent      IN ab_institution.id_ab_institution_parent%TYPE,
        i_flg_type       IN ab_institution.flg_type%TYPE,
        i_tax            IN inst_attributes.social_security_number%TYPE,
        i_abbreviation   IN ab_institution.shortname%TYPE,
        i_pref_lang      IN language.id_language%TYPE,
        i_currency       IN inst_attributes.id_currency%TYPE,
        i_phone_number   IN ab_institution.phone_number%TYPE,
        i_fax            IN ab_institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_adress         IN ab_institution.address1%TYPE,
        i_location       IN ab_institution.address2%TYPE,
        i_geo_state      IN ab_institution.address3%TYPE,
        i_zip_code       IN ab_institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_flg_available  IN VARCHAR2,
        i_id_tz_region   IN ab_institution.id_timezone_region%TYPE,
        i_id_market      IN ab_institution.id_ab_market%TYPE,
        o_id_institution OUT ab_institution.id_ab_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get display for apex LOV (Software Institution configuration)
    *
    * @param i_lang                      Language id
    * @param i_id_institution            Institution id
    * @param o_inst_attrib_id            Institution attributes id
    * @param o_institution_name          Institution name
    * @param o_parent_institution        Parent institution id
    * @param o_institution_type          Institution type
    * @param o_flg_available             Available
    * @param o_soc_security              Soc. Security no.
    * @param o_shortname                 Shortname
    * @param o_language                  Language id
    * @param o_currency                  Currency id
    * @param o_phone_num                 Phone no.
    * @param o_fax_num                   Fax no.
    * @param o_email                     Email
    * @param o_address                   Address
    * @param o_city                      City
    * @param o_state                     State
    * @param o_zipcode                   Zipcode
    * @param o_country                   Country id
    * @param o_timezone                  Timezone
    * @param o_market                    Market id
    * @param o_error                     Error output
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/

    FUNCTION get_institution_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN ab_institution.id_ab_institution%TYPE,
        o_inst_attrib_id     OUT inst_attributes.id_inst_attributes%TYPE,
        o_institution_name   OUT VARCHAR2,
        o_parent_institution OUT ab_institution.id_ab_institution_parent%TYPE,
        o_institution_type   OUT ab_institution.flg_type%TYPE,
        o_flg_available      OUT ab_institution.flg_available%TYPE,
        o_soc_security       OUT inst_attributes.social_security_number%TYPE,
        o_shortname          OUT ab_institution.shortname%TYPE,
        o_language           OUT institution_language.id_language%TYPE,
        o_currency           OUT inst_attributes.id_currency%TYPE,
        o_phone_num          OUT ab_institution.phone_number%TYPE,
        o_fax_num            OUT ab_institution.fax_number%TYPE,
        o_email              OUT ab_institution.email%TYPE,
        o_address            OUT ab_institution.address1%TYPE,
        o_city               OUT ab_institution.address2%TYPE,
        o_state              OUT ab_institution.ine_location%TYPE,
        o_zipcode            OUT ab_institution.zip_code%TYPE,
        o_country            OUT inst_attributes.id_country%TYPE,
        o_timezone           OUT ab_institution.id_timezone_region%TYPE,
        o_market             OUT ab_institution.id_ab_market%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get display for apex LOV (Software Institution configuration)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    FUNCTION get_software_institution_list(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields;

    FUNCTION get_institution_logo
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE
    ) RETURN BLOB;

    FUNCTION get_institution_banner
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE
    ) RETURN BLOB;

    FUNCTION get_institution_banner_small
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE
    ) RETURN BLOB;

    FUNCTION set_institution_logos
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE,
        i_logo           IN BLOB,
        i_banner         IN BLOB,
        i_banner_small   IN BLOB
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    FUNCTION get_all_institution_report(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields;
    /********************************************************************************************
    * set list of softwares to be used in institution
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/12
    ********************************************************************************************/
    FUNCTION set_institution_software
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN ab_institution.id_ab_institution%TYPE,
        i_software_list  IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Delete row of software institution configuration
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/12
    ********************************************************************************************/
    PROCEDURE delete_inst_soft
    (
        i_lang     IN language.id_language%TYPE,
        i_id_si_pk IN ab_software_institution.id_ab_software_institution%TYPE
    );
    /********************************************************************************************
    * Set building in institution
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION set_building
    (
        i_lang          IN language.id_language%TYPE,
        i_building_id   IN building.id_building%TYPE,
        i_building_name IN translation.desc_lang_1%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Update building description
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    PROCEDURE update_building_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_building_id   IN building.id_building%TYPE,
        i_building_name IN translation.desc_lang_1%TYPE
    );
    /********************************************************************************************
    * Disable building record listed in apex
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    PROCEDURE disable_building
    (
        i_lang        IN language.id_language%TYPE,
        i_building_id IN building.id_building%TYPE
    );

    /********************************************************************************************
    * Disable floor record listed in apex
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    PROCEDURE disable_floor
    (
        i_lang     IN language.id_language%TYPE,
        i_floor_id IN floors.id_floors%TYPE
    );

    /********************************************************************************************
    * Get display for apex LOV (building report)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    FUNCTION get_building_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN t_tbl_apex_manyfields;
    /********************************************************************************************
    * Get display for apex LOV (Floors Institution report)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    FUNCTION get_floors_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN t_tbl_apex_manyfields;

    PROCEDURE get_floor_data
    (
        i_lang           IN language.id_language%TYPE,
        i_floor_id       IN floors.id_floors%TYPE,
        o_floor_name     OUT VARCHAR2,
        o_floor_image    OUT floors.image_plant%TYPE,
        o_floor_building OUT floors_institution.id_building%TYPE
    );
    /********************************************************************************************
    * Set FLOORS in institution
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION set_floors_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_floor       IN floors.id_floors%TYPE,
        i_floor_name     IN translation.desc_lang_1%TYPE,
        i_image          IN floors.image_plant%TYPE,
        i_building       IN building.id_building%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Update or Insert institution group configuration record using apex (Institution Group config)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    FUNCTION set_institution_group
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN table_number,
        i_id_group       IN table_number,
        i_flg_relation   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Delete institution group configuration record using apex (Institution Group config)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    FUNCTION del_institution_group
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_group       IN institution_group.id_group%TYPE,
        i_flg_relation   IN institution_group.flg_relation%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Report for apex (Institution Group information)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    FUNCTION get_institution_group
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN t_tbl_apex_manyfields;

    PROCEDURE set_def_process_job_args
    (
        i_config_type   IN table_varchar,
        i_areas         IN table_varchar,
        i_tables        IN table_varchar,
        i_market        IN table_number,
        i_version       IN table_varchar,
        i_software      IN table_number,
        i_dcs_full_list IN table_number,
        i_cs_full_list  IN table_number,
        o_config_type   OUT VARCHAR2,
        o_areas         OUT VARCHAR2,
        o_tables        OUT VARCHAR2,
        o_market        OUT VARCHAR2,
        o_version       OUT VARCHAR2,
        o_software      OUT VARCHAR2,
        o_dcs_full_list OUT VARCHAR2,
        o_cs_full_list  OUT VARCHAR2
    );
    /* DEfault process execute by job - Apex area execution consumer */
    FUNCTION send_default_process_job_area
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_session_type  IN VARCHAR2,
        i_author        IN VARCHAR2,
        i_config_type   IN table_varchar,
        i_areas         IN table_varchar,
        i_tables        IN table_varchar,
        i_dependencies  IN VARCHAR2,
        i_market        IN table_varchar,
        i_version       IN table_varchar,
        i_software      IN table_varchar,
        i_flg_dcs_all   IN table_varchar,
        i_dcs_full_list IN table_varchar,
        i_cs_full_list  IN table_varchar
    ) RETURN table_varchar;

    FUNCTION send_default_process_job
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_session_type  IN VARCHAR2,
        i_author        IN VARCHAR2,
        i_config_type   IN table_varchar,
        i_areas         IN table_varchar,
        i_tables        IN table_varchar,
        i_dependencies  IN VARCHAR2,
        i_market        IN table_number,
        i_version       IN table_varchar,
        i_software      IN table_number,
        i_flg_dcs_all   IN VARCHAR2,
        i_dcs_full_list IN table_number,
        i_cs_full_list  IN table_number
    ) RETURN VARCHAR2;
    /* Get info about current job and if they have finished the routine */
    FUNCTION get_job_status_complete(i_cur_job_name IN VARCHAR2) RETURN BOOLEAN;
    /* Enable job */
    PROCEDURE set_job_enable(i_cur_job_name IN VARCHAR2);

    FUNCTION synch_ncd_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_code_translation IN translation.code_translation%TYPE DEFAULT 'ALL',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_job_report(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields;

    /********************************************************************************************
    * Get visit list report
    *
    * @param i_lang  Language id
    * @param i_institution  Institution id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_visit_report
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_patient_list IN VARCHAR2,
        i_visit_list   IN VARCHAR2
    ) RETURN t_tbl_apex_manyfields;

    /********************************************************************************************
    * Get episode list report
    *
    * @param i_lang  Language id
    * @param i_institution  Institution id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_episode_report
    (
        i_lang             IN language.id_language%TYPE,
        i_institution_list IN table_number,
        i_patient_list     IN table_number,
        i_visit_list       IN table_number,
        i_episode_list     IN table_number
    ) RETURN t_tbl_apex_manyfields;

    /********************************************************************************************
    * Get visit list report
    *
    * @param i_lang  Language id
    * @param i_institution  Institution id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_patient_report
    (
        i_lang             IN language.id_language%TYPE,
        i_institution_list IN table_number,
        i_patient_list     IN table_number
    ) RETURN t_tbl_apex_manyfields;

    /********************************************************************************************
    * Get all tables with id_content not from alerT_default
    *
    * @param i_lang  Language id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_tables_w_id_content_rep(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields;
    -- check if there are external institutions conection
    FUNCTION get_checkpoint_external_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    -- chech if institution is a discharge destination
    FUNCTION get_checkpoint_disch_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    -- check if institution is parent of other
    FUNCTION get_checkpoint_parent_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    -- check if institution is in same group as others
    FUNCTION get_checkpoint_group_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION get_institution_report
    (
        i_lang       IN language.id_language%TYPE,
        i_instit_chr IN VARCHAR2
    ) RETURN t_tbl_apex_manyfields;
    /********************************************************************************************
    * Get display for apex LOV (get_content list)
    *
    * @author                        JM
    * @version                       2.6.3
    * @since                         2013/11/24
    ********************************************************************************************/
    PROCEDURE get_content_list_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_condition   IN table_varchar DEFAULT table_varchar(),
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    );
    /********************************************************************************************
    * Get display for apex LOV (complaint list)
    *
    * @author                        JM
    * @version                       2.6.3
    * @since                         2013/11/24
    ********************************************************************************************/
    PROCEDURE get_complaint_list_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution NUMBER,
        i_software    IN table_number,
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    );
    /********************************************************************************************
    * Get display for apex LOV (get_dept|department|dcs list)
    *
    * @author                        JM
    * @version                       2.6.3
    * @since                         2013/11/24
    ********************************************************************************************/
    PROCEDURE get_dcs_list_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    );
    /********************************************************************************************
    * Send request to IA services in order to do operations according to system configuration changes
    *
    * @param i_cfg_id  System configuration id
    * @param i_value  Value
    * @param i_institution  Institution ID
    * @param i_software  Software ID
    *
    * @author                        RMGM
    * @version                       2.6.4.3
    * @since                         2015/02/19
    ********************************************************************************************/
    /*PROCEDURE set_ncd_updates
    (
        i_cfg_id      IN sys_config.id_sys_config%TYPE,
        i_value       IN sys_config.value%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    );*/

    -- vars
    g_error         VARCHAR2(2000);
    g_flg_available VARCHAR2(1);
    g_no            VARCHAR2(1);
    g_active        VARCHAR2(1);
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(100);
END pk_default_apex;
/
