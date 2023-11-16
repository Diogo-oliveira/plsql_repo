/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_utils IS

    FUNCTION create_lab_test_req_par
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_analysis_req_par OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_request
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_analysis IN table_number,
        o_msg_req  OUT VARCHAR2,
        o_button   OUT VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_param_id_content
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN VARCHAR2;

    /*
    * Return the translation of lab test alias if exists
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_flg_type           Flag that indicates the type of alias: 
                                      A - Lab Tests; G - Panel; P - Parameter; S - Sample
    * @param     i_code_translation   Code for translation
    * @param     i_dep_clin_serv      Dep_clin_serv id
    
    * @return    string
    *
    * @author    Rui Spratley
    * @version   2.4.0
    * @since     2007/08/06
    */

    FUNCTION get_alias_translation
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_flg_type                  IN VARCHAR2,
        i_analysis_code_translation IN translation.code_translation%TYPE,
        i_sample_code_translation   IN translation.code_translation%TYPE,
        i_dep_clin_serv             IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_alias_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2,
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_alias_code_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2,
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN translation.code_translation%TYPE;

    /*
    * Gets lab tests rank for a given lab test and institution.
    *
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_analysis   Lab test id
    *
    * @return    Number
    *
    * @author    Jose Castro
    * @version   2.6.0.4
    * @since     2010/10/01
    */

    FUNCTION get_lab_test_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER;

    /*
    * Gets parameter rank
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_analysis             Lab test id
    * @param     i_sample_type          Sample type id  
    * @param     i_analysis_parameter   Parameter id
    *
    * @return    Number
    *
    * @author    Jose Castro
    * @version   2.6.0.4
    * @since     2010/10/01
    */

    FUNCTION get_lab_test_parameter_rank
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER;

    /*
    * Gets sample type rank
    *
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_sample_type   Sample type id
    *
    * @return    Number
    *
    * @author    Ana Matos
    * @version   2.6.3.1
    * @since     2013/01/03
    */

    FUNCTION get_lab_test_sample_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_group_rank
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_category_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_question_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN analysis_questionnaire.flg_time%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_unit_measure
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_reference_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_flg_type           IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_parameter_type
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_parameter_color
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_parameter_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_cat_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_cat IN exam_cat.id_exam_cat%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE get_lab_test_init_parameters
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

    FUNCTION get_lab_test_in_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_flg_type     IN VARCHAR2
    ) RETURN CLOB;

    FUNCTION get_harvest_in_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE
    ) RETURN CLOB;

    /*
    * Returns a flag indicating if the user has permission to have a given button available
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_area                  Functional area
    * @param     i_button                Permission button
    * @param     i_episode               Episode id
    * @param     i_analysis_req          Lab tests' order id 
    * @param     i_analysis_req_det      Lab tests' order detail id 
    * @param     i_flg_current_episode   Flag that indicates if the exam is in the current episode or not
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/03/02
    */

    FUNCTION get_lab_test_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN VARCHAR2,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_analysis_req        IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det    IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_access_permission
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN analysis.id_analysis%TYPE,
        i_flg_type IN group_access.flg_type%TYPE DEFAULT pk_lab_tests_constant.g_infectious_diseases_orders
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN analysis_req_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns the codification for a given lab test
    *
    * @param     i_lang                    Language id
    * @param     i_prof                    Professional
    * @param     i_analysis                Lab test id
    * @param     i_sample_type             Sample type id  
    * @param     i_analysis_codification   Lab test's codification id
    
    * @return    number
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2008/09/09
    */

    FUNCTION get_lab_test_codification
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_analysis_codification IN analysis_codification.id_analysis_codification%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_with_codification
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_icon
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns a formated string
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_analysis_req   Lab tests' order id
    * @param     i_harvest        Harvest id
    * @param     i_code           EPL/ZPL code
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.7.3.1
    * @since     2018/03/29
    */

    FUNCTION get_lab_test_barcode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        i_code         IN VARCHAR2
    ) RETURN VARCHAR2;

    /*
    * Returns a formated string
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_analysis_field        Lab test detail field
    * @param     i_analysis_field_type   Lab test detail field type (T - title; F - field)
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/02/23
    */

    FUNCTION get_lab_test_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_field      IN table_varchar,
        i_analysis_field_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_detail_clob
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_field      IN table_clob,
        i_analysis_field_type IN VARCHAR2
    ) RETURN CLOB;

    /*
    * Returns the responses for a specific procedure by flg_time/id_questionnaire
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_analysis        Lab test id
    * @param     i_sample_type     Sample type id
    * @param     i_flg_time        Flag that indicates when the questionnaire is to be answered
    * @param     i_questionnaire   Questionnaire id    
    * @param     i_response        Response id
    
    * @return    string
    *
    * @author    Ariel Machado
    * @version   2.6.5.0.2
    * @since     2015/05/05
    */

    FUNCTION get_lab_test_question_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN analysis_questionnaire.flg_time%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN analysis_questionnaire.flg_type%TYPE;

    /*
    * Returns the responses for a specific lab test by flg_time/id_questionnaire
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_questionnaire   Questionnaire id    
    * @param     i_analysis        Lab test id
    * @param     i_sample_type     Sample Type  Id   
    * @param     i_flg_time        Flag that indicates WHEN the questionnaire is answered
    
    * @return    string
    *
    * @author    Teresa Coutinho
    * @version   2.6.3.11
    * @since     2014/02/27
    */

    FUNCTION get_lab_test_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_analysis      IN analysis.id_analysis%TYPE,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
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

    FUNCTION get_lab_test_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN analysis_question_response.notes%TYPE
    ) RETURN analysis_question_response.notes%TYPE;

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

    FUNCTION get_lab_test_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN analysis_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_harvest_instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_harvest_professional
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN NUMBER;

    FUNCTION get_harvest_institution
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN NUMBER;

    FUNCTION get_harvest_unit_measure
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sample_recipient IN sample_recipient.id_sample_recipient%TYPE
    ) RETURN NUMBER;

    FUNCTION get_harvest_alias_translation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_doc_external
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE
    ) RETURN NUMBER;

    FUNCTION get_lab_test_result_url
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_url_type         IN VARCHAR2,
        o_url              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result_url
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_url_type         IN VARCHAR2
    ) RETURN VARCHAR2;

    /*
    * Returns the default result status id
    *
    * @param     i_lang   Language id
    * @param     i_prof   Professional
    
    * @return    Number
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.3
    * @since     2010/05/05
    */

    FUNCTION get_lab_test_result_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    /*
    * Returns the number of parameters for complex lab tests
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id 
    
    * @return    String
    *
    * @author    Teresa Coutinho
    * @version   2.5.1.5
    * @since     2011/04/14
    */

    FUNCTION get_lab_test_result_parameters
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_calculated_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_analysis_calculator IN analysis_res_calculator.id_analysis_res_calc%TYPE,
        i_analysis_result_par IN table_number,
        i_result              IN table_number
    ) RETURN VARCHAR2;

    /*
    * Returns the last unit used for a specific lab test register 
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_patient          Patient id
    * @param     i_lab_test         Lab test id
    * @param     i_lab_test_param   Lab test parameter id
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author   Pedro Maia
    * @version  2.6.0.3
    * @since    2010/06/18 
    */

    FUNCTION get_lab_test_initial_convert
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_last_unit_mea      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_concat_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN VARCHAR2,
        i_delim            IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_result_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    PROCEDURE set_lab_test_migration;

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
        i_analysis      analysis.id_analysis%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

END pk_lab_tests_utils;
/
