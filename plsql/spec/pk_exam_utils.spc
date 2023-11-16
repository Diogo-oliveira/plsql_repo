/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_exam_utils IS

    FUNCTION get_exam_request
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_exam      IN table_number,
        o_msg_title OUT VARCHAR2,
        o_msg_req   OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_exam_id_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN exam.id_exam%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns the translation of exam alias if exists
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_code_exam       Exam code for translation
    * @param     i_dep_clin_serv   Dep_clin_serv id
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2008/04/21
    */

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_alias_code_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN exam_alias.code_exam_alias%TYPE;

    /*
    * Gets lab tests rank for a given lab test and institution
    *
    * @param     i_lang   Language id
    * @param     i_prof   Professional
    * @param     i_exam   Exam id
    *
    * @return    Number
    *
    * @author    Jose Castro
    * @version   2.6.0.4
    * @since     2010/20/01
    */

    FUNCTION get_exam_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam          IN exam.id_exam%TYPE,
        i_flg_type      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER;

    FUNCTION get_exam_group_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_group    IN exam_group.id_exam_group%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER;

    FUNCTION get_exam_category_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER;

    FUNCTION get_exam_questionnaire_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam          IN exam.id_exam%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN exam_questionnaire.flg_time%TYPE
    ) RETURN NUMBER;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE get_exam_init_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_exam_in_order
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        i_flg_type IN VARCHAR2
    ) RETURN CLOB;

    /*
    * Returns a flag indicating if the user has permission to have a given button available
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_area                  Functional area
    * @param     i_button                Permission button
    * @param     i_episode               Episode id
    * @param     i_exam_req              Exam order id
    * @param     i_exam_req_det          Exam detail order id
    * @param     i_flg_current_episode   Flag that indicates if the exam is in the current episode or not
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/08/19
    */

    FUNCTION get_exam_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN VARCHAR2,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_exam_req            IN exam_req.id_exam_req%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_exam_timeout
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN exam.id_exam%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN exam_req_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns the codification for a given exam
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_exam                Exam's id
    * @param     i_exam_codification   Exam's codification id
    
    * @return    number
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2008/09/09
    */

    FUNCTION get_exam_codification
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_exam_codification IN exam_codification.id_exam_codification%TYPE
    ) RETURN NUMBER;

    FUNCTION get_exam_with_codification
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN exam.id_exam%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get exam icon to show (document icon, order set icon or document + order set icon)
    *                                        
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    
    * @return    string
    *                                                                            
    * @author    Filipe Silva                            
    * @version   2.6.0.3                                   
    * @since     2010/06/10                                 
    */

    FUNCTION get_exam_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns a formated string
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_exam_field        Exam detail field
    * @param     i_exam_field_type   Exam detail field type (T - title; F - field)
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/02/23
    */

    FUNCTION get_exam_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_field      IN table_varchar,
        i_exam_field_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_exam_detail_clob
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_field      IN table_clob,
        i_exam_field_type IN VARCHAR2
    ) RETURN CLOB;

    /*
    * Returns the responses for a specific procedure by flg_time/id_questionnaire
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_exam            Exam id
    * @param     i_flg_time        Flag that indicates when the questionnaire is to be answered
    * @param     i_questionnaire   Questionnaire id    
    * @param     i_response        Response id
    
    * @return    string
    *
    * @author    Ariel Machado
    * @version   2.6.5.0.2
    * @since     2015/05/05
    */

    FUNCTION get_exam_question_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam          IN exam.id_exam%TYPE,
        i_flg_time      IN exam_questionnaire.flg_time%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN exam_questionnaire.flg_type%TYPE;

    /*
    * Returns the responses for a specific exam by flg_time/id_questionnaire
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_questionnaire   Questionnaire id    
    * @param     i_exam            Exam id
    * @param     i_flg_time        Flag that indicates WHEN the questionnaire is answered
    
    * @return    string
    *
    * @author    Teresa Coutinho
    * @version   2.6.3.11
    * @since     2014/02/27
    */

    FUNCTION get_exam_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_exam          IN exam.id_exam%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar;

    /*
    * Returns a formatted string that represents the response to a clinical question 
    * Used to handle answers of type date since the field "note" holds a serialized date
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     i_notes   Clinical questions notes
    
    * @return   string
    *
    * @author   Ariel Machado
    * @version  2.6.5.0.2
    * @since    2015/05/05
    */

    FUNCTION get_exam_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN exam_question_response.notes%TYPE
    ) RETURN exam_question_response.notes%TYPE;

    /*
    * Returns the responses for id_questionnaire within an episode
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_episode         Episode id
    * @param     i_questionnaire   Questionnaire id  
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.7.1.3
    * @since     2017/07/31
    */

    FUNCTION get_exam_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN exam_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns an external url
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam detail order id
    * @param     i_url_type       Flag that indicates the format of the information shown: I - Image; R - PDF
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/06/02
    */

    FUNCTION get_exam_result_url
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_url_type     IN VARCHAR2,
        i_count_img    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /*
    * Returns the default result status id
    *
    * @param     i_lang   Language id
    * @param     i_prof   Professional
    * @param     o_error  Error message
    
    * @return    number
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3
    * @since     2010/05/05
    */

    FUNCTION get_exam_result_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    FUNCTION get_exam_result_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_message            IN VARCHAR2,
        i_flg_report         IN VARCHAR2 DEFAULT 'N',
        i_epis_documentation IN exam_result.id_epis_documentation%TYPE
    ) RETURN CLOB;

    /*
    * Name :                        create_body_struct_rel
    * Description:                  Create or Recreate the body structure relations. 
    *                               This function should create the relations using the exams 
    *                               parametrized for the institution and using SNOMED as source. 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional structure
    * @param   i_mcs_concept        Concept ID to be used as primary node on the tree of relationships
    * @param   i_mcs_concept_parent Parent concept ID. Should be the same as the concept_id
    *
    * @param   o_error              Error information
    *
    * @return  Boolean
    *
    * @author                       Jose Castro
    * @version                      2.6.0.3
    * @since                        27-05-2010
    */

    FUNCTION create_body_struct_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mcs_concept        IN body_structure_rel.id_mcs_concept%TYPE,
        i_mcs_concept_parent IN body_structure_rel.id_mcs_concept_parent%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Name :                        recreate_body_struct_rel
    * Description:                  Recreate the body structure relations. 
    *                               Recursive function that should create the relations using the exams 
    *                               parametrized for the institution and using SNOMED as source. 
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional structure
    * @param   i_mcs_concept        Concept ID to be used as primary node on the tree of relationships
    * @param   i_mcs_concept_parent Parent concept ID
    *
    * @param   o_error              Error information
    *
    * @return  Boolean
    *
    * @author                       Jose Castro
    * @version                      2.6.0.3
    * @since                        27-05-2010
    */

    FUNCTION recreate_body_struct_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mcs_concept        IN body_structure_rel.id_mcs_concept%TYPE,
        i_mcs_concept_parent IN body_structure_rel.id_mcs_concept_parent%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Name :                        check_exam_body_structure
    * Description:                  Check if the body structure of MCS exists parametrized on exams and body structure 
    * 
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional structure
    * @param   i_mcs_concept        Concept ID to be used as primary node on the tree of relationships
    *
    * @param   o_body_structure_list  Body structure childs list
    * @param   o_error              Error information
    *
    * @return  Boolean
    *
    * @author                       Jose Castro
    * @version                      2.6.0.3
    * @since                        27-05-2010
    */

    FUNCTION check_exam_body_structure
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mcs_concept    IN body_structure_rel.id_mcs_concept%TYPE,
        o_body_structure OUT body_structure.id_body_structure%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Name :                        check_body_structure_dcs
    * Description:                  Check if the body structure of MCS exists parametrized on body structure dcs table
    * 
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional structure
    * @param   i_mcs_concept        Concept ID to be used as primary node on the tree of relationships
    *
    * @param   o_body_structure_list  Body structure childs list
    * @param   o_error              Error information
    *
    * @return  Boolean
    *
    * @author                       Jose Castro
    * @version                      2.6.0.5.1
    * @since                        30-01-2011
    */

    FUNCTION check_body_structure_dcs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mcs_concept    IN body_structure_rel.id_mcs_concept%TYPE,
        o_body_structure OUT body_structure.id_body_structure%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Name :                        del_1st_body_structure_rel
    * Description:                  Delete records that has as parent the first node,
    *                               and that have at least another parent
    * 
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional structure
    * @param   i_mcs_concept        Concept ID to be used as primary node on the tree of relationships
    *
    * @param   o_error              Error information
    *
    * @return  Boolean
    *
    * @author                       Jose Castro
    * @version                      2.6.0.5.1
    * @since                        30-01-2011
    */

    FUNCTION del_1st_body_structure_rel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_mcs_concept_parent IN body_structure_rel.id_mcs_concept_parent%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Name :                        body_structure_has_exams
    * Description:                  Check if I_MCS_CONCEPT or any child node has exams
    * 
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional structure
    * @param   i_mcs_concept        Concept ID to be used as primary node on the tree of relationships
    *
    * @return  Number               Y = True; N = False
    *
    * @author                       Jose Castro
    * @version                      2.6.0.5.1
    * @since                        11-01-2011
    */

    FUNCTION body_structure_has_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_mcs_concept IN body_structure_rel.id_mcs_concept%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_exam_concat_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN VARCHAR2,
        i_delim        IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_response_parent
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_exam          exam.id_exam%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_relationship_type sys_config.value%TYPE;
    g_concept_status    sys_config.value%TYPE;
    g_mcs_source        sys_config.value%TYPE;

END pk_exam_utils;
/
