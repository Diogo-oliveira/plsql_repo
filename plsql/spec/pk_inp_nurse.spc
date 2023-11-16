/*-- Last Change Revision: $Rev: 2028753 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_nurse IS
    /********************************************************************************************
    * Cancel an episode documentation
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_id_cancel_reason       Cancel reason
    * @param i_notes                  Cancel Notes
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - Não, R - lido, C - confirmado                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda, based on pk_documentation.sr_cancel_epis_documentation
    * @version                        1.0   
    * @since                          2007/06/01
    * @Deprecated : cancel_epis_documentation (with i_cancel_reason) should be used instead.
    **********************************************************************************************/
    FUNCTION cancel_epis_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes       IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_scale_epis_doc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes       IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_scales_class
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_value             IN scales_class.max_value%TYPE,
        i_scales            IN scales.id_scales%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_id_scales_formula IN scales_formula.id_scales_formula%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_scales_class_pat
    (
        i_lang              NUMBER,
        i_value             IN scales_doc_value.value%TYPE,
        i_scales            NUMBER,
        i_id_patient        IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_id_scales_formula IN scales_formula.id_scales_formula%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_scales_det
    (
        i_lang               NUMBER,
        i_epis_documentation IN NUMBER,
        o_scales_det         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional
    ) RETURN VARCHAR2;

    FUNCTION update_scales_task
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN NUMBER,
        i_prof     IN profissional,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Returns the summary page values for the scale evaluation summary page.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_doc_area                documentation area ID
    * @param i_id_episode              the episode id
    * @param o_doc_area_register       Cursor with the doc area info register
    * @param o_doc_area_val            Cursor containing the completed info for episode
    * @param o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param o_doc_not_register        Cursor containing the reason to not document the assessment    
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          José Silva
    * @version                         1.0
    * @since                           12-11-2007
    **********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN NUMBER,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_scales         OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets documentation values associated with an area (doc_area) of a template (doc_template). 
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_cat_type              professional category
    * @param i_doc_area                   doc_area id
    * @param i_doc_template               doc_template id
    * @param i_epis_documentation         epis documentation id
    * @param i_flg_type                   A Agree, E edit, N - new 
    * @param i_id_documentation           array with id documentation,
    * @param i_id_doc_element             array with doc elements
    * @param i_id_doc_element_crit        array with doc elements crit
    * @param i_value                      array with values,
    * @param i_notes                      note
    * @param i_id_doc_element_qualif      array with doc elements qualif  
    * @param i_epis_context               context id (Ex: id_interv_presc_det, id_exam...)
    * @param i_summary_and_notes          template summary to be included on clinical notes
    * @param i_episode_context            context episode id  used in preoperative ORIS area by OUTP, INP, EDIS 
    * @param i_flg_table_origin            Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param o_error                       Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION
    * @value i_flg_commit                  {*} 'Y'  For commit, 'N' otherwise
    * @value o_schow_action                Returns if is necessary to show pop-up with actions
    * @value o_action                      Returns actions for the result
    * @value o_score                       Returns result score                                    
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Rita Lopes, based on pk_touch_option.set_epis_documentation
    * @version                            1.0   
    * @since                              08-04-2010
    *
    **********************************************************************************************/
    FUNCTION get_scales_evaluation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_show_action        OUT VARCHAR2,
        o_action             OUT pk_types.cursor_type,
        o_title_message      OUT VARCHAR2,
        o_desc_message       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Answer to avaliaton action
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param o_error                       Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Rita Lopes
    * @version                            1.0   
    * @since                              09-04-2010
    *
    **********************************************************************************************/
    FUNCTION set_scales_action
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_action_intern_name IN scales_action.internal_name%TYPE,
        i_scales_action      IN scales_action.id_scales_action%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_notes_reason       IN consult_req.reason_for_visit%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Checks if an episode has records for a provided assessment.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_episode                 Episode ID
    * @param i_id_doc_area             Documentation area ID
    * @param i_cancel_area             Cancel reason area 
    * @param o_flg_show                Show warning modal window? (Y) Yes (N) No
    * @param o_flg_write               Professional has permission to document the assessment? (Y) Yes (N) No
    * @param o_reasons                 Reasons to not fill the assessment
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          José Brito
    * @version                         2.5.0.7.8
    * @since                           03-12-2010
    **********************************************************************************************/
    FUNCTION check_assessment_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_cancel_area IN cancel_rea_area.intern_name%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_flg_write   OUT summary_page_access.flg_write%TYPE,
        o_reasons     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Set the reason for NOT document the assessment
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_doc_area             Documentation Area ID
    * @param i_id_cancel_reason        Cancel reason ID
    * @param i_notes                   Notes
    * @param o_id_epis_documentation   New documentation ID
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          José Brito
    * @version                         2.5.0.7.8
    * @since                           03-12-2010
    **********************************************************************************************/
    FUNCTION set_scale_no_doc_reason
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_doc_area           IN doc_area.id_doc_area%TYPE,
        i_id_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_notes                 IN epis_documentation.notes%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*  Returns the summary page values for the scale evaluation summary page.
    * This functions can by filter by episode, patient or visit according to the given i_flg_scope.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_doc_area                documentation area ID
    * @param i_id_episode              Episode identifier; mandatory if i_flg_scope='E'
    * @param i_flg_scope               Scope: P -patient; E- episode; V-visit; S-session
    * @param i_scope                   For i_flg_scope = P, i_scope regards to id_patient
    *                                  For i_flg_scope = V, i_scope regards to id_visit
    *                                  For i_flg_scope = E, i_scope regards to id_episode
    * @param i_start_date              Start date
    * @param i_end_date                End date
    * @param o_doc_area_register       Cursor with the doc area info register
    * @param o_doc_area_val            Cursor containing the completed info for episode
    * @param o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param o_doc_not_register        Cursor containing the reason to not document the assessment
    * @param o_template_layouts        Cursor containing the layout for each template used
    * @param o_doc_area_component      Cursor containing the components for each template used 
    * @param o_record_count            Indicates the number of records that match filters criteria
    * @param o_groups                  Groups info: indicated the id_documentations that belongs to each group
    * @param o_scores                  Scores info    
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.5
    * @since                           06-01-2011
    *
    * DEPENDENCIES: REPORTS
    **********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_start_date         IN VARCHAR2 DEFAULT NULL,
        i_end_date           IN VARCHAR2 DEFAULT NULL,
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_groups             OUT pk_types.cursor_type,
        o_scores             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*  Returns the summary page values for the scale evaluation summary page with pagination
    *
    * @param    i_lang                    Language identifier
    * @param    i_prof                    Professional, software and institution identifiers
    * @param    i_doc_area                Documentation area identifier
    * @param    i_id_episode              Episode identifier; mandatory if i_flg_scope='E'
    * @param    i_scope                   Scope identifier (Episode identifier; Visit identifier; Patient identifier)
    * @param    i_flg_scope               Scope: P -patient; E- episode; V-visit
    * @param    i_paging                  Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param    i_start_record            First record. Just considered when paging is used. Default 1
    * @param    i_num_records             Number of records to be retrieved. Just considered when paging is used.  Default 20
    *
    * @param    o_doc_area_register       Cursor with the doc area info register
    * @param    o_doc_area_val            Cursor containing the completed info for episode
    * @param    o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param    o_doc_not_register        Cursor containing the reason to not document the assessment
    * @param    o_template_layouts        Cursor containing the layout for each template used
    * @param    o_doc_area_component      Cursor containing the components for each template used 
    * @param    o_record_count            Indicates the number of records that match filters criteria
    * @param    o_error                   Error message
    *
    * @return                             true (sucess), false (error)
    *
    * @value    i_flg_scope               {*} 'E'- Episode {*} 'P'- Patient {*} 'V'- Visit
    * @value    i_paging                  {*} 'Y'- Yes {*} 'N'- No
    *
    * @author                             Sofia Mendes
    * @version                            2.6.0.5
    * @since                              06-01-2011
    *
    * @author                             ANTONIO.NETO
    * @version                            2.6.2.1
    * @since                              16-May-2012
    **********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_flg_scope          IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 20,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_scales         OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the scores of the elements associated to an doc_area
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID    
    * @param o_score                   New documentation ID
    * @param o_groups                  Groups info
    * @param o_id_scales               Scales identifier
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           24-Mai-2011
    **********************************************************************************************/
    FUNCTION get_elements_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        o_score           OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_id_scales       OUT scales.id_scales%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_id_episode       Episode Id
    * @param i_doc_elements     Documentation element IDs of all template (total score) 
    *                           or the element of a block (partial score)
    * @param i_flg_score_type   P -partial score; T-total score
    * @param o_score            score (total or partial)
    * @param o_descs            List with the descritives
    * @param o_error            Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    /*FUNCTION get_score
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_doc_elements   IN table_number,
        i_flg_score_type IN VARCHAR2,
        o_score          OUT VARCHAR2,
        o_descs          OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;*/

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_doc_elements             Doc elements Ids
    * @param i_values                   Values inserted by the user for each doc_element
    * @param i_flg_score_type           'P' - partial score; T - total score.
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_main_scores              Main scores results
    * @param o_descs                    Scales decritions and complementary formulas results.
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_main_scores           OUT pk_types.cursor_type,
        o_descs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
    * Includes support for vital signs.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_prof_cat_type              Professional category
    * @param   i_epis                       Episode ID
    * @param   i_doc_area                   Documentation area ID
    * @param   i_doc_template               Touch-option template ID
    * @param   i_epis_documentation         Epis documentation ID
    * @param   i_flg_type                   Operation that was applied to save this entry
    * @param   i_id_documentation           Array with id documentation
    * @param   i_id_doc_element             Array with doc elements
    * @param   i_id_doc_element_crit        Array with doc elements crit
    * @param   i_value                      Array with values
    * @param   i_notes                      Free text documentation / Additional notes
    * @param   i_id_doc_element_qualif      Array with element quantifications/qualifications 
    * @param   i_epis_context               Context ID (Ex: id_interv_presc_det, id_exam...)
    * @param   i_summary_and_notes          Template's summary to be included in clinical notes
    * @param   i_episode_context            Context episode id  used in preoperative ORIS area by OUTP, INP, EDIS
    * @param   i_flg_table_origin           Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param   i_vs_element_list            List of template's elements ID (id_doc_element) filled with vital signs
    * @param   i_vs_save_mode_list          List of flags to indicate the applicable mode to save each vital signs measurement
    * @param   i_vs_list                    List of vital signs ID (id_vital_sign)
    * @param   i_vs_value_list              List of vital signs values
    * @param   i_vs_uom_list                List of units of measurement (id_unit_measure)
    * @param   i_vs_scales_list             List of scales (id_vs_scales_element)
    * @param   i_vs_date_list               List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param   i_vs_read_list               List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_flags                      List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                        List of ids: Scale, Documentation, Group
    * @param   i_scores                     List of calculated scores
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_id_epis_scales_score       The epis_scales_score ID created
    * @param   o_error                      Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_epis_doc_scales
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_epis_doc_scales
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_id_edit_reason        IN table_number,
        i_notes_edit            IN table_clob,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    *  Get the documentation actual info and the respective scores.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_epis_documentation    Epis documentation Id        
    * @param i_id_scales                Scales Id     
    * @param o_epis_doc_register        array with the detail info register
    * @param o_epis_document_val        array with detail of documentation
    * @param o_groups                   Groups info: indicated the id_documentations that belongs o each group
    * @param o_scores                   Scores info
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_scores_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        o_groups                OUT pk_types.cursor_type,
        o_scores                OUT pk_types.cursor_type,
        o_doc_area_register     OUT pk_types.cursor_type,
        o_epis_document_val     OUT pk_types.cursor_type,
        o_template_layouts      OUT pk_types.cursor_type,
        o_doc_area_component    OUT pk_types.cursor_type,
        o_record_count          OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the documentation info and respective scores in single page detail
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.5
    * @since                         30/08/2016 
    ***********************************************************************************************/
    FUNCTION get_scores_detail_pn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************************************
    * Get the documentation info and respective scores for history of changes in single page detail
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.5
    * @since                         30/08/2016 
    ***********************************************************************************************/
    FUNCTION get_scores_detail_pn_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_software_intern_name VARCHAR2(3);
    g_patient_active       VARCHAR2(0050);

    g_epis_stat_inactive VARCHAR2(0050);

    g_episode_flg_status_active   VARCHAR2(0050);
    g_episode_flg_status_temp     VARCHAR2(0050);
    g_episode_flg_status_canceled VARCHAR2(0050);
    g_episode_flg_status_inactive VARCHAR2(0050);

    g_seconds_in_a_day    NUMBER;
    g_hours_in_a_day      NUMBER;
    g_minutes_in_a_hour   NUMBER;
    g_seconds_in_a_minute NUMBER;

    g_flg_pos_executed  VARCHAR2(0050);
    g_flg_pos_requested VARCHAR2(0050);
    g_flg_pos_canceled  VARCHAR2(0050);
    g_outdated          VARCHAR2(0050);
    g_canceled          VARCHAR2(0050);
    g_active            VARCHAR2(0050);

    g_pos_status_domain      VARCHAR2(0050);
    g_pos_status_note_domain VARCHAR2(0050);

    g_separador   VARCHAR2(0500);
    g_scales_type VARCHAR2(3);

    g_available VARCHAR2(3);
    g_value_n   VARCHAR2(1) := 'N';
    g_found     BOOLEAN;
    g_error     VARCHAR2(4000);

    g_text     VARCHAR2(1);
    g_numeric  VARCHAR2(1);
    g_no_color VARCHAR2(1);

    g_exception EXCEPTION;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END;
/
