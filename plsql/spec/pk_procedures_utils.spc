/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_procedures_utils IS

    FUNCTION create_procedure_movement
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_request
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_intervention IN table_number,
        o_msg_title    OUT VARCHAR2,
        o_msg_req      OUT VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_id_content
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_alias_code_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN intervention_alias.code_intervention_alias%TYPE;

    FUNCTION get_procedure_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_type      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER;

    FUNCTION get_procedure_question_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE get_procedure_init_parameters
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

    FUNCTION get_procedure_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN VARCHAR2,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_interv_presc_det    IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan   IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_field      IN table_varchar,
        i_interv_field_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_detail_clob
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_field      IN table_clob,
        i_interv_field_type IN VARCHAR2
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
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/30
    */

    FUNCTION get_procedure_question_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN interv_questionnaire.flg_type%TYPE;

    /*
    * Returns the responses for a specific procedure by flg_time/id_questionnaire
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_questionnaire   Questionnaire id    
    * @param     i_intervention    Procedure id
    * @param     i_flg_time        Flag that indicates WHEN the questionnaire is answered
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/30
    */

    FUNCTION get_procedure_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE
    ) RETURN table_varchar;

    /*
    * Returns a formatted string that represents the response to a clinical question 
    * Used to handle answers of type date since the field "note" holds a serialized date
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     i_notes   Clinical questions notes
    
    * @return    string
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/30
    */

    FUNCTION get_procedure_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN interv_question_response.notes%TYPE
    ) RETURN interv_question_response.notes%TYPE;

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

    FUNCTION get_procedure_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN interv_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_modifiers
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns a flag if a procedure has timeout template
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_intervention   Procedure id
    
    * @return    true or false on success or error
    *
    * @author    Joao Martins
    * @version   2.5.0.6
    * @since     2009/09/28
    */

    FUNCTION get_procedure_timeout
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN interv_presc_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_supplies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies_list IN interv_presc_det_hist.id_supplies_list%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns the codification for a given procedure
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_intervention          Procedure's id
    * @param     i_interv_codification   Procedure's codification id
    
    * @return    number
    *
    * @author    Ana Matos
    * @version   2.6
    * @since     2015/10/09
    */

    FUNCTION get_procedure_codification
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_interv_codification IN interv_codification.id_interv_codification%TYPE
    ) RETURN NUMBER;

    FUNCTION get_procedure_with_codification
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_intervention        IN intervention.id_intervention%TYPE,
        i_interv_codification IN interv_codification.id_interv_codification%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_code
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_intervention        IN intervention.id_intervention%TYPE,
        i_codification        IN codification.id_codification%TYPE,
        i_interv_codification IN interv_codification.id_interv_codification%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get procedure icon to show (document icon, order set icon or document + order set icon)
    *                                        
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_interv_presc_det    Procedure detail order id
    * @param     i_flg_procedure_doc   Flag that indicates if there is a document or not (Y/N)
    * @param     i_flg_procedure_tde   Flag that indicates if the exam was created by order sets functionality (O)
    
    * @return    string
    *                                                                            
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/07/11                                 
    */

    FUNCTION get_procedure_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_procedure_doc IN VARCHAR2,
        i_flg_procedure_tde IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_concat_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN VARCHAR2,
        i_delim            IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_flg_favorite
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_interv_favorite
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_interv_hash
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE
    ) RETURN NUMBER;

    FUNCTION manage_most_frequent
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION manage_most_frequent_dept
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        i_dept            IN clinical_service.id_clinical_service%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_intervention  intervention.id_intervention%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

END pk_procedures_utils;
/
