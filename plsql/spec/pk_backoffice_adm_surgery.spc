/*-- Last Change Revision: $Rev: 2028508 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_adm_surgery IS

    -- Author  : ORLANDO.ANTUNES
    -- Created : 10-05-2010 11:06:50
    -- Purpose : This package supports the functionality - Backoffice for Admission and Surgery request. 
    -- This functionality allows the system administrator to manage the inpatient admissions, with or without surgery.

    --Global definitions
    g_dcs_separator_char          CONSTANT VARCHAR2(2 CHAR) := ': ';
    g_nch_1_period                CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_nch_2_period                CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_backoffice_parameterization CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_equipment_type_room         CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_equipment_type_bed          CONSTANT VARCHAR2(1 CHAR) := 'B';
    --bed type
    g_bed_type_permanent_p CONSTANT VARCHAR2(1 CHAR) := 'P';
    --bed occupation
    g_bed_occupation_v CONSTANT VARCHAR2(1 CHAR) := 'V';

    --department type
    g_department_urg CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_department_inp CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_department_obs CONSTANT VARCHAR2(2 CHAR) := 'IO';

    --active_state
    g_active CONSTANT VARCHAR2(1 CHAR) := 'A';

    --
    g_not_complete       CONSTANT VARCHAR2(4 CHAR) := ' ...';
    g_max_size_to_select CONSTANT PLS_INTEGER := 995;

    /********************************************************************************************
    * Get the list of Indications for admission 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of indications
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/10
    **********************************************************************************************/
    FUNCTION get_adm_indication_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_indications    OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the description of a given dep. clinical service (dcs) in the format: Service+Separator+Specialty
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of indications
    * @param o_error                  Error
    *
    * @return                         the dcs description
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/11
    **********************************************************************************************/
    FUNCTION get_dcs_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_dcs    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_separator IN VARCHAR2 DEFAULT g_dcs_separator_char
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get the description of a given Specialty
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_specialty           Specialty ID
    *
    * @return                         the specialty description
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_specialty_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_specialty IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get prefered dep. clinical service (dcs) for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of indications
    *
    * @return                         the prefered dcs id
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/11
    **********************************************************************************************/
    FUNCTION get_adm_indication_pref_dcs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN NUMBER;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @return                         the list dcs ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_dcs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list of escape services defined for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    *
    * @return                         the list escape services ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_adm_ind_esc_services
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) as a string for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    * @param i_id_adm_indication_hist Adm indication history Id
    *
    * @return                         the list of dcs as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_dcs_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_adm_indication      IN adm_indication.id_adm_indication%TYPE,
        i_id_adm_indication_hist IN adm_indication_hist.id_adm_indication_hist%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) as a string for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    *
    * @return                         the list of dcs as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_dcs_array
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_table_varchar;
    --

    /********************************************************************************************
    * Get the Indications for admission data for the create/edit screen
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication data   
    * @param o_indications            List of indications
    * @param o_indications_nch        NCH for the given indications
    * @param o_screen_labels          Screen labels
    * @param o_selected_dcs           Selected dep_clin_serv's
    * @param o_selected_serv          Selected services
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_edit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_indications       OUT pk_types.cursor_type,
        o_indications_nch   OUT pk_types.cursor_type,
        o_screen_labels     OUT pk_types.cursor_type,
        o_selected_dcs      OUT pk_types.cursor_type,
        o_selected_serv     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of services that are available in the instituion 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_services_list          List of services
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/13
    **********************************************************************************************/
    FUNCTION get_services_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_services_list  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the list of specialties available for a given service
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_service             Service ID
    * @param i_id_institution         Institution ID
    * @param o_services_list          List of specialties
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/13
    **********************************************************************************************/
    FUNCTION get_specialties_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_service     IN department.id_department%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        o_specialty_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of specialties available for a given service
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_dcs                 array with DSCs IDs 
    * @param i_id_institution         Institution ID
    * @param o_specialties_list       List of specialties
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/02
    **********************************************************************************************/
    FUNCTION get_specialties_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_dcs         IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_specialty_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Create admission indication.
    * This function allows the create of new indication (i_adm_indication = null) or the 
    * edit of an existing indication.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_adm_indication        Adm_indication ID (not null only for the edit operation)
    * @ param i_name                  Indication name
    * @ param i_services              List of serices for the indication
    * @ param i_pref_service          Preferential service 
    * @ param i_esc_services          List of escape services
    * @ param i_flg_escape            Flag that indicates the possible escape services: A - all, N - none, E - other
    * @ param i_urg_level             Urgency level
    * @ param i_exp_duration          Expected duration of admission
    * @ param i_state                 Indication state
    * @ param i_nch_1_startday        NCH startday for the first period
    * @ param i_nch_1_n_hours         NCH number of hours for the first period
    * @ param i_nch_2_startday        NCH startday for the second period
    * @ param i_nch_2_n_hours         NCH number of hours for the second period
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION set_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        --
        i_name                 IN adm_indication.code_adm_indication%TYPE,
        i_services             IN table_number,
        i_pref_service         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_esc_services         IN table_number,
        i_flg_escape           IN adm_indication.flg_escape%TYPE,
        i_urg_level            IN adm_indication.id_wtl_urg_level%TYPE,
        i_exp_duration         IN adm_indication.avg_duration%TYPE,
        i_state                IN adm_indication.flg_available%TYPE,
        i_nch_1_startday       IN nch_level.value%TYPE,
        i_nch_1_n_hours        IN nch_level.duration%TYPE,
        i_nch_2_startday       IN nch_level.value%TYPE,
        i_nch_2_n_hours        IN nch_level.duration%TYPE,
        i_adm_indication_multi IN adm_indication.id_adm_indication%TYPE,
        
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set of a new Admission indication state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_adm_indication        Adm_indication ID (not null only for the edit operation)
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION set_adm_indication_state
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        --
        i_state IN adm_indication.flg_available%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel an NCH perido for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_adm_indication     Adm_indication ID (not null only for the edit operation)
    * @ param i_nch_period            NHC period: F - first, S - second
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION cancel_adm_ind_nch_period
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_nch_period        IN VARCHAR2 DEFAULT 'S',
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of Escape services for a given Admission indication 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication     Adm_indication ID
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_escape_services_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list of Escape services for a given Admission indication, as string 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication     Adm_indication ID
    * @param o_escape_services        List of services
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_escape_services_list_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get the list of Escape services for a given Admission indication, as string 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication_hist    Adm indication history ID
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_escape_serv_list_str_hist
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_adm_indication_hist IN escape_department_hist.id_adm_indication_hist%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Cancel Admission indication.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication     Adm_indication ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_adm_indication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the Indications for admission detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID   
    * @param o_indication             List of indication details
    * @param o_indication_prof        List of professionals responsible for each action in 
    *                                 the given Indications
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_adm_indication_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_indication        OUT pk_types.cursor_type,
        o_indication_prof   OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************
    |             Urgency Level                 |
    ********************************************/

    /********************************************************************************************
    * Get the list of Urgency levels for a given institution 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_urgency_levels         List of Urgency levels
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_urgency_levels_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_urgency_levels OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of Urgency levels for a given institution. For each urgency level item only 
    * id|desc will be returned. To get the complete information of urgency levels the function 
    * get_urgency_levels_list should be used.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_urgency_levels         List of Urgency levels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/20
    **********************************************************************************************/
    FUNCTION get_urgency_levels
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_urgency_levels OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the Urgency level data data for the create/edit screen 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_urgency_level       Urgency level ID
    * @param o_urgency_level          Urgency level data details
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_urgency_levels_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_urgency_levels   OUT pk_types.cursor_type,
        o_screen_labels    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Set of a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_urgency_level      Urgency level ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_urgency_level
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_name             IN wtl_urg_level.code%TYPE,
        i_max_scheduling   IN wtl_urg_level.duration%TYPE,
        i_state            IN wtl_urg_level.flg_available%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Create a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_urgency_level      Urgency level ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_urgency_level_state
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        --
        i_state IN wtl_urg_level.flg_available%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel Urgency levels.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_urgency_level      Urgency level ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_urgency_level
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the Urgency level detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_urgency_level       Urgency level ID   
    * @param o_urgency_level          List of urgency level details
    * @param o_preparation_prof       List of professionals responsible for each action in 
    *                                 the given preparation
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_urgency_level_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_urgency_level   IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_urgency_level      OUT pk_types.cursor_type,
        o_urgency_level_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /*******************************************
    |             Preparation list              |
    ********************************************/

    /********************************************************************************************
    * Get the list of Preparatuions for admission 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_preparation            List of preparations
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_preparation_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_preparation    OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the Preparation data for the create/edit screen 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_preparation         Preparation ID
    * @param o_preparations           Preparation data details
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_preparation_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_preparation IN adm_preparation.id_adm_preparation%TYPE,
        o_preparations   OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create or update a Preparation.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_preparation        Preparation ID (not null only for the edit operation)
    * @ param i_name                  Preparation name
    * @ param i_state                 Preparation state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_preparation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_preparation IN adm_preparation.id_adm_preparation%TYPE,
        i_name           IN adm_preparation.code_adm_preparation%TYPE,
        i_state          IN adm_preparation.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set of a new Preparation state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_preparation        Preparation ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_preparation_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_preparation IN adm_preparation.id_adm_preparation%TYPE,
        i_state          IN adm_preparation.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel Preparations.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_preparation    Preparation ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_adm_preparation IN adm_preparation.id_adm_preparation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the Preparation detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_preparation         Preparation ID   
    * @param o_preparation            List of preparations
    * @param o_preparation_prof       List of professional responsible for each preparation
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_preparation_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_preparation   IN adm_preparation.id_adm_preparation%TYPE,
        o_preparation      OUT pk_types.cursor_type,
        o_preparation_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /*******************************************
    |             Admission types               |
    ********************************************/
    /********************************************************************************************
    * Get the list of Admission types 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of Admission types
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_admission_types_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institution  IN institution.id_institution%TYPE,
        o_admission_types OUT pk_types.cursor_type,
        o_screen_labels   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the Admission types data for the create/edit screen 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_type            Admission type ID
    * @param o_admission_types        List of Admission types
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_admission_types_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_adm_type     IN admission_type.id_admission_type%TYPE,
        o_admission_types OUT pk_types.cursor_type,
        o_screen_labels   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Set of a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_admission_type     Admission type ID 
    * @ param i_name                  Admission type name
    * @ param i_max_adm_time          Maximum time for admission 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/20
    **********************************************************************************************/
    FUNCTION set_admission_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_admission_type IN admission_type.id_admission_type%TYPE,
        i_name              IN admission_type.code_admission_type%TYPE,
        i_state             IN admission_type.flg_available%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    FUNCTION set_admission_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_admission_type IN admission_type.id_admission_type%TYPE,
        i_name              IN admission_type.code_admission_type%TYPE,
        i_max_adm_time      IN admission_type.max_admission_time%TYPE,
        i_state             IN admission_type.flg_available%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set of a new Admission type state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_adm_type           Admission type ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_admission_types_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_adm_type    IN admission_type.id_admission_type%TYPE,
        i_state          IN admission_type.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel Admission type.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_admission_type     Admission_type ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_admission_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_admission_type IN admission_type.id_admission_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the Admission type detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_admission_type         admission_type ID   
    * @param o_admission_type            List of admission_types
    * @param o_admission_type_prof       List of professional responsible for each admission_type
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_admission_type_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_admission_type   IN admission_type.id_admission_type%TYPE,
        o_admission_type      OUT pk_types.cursor_type,
        o_admission_type_prof OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /*******************************************
    |                    NCH                   |
    ********************************************/

    /********************************************************************************************
    * Create NCH periods 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_period                 ID NCH period
    * @param i_nch_startday           Start day 
    * @param i_nch_n_hours            Number of hours
    * @param i_id_nch_previous        ID NCH of the previous period
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/10
    **********************************************************************************************/
    FUNCTION create_nch_periods
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_period          IN VARCHAR2 DEFAULT 'F',
        i_nch_duration    IN nch_level.duration%TYPE,
        i_nch_n_hours     IN nch_level.value%TYPE,
        i_id_nch_previous IN nch_level.id_previous%TYPE,
        o_nch_id          OUT nch_level.id_nch_level%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get NCH periods for a given Indications for admission
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    * @param o_nch                    NCH information (First and Second periods)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/17
    **********************************************************************************************/
    FUNCTION get_nch_periods
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_nch               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update NCH periods 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_nch_level              ID NCH period
    * @param i_nch_duration           First period duration 
    * @param i_nch_n_hours            Number of hours for the first period
    * @param i_nch_2_n_hours          Number of hours for the second period  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/25
    **********************************************************************************************/
    FUNCTION update_nch_periods
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nch_level     IN nch_level.id_nch_level%TYPE,
        i_nch_duration  IN nch_level.duration%TYPE,
        i_nch_n_hours   IN nch_level.value%TYPE,
        i_nch_2_n_hours IN nch_level.duration%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the nch_level id for the given adm indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    * @param o_error                  Error
    *
    * @return                         The NCH ID, or null if the NCH doesn't exist
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/25
    **********************************************************************************************/
    FUNCTION get_adm_indication_nch
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN NUMBER;

    /*******************************************
    |             Equipment types              |
    ********************************************/

    /********************************************************************************************
    * Get the list of Equipment types for the institution
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_equipments             List of equipments
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION get_equipment_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_equipment      OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of bed types available in the institution
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_bed_type               List of bed types
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/07
    **********************************************************************************************/
    FUNCTION get_bed_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_bed_type       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of Room types available in the institution
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_room_type              List of room types
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/07
    **********************************************************************************************/
    FUNCTION get_room_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_room_type      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the equipment data for the create/edit screen 
    *
    * @param i_lang                 Preferred language ID for this professional 
    * @param i_prof                 Object (professional ID, institution ID, software ID)
    * @param i_id_equipment         Equipment ID
    * @param i_equipment_type       Equipment type: R - room, B - bed
    * @param o_equipments           Equipment data details
    * @param o_screen_labels        Screen labels
    * @param o_error                Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION get_equipment_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        o_equipment      OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Create a new equipment. The i_equipment_type defines if we are creating 
    * a new Room or a new Bed.
    *
    * @param i_lang                  Preferred language ID for this professional 
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID 
    * @param i_id_equipment          Equipment ID
    * @param i_name                  Equipment name
    * @param i_equipment_type        Equipment type: R - room, B - bed
    * @param i_state                 Equipment state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION set_equipment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_name           IN room_type.code_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        i_state          IN room_type.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Set of a new equipment state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_equipment          Equipment ID 
    * @param i_equipment_type         Equipment type: R - room, B - bed
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION set_equipment_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        i_state          IN room_type.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel equipments.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_equipment      Equipment ID
    * @param i_equipment_type         Equipment type: R - room, B - bed
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION cancel_equipment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the equipment detail. The i_equipment_type defines the type of equipment: Room or a Bed.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_equipment           Equipment ID   
    * @param i_equipment_type         Equipment type: R - room, B - bed
    * @param o_equipment              List of equipments
    * @param o_equipment_prof         List of professional responsible for each equipment
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION get_equipment_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        o_equipment      OUT pk_types.cursor_type,
        o_equipment_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of Admission types 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_admission_types        List of Admission types
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/1
    **********************************************************************************************/
    FUNCTION get_admission_types
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institution  IN institution.id_institution%TYPE,
        o_admission_types OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************
    |                  Rooms                   |
    ********************************************/

    /********************************************************************************************
    * Get the list of rooms for a given institution with all details that includes:
    *     Number of beds, room type, Service, Specialtya and status
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_rooms                  List of Rooms
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institutiton IN institution.id_institution%TYPE,
        o_rooms           OUT pk_types.cursor_type,
        o_screen_labels   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    *
    * @return                         the list dcs ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_room_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN VARCHAR2
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list of specialties for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    *
    * @return                         the list specialties ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_specialties
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get a list dep. clinical service (dcs) as a string for a list of ids
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dcs_list               List id DCS IDs
    *
    * @return                         the list of dcs as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_dcs_list_as_str
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dcs_list       IN table_number,
        i_separator_char IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get a list of specialties as a string
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_specialties_list       List of specialties IDs
    *
    * @return                         the list of specialties as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_specialties_list_as_str
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_specialties_list IN table_number,
        i_separator_char   IN VARCHAR2
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get the room data for the create/edit screen 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Rooms
    * @param o_beds                   List of beds for the selected room
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_room       IN VARCHAR2,
        o_room          OUT pk_types.cursor_type,
        o_beds          OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /*******************************************
    |                  Beds                    |
    ********************************************/

    /********************************************************************************************
    * Get the list of bed for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Beds
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_beds_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN institution.id_institution%TYPE,
        o_beds    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of beds for a given room with all information to edit the room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Beds
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/07
    **********************************************************************************************/
    FUNCTION get_beds_edit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN VARCHAR2,
        o_beds    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of bed for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Beds
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/05/31
    **********************************************************************************************/
    FUNCTION get_bed_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_bed        IN institution.id_institution%TYPE,
        o_bed           OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get the list of specialties for a given bed
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_bed                 Bed ID
    *
    * @return                         the list specialties ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/05/31
    **********************************************************************************************/
    FUNCTION get_bed_specialties
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list of specialties for a given bed history record
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_bed_hist            Bed history Id
    *
    * @return                         the list specialties ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/18
    **********************************************************************************************/
    FUNCTION get_bed_hist_specialties
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_bed_hist IN bed_hist.id_bed_hist%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list of dep. clinical service (dcs) for a given bed
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_bed                 Bed ID
    *
    * @return                         the list dcs ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_bed_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Get the list of beds for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    *
    * @return                         the list beds ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_room_beds
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN table_number;
    --

    /********************************************************************************************
    * Create or edit a room and all the beds associated with it.
    *
    * @param i_lang                       Preferred language ID for this professional 
    * @param i_prof                       Object (professional ID, institution ID, software ID)
    * @ param i_id_institution            Institution ID 
    * @ param i_id_room                   Room ID (not null only for the edit operation)
    *
    * @ param i_name                      room name
    * @ param i_abbreviation              room abbreviation
    * @ param i_category                  room category
    * @ param i_room_type                 room type
    * @ param i_room_service              select room service
    * @ param i_room_specialties          list of specialties
    * @ param i_flg_selected_spec         Flag that indicates the type of selection of specialties: 
    *                                     A - all, N - none, O - other
    * @ param i_state                     room state (Y - active/N - Inactive)
    * @ param i_beds_name                 array with beds names
    * @ param i_beds_type                 array with beds types
    * @ param i_beds_specialties          array with beds specialties
    * @ param i_beds_flg_selected_spec    array with flags indicating the type of selection of specialties: 
    *                                     A - all, N - none, O - other
    * @ param i_beds_state                array with beds states (Y - active/N - Inactive)
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION set_room
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        --
        i_name              IN room.code_room%TYPE,
        i_abbreviation      IN room.code_room%TYPE,
        i_category          IN table_varchar,
        i_room_type         IN room_type.id_room_type%TYPE,
        i_room_service      IN room.id_department%TYPE,
        i_room_specialties  IN table_number,
        i_flg_selected_spec IN room.flg_selected_specialties%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        i_state             IN room.flg_available%TYPE,
        --beds
        i_beds_id                IN table_number,
        i_beds_name              IN table_varchar,
        i_beds_type              IN table_number,
        i_beds_specialties       IN table_table_number,
        i_beds_flg_selected_spec IN table_varchar,
        i_beds_state             IN table_varchar,
        --
        i_capacity IN room.capacity%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Create a bed.
    *
    * @param i_lang                      Preferred language ID for this professional 
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @ param i_id_institution           Institution ID 
    * @ param i_id_room                  Room ID (not null only for the edit operation)
    * @ param i_bed_name                 bed name
    * @ param i_bed_type                 bed type
    * @ param i_bed_specialties          array with bed specialties
    * @ param i_bed_flg_selected_spec    flg indicating the type of selection of specialties: 
    *                                     A - all, N - none, O - other
    * @ param i_bed_state                bed state (Y - active/N - Inactive)
    * @ param i_bed_date                 bed creation date [default NULL]
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION set_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        i_id_room_hist   IN room_hist.id_room_hist%TYPE,
        --beds
        i_bed_id                IN bed.id_bed%TYPE,
        i_bed_name              IN pk_translation.t_desc_translation,
        i_bed_type              IN bed_type.id_bed_type%TYPE,
        i_bed_specialties       IN table_number,
        i_bed_flg_selected_spec IN VARCHAR2,
        i_bed_state             IN bed.flg_available%TYPE,
        i_bed_date              IN bed.dt_creation%TYPE DEFAULT NULL,
        i_commit                IN VARCHAR2 DEFAULT 'N',
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set of a new room state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_room               Room ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/31
    **********************************************************************************************/
    FUNCTION set_room_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        i_state          IN room.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel room.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_room               Room ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION cancel_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancel bed.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_bed                bed ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/02
    **********************************************************************************************/
    FUNCTION cancel_bed
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_bed       IN bed.id_bed%TYPE,
        i_id_room_hist IN room_hist.id_room_hist%TYPE DEFAULT NULL,
        i_commit       IN VARCHAR2 DEFAULT 'N',
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the room detail.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                room ID   
    * @param o_room                   List of rooms
    * @param o_room_prof              List of professional responsible for each room
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_room_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_room   IN room_type.id_room_type%TYPE,
        o_room      OUT pk_types.cursor_type,
        o_room_prof OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --

    FUNCTION get_beds_detail_str
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room_hist.id_room_hist%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * Get Room Floor description
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_room               Room ID
    *
    *
    * @return                      Floor description
    *
    * @author                      Orlando Antunes
    * @version                     2.6.0.3
    * @since                       2010/06/02
    ********************************************************************************************/
    FUNCTION get_room_floor_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR;
    --

    /********************************************************************************************
    * Checks if all beds of a given room are available
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_id_room                Room ID
    *
    * @return                         'Y' if all beds of this room are available or 'N' otherwise
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/14
    **********************************************************************************************/
    FUNCTION has_all_beds_available
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN institution.id_institution%TYPE
    ) RETURN VARCHAR;
    /********************************************************************************************
    * Get the list of specialities for a given bed 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param i_id_bed                 Bed ID
    * @param o_error                  Error
    *
    * @return                         CLOB with specialities associated to a bed
    *
    * @author                          Rui Gomes
    * @version                         2.6.0.5
    * @since                           2011/03/18
    **********************************************************************************************/
    FUNCTION get_bed_room_dcs_match
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN VARCHAR2,
        i_id_bed  IN bed.id_bed%TYPE
    ) RETURN CLOB;
    --

    /********************************************************************************************
    * Get the list of specialties for a given bed history record
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room_hist           Room history Id
    *
    * @return                         the list specialties ids
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1
    * @since                           14-Apr-2011
    **********************************************************************************************/
    FUNCTION get_room_hist_specialties
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_room_hist IN room_hist.id_room_hist%TYPE
    ) RETURN table_number;

	/********************************************************************************************
    * Insert the history of the room
    *
    * @param i_lang                     Preferred language ID for this professional
    * @param i_id_room_hist             Room ID History
    * @param i_id_room                  Room ID
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.6
    * @since                            2018/06/14
    **********************************************************************************************/
    FUNCTION insert_room_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_id_room_hist IN room_hist.id_room_hist%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_backoffice_adm_surgery;
/
