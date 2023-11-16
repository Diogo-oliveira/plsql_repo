/*-- Last Change Revision: $Rev: 2028592 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_default_content IS
    SUBTYPE t_big_char IS CLOB;
    SUBTYPE t_med_char IS VARCHAR2(0500 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0100 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    /********************************************************************************************
    * Set Default translations 
    *
    * @param i_lang                Prefered language ID
    * @param i_table               Table Name for get translations
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.0.5
    * @since                       2011/03/15
    ********************************************************************************************/
    FUNCTION set_def_translations
    (
        i_lang  IN language.id_language%TYPE,
        i_table IN user_tables.table_name%TYPE,
        o_res   OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/16
    ********************************************************************************************/
    FUNCTION set_def_content
    (
        i_lang                   IN language.id_language%TYPE,
        o_health_plan_entities   OUT table_number,
        o_health_plans           OUT table_number,
        o_clinical_services      OUT pk_types.cursor_type,
        o_analysis_parameters    OUT table_number,
        o_sample_types           OUT table_number,
        o_sample_rec             OUT table_number,
        o_exam_cat               OUT table_number,
        o_analysis               OUT table_number,
        o_analysis_res_calcs     OUT table_number,
        o_analysis_res_par_calcs OUT table_number,
        o_analysis_loinc         OUT table_number,
        o_analysis_desc          OUT table_number,
        o_exams                  OUT table_number,
        o_interv                 OUT table_number,
        o_interv_cat             OUT table_number,
        o_supplies               OUT table_number,
        o_habits                 OUT table_number,
        o_habit_char             OUT table_number,
        o_hidrics                OUT table_number,
        o_transp_entity          OUT table_number,
        o_disch_reas             OUT table_number,
        o_disch_dest             OUT table_number,
        o_disch_instr_group      OUT table_number,
        o_disch_instructions     OUT table_number,
        o_icnp_compositions      OUT pk_types.cursor_type,
        o_events                 OUT pk_types.cursor_type,
        o_lens                   OUT table_number,
        o_necessity              OUT table_number,
        o_codification           OUT table_number,
        o_codification_analysis  OUT table_number,
        o_interv_codification    OUT table_number,
        o_exam_codification      OUT table_number,
        o_transfer_option        OUT table_number,
        o_sr_intervention        OUT table_number,
        o_sr_equip               OUT table_number,
        o_sr_equip_kit           OUT table_number,
        o_sr_equip_period        OUT table_number,
        o_diet_parent            OUT pk_types.cursor_type,
        o_diet                   OUT pk_types.cursor_type,
        o_positioning            OUT table_number,
        o_speciality             OUT table_number,
        o_physiatry_area         OUT table_number,
        o_interv_physiatry_area  OUT table_number,
        o_comp_axe               OUT table_number,
        o_complication           OUT table_number,
        o_comp_axe_group         OUT table_number,
        o_checklist              OUT table_number,
        o_rehab_area             OUT table_number,
        o_rehab_session_type     OUT table_varchar,
        o_body_structure         OUT table_number,
        o_questionnaire          OUT pk_types.cursor_type,
        o_response               OUT pk_types.cursor_type,
        o_hidrics_device         OUT pk_types.cursor_type,
        o_hidrics_occurs_type    OUT pk_types.cursor_type,
        o_isencao                OUT table_number,
        --o_id_relation_set       OUT table_number,
        o_supply_type   OUT pk_types.cursor_type,
        o_supply        OUT pk_types.cursor_type,
        o_res_notes     OUT pk_types.cursor_type,
        o_labt_st       OUT pk_types.cursor_type,
        o_labt_bs       OUT pk_types.cursor_type,
        o_labt_compl    OUT pk_types.cursor_type,
        o_mcdt_nature   OUT table_number,
        o_mcdt_nisencao OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Health Plans
    *
    * @param i_lang                 Prefered language ID
    * @param o_health_plan_entities Health Plan Entities
    * @param o_health_plans         Health Plans
    * @param o_error                Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/16
    ********************************************************************************************/
    FUNCTION set_def_health_plans
    (
        i_lang                 IN language.id_language%TYPE,
        o_health_plan_entities OUT table_number,
        o_health_plans         OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Clinical Services
    *
    * @param i_lang                Prefered language ID
    * @param o_clinical_services   Clinical Services
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Mauro Sousa
    * @version                     0.4
    * @since                       2010/11/29
    ********************************************************************************************/
    FUNCTION set_def_clinical_services
    (
        i_lang              IN language.id_language%TYPE,
        o_clinical_services OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Analysis Parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_parameters Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis_parameters
    (
        i_lang                IN language.id_language%TYPE,
        o_analysis_parameters OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Samples Types
    *
    * @param i_lang                Prefered language ID
    * @param o_sample_types        Samples Types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_sample_types
    (
        i_lang         IN language.id_language%TYPE,
        o_sample_types OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Samples Recipients
    *
    * @param i_lang                Prefered language ID
    * @param o_sample_recipients   Sample Recipients
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_sample_recipients
    (
        i_lang              IN language.id_language%TYPE,
        o_sample_recipients OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Exam Categories
    *
    * @param i_lang                Prefered language ID
    * @param o_exam_categories     Exam categories
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_exam_categories
    (
        i_lang            IN language.id_language%TYPE,
        o_exam_categories OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Analysis
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis            Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis
    (
        i_lang     IN language.id_language%TYPE,
        o_analysis OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Analysis Groups
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_groups     Analysis Groups
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION set_def_analysis_groups
    (
        i_lang            IN language.id_language%TYPE,
        o_analysis_groups OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Analysis Loinc Codes
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis            Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis_loinc
    (
        i_lang           IN language.id_language%TYPE,
        o_analysis_loinc OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Analysis Descriptions
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis            Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis_desc
    (
        i_lang          IN language.id_language%TYPE,
        o_analysis_desc OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Exams
    *
    * @param i_lang                Prefered language ID
    * @param o_exams               Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION set_def_exams
    (
        i_lang  IN language.id_language%TYPE,
        o_exams OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Interventions
    *
    * @param i_lang                Prefered language ID
    * @param o_interventions       Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/31
    ********************************************************************************************/
    FUNCTION set_def_interventions
    (
        i_lang          IN language.id_language%TYPE,
        o_interventions OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Supplies
    *
    * @param i_lang                Prefered language ID
    * @param o_supplies            Supplies
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_supplies
    (
        i_lang     IN language.id_language%TYPE,
        o_supplies OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Habits
    *
    * @param i_lang                Prefered language ID
    * @param o_habits              Habits
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_habits
    (
        i_lang   IN language.id_language%TYPE,
        o_habits OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Hidrics Types
    *
    * @param i_lang                Prefered language ID
    * @param o_hidrics_type        Hidrics Types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_hidrics_type
    (
        i_lang         IN language.id_language%TYPE,
        o_hidrics_type OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set HIDRICS LOCATION Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_hidrics_location        Cursor of Instituition HIDRICS LOCATIONS
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/07/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_location
    (
        i_lang             IN language.id_language%TYPE,
        o_hidrics_location OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Hidrics
    *
    * @param i_lang                Prefered language ID
    * @param o_hidrics             Hidrics
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_hidrics
    (
        i_lang    IN language.id_language%TYPE,
        o_hidrics OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Transport entities
    *
    * @param i_lang                Prefered language ID
    * @param o_transp              Transport entities
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_transp
    (
        i_lang   IN language.id_language%TYPE,
        o_transp OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Discharge Reasons
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_reas          Discharge Reasons
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_discharge_reason
    (
        i_lang       IN language.id_language%TYPE,
        o_disch_reas OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Discharge Destinations
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_dest          Discharge Destinations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_discharge_dest
    (
        i_lang       IN language.id_language%TYPE,
        o_disch_dest OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Groups of discharge instructions
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_instr_group   Groups of discharge instructions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_disch_instr_group
    (
        i_lang              IN language.id_language%TYPE,
        o_disch_instr_group OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Discharge instructions
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_instructions  Discharge instructions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/06
    ********************************************************************************************/
    FUNCTION set_def_disch_instructions
    (
        i_lang               IN language.id_language%TYPE,
        o_disch_instructions OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Events (analysis, habits, vital signs)
    *
    * @param i_lang                Prefered language ID
    * @param o_events              Events (analysis, habits, vital signs)
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/14
    ********************************************************************************************/
    FUNCTION set_def_events
    (
        i_lang   IN language.id_language%TYPE,
        o_events OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Lens
    *
    * @param i_lang                Prefered language ID
    * @param o_diagnosis           Lens
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION set_def_lens
    (
        i_lang  IN language.id_language%TYPE,
        o_lens  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Physiatry Area
    *
    * @param i_lang                 Prefered language ID
    * @param o_physiatry_area       Physiatry_area
    * @param o_error                Error
    *
    * @return                       true or false on success or error
    *
    * @author                       MESS
    * @version                      2.6
    * @since                        2010/04/29
    ********************************************************************************************/
    FUNCTION set_def_physiatry_area
    (
        i_lang           IN language.id_language%TYPE,
        o_physiatry_area OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default INTERV_PHYSIATRY_AREA
    *
    * @param i_lang                Prefered language ID
    * @param o_interv_physiatry_area          interv_physiatry_area
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/29
    ********************************************************************************************/
    FUNCTION set_def_interv_physiatry_area
    (
        i_lang                  IN language.id_language%TYPE,
        o_interv_physiatry_area OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Necessity
    *
    * @param i_lang                Prefered language ID
    * @param o_necessity           Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_necessity
    (
        i_lang      IN language.id_language%TYPE,
        o_necessity OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default CODIFICATION
    *
    * @param i_lang                           Prefered language ID
    * @param o_codification                   External Cause
    * @param o_analysis_codification          External Cause
    * @param o_interv_codification            External Cause
    * @param o_exam_codification              External Cause
    * @param o_error                          Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_codification
    (
        i_lang                  IN language.id_language%TYPE,
        o_codification          OUT table_number,
        o_analysis_codification OUT table_number,
        o_interv_codification   OUT table_number,
        o_exam_codification     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default transfer_option
    *
    * @param i_lang                           Prefered language ID
    * @param o_transfer_option                   External Cause
    * @param o_error                          Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/07
    ********************************************************************************************/

    FUNCTION set_def_transfer_option
    (
        i_lang            IN language.id_language%TYPE,
        o_transfer_option OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default SR_INTERVENTION
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_intervention           Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_sr_intervention
    (
        i_lang            IN language.id_language%TYPE,
        o_sr_intervention OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Sr_equip
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_equip       Sr_equip
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6.0
    * @since                       2010/01/18
    ********************************************************************************************/
    FUNCTION set_def_sr_equip
    (
        i_lang     IN language.id_language%TYPE,
        o_sr_equip OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Sr_equip_kit
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_equip_kit        Sr_equip_kit
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6.0
    * @since                       2010/01/20
    ********************************************************************************************/
    FUNCTION set_def_sr_equip_kit
    (
        i_lang         IN language.id_language%TYPE,
        o_sr_equip_kit OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default set_def_SR_EQUIP_PERIOD
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_equip_period     sr_equip_period
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6.0
    * @since                       2010/01/20
    ********************************************************************************************/
    FUNCTION set_def_sr_equip_period
    (
        i_lang            IN language.id_language%TYPE,
        o_sr_equip_period OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Diets
    *
    * @param i_lang                Prefered language ID
    * @param o_diet                Diets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/28
    ********************************************************************************************/
    FUNCTION set_def_diet
    (
        i_lang        IN language.id_language%TYPE,
        o_diet_parent OUT pk_types.cursor_type,
        o_diet        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Speciality
    *
    * @param i_lang                Prefered language ID
    * @param o_speciality          Speciality
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/28
    ********************************************************************************************/
    FUNCTION set_def_speciality
    (
        i_lang       IN language.id_language%TYPE,
        o_speciality OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Comp_Axe
    *
    * @param i_lang                Prefered language ID
    * @param o_comp_axe            Comp_Axe
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/20
    ********************************************************************************************/
    FUNCTION set_def_comp_axe
    (
        i_lang     IN language.id_language%TYPE,
        o_comp_axe OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Complications
    *
    * @param i_lang                Prefered language ID
    * @param o_complications       Complications
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/20
    ********************************************************************************************/
    FUNCTION set_def_complication
    (
        i_lang          IN language.id_language%TYPE,
        o_complications OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Comp_Axe_Group
    *
    * @param i_lang                Prefered language ID
    * @param o_comp_axe_group      Comp_Axe_Group
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/31
    ********************************************************************************************/
    FUNCTION set_def_comp_axe_group
    (
        i_lang           IN language.id_language%TYPE,
        o_comp_axe_group OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Checklists
    *
    * @param i_lang                Prefered language ID
    * @param o_checklist           Checklist
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/07
    ********************************************************************************************/
    FUNCTION set_def_checklist
    (
        i_lang      IN language.id_language%TYPE,
        o_checklist OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set REHAB_AREA Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_rehab_area              Cursor of Instituition REHAB_AREA
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.3.3
    * @since                           2010/09/23
    ********************************************************************************************/
    FUNCTION set_def_rehab_area
    (
        i_lang       IN language.id_language%TYPE,
        o_rehab_area OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set REHAB_SESSION_TYPE Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_rehab_session_type      Cursor of Instituition REHAB_SESSION_TYPE
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.3.3
    * @since                           2010/09/23
    ********************************************************************************************/
    FUNCTION set_def_rehab_session_type
    (
        i_lang               IN language.id_language%TYPE,
        o_rehab_session_type OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set BODY_STRUCTURE Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_body_structure          Cursor of Instituition BODY_STRUCTURE
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.4
    * @since                           2010/10/08
    ********************************************************************************************/
    FUNCTION set_def_body_structure
    (
        i_lang           IN language.id_language%TYPE,
        o_body_structure OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set QUESTIONNAIRE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/15
    ********************************************************************************************/
    FUNCTION set_def_questionnaire
    (
        i_lang                 IN language.id_language%TYPE,
        o_id_questionnaire_cnt OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set RESPONSE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/17
    ********************************************************************************************/
    FUNCTION set_def_response
    (
        i_lang            IN language.id_language%TYPE,
        o_id_response_cnt OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Hidrics_Device
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_device
    (
        i_lang           IN language.id_language%TYPE,
        o_hidrics_device OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Hidrics_Occurs_Type
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_occurs_type
    (
        i_lang                IN language.id_language%TYPE,
        o_hidrics_occurs_type OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Graph discrete lab results for Analysis Parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_discrete_lab_results Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     0.1
    * @since                       2010/08/05
    ********************************************************************************************/
    FUNCTION set_def_discrete_lab_results
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_discrete_lab_results  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Graph discrete lab results Relation for Analysis Parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_discrete_lab_results Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/08/05
    ********************************************************************************************/
    FUNCTION set_def_discrete_lab_res_rel
    (
        i_lang                     IN language.id_language%TYPE,
        o_discrete_lab_results_rel OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Diets
    *
    * @param i_lang                Prefered language ID
    * @param o_diet                Diets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3
    * @since                       2010/12/07
    ********************************************************************************************/
    FUNCTION get_def_diet_parent
    (
        i_lang                  IN language.id_language%TYPE,
        o_id_content            OUT pk_types.cursor_type,
        o_rank                  OUT pk_types.cursor_type,
        o_diet_type             OUT pk_types.cursor_type,
        o_quantity_default      OUT pk_types.cursor_type,
        o_id_unit_measure       OUT pk_types.cursor_type,
        o_energy_quantity_value OUT pk_types.cursor_type,
        o_id_unit_mea_energy    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Diets
    *
    * @param i_lang                Prefered language ID
    * @param o_diet                Diets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3
    * @since                       2010/12/07
    ********************************************************************************************/
    FUNCTION get_def_diet
    (
        i_lang                  IN language.id_language%TYPE,
        o_id_content            OUT pk_types.cursor_type,
        o_rank                  OUT pk_types.cursor_type,
        o_diet_type             OUT pk_types.cursor_type,
        o_quantity_default      OUT pk_types.cursor_type,
        o_id_unit_measure       OUT pk_types.cursor_type,
        o_energy_quantity_value OUT pk_types.cursor_type,
        o_id_unit_mea_energy    OUT pk_types.cursor_type,
        o_id_parent             OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklist_Version set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist           Checklist ID's
    * @param o_id_checklist_version   Cursor of id_checklist_version
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/07
    ********************************************************************************************/
    FUNCTION set_def_checklist_version
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_checklist         IN checklist.id_checklist%TYPE,
        o_id_checklist_version OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklist_Clin_Serv set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_checklist_clin_serv    Cursor of Clinical Services
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/07
    ********************************************************************************************/
    FUNCTION set_def_checklist_freq
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_checklist_version_def IN checklist_version.id_checklist_version%TYPE,
        i_id_checklist_version     IN checklist_version.id_checklist_version%TYPE,
        o_id_clin_serv             OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklist_Prof_Templ set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_checklist_clin_serv    Cursor of Clinical Services
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_checklist_prof_templ
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_checklist_version_def IN checklist_version.id_checklist_version%TYPE,
        i_id_checklist_version     IN checklist_version.id_checklist_version%TYPE,
        o_id_profile_template      OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklist_Item set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_id_checklist_item      Cursor of Checklist ITEMS
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_checklist_item
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_checklist_version_def IN checklist_version.id_checklist_version%TYPE,
        i_id_checklist_version     IN checklist_version.id_checklist_version%TYPE,
        o_id_checklist_item        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklist_ITEM_Prof_Templ set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_id_profile_template    Cursor of Profile Template
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_chklst_item_prof_templ
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_checklist_item_def IN checklist_item.id_checklist_item%TYPE,
        i_id_checklist_item     IN checklist_item.id_checklist_item%TYPE,
        o_id_profile_template   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklist_ITEM_Dep set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_id_profile_template    Cursor of Profile Template
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_checklist_item_dep
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_checklist_item_def IN checklist_item.id_checklist_item%TYPE,
        o_id_checklist_item_dep OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get QUESTIONNAIRE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/15
    ********************************************************************************************/
    FUNCTION get_def_questionnaire
    (
        i_lang       IN language.id_language%TYPE,
        o_id_content OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get RESPONSE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/17
    ********************************************************************************************/
    FUNCTION get_def_response
    (
        i_lang          IN language.id_language%TYPE,
        o_id_content    OUT pk_types.cursor_type,
        o_flg_free_text OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Hidrics_Device
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION get_def_hidrics_device
    (
        i_lang          IN language.id_language%TYPE,
        o_code          OUT pk_types.cursor_type,
        o_id_content    OUT pk_types.cursor_type,
        o_flg_free_text OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Hidrics_Occurs_Type
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION get_def_hidrics_occurs_type
    (
        i_lang       IN language.id_language%TYPE,
        o_code       OUT pk_types.cursor_type,
        o_id_content OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Default Clinical Services
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/24
    ********************************************************************************************/
    FUNCTION get_def_clinical_services
    (
        i_lang                    IN language.id_language%TYPE,
        o_id_clinical_service_par OUT pk_types.cursor_type,
        o_id_content              OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set SET_APPOINTMENTS Value for a specific institution
    *
    * @param i_lang                    Prefered language ID   
    * @param i_id_institution          Institution ID
    * @param o_appointments            Cursor of APPOINTMENTS
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.4
    * @since                           2010/10/19
    ********************************************************************************************/
    FUNCTION set_appointments
    (
        i_lang                IN language.id_language%TYPE,
        i_id_clinical_service IN appointment.id_clinical_service%TYPE DEFAULT NULL,
        o_appointments        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set APPOINTMENT set of markets, versions and sotwares
    *
    * @param i_lang                  Language ID
    * @param o_id_clinical_service   Cursor of Clinical Services
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        RMGM
    * @version                       2.6.1.3
    * @since                         2011/09/25
    ********************************************************************************************/
    FUNCTION set_appointments_transl
    (
        i_lang                IN language.id_language%TYPE,
        i_id_clinical_service IN appointment.id_clinical_service%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check APPOINTMENT set of markets, versions and sotwares
    *
    * @param i_id_institution        Institution ID
    * @param o_id_sch_event          Cursor of Scheduler Events
    * @param o_id_clinical_service   Cursor of Clinical Services
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        MESS
    * @version                       2.6.0.4
    * @since                         2010/10/19
    ********************************************************************************************/
    FUNCTION get_appointments
    (
        i_lang                IN language.id_language%TYPE DEFAULT 2,
        i_id_clinical_service IN appointment.id_clinical_service%TYPE DEFAULT NULL,
        o_id_sch_event        OUT pk_types.cursor_type,
        o_id_clinical_service OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET Default Habits Characterization
    *
    * @param i_lang                Prefered language ID
    * @param o_habits_charact      Habit characterization array
    * @param o_hc_id_content       Habit characterization id_content array
    * @param o_hc_rank             Habit characterization rank array
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/04/12
    ********************************************************************************************/
    FUNCTION get_def_habit_charact
    (
        i_lang           IN language.id_language%TYPE,
        o_habits_charact OUT table_number,
        o_hc_id_content  OUT table_varchar,
        o_hc_rank        OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Default Habits
    *
    * @param i_lang                Prefered language ID
    * @param o_habits_charact      Habit Characterization ids array
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/04/12
    ********************************************************************************************/
    FUNCTION set_def_habits_charact
    (
        i_lang           IN language.id_language%TYPE,
        o_habits_charact OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default isencao
    *
    * @param i_lang                Prefered language ID
    * @param o_isencao              Isencao
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2011/05/04
    ********************************************************************************************/

    FUNCTION get_def_isencao
    (
        i_lang          IN language.id_language%TYPE,
        o_isencao       OUT table_number,
        o_is_rank       OUT table_number,
        o_is_gender     OUT table_varchar,
        o_is_agemax     OUT table_number,
        o_is_agemin     OUT table_number,
        o_is_id_content OUT table_varchar,
        o_is_status     OUT table_varchar,
        o_is_impcode    OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default isencao
    *
    * @param i_lang                Prefered language ID
    * @param o_isencao              Isencao
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2011/05/04
    ********************************************************************************************/

    FUNCTION set_def_isencao
    (
        i_lang    IN language.id_language%TYPE,
        o_isencao OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************
    * Set ENTITY_RELATION_CONTENT Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_id_relation_set         Cursor of Instituition ENTITY_RELATION_CONTENT
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.4
    * @since                           2010/10/08
    ********************************************************************************************/
    /*FUNCTION set_def_entity_rel_content
    (
        i_lang            IN language.id_language%TYPE,
        o_id_relation_set OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;*/
    /********************************************************************************************
    * Get the list of supply types
    *
    * @param i_lang                Prefered language ID
    * @param o_id_content          Cursor of default data
    * @param o_code_supply_type    Cursor of default data
    * @param o_id_parent           Cursor of default data
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     v2.6.1.5
    * @since                       2011/11/04
    ********************************************************************************************/
    FUNCTION get_supply_type
    (
        i_lang       IN language.id_language%TYPE,
        i_level      IN NUMBER,
        o_id_content OUT pk_types.cursor_type,
        o_id_parent  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supplies types.
    *
    * @param i_lang                    Prefered language ID
    * @param o_code_supply_type        Cursor of supplies types codes
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_type
    (
        i_lang        IN language.id_language%TYPE,
        o_supply_type OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of default supplies.
    *
    * @param i_lang                Prefered language ID
    * @param o_id_content          Cursor of default data
    * @param o_id_supply_type      Cursor of default data
    * @param o_flg_type            Cursor of default data
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION get_supply
    (
        i_lang           IN language.id_language%TYPE,
        o_id_content     OUT pk_types.cursor_type,
        o_id_supply_type OUT pk_types.cursor_type,
        o_flg_type       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set supplies for a specific market.
    *
    * @param i_lang                    Prefered language ID
    * @param o_supply                  Cursor of supplies
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply
    (
        i_lang   IN language.id_language%TYPE,
        o_supply OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get number of levels in child relationship in supply_type
    *
    * @param i_table_name              table being processed
    * @param o_level_array             Array of levels in configuration
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           07-NOV-2011
    ********************************************************************************************/

    FUNCTION get_table_levels
    (
        i_lang        IN language.id_language%TYPE,
        i_table_name  IN all_objects.object_name%TYPE,
        o_level_array OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Content from Result Notes Area (Default)
    *
    * @param i_lang                Prefered language ID
    * @param o_resnt               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2012/04/19
    ********************************************************************************************/
    FUNCTION get_def_result_notes
    (
        i_lang  IN language.id_language%TYPE,
        o_resnt OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Content on Result Notes Area (Exams)
    *
    * @param i_lang                Prefered language ID
    * @param o_resnt               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2012/04/19
    ********************************************************************************************/
    FUNCTION set_def_result_notes
    (
        i_lang  IN language.id_language%TYPE,
        o_resnt OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Configuration on Analysis and Sample Type Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labst               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION get_def_analysis_st
    (
        i_lang  IN language.id_language%TYPE,
        o_labst OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Configuration on Analysis and Body Structure Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labbs               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION get_def_analysis_bs
    (
        i_lang  IN language.id_language%TYPE,
        o_labbs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Configuration on Analysis and Complaint Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labcmpl             Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION get_def_analysis_complaint
    (
        i_lang    IN language.id_language%TYPE,
        o_labcmpl OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Configuration on Analysis and Sample Type Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labst               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION set_def_analysis_st
    (
        i_lang  IN language.id_language%TYPE,
        o_labst OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Configuration on Analysis and Body Structure Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labbs               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION set_def_analysis_bs
    (
        i_lang  IN language.id_language%TYPE,
        o_labbs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Configuration on Analysis and Complaint Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labcmpl             Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION set_def_analysis_complaint
    (
        i_lang    IN language.id_language%TYPE,
        o_labcmpl OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION set_sr_interv_codif
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION set_diag_codif
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION set_extcause_codif
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_flg_mcdts             array with mcdt type classification
    * @param o_flg_natures           array with mcdt nature flg nature
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/22
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION get_def_mcdt_nature
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/24
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION set_def_mcdt_nature
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_flg_mcdts             array with mcdt type classification
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/24
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION get_def_mcdt_nisencao
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/24
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION set_def_mcdt_nisencao
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Intervention relation with Body structures and laterality definition
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/07/24
    ********************************************************************************************/
    FUNCTION set_def_interv_body_structure
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get alert default event id by receiving alert event id
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_event            Alert event id
    *
    * @return                      returns alert default id event by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_def_event_id
    (
        i_lang     IN language.id_language%TYPE,
        i_id_event IN periodic_observation_param.id_event%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Get alert default periodic_observation id by unique properties of equivalent id in ALERT
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_content          Alert periodic_observation id content
    * @param i_id_clinical_service Alert periodic_observation clinical service id
    * @param i_id_software         Alert periodic_observation software id
    * @param i_id_event            Alert periodic_observation event id
    * @param i_id_institution      Alert periodic_observation institution id
    *
    * @return                      returns alert default id periodic observation by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_def_periodic_obs_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_content          IN periodic_observation_param.id_content%TYPE,
        i_id_clinical_service IN periodic_observation_param.id_clinical_service%TYPE,
        i_id_software         IN periodic_observation_param.id_software%TYPE,
        i_id_event            IN periodic_observation_param.id_event%TYPE,
        i_id_institution      IN periodic_observation_param.id_institution%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Get alert event id by receiving alert default event id
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_event            Alert DEFAULT event id
    *
    * @return                      returns alert id event by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_alert_event_id
    (
        i_lang     IN language.id_language%TYPE,
        i_id_event IN periodic_observation_param.id_event%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Get alert periodic_observation id by unique properties of equivalent id in ALERT default
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_content          Alert default periodic_observation id content
    * @param i_id_clinical_service Alert default periodic_observation clinical service id
    * @param i_id_software         Alert default periodic_observation software id
    * @param i_id_event            Alert default periodic_observation event id
    * @param i_id_institution      Alert default periodic_observation market id
    *
    * @return                      returns alert id periodic observation by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_alert_periodic_obs_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_content          IN periodic_observation_param.id_content%TYPE,
        i_id_clinical_service IN periodic_observation_param.id_clinical_service%TYPE,
        i_id_software         IN periodic_observation_param.id_software%TYPE,
        i_id_event            IN periodic_observation_param.id_event%TYPE,
        i_id_market           IN institution.id_market%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
      * Set Default calculators for Analysis parameters
    *
    * @param i_lang                   Prefered language ID
    * @param o_analysis_res_calc      Analysis calculations
    * @param o_error                  Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      LCRS
    * @version                     0.1
    * @since                       2012/02/28
    ********************************************************************************************/
    FUNCTION set_def_analysis_res_calcs
    (
        i_lang              IN language.id_language%TYPE,
        o_analysis_res_calc OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default calculators for Analysis results
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_res_par_calc Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      LCRS
    * @version                     0.1
    * @since                       2012/02/29
    ********************************************************************************************/
    FUNCTION set_def_analysis_res_par_calcs
    (
        i_lang                  IN language.id_language%TYPE,
        o_analysis_res_par_calc OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Exam Complaint association
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/16
    ********************************************************************************************/
    FUNCTION load_exam_complaint_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Interv Plan content Social Worker
    *
    * @param i_lang                Prefered language ID
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
    FUNCTION set_intervplan_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Interv Plan content Social Worker
    *
    * @param i_lang                Prefered language ID
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
    FUNCTION set_taksgoal_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Decode Task by id task type
    *
    * @param i_lang                Prefered language ID
    * @param i_task_id             Task ID
    * @param i_task_type           Task Type Id
    *
    *
    * @return                      Decoded destination task id
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/16
    ********************************************************************************************/
    FUNCTION get_dest_task_by_type
    (
        i_lang      IN language.id_language%TYPE,
        i_task_id   IN icnp_task_composition.id_task%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Pre Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.0.5
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
    * @version                       2.6.0.5
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
    /********************************************************************************************
    * Set Default translations In existing content but with new language translated
    *
    * @param i_lang                Prefered language ID
    * @param i_table               Table Name for get translations
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2011/09/25
    ********************************************************************************************/
    FUNCTION get_default_cnt_tables
    (
        i_lang   IN language.id_language%TYPE,
        o_tables OUT table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default translations In existing content but with new language translated
    *
    * @param i_lang                Prefered language ID
    * @param i_table               Table Name for get translations
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2011/09/25
    ********************************************************************************************/
    FUNCTION upd_new_translations
    (
        i_lang  IN language.id_language%TYPE,
        i_table IN user_tables.table_name%TYPE DEFAULT NULL,
        o_res   OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Content using new engine
    *
    * @param i_lang                Prefered language ID
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)
    * @param o_results             Generic cursor with execution details        
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/05
    ********************************************************************************************/
    FUNCTION set_def_content_new
    (
        i_lang          IN language.id_language%TYPE,
        i_commit_at_end IN VARCHAR2,
        o_results       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_error         VARCHAR2(2000);
    g_flg_available VARCHAR2(1);
    g_yes           VARCHAR2(1);
    g_active        VARCHAR2(1);
    g_version       VARCHAR2(30);
    g_func_name     VARCHAR2(500);

    g_array_size  NUMBER;
    g_array_size1 NUMBER;

END pk_default_content;
/
