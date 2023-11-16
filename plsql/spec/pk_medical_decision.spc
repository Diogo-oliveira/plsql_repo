/*-- Last Change Revision: $Rev: 2028793 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_medical_decision AS
    /********************************************************************************************
    * Get the last doctor note associated with an episode.
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_prof_cat               Professional category
    * @param o_interv_notes           Cursor containing all interval notes for the episode
    * @param o_error                  Error message
    *                        
    * @return                         TRUE if successfull, FALSE otherwise
    * 
    * @author                         Filipe Silva (based on GET_EPIS_INTERVAL_NOTES by José Brito)
    * @version                        1.0
    * @since                          200/08/25
    **********************************************************************************************/
    FUNCTION get_epis_last_doctor_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_prof_cat     IN category.flg_type%TYPE,
        o_doctor_notes OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get the last nursing note associated with an episode.
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_prof_cat               Professional category
    * @param o_interv_notes           Cursor containing all interval notes for the episode
    * @param o_error                  Error message
    *                        
    * @return                         TRUE if successfull, FALSE otherwise
    * 
    * @author                         Filipe Silva (based on GET_EPIS_INTERVAL_NOTES by José Brito)
    * @version                        1.0
    * @since                          200/08/25
    **********************************************************************************************/
    FUNCTION get_epis_last_nurse_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        o_nursing_notes OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar as revisões associadas ás análises e exames de um episódio   
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_request_review         request review
    * @param i_flg_type               Tipo de revisão sobre: A - Analysis ; E - Exam 
    * @param i_desc_test_review       Notas de revisão        
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_tests_review
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_request_review   IN tests_review.id_request%TYPE,
        i_flg_type         IN tests_review.flg_type%TYPE,
        i_desc_test_review IN tests_review.desc_tests_review%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter todas as revisões de exames e/ou análises de um episódio
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param o_tests_review           array with all revisões de exames e/ou análises de um episódio        
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_tests_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        o_tests_review OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * This function returns a full result description for the exam_result passed in the i_epis_context var
    * 
    * @param i_lang language id
    * @param i_prof user data
    * @param i_episode episode id
    * @param i_epis_context exam_result id
    *
    * @return a string with the full result
    * 
    * @author                         João Eiras
    * @version                        1.0
    * @since                          2007/01/31
    */
    FUNCTION get_exam_result_template_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_context IN epis_documentation.id_epis_context%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
    * Obter as revisões e resultados de um exame e/ou análise de um episódio 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_request_review         request review    
    * @param i_flg_type               Tipo de revisão sobre: A - Analysis ;E - Exam     
    * @param o_tests_result           Listar os resultados de análises e exames do episódio         
    * @param o_tests_review           Listar as revisões de exames e análises de um episódio    
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/

    FUNCTION get_tests_review_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_request_review IN tests_review.id_request%TYPE,
        i_flg_type       IN tests_review.flg_type%TYPE,
        o_tests_result   OUT pk_types.cursor_type,
        o_tests_review   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter TODOS os resultados de um exame e/ou análise de um episódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               Tipo de revisão sobre: A - Analysis ;E - Exam     
    * @param i_request_det            request detail id   
    * @param o_tests_result           Listar os resultados dos exames e análises de um episódio  
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_tests_result
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_flg_type     IN tests_review.flg_type%TYPE,
        i_request_det  IN tests_review.id_request%TYPE,
        o_tests_result OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar as notas de tratamento para a medicação e/ou procedimento de um episódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_treatment              treatment id
    * @param i_flg_type               Tipo de revisão sobre: I - Intervention ;D - Drug       
    * @param i_desc_treat_manag       treatment notes
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_treat_management
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_treatment        IN treatment_management.id_treatment%TYPE,
        i_flg_type         IN treatment_management.flg_type%TYPE,
        i_desc_treat_manag IN treatment_management.desc_treatment_management%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar todas as notas de tratamento associadas à medicação e/ou procedimento de um epsisódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param o_treat_manag            Listar para a medicação e/ou procedimento as suas notas de tratamento
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_treat_manag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        o_treat_manag OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar as notas de tratamento associadas a uma medicação e/ou procedimento de um epsisódio  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               Tipo de revisão sobre: I - Intervention ;D - Drug
    * @param i_treat_manag            treatment management id
    * @param o_treat_manag            Listar para a medicação e/ou procedimento as suas notas de tratamento
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_treat_manag_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_flg_type    IN treatment_management.flg_type%TYPE,
        i_treat_manag IN treatment_management.id_treatment%TYPE,
        o_treat_manag OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar as notas de atendimento associadas a um episódio   
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_profile_review         review profile 
    * @param i_prof_review            review professional id
    * @param i_dt_review_str          Data da avaliação 
    * @param i_notes_reviewed         Notas de avaliação
    * @param i_notes_additional       Notas adicionais    
    * @param i_flg_agree                  
    * @param i_flg_type               
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_attending_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_profile_review   IN epis_attending_notes.profile_reviewed%TYPE,
        i_prof_review      IN epis_attending_notes.id_prof_reviewed%TYPE,
        i_dt_review_str    IN VARCHAR2,
        i_notes_reviewed   IN epis_attending_notes.notes_reviewed%TYPE,
        i_notes_additional IN epis_attending_notes.notes_additional%TYPE,
        i_flg_agree        IN epis_attending_notes.flg_agree%TYPE,
        i_flg_type         IN epis_attending_notes.flg_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter as notas de atendimento associadas a um episódio    
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               
    * @param o_prof_reviewed          Listar o perfil e nome do avaliado
    * @param o_attend_notes           Listar as notas de avaliação
    * @param o_notes_addit            Listar as notas adicionais de avaliação
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION get_attending_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_flg_type      IN epis_attending_notes.flg_type%TYPE,
        o_prof_reviewed OUT pk_types.cursor_type,
        o_attend_notes  OUT pk_types.cursor_type,
        o_notes_addit   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter o detalhe de uma nota de atendimento de um episódio     
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_attending_notes        attending notes id               
    * @param o_attend_notes           Listar o detalhe de uma nota de atendimento 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_attending_notes_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_attending_notes IN epis_attending_notes.id_epis_attending_notes%TYPE,
        o_attend_notes    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Lista dos perfis disponiveis para a urgência      
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_profile                Lista dos perfis disponiveis
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_profile_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_profile OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar os profissionais do perfil seleccionado      
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode id
    * @param i_profile                profile id                   
    * @param o_profile_prof            Listar os profissionais do perfil seleccionado
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_profile_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_profile      IN profile_template.id_profile_template%TYPE,
        o_profile_prof OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar todas as revisões de registo de um episódio        
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_records_review         Listar todas as revisões de registo de um episódio
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_records_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        o_records_review OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar todos os profissionais que realizaram revisão de registos,excepto o próprio profissional         
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_all_prof               Listar todos os profissionais que realizaram revisão de registos, excepto o próprio profissional
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2009/10/21 
    **********************************************************************************************/
    FUNCTION get_all_prof_rec_review
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis     IN episode.id_episode%TYPE,
        o_all_prof OUT table_varchar,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --    
    /********************************************************************************************
    * Listar todos os profissionais que realizaram revisão de registos        
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_ret_all_prof           'N' - Returns all professionals expect the current one; 'Y' - returns all professionals
    * @param o_all_prof               Listar todos os profissionais que realizaram revisão de registos, excepto o próprio profissional
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_all_prof_rec_review_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_ret_all_prof IN VARCHAR2 DEFAULT 'N',
        o_all_prof     OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar todas as leituras de revisões de registos         
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_records_review         record review id
    * @param i_flg_status             Estado da revisão de registo efectuada pelo profissional. A- Activo; C - Cancelada 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION set_records_review_read
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_records_review IN table_varchar,
        i_flg_status     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar o detalhe de uma revisão de registo          
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_records_review         record review id
    * @param o_rec_review_det         Listar o detalhe de uma revisão de registo 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_records_review_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_records_review IN records_review.id_records_review%TYPE,
        o_rec_review_det OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar todas as notas críticas         
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_critical_care          Listar todas as notas críticas 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_critical_care_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        o_critical_care OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar as notas críticas do episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_critical_care          critical care id
    * @param i_value                  value
    * @param i_notes                  notes 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION set_critical_care_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_critical_care IN table_varchar,
        i_value         IN table_varchar,
        i_notes         IN critical_care_read.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar todas as notas críticas de um episódio                
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_crit_care_det          Listar todas as notas críticas de um episódio
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/24 
    **********************************************************************************************/
    FUNCTION get_critical_care_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        o_crit_care_det OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar a última nota crítica de um episódio            
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param o_crit_care              Listar a última nota crítica de um episódio
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_critical_care
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_crit_care OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Definir a label a ser retornada tendo em conta o valor: h - Horas; min. - Minutos           
    *
    * @param i_lang                   The language ID
    * @param i_value                  Valor das notas críticas
    *                        
    * @return                         description
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_ccare_hour_min
    (
        i_lang  IN language.id_language%TYPE,
        i_value IN VARCHAR2
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Registar o numero de elemntos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_document_area          doc area id
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_coding_element_chart
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_document_area IN doc_area.id_doc_area%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar o numero de elemntos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_id_mdm_evaluation      mdm evaluation
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_coding_element_mdm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_id_mdm_evaluation IN doc_area.id_doc_area%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cod_elem_mdm_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_id_mdm_evaluation IN doc_area.id_doc_area%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar o numero de elementos registados por um profissonal para uma àrea da BARTCHART  associada a um episódio           
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_origin                 origin id
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_coding_element_mdm_1
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        i_origin IN VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Registar o numero de elementos registados por um profissonal para uma àrea da BARTCHART  
    * associada a um episódio - SEM COMMITS        
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   episode id
    * @param i_origin                 origin id
    *                        
    * @return                         description
    * 
    * @author                         Sílvia Freitas
    * @version                        1.0
    * @since                          2006/10/08 
    **********************************************************************************************/
    FUNCTION set_cod_elem_mdm_1_no_commit
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        i_origin IN VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Registar as notas de tratamento para a medicação e/ou procedimento de um episódio  
    *
    * @param i_lang                       The language ID
    * @param i_prof                       Object (professional ID, institution ID, software ID)
    * @param i_epis                       the episode ID
    * @param i_treatment                  treatment id
    * @param i_flg_type                   Tipo de revisão sobre: I - Intervention ;D - Drug       
    * @param i_desc_treat_manag           treatment notes
    * @param o_id_treatment_management    treatment management id
    * @param o_error                      Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/23 
    **********************************************************************************************/
    FUNCTION set_treat_management_no_comit
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis                    IN episode.id_episode%TYPE,
        i_treatment               IN treatment_management.id_treatment%TYPE,
        i_flg_type                IN treatment_management.flg_type%TYPE,
        i_desc_treat_manag        IN treatment_management.desc_treatment_management%TYPE,
        o_id_treatment_management OUT treatment_management.id_treatment_management%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List all patient's response to treatment  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_treat                  id_treatment (id prescription)
    * @param o_treat_manag            Patient's response to treatment 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013/06/05 
    *
    **********************************************************************************************/
    FUNCTION get_treat_manag_presc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE,
        o_treat     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);
    g_error         VARCHAR2(4000);
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char  VARCHAR2(50);
    g_found         BOOLEAN;

    --
    g_available   profile_template.flg_available%TYPE;
    g_epis_active episode.flg_status%TYPE;
    --
    g_flg_status_a records_review_read.flg_status%TYPE;
    g_flg_status_c records_review_read.flg_status%TYPE;
    --
    g_exam_status_final exam_req_det.flg_status%TYPE;
    g_exam_status_read  exam_req_det.flg_status%TYPE;
    -- 
    g_analisys_status_final analysis_req_det.flg_status%TYPE;
    g_analisys_status_red   analysis_req_det.flg_status%TYPE;
    --
    g_tests_type_exam     tests_review.flg_type%TYPE;
    g_tests_type_analisys tests_review.flg_type%TYPE;
    --
    g_icon               VARCHAR2(1);
    g_icon_type_analysis sys_domain.img_name%TYPE;
    g_icon_type_exam     sys_domain.img_name%TYPE;
    --
    g_treat_type_interv treatment_management.flg_type%TYPE;
    g_treat_type_drug   treatment_management.flg_type%TYPE;
    --
    g_interv_status_final interv_presc_det.flg_status%TYPE;
    g_interv_status_curso interv_presc_det.flg_status%TYPE;
    g_interv_status_inter interv_presc_det.flg_status%TYPE;
    --
    g_icon_type_interv sys_domain.img_name%TYPE;
    g_icon_type_drug   sys_domain.img_name%TYPE;
    --
    g_flg_time_betw drug_prescription.flg_time%TYPE;
    g_flg_time_next drug_prescription.flg_time%TYPE;
    --
    g_presc_take_cont drug_presc_det.flg_take_type%TYPE;
    g_presc_take_sos  drug_presc_det.flg_take_type%TYPE;
    --
    g_presc_req  drug_prescription.flg_status%TYPE;
    g_presc_pend drug_prescription.flg_status%TYPE;
    g_presc_exec drug_prescription.flg_status%TYPE;
    g_presc_act  drug_prescription.flg_status%TYPE;
    g_presc_fin  drug_prescription.flg_status%TYPE;
    g_presc_can  drug_prescription.flg_status%TYPE;
    g_presc_par  drug_prescription.flg_status%TYPE;
    g_presc_intr drug_prescription.flg_status%TYPE;
    --
    g_presc_det_req  drug_presc_det.flg_status%TYPE;
    g_presc_det_pend drug_presc_det.flg_status%TYPE;
    g_presc_det_exe  drug_presc_det.flg_status%TYPE;
    g_presc_det_fin  drug_presc_det.flg_status%TYPE;
    g_presc_det_can  drug_presc_det.flg_status%TYPE;
    g_presc_det_intr drug_presc_det.flg_status%TYPE;
    --
    g_presc_plan_stat_adm  drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_nadm drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_can  drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_req  drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_pend drug_presc_plan.flg_status%TYPE;
    --
    g_interv_take_sos interv_presc_det.flg_interv_type%TYPE;
    --
    g_flg_type_c critical_care.flg_type%TYPE;
    g_flg_type_h critical_care.flg_type%TYPE;
    g_flg_type_n critical_care.flg_type%TYPE;
    --
    g_flg_type_d category.flg_type%TYPE;
    --
    g_cms_area_hpi  mdm_evaluation.cms_area%TYPE;
    g_cms_area_ros  mdm_evaluation.cms_area%TYPE;
    g_cms_area_pfsh mdm_evaluation.cms_area%TYPE;
    g_cms_area_pe   mdm_evaluation.cms_area%TYPE;
    g_cms_area_mdm  mdm_evaluation.cms_area%TYPE;
    --
    g_bartchart_status_a epis_bartchart.flg_status%TYPE;
    g_label              VARCHAR2(1);
    g_no_color           VARCHAR2(1);

    g_exam_type_img VARCHAR2(1);

    g_doc_area_exam CONSTANT doc_area.id_doc_area%TYPE := 1083;
    g_local VARCHAR2(100);
    g_soro  VARCHAR2(100);
    g_drug  drug.flg_type%TYPE;
    --
    g_flg_nursing_notes epis_recomend.flg_type%TYPE;
    --
    g_cat_doc   category.flg_type%TYPE;
    g_cat_nurse category.flg_type%TYPE;
    g_cat_tech  category.flg_type%TYPE;
    --
    g_trs_session CONSTANT notes_config.notes_code%TYPE := 'TRS';
    g_xrv_session CONSTANT notes_config.notes_code%TYPE := 'XRV';
    g_crv_session CONSTANT notes_config.notes_code%TYPE := 'CRV';

    g_orig_analysis_periodic_obs analysis_result.flg_orig_analysis%TYPE;
    g_orig_analysis_ser_analysis analysis_result.flg_orig_analysis%TYPE;
    g_orig_analysis_woman_health analysis_result.flg_orig_analysis%TYPE;

END pk_medical_decision;
/
