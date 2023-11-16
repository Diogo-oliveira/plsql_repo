/*-- Last Change Revision: $Rev: 2028515 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_ext_instit IS

    -- Author  : TERCIO.SOARES
    -- Created : 02-06-2010 11:37:59
    -- Purpose : Package to manage External Institution information

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        Tércio Soares
    * @since                         2010/06/04
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER;

    /********************************************************************************************
    * Returns Number of External Institutions
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_search                Search
    * @param o_ext_insitit           Number of External institution
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_instit_list_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        o_ext_insitit    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Institutions data
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    *
    * @return                        table of external institution (t_table_ext_inst)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_instit_list_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_ext_inst;

    /********************************************************************************************
    * Returns External Institutions
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_ext_insitit           External institution
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_instit_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_ext_insitit    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel an External Institution
    *
    * @param i_lang                  Language id
    * @param i_institution           External insitutions ID's to cancel
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Nelson Sousa
    * @since                         2015/01/20
    * @version                       2.6.4.3
    ********************************************************************************************/
    FUNCTION cancel_ext_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Institutions License number
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_stg_institution    Staging area External Institution identifier
    * @param i_id_market             Market identifier
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_license_number
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_stg_institution IN stg_institution.id_stg_institution%TYPE,
        i_id_market          IN market.id_market%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns External Institution General data
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_market             Market identifier
    * @param o_ext_inst_data         Genral data in insitution table
    * @param o_ext_inst_field_data   General data from a specific country
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_general_data
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_market           IN market.id_market%TYPE,
        o_ext_inst_data       OUT pk_types.cursor_type,
        o_ext_inst_field_data OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Institution Contacts data
    *
    * @param i_lang                     Language id
    * @param i_id_institution           Institution identifier
    * @param i_id_market             Market identifier
    * @param o_ext_inst_contacts        Genral data in insitution table
    * @param o_ext_inst_field_contacts  General data from a specific country
    * @param o_error                    Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_contacts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_market               IN market.id_market%TYPE,
        o_ext_inst_contacts       OUT pk_types.cursor_type,
        o_ext_inst_field_contacts OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create/Update external institution
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_inst_att           Institution Attibutes ID
    * @param i_inst_name             Institution name
    * @param i_flg_type              Flag type for institution - H - Hospital, C - Primary Care, P - Private Practice
    * @param i_abbreviation          Institution abbreviation
    * @param i_phone                 Institution phone
    * @param i_fax                   Institution fax
    * @param i_email                 Institution email
    * @param i_street                Institution address
    * @param i_city                  Institution City
    * @param i_postal_code           Institution postal code
    * @param i_country               Institution Country ID
    * @param i_market                Institution Market ID
    * @param i_flg_available         Available - Y - Yes, N - No 
    * @param i_fields                List of dynamic fields
    * @param i_values                Information values for the dynamic fields
    * @param o_id_institution        institution ID
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_inst_name      IN VARCHAR2,
        i_flg_type       IN institution.flg_type%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_phone          IN institution.phone_number%TYPE,
        i_fax            IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_street         IN institution.address%TYPE,
        i_city           IN institution.location%TYPE,
        i_postal_code    IN institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_market         IN institution.id_market%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_fields         IN table_number,
        i_values         IN table_varchar,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Number of  external institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institutions ID
    * @param i_name                External institution name
    * @param i_category            External institution Type
    * @param i_city                External institution City
    * @param i_postal_code         External institution Postal Code
    * @param i_postal_code_from    External institution range of postal codes
    * @param i_postal_code_to      External institution range of postal codes
    * @param i_search              Search
    * @param o_ext_prof_list       Number of external institutions
    * @param o_error               error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @since                       2010/06/03
    * @version                     2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_inst_count
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN institution.address%TYPE,
        i_postal_code      IN institution.zip_code%TYPE,
        i_postal_code_from IN institution.zip_code%TYPE,
        i_postal_code_to   IN institution.zip_code%TYPE,
        i_search           IN VARCHAR2,
        o_ext_inst_list    OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Find external institution data
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institutions ID
    * @param i_name                External institution name
    * @param i_category            External institution Type
    * @param i_city                External institution City
    * @param i_postal_code         External institution Postal Code
    * @param i_postal_code_from    External institution range of postal codes
    * @param i_postal_code_to      External institution range of postal codes
    * @param i_search              Search
    * @param i_start_record        Paging - initial recrod number
    * @param i_num_records         Paging - number of records to display
    * @param o_ext_prof_list       List of external institutions
    * @param o_error               error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @since                       2010/06/03
    * @version                     2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_inst_data
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN institution.address%TYPE,
        i_postal_code      IN institution.zip_code%TYPE,
        i_postal_code_from IN institution.zip_code%TYPE,
        i_postal_code_to   IN institution.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_stg_ext_inst;

    /********************************************************************************************
    * Find external institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institutions ID
    * @param i_name                External institution name
    * @param i_category            External institution Type
    * @param i_city                External institution City
    * @param i_postal_code         External institution Postal Code
    * @param i_postal_code_from    External institution range of postal codes
    * @param i_postal_code_to      External institution range of postal codes
    * @param i_search              Search
    * @param i_start_record        Paging - initial recrod number
    * @param i_num_records         Paging - number of records to display
    * @param o_ext_prof_list       List of external institutions
    * @param o_error               error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @since                       2010/06/03
    * @version                     2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN institution.address%TYPE,
        i_postal_code      IN institution.zip_code%TYPE,
        i_postal_code_from IN institution.zip_code%TYPE,
        i_postal_code_to   IN institution.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records,
        o_ext_inst_list    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update/insert information for external institutions
    *
    * @param i_lang                  Prefered language ID
    * @param i_stg_professional      Staging area External Professional ID's
    * @param i_id_institution        Institution ID
    * @param o_ext_prof              External Professionals ID's imported
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_import_ext_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_stg_institution IN table_number,
        i_id_institution  IN institution.id_institution%TYPE,
        o_ext_inst        OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate External Institution data changed by the file imported to the staging area
    *
    * @param i_lang                 Language id
    * @param i_institution          Institution id
    * @param o_error                Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/07/07
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION validate_ext_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Institutions by License number
    *
    * @param i_lang                  Language id
    * @param i_license               License number
    * @param i_stg_license           Staging area license number
    * @param i_id_market             Market identifier
    * @param i_id_institution        Institution id
    * @param o_ext_inst              External institutions
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_by_license_number
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN institution_field_data.value%TYPE,
        i_stg_license    IN stg_institution_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_ext_inst       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Institutions list by License number
    *
    * @param i_lang                  Language id
    * @param i_license               License number
    * @param i_stg_license           Staging area license number
    * @param i_id_market             Market identifier
    * @param i_id_institution        Institution id
    *
    * @return                        List of external professonals
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_list_by_lic_num
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN institution_field_data.value%TYPE,
        i_stg_license    IN stg_institution_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Compare an External Institutions data with the staging area data
    *
    * @param i_lang                  Language id
    * @param i_id_ext_institution    External institution ID
    * @param i_id_stg_institution    External institution ID in staging area
    * @param i_id_institution        Institution ID
    *
    * @return                        Flag of changed data ('Y' - different data, 'N' - no different data)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_data_update
    (
        i_lang               IN language.id_language%TYPE,
        i_id_ext_institution IN institution.id_institution%TYPE,
        i_id_stg_institution IN stg_institution.id_stg_institution%TYPE,
        i_id_institution     IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Compare an External Institution data with the staging area data
    *
    * @param i_lang                      Language id
    * @param i_id_ext_institution        External institution ID
    * @param i_stg_institution           External institution ID's in staging area
    * @param i_id_institution            Institution ID
    * @param o_ext_inst_data             Cursor containing the different data
    * @param o_ext_inst_fields_data      Cursor containing the different data
    * @param o_ext_stg_inst_data         Cursor containing the different data
    * @param o_ext_stg_inst_fields_data  Cursor containing the different data
    * @param o_error                     Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_data_review
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_ext_institution       IN institution.id_institution%TYPE,
        i_stg_institution          IN table_number,
        i_id_institution           IN institution.id_institution%TYPE,
        o_ext_inst_data            OUT pk_types.cursor_type,
        o_ext_inst_fields_data     OUT pk_types.cursor_type,
        o_ext_stg_inst_data        OUT pk_types.cursor_type,
        o_ext_stg_inst_fields_data OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Import the staging area data for an External Institution
    *
    * @param i_lang                  Language id
    * @param i_institution           External institution ID's
    * @param i_stg_institution       External institution ID's in staging area
    * @param i_id_institution        Institution ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_accept_data_update
    (
        i_lang            IN language.id_language%TYPE,
        i_institution     IN table_number,
        i_stg_institution IN table_number,
        i_id_institution  IN institution.id_institution%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Reject the staging area data for an External Institution
    *
    * @param i_lang                  Language id
    * @param i_institution           External institution ID's
    * @param i_id_institution        Institution ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_reject_data_update
    (
        i_lang           IN language.id_language%TYPE,
        i_institution    IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete Staging Area data imported to an institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/07/09
    ********************************************************************************************/
    FUNCTION set_delete_stg_ext_inst_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get External Institution country list
    *
    * @param i_lang                Prefered language ID
    * @param i_column              Column to return (1 - VAL, 2 - DESC_VAL, 3 - ICON)
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/07/12
    ********************************************************************************************/
    FUNCTION get_ext_country_list
    (
        i_lang   IN language.id_language%TYPE,
        i_column IN NUMBER
    ) RETURN CLOB;
    /* Method that returns external institution address information */
    FUNCTION get_ext_institution_address
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    g_ext_prof_to_sch      CONSTANT professional_take_over.flg_status%TYPE := 'S';
    g_ext_prof_to_finished CONSTANT professional_take_over.flg_status%TYPE := 'F';
    g_ext_prof_active      CONSTANT prof_institution.flg_state%TYPE := 'A';

    g_error VARCHAR2(2000);

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_BACKOFFICE_EXT_INSTIT';

    g_country_pt  CONSTANT country.id_country%TYPE := 620;
    g_country_nl  CONSTANT country.id_country%TYPE := 528;
    g_country_usa CONSTANT country.id_country%TYPE := 840;
    g_country_uk  CONSTANT country.id_country%TYPE := 826;

    g_market_pt  CONSTANT market.id_market%TYPE := 1;
    g_market_nl  CONSTANT market.id_market%TYPE := 5;
    g_market_usa CONSTANT market.id_market%TYPE := 2;

    g_string_delim CONSTANT VARCHAR2(1) := '|';

END pk_backoffice_ext_instit;
/
