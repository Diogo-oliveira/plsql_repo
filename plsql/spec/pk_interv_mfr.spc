/*-- Last Change Revision: $Rev: 2028762 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_interv_mfr IS

    -- Ana Monteiro: 2008/11/17 - TYPE utilizado para retornar informacao de mfr
    TYPE interv_mfr_rec IS RECORD(
        id_area              NUMBER(24),
        desc_area            VARCHAR2(4000),
        id_interv_presc_det  NUMBER(24),
        id_intervention      NUMBER(24),
        desc_procedure       VARCHAR2(4000),
        id_codification      NUMBER(24),
        codification         VARCHAR2(4000),
        id_mcdt_codification NUMBER(24),
        id_exec_institution  NUMBER(24),
        exec_institution     VARCHAR2(4000),
        instrucao            VARCHAR2(4000),
        prof_req             VARCHAR2(200),
        date_req             VARCHAR2(50),
        date_req_str         VARCHAR2(14),
        proc_status          VARCHAR2(2),
        avail_butt_ok        VARCHAR2(1),
        avail_butt_action    VARCHAR2(2),
        icon                 VARCHAR2(100),
        date_icon            VARCHAR2(50),
        flg_text             VARCHAR2(2),
        avail_butt_cancel    VARCHAR2(2),
        title_notes          VARCHAR2(4000),
        total_sessions       NUMBER(3),
        num_sessions         NUMBER(3),
        episode              NUMBER(24),
        prof                 NUMBER(24),
        flg_propose          VARCHAR2(2),
        rank                 NUMBER(6));

    -- Ana Monteiro: 2008/11/17 - cursor utilizado para retornar informacao de mfr
    TYPE interv_mfr_cur IS REF CURSOR RETURN interv_mfr_rec;

    /**********************************************************************************************
    * Gathers the information on intervention (names and number of execution) for a given
    * professional, patient and day
    * 
    * @param i_lang                     Language ID
    * @param i_id_professional          Professional's ID
    * @param i_id_patient               Patient ID
    * @param i_schedule                 Schedule ID
    *
    * @return                           A string with the concatenated info
    *
    * @author                           Joao Martins
    * @since                            2008/05/20
    **********************************************************************************************/
    FUNCTION get_concatenated_interventions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_schedule        IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Updates a prescription's status information (private function)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_interv_presc_det    Intervention prescription ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Joao Martins
    * @version                        1.0
    * @since                          2008/04/17
    *
    * @alteration                     JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION update_interv_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the icon corresponding to a PM&R schedule status
    * 
    * @param i_lang             Language ID
    * @param i_prof             Professional details
    * @param i_schedule         Schedule ID
    *
    * @return                   Icon name
    *
    * @author                   Rita Lopes
    * @since                    2008/05/23
    **********************************************************************************************/
    FUNCTION get_icon_state_mfr
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the status of a PM&R schedule
    * 
    * @param i_lang                  Language ID
    * @param i_prof                  Professional details
    * @param i_schedule              Schedule ID
    *
    * @return                        String with the status
    *
    * @author                        Rita Lopes
    * @since                         2008/05/23
    **********************************************************************************************/
    FUNCTION get_state_mfr
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the number of executions for an intervention
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_interv_presc_det       Intervention details
    *
    * @return                         A number
    *                        
    * @author                         Rita Lopes
    * @version                        1.0 
    * @since                          2008/04/19
    **********************************************************************************************/
    FUNCTION get_num_exec_mfr
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the number of scheduled sessions for a given intervention
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_interv_presc_det       Intervention's ID
    *
    * @return                         number
    *                        
    * @author                         Rita Lopes
    * @version                        1.0 
    * @since                          2008/04/19
    **********************************************************************************************/
    FUNCTION get_num_sessions_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN NUMBER;
    /**********************************************************************************************
    * Returns Icon NAME
    * (ATTENTION: Any changes regarding on this function should be reported to the P1 team)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_interv_presc_det                    Patient ID
    *
    * @return                         Icon name
    *                        
    * @author                         Rita Lopes
    * @version                        1.0 
    * @since                          2008/07/26
    *
    **********************************************************************************************/
    FUNCTION get_icon_name
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the info for header 
    *
    * @param i_lang                   Language ID
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Rita Lopes
    * @version                        2.4.3
    * @since                          2008/07/23
    * @alteration                     JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_epis_header
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat              IN patient.id_patient%TYPE,
        i_id_sched            IN schedule.id_schedule%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        o_name                OUT patient.name%TYPE,
        o_gender              OUT patient.gender%TYPE,
        o_age                 OUT VARCHAR2,
        o_health_plan         OUT VARCHAR2,
        o_compl_diag          OUT VARCHAR2,
        o_prof_name           OUT VARCHAR2,
        o_prof_spec           OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_episode             OUT pk_types.cursor_type,
        o_clin_rec            OUT pk_types.cursor_type,
        o_location            OUT pk_types.cursor_type,
        o_sched               OUT pk_types.cursor_type,
        o_efectiv             OUT pk_types.cursor_type,
        o_atend               OUT pk_types.cursor_type,
        o_wait                OUT pk_types.cursor_type,
        o_pat_photo           OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_shcut_habits        OUT VARCHAR2,
        o_shcut_allergies     OUT VARCHAR2,
        o_shcut_episodes      OUT VARCHAR2,
        o_shcut_bloodtype     OUT VARCHAR2,
        o_shcut_relevdiseases OUT VARCHAR2,
        o_shcut_relevnotes    OUT VARCHAR2,
        o_shcut_photo         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns true if all the sessions of a schedule are finished
    *
    * @param i_lang        ID language
    * @param i_prof        Assigned professional's ID
    * @param i_id_schedule id schedule
    *
    * @return                         True if session done, or false if not
    *                        
    * @author                         Rita Lopes
    * @version                        2.4.3.2
    * @since                          2008/09/18
    **********************************************************************************************/
    FUNCTION get_plan_status_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the names of the professionals allocated to an intervention's prescription.
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's ID
    * @param i_id_interv_presc_det Prescription's ID
    *
    * @return                      Names of the professionals separated by semicolons
    *                        
    * @author                      Joao Martins
    * @version                     2.4.3
    * @since                       2008/12/12
    **********************************************************************************************/
    FUNCTION get_prof_alloc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the IDs of the professionals allocated to an intervention's prescription.
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's ID
    * @param i_id_interv_presc_det Prescription's ID
    *
    * @return                      Names of the professionals separated by semicolons
    *                        
    * @author                      Joao Martins
    * @version                     2.4.3
    * @since                       2009/01/05
    **********************************************************************************************/
    FUNCTION get_prof_id_alloc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the description of an intervention's physiatry area.
    *
    * @param i_lang                ID language
    * @param i_id_intervention     Intervention ID
    *
    * @return                      Physiatry area
    *                        
    * @author                      Joao Martins
    * @version                     2.4.3
    * @since                       2009/01/06
    **********************************************************************************************/
    FUNCTION get_physiatry_area
    (
        i_lang            IN language.id_language%TYPE,
        i_id_intervention IN interv_presc_det.id_intervention%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the most frequent conditions of ICF
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details    
    *
    * @param o_conditions          Array of conditions
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/01/21
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_interv_conditions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_conditions OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the categories associated to one condition of the most frequent
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details    
    * @param i_idCondition         ID of the condition    
    *
    * @param o_categories          Array of conditions
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/01/21
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_icf_by_conditions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_idcondition IN interv_condition.id_interv_condition%TYPE,
        o_categories  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of icf od a determine icf parent
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_idicfparent         ID of the parent (null in the case of obtain components)  
    * @param o_id_GrandParent      ID of grand parent (null in case of components and chapters)
    *
    * @param o_icf                 Array of icf the column Folha if 0 means that has child, 1 - doesn't have child
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/01/23
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_icf_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_idicfparent    IN icf.id_icf_parent%TYPE,
        o_id_parent      OUT icf.id_icf%TYPE,
        o_id_grandparent OUT icf.id_icf%TYPE,
        o_icf            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the details for the ICF Assessment section of the summary page
    * This functions can by filter by episode, patient, doc area, start and end date 
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional's details
    * @param i_id_episode          Current episode
    * @param i_id_patient          Patient's ID
    * @param i_doc_area            Doc area ID
    * @param i_start_date          Begin date (optional)         
    * @param i_end_date            End date (optional)
    * @param o_doc_area_register   Record details
    * @param o_doc_area_val        Assessment details
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Cristina Oliveira
    * @version                     2.6.4
    * @since                       2014/10/02
    **********************************************************************************************/
    FUNCTION get_evaluation_icf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_start_date        IN VARCHAR2 DEFAULT NULL,
        i_end_date          IN VARCHAR2 DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the details for the ICF Assessment section of the summary page
    * This functions can by filter by episode, patient, doc area, start and end date 
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional's details
    * @param i_scope               'E' -> Episode | 'P' -> Patient
    * @param i_id_scope            Value
    * @param o_assessment          Assessment details
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Pedro Henriques
    * @version                     2.7.1.5
    * @since                       2017/10/09
    **********************************************************************************************/
    FUNCTION get_evaluation_icf_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_assessment OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the details for the ICF Assessment section of the summary page
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional's details
    * @param i_id_episode          Current episode
    * @param i_id_patient          Patient's ID
    * @param i_doc_area            Doc area ID
    * @param o_doc_area_register   Record details
    * @param o_doc_area_val        Assessment details
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joao Martins
    * @version                     2.4.4
    * @since                       2009/01/20
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_evaluation_icf
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the top ICF component's ID for a given ICF category or chapter
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional's details
    * @param i_id_icf              ICF category or chapter
    *
    * @return                      ID of the component
    *                        
    * @author                      Joao Martins
    * @version                     2.4.4
    * @since                       2009/01/22
    **********************************************************************************************/
    FUNCTION get_top_id_icf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_icf IN icf.id_icf%TYPE
    ) RETURN icf.id_icf%TYPE;

    /**********************************************************************************************
    * Returns an assessment's full coding string for a given category
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_icf                ICF category
    * @param i_id_interv_evaluation  Evaluation ID
    *
    * @return                        String with the coding
    *                        
    * @author                        Joao Martins
    * @version                       2.4.4
    * @since                         2009/01/22
    **********************************************************************************************/
    FUNCTION get_full_coding
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_icf               IN interv_eval_icf_qualif.id_icf%TYPE,
        i_id_interv_evaluation IN interv_eval_icf_qualif.id_interv_evaluation%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the list of icf filtered by the text
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_code_name           Text to search (code or name of icf)  
    *
    * @param o_icf                 Array of icf. the column Folha if 0 means that has child, 1 - doesn't have child
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_MSG - mensagem com indicação de q ultrapassou o nº limite de registos
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso
    * @param O_FLG_SHOW = Y
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/01/26
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_icf_categories
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_name IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_icf       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the detail of an icf evaluation
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_idinterv           ID_interv_evaluation  
    *
    * @param o_icf                 Array of selected icf. 
    * @param o_icf_hier            Array of hierarchy of icf 
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/01/29
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    * @
    **********************************************************************************************/
    FUNCTION get_icf_evaluation
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_idinterv IN interv_evaluation.id_interv_evaluation%TYPE,
        o_icf      OUT pk_types.cursor_type,
        o_icf_hier OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels an ICF evaluation, optional notes
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details     
    * @param i_id_interv_evaluation  Evaluation ID
    * @param i_notes                 Cancelling notes  
    *
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Joao Martins
    * @version                       2.4.4
    * @since                         2009/02/02
    * @alteration                    JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION cancel_icf_evaluation
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_interv_evaluation IN interv_evaluation.id_interv_evaluation%TYPE,
        i_notes                IN interv_evaluation.notes_cancel%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels an ICF evaluation, optional notes
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details     
    * @param i_id_interv_evaluation  Evaluation ID
    * @param i_cancel_mode           (C)ancel or (O)utdate?
    * @param i_notes                 Cancelling notes  
    *
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Joao Martins
    * @version                       2.4.4
    * @since                         2009/02/02
    * @alteration                    JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION cancel_icf_evaluation_nocommit
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_interv_evaluation IN interv_evaluation.id_interv_evaluation%TYPE,
        i_cancel_mode          IN interv_evaluation.flg_status%TYPE DEFAULT 'C',
        i_notes                IN interv_evaluation.notes_cancel%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets a list of qualificators for a given category/component
    *
    * @param i_lang                        Language ID
    * @param i_prof                        Professional's details     
    * @param i_id_icf                      Category/component ID
    * @param i_id_icf_qualification_scale  Scale ID
    * @param i_flg_level                   Level
    * @param o_qualif                      Qualificators
    * @param o_error                       Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Joao Martins
    * @version                       2.4.4
    * @since                         2009/02/02
    * @alteration                    JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_icf_qualif
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_icf                     IN icf_qualification_rel.id_icf%TYPE,
        i_id_icf_qualification_scale IN icf_qualification_rel.id_icf_qualification_scale%TYPE,
        i_flg_level                  IN icf_qualification_rel.flg_level%TYPE,
        o_qualif                     OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a icf evalutaion.
    * all the arrays must have the same size.
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details  
    * @param i_id_episode          Current episode
    * @param i_id_patient          Patient's ID      
    * @param i_IdICF               Array of selected icf. 
    * @param i_Notes               Array of Notes associated to id_icf
    * @param i_idQualScaleLevel1   Array of Qualification Scale of Level1
    * @param i_id_QualifiLevel1    Array of Qualification of Level1
    * @param i_idQualScaleLevel2   Array of Qualification Scale of Level1
    * @param i_id_QualifiLevel2    Array of Qualification of Level1
    * @param i_idQualScaleLevel3   Array of Qualification Scale of Level1
    * @param i_id_QualifiLevel3    Array of Qualification of Level1
    
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/02/02
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION create_icf_evaluation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_idicf               IN table_number,
        i_notes               IN table_varchar,
        i_idqualscalelevel1   IN table_number,
        i_id_qualifilevel1    IN table_number,
        i_idqualscalelevel2   IN table_number,
        i_id_qualifilevel2    IN table_number,
        i_idqualscalelevel3   IN table_number,
        i_id_qualifilevel3    IN table_number,
        o_id_intervevaluation OUT interv_evaluation.id_interv_evaluation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Updates one icf evalutaion, by canceling the oldest and creating a new one. 
    * all the arrays must have the same size.
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_idinterv            ID_interv_evaluation  
    * @param i_IdEpisode           Current episode
    * @param i_IdPatient           Current patient ID
    * @param i_IdICF               Array of selected icf. 
    * @param i_Notes               Array of Notes associated to id_icf
    * @param i_idQualScaleLevel1   Array of Qualification Scale of Level1
    * @param i_id_QualifiLevel1    Array of Qualification of Level1
    * @param i_idQualScaleLevel2   Array of Qualification Scale of Level1
    * @param i_id_QualifiLevel2    Array of Qualification of Level1
    * @param i_idQualScaleLevel3   Array of Qualification Scale of Level1
    * @param i_id_QualifiLevel3    Array of Qualification of Level1
    
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/02/02
    * @alteration                  JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION update_icf_evaluation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_idinterv            IN interv_evaluation.id_interv_evaluation%TYPE,
        i_idepisode           IN episode.id_episode%TYPE,
        i_idpatient           IN patient.id_patient%TYPE,
        i_idicf               IN table_number,
        i_notes               IN table_varchar,
        i_idqualscalelevel1   IN table_number,
        i_id_qualifilevel1    IN table_number,
        i_idqualscalelevel2   IN table_number,
        i_id_qualifilevel2    IN table_number,
        i_idqualscalelevel3   IN table_number,
        i_id_qualifilevel3    IN table_number,
        o_id_intervevaluation OUT interv_evaluation.id_interv_evaluation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the number of qualifiers of a component, given a component/chapter/category
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_icf                ICF category (array)
    * @param o_qualif                Cursor with qualifier scale per component
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.4.4
    * @since                         2009/02/06
    * @alteration                    JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_num_icf_qualif
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_icf IN table_number,
        o_qualif OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the menu items for the add (+) or advanced search (magnifier +) buttons
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_subject               Menu identifier
    * @param i_state                 Menu identifier
    * @param o_menu                  Menu items
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Joao Martins
    * @version                       2.4.4
    * @since                         2009/02/09
    * @alteration                    JM 2009/03/09 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION get_menu_evaluation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_subject IN action.subject%TYPE,
        i_state   IN action.from_state%TYPE,
        o_menu    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Proxy function for the summary page getter function - provides specific extra information
    * related with the physiatry area of each template. 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param o_physiatry_area         Name of the template's physiatry area
    * @param o_totals                 Assessment score
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Joao Martins
    * @version                        2.5
    * @since                          2009/03/23
    **********************************************************************************************/
    FUNCTION get_summ_page_mfr_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        i_start_date         IN VARCHAR2 DEFAULT NULL,
        i_end_date           IN VARCHAR2 DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_physiatry_area     OUT pk_types.cursor_type,
        o_totals             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Proxy function for the summary page getter function - provides specific extra information
    * related with the physiatry area of each template. 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param o_physiatry_area         Name of the template's physiatry area
    * @param o_totals                 Assessment score
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Joao Martins
    * @version                        2.5
    * @since                          2009/03/23
    **********************************************************************************************/
    FUNCTION get_summ_page_mfr_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_physiatry_area     OUT pk_types.cursor_type,
        o_totals             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the instructions for a PM&R prescription according to the passed format, using
    * combinations of the following values: P (priority), F (frequency), S (number of sessions),
    * E (executions per session), D (start date)
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_id_interv_presc_det Prescription ID
    * @param i_format              Output string format (optional)
    *
    * @return                      Instructions for this prescription
    *                        
    * @author                      Joao Martins
    * @version                     2.5
    * @since                       2009/02/21
    **********************************************************************************************/
    FUNCTION get_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_format              IN VARCHAR2 DEFAULT 'PFSED'
    ) RETURN VARCHAR2;

    -- Global variables
    g_found        BOOLEAN;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);

    -- Global constants
    get_interv_freq_m       CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'M';
    g_interv_request        CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'P';
    g_interv_conv           CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'C';
    g_flg_next_episode      CONSTANT interv_prescription.flg_time%TYPE := 'B';
    g_flg_status_pendente   CONSTANT interv_prescription.flg_status%TYPE := 'D';
    g_priority_domain       CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_PRTY';
    g_flg_status            CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_STATUS_MFR';
    g_flg_status_change     CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET_CHANGE.FLG_STATUS_CHANGE';
    g_flg_freq              CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_FREQ';
    g_flg_status_plan       CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_PLAN.FLG_STATUS_MFR';
    g_flg_status_schedule   CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE.FLG_STATUS';
    g_interv_type_con       CONSTANT interv_presc_det.flg_interv_type%TYPE := 'C';
    g_flg_active            CONSTANT intervention.flg_status%TYPE := 'A';
    g_flg_status_finalizado CONSTANT interv_prescription.flg_status%TYPE := 'F';
    g_flg_status_cancel     CONSTANT interv_prescription.flg_status%TYPE := 'C';
    g_transition            CONSTANT sys_domain.code_domain%TYPE := 'STATUS_PROCEDURE_MFR';
    g_interv_freq           CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'M';
    g_interv_total          CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'T';
    g_selected              CONSTANT VARCHAR2(1) := 'S';
    g_interv_can_req        CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'P';
    g_flg_status_sched_c    CONSTANT schedule.flg_status%TYPE := 'C';
    g_flg_status_sched_a    CONSTANT schedule.flg_status%TYPE := 'A';

    g_flg_interv_type_n CONSTANT interv_presc_det.flg_interv_type%TYPE := 'N';

    g_flg_plan_cancelled       CONSTANT interv_presc_plan.flg_status%TYPE := 'C';
    g_flg_plan_completed       CONSTANT interv_presc_plan.flg_status%TYPE := 'F';
    g_flg_status_plan_d        CONSTANT interv_presc_plan.flg_status%TYPE := 'D';
    g_flg_status_plan_agendado CONSTANT interv_presc_plan.flg_status%TYPE := 'A';
    g_flg_status_plan_emcurso  CONSTANT interv_presc_plan.flg_status%TYPE := 'E';
    g_flg_status_plan_faltou   CONSTANT interv_presc_plan.flg_status%TYPE := 'M';
    g_flg_status_plan_p        CONSTANT interv_presc_plan.flg_status%TYPE := 'P';

    g_notes     CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T063';
    g_canc      CONSTANT VARCHAR2(4) := 'CANC';
    g_desc_canc CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T020';
    g_f_canc    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_canc    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T021';

    g_dup CONSTANT VARCHAR2(4) := 'DUP';

    g_sus      CONSTANT VARCHAR2(4) := 'SUS';
    g_desc_sus CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T023';
    g_f_sus    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_sus    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T024';

    g_des      CONSTANT VARCHAR2(4) := 'DES';
    g_desc_des CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T025';
    g_f_des    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_des    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T026';

    g_ret      CONSTANT VARCHAR2(4) := 'RET';
    g_desc_ret CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T027';
    g_f_ret    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_ret    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T028';

    g_rec      CONSTANT VARCHAR2(4) := 'REC';
    g_desc_rec CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T029';
    g_f_rec    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_rec    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T030';

    g_recd      CONSTANT VARCHAR2(4) := 'RECD';
    g_desc_recd CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T031';
    g_f_recd    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_recd    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T032';

    g_rect      CONSTANT VARCHAR2(4) := 'RECR';
    g_desc_rect CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T033';
    g_f_rect    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_rect    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T034';

    g_recs      CONSTANT VARCHAR2(4) := 'RECS';
    g_desc_recs CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T129';
    g_f_recs    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_recs    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T130';

    g_desc_canc_propose CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T111';
    g_f_canc_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_canc_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T112';

    g_desc_sus_propose CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T113';
    g_f_sus_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_sus_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T114';

    g_desc_des_propose CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T115';
    g_f_des_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_des_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T116';

    g_desc_ret_propose CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T117';
    g_f_ret_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_ret_propose    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T118';

    g_canc_sess      CONSTANT VARCHAR2(6) := 'CANC_S';
    g_desc_canc_sess CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T126';
    g_f_canc_sess    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_canc_sess    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T021';

    g_ref_p      CONSTANT VARCHAR2(5) := 'REF_P';
    g_desc_ref_p CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T127';
    g_f_ref_p    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_ref_p    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T128';

    g_chg_sess CONSTANT VARCHAR(7) := 'ALTER_S';

    g_add CONSTANT VARCHAR2(4) := 'ADD';

    g_alter_proc CONSTANT VARCHAR2(5) := 'ALTER';
    g_alter      CONSTANT VARCHAR2(5) := 'RECA';
    g_desc_alter CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T131';
    g_f_alter    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T002';
    g_s_alter    CONSTANT sys_message.code_message%TYPE := 'PROCEDURES_MFR_T132';

    g_last8      CONSTANT VARCHAR2(1) := 'L';
    g_all_interv CONSTANT VARCHAR2(1) := 'A';
    g_with_me    CONSTANT VARCHAR2(1) := 'P';
    g_episode    CONSTANT VARCHAR2(1) := 'E';

    g_notification_via CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE.FLG_NOTIFICATION_VIA';

    g_flg_state_a CONSTANT schedule_intervention.flg_state%TYPE := 'A';
    g_flg_state_p CONSTANT schedule_intervention.flg_state%TYPE := 'P';
    g_flg_state_d CONSTANT schedule_intervention.flg_state%TYPE := 'D';
    g_flg_state_c CONSTANT schedule_intervention.flg_state%TYPE := 'C';
    g_flg_state_s CONSTANT schedule_intervention.flg_state%TYPE := 'S';

    g_flg_notification_n CONSTANT schedule.flg_notification%TYPE := 'N';

    g_flg_status_ia CONSTANT interv_evaluation.flg_status%TYPE := 'A';

    g_flg_status_schedulepend CONSTANT interv_presc_det.flg_status%TYPE := 'P';
    g_flg_status_scheduled    CONSTANT interv_presc_det.flg_status%TYPE := 'A';
    g_flg_status_e            CONSTANT interv_presc_det.flg_status%TYPE := 'E';
    g_flg_status_d            CONSTANT interv_presc_det.flg_status%TYPE := 'D';
    g_flg_status_s            CONSTANT interv_presc_det.flg_status%TYPE := 'S';
    g_flg_status_f            CONSTANT interv_presc_det.flg_status%TYPE := 'F';
    g_flg_status_i            CONSTANT interv_presc_det.flg_status%TYPE := 'I';
    g_flg_status_g            CONSTANT interv_presc_det.flg_status%TYPE := 'G';
    g_flg_status_c            CONSTANT interv_presc_det.flg_status%TYPE := 'C';
    g_flg_status_p            CONSTANT interv_presc_det.flg_status%TYPE := 'P';
    g_flg_status_v            CONSTANT interv_presc_det.flg_status%TYPE := 'V';
    g_flg_status_t            CONSTANT interv_presc_det.flg_status%TYPE := 'T';
    g_flg_status_ext          CONSTANT interv_presc_det.flg_status%TYPE := 'X';
    g_flg_status_declined_g   CONSTANT interv_presc_det.flg_status%TYPE := 'G';

    g_flg_available_y CONSTANT sys_domain.flg_available%TYPE := 'Y';

    g_cat_doctor CONSTANT category.id_category%TYPE := 1;

    g_flg_propose_n CONSTANT VARCHAR2(1) := 'N';
    g_flg_propose_y CONSTANT VARCHAR2(1) := 'Y';

    g_flg_si_state_o   CONSTANT schedule_intervention.flg_state%TYPE := 'O';
    g_flg_si_state_f   CONSTANT schedule_intervention.flg_state%TYPE := 'F';
    g_flg_si_state_c   CONSTANT schedule_intervention.flg_state%TYPE := 'C';
    g_flg_si_state_s   CONSTANT schedule_intervention.flg_state%TYPE := 'S';
    g_disch_type_alert CONSTANT epis_info.flg_status%TYPE := 'A';
    g_epis_inactive    CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pend        CONSTANT episode.flg_status%TYPE := 'P';
    g_epis_active      CONSTANT episode.flg_status%TYPE := 'A';
    g_visit_inactive   CONSTANT visit.flg_status%TYPE := 'I';
    g_visit_active     CONSTANT visit.flg_status%TYPE := 'A';

    g_flg_y CONSTANT VARCHAR2(1) := 'Y';
    g_flg_n CONSTANT VARCHAR2(1) := 'N';

    g_prof_inst_active CONSTANT prof_institution.flg_state%TYPE := 'A';

    g_flg_status_exists CONSTANT VARCHAR2(1) := 'Y';

    g_category_f CONSTANT category.flg_type%TYPE := 'F';

    g_flg_referral_reserved  CONSTANT interv_presc_det.flg_referral%TYPE := 'R';
    g_flg_referral_sent_s    CONSTANT interv_presc_det.flg_referral%TYPE := 'S';
    g_flg_referral_sent_i    CONSTANT interv_presc_det.flg_referral%TYPE := 'I';
    g_flg_referral_available CONSTANT interv_presc_det.flg_referral%TYPE := 'A';

    g_patient_active          CONSTANT patient.flg_status%TYPE := 'A';
    g_pat_blood_active        CONSTANT pat_blood_group.flg_status%TYPE := 'A';
    g_default_hplan_y         CONSTANT pat_health_plan.flg_default%TYPE := 'Y';
    g_hplan_active            CONSTANT pat_health_plan.flg_status%TYPE := 'A';
    g_sched_cancel            CONSTANT schedule.flg_status%TYPE := 'C';
    g_sched_temp              CONSTANT schedule.flg_status%TYPE := 'T';
    g_pat_allergy_cancel      CONSTANT pat_allergy.flg_status%TYPE := 'C';
    g_pat_habit_cancel        CONSTANT pat_habit.flg_status%TYPE := 'C';
    g_epis_stat_inactive      CONSTANT episode.flg_status%TYPE := 'I';
    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';
    g_pat_notes_cancel        CONSTANT pat_notes.flg_status%TYPE := 'C';
    g_epis_consult epis_type.id_epis_type%TYPE;
    g_epis_cs      epis_type.id_epis_type%TYPE;
    g_epis_fis     epis_type.id_epis_type%TYPE;
    g_epis_inpt CONSTANT epis_type.id_epis_type%TYPE := 5;
    g_months_sign VARCHAR2(200);
    g_days_sign   VARCHAR2(200);
    g_exception EXCEPTION;

    g_flg_sch_type CONSTANT schedule.flg_sch_type%TYPE := 'I';

    /* Package name */
    g_package_name VARCHAR2(30);

    g_flg_session_y CONSTANT VARCHAR2(1) := 'Y';

    g_flg_icf_component CONSTANT VARCHAR2(1) := 'C';
    g_flg_icf_chapter   CONSTANT VARCHAR2(1) := 'A';
    g_flg_icf_category  CONSTANT VARCHAR2(1) := 'T';

    g_flg_level1 CONSTANT icf_qualification_rel.flg_level%TYPE := 1;
    g_flg_level2 CONSTANT icf_qualification_rel.flg_level%TYPE := 2;
    g_flg_level3 CONSTANT icf_qualification_rel.flg_level%TYPE := 3;

    g_status_eval_canc CONSTANT interv_evaluation.flg_status%TYPE := 'C';
    g_status_eval_outd CONSTANT interv_evaluation.flg_status%TYPE := 'O';

    g_flg_typeevaluation_icf   CONSTANT interv_evaluation.flg_type%TYPE := 'I';
    g_flg_typeevaluation_notes CONSTANT interv_evaluation.flg_type%TYPE := 'N';
    g_flg_typeevaluation_plan  CONSTANT interv_evaluation.flg_type%TYPE := 'P';

    g_unit_day   CONSTANT unit_measure.id_unit_measure%TYPE := 2680;
    g_unit_week  CONSTANT unit_measure.id_unit_measure%TYPE := 2681;
    g_unit_month CONSTANT unit_measure.id_unit_measure%TYPE := 2682;

    g_rehab_assessment_scope_e CONSTANT sys_config.value%TYPE := 'E';
    g_rehab_assessment_scope_p CONSTANT sys_config.value%TYPE := 'P';
    g_rehab_assessment_scope_o CONSTANT sys_config.value%TYPE := 'O';
    g_rehab_assessment_scope_v CONSTANT sys_config.value%TYPE := 'V';
END pk_interv_mfr;
/
