/*-- Last Change Revision: $Rev: 2028516 $*/ 
/*-- Last Change by: $Author: mario.fernandes $*/ 
/*-- Date of last change: $Date: 2022-08-02 18:46:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_ext_prof IS

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
    * Returns Number of External Professionals linked to an Insitution
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_ext_prof_to        Professional Take over ID
    * @param i_search                Search
    * @param o_ext_prof_count        External professionals count
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_list_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_ext_prof_to IN professional.id_professional%TYPE,
        i_search         IN VARCHAR2,
        o_ext_prof_count OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals data linked to an Insitution
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_ext_prof_to        Professional Take over ID
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_error                 Error message
    *
    * @return                        table of external professionals (t_table_ext_prof)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_list_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_ext_prof_to IN professional.id_professional%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_ext_prof;

    /********************************************************************************************
    * Returns External Professionals linked to an Insitution
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_institution        Institution identifier
    * @param i_id_ext_prof_to        Professional Take over ID
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_ext_prof              External professionals
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_ext_prof_to IN professional.id_professional%TYPE,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_ext_prof       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals License number
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_stg_professional   Staging area External Professional identifier
    * @param i_id_market             Market identifier
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_license_number
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_id_market           IN market.id_market%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns External Professionals Category
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_stg_professional   Staging area Professional identifier
    * @param i_id_market             Market identifier
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_category
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_id_market           IN market.id_market%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns External Professionals Personal data
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_market             Market identifier
    * @param o_ext_prof_data         Personal data in professional table
    * @param o_ext_prof_field_data   Personal data from a specific country
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_personal_data
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_market           IN market.id_market%TYPE,
        o_ext_prof_data       OUT pk_types.cursor_type,
        o_ext_prof_field_data OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals Personal contacts
    *
    * @param i_lang                      Language id
    * @param i_id_professional           Professional identifier
    * @param i_id_market                 Market identifier
    * @param o_ext_prof_contacts         Personal contacts in professional table
    * @param o_ext_prof_field_contacts   Personal contacts from a specific country
    * @param o_error                     Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_personal_contacts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_professional         IN professional.id_professional%TYPE,
        i_id_market               IN market.id_market%TYPE,
        o_ext_prof_contacts       OUT pk_types.cursor_type,
        o_ext_prof_field_contacts OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals professional data
    *
    * @param i_lang                        Language id
    * @param i_id_professional             Professional identifier
    * @param i_id_market                   MArket identifier
    * @param o_ext_prof_professional       Professional data in professional table
    * @param o_ext_prof_field_professinal  Professional data from a specific country
    * @param o_error                       Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_professional_data
    (
        i_lang                       IN language.id_language%TYPE,
        i_id_professional            IN professional.id_professional%TYPE,
        i_id_market                  IN market.id_market%TYPE,
        o_ext_prof_professional      OUT pk_types.cursor_type,
        o_ext_prof_field_professinal OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals professional data
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_professional       Professional identifier
    * @param o_ext_prof_institutions Professional institutions
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_institutions_data
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_professional       IN professional.id_professional%TYPE,
        o_ext_prof_institutions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update/insert information for an external professional
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_title                 Professional Title
    * @param i_first_name            Professional first name
    * @param i_middle_name           Professional middle name
    * @param i_last_name             Professional last name
    * @param i_initials              Professional initials
    * @param i_dt_birth              Professional Date of Birth
    * @param i_gender                Professioanl gender
    * @param i_street                Professional adress
    * @param i_zip_code              Professional zip code
    * @param i_city                  Professional city
    * @param i_id_country            Professional country
    * @param i_phone                 Professional phone
    * @param i_cell_phone            Professional mobile phone
    * @param i_fax                   Professional fax
    * @param i_email                 Professional email
    * @param i_num_order             Professional license number
    * @param i_id_institution        Institution ID
    * @param i_fields                List of dynamic fields
    * @param i_institution           Institutins for the dynamic fields
    * @param i_values                Information values for the dynamic fields
    * @param o_professional          Professional ID
    * @param o_error                 error    
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_professional
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_title           IN professional.title%TYPE,
        i_first_name      IN professional.first_name%TYPE,
        i_middle_name     IN professional.middle_name%TYPE,
        i_last_name       IN professional.last_name%TYPE,
        i_initials        IN professional.initials%TYPE,
        i_dt_birth        IN VARCHAR2,
        i_gender          IN professional.gender%TYPE,
        i_street          IN professional.address%TYPE,
        i_zip_code        IN professional.zip_code%TYPE,
        i_city            IN professional.city%TYPE,
        i_id_country      IN professional.id_country%TYPE,
        i_phone           IN professional.num_contact%TYPE,
        i_cell_phone      IN professional.cell_phone%TYPE,
        i_fax             IN professional.fax%TYPE,
        i_email           IN professional.email%TYPE,
        i_num_order       IN professional.num_order%TYPE,
        i_speciality      IN professional.id_speciality%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_fields          IN table_number,
        i_institution     IN table_number,
        i_values          IN table_varchar,
        o_professional    OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update/insert information for an external user linked to external institutions
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_professional       External Professional ID
    * @param i_institution           External institutions ID's
    * @param i_dt_begin              External institutions and professional relation: Date begin
    * @param i_dt_begin              External institutions and professional relation: Date end
    * @param i_flg_state             External institutions and professional relation: State
    * @param i_inst_delete           External associations to delete
    * @param o_error                 error    
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_prof_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_institution     IN table_number,
        i_dt_begin        IN table_varchar,
        i_dt_end          IN table_varchar,
        i_flg_state       IN table_varchar,
        i_inst_delete     IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Count external professionals
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institutions ID
    * @param i_name                  External professional name
    * @param i_category              External professional Type
    * @param i_city                  External professional City
    * @param i_postal_code           External professional Postal Code
    * @param i_postal_code_from      External professionals range of postal codes
    * @param i_postal_code_to        External professionals range of postal codes
    * @param i_search                Search
    * @param o_ext_prof_count        List of external professionals
    * @param o_error                 error    
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_prof_count
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN professional.city%TYPE,
        i_postal_code      IN professional.zip_code%TYPE,
        i_postal_code_from IN professional.zip_code%TYPE,
        i_postal_code_to   IN professional.zip_code%TYPE,
        i_search           IN VARCHAR2,
        o_ext_prof_count   OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Find external professionals data
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institutions ID
    * @param i_name                  External professional name
    * @param i_category              External professional Type
    * @param i_city                  External professional City
    * @param i_postal_code           External professional Postal Code
    * @param i_postal_code_from      External professionals range of postal codes
    * @param i_postal_code_to        External professionals range of postal codes
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/04
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_prof_data
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN professional.city%TYPE,
        i_postal_code      IN professional.zip_code%TYPE,
        i_postal_code_from IN professional.zip_code%TYPE,
        i_postal_code_to   IN professional.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records
    ) RETURN t_table_stg_ext_prof;

    /********************************************************************************************
    * Find external professionals
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institutions ID
    * @param i_name                  External professional name
    * @param i_category              External professional Type
    * @param i_city                  External professional City
    * @param i_postal_code           External professional Postal Code
    * @param i_postal_code_from      External professionals range of postal codes
    * @param i_postal_code_to        External professionals range of postal codes
    * @param i_search                Search
    * @param i_start_record          Paging - initial recrod number
    * @param i_num_records           Paging - number of records to display
    * @param o_ext_prof_list         List of external professionals
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION find_ext_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_name             IN professional.name%TYPE,
        i_category         IN VARCHAR2,
        i_city             IN professional.city%TYPE,
        i_postal_code      IN professional.zip_code%TYPE,
        i_postal_code_from IN professional.zip_code%TYPE,
        i_postal_code_to   IN professional.zip_code%TYPE,
        i_search           IN VARCHAR2,
        i_start_record     IN NUMBER DEFAULT 1,
        i_num_records      IN NUMBER DEFAULT get_num_records,
        o_ext_prof_list    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update/insert information for an external user
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
    FUNCTION set_import_ext_professionals
    (
        i_lang             IN language.id_language%TYPE,
        i_stg_professional IN table_number,
        i_id_institution   IN institution.id_institution%TYPE,
        o_ext_prof         OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate Insitution External Professionals take over dates
    *
    * @param i_lang                 Language id
    * @param i_id_institution       Institution identifier
    * @param o_error                Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/06/03
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION validate_ext_prof_to
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate External Professionals take overs scheduled
    *
    * @param i_lang                  Language id
    * @param i_id_professional_to    External Professional identifier
    *
    * @return                       true ('Y'), false ('N')
    *
    * @author                       Tércio Soares
    * @since                        2010/06/04
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION verifiy_ext_prof_to_possible
    (
        i_lang               IN language.id_language%TYPE,
        i_id_professional_to IN professional_take_over.id_professional_to%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Set the External Professional take over
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_professional_from  External professional take over from id
    * @param i_id_professional_to    External professional take over to id
    * @param i_take_over_time        Take Over defined Time
    * @param i_notes                 Take Over notes
    * @param o_flg_status            Take over status
    * @param o_status_desc           Description of Take over status
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_ext_prof_to
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_professional_from IN professional_take_over.id_professional_from%TYPE,
        i_id_professional_to   IN professional_take_over.id_professional_to%TYPE,
        i_take_over_time       IN VARCHAR2,
        i_notes                IN professional_take_over.notes%TYPE,
        o_flg_status           OUT professional_take_over.flg_status%TYPE,
        o_status_desc          OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel an External Professional take over
    *
    * @param i_lang                  Language id
    * @param i_id_professional       External professional ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/03
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_ext_prof_to
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional_take_over.id_professional_from%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get External professional sys_domain list
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param i_sys_domain_column   Sys_domain column to return (1 - VAL, 2 - DESC_VAL, 3 - ICON)
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3
    * @since                       2010/07/02
    ********************************************************************************************/
    FUNCTION get_ext_state_list
    (
        i_lang              IN language.id_language%TYPE,
        i_code_domain       IN sys_domain.code_domain%TYPE,
        i_sys_domain_column IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns External institutions list not associated with an external professional
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_institution        Institution id
    * @param i_institution           Institution id already associated
    * @param o_ext_inst              External institution
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/06
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_inst_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_institution    IN table_number,
        o_ext_inst       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel an External Professionals
    *
    * @param i_lang                  Language id
    * @param i_professional          External professional ID's to cancel
    * @param i_id_institution        Institution ID
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_ext_professional
    (
        i_lang           IN language.id_language%TYPE,
        i_professional   IN table_number,
        i_id_institution IN prof_institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals Types list
    *
    * @param i_lang                  Language id
    * @param i_id_market             Market identifier
    * @param o_type_list             Professional types list
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        o_type_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate External Professionals data changed by the file imported to the staging area
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
    FUNCTION validate_ext_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals by License number
    *
    * @param i_lang                  Language id
    * @param i_license               License number
    * @param i_stg_license           Staging area license number
    * @param i_id_market             Market identifier
    * @param i_id_institution        Institution id
    * @param o_ext_prof              External professionals
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_by_license_number
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN professional_field_data.value%TYPE,
        i_stg_license    IN stg_professional_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_ext_prof       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns External Professionals list by License number
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
    FUNCTION get_ext_prof_list_by_lic_num
    (
        i_lang           IN language.id_language%TYPE,
        i_license        IN professional_field_data.value%TYPE,
        i_stg_license    IN stg_professional_field_data.value%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Compare an External Professional data with the staging area data
    *
    * @param i_lang                  Language id
    * @param i_id_professional       External professional ID
    * @param i_id_stg_professional   External professional ID in staging area
    * @param i_id_institution        Institution ID
    *
    * @return                        Flag of changed data ('Y' - different data, 'N' - no different data)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_data_update
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_stg_professional IN stg_professional.id_stg_professional%TYPE,
        i_id_institution      IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Compare an External Professional data with the staging area data
    *
    * @param i_lang                      Language id
    * @param i_id_professional           External professional ID
    * @param i_id_stg_professional       External professional ID's in staging area
    * @param i_id_institution            Institution ID
    * @param o_ext_prof_data             Cursor containing the different data
    * @param o_ext_prof_fields_data      Cursor containing the different data
    * @param o_ext_stg_prof_data         Cursor containing the different data
    * @param o_ext_stg_prof_fields_data  Cursor containing the different data
    * @param o_error                     Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/07/07
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_ext_prof_data_review
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_professional          IN professional.id_professional%TYPE,
        i_stg_professional         IN table_number,
        i_id_institution           IN institution.id_institution%TYPE,
        o_ext_prof_data            OUT pk_types.cursor_type,
        o_ext_prof_fields_data     OUT pk_types.cursor_type,
        o_ext_stg_prof_data        OUT pk_types.cursor_type,
        o_ext_stg_prof_fields_data OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Import the staging area data for an External Professional
    *
    * @param i_lang                  Language id
    * @param i_professional          External professional ID's
    * @param i_stg_professional      External professional ID in staging area
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
        i_lang             IN language.id_language%TYPE,
        i_professional     IN table_number,
        i_stg_professional IN table_number,
        i_id_institution   IN institution.id_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Reject the staging area data for an External Professional
    *
    * @param i_lang                  Language id
    * @param i_professional          External professional ID's
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
        i_professional   IN table_number,
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
    FUNCTION set_delete_stg_ext_prof_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get External professional speciality list
    *
    * @param i_lang                Prefered language ID
    * @param i_column              speciality column to return (1 - id, 2 - DESC)
    *
    *
    * @return                      specialities list (id or description)
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2011/04/07
    ********************************************************************************************/

    FUNCTION get_ext_prof_spec
    (
        i_lang   IN language.id_language%TYPE,
        i_column IN NUMBER
    ) RETURN VARCHAR2;
		
		/********************************************************************************************
    * Get External professional multichoice values and descriptions
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional id
    * @param i_area                Professional configuration area
    * @param i_argument            Professional configuration argument
    * @param i_column              column to return (1 - ID's list, 2 - DESCRIPTIONS list, 3 - ID, 4 - DESCRIPTION)
    *
    *
    * @return                      multichoice (id/description)
    *
    * @author                      JTS
    * @version                     2.6.1.13
    * @since                       2012/12/11
    ********************************************************************************************/
    FUNCTION get_ext_prof_mc_values
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_area            IN NUMBER,
        i_argument        IN NUMBER,
        i_column          IN NUMBER
    ) RETURN VARCHAR2;

    g_ext_prof_to_sch      CONSTANT professional_take_over.flg_status%TYPE := 'S';
    g_ext_prof_to_finished CONSTANT professional_take_over.flg_status%TYPE := 'F';
    g_ext_prof_active      CONSTANT prof_institution.flg_state%TYPE := 'A';

    g_error VARCHAR2(2000);

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_BACKOFFICE_EXT_PROF';

    g_country_pt  CONSTANT country.id_country%TYPE := 620;
    g_country_nl  CONSTANT country.id_country%TYPE := 528;
    g_country_usa CONSTANT country.id_country%TYPE := 840;
    g_country_uk  CONSTANT country.id_country%TYPE := 826;

    g_market_all CONSTANT market.id_market%TYPE := 0;
    g_market_pt  CONSTANT market.id_market%TYPE := 1;
    g_market_nl  CONSTANT market.id_market%TYPE := 5;
    g_market_usa CONSTANT market.id_market%TYPE := 2;
    g_market_uk  CONSTANT market.id_market%TYPE := 8;

    g_string_delim CONSTANT VARCHAR2(1) := '|';

    g_field_type_personal_data     CONSTANT field_type.id_field_type%TYPE := 1;
    g_field_type_personal_contacts CONSTANT field_type.id_field_type%TYPE := 2;
    g_field_type_prof_data         CONSTANT field_type.id_field_type%TYPE := 3;
    g_field_type_inst_data         CONSTANT field_type.id_field_type%TYPE := 4;
    g_field_type_inst_info         CONSTANT field_type.id_field_type%TYPE := 5;
    g_field_type_inst_adress       CONSTANT field_type.id_field_type%TYPE := 6;

    g_prof_inst_dn_validated CONSTANT prof_institution.dn_flg_status%TYPE := 'V';

    g_soft_backoffice CONSTANT software.id_software%TYPE := 26;

    g_field_inst_agb CONSTANT field.id_field%TYPE := 40;

    g_field_flg_pi_prof CONSTANT field.flg_field_prof_inst%TYPE := 'P';
    g_field_flg_pi_inst CONSTANT field.flg_field_prof_inst%TYPE := 'I';

    g_prof_backoffice CONSTANT professional.id_professional%TYPE := 0;

END pk_backoffice_ext_prof;
/
