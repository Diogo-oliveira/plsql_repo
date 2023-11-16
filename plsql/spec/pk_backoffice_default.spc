/*-- Last Change Revision: $Rev: 2028512 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_default IS

    -- Author  : TERCIO.SOARES
    -- Created : 16-04-2008 10:28:58
    -- Purpose : Parametrizações default
    /********************************************************************************************
    * check_translation: check if translation exists
    *
    * @param i_lang                Prefered language ID
    * @param i_code                code translation    
    *
    *
    * @return                      0 id no tranlsation available, 1 if tranlsation exists
    *
    * @author                      CMF
    * @version                     1
    * @since                       2010/09/28
    ********************************************************************************************/
    FUNCTION check_translation
    (
        i_lang IN language.id_language%TYPE,
        i_code IN translation.code_translation%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Set a Default Parameterization for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/25
    ********************************************************************************************/
    FUNCTION set_inst_default_param
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
				i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_event_alert
    (
        i_lang      IN language.id_language%TYPE,
        id_event_df IN event.id_event%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Get Health Plans for a set of markets and versions
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_health_plans        Cursor of Health Plans
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/19
    ********************************************************************************************/
    FUNCTION get_inst_health_plans
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_health_plans   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Health Plans for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_inst_health_plans   Cursor of Instituition Health Plans
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/19
    ********************************************************************************************/
    FUNCTION set_inst_health_plans
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        o_inst_health_plans OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Unit Measures for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_unit_measures       Cursor of Unit measures
    * @param o_unit_measures       Cursor of Unit measures prescription flags
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION get_inst_unit_measures
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_unit_measures  OUT pk_types.cursor_type,
        o_umsi_flg_presc OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Unir Measures for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_unit_measures  Cursor of Instituition Unit_MEasures
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/19
    ********************************************************************************************/
    FUNCTION set_inst_unit_measures
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        o_inst_unit_measures OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis loinc codes for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_analysis            Cursor of analysis
    * @param o_al_loinc            Cursor of loinc codes
    * @param o_al_flg_default      Cursor of analysis loinc codes default flags
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION get_inst_analysis_loinc
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_analysis       OUT pk_types.cursor_type,
        o_al_loinc       OUT pk_types.cursor_type,
        o_al_flg_default OUT pk_types.cursor_type,
        o_al_sptype      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_analysis            Cursor of analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION get_inst_analysis
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_software           IN software.id_software%TYPE,
        o_analysis              OUT pk_types.cursor_type,
        o_ais_flg_type          OUT pk_types.cursor_type,
        o_ais_flg_mov_pat       OUT pk_types.cursor_type,
        o_ais_flg_first_result  OUT pk_types.cursor_type,
        o_ais_flg_mov_recipient OUT pk_types.cursor_type,
        o_ais_flg_harvest       OUT pk_types.cursor_type,
        o_ais_flg_fill_type     OUT pk_types.cursor_type,
        o_exam_cat              OUT pk_types.cursor_type,
        o_ais_sample_type       OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis Recipients for a set of markets, versions and softwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_analysis_instit_soft  Cursor of analysis
    * @param o_air_sample_recipient  Cursor of sample_recipients
    * @param o_air_flg_default       Cursor of analysis recipients default flags
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/27
    ********************************************************************************************/
    FUNCTION get_inst_analysis_recipients
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE,
        o_analysis_instit_soft OUT pk_types.cursor_type,
        o_air_sample_recipient OUT pk_types.cursor_type,
        o_air_flg_default      OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis Parameters for a set of markets, versions and softwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_ap_analysis           Cursor of analysis
    * @param o_ap_parameter          Cursor of analysis parameters
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/27
    ********************************************************************************************/
    FUNCTION get_inst_analysis_param
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_ap_analysis    OUT pk_types.cursor_type,
        o_ap_parameter   OUT pk_types.cursor_type,
        o_ap_rank        OUT pk_types.cursor_type,
        o_ap_colors      OUT pk_types.cursor_type,
        o_ap_fill        OUT pk_types.cursor_type,
        o_ap_sptype      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Analysis Parameters Functionalities for a set of markets, versions and softwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_apf_analysis_param    Cursor of analysis param
    * @param o_apf_flg_type          Cursor of analysis param types
    * @param o_apf_fill_type         Cursor of analysis param fill types
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/27
    ********************************************************************************************/
    FUNCTION get_inst_analysis_param_func
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_software        IN software.id_software%TYPE,
        o_apf_analysis_param OUT pk_types.cursor_type,
        o_apf_flg_type       OUT pk_types.cursor_type,
        o_apf_fill_type      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis Unit Measures for a set of markets, versions and softwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_aum_analysis          Cursor of analysis
    * @param o_aum_unit_measures     Cursor of analysis unit measures
    * @param o_aum_val_min           Cursor of analysis min values
    * @param o_aum_val_max           Cursor of analysis max values
    * @param o_aum_format_num        Cursor of analysis num format
    * @param o_aum_decimals          Cursor of analysis decimals
    * @param o_aum_flg_default       Cursor of analysis default flags
    * @param o_aum_analysis_param    Cursor of analysis parameters
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/27
    ********************************************************************************************/
    FUNCTION get_inst_analysis_unit_mea
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_software        IN software.id_software%TYPE,
        o_aum_analysis       OUT pk_types.cursor_type,
        o_aum_unit_measures  OUT pk_types.cursor_type,
        o_aum_val_min        OUT pk_types.cursor_type,
        o_aum_val_max        OUT pk_types.cursor_type,
        o_aum_format_num     OUT pk_types.cursor_type,
        o_aum_decimals       OUT pk_types.cursor_type,
        o_aum_flg_default    OUT pk_types.cursor_type,
        o_aum_analysis_param OUT pk_types.cursor_type,
        o_aum_sample_type    OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vital signs for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_vital_sign          Cursor of Vital signs
    * @param o_unit_measure        Cursor of Unit measures
    * @param o_vssi_flg_view       Cursor of view flags
    * @param o_vssi_color_grafh    Cursor of grafh colors
    * @param o_vssi_color_text     Cursor of text colors
    * @param o_vssi_box_type       Cursor of box types
    * @param o_vssi_rank           Cursor of ranks
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/14
    ********************************************************************************************/
    FUNCTION get_inst_vs_soft_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE,
        o_vital_sign       OUT pk_types.cursor_type,
        o_unit_measure     OUT pk_types.cursor_type,
        o_vssi_flg_view    OUT pk_types.cursor_type,
        o_vssi_color_grafh OUT pk_types.cursor_type,
        o_vssi_color_text  OUT pk_types.cursor_type,
        o_vssi_box_type    OUT pk_types.cursor_type,
        o_vssi_rank        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Analysis for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_analysis       Cursor of Instituition Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/19
    ********************************************************************************************/
    FUNCTION set_inst_analysis
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_analysis  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis Groups set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_analysis_group      Cursor of analysis groups
    * @param o_ais_flg_type        Cursor of analysis groups types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION get_inst_analysis_group
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_analysis_group OUT pk_types.cursor_type,
        o_ais_flg_type   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Analysis Groups for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_analysis_group Cursor of Instituition Analysis Groups
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/19
    ********************************************************************************************/
    FUNCTION set_inst_analysis_group
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_institution      IN institution.id_institution%TYPE,
        i_software            IN table_number,
        o_inst_analysis_group OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Exams set of markets, versions and sotwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_exams                 Cursor of exams
    * @param o_ecs_flg_first_result  Cursor of exams first result flags
    * @param o_ecs_flg_mov_pat       Cursor of exams mov. patient flags
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION get_inst_exams
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE,
        o_exams                OUT pk_types.cursor_type,
        o_ecs_flg_first_result OUT pk_types.cursor_type,
        o_ecs_flg_mov_pat      OUT pk_types.cursor_type,
        o_ecs_flg_type         OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Exams set of markets, versions and sotwares
    *
    * @param i_lang                       Prefered language ID
    * @param i_market                     Market ID's
    * @param i_version                    ALERT version's
    * @param i_id_institution             Institution ID
    * @param i_id_software                Software ID
    * @param o_exams                      Cursor of exams
    * @param o_exams_type                 Cursor of exams first result flags
    * @param o_ecs_flg_bypass_validation  Cursor of exams mov. patient flags
    * @param o_error                      Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION get_inst_exam_types
    (
        i_lang                      IN language.id_language%TYPE,
        i_market                    IN table_number,
        i_version                   IN table_varchar,
        i_id_institution            IN institution.id_institution%TYPE,
        i_id_software               IN software.id_software%TYPE,
        o_exams                     OUT pk_types.cursor_type,
        o_exams_type                OUT pk_types.cursor_type,
        o_ecs_flg_bypass_validation OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Exams for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_exams          Cursor of Instituition Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION set_inst_exams
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_exams     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Interventions set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_interv              Cursor of interventions
    * @param o_ics_flg_bandaid     Cursor of interv bandaid flags
    * @param o_ics_flg_chargeable  Cursor of interv chargeable flags
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION get_inst_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_software        IN software.id_software%TYPE,
        o_interv             OUT pk_types.cursor_type,
        o_ics_flg_bandaid    OUT pk_types.cursor_type,
        o_ics_flg_chargeable OUT pk_types.cursor_type,
        o_ics_flg_type       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Interventions for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_interv         Cursor of Instituition Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/31
    ********************************************************************************************/
    FUNCTION set_inst_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_interv    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Diagnosis for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_inst_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Sample Text Types and relation with professional categories for a set of markets, versions
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_st_types            Cursor of sample text types
    * @param o_st_categories       Cursor of categories
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION get_inst_sample_text
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_st_types       OUT pk_types.cursor_type,
        o_st_categories  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Sample texts for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_diag           Cursor of Instituition Diagnosis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_inst_sample_text
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_sttc      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Hidrics set of markets, versions and sotwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_hidrics               Cursor of hidrics
    * @param o_hidrics_types         Cursor of hidrics types
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION get_inst_hidrics
    (
        i_lang           IN language.id_language%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_hidrics        OUT pk_types.cursor_type,
        o_hidrics_types  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Hidrics for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_hidrics        Cursor of Instituition Hidrics
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_inst_hidrics
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_hidrics   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Transports entities set of markets, versions and sotwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_hidrics               Cursor of hidrics
    * @param o_hidrics_types         Cursor of hidrics types
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION get_inst_transp_entity
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_transp_entity  OUT pk_types.cursor_type,
        o_tei_flg_type   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Transports for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_inst_transp         Cursor of Instituition Transports
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_inst_transp
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_transp    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Discharge instructions for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_disch_instr         Cursor of discharge instructions
    * @param o_disch_instr_group   Cursor of discharge instructions groups
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/06
    ********************************************************************************************/
    FUNCTION get_inst_disch_instr
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_software       IN software.id_software%TYPE,
        o_disch_instr       OUT pk_types.cursor_type,
        o_disch_instr_group OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Discharge instructions for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_disch_reason        Cursor of discharge reason
    * @param o_disch_dest          Cursor of discharge destinations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/06
    ********************************************************************************************/
    FUNCTION get_inst_disch_reas_dest
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_id_software            IN software.id_software%TYPE,
        o_disch_reason           OUT pk_types.cursor_type,
        o_disch_dest             OUT pk_types.cursor_type,
        o_drd_flg_diag           OUT pk_types.cursor_type,
        o_drd_report_name        OUT pk_types.cursor_type,
        o_drd_id_epis_type       OUT pk_types.cursor_type,
        o_drd_type_screen        OUT pk_types.cursor_type,
        o_drd_id_reports         OUT pk_types.cursor_type,
        o_drd_flg_mcdt           OUT pk_types.cursor_type,
        o_drd_flg_care_stage     OUT pk_types.cursor_type,
        o_drd_flg_default        OUT pk_types.cursor_type,
        o_rank                   OUT pk_types.cursor_type,
        o_flg_specify_dest       OUT pk_types.cursor_type,
        o_flg_rep_notes          OUT pk_types.cursor_type,
        o_flg_def_disch_status   OUT pk_types.cursor_type,
        o_id_def_disch_status    OUT pk_types.cursor_type,
        o_flg_needs_overall_resp OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Discharges for a specific institution
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_version                ALERT version's
    * @param i_id_institution         Institution ID
    * @param i_software               Software ID's
    * @param o_inst_disch_instr       Cursor of Instituition Discharges Intructions
    * @param o_inst_disch_instr_group Cursor of Instituition Discharges Intructions Groups
    * @param o_inst_disch_reason      Cursor of Instituition Discharges Reasons
    * @param o_inst_disch_dest        Cursor of Instituition Discharges Destines
    * @param o_error                  Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/06
    ********************************************************************************************/
    FUNCTION set_inst_discharges
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_software               IN table_number,
        o_inst_disch_instr       OUT pk_types.cursor_type,
        o_inst_disch_instr_group OUT pk_types.cursor_type,
        o_inst_disch_reason      OUT pk_types.cursor_type,
        o_inst_disch_dest        OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get ICNP Compositions set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_icnp_compo_parent   Cursor of icnp composition parents
    * @param o_icnp_compo          Cursor of icnp compositions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_inst_icnp_compo
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE,
        o_icnp_compo_parent    OUT pk_types.cursor_type,
        o_icnp_compo           OUT pk_types.cursor_type,
        o_icnp_predifined_act1 OUT pk_types.cursor_type,
        o_icnp_predifined_hist OUT pk_types.cursor_type,
        o_icnp_predifined_act2 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set ICNP Compostions for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_icnp_compo     Cursor of Instituition ICNP Compostions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION set_inst_icnp_compo
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN table_number,
        i_version         IN table_varchar,
        i_id_institution  IN institution.id_institution%TYPE,
        i_software        IN table_number,
        o_inst_icnp_compo OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Vaccines set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_vacc_group          Cursor of vaccines
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_inst_vacc
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_vacc_group     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Vaccines for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_vacc_group     Cursor of Instituition Vaccines
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION set_inst_vacc
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN table_number,
        i_version         IN table_varchar,
        i_id_institution  IN institution.id_institution%TYPE,
        i_software        IN table_number,
        o_inst_vacc_group OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vital sign unit measures set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_vital_sign          Cursor of Vital signs
    * @param o_unit_measure        Cursor of Unit measures
    * @param o_val_min             Cursor of Minimum values
    * @param o_val_max             Cursor of Maximum values
    * @param o_format_num          Cursor of values format
    * @param o_decimals            Cursor of decimals
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_inst_vs_unit_mea
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_vital_sign     OUT pk_types.cursor_type,
        o_unit_measure   OUT pk_types.cursor_type,
        o_val_min        OUT pk_types.cursor_type,
        o_val_max        OUT pk_types.cursor_type,
        o_format_num     OUT pk_types.cursor_type,
        o_decimals       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Vital signs for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_vacc_group     Cursor of Instituition Vaccines
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION set_inst_vital_signs
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        o_inst_vital_signs OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vital sign unit measures set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_vs_unit_mea         Cursor of Vital signs unit measures
    * @param o_id_exam_type        Cursor of Exam types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_inst_vs_exam_type
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_vs_unit_mea    OUT pk_types.cursor_type,
        o_id_exam_type   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set  Vital Signs exam types for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_exam_type_vs   Cursor of Instituition Vital Signs exam types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION set_inst_vs_exam_type
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        o_inst_exam_type_vs OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Events set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_event_group         Cursor of events
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/14
    ********************************************************************************************/
    FUNCTION get_inst_events
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_event_group    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Events for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_events         Cursor of Instituition Events
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/14
    ********************************************************************************************/
    FUNCTION set_inst_events
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_events    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Lens set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_lens                Cursor of lens
    * @param o_lens_rank           Cursor of lens ranks
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION get_inst_lens
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_lens           OUT pk_types.cursor_type,
        o_lens_rank      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Lens for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_lens           Cursor of Instituition Lens
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION set_inst_lens
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_lens      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Calculators set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_calc                Cursor of calculators
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION get_inst_calc
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_calc           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Calculators fields set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_calc                Cursor of calculators
    * @param o_calc_field          Cursor of calculators fields
    * @param o_cf_unit_mea         Cursor of calculators fields unit measures
    * @param o_cf_format           Cursor of calculators fields formats
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION get_inst_calc_field
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_calc           OUT pk_types.cursor_type,
        o_calc_field     OUT pk_types.cursor_type,
        o_cf_unit_mea    OUT pk_types.cursor_type,
        o_cf_format      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Calculators for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_calc           Cursor of Instituition Calculators
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION set_inst_calc
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_calc      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Templates set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_templates           Cursor of templates
    * @param o_profiles            Cursor of profiles
    * @param o_context             Cursor of contexts
    * @param o_flg_types           Cursor of templates flag types
    * @param o_id_sch_event        Cursor of scheduler events
    * @param o_context_2           Cursor of additional contexts  
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION get_inst_templates
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_templates      OUT pk_types.cursor_type,
        o_profiles       OUT pk_types.cursor_type,
        o_context        OUT pk_types.cursor_type,
        o_flg_types      OUT pk_types.cursor_type,
        o_id_sch_event   OUT pk_types.cursor_type,
        o_context_2      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Templates for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_templates      Cursor of Instituition Templates
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION set_inst_templates
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_templates OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Periodic observation param for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_pop_id_content      Cursor of periodic observation param Content identifier
    * @param o_pop_id_event        Cursor of events
    * @param o_pop_po_type         Cursor of periodic observation param types
    * @param o_pop_id_cs           Cursor of clinical services
    * @param o_pop_id_teg          Cursor of time event groups
    * @param o_pop_fill_type       Cursor of periodic observation param fill types
    * @param o_pop_format_num      Cursor of periodic observation param num formats
    * @param o_pop_id_unit_mea     Cursor of periodic observation param unit measures
    * @param o_pop_id_context      Cursor of periodic observation param context
    * @param o_pop_flg_type        Cursor of periodic observation param flag types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION get_inst_periodic_obs_param
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_pop_config     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Periodic observation param desc for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_pod_id_pop          Cursor of periodic observation param desc identifiers
    * @param o_pod_value           Cursor of eriodic observation param desc values
    * @param o_pod_icon            Cursor of periodic observation param desc icons
    * @param o_pod_id_content      Cursor of periodic observation param desc Content identifier
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION get_inst_periodic_obs_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_cursor_config  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Periodic observations for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_inst_periodic_obs_param  Cursor of Instituition Periodic Observations
    * @param o_error                    Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_periodic_obs_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_software                IN table_number,
        o_inst_periodic_obs_param OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Periodic observations desc. for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_inst_periodic_obs_desc   Cursor of Instituition Periodic Observations Desc.
    * @param o_error                    Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_periodic_obs_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_pod       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Internal medication for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_int_med             Cursor of drugs
    * @param o_int_med_vers        Cursor of drugs versions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/20
    ********************************************************************************************/
    FUNCTION get_inst_int_med
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_int_med        OUT pk_types.cursor_type,
        o_int_med_vers   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Internal medication for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_int_med        Cursor of Instituition Internal medication
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/20
    ********************************************************************************************/
    FUNCTION set_inst_int_med
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_int_med   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get External medication for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_ext_med             Cursor of drugs
    * @param o_ext_med_vers        Cursor of drugs version
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/21
    ********************************************************************************************/
    FUNCTION get_inst_ext_med
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_ext_med        OUT pk_types.cursor_type,
        o_ext_med_vers   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set External medication for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_ext_med        Cursor of Instituition External medication
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/21
    ********************************************************************************************/
    FUNCTION set_inst_ext_med
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_ext_med   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Validate that ALERT Universes doesn't have ID_CONTENT with null value.
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/10/13
    ********************************************************************************************/
    FUNCTION validate_universes
    (
        i_lang  IN language.id_language%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set HEALTH PROGRAM for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_health_program         Cursor of Instituition Interventions
    * @param o_inst_health_program_event         Cursor of Instituition Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/31
    ********************************************************************************************/
    FUNCTION set_inst_health_program
    (
        i_lang                      IN language.id_language%TYPE,
        i_market                    IN table_number,
        i_version                   IN table_varchar,
        i_id_institution            IN institution.id_institution%TYPE,
        i_software                  IN table_number,
        o_inst_health_program       OUT pk_types.cursor_type,
        o_inst_health_program_event OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Cancel_reason for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_cancel_reason          Cursor of Instituition Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2009/01/05
    ********************************************************************************************/

    FUNCTION set_inst_cancel_reason
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        o_inst_cancel_reason OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default External Cause
    *
    * @param i_lang                Prefered language ID
    * @param o_external_cause      External Cause
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_external_cause
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        o_external_cause OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get diet set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_diet                Cursor of diet
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/06
    ********************************************************************************************/
    FUNCTION get_inst_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_diet           OUT pk_types.cursor_type,
        o_size           OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set diet for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_diet          Cursor of Instituition diet
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/06
    ********************************************************************************************/
    FUNCTION set_inst_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_diet      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get codification set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_codification        Cursor of diet
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/06
    ********************************************************************************************/
    FUNCTION get_inst_codification
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN market.id_market%TYPE,
        i_version        IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_codification   OUT pk_types.cursor_type,
        o_flg_default    OUT pk_types.cursor_type,
        o_size           OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Cancel_reason for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_cancel_reason          Cursor of Instituition Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2009/01/06
    ********************************************************************************************/
    FUNCTION set_inst_codification
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        o_inst_codification OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get advanced input set of markets, versions and sotwares
    *
    * @param i_lang                      Prefered language ID
    * @param i_market                    Market ID's
    * @param i_version                   ALERT version's
    * @param i_id_institution            Institution ID
    * @param i_id_software               Software ID
    * @param o_advanced_input            Cursor of advanced input
    * @param o_advanced_input_field      Cursor of advanced input field
    * @param o_error_message             Cursor of error message
    * @param o_rank                      Cursor of rank
    * @param o_error                     Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/06
    ********************************************************************************************/
    FUNCTION get_inst_advanced_input
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE,
        o_advanced_input       OUT pk_types.cursor_type,
        o_advanced_input_field OUT pk_types.cursor_type,
        o_error_message        OUT pk_types.cursor_type,
        o_rank                 OUT pk_types.cursor_type,
        o_market               OUT pk_types.cursor_type,
        o_size                 OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set advanced input for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_advanced_input          Cursor of Instituition advanced input
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2009/01/06
    ********************************************************************************************/
    FUNCTION set_inst_advanced_input
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_institution      IN institution.id_institution%TYPE,
        i_software            IN table_number,
        o_inst_advanced_input OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get notes profile set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_profile_template         Cursor of events
    * @param o_notes_config         Cursor of events
    * @param o_flg_write         Cursor of events
    * @param o_flg_read         Cursor of events
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/08
    ********************************************************************************************/

    FUNCTION get_inst_notes_profile_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        o_profile_template OUT pk_types.cursor_type,
        o_notes_config     OUT pk_types.cursor_type,
        o_flg_write        OUT pk_types.cursor_type,
        o_flg_read         OUT pk_types.cursor_type,
        o_size             OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set notes profile for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_notes_profile          Cursor of Instituition Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2009/01/11
    ********************************************************************************************/
    FUNCTION set_inst_notes_profile_inst
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        o_inst_notes_profile OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get sr_interv_duration set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_sr_interv_duration  Cursor of sr_interv_duration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/06
    ********************************************************************************************/
    FUNCTION get_inst_sr_interv_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        o_sr_interv_duration OUT pk_types.cursor_type,
        o_avg_duration       OUT pk_types.cursor_type,
        o_size               OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Interventions for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_SR_inst_interv         Cursor of Instituition Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/11
    ********************************************************************************************/
    FUNCTION set_sr_interv_duration_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_sr_inst_interv OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get sr_posit set of markets, versions and softwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_ID_sr_posit                 Cursor of ID_sr_posit
    * @param o_ID_sr_parent  Cursor of ID_sr_parent
    * @param o_rank       Cursor of rank
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/18
    ********************************************************************************************/
    FUNCTION get_inst_sr_posit
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_sr_posit    OUT pk_types.cursor_type,
        o_id_sr_parent   OUT pk_types.cursor_type,
        o_rank           OUT pk_types.cursor_type,
        o_size           OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set sr_posit for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_sr_posit         Cursor of Instituition Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/18
    ********************************************************************************************/
    FUNCTION set_inst_sr_posit
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_sr_posit  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Set CIRURGICAL PROTOCOLS for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_protocols         Cursor of Instituition Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/21
    ********************************************************************************************/
    FUNCTION set_inst_wtl_urg_level
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_wtl       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default origin
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution identification
    * @param o_origin              Origin
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/22
    ********************************************************************************************/
    FUNCTION set_inst_origin
    (
        i_lang   IN language.id_language%TYPE,
        o_origin OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get ORIGIN set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_id_origin            Cursor of origin identification
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/22
    ********************************************************************************************/
    FUNCTION get_inst_origin_soft_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_origin      OUT pk_types.cursor_type,
        o_size           OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set ORIGIN for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_origin           Cursor of Instituition Lens
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/22
    ********************************************************************************************/
    FUNCTION set_inst_origin_soft_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_origin    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
        * Get order set of markets, versions and sotwares
        *
        * @param i_lang                  Prefered language ID
        * @param i_market                Market ID's
        * @param i_version               ALERT version's
        * @param i_id_institution        Institution ID
        * @param i_id_software           Software ID
    * @param o_id_order_set cursor 
    * @param        o_id_order_set_internal cursor
    * @param        o_id_os_prev_vers cursor
    * @param        o_title cursor
    * @param        o_author_desc cursor
    * @param        o_flg_target_professional cursor
    * @param        o_flg_edit_permission cursor
    * @param        o_flg_status cursor
    * @param        o_notes_global cursor
    * @param        o_flg_additional_info cursor
    * @param        o_id_content cursor
    * @param o_error                 Error
        *
        *
        * @return                      true or false on success or error
        *
        * @author                      SMSS
        * @version                     2.6
        * @since                       2010/01/25
        ********************************************************************************************/
    FUNCTION get_inst_order_set
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        o_id_order_set            OUT pk_types.cursor_type,
        o_id_order_set_internal   OUT pk_types.cursor_type,
        o_id_os_prev_vers         OUT pk_types.cursor_type,
        o_title                   OUT pk_types.cursor_type,
        o_author_desc             OUT pk_types.cursor_type,
        o_flg_target_professional OUT pk_types.cursor_type,
        o_flg_edit_permission     OUT pk_types.cursor_type,
        o_flg_status              OUT pk_types.cursor_type,
        o_notes_global            OUT pk_types.cursor_type,
        o_flg_additional_info     OUT pk_types.cursor_type,
        o_id_content              OUT pk_types.cursor_type,
        o_flag_update             OUT pk_types.cursor_type,
        o_size                    OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Set orders set for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_order_set         Cursor of Instituition order sets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/25
    ********************************************************************************************/
    FUNCTION set_inst_order_set
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_order_set OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get order set link set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_id_order_set              Cursor of interventions
    * @param o_id_link     Cursor of interv bandaid flags
    * @param o_flg_link_type  Cursor of interv chargeable flags
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/26
    ********************************************************************************************/
    FUNCTION get_inst_order_set_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        
        o_id_order_set  OUT pk_types.cursor_type,
        o_id_link       OUT pk_types.cursor_type,
        o_flg_link_type OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
        
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set link for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_order_set_link         Cursor of Instituition order set link
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/26
    ********************************************************************************************/
    FUNCTION set_inst_order_set_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_order_set_link OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get order set task of markets, versions and sotwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_id_order_set_task     cursor 
    * @param o_id_order_set          cursor
    * @param o_id_task_type          cursor
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/27
    ********************************************************************************************/
    FUNCTION get_inst_order_set_task
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_software       IN software.id_software%TYPE,
        o_id_order_set_task OUT pk_types.cursor_type,
        o_id_order_set      OUT pk_types.cursor_type,
        o_id_task_type      OUT pk_types.cursor_type,
        o_task_def          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set task for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_order_set_task          Cursor of Instituition diet
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/27
    ********************************************************************************************/
    FUNCTION set_inst_order_set_task
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_order_set_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set task link for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software      Software ID
    * @param o_inst_order_set_task_link         Cursor of Instituition Transports
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/28
    ********************************************************************************************/
    FUNCTION get_inst_order_set_task_link
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_order_set_task   IN order_set_task.id_order_set_task%TYPE,
        i_id_order_set_task_n IN order_set_task.id_order_set_task%TYPE,
        o_id_order_set_task   OUT pk_types.cursor_type,
        o_task_link           OUT pk_types.cursor_type,
        o_flg_task_link_type  OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get institution order set task detail of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_order_set_task_detail     cursor 
    * @param o_id_order_set_task            cursor
    * @param o_flg_value_type               cursor
    * @param o_nvalue                       cursor
    * @param o_dvalue                       cursor
    * @param o_vvalue                       cursor
    * @param o_flg_detail_type              cursor
    * @param o_id_adv_input                 cursor
    * @param o_id_adv_input_field_det       cursor
    * @param o_id_unit_measure              cursor                                                                                    
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               SMSS
    * @version                              2.6
    * @since                                2010/01/28
    ********************************************************************************************/
    FUNCTION get_inst_order_set_task_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_market                   IN table_number,
        i_version                  IN table_varchar,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_software              IN software.id_software%TYPE,
        o_id_order_set_task_detail OUT pk_types.cursor_type,
        o_id_order_set_task        OUT pk_types.cursor_type,
        o_flg_value_type           OUT pk_types.cursor_type,
        o_nvalue                   OUT pk_types.cursor_type,
        o_dvalue                   OUT pk_types.cursor_type,
        o_vvalue                   OUT pk_types.cursor_type,
        o_flg_detail_type          OUT pk_types.cursor_type,
        o_id_adv_input             OUT pk_types.cursor_type,
        o_id_adv_input_field       OUT pk_types.cursor_type,
        o_id_adv_input_field_det   OUT pk_types.cursor_type,
        o_id_unit_measure          OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set task detail for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software      Software ID
    * @param o_inst_order_set_task_detail         Cursor of Instituition Transports
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/28
    ********************************************************************************************/
    FUNCTION set_inst_order_set_task_detail
    (
        i_lang                       IN language.id_language%TYPE,
        i_market                     IN table_number,
        i_version                    IN table_varchar,
        i_id_institution             IN institution.id_institution%TYPE,
        i_software                   IN table_number,
        o_inst_order_set_task_detail OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
        * Get institution order set frequent of markets, versions and sotwares
        *
        * @param i_lang                  Prefered language ID
        * @param i_market                Market ID's
        * @param i_version               ALERT version's
        * @param i_id_institution        Institution ID
        * @param i_id_software           Software ID
    * @param o_id_order_set cursor 
    * @param        o_rank cursor
                                                                                
    * @param o_error                 Error
        *
        *
        * @return                      true or false on success or error
        *
        * @author                      SMSS
        * @version                     2.6
        * @since                       2010/01/28
        ********************************************************************************************/
    FUNCTION get_inst_order_set_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_order_set   OUT pk_types.cursor_type,
        o_rank           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set frequent for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software      Software ID
    * @param o_inst_order_set_frequent         Cursor of Instituition Transports
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/28
    ********************************************************************************************/
    FUNCTION set_inst_order_set_frequent
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_software                IN table_number,
        o_inst_order_set_frequent OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the available urgency levels 
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_duration cursor 
    * @param o_id_content cursor
    * @param o_id_wtl cursor
    * @param o_id_language cursor
    * @param o_desc_translation cursor 
    * @param o_id_wtl_lan cursor
    * @param o_id_lang cursor
    * @param o_desc cursor
    * @param o_id_wtl_d cursor
    * @param o_flag_translation cursor
    * @param o_desc cursor
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/21
    ********************************************************************************************/
    FUNCTION get_inst_wtl_urg_level
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        o_duration         OUT pk_types.cursor_type,
        o_id_content       OUT pk_types.cursor_type,
        o_id_wtl           OUT pk_types.cursor_type,
        o_flg_status       OUT pk_types.cursor_type,
        o_flg_param        OUT pk_types.cursor_type,
        o_wtl_descr        OUT pk_types.cursor_type,
        o_flag_translation OUT VARCHAR2,
        o_size1            OUT NUMBER,
        o_size2            OUT NUMBER,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Graphic for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_graphic          Cursor of Instituition Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/03/18
    ********************************************************************************************/
    FUNCTION set_inst_graphic_soft_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_graphic   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set follow up entity for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_follow          Cursor of Instituition Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/03/18
    ********************************************************************************************/
    FUNCTION set_inst_follow_up_entity_si
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_follow    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set DOC_AREAS by markets, versions and softwares into institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Set of Market ID's
    * @param i_version             Set of ALERT content version's
    * @param i_id_institution      Institution ID
    * @param i_software            Set of Software ID's
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2013/01/22
    ********************************************************************************************/
    FUNCTION set_inst_doc_area
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set DOC_TEMPLATE by markets, versions and softwares into institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Set of Market ID's
    * @param i_version             Set of ALERT content version's
    * @param i_id_institution      Institution ID
    * @param i_software            Set of Software ID's
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      JM
    * @version                     2.6.3
    * @since                       2013/04/08
    ********************************************************************************************/
    FUNCTION set_inst_doc_template_si
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get P1_SPEC_HELPS according to a P1_SPECIALITY
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID   
    * @param o_id_spec_help        Cursor of Spec_Help
    * @param o_code_title          Cursor of Code_Titles
    * @param o_code_text           Cursor of Code_Texts
    * @param o_rank                Cursor of Ranks
    * @param o_id_speciality       Cursor of P1_Specialities
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/13
    ********************************************************************************************/

    FUNCTION get_inst_p1_spec_help
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_id_spec_help   OUT pk_types.cursor_type,
        o_code_title     OUT pk_types.cursor_type,
        o_code_text      OUT pk_types.cursor_type,
        o_rank           OUT pk_types.cursor_type,
        o_id_speciality  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set P1 for a specific institution
    *
    * @param i_lang                Prefered language ID  
    * @param i_id_institution      Institution ID
    * @param o_inst_vacc_group     Cursor of Instituition Vaccines
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/13
    ********************************************************************************************/
    FUNCTION set_inst_p1
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_p1        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get BodyDiagram_Age_Group set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_bd_age_grp          Cursor of BodyDiagram_Age_Group
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/14
    ********************************************************************************************/
    FUNCTION get_inst_bd_age_grp
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_bd_age_grp     OUT pk_types.cursor_type,
        o_bd_min_age     OUT pk_types.cursor_type,
        o_bd_max_age     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set BodyDiagrams for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_body_diagram   Cursor of Instituition BodyDiagrams
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/14
    ********************************************************************************************/
    FUNCTION set_inst_body_diagram
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        o_inst_body_diagram OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get SYS_CONFIG set of markets and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_sys_config          Cursor of SYS_CONFIG
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/15
    ********************************************************************************************/
    FUNCTION get_inst_sys_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_sys_config     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set SYS_CONFIG for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_sys_config     Cursor of Instituition SYS_CONFIG
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/15
    ********************************************************************************************/
    FUNCTION set_inst_sys_config
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN table_number,
        i_id_institution  IN institution.id_institution%TYPE,
        i_software        IN table_number,
        o_inst_sys_config OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Transports entities set of markets, versions and sotwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_id_disch_reason               Cursor of disch_reason
    * @param o_id_transp_entity         Cursor of transp_entity
    * @param o_error                 Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/16
    ********************************************************************************************/
    FUNCTION get_inst_disch_rea_transp_ei
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        o_id_disch_reason  OUT pk_types.cursor_type,
        o_id_transp_entity OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get DISCHARGE_REASON/TRANSP_ENTITY relation set of markets and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_inst_disch_rea_transp_ei   Cursor of Instituition DISCHARGE_REASON/TRANSP_ENTITY relation
    * @param o_error               Error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/16
    ********************************************************************************************/
    FUNCTION set_inst_disch_rea_transp_ei
    (
        i_lang                     IN language.id_language%TYPE,
        i_market                   IN table_number,
        i_version                  IN table_varchar,
        i_id_institution           IN institution.id_institution%TYPE,
        o_inst_disch_rea_transp_ei OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Profile_Discharge_Reason set of markets, versions and sotwares
    *
    * @param i_lang                  Prefered language ID
    * @param i_market                Market ID's
    * @param i_version               ALERT version's
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_id_disch_reason               Cursor of disch_reason
    * @param o_id_transp_entity         Cursor of transp_entity
    * @param o_error                 Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/16
    ********************************************************************************************/
    FUNCTION get_inst_profile_disch_reason
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_institution      IN institution.id_institution%TYPE,
        o_id_disch_reason     OUT pk_types.cursor_type,
        o_id_profile_template OUT pk_types.cursor_type,
        o_flg_available       OUT pk_types.cursor_type,
        o_id_flash_files      OUT pk_types.cursor_type,
        o_flg_access          OUT pk_types.cursor_type,
        o_rank                OUT pk_types.cursor_type,
        o_flg_default         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Profile_Discharge_Reason set of markets and sotwares
    *
    * @param i_lang                       Prefered language ID
    * @param i_market                     Market ID's
    * @param i_version                    ALERT version's
    * @param i_id_institution             Institution ID
    * @param o_inst_profile_disch_reason  Cursor of Instituition PROFILE_DISCH_REASON
    * @param o_error                      Error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/16
    ********************************************************************************************/
    FUNCTION set_inst_profile_disch_reason
    (
        i_lang                      IN language.id_language%TYPE,
        i_market                    IN table_number,
        i_version                   IN table_varchar,
        i_id_institution            IN institution.id_institution%TYPE,
        o_inst_profile_disch_reason OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get PROTOCOL set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of protocol
    * @param o_id_protocol_prev_vrs         Cursor of protocol_previous version
    * @param o_protocol_descr               Cursor of protocol description
    * @param o_flg_status                   Cursor of flg_status
    * @param o_id_ebm                       Cursor of EMB_ID
    * @param o_context_title                Cursor of Context_Title
    * @param o_context_adaptation           Cursor of Context_Adaptation
    * @param o_context_type_media           Cursor of Context_Type_Media
    * @param o_context_editor               Cursor of Context_Editor
    * @param o_context_edition_site         Cursor of Context_Edition_Site
    * @param o_context_edition              Cursor of Context_Edition
    * @param o_dt_context_edition           Cursor of Date_Context_Edition
    * @param o_context_access               Cursor of Context_Access
    * @param o_id_context_lang              Cursor of ID_Context_Language
    * @param o_flg_context_img              Cursor of Flg_Context_Image
    * @param o_context_subtitle             Cursor of Context_Subtitle
    * @param o_id_context_associated_lang   Cursor of Id_Context_Associated
    * @param o_flg_type_recommend           Cursor of Flg_Type_Recommend
    * @param o_context_desc                 Cursor of Context_description
    * @param o_id_content                   Cursor of Id_Content
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/04/19
    ********************************************************************************************/
    FUNCTION get_inst_protocol
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_software           IN software.id_software%TYPE,
        o_id_protocol           OUT pk_types.cursor_type,
        o_id_protocol_prev_vrs  OUT pk_types.cursor_type,
        o_protocol_descr        OUT pk_types.cursor_type,
        o_flg_status            OUT pk_types.cursor_type,
        o_id_ebm                OUT pk_types.cursor_type,
        o_context_title         OUT pk_types.cursor_type,
        o_context_adaptation    OUT pk_types.cursor_type,
        o_context_type_media    OUT pk_types.cursor_type,
        o_context_editor        OUT pk_types.cursor_type,
        o_context_edition_site  OUT pk_types.cursor_type,
        o_context_edition       OUT pk_types.cursor_type,
        o_dt_context_edition    OUT pk_types.cursor_type,
        o_context_access        OUT pk_types.cursor_type,
        o_id_context_lang       OUT pk_types.cursor_type,
        o_flg_context_img       OUT pk_types.cursor_type,
        o_context_subtitle      OUT pk_types.cursor_type,
        o_id_context_assoc_lang OUT pk_types.cursor_type,
        o_flg_type_recommend    OUT pk_types.cursor_type,
        o_context_desc          OUT pk_types.cursor_type,
        o_id_content            OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set protocol for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_protocol      Cursor of Instituition protocol
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/20
    ********************************************************************************************/
    FUNCTION set_inst_protocol
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_protocol  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get order set link set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_id_protocol         Cursor of Protocols
    * @param o_id_link             Cursor of flags
    * @param o_link_type           Cursor of Link Type
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/20
    ********************************************************************************************/
    FUNCTION get_inst_protocol_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_protocol    OUT pk_types.cursor_type,
        o_id_link        OUT pk_types.cursor_type,
        o_link_type      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol link for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_protocol_link      Cursor of Instituition Protocol_Link
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/26
    ********************************************************************************************/
    FUNCTION set_inst_protocol_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_protocol_link  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Questions set by Protocol
    *
    * @param i_lang                         Prefered language ID
    * @param i_id_protocol                  Protocol ID   
    * @param o_id_protocol_question         Cursor of Protocol Question
    * @param o_descr_question               Cursor of Question Description  
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/04/20
    ********************************************************************************************/
    FUNCTION get_inst_protocol_question
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_protocol_def      IN protocol_element.id_protocol%TYPE,
        o_id_protocol_question OUT pk_types.cursor_type,
        o_descr_question       OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Protocol set by Protocol
    *
    * @param i_lang                         Prefered language ID
    * @param i_id_protocol                  Protocol ID   
    * @param o_id_protocol_protocol         Cursor of Protocol Question
    * @param o_descr_question               Cursor of Protocol Description  
    * @param o_id_nested_protocol           Cursor of Nested Protocol
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/04/20
    ********************************************************************************************/
    FUNCTION get_inst_protocol_protocol
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_protocol          IN protocol_element.id_protocol%TYPE,
        o_id_protocol_protocol OUT pk_types.cursor_type,
        o_descr_protocol       OUT pk_types.cursor_type,
        o_id_nested_protocol   OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Task set by Protocol
    *
    * @param i_lang                         Prefered language ID
    * @param i_id_protocol                  Protocol ID   
    * @param o_id_protocol_task             Cursor of Protocol Task
    * @param o_id_group_task                Cursor of Group Task ID
    * @param o_descr_protocol_task          Cursor of Task Description
    * @param o_id_task_link                 Cursor of Task Link
    * @param o_task_type                    Cursor of Task Type
    * @param o_task_notes                   Cursor of Task Notes
    * @param o_id_task_attach               Cursor of Task Attach
    * @param o_task_codif                   Cursor of Task Codificaton
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/03
    ********************************************************************************************/
    FUNCTION get_inst_protocol_task
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        o_id_protocol_task    OUT pk_types.cursor_type,
        o_id_group_task       OUT pk_types.cursor_type,
        o_descr_protocol_task OUT pk_types.cursor_type,
        o_id_task_link        OUT pk_types.cursor_type,
        o_task_type           OUT pk_types.cursor_type,
        o_task_notes          OUT pk_types.cursor_type,
        o_id_task_attach      OUT pk_types.cursor_type,
        o_task_codif          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Text set by Protocol
    *
    * @param i_lang                         Prefered language ID
    * @param i_id_protocol                  Protocol ID   
    * @param o_id_protocol_text             Cursor of Protocol Text
    * @param o_descr_protocol_text          Cursor of Text Description  
    * @param o_text_type                    Cursor of Text Type
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/03
    ********************************************************************************************/
    FUNCTION get_inst_protocol_text
    (
        i_lang                IN language.id_language%TYPE,
        i_id_protocol         IN protocol_element.id_protocol%TYPE,
        o_id_protocol_text    OUT pk_types.cursor_type,
        o_descr_protocol_text OUT pk_types.cursor_type,
        o_text_type           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Elements set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Protocols
    * @param o_id_element                   Cursor of Elements
    * @param o_element_type                 Cursor of Element_Type
    * @param o_desc_element                 Cursor of Desc_Element
    * @param o_x_coordinate                 Cursor of x_coordinate
    * @param o_y_coordinate                 Cursor of y_coordinate
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/04/27
    ********************************************************************************************/
    FUNCTION get_inst_protocol_element
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_protocol    OUT pk_types.cursor_type,
        o_id_element     OUT pk_types.cursor_type,
        o_element_type   OUT pk_types.cursor_type,
        o_desc_element   OUT pk_types.cursor_type,
        o_x_coordinate   OUT pk_types.cursor_type,
        o_y_coordinate   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Element for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_protocol_element    Cursor of Instituition Protocol_Element
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/26
    ********************************************************************************************/
    FUNCTION set_inst_protocol_element
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        o_protocol_element OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Task for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_protocol_task       Cursor of Instituition Protocol_Taks_Link
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/19
    ********************************************************************************************/
    FUNCTION set_inst_protocol_task
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Criteria set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Protocol ID 
    * @param o_criteria_type                Cursor of Criteria Type
    * @param o_gender                       Cursor of Gender
    * @param o_min_age                      Cursor of min age
    * @param o_max_age                      Cursor of max age
    * @param o_min_weight                   Cursor of min weight
    * @param o_max_weight                   Cursor of max weight
    * @param o_id_weight_unit_mea           Cursor of weight unit measure ID
    * @param o_min_height                   Cursor of min height
    * @param o_max_height                   Cursor of max height
    * @param o_id_height_unit_mea           Cursor of height unit measure ID
    * @param o_imc_min                      Cursor of min IMC
    * @param o_imc_max                      Cursor of max IMC
    * @param o_id_blood_pres_unit_mea       Cursor of Blood pressure unit measure ID
    * @param o_min_blood_press_s            Cursor of min Blood pressure sistolic
    * @param o_max_blood_press_s            Cursor of max Blood pressure sistolic
    * @param o_min_blood_press_d            Cursor of min Blood pressure diastolic
    * @param o_max_blood_press_d            Cursor of max Blood pressure diastolic
    * @param o_error                        Error  
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/03
    ********************************************************************************************/
    FUNCTION get_inst_protocol_criteria
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_id_software            IN software.id_software%TYPE,
        o_id_protocol            OUT pk_types.cursor_type,
        o_criteria_type          OUT pk_types.cursor_type,
        o_gender                 OUT pk_types.cursor_type,
        o_min_age                OUT pk_types.cursor_type,
        o_max_age                OUT pk_types.cursor_type,
        o_min_weight             OUT pk_types.cursor_type,
        o_max_weight             OUT pk_types.cursor_type,
        o_id_weight_unit_mea     OUT pk_types.cursor_type,
        o_min_height             OUT pk_types.cursor_type,
        o_max_height             OUT pk_types.cursor_type,
        o_id_height_unit_mea     OUT pk_types.cursor_type,
        o_imc_min                OUT pk_types.cursor_type,
        o_imc_max                OUT pk_types.cursor_type,
        o_id_blood_pres_unit_mea OUT pk_types.cursor_type,
        o_min_blood_press_s      OUT pk_types.cursor_type,
        o_max_blood_press_s      OUT pk_types.cursor_type,
        o_min_blood_press_d      OUT pk_types.cursor_type,
        o_max_blood_press_d      OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Criteria for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_protocol_criteria   Cursor of Instituition Protocol_Criteria
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/04
    ********************************************************************************************/
    FUNCTION set_inst_protocol_criteria
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        o_protocol_criteria OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Criteria Links set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol_criteria         Cursor of Protocol Criteria
    * @param o_id_link_other_criteria       Cursor of Link Other Criteria ID
    * @param o_id_link_other_criteria_type  Cursor of Link Other Criteria Type ID 
    * @param o_error                        Error  
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/05
    ********************************************************************************************/
    FUNCTION get_inst_protocol_crit_link
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        o_id_protocol_criteria    OUT pk_types.cursor_type,
        o_id_link_other_criteria  OUT pk_types.cursor_type,
        o_id_link_other_crit_type OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Criteria Link for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_protocol_criteria_link   Cursor of Instituition Protocol_Criteria_Link
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/05
    ********************************************************************************************/
    FUNCTION set_inst_protocol_crit_link
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_software               IN table_number,
        o_protocol_criteria_link OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol ADV Input Value set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_adv_input_link            Cursor of adv input link
    * @param o_flg_type                     Cursor of Flg Type
    * @param o_value_type                   Cursor of Value Type
    * @param o_nvalue                       Cursor of n Value
    * @param o_dvalue                       Cursor of d Value
    * @param o_vvalue                       Cursor of v Value
    * @param o_vvalue_desc                  Cursor of v Value Description
    * @param o_criteria_value_type          Cursor of Criteria Value Type
    * @param o_id_adv_input                 Cursor of adv input
    * @param o_id_adv_input_field           Cursor of adv input field
    * @param o_id_adv_input_field_det       Cursor of adv input field det
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/04
    ********************************************************************************************/
    FUNCTION get_inst_prtcl_adv_input_value
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_software            IN software.id_software%TYPE,
        o_id_adv_input_link      OUT pk_types.cursor_type,
        o_flg_type               OUT pk_types.cursor_type,
        o_value_type             OUT pk_types.cursor_type,
        o_nvalue                 OUT pk_types.cursor_type,
        o_dvalue                 OUT pk_types.cursor_type,
        o_vvalue                 OUT pk_types.cursor_type,
        o_vvalue_desc            OUT pk_types.cursor_type,
        o_criteria_value_type    OUT pk_types.cursor_type,
        o_id_adv_input           OUT pk_types.cursor_type,
        o_id_adv_input_field     OUT pk_types.cursor_type,
        o_id_adv_input_field_det OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol AVD Input VAlue for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param i_software                Software ID's
    * @param o_prtcl_adv_input_value   Cursor of Instituition Protocol_Advanced_Input_Value
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/05/04
    ********************************************************************************************/
    FUNCTION set_inst_prtcl_adv_input_value
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_software              IN table_number,
        o_prtcl_adv_input_value OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Connector set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param o_id_protocol_connector        Cursor of Protocol Connector ID
    * @param o_desc_protocol_connector      Cursor of Protocol Connector Description
    * @param o_flg_desc_protocol_conn       Cursor of Flg Description Protocol Connector  
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/04
    ********************************************************************************************/
    FUNCTION get_inst_protocol_connector
    (
        i_lang                        IN language.id_language%TYPE,
        o_id_protocol_connector       OUT pk_types.cursor_type,
        o_desc_protocol_connector     OUT pk_types.cursor_type,
        o_flg_desc_protocol_connector OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Context Author set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Protocols
    * @param o_first_name                   Cursor of First Name
    * @param o_last_name                    Cursor of Last Name
    * @param o_title                        Cursor of Title    
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/06
    ********************************************************************************************/
    FUNCTION get_inst_protocol_context_auth
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_protocol    OUT pk_types.cursor_type,
        o_first_name     OUT pk_types.cursor_type,
        o_last_name      OUT pk_types.cursor_type,
        o_title          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Context Auth for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_protocol_context_auth    Cursor of Instituition Protocol_Context_Author
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/06
    ********************************************************************************************/
    FUNCTION set_inst_protocol_context_auth
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_software              IN table_number,
        o_protocol_context_auth OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Context Image set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Protocols
    * @param o_file_name                    Cursor of File Name
    * @param o_img_desc                     Cursor of Image Desc
    * @param o_dt_img                       Cursor of Date Image 
    * @param o_img                          Cursor of Image 
    * @param o_img_thumbnail                Cursor of Image Thumbanail 
    * @param o_flg_status                   Cursor of Flg_Status 
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/06
    ********************************************************************************************/
    FUNCTION get_inst_protocol_context_img
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_protocol    OUT pk_types.cursor_type,
        o_file_name      OUT pk_types.cursor_type,
        o_img_desc       OUT pk_types.cursor_type,
        o_dt_img         OUT pk_types.cursor_type,
        o_img            OUT pk_types.cursor_type,
        o_img_thumbnail  OUT pk_types.cursor_type,
        o_flg_status     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Context Image for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_protocol_context_img     Cursor of Instituition Protocol_Context_Image
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/06
    ********************************************************************************************/
    FUNCTION set_inst_protocol_context_img
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        i_id_institution       IN institution.id_institution%TYPE,
        i_software             IN table_number,
        o_protocol_context_img OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Relations set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Protocols
    * @param o_id_protocol_element_par      Cursor of Protocol element parent
    * @param o_id_protocol_connector        Cursor of Protocol connector
    * @param o_id_protocol_element          Cursor of Protocol element
    * @param o_desc_relation                Cursor of Protocol relation description
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/06
    ********************************************************************************************/
    FUNCTION get_inst_protocol_relation
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        o_id_protocol             OUT pk_types.cursor_type,
        o_id_protocol_element_par OUT pk_types.cursor_type,
        o_id_protocol_connector   OUT pk_types.cursor_type,
        o_id_protocol_element     OUT pk_types.cursor_type,
        o_desc_relation           OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Relation for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_protocol_relation        Cursor of Instituition Protocol Relation
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/10
    ********************************************************************************************/
    FUNCTION set_inst_protocol_relation
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        o_protocol_relation OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Protocol Frequent set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Protocols
    * @param o_id_software                  Cursor of Software ID
    * @param o_rank                         Cursor of Rank
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/10
    ********************************************************************************************/
    FUNCTION get_inst_protocol_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_protocol    OUT pk_types.cursor_type,
        o_id_software    OUT pk_types.cursor_type,
        o_rank           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Protocol Frequent for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_protocol_frequent        Cursor of Instituition Protocol_Frequent
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/10
    ********************************************************************************************/
    FUNCTION set_inst_protocol_frequent
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        o_protocol_frequent OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get GUIDELINES set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_guideline                 Cursor of guideline
    * @param o_guideline_desc               Cursor of guideline_desc
    * @param o_flg_status                   Cursor of flg_status
    * @param o_context_title                Cursor of context_title  
    * @param o_context_adaptation           Cursor of context_adaptation
    * @param o_context_type_media           Cursor of context_type_media
    * @param o_context_editor               Cursor of context_editor 
    * @param o_id_guideline_ebm             Cursor of id_guideline_ebm
    * @param o_context_edition_site         Cursor of context_edition_site
    * @param o_context_edition              Cursor of context_edition
    * @param o_context_access               Cursor of context_access
    * @param o_id_context_language          Cursor of id_context_language
    * @param o_context_subtitle             Cursor of context_subtitle
    * @param o_id_context_assoc_lang        Cursor of id_context_assoc_lang
    * @param o_id_software                  Cursor of id_software
    * @param o_flg_type_recommend           Cursor of flg_type_recommend
    * @param o_context_desc                 Cursor of context_desc
    * @param o_id_content                   Cursor of id_content 
    * @param o_dt_context_edition           Cursor of dt_context_edition
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/11
    ********************************************************************************************/
    FUNCTION get_inst_guideline
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_software           IN software.id_software%TYPE,
        o_id_guideline          OUT pk_types.cursor_type,
        o_guideline_desc        OUT pk_types.cursor_type,
        o_flg_status            OUT pk_types.cursor_type,
        o_context_title         OUT pk_types.cursor_type,
        o_context_adaptation    OUT pk_types.cursor_type,
        o_context_type_media    OUT pk_types.cursor_type,
        o_context_editor        OUT pk_types.cursor_type,
        o_id_guideline_ebm      OUT pk_types.cursor_type,
        o_context_edition_site  OUT pk_types.cursor_type,
        o_context_edition       OUT pk_types.cursor_type,
        o_context_access        OUT pk_types.cursor_type,
        o_id_context_language   OUT pk_types.cursor_type,
        o_context_subtitle      OUT pk_types.cursor_type,
        o_id_context_assoc_lang OUT pk_types.cursor_type,
        o_id_software           OUT pk_types.cursor_type,
        o_flg_type_recommend    OUT pk_types.cursor_type,
        o_context_desc          OUT pk_types.cursor_type,
        o_id_content            OUT pk_types.cursor_type,
        o_dt_context_edition    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_inst_guideline      Cursor of Instituition protocol
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/11
    ********************************************************************************************/
    FUNCTION set_inst_guideline
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_guideline OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline link set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_id_guideline        Cursor of Guideline
    * @param o_id_link             Cursor of flags
    * @param o_link_type           Cursor of Link Type
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/11
    ********************************************************************************************/
    FUNCTION get_inst_guideline_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_guideline   OUT pk_types.cursor_type,
        o_id_link        OUT pk_types.cursor_type,
        o_link_type      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline link for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_guideline_link      Cursor of Instituition Guideline_Link
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/12
    ********************************************************************************************/
    FUNCTION set_inst_guideline_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_guideline_link OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline Task Link set by Protocol
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_id_guideline        Cursor of Guideline
    * @param o_id_task_link        Cursor of Task Link
    * @param o_task_type           Cursor of Task Type
    * @param o_task_notes          Cursor of Task Notes
    * @param o_id_task_attach      Cursor of Task Attach
    * @param o_task_codif          Cursor of Task Codificaton
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/12
    ********************************************************************************************/
    FUNCTION get_inst_guideline_task_link
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_guideline   OUT pk_types.cursor_type,
        o_id_task_link   OUT pk_types.cursor_type,
        o_task_type      OUT pk_types.cursor_type,
        o_task_notes     OUT pk_types.cursor_type,
        o_id_task_attach OUT pk_types.cursor_type,
        o_task_codif     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline Task link for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_guideline_task_link Cursor of Instituition Guideline_Taks_Link
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/18
    ********************************************************************************************/
    FUNCTION set_inst_guideline_task_link
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_institution      IN institution.id_institution%TYPE,
        i_software            IN table_number,
        o_guideline_task_link OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline Context Image set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_guideline                  Cursor of Guidelines
    * @param o_file_name                    Cursor of File Name
    * @param o_img_desc                     Cursor of Image Desc
    * @param o_dt_img                       Cursor of Date Image 
    * @param o_img                          Cursor of Image 
    * @param o_img_thumbnail                Cursor of Image Thumbanail 
    * @param o_flg_status                   Cursor of Flg_Status 
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/18
    ********************************************************************************************/
    FUNCTION get_inst_guideline_context_img
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_guideline   OUT pk_types.cursor_type,
        o_file_name      OUT pk_types.cursor_type,
        o_img_desc       OUT pk_types.cursor_type,
        o_dt_img         OUT pk_types.cursor_type,
        o_img            OUT pk_types.cursor_type,
        o_img_thumbnail  OUT pk_types.cursor_type,
        o_flg_status     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline Context Image for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_guideline_context_img    Cursor of Instituition Guideline_Context_Image
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/18
    ********************************************************************************************/
    FUNCTION set_inst_guideline_context_img
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_software              IN table_number,
        o_guideline_context_img OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline Context Author set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_guideline                 Cursor of Guideline
    * @param o_first_name                   Cursor of First Name
    * @param o_last_name                    Cursor of Last Name
    * @param o_title                        Cursor of Title    
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/18
    ********************************************************************************************/
    FUNCTION get_inst_guideline_cntext_auth
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_guideline   OUT pk_types.cursor_type,
        o_first_name     OUT pk_types.cursor_type,
        o_last_name      OUT pk_types.cursor_type,
        o_title          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline Context Auth for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_guideline_context_auth   Cursor of Instituition Guideline_Context_Author
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/18
    ********************************************************************************************/
    FUNCTION set_inst_guideline_cntext_auth
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_software               IN table_number,
        o_guideline_context_auth OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline Criteria set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_protocol                  Cursor of Guideline ID 
    * @param o_criteria_type                Cursor of Criteria Type
    * @param o_gender                       Cursor of Gender
    * @param o_min_age                      Cursor of min age
    * @param o_max_age                      Cursor of max age
    * @param o_min_weight                   Cursor of min weight
    * @param o_max_weight                   Cursor of max weight
    * @param o_id_weight_unit_mea           Cursor of weight unit measure ID
    * @param o_min_height                   Cursor of min height
    * @param o_max_height                   Cursor of max height
    * @param o_id_height_unit_mea           Cursor of height unit measure ID
    * @param o_imc_min                      Cursor of min IMC
    * @param o_imc_max                      Cursor of max IMC
    * @param o_id_blood_pres_unit_mea       Cursor of Blood pressure unit measure ID
    * @param o_min_blood_press_s            Cursor of min Blood pressure sistolic
    * @param o_max_blood_press_s            Cursor of max Blood pressure sistolic
    * @param o_min_blood_press_d            Cursor of min Blood pressure diastolic
    * @param o_max_blood_press_d            Cursor of max Blood pressure diastolic
    * @param o_error                        Error  
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/18
    ********************************************************************************************/
    FUNCTION get_inst_guideline_criteria
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_id_software            IN software.id_software%TYPE,
        o_id_guideline           OUT pk_types.cursor_type,
        o_criteria_type          OUT pk_types.cursor_type,
        o_gender                 OUT pk_types.cursor_type,
        o_min_age                OUT pk_types.cursor_type,
        o_max_age                OUT pk_types.cursor_type,
        o_min_weight             OUT pk_types.cursor_type,
        o_max_weight             OUT pk_types.cursor_type,
        o_id_weight_unit_mea     OUT pk_types.cursor_type,
        o_min_height             OUT pk_types.cursor_type,
        o_max_height             OUT pk_types.cursor_type,
        o_id_height_unit_mea     OUT pk_types.cursor_type,
        o_imc_min                OUT pk_types.cursor_type,
        o_imc_max                OUT pk_types.cursor_type,
        o_id_blood_pres_unit_mea OUT pk_types.cursor_type,
        o_min_blood_press_s      OUT pk_types.cursor_type,
        o_max_blood_press_s      OUT pk_types.cursor_type,
        o_min_blood_press_d      OUT pk_types.cursor_type,
        o_max_blood_press_d      OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline Criteria for a specific institution
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param o_guideline_criteria  Cursor of Instituition Guideline_Criteria
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/18
    ********************************************************************************************/
    FUNCTION set_inst_guideline_criteria
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        o_guideline_criteria OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline Criteria Links set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_guideline_criteria        Cursor of Guideline Criteria
    * @param o_id_link_other_criteria       Cursor of Link Other Criteria ID
    * @param o_id_link_other_criteria_type  Cursor of Link Other Criteria Type ID 
    * @param o_error                        Error  
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/18
    ********************************************************************************************/
    FUNCTION get_inst_guideline_crit_link
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        o_id_guideline_criteria   OUT pk_types.cursor_type,
        o_id_link_other_criteria  OUT pk_types.cursor_type,
        o_id_link_other_crit_type OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline Criteria Link for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_guideline_criteria_link   Cursor of Instituition Guideline_Criteria_Link
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/18
    ********************************************************************************************/
    FUNCTION set_inst_guideline_crit_link
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_software                IN table_number,
        o_guideline_criteria_link OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline ADV Input Value set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_adv_input_link            Cursor of adv input link
    * @param o_flg_type                     Cursor of Flg Type
    * @param o_value_type                   Cursor of Value Type
    * @param o_nvalue                       Cursor of n Value
    * @param o_dvalue                       Cursor of d Value
    * @param o_vvalue                       Cursor of v Value
    * @param o_vvalue_desc                  Cursor of v Value Description
    * @param o_criteria_value_type          Cursor of Criteria Value Type
    * @param o_id_adv_input                 Cursor of adv input
    * @param o_id_adv_input_field           Cursor of adv input field
    * @param o_id_adv_input_field_det       Cursor of adv input field det
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/19
    ********************************************************************************************/
    FUNCTION get_inst_guide_adv_input_value
    (
        i_lang                   IN language.id_language%TYPE,
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_software            IN software.id_software%TYPE,
        o_id_adv_input_link      OUT pk_types.cursor_type,
        o_flg_type               OUT pk_types.cursor_type,
        o_value_type             OUT pk_types.cursor_type,
        o_nvalue                 OUT pk_types.cursor_type,
        o_dvalue                 OUT pk_types.cursor_type,
        o_vvalue                 OUT pk_types.cursor_type,
        o_vvalue_desc            OUT pk_types.cursor_type,
        o_criteria_value_type    OUT pk_types.cursor_type,
        o_id_adv_input           OUT pk_types.cursor_type,
        o_id_adv_input_field     OUT pk_types.cursor_type,
        o_id_adv_input_field_det OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline AVD Input VAlue for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param i_software                Software ID's
    * @param o_guide_adv_input_value   Cursor of Instituition Guideline_Advanced_Input_Value
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/05/19
    ********************************************************************************************/
    FUNCTION set_inst_guide_adv_input_value
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_software              IN table_number,
        o_guide_adv_input_value OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Guideline Frequent set of markets, versions and sotwares
    *
    * @param i_lang                         Prefered language ID
    * @param i_market                       Market ID's
    * @param i_version                      ALERT version's
    * @param i_id_institution               Institution ID
    * @param i_id_software                  Software ID
    * @param o_id_guideline                  Cursor of Guidelines
    * @param o_id_software                  Cursor of Software ID
    * @param o_rank                         Cursor of Rank
    * @param o_error                        Error
    *
    * @return                               true or false on success or error
    *
    * @author                               MESS
    * @version                              2.6
    * @since                                2010/05/19
    ********************************************************************************************/
    FUNCTION get_inst_guideline_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_guideline   OUT pk_types.cursor_type,
        o_id_software    OUT pk_types.cursor_type,
        o_rank           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Guideline Frequent for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_guideline_frequent        Cursor of Instituition Guideline_Frequent
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           MESS
    * @version                          2.6
    * @since                            2010/05/19
    ********************************************************************************************/
    FUNCTION set_inst_guideline_frequent
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        o_guideline_frequent OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Comp_Config set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_comp_Axe            Cursor of Comp_Axe
    * @param o_complication        Cursor of Complication
    * @param o_id_clinical_service Cursor of Clinical_Service
    * @param o_flg_configuration   Cursor of Flg_Configuration
    * @param o_id_sys_list         Cursor of ID_Sys_List
    * @param o_rank                Cursor of Rank
    * @param o_flg_default         Cursor of Flg_Default
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/20
    ********************************************************************************************/
    FUNCTION get_inst_comp_config
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        o_complication        OUT pk_types.cursor_type,
        o_comp_axe            OUT pk_types.cursor_type,
        o_id_clinical_service OUT pk_types.cursor_type,
        o_flg_configuration   OUT pk_types.cursor_type,
        o_id_sys_list         OUT pk_types.cursor_type,
        o_rank                OUT pk_types.cursor_type,
        o_flg_default         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Comp_Config Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param i_software                Software ID's
    * @param o_comp_config             Cursor of Instituition Comp_Config
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/05/21
    ********************************************************************************************/
    FUNCTION set_inst_comp_config
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_comp_config    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Comp_Axe_Detail set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_id_comp_axe         Cursor of Comp_Axe_ID
    * @param o_id_parent_axe       Cursor of Comp_Axe_Parent_ID
    * @param o_id_comp_axe_group   Cursor of Comp_Axe_Group
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/21
    ********************************************************************************************/
    FUNCTION get_inst_comp_axe_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        o_id_comp_axe       OUT pk_types.cursor_type,
        o_id_parent_axe     OUT pk_types.cursor_type,
        o_id_comp_axe_group OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set Comp_Axe_Detail Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param o_comp_axe_detail         Cursor of Instituition Comp_Axe_Detail
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/05/31
    ********************************************************************************************/
    FUNCTION set_inst_comp_axe_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN table_number,
        i_version         IN table_varchar,
        o_comp_axe_detail OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Checklist set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_checklist           Cursor of checklist
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/07
    ********************************************************************************************/
    FUNCTION get_inst_checklist
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN table_number,
        i_version         IN table_varchar,
        i_id_institution  IN institution.id_institution%TYPE,
        o_id_checklist    OUT pk_types.cursor_type,
        o_flg_cnt_creator OUT pk_types.cursor_type,
        o_internal_name   OUT pk_types.cursor_type,
        o_flg_status      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Set CHECKLIST_INST Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param o_checklist_inst          Cursor of Instituition CHECKLIST_INST
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/07/07
    ********************************************************************************************/
    FUNCTION set_inst_checklist_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_checklist_inst OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get REHAB_AREA_INTERV set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_id_rehab_area       Cursor of Rehab_Area
    * @param o_id_interv           Cursor of Intervention
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3.3
    * @since                       2010/09/24
    ********************************************************************************************/
    FUNCTION get_inst_rehab_area_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_id_rehab_area  OUT pk_types.cursor_type,
        o_id_interv      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set REHAB_AREA_INTERV Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param o_rehab_area_interv       Cursor of REHAB_AREA_INTERV
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.3.3
    * @since                           2010/09/24
    ********************************************************************************************/
    FUNCTION set_inst_rehab_area_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        o_rehab_area_interv OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get REHAB_AREA_INST_SOFT set of markets, versions and sotwares
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_version                ALERT version's
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param o_id_rehab_area_interv   Cursor of rehab_area_interv
    * @param o_id_rehab_ss_type       Cursor of id_rehab_ss_type
    * @param o_flg_execute            Cursor of flg_execute
    * @param o_flg_add_remove         Cursor of flg_add_remove
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6.0.3.3
    * @since                          2010/09/24
    ********************************************************************************************/
    FUNCTION get_inst_rehab_inst_soft
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE,
        o_id_rehab_area_interv OUT pk_types.cursor_type,
        o_id_rehab_ss_type     OUT pk_types.cursor_type,
        o_flg_execute          OUT pk_types.cursor_type,
        o_flg_add_remove       OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set REHAB_AREA_INST_SOFT Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param i_software                Software ID
    * @param o_rehab_inst_soft         Cursor of REHAB_INST_SOFT
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.3.3
    * @since                           2010/09/24
    ********************************************************************************************/
    FUNCTION set_inst_rehab_inst_soft
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN table_number,
        i_version         IN table_varchar,
        i_id_institution  IN institution.id_institution%TYPE,
        i_software        IN table_number,
        o_rehab_inst_soft OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get REHAB_AREA_INST set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_rehab_content    ID_CONTENT
    * @param o_id_rehab_area       Cursor of Rehab_Area
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3.3
    * @since                       2010/11/25
    ********************************************************************************************/
    FUNCTION get_inst_rehab_area_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_ra_rehab_area IN rehab_area.id_rehab_area%TYPE,
        o_id_rehab_area    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set REHAB_AREA_INST set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_rehab_content    ID_CONTENT
    * @param o_id_rehab_area       Cursor of Rehab_Area
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3.3
    * @since                       2010/11/25
    ********************************************************************************************/
    FUNCTION set_inst_rehab_area_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_ra_rehab_area IN rehab_area.id_rehab_area%TYPE,
        o_rehab_area_inst  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set HIDRICS CHARACTERISTICS Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_hidrics_charact         Cursor of Instituition HIDRICS CHARACTERISTICS
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/07/12
    ********************************************************************************************/
    FUNCTION set_def_hidrics_charact
    (
        i_lang            IN language.id_language%TYPE,
        i_id_market       IN market.id_market%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_hidrics_charact OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Hidrics_Charact_Rel set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_hdrcs_charact_def   Hidrics_Charact Default ID's
    * @param i_id_hdrcs_charact       Hidrics_Charact Alert ID's
    * @param o_hidrics_charact_rel    Cursor of Hidrics_Charact_Rel
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/13
    ********************************************************************************************/
    FUNCTION set_inst_hidrics_charact_rel
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_market            IN market.id_market%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_hdrcs_charact_def IN hidrics_charact.id_hidrics_charact%TYPE,
        i_id_hdrcs_charact     IN hidrics_charact.id_hidrics_charact%TYPE,
        o_hidrics_charact_rel  OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set HIDRICS WAY Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_hidrics_way             Cursor of Instituition HIDRICS WAY
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/07/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_way
    (
        i_lang           IN language.id_language%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_hidrics_way    OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Hidrics_Way_Rel set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_hdrcs_way_def       Hidrics_Way Default ID's
    * @param i_id_hdrcs_way           Hidrics_Way Alert ID's
    * @param o_hidrics_way_rel        Cursor of Hidrics_Way_Rel
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/13
    ********************************************************************************************/
    FUNCTION set_inst_hidrics_way_rel
    (
        i_lang             IN language.id_language%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_hdrcs_way_def IN way.id_way%TYPE,
        i_id_hdrcs_way     IN way.id_way%TYPE,
        o_hidrics_way_rel  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Hidrics_Location_Rel set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_hdrcs_way_def       Hidrics_Way Default ID's
    * @param i_id_hdrcs_way           Hidrics_Way Alert ID's
    * @param o_hidrics_loc_rel        Cursor of Hidrics_Location_Rel
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/13
    ********************************************************************************************/
    FUNCTION set_inst_hidrics_loc_rel
    (
        i_lang             IN language.id_language%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_hdrcs_way_def IN way.id_way%TYPE,
        i_id_hdrcs_way     IN way.id_way%TYPE,
        o_hidrics_loc_rel  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Hidrics_Configuration 
    *
    * @param i_lang                   Prefered language ID
    * @param o_hidrics_confs          Cursor of Hidrics_Location_Rel
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/13
    ********************************************************************************************/
    FUNCTION set_inst_hidrics_configuration
    (
        i_lang           IN language.id_language%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_hidrics_confs  OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get EXAM_BODY_STRUCTURE configuration set of markets, versions
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param o_exam_body_structure Cursor of Configuration details
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/05/31
    ********************************************************************************************/
    FUNCTION get_inst_exam_body_structure
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        o_exam_body_structure OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set EXAM_BODY_STRUCTURE Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID's
    * @param i_version                 ALERT version's
    * @param i_id_institution          Institution ID
    * @param o_exam_body_structure     Cursor of EXAM_BODY_STRUCTURE
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.4
    * @since                           2010/10/08
    ********************************************************************************************/
    FUNCTION set_inst_exam_body_structure
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        o_exam_body_structure OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set GET_INST_HABTIS by Market and Institution
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5
    * @since                       2010/12/14
    ********************************************************************************************/
    FUNCTION get_inst_habits
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_id_habit       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set SET_INST_HABITS by Market, Software, Institution
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5
    * @since                       2010/12/14
    ********************************************************************************************/
    FUNCTION set_inst_habits
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        o_id_habits      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get QUESTIONNAIRE_RESPONSE set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/17
    ********************************************************************************************/
    FUNCTION get_inst_quest_response
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        o_id_questionnaire OUT pk_types.cursor_type,
        o_id_response      OUT pk_types.cursor_type,
        o_rank             OUT pk_types.cursor_type,
        o_id_content       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set QUESTIONNAIRE_RESPONSE
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/17
    ********************************************************************************************/
    FUNCTION set_inst_quest_response
    (
        i_lang          IN language.id_language%TYPE,
        i_market        IN table_number,
        i_version       IN table_varchar,
        o_id_quest_resp OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get EXAM_UESTIONNAIRE set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/18
    ********************************************************************************************/
    FUNCTION get_inst_exam_questionnaire
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        o_id_exam          OUT pk_types.cursor_type,
        o_id_questionnaire OUT pk_types.cursor_type,
        o_flg_type         OUT pk_types.cursor_type,
        o_flg_mandatory    OUT pk_types.cursor_type,
        o_rank             OUT pk_types.cursor_type,
        o_gender           OUT pk_types.cursor_type,
        o_flg_time         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set EXAM_QUESTIONNAIRE
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/18
    ********************************************************************************************/
    FUNCTION set_inst_exam_questionnaire
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN table_number,
        i_version              IN table_varchar,
        o_id_exam_questionaire OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set GET_INST TIMELINE Vertical Axis by Market, Software, Institution
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.2
    * @since                       2010/11/22
    ********************************************************************************************/
    FUNCTION get_inst_tl_vertical_axis
    (
        i_lang           IN language.id_language%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_id_tl_timeline OUT pk_types.cursor_type,
        o_id_tl_software OUT pk_types.cursor_type,
        o_rank           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set SET_INST TIMELINE Vertical Axis by Market, Software, Institution
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.2
    * @since                       2010/11/23
    ********************************************************************************************/
    FUNCTION set_inst_tl_vertical_axis
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_software              IN table_number,
        o_inst_tl_vertical_axis OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set GET_INST TIMELINE Horizontal Axis by Market, Software, Institution
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.2
    * @since                       2010/11/23
    ********************************************************************************************/
    FUNCTION get_inst_tl_horizontal_axis
    (
        i_lang               IN language.id_language%TYPE,
        i_id_market          IN market.id_market%TYPE,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_software        IN software.id_software%TYPE,
        o_id_tl_timeline     OUT pk_types.cursor_type,
        o_id_tl_scale_xupper OUT pk_types.cursor_type,
        o_id_tl_scale_xlower OUT pk_types.cursor_type,
        o_rank               OUT pk_types.cursor_type,
        o_flg_default        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set SET_INST TIMELINE Horizontal Axis by Market, Software, Institution
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.2
    * @since                       2010/11/23
    ********************************************************************************************/
    FUNCTION set_inst_tl_horizontal_axis
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN table_number,
        i_version                 IN table_varchar,
        i_id_institution          IN institution.id_institution%TYPE,
        i_software                IN table_number,
        o_inst_tl_horizontal_axis OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get HIDRICS_DEVICE_REL set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_device_rel
    (
        i_lang              IN language.id_language%TYPE,
        i_id_market         IN market.id_market%TYPE,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        o_id_hidrics_device OUT pk_types.cursor_type,
        o_id_hidrics        OUT pk_types.cursor_type,
        o_id_way            OUT pk_types.cursor_type,
        o_rank              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set HIDRICS_DEVICE_REL set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION set_inst_hidrics_device_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        o_hidrics_device_rel OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get HIDRICS_OCCURS_TYPE_REL set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_occurs_tp_rel
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_market              IN market.id_market%TYPE,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        o_id_hidrics_occurs_type OUT pk_types.cursor_type,
        o_id_hidrics             OUT pk_types.cursor_type,
        o_rank                   OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set HIDRICS_DEVICE_REL set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION set_inst_hidrics_occurs_tp_rel
    (
        i_lang                  IN language.id_language%TYPE,
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        o_hidrics_occurs_tp_rel OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Habits char relation
    *
    * @param i_lang                Prefered language ID
    * @param i_market                Prefered market ID
    * @param i_version                Prefered content version
    * @param o_habit_char              Habits_characterization ids array
    * @param o_habit              Habit ids array
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/04/21
    ********************************************************************************************/
    FUNCTION get_inst_habit_char_rel
    (
        i_lang       IN language.id_language%TYPE,
        i_market     IN market.id_market%TYPE,
        i_version    IN VARCHAR2,
        o_habit_char OUT table_number,
        o_habit      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Habits Char REl
    *
    * @param i_lang                Prefered language ID
    * @param i_market                Prefered market ID
    * @param i_version                Prefered content version
    * @param o_habit_char              Habits_characterization ids array
    * @param o_habit              Habit ids array
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/04/21
    ********************************************************************************************/
    FUNCTION set_inst_habit_char_rel
    (
        i_lang       IN language.id_language%TYPE,
        i_market     IN market.id_market%TYPE,
        i_version    IN VARCHAR2,
        o_habit_char OUT table_number,
        o_habit      OUT table_number,
        o_error      OUT t_error_out
        
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of supply for a set of markets and versions.
    *
    * @param i_lang                        Prefered language ID
    * @param i_market                      Market ID's
    * @param i_version                     ALERT version's
    * @param i_id_institution              Institution ID
    * @param i_id_software                 Software ID
    * @param o_id_supply                   Cursor of default data
    * @param o_quantity                    Cursor of default data
    * @param o_id_unit_measure             Cursor of default data
    * @param o_flg_cons_type               Cursor of default data
    * @param o_flg_reusable                Cursor of default data
    * @param o_flg_editable                Cursor of default data
    * @param o_total_avail_quantity        Cursor of default data
    * @param o_flg_preparing               Cursor of default data
    * @param o_flg_countable               Cursor of default data
    * @param o_error                       Error
    *
    *
    * @return                              true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION get_supply_soft_inst
    (
        i_lang                 IN language.id_language%TYPE,
        i_market               IN market.id_market%TYPE,
        i_version              IN VARCHAR2,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE,
        o_id_supply            OUT pk_types.cursor_type,
        o_quantity             OUT pk_types.cursor_type,
        o_id_unit_measure      OUT pk_types.cursor_type,
        o_flg_cons_type        OUT pk_types.cursor_type,
        o_flg_reusable         OUT pk_types.cursor_type,
        o_flg_editable         OUT pk_types.cursor_type,
        o_total_avail_quantity OUT pk_types.cursor_type,
        o_flg_preparing        OUT pk_types.cursor_type,
        o_flg_countable        OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supplies for a specific institution and software.
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID
    * @param i_version                 Version ID
    * @param i_id_institution          Institution ID
    * @param i_id_software             Software ID
    * @param o_supply                  Cursor of supplies
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_soft_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN market.id_market%TYPE,
        i_version        IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_supply         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of supply sup. area for a set of markets and versions.
    *
    * @param i_lang                        Prefered language ID
    * @param i_market                      Market ID's
    * @param i_version                     ALERT version's
    * @param i_id_institution              Institution ID
    * @param i_id_software                 Software ID
    * @param o_id_supply_soft_inst         Cursor of default data
    * @param o_id_supply_area              Cursor of default data
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION get_supply_sup_area
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        o_id_supply_soft_inst OUT pk_types.cursor_type,
        o_id_supply_area      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supply sup. area for a specific market and version.
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID
    * @param i_version                 Version ID
    * @param i_id_institution          Institution ID
    * @param i_id_software             Software ID
    * @param o_id_supply_soft_inst     Cursor of supply soft. inst.
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_sup_area
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN table_number,
        o_id_supply_soft_inst OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of supply loc. default for a set of markets and versions.
    *
    * @param i_lang                        Prefered language ID
    * @param i_market                      Market ID's
    * @param i_version                     ALERT version's
    * @param i_id_institution              Institution ID
    * @param i_id_software                 Software ID
    * @param o_id_supply_location          Cursor of default data
    * @param o_id_supply_soft_inst         Cursor of default data
    * @param o_flg_default                 Cursor of default data
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2011/11/09
    ********************************************************************************************/
    FUNCTION get_supply_loc_default
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        o_id_supply_location  OUT pk_types.cursor_type,
        o_id_supply_soft_inst OUT pk_types.cursor_type,
        o_flg_default         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supply loc. default for a specific market and version.
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID
    * @param i_version                 Version ID
    * @param i_id_institution          Institution ID
    * @param i_id_software             Software ID
    * @param o_id_supply_location      Cursor of supply location
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           09-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_loc_default
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN market.id_market%TYPE,
        i_version            IN VARCHAR2,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_software        IN table_number,
        o_id_supply_location OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of supply context for a set of markets and versions.
    *
    * @param i_lang                        Prefered language ID
    * @param i_market                      Market ID's
    * @param i_version                     ALERT version's
    * @param i_id_institution              Institution ID
    * @param i_id_software                 Software ID
    * @param o_id_supply                   Cursor of default data
    * @param o_quantity                    Cursor of default data
    * @param o_id_unit_measure             Cursor of default data
    * @param o_id_context                  Cursor of default data
    * @param o_flg_context                 Cursor of default data
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.5
    * @since                       2011/11/09
    ********************************************************************************************/
    FUNCTION get_supply_context
    (
        i_lang            IN language.id_language%TYPE,
        i_market          IN market.id_market%TYPE,
        i_version         IN VARCHAR2,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_software     IN software.id_software%TYPE,
        o_id_supply       OUT pk_types.cursor_type,
        o_quantity        OUT pk_types.cursor_type,
        o_id_unit_measure OUT pk_types.cursor_type,
        o_id_context      OUT pk_types.cursor_type,
        o_flg_context     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supplies context.
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID
    * @param i_version                 Version
    * @param i_id_institution          Institution ID
    * @param i_id_software             Software ID
    * @param o_id_supply               Cursor of supplies identifier
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           09-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_context
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN market.id_market%TYPE,
        i_version        IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_id_supply      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Clinical Decision Rules definitions for a set of markets and versions.
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_id_supply_reason    Cursor of default data
    * @param o_id_content          Cursor of default data
    * @param o_flg_type            Cursor of default data
    * @param o_code_supply_reason  Cursor of default data
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           09-NOV-2011
    ********************************************************************************************/
    FUNCTION get_supply_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN market.id_market%TYPE,
        i_version          IN VARCHAR2,
        o_id_supply_reason OUT pk_types.cursor_type,
        o_id_content       OUT pk_types.cursor_type,
        o_flg_type         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supply reasons for a specific market and version.
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID
    * @param i_version                 Version ID
    * @param o_id_supply_reason      Cursor of supply reasons
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           09-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN market.id_market%TYPE,
        i_version          IN VARCHAR2,
        o_id_supply_reason OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Supply Relation Configuration for a set of markets and versions.
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param o_id_supply           Cursor of default data
    * @param o_id_supply_item      Cursor of default data
    * @param o_id_quantity         Cursor of default data
    * @param o_unit_mea            Cursor of default data
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           23-NOV-2011
    ********************************************************************************************/
    FUNCTION get_supply_relation
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN market.id_market%TYPE,
        i_version        IN VARCHAR2,
        o_id_supply      OUT pk_types.cursor_type,
        o_id_supply_item OUT pk_types.cursor_type,
        o_id_quantity    OUT pk_types.cursor_type,
        o_unit_mea       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supply Relation for a specific market and version.
    *
    * @param i_lang                    Prefered language ID
    * @param i_market                  Market ID
    * @param i_version                 Version ID
    * @param o_id_supply               Cursor of supply reasons
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           23-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_relation
    (
        i_lang               IN language.id_language%TYPE,
        i_market             IN market.id_market%TYPE,
        i_version            IN VARCHAR2,
        o_id_supply_relation OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False and list of result notes configuration details by market/version/software
    *
    * @param i_lang                  Language id
    * @param i_market                Market id Array
    * @param i_version               Version Array
    * @param i_id_institution        Institution id
    * @param i_id_software           Software id Array
    * @param o_resnt                 Default detailed cursor output
    * @param o_error                 error output
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/04/18
    * @version                       2.6.1.8
    ********************************************************************************************/
    FUNCTION get_inst_result_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_resnt          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False and list of result notes configuration ids by market/version/software
    *
    * @param i_lang                  Language id
    * @param i_market                Market id Array
    * @param i_version               Version Array
    * @param i_id_institution        Institution id
    * @param i_id_software           Software id Array
    * @param o_resnt                 Default detailed cursor output
    * @param o_error                 error output
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/04/18
    * @version                       2.6.1.8
    ********************************************************************************************/
    FUNCTION set_inst_result_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_resnt          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns list of analysis collection configuration properties
    *
    * @param i_lang                  Language id
    * @param i_market                Market id Array
    * @param i_version               Version Array
    * @param i_id_institution        Institution id
    * @param i_id_software           Software id
    * @param o_labcollection         id_collection output cursor
    * @param o_error                 error output
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/19
    * @version                       2.6.1.6
    ********************************************************************************************/
    FUNCTION get_inst_analysis_collection
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_labcolection   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False and list of analysis collection new Id's
    *
    * @param i_lang                  Language id
    * @param i_market                Market id Array
    * @param i_version               Version Array
    * @param i_id_institution        Institution id
    * @param i_id_software           Software id Array
    * @param o_labcollection         id_collection output cursor
    * @param o_error                 error output
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/19
    * @version                       2.6.1.6
    ********************************************************************************************/
    FUNCTION set_inst_analysis_collection
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_labcolection   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns list of analysis collection configuration properties
    *
    * @param i_lang                  Language id
    * @param i_market                Market id Array
    * @param i_version               Version Array
    * @param i_id_institution        Institution id
    * @param i_id_software           Software id
    * @param o_labcolection_int      id_collection output cursor
    * @param o_error                 error output
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/19
    * @version                       2.6.1.6
    ********************************************************************************************/
    FUNCTION get_inst_lab_collection_int
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN table_number,
        o_labcolection_int OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False and list of analysis collection internal new Id's
    *
    * @param i_lang                  Language id
    * @param i_market                Market id Array
    * @param i_version               Version Array
    * @param i_id_institution        Institution id
    * @param i_id_software           Software id Array
    * @param o_labcollection_int         id_collection output cursor
    * @param o_error                 error output
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/21
    * @version                       2.6.1.6
    ********************************************************************************************/
    FUNCTION set_inst_lab_collection_int
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_software       IN table_number,
        o_labcollection_int OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get OCCUPATION DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @param i_market              List of markets to colect content
    * @param i_version             List of content versions to colect content     
    * @param o_id_occupation       List of ids configured
    * @param o_error               Error Out
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/25
    ********************************************************************************************/
    FUNCTION get_def_occupation
    (
        i_lang          IN language.id_language%TYPE,
        i_market        IN table_number,
        i_version       IN table_varchar,
        o_id_occupation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set OCCUPATION DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @param i_market              List of markets to colect content
    * @param i_version             List of content versions to colect content     
    * @param o_id_occupation       List of ids configured
    * @param o_error               Error Out
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/25
    ********************************************************************************************/
    FUNCTION set_def_occupation
    (
        i_lang          IN language.id_language%TYPE,
        i_market        IN table_number,
        i_version       IN table_varchar,
        o_id_occupation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP_COMPOSITION for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP_COMPOSITION_HIST for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP_COMPOSITION_TERM for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition_term
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ICNP TASK COMPOSITION BY SOFTWARE AND specified institution.
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_inst_interv_drug    Cursor of default data
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/17
    ********************************************************************************************/
    FUNCTION set_inst_task_comp_search
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Positionings
    *
    * @param i_lang                Prefered language ID
    * @param o_positioning         Positioning
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2013/03/28
    ********************************************************************************************/
    FUNCTION set_def_positioning
    (
        i_lang    IN language.id_language%TYPE,
        i_market  IN table_number,
        i_version IN table_varchar,
        o_result  OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Interventions Categories
    *
    * @param i_lang                Prefered language ID
    * @param o_interv_cat          Interventions categories
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/31
    ********************************************************************************************/
    FUNCTION set_inst_interv_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_result         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Dashboard areas configuration
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/15
    ********************************************************************************************/
    FUNCTION set_dash_da_mkt_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Dashboard areas configuration
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/15
    ********************************************************************************************/
    FUNCTION set_dash_da_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list                
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list                
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_taskgoaltask_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Checks and removes all order set, guideline and protocols without tasks
    *
    * @param i_lang                    Prefered language ID
    * @param i_id_institution          Institution ID
    * @param o_error                   Error
    *
    * @author                          RMGM
    * @version                         v2.6.2.0
    * @since                           16/02/2012
    ********************************************************************************************/
    PROCEDURE orders_double_check
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    );
    /********************************************************************************************
    * Check the list of child clinical_services ids from a parent selection
    *
    * @param i_lang                Language ID
    * @param i_clinical_service    Primary clinical service Parent ID
    *
    * @return                      table of child clinical services ids
    *
    * @author                      RMGM
    * @version                     2.6.1.9
    * @since                       2012/06/20
    ********************************************************************************************/
    FUNCTION check_clinical_service_parent
    (
        i_lang      IN language.id_language%TYPE,
        i_cs_parent IN clinical_service.id_clinical_service%TYPE
    ) RETURN table_number;
    /********************************************************************************************
    * Set a Default Parameterization for a specific institution using new engine
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)    
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/05
    ********************************************************************************************/
    FUNCTION set_inst_default_param_new
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        i_commit_at_end  IN VARCHAR2,
        o_results        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

    g_flg_available VARCHAR2(1);
    g_yes           VARCHAR2(1);
    g_active        VARCHAR2(1);
    g_version       VARCHAR2(30);

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
    g_generic     NUMBER;

    g_func_name  VARCHAR2(500);
    g_table_name VARCHAR2(500);
END pk_backoffice_default;
/
/
