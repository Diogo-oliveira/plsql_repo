/*-- Last Change Revision: $Rev: 2028937 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_risk_factor IS

    TYPE t_rec_doc_risk IS RECORD(
        id_epis_documentation epis_documentation.id_epis_documentation%TYPE,
        id_score              risk_factor.id_risk_factor%TYPE,
        id_doc_template       doc_template.id_doc_template%TYPE,
        desc_class            VARCHAR2(4000),
        soma                  NUMBER(24),
        id_professional       professional.id_professional%TYPE,
        nick_name             professional.nick_name%TYPE,
        date_target           VARCHAR2(4000),
        hour_target           VARCHAR2(4000),
        dt_last_update        VARCHAR2(4000),
        dt_last_update_tstz   epis_documentation.dt_last_update_tstz%TYPE,
        flg_status            epis_documentation.flg_status%TYPE);

    TYPE t_coll_doc_risk IS TABLE OF t_rec_doc_risk;

    FUNCTION get_risk_factor_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_risk_factor_summary_page
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_filter_days       IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns documentation data for a given patient used by reports
    *
    * @param i_lang                   Language ID
    * @param i_prof_id                Professional ID
    * @param i_prof_inst              Institution ID
    * @param i_prof_sw                Software ID
    * @param i_prof                   Object ()
    * @param i_episode                Episode ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    *                                     
    * @param o_error                  Error message
    *                   
    * @return                         true or false on success or error
    *
    * @author                    Ariel Machado (based on get_risk_factor_summary_page)
    * @version                   1.0  (2.4.3)   
    * @since                     2008/08/27
    *
    ********************************************************************************************/
    FUNCTION get_risk_factor_summ_page_rep
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_filter_days       IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_elements_score
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        o_score        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_risk_factor_score
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_doc_element IN table_number,
        o_total_score OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_risk_factor
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_episode               IN epis_risk_factor.id_episode%TYPE,
        i_doc_area              IN summary_page_section.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_total_score           IN epis_risk_factor.total_score%TYPE,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prev_risk_factor_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_doc_area   IN epis_documentation.id_doc_area%TYPE,
        i_flg_type   IN VARCHAR2,
        o_prev_score OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_risk_factor_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_total_score(i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * Get the risk total score of a specific documentation area 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_patient             patient ID
    * @param   i_doc_area            doc area ID
    *
    * @RETURN  Total score
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   21-11-2011
    **********************************************************************************************/
    FUNCTION get_pat_total_score
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN NUMBER;

    FUNCTION get_risk_factor_help
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_title    OUT pk_types.cursor_type,
        o_help     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * return list of scales for a given epis_documentation           
    *                                                                         
    * @param i_lang                   The language ID                         
    * @param i_prof                   Object (professional ID, institution ID,software ID)   
    * @param i_patient                patient ID                         
    * @param i_epis_documentation     array with ID_EPIS_DOCUMENTION                        
    *                                                                         
    * @return                         return list of scales epis_documentation       
    *                                                                         
    * @author                         Elisabete Bugalho                              
    * @version                        2.6.2.1                                     
    * @since                          2012/03/26                              
    **************************************************************************/
    FUNCTION tf_risk_total_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN table_number
    ) RETURN t_coll_doc_risk
        PIPELINED;
    ------------------------------------------
    /********************************************************************************************
    * Cancel documentation risk_factor episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Indica se deve mostrar a confirmação de alteração
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - Não, R - lido, C - confirmado                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jorge Silva
    * @version                        1.0   
    * @since                          2013/04/11
    *  
    **********************************************************************************************/

    FUNCTION cancel_epis_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_notes       IN VARCHAR2,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    
    FUNCTION get_epis_risk_factors
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_RISK_FACTORS  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
        
    g_error        VARCHAR2(4000); -- Localização do erro
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_sysdate_char VARCHAR2(50);

    g_active    CONSTANT VARCHAR2(1) := 'A';
    g_available CONSTANT VARCHAR2(1) := 'Y';
    g_yes       CONSTANT VARCHAR2(1) := 'Y';
    g_no        CONSTANT VARCHAR2(1) := 'N';

    g_flg_all_eval     CONSTANT VARCHAR2(2) := 'A';
    g_flg_last_eval    CONSTANT VARCHAR2(2) := 'L';
    g_flg_my_eval      CONSTANT VARCHAR2(2) := 'M';
    g_flg_my_last_eval CONSTANT VARCHAR2(2) := 'ML';
    --
    g_touch_option CONSTANT VARCHAR2(1) := 'D';
    g_free_text    CONSTANT VARCHAR2(1) := 'N';

    g_exception EXCEPTION;

END;
/
