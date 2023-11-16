/*-- Last Change Revision: $Rev: 2028976 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_social IS

    TYPE home_rec IS RECORD(
        id                           home.id_home%TYPE,
        field_title                  sys_message.desc_message%TYPE,
        field                        sys_message.desc_message%TYPE,
        field_value                  sys_message.desc_message%TYPE,
        order_date                   VARCHAR2(20 CHAR),
        hfc_rank                     home_field_config_mkt.rank%TYPE,
        hf_rank                      home_field.rank%TYPE,
        id_home_field                home_field.id_home_field%TYPE,
        intern_name_sample_text_type home_field.intern_name_sample_text_type%TYPE,
        domain                       home_field.domain%TYPE,
        flg_data_type                home_field.flg_data_type%TYPE,
        flg_mandatory                home_field_config_mkt.flg_mandatory%TYPE,
        min_value                    home_field_config_mkt.min_value%TYPE,
        max_value                    home_field_config_mkt.max_value%TYPE,
        mask                         home_field_config_mkt.mask%TYPE);

    TYPE home_table IS TABLE OF home_rec;

    TYPE home_hist_rec IS RECORD(
        id_home_hist    home_hist.id_home_hist%TYPE,
        dt_home_hist    home_hist.dt_home_hist%TYPE,
        id_professional home_hist.id_professional%TYPE,
        flg_status      home_hist.flg_status%TYPE);

    TYPE home_hist_table IS TABLE OF home_hist_rec;

    /********************************************************************************************
    * Get home table function 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_market              market identifier
    * @param i_active                 get active or inactive
    * @param i_ids                    table with id's to select
    * @param i_table                  table to select
    *
    * @return                         pipelined table
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_home_field_tf
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_market IN market.id_market%TYPE,
        i_active    IN VARCHAR2,
        i_ids       IN table_number,
        i_table     IN VARCHAR2
    ) RETURN home_table
        PIPELINED;
    /********************************************************************************************
    * Get home table function 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 patient identifier
    * @param i_rownum                 rownumber
    * @param i_show_cancelled         flg show cancelled
    *
    * @return                         pipelined table
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_home_hist_tf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat         IN patient.id_patient%TYPE,
        i_rownum         IN NUMBER,
        i_show_cancelled IN VARCHAR2
    ) RETURN home_hist_table
        PIPELINED;
    -- Purpose : Functions for Social Assistant Software

    /********************************************************************************************
     * Create patient's family members
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_name                   Family member's name
     * @param i_gender                 Family member's gender
     * @param i_dt_birth               Family member's birth date
     * @param i_id_family_relationship Family relationship     
     * @param i_marital_status         Marital status
     * @param i_scholarship            Scholarship
     * @param i_pension                Pension value
     * @param i_net_wage               Net wage value
     * @param i_unemployment_subsidy   Subsidy value
     * @param i_job                    Job/occupation
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2007/12/19
    **********************************************************************************************/

    FUNCTION create_pat_family
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_pat                 IN patient.id_patient%TYPE,
        i_prof                   IN profissional,
        i_name                   IN patient.name%TYPE,
        i_gender                 IN patient.gender%TYPE,
        i_dt_birth               IN patient.dt_birth%TYPE,
        i_id_family_relationship IN pat_family_member.id_family_relationship%TYPE,
        i_marital_status         IN pat_soc_attributes.marital_status%TYPE,
        i_scholarship            IN pat_soc_attributes.id_scholarship%TYPE,
        i_pension                IN pat_soc_attributes.pension%TYPE,
        i_currency_pension       IN currency.id_currency%TYPE,
        i_net_wage               IN pat_soc_attributes.net_wage%TYPE,
        i_currency_net_wage      IN currency.id_currency%TYPE,
        i_unemployment_subsidy   IN pat_soc_attributes.unemployment_subsidy%TYPE,
        i_currency_unemp_sub     IN currency.id_currency%TYPE,
        i_job                    IN pat_job.id_occupation%TYPE,
        i_occupation_desc        IN pat_job.occupation_desc%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION create_pat_family_internal
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_pat                 IN patient.id_patient%TYPE,
        i_id_new_pat             IN patient.id_patient%TYPE,
        i_prof                   IN profissional,
        i_name                   IN patient.name%TYPE,
        i_gender                 IN patient.gender%TYPE,
        i_dt_birth               IN patient.dt_birth%TYPE,
        i_id_family_relationship IN pat_family_member.id_family_relationship%TYPE,
        i_marital_status         IN pat_soc_attributes.marital_status%TYPE,
        i_scholarship            IN pat_soc_attributes.id_scholarship%TYPE,
        i_pension                IN pat_soc_attributes.pension%TYPE,
        i_currency_pension       IN currency.id_currency%TYPE,
        i_net_wage               IN pat_soc_attributes.net_wage%TYPE,
        i_currency_net_wage      IN currency.id_currency%TYPE,
        i_unemployment_subsidy   IN pat_soc_attributes.unemployment_subsidy%TYPE,
        i_currency_unemp_sub     IN currency.id_currency%TYPE,
        i_job                    IN pat_job.id_occupation%TYPE,
        i_occupation_desc        IN pat_job.occupation_desc%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_family_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat      OUT pk_types.cursor_type,
        o_pat_prob OUT pk_types.cursor_type,
        o_epis     OUT pk_types.cursor_type,
        o_shortcut OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get total and per capita family budget.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_allowance_family        Abonos
     * @param i_allowance_complementary Abonos complementares ID
     * @param i_subsidy                 Subs?os
     * @param i_other                   Outros
     * @param i_fixed_expenses          Despesas fixas
     * @param i_total                   Total do rendimento do agregado familiar do paciente
     * @param i_tot_person              N? de pessoas do agragado familiar do paciente
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
    ) RETURN BOOLEAN;

    ---------------------- ***** CLASSE SOCIAL ***** ------------------------------------------

    FUNCTION get_val_graf_crit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_id_pat_graf_crit IN graffar_criteria.id_graffar_criteria%TYPE,
        o_val_g_crit       OUT graffar_crit_value.val%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_social_class
    (
        i_lang            IN language.id_language%TYPE,
        i_class_number    IN social_class.val_max%TYPE,
        o_id_social_class OUT social_class.id_social_class%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient's social class and its criteria values to use in the summary page
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient             Patient ID      
     * @param o_id_pat_fam_soc_class   Patient family social class id
     * @param o_pat_fam_soc_desc       Patient's social class
     *
     * @return                         True on success, False otherwise
     *
     * @author                         Diogo Oliveira
     * @version                        v2.7.3.6
     * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_soc_class_summary_page
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        o_id_pat_fam_soc_class OUT pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE,
        o_pat_fam_soc_desc     OUT VARCHAR2
    ) RETURN BOOLEAN;

    ---------------------- ***** LISTAS ***** ------------------------------------------

    /********************************************************************************************
     * Get family relationships list.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_gender                 Gender
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_relationship           List
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2007/12/24
    **********************************************************************************************/

    FUNCTION get_relationship_list
    (
        i_lang         IN language.id_language%TYPE,
        i_gender       IN patient.gender%TYPE,
        i_prof         IN profissional,
        o_relationship OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_wc_location_list
    (
        i_lang            IN language.id_language%TYPE,
        o_flg_wc_location OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_water_origin_list
    (
        i_lang             IN language.id_language%TYPE,
        o_flg_water_origin OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_conserv_list
    (
        i_lang        IN language.id_language%TYPE,
        o_flg_conserv OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_owner_list
    (
        i_lang      IN language.id_language%TYPE,
        o_flg_owner OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_hab_type_list
    (
        i_lang         IN language.id_language%TYPE,
        o_flg_hab_type OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get home location list.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_flg_hab_location       List
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/12/18
    **********************************************************************************************/

    FUNCTION get_flg_hab_location_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_flg_hab_location OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_light_list
    (
        i_lang      IN language.id_language%TYPE,
        o_flg_light OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------- *****  ***** ------------------------------------------

    FUNCTION set_pat_fam
    (
        i_lang       IN language.id_language%TYPE,
        i_id_pat     IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_id_pat_fam OUT patient.id_pat_family%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Registar o familiar do paciente
       PARAMETROS:  Entrada: I_LANG - L?ua registada como prefer?ia do profissional
               I_ID_PAT - ID do paciente.
        
              Saida:   O_ID_PAT_FAM - ID do familiar
                             O_ERROR - erro
        
      CRIA!O: ET 2006/04/13
      NOTAS:
    *********************************************************************************/
    FUNCTION set_pat_fam
    (
        i_lang       IN language.id_language%TYPE,
        i_id_pat     IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_commit     IN VARCHAR2,
        o_id_pat_fam OUT patient.id_pat_family%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------- ***** REQUISI??O DE PEDIDOS SOCIAIS ***** ------------------------------------------

    FUNCTION get_soc_epis_req_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_s_epis  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------- ****** SOCIAL SITUATION ***** --------------------------------------------------

    FUNCTION get_soc_epis_sit
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE,
        i_prof    IN profissional,
        o_s_epis  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------- ****** SOCIAL INTERVENTION ***** --------------------------------------------------

    FUNCTION get_soc_epis_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis         IN social_episode.id_social_episode%TYPE,
        i_new_interv      IN VARCHAR2 DEFAULT 'N',
        o_soc_epis_interv OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------- ****** SOCIAL SOLUTION ***** --------------------------------------------------

    FUNCTION get_soc_epis_sol
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE,
        i_prof    IN profissional,
        o_s_epis  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------- ****** SOCIAL DISCHARGE ***** --------------------------------------------------

    FUNCTION get_title_cont
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_title_cont OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get currency's description
    *
    * @param       I_LANG             Predefined language
    * @param       I_PROF             Profissional ID
    * @param       O_CURRENCY         Currency name
    * @param       O_ERROR            Error message
    *
    * @return      boolean
    * @author      Thiago Brito
    * @version     2.4.3
    * @since       2008/05/15
    */
    FUNCTION get_currency_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2 DEFAULT 'Y',
        o_currency OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This is a copy of PK_LIST.get_occup_list that was done
     * in order to change the <<nenhum>> option for <<outro>>.
     * This functionality will be centralized in further release.
     *
     * @param id_lang     language identification
     * @param o_occup     list of all occupations
     * @param o_error     error message
     *
     * @return boolean
     *
     * @author Thiago Brito
     * @since  23-JUL-2008
    */
    FUNCTION get_occup_list
    (
        i_lang     IN language.id_language%TYPE,
        i_show_all IN VARCHAR2 DEFAULT 'Y',
        o_occup    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------Version 2.6.0.1-------------------------------------

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
     * @author                          ET
     * @version                         0.1
     * @since                           2006/04/17
    **********************************************************************************************/
    FUNCTION get_home_2
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

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
    FUNCTION get_home_edit
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_home OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    FUNCTION get_social_status_menu
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_social_status_menu    OUT pk_types.cursor_type,
        o_social_status_actions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the social status screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_status_labels   Social status screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_labels
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_social_status_labels OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
    --

    FUNCTION set_home_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_home IN home.id_home%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Cancel home.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
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
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient's job (the last one)
     * This functions is only a wrapper to the original function created in the pk_patient package
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param o_error                  Error
     *
     * @return                         the patient's job
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_pat_job
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
     * Get patient's family doctor
     *
     * @param i_lang                   Preferred language ID for this professional     
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_error                  Error
     *
     * @return                         the patient's job
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_family_doctor
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        i_return_name IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR;

    /********************************************************************************************
     * Get patient's household information, that includes: photo, kinship, name/profession, wage, etc
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat                    Family grid
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_household
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient's household information to show in the summary screen
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professional
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/06/25
    **********************************************************************************************/
    FUNCTION get_household_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get the household information for the create/edit screen. If no information exists 
     * for the given patient the cursor returns only the screen's labels, otherwise it 
     * returns the information previously created.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_id_pat_household       Patient ID for the household member to edit
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
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_g_crit             Info
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        o_social_class      OUT pk_types.cursor_type,
        o_prof_social_class OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_graf_crit              Criteria ID 
     *
     * @param o_crit                   Criteria values for a given criteria
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_graff_criteria_value_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_graf_crit IN graffar_criteria.id_graffar_criteria%TYPE,
        o_crit      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
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
    FUNCTION get_household_financial
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        i_show_cancel        IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label  IN VARCHAR2 DEFAULT 'N',
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get domains values for the household financial fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
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
    ) RETURN BOOLEAN;

    --
    FUNCTION set_household_fin_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat       IN patient.id_patient%TYPE,
        i_id_fam_money IN family_monetary.id_family_monetary%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION set_cancel_household_financial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_fam_money  IN family_monetary.id_family_monetary%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_pat_graff_criteria_id
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_criteria IN graffar_criteria.id_graffar_criteria%TYPE
    ) RETURN pat_graffar_crit.id_pat_graffar_crit%TYPE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    FUNCTION get_household_financial_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * 
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
    * @since                           2010/02/17
    **********************************************************************************************/
    FUNCTION get_graf_crit_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat                 IN patient.id_patient%TYPE,
        i_id_pat_graf_crit       IN graffar_criteria.id_graffar_criteria%TYPE,
        i_pat_fam_soc_class_hist IN pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE
    ) RETURN VARCHAR;

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
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*
    * Build status string for social assistance requests. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION get_req_status_str
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN social_epis_request.flg_status%TYPE,
        i_dt_req IN social_epis_request.dt_creation_tstz%TYPE
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /*
    * Get social services requests list.
    * Used in the clinical profiles.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Orlando Antnes
    * @version                 2.6.0.1
    * @since                  2010/03/19
    */
    FUNCTION get_social_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_grid_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create new or edit household members. When the parameter i_id_pat_household is not null 
    * we are editing the family member information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_pat                 Patient ID
    * @ param i_id_pat_household       Household patient ID to edit
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
        i_fam_doctor                IN pat_professional_inst.id_professional%TYPE,
        i_free_text_fam_doctor      IN pat_professional_inst.desc_professional%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get domains values for the household fields (gender, marital status, relationship, occupation).
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *    
    * @ param o_gender_domain         Gender list
    * @ param o_marital_domain        Marital status list  
    * @ param o_relationship_domain   Relationship list 
    * @ param o_occupation_domain     Occupation list
    * @ param o_currency_domain       Currency list
    * @ param o_dependency            Dependency list
    * @ param o_prof_list             List of doctors
    
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get values for the dependency list
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_dependency             List of dependency values
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         2.6.0.1
     * @since                           2010/03/08
    **********************************************************************************************/
    FUNCTION get_dependency_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_dependency OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient's household members
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient             Patient ID     
     * @param o_tbl_id_patient         Table of patient ids
     * @param o_tbl_household_desc     Patient's household members information
     *
     * @return                         True on success, False otherwise
     *
     * @author                         Diogo Oliveira
     * @version                        v2.7.3.6
     * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_household_summary_page
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        o_tbl_id_patient     OUT table_number,
        o_tbl_household_desc OUT table_varchar
    ) RETURN BOOLEAN;

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
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_social_report         Social report
    * @ param o_social_report_prof    Professional that creates/edit the social report
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
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
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the EHR social summary
    * (implementation of get_social_summary_ehr for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_labels       labels
    * @param o_episodes_det episodes
    * @param o_diagnosis    social diagnoses
    * @param o_interv_plan  social intervention plans
    * @param o_follow_up    follow up notes
    * @param o_soc_report   social report
    * @param o_soc_request  previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    FUNCTION get_social_summary_ehr_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_labels       OUT pk_types.cursor_type,
        o_episodes_det OUT pk_types.cursor_type,
        o_diagnosis    OUT pk_types.cursor_type,
        o_interv_plan  OUT pk_types.cursor_type,
        o_follow_up    OUT pk_types.cursor_type,
        o_soc_report   OUT pk_types.cursor_type,
        o_soc_request  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get patient's household financial information
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient             Patient ID     
     * @param o_id_fam_mon             Family monetary id
     * @param o_house_fin_desc         Patient's household financial information
     *
     * @return                         True on success, False otherwise
     *
     * @author                         Diogo Oliveira
     * @version                        v2.7.3.6
     * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_house_fin_summary_page
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        o_id_fam_mon     OUT family_monetary.id_family_monetary%TYPE,
        o_house_fin_desc OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the episodes detail information 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_social_episodes_det
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's list of episode of a given type 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param i_id_epis_type          List of epis types
    * @ param i_remove_status         Episode status to remove from the list
    * @ param o_episodes_ids          List of episode IDs
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_epis_by_type_and_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis_type  IN table_number,
        i_remove_status IN table_varchar DEFAULT table_varchar(pk_alert_constant.g_flg_status_c),
        --list of episodes
        o_episodes_ids OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION adt_next_key
    (
        table_name IN VARCHAR2,
        i_prof     IN profissional
    ) RETURN patient.id_patient%TYPE;

    /********************************************************************************************
    * Get social episode type
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID
    *
    * @return                         A for appointments or R for requests
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/24
    **********************************************************************************************/
    FUNCTION get_social_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get patient's household data for the report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_household_report
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get patient's home data for the report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_home_report
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --
        o_pat      OUT pk_types.cursor_type,
        o_pat_prof OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get intervention plans data for the given episode to be used in report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_interv_plan_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_soc_epis_interv OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Get social assistence requests data for the given episode to be used in report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_s_epis                Social assistence requests data
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_request_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_s_epis      OUT pk_types.cursor_type,
        o_s_epis_prof OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get social followup notes data for the given episode to be used in report. 
    * This data includes the Social situation information that was migrated into this new 
    * funcionality in version 2.6.0.1.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_s_epis                Follow up data
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_followup_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_s_epis      OUT pk_types.cursor_type,
        o_s_epis_prof OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* Get Social report's data for the given episode 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_s_epis      OUT pk_types.cursor_type,
        o_s_epis_prof OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
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
    FUNCTION get_home_2_report
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
     * Get patient's household history information.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
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
     * @since                           2006/11/06
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
    ) RETURN BOOLEAN;
    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_g_crit             Info
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_report
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        o_social_class      OUT pk_types.cursor_type,
        o_prof_social_class OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
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
    FUNCTION get_household_financial_report
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        i_show_cancel        IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label  IN VARCHAR2 DEFAULT 'N',
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
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
    FUNCTION get_household_fin_hist_report
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
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
    FUNCTION get_social_class_hist_report
    
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_pat                IN patient.id_patient%TYPE,
        i_prof                  IN profissional,
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
    /***
    * Checks if a home_field is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_home_field          home_field identifier
    * @param i_market                 market identifier
    * @param i_flg_active             'Y' or 'N'    
    *
    * @return  id_home_field_config_mkt
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2011/08/25
    */
    FUNCTION get_hfcm_pk
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_home_field IN home_field.id_home_field%TYPE,
        i_market        IN market.id_market%TYPE,
        i_flg_active    IN home_field_config_mkt.flg_active%TYPE
    ) RETURN NUMBER;
    /***
    * Checks if a home_field is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_home_field          home_field identifier
    * @param i_flg_active             'Y' or 'N'
    *
    * @return  id_home_field_config
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2011/08/25
    */
    FUNCTION get_hfc_pk
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_home_field IN home_field.id_home_field%TYPE,
        i_flg_active    IN home_field_config.flg_active%TYPE
    ) RETURN NUMBER;
    /***
    * get field 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id                     identifier 
    * @param i_home_field             home_field
    * @param i_table                  table
    *
    * @return  value
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2011/08/25
    */
    FUNCTION get_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id         IN NUMBER,
        i_home_field IN home_field.home_field%TYPE,
        i_table      IN VARCHAR2
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get patient's home characteristics history
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    
    * @param o_id_home                id_home out
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          paulo teixeira
    * @version                         0.1
    * @since                           2011/08/29
    **********************************************************************************************/
    FUNCTION get_home_edit_new
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_home OUT pk_types.cursor_type,
        o_id_home  OUT home.id_home%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
     * Save family home conditions.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)     
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     * @param i_id_home_field           home_field identifier array
     * @param i_table_flg               home_field falgs array
     * @param i_table_desc              home_field discriptions array        
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Paulo teixeira
     * @version                          0.1
     * @since                            2011/08/28
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
    ) RETURN BOOLEAN;
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
    * @author                          paulo teixeira
    * @version                         0.1
    * @since                           2011/08/29
    **********************************************************************************************/
    FUNCTION get_home_new
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        i_show_inactive     IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
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
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_home_new_report
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's home characteristics for the summary page
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)    
    * @param i_id_patient             Patient ID 
    * @param o_id_home                Home id
    * @param o_home_desc              Patient's home characteristics
    *
    * @return                         True on success, False otherwise
    *
    * @author                         Diogo Oliveira
    * @version                        v2.7.3.6
    * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_home_summary_page
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_id_home    OUT home.id_home%TYPE,
        o_home_desc  OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get ids home hist 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 patient identifier
    * @param i_rownum                 rownumber
    * @param i_show_cancelled         show cancelled
    *
    * @return                         id's home_hist
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/09/08
    **********************************************************************************************/
    FUNCTION get_ids_home_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat         IN patient.id_patient%TYPE,
        i_rownum         IN NUMBER,
        i_show_cancelled IN VARCHAR2
    ) RETURN table_number;
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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create a follow-up request and sets it as accepted. To be used in the All patient button when
    * the user presses OK in a valid episode (those without follow-up). Also used in the same button
    * inside the dietitian software.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             episode that will be followed
    * @param i_id_patient             episode patient
    * @param i_id_dcs                 episode dcs
    * @param i_id_prof                professional that is creating this follow up
    * @param i_id_opinion_type        1 = dietitian;  3 = soc worker
    * @param o_id_opinion             resulting follow up request id
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
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof         IN opinion.id_prof_questioned%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        o_id_opinion      OUT opinion.id_opinion%TYPE,
        o_id_episode      OUT opinion.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the episodes detail information, within a list of episodes 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episodes ID    
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Teresa Coutinho
    * @version                         0.1
    * @since                           2014/09/19
    **********************************************************************************************/
    FUNCTION get_social_episodes_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN table_number,
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get patient's list of social episodes and social followup requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param i_remove_status         Episode status to remove from the list
    * @ param o_episodes_ids          List of episode IDs
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Teresa Coutinho
    * @version                         0.1
    * @since                           2014/09/19
    **********************************************************************************************/

    FUNCTION get_epis_by_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis_type  IN table_number,
        i_remove_status IN table_varchar DEFAULT table_varchar(pk_alert_constant.g_flg_status_c),
        o_episodes_ids  OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get current state of housing for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_housing_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    *  Get current state of Socio-demographic data for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_demographic_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    *  Get current state of Household financial situation for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_finance_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of Social Services Report for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_serv_report_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of Social Services Report for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_social_interv_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of Social discharge for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_social_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    -- *************************************************************************
    FUNCTION get_vwr_social_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    -- *************************************************************************
    FUNCTION get_vwr_social_final_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    -- *************************************************************************
    FUNCTION get_vwr_social_diff_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_mom_patient_id
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Get patient's intervention plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID     
    *
    * @return                         Returns the list of intervention plans
    *
    * @author                         Diogo Oliveira
    * @version                        v2.7.3.6
    * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_interv_plan_summary_page
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_varchar;

    FUNCTION get_interv_plan_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        i_flg_description     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_followup_notes_desc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_management_follow_up IN management_follow_up.id_management_follow_up%TYPE,
        i_flg_description         IN VARCHAR2
    ) RETURN VARCHAR2;

    g_domain_flg_wc_location  CONSTANT sys_domain.code_domain%TYPE := 'HOME.FLG_WC_LOCATION';
    g_domain_flg_water_origin CONSTANT sys_domain.code_domain%TYPE := 'HOME.FLG_WATER_ORIGIN';
    g_domain_flg_conserv      CONSTANT sys_domain.code_domain%TYPE := 'HOME.FLG_CONSERV';
    g_domain_flg_owner        CONSTANT sys_domain.code_domain%TYPE := 'HOME.FLG_OWNER';
    g_domain_flg_hab_type     CONSTANT sys_domain.code_domain%TYPE := 'HOME.FLG_HAB_TYPE';
    g_domain_flg_hab_location CONSTANT sys_domain.code_domain%TYPE := 'HOME.FLG_HAB_LOCATION';

    g_config_family_shortcut CONSTANT sys_config.id_sys_config%TYPE := 'FAMILY_RELATIONSHIPS_SHORTCUT';

    -- Hospital social worker profile template identifier
    g_hospital_sw_pt CONSTANT profile_template.id_profile_template%TYPE := 31;
    -- Non hospital social worker profile template identifier
    g_non_hospital_sw_pt CONSTANT profile_template.id_profile_template%TYPE := 28;

    g_home_flg_other       CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_home_flg_data_type_m CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_home_flg_data_type_n CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_home_flg_data_type_t CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_home_flg_status_c    CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_home_hist_flg_status CONSTANT VARCHAR2(30 CHAR) := 'HOME_HIST.FLG_STATUS';
    g_dt_home_hist         CONSTANT VARCHAR2(30 CHAR) := 'DT_HOME_HIST';
    g_dot                  CONSTANT VARCHAR2(1 CHAR) := '.';
    g_table_home           CONSTANT VARCHAR2(10 CHAR) := 'HOME';
    g_table_home_hist      CONSTANT VARCHAR2(15 CHAR) := 'HOME_HIST';
    g_social_worker_category PLS_INTEGER := 25;

    g_graffar_status_c    CONSTANT pat_graffar_crit.flg_status%TYPE := 'C';
    g_hh_finance_status_c CONSTANT family_monetary.flg_status%TYPE := 'C';

    g_id_fam_relationship_m CONSTANT family_relationship.id_family_relationship%TYPE := 3;
    g_id_fam_relationship_f CONSTANT family_relationship.id_family_relationship%TYPE := 4;
    g_id_fam_rel_mother     CONSTANT family_relationship.id_family_relationship%TYPE := 2;
    g_id_fam_rel_brother    CONSTANT family_relationship.id_family_relationship%TYPE := 13;

END pk_social;
/
