/*-- Last Change Revision: $Rev: 2028462 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_backoffice_default IS

    -- Author  : MAURO.SOUSA
    -- Created : 29-06-2010 15:57:45
    -- Purpose : To be Executed by Operations Team on Parametrizações default

    /*
    * PROCESS ERRORS
    */

    PROCEDURE process_error
    (
        i_pckg  IN alert_default.logs.package%TYPE,
        i_funct IN alert_default.logs.funtion%TYPE
    );

    /********************************************************************************************
    * Set EXAMS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/25
    ********************************************************************************************/
    FUNCTION set_iso_exams
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_exam_cat          OUT table_number,
        o_exams             OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set INTERVENTIONS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/25
    ********************************************************************************************/
    FUNCTION set_iso_interventions
    (
        i_lang                  IN language.id_language%TYPE,
        i_content_universe      IN VARCHAR2 DEFAULT 'N',
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_software              IN table_number,
        i_pesquisaveis          IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1     IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all     IN VARCHAR2 DEFAULT 'N',
        o_physiatry_area        OUT table_number,
        o_interv_physiatry_area OUT table_number,
        o_interv                OUT table_number,
        o_interv_cat            OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ANALYSIS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_content_universe       IN VARCHAR2 DEFAULT 'N',
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_software               IN table_number,
        i_pesquisaveis           IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1      IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all      IN VARCHAR2 DEFAULT 'N',
        o_analysis_parameters    OUT table_number,
        o_sample_types           OUT table_number,
        o_sample_rec             OUT table_number,
        o_exam_cat               OUT table_number,
        o_analysis               OUT table_number,
        o_analysis_res_calcs     OUT table_number,
        o_analysis_res_par_calcs OUT table_number,
        o_analysis_loinc         OUT table_number,
        o_analysis_desc          OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set CLINICAL_SERVICE Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_clinical_service
    (
        i_lang              IN language.id_language%TYPE,
        o_clinical_services OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set HEALTH_PLAN Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_health_plan
    (
        i_lang                 IN language.id_language%TYPE,
        o_health_plan_entities OUT table_number,
        o_health_plans         OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set HABITS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_habits
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_habits           OUT table_number,
        o_habits_char      OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set SUPPLIES Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_supplies
    (
        i_lang     IN language.id_language%TYPE,
        o_supplies OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set PROTOCOLS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_protocols
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set GUIDELINES Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_guidelines
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set ORDER_SETS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_order_sets
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Checklists Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/08
    ********************************************************************************************/
    FUNCTION set_iso_checklist
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_checklist        OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set External Medication Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/26
    ********************************************************************************************/
    FUNCTION set_iso_ext_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Hidrics Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/13
    ********************************************************************************************/
    FUNCTION set_iso_hidrics
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_hidrics          OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set new MFR Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.3.3
    * @since                       2010/09/27
    ********************************************************************************************/
    FUNCTION set_iso_rehabilitation
    (
        i_lang               IN language.id_language%TYPE,
        i_content_universe   IN VARCHAR2 DEFAULT 'N',
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        i_pesquisaveis       IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1  IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all  IN VARCHAR2 DEFAULT 'N',
        o_rehab_area         OUT table_number,
        o_rehab_session_type OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set new BODY_STRUCTURE Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/10/08
    ********************************************************************************************/
    FUNCTION set_iso_body_structure
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_body_structure    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************
    * Merges a record into clinical_service table         *
    *                                                     *
    * @param l_id_clinical_service_par    parent_id       *
    * @param l_cs_id_content              id_content      *
    *                                                     *
    ******************************************************/
    PROCEDURE insert_into_clinical_service
    (
        l_id_clinical_service_par IN clinical_service.id_clinical_service_parent%TYPE DEFAULT NULL,
        l_cs_id_content           IN clinical_service.id_content%TYPE,
        i_lang                    IN language.id_language%TYPE DEFAULT NULL,
        i_descr                   IN translation.desc_lang_1%TYPE DEFAULT NULL,
        only_this                 IN VARCHAR2 DEFAULT 'Y'
    );
    /******************************************************
    * Merges a record into appointment table              *
    *                                                     *
    * @param l_id_clinical_service  clinical_service_id   *
    * @param l_id_sch_event         sch_event_id          *
    *                                                     *
    ******************************************************/
    PROCEDURE insert_into_appointment
    (
        l_id_clinical_service IN appointment.id_clinical_service%TYPE,
        l_id_sch_event        IN appointment.id_sch_event%TYPE
    );
    /********************************************************************************************
    * Set Default Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION create_def_institutions
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_default_param    IN VARCHAR2 DEFAULT 'N',
        i_mypreferences    IN VARCHAR2 DEFAULT 'N',
        i_version          IN table_varchar,
        i_software         IN table_number,
        o_institution      OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Software_Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION get_software_institution
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution_def IN software_institution.id_institution%TYPE,
        i_id_software        IN software_institution.id_software%TYPE,
        o_sw_instit          OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Fisical Structure Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID
    * @param i_lang                Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/10/25
    ********************************************************************************************/
    FUNCTION get_fisical_structure
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_institution_def IN institution.id_institution%TYPE,
        o_id_floors          OUT table_number,
        o_id_building        OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Backoffice Administrator Users Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID
    * @param i_lang                Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION create_backoffice_adm
    (
        i_lang   IN language.id_language%TYPE,
        i_market IN institution.id_market%TYPE,
        i_instit IN institution.id_institution%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Software_Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION get_dept
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN software_institution.id_institution%TYPE,
        i_id_software    IN software_institution.id_software%TYPE,
        o_id_dept        OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Software_Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION get_department
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software_institution.id_software%TYPE,
        i_id_dept_def    IN department.id_dept%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        o_id_department  OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default DEP_CLIN_SERVS Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang              IN language.id_language%TYPE,
        i_id_department_def IN department.id_department%TYPE,
        i_id_department     IN department.id_department%TYPE,
        o_id_dcs            OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Rooms by DEPARTMENT Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/11
    ********************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang              IN language.id_language%TYPE,
        i_id_department_def IN department.id_department%TYPE,
        i_id_department     IN department.id_department%TYPE,
        i_floor_dept        IN floors_department.id_floors_department%TYPE,
        o_id_room           OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Default Beds by ROOM Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/11
    ********************************************************************************************/
    FUNCTION get_beds
    (
        i_lang          IN language.id_language%TYPE,
        i_id_room_def   IN room.id_room%TYPE,
        i_id_room       IN room.id_room%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_id_bed        OUT table_number,
        o_error         OUT t_error_out
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
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/11
    ********************************************************************************************/
    FUNCTION set_default_content
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Analysis_Room, Exam_Room and Epis_Type_Room Pos-Default Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/17
    ********************************************************************************************/
    FUNCTION set_rooms_pos_default
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_institution_def     IN institution.id_institution%TYPE,
        o_id_analysis_room       OUT table_number,
        o_id_exam_room           OUT table_number,
        o_id_epis_type_room      OUT table_number,
        o_id_analysis_quest_room OUT table_number,
        o_id_room_questionnaire  OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************
    *  DELETE DEFAULT Structure in ALERT SIDE             *
    *                                                     *
    * @param i_id_institution       Alert Institution ID  *
    *                                                     *
    ******************************************************/
    PROCEDURE delete_1def_structure
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_del_content    IN VARCHAR2 DEFAULT 'N',
        o_error          OUT t_error_out
    );
    /******************************************************
    *  DELETE DEFAULT Structure in ALERT SIDE             *
    *                                                     *
    * @param i_id_institution       Alert Institution ID  *
    *                                                     *
    ******************************************************/
    PROCEDURE delete_all_def_structure(o_error OUT t_error_out);

    /******************************************************
    * Update Queue of Lucene Indexes used by Translations *
    *                                                     *
    ******************************************************/
    PROCEDURE luceneindex_sync;
    /********************************************************************************************
    * Set Questionnaire/Response Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/12/15
    ********************************************************************************************/
    FUNCTION set_iso_question_response
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_id_questionnaire OUT pk_types.cursor_type,
        o_id_response      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * SET_ISO_ICNP
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.1 HF
    * @since                       2010/12/21
    ********************************************************************************************/
    FUNCTION set_iso_icnp
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);
    /********************************************************************************************
    * Synch Lb_translation with translation info
    *
    * @param i_lang                Prefered language ID
    * @param i_code_translation    Code to process by default 'ALL' will be processed
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.1
    * @since                       2011/05/25
    ********************************************************************************************/
    FUNCTION synch_ncd_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_code_translation IN translation.code_translation%TYPE DEFAULT 'ALL',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set isolated Content and Parametrization 
    *
    * @param i_lang                Prefered language ID
    * @param i_content_universe    Load Content Y/N
    * @param i_market              market to configure
    * @param i_version             Version of Content to configure
    * @param i_id_institution      Institution to configure
    * @param i_software            Software list to configure
    * @param i_pesquisaveis        Institution Parametrization Y/N
    * @param o_supply              cursor with supply inserted
    * @param o_error               cursor with supply configured
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_iso_supply
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_supply           OUT pk_types.cursor_type,
        o_inst_supply      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set isolated Content and Configurations 
    *
    * @param i_lang                Prefered language ID
    * @param i_content_universe    Load Content Y/N
    * @param i_market              market to configure
    * @param i_version             Version of Content to configure
    * @param i_id_institution      Institution to configure
    * @param i_software            Software list to configure
    * @param i_pesquisaveis        Institution Parametrization Y/N
    * @param o_resnt               cursor with result notes inserted
    * @param o_inst_resnt          cursor with result notes instit configured
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.8
    * @since                           18-APR-2012
    ********************************************************************************************/
    FUNCTION set_iso_result_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_resnt            OUT pk_types.cursor_type,
        o_inst_resnt       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * SET_ISO_PERIODIC_OBSERVATIONS
    *
    * @param i_lang                Prefered language ID
    * @param i_content_universe    Load Content Y/N
    * @param i_market              market to configure
    * @param i_version             Version of Content to configure
    * @param i_id_institution      Institution to configure
    * @param i_software            Software list to configure
    * @param i_pesquisaveis        Institution Parametrization Y/N
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8.X HF
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION set_iso_periodic_obs
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set EXAMS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/25
    ********************************************************************************************/
    FUNCTION set_iso_social_worker_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Institutions
    *
    * @param i_lang                Prefered language ID
    * @param o_institutions        Institutions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION set_def_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_flg_type     IN institution.flg_type%TYPE,
        i_market       IN institution.id_market%TYPE,
        o_institutions OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Institutions_Group
    *
    * @param i_lang                Prefered language ID
    * @param o_institutions_grp    Institutions Group
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION set_def_institution_group
    (
        i_lang             IN language.id_language%TYPE,
        o_institutions_grp OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    -- collect all configured and valid dep_clin_serv, clinical_service and software list to proccess
    FUNCTION get_valid_dcs_all
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_dcs            OUT table_number,
        o_def_cs         OUT table_number,
        o_cs             OUT table_number,
        o_software_dcs   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_valid_dcs_for_softwares
    (
        i_lang        IN VARCHAR2,
        i_institution IN NUMBER,
        i_soft        IN table_number,
        i_dcs         IN table_number,
        o_dcs         OUT table_number
    );
    /********************************************************************************************
    * Returns true or false and list of valid DCS expanded by software
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_software           Software identifier list
    * @param i_dcs                   Dep_clin_serv identifier list
    * @param i_cs                    Clinical_service identifier list
    * @param o_dcs                   Dep_clin_serv identifier list
    * @param o_def_cs                Default Clinical_service identifier list
    * @param o_software_dcs          Software identifier list
    * @param o_cs                    Clinical_service identifier list
    * @param o_error                 Error ID
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2013/03/06
    * @version                       2.6.3.x
    ********************************************************************************************/
    FUNCTION get_valid_dcs_from_input
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        i_dcs            IN table_number,
        i_cs             IN table_number,
        o_dcs            OUT table_number,
        o_def_cs         OUT table_number,
        o_cs             OUT table_number,
        o_software_dcs   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns true or false and list of valid cs/dcs combinations taken from dcs given.
    * Results are expanded expanded by software
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_software           Software identifier list
    * @param i_dcs                   Dep_clin_serv identifier list
    * @param o_dcs                   Dep_clin_serv identifier list
    * @param o_def_cs                Default Clinical_service identifier list
    * @param o_software_dcs          Software identifier list
    * @param o_cs                    Clinical_service identifier list
    * @param o_error                 Error ID
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        LCRS
    * @since                         2013/11/28
    * @version                       2.6.3.x
    ********************************************************************************************/
    FUNCTION get_valid_cs_from_dcs_input
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        i_dcs            IN table_number,
        o_dcs            OUT table_number,
        o_def_cs         OUT table_number,
        o_cs             OUT table_number,
        o_software_dcs   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    -- get alert_default clinical_service ids based on id_content
    FUNCTION get_default_cs_id
    (
        i_lang    IN language.id_language%TYPE,
        i_cs_list IN table_number,
        o_cs_list OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get list of complaint relations
    *
    * @param i_lang                Language id
    * @param i_id_complaint        Complaint initial id
    * @param o_id_comp             list of complaint upper leaf ids
    * @param o_error               error output
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.2
    * @since                       2012/07/15
    ********************************************************************************************/
    FUNCTION check_complaint
    (
        i_lang         IN language.id_language%TYPE,
        i_id_complaint IN complaint.id_complaint%TYPE,
        o_id_comp      OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get list of software modules by area and institution 
    *
    * @param i_lang                Language id
    * @param i_id_tool_area         output string
    * @param i_id_institution      institution id
    * @param o_id_sw               list of final softwares to configure by area
    * @param o_error               error output
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.2
    * @since                       2012/07/15
    ********************************************************************************************/
    /*  FUNCTION check_softwares
    (
        i_lang           IN language.id_language%TYPE,
        i_id_tool_area   IN tool_area.id_tool_area%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_id_sw          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;*/
    /********************************************************************************************
    * get all valid software modules
    *
    * @param i_lang                 Language id
    * @param i_institution          Institution id
    * @param i_param_sw_list        Parameter Software id list
    * @param o_sw_list              Output valid software list
    * @param o_error                Error output
    *
    * @author                       RMGM
    * @version                      2.6.2
    * @since                        2012/07/30
    ********************************************************************************************/
    FUNCTION check_software_instit
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_param_sw_list IN table_number,
        o_sw_list       OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get list of Profiles to configure by category, software, market and institution filtering
    *
    * @param i_lang                Language id
    * @param i_id_category         Professional category id
    * @param i_id_market           Configuration Market id
    * @param i_id_software         Software module id
    * @param o_id_cat              list of profile templata ids to configure
    * @param o_error               error output
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.2
    * @since                       2012/07/30
    ********************************************************************************************/
    FUNCTION check_category
    (
        i_lang        IN language.id_language%TYPE,
        i_id_category IN category.id_category%TYPE,
        i_id_market   IN market.id_market%TYPE,
        i_id_software IN software.id_software%TYPE,
        o_id_cat      OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set default labtests migration base table
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.3.1
    * @since                       2012/11/29
    ********************************************************************************************/
    FUNCTION load_labtest_migration_base
    (
        i_lang  IN language.id_language%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /* procedure that execute maintenance apis (xmap, EA rebuild, orders check)*/
    PROCEDURE post_default_maintenance
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_softw_list            IN table_number,
        i_flg_exam_bs_xmap      IN BOOLEAN DEFAULT FALSE,
        i_flg_orders_review     IN BOOLEAN DEFAULT FALSE,
        i_flgintakeoutp_ref     IN BOOLEAN DEFAULT FALSE,
        i_flg_diagnosis_rebuild IN BOOLEAN DEFAULT FALSE
    );
    /* 
    Method that Register and schedulle job to execute maintenance post default
    */
    FUNCTION post_def_job
    (
        i_lang  IN language.id_language%TYPE,
        l_sql   IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set complete default configuration (content, search, frequent and translations) using new engine
    *
    * @param i_lang                        Prefered language ID
    * @param i_id_market               Market ID
    * @param i_version                    ALERT version
    * @param i_software                  Software ID's    
    * @param i_id_content               ID's Content
    * @param i_id_clinical_service   Clinical Service ID
    * @param i_id_clinical_service   Clinical Service ID
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)
    * @param o_error                      Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                 RMGM
    * @version                                0.1
    * @since                                   2013/05/17
    */

    FUNCTION set_full_default_config
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_software         IN table_number,
        i_id_content          IN table_varchar,
        i_id_clinical_service IN table_number,
        i_id_dep_clin_serv    IN table_number,
        i_flg_dcs_all         IN VARCHAR2 DEFAULT 'Y',
        i_commit_at_end       IN VARCHAR2,
        o_results             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set complete default configuration BY AREA (content, search, frequent and translations) using new engine
    *
    * @param i_lang                         Prefered language ID
    * @param i_id_market                Market ID
    * @param i_version                     ALERT version
    * @param i_software                   Software ID's
    * @param i_software                   ID's Content
    * @param i_id_clinical_service    Clinical Service ID
    * @param i_id_clinical_service    Clinical Service ID
    * @param i_commit_at_end         Commit automatic in transaction (Y, N)
    * @param o_error                        Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/27
    */

    FUNCTION set_iso_area
    (
        i_lang              IN language.id_language%TYPE,
        i_area_to_config    IN VARCHAR2,
        i_area_dependecies  IN VARCHAR2 DEFAULT 'N',
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_search_cfg        IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        i_commit_at_end     IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_id_content        IN table_varchar,
        i_id_dep_clin_serv  IN table_number,
        o_results           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_flg_available VARCHAR2(1);
    g_yes           VARCHAR2(1);
    g_active        VARCHAR2(1);
    g_version       VARCHAR2(30);

    g_array_size  NUMBER;
    g_array_size1 NUMBER;

END pk_api_backoffice_default;
/
