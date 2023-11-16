/*-- Last Change Revision: $Rev: 2028943 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_scales_core IS

    -- Author  : SOFIA.MENDES
    -- Created : 7/8/2011 2:22:51 PM
    -- Purpose : This package will contain the scales score transactional logic.

    -- Public type declarations
    TYPE t_rec_doc_scales IS RECORD(
        id_epis_documentation epis_documentation.id_epis_documentation%TYPE,
        id_scales             scales.id_scales%TYPE,
        id_doc_template       doc_template.id_doc_template%TYPE,
        desc_class            VARCHAR2(4000),
        doc_desc_class        VARCHAR2(4000),
        soma                  NUMBER(24),
        id_professional       professional.id_professional%TYPE,
        nick_name             professional.nick_name%TYPE,
        date_target           VARCHAR2(4000),
        hour_target           VARCHAR2(4000),
        dt_last_update        VARCHAR2(4000),
        dt_last_update_tstz   epis_documentation.dt_last_update_tstz%TYPE,
        flg_status            epis_documentation.flg_status%TYPE,
        signature             VARCHAR2(4000));

    TYPE t_coll_doc_scales IS TABLE OF t_rec_doc_scales;
    TYPE t_cur_doc_scales IS REF CURSOR RETURN t_rec_doc_scales;

    /**
    * Saves the calculated partial and/or total scores.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode ID
    * @param   i_id_epis_doc_old            Id_epis_documentation being updated    
    * @param   i_id_epis_doc_new            Id_epis_documentation created
    * @param   i_flags                      List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                        List of ids: Scale, Documentation, Group
    * @param   i_scores                     List of calculated scores
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    * @param   o_id_epis_scales_score       Epis scales score ID created
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
    FUNCTION set_epis_scales_score
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_doc_old      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_doc_new      IN epis_documentation.id_epis_documentation%TYPE,
        i_flags                IN table_varchar,
        i_ids                  IN table_number,
        i_scores               IN table_varchar,
        i_id_scales_formulas   IN table_number,
        i_dt_clinical          IN VARCHAR2 DEFAULT NULL,
        o_id_epis_scales_score OUT table_number,
        o_error                OUT t_error_out
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
    * @param   i_dt_clinical                Clinical date
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
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    -- Public function and procedure declarations
    /********************************************************************************************
    * Get all the calculated scores.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_epis_documentation   Epis documentation ID        
    * @param i_id_patient              Patient id
    * @param i_id_visit                Visit id
    * @param i_id_episode              Episode id
    * @param i_id_doc_area             Doc_area id
    * @param i_start_date              Begin date (optional)        
    * @param i_end_date                End date (optional)
    * @param o_scores                  Scores info
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           12-Jul-2011
    **********************************************************************************************/
    FUNCTION get_saved_scores
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_visit              IN visit.id_visit%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_doc_area           IN doc_area.id_doc_area%TYPE,
        i_start_date            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_scores                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the main score associated to an epis_documentation.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_epis_documentation   Epis documentation ID                
    * @param i_flg_summary             Y - The score should appear in the summary grid. N - otherwise
    *
    * @return                          Score value
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Jul-2011
    **********************************************************************************************/
    FUNCTION get_main_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_summary           IN scales_formula.flg_summary%TYPE DEFAULT pk_alert_constant.g_yes
    ) RETURN epis_scales_score.score_value%TYPE;

    /**************************************************************************
    * return list of scales for patient, episode or visit                     *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_doc_area               the doc_area id                         *
    * @param i_scope                  id_patient, id_visit or id_episode      *
    *                                 according to i_flg_scope                *
    * @param i_scope_type             P-id_patient, V -id_visit, E-id_episode *
    * @param i_coll_epis_doc          Table number with id_epis_documentation *   
    * @param i_start_date             Begin date (optional)                   *  
    * @param i_end_date               End date (optional)                     *
    *                                                                         *
    * @return                         return list of scales for patient       *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_scales_list
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_doc_area      IN NUMBER,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2 DEFAULT 'E',
        i_coll_epis_doc IN table_number DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN t_coll_doc_scales
        PIPELINED;

    /********************************************************************************************
    * Returns the info registered in the documentation regarding a patient, an episode or an visit.
    * For a patient scope: i_flg_scope = P and i_scope regards to id_patient
    * For a visit scope: i_flg_scope = V and i_scope regards to id_visit
    * For an episode scope: i_flg_scope = E and i_scope regards to id_episode    
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID
    * @param i_episode                the episode ID
    * @param i_scope                  Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type             Scope type (by episode; by visit; by patient)
    * @param i_coll_epis_doc          Table number with id_epis_documentation
    * @param i_start_date             Begin date (optional)        
    * @param i_end_date               End date (optional)
    * @param i_only_last              Only most updated record
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          06-Jan-2010
    **********************************************************************************************/
    FUNCTION get_scales_list
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_doc_area      IN NUMBER,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2 DEFAULT 'E',
        i_coll_epis_doc IN table_number DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_only_last     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_scales_list   OUT t_cur_doc_scales,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um paciente, relativamente às escalas
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID
    * @param i_episode                the episode ID
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2008/10/27
    **********************************************************************************************/
    FUNCTION get_scales_list_pat
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_doc_area    IN NUMBER,
        i_id_episode  IN NUMBER,
        o_scales_list OUT t_cur_doc_scales,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_MATCH_SCALES                   This function make "match" of scales scores of an episode
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 07-Apr-2011
    **********************************************************************************************/
    FUNCTION set_match_scales_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_MATCH_SCALES                   This function make "match" of scales scores of a patient
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_patient_temp               Temporary patient
    * @param i_id_patient                    Patient identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 07-Apr-2011
    **********************************************************************************************/
    FUNCTION set_match_scales_pat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient_temp IN patient.id_patient%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the scales associated to the doc_area.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID        
    * @param o_id_scales               Scales identifier
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           24-Mai-2011
    **********************************************************************************************/
    FUNCTION get_id_scales
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        o_id_scales       OUT scales.id_scales%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the documentation actual info and the respective scores.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_epis_documentation    Epis documentation Id        
    * @param i_id_scales                Scales Id    
    * @param o_groups                   Groups info: indicated the id_documentations that belongs o each group
    * @param o_scores                   Scores info
    * @param o_epis_doc_register        array with the detail info register
    * @param o_epis_document_val        array with detail of documentation
    * @param o_template_layouts         Cursor containing the layout for each template used
    * @param o_doc_area_component       Cursor containing the components for each template used 
    * @param o_record_count             Indicates the number of records that match filters criteria
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

    /********************************************************************************************
    *  Get the documented assessment scales description "Title: score"
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_episode                  Episode Id
    * @param i_id_scales                Scales Id
    * @param o_ass_scales               Cursor with description in the format: "Title: score"
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Nuno Alves
    * @version                         2.6.3.8.2
    * @since                           27-04-2015
    **********************************************************************************************/
    FUNCTION get_epis_ass_scales_scores
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_show_all_scores IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_tbl_ass_scales  OUT t_coll_desc_scales,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    *  Get the documented assessment scales description "Title: score"
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_episode                  Episode Id
    * @param i_id_scales                Scales Id
    * @param o_ass_scales               Cursor with description in the format: "Title: score"
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Nuno Alves
    * @version                         2.6.3.8.2
    * @since                           27-04-2015
    **********************************************************************************************/
    FUNCTION get_epis_ass_scales_scores
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_episode     IN table_number,
        i_show_all_scores IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_ass_scales      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Copy the scores of an epis_documentation to an epis_documentation equal to the previous one (Copy without changes option)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode ID
    * @param   i_id_epis_doc_old            Id_epis_documentation being updated    
    * @param   i_id_epis_doc_new            Id_epis_documentation created    
    * @param   o_id_epis_scales_score       Epis scales score created IDs
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   17-Oct-2011
    */
    FUNCTION set_copy_scores
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_doc_old      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_doc_new      IN epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score OUT table_number,
        o_error                OUT t_error_out
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
    FUNCTION tf_scales_list
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_epis_documentation IN table_number
    ) RETURN t_coll_doc_scales
        PIPELINED;

    FUNCTION cancel_scales_score_vs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    
    g_exception EXCEPTION;
    g_sysdate TIMESTAMP WITH LOCAL TIME ZONE;

END pk_scales_core;
/