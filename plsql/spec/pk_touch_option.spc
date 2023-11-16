/*-- Last Change Revision: $Rev: 2029015 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_touch_option AS

    -- Public type declarations
    TYPE t_rec_doc_area_register IS RECORD(
        order_by_default            INTERVAL DAY(9) TO SECOND,
        order_default               DATE,
        id_epis_documentation       epis_documentation.id_epis_documentation%TYPE,
        PARENT                      epis_documentation.id_epis_documentation_parent%TYPE,
        id_doc_template             doc_template.id_doc_template%TYPE,
        template_desc               pk_translation.t_desc_translation,
        dt_creation                 pk_translation.t_desc_translation,
        dt_creation_tstz            epis_documentation.dt_creation_tstz%TYPE,
        dt_register                 pk_translation.t_desc_translation,
        id_professional             professional.id_professional%TYPE,
        nick_name                   professional.nick_name%TYPE,
        desc_speciality             pk_translation.t_desc_translation,
        id_doc_area                 doc_area.id_doc_area%TYPE,
        flg_status                  epis_documentation.flg_status%TYPE,
        desc_status                 pk_translation.t_desc_translation,
        id_episode                  episode.id_episode%TYPE,
        flg_current_episode         VARCHAR2(1 CHAR),
        notes                       epis_documentation.notes%TYPE,
        dt_last_update              pk_translation.t_desc_translation,
        dt_last_update_tstz         epis_documentation.dt_last_update_tstz%TYPE,
        flg_detail                  VARCHAR2(1 CHAR),
        flg_external                VARCHAR2(1 CHAR),
        flg_type_register           VARCHAR2(1 CHAR),
        flg_table_origin            VARCHAR2(1 CHAR),
        flg_reviewed                VARCHAR2(1 CHAR),
        id_prof_cancel              epis_documentation.id_prof_cancel%TYPE,
        dt_cancel_tstz              epis_documentation.dt_cancel_tstz%TYPE,
        id_cancel_reason            epis_documentation.id_cancel_reason%TYPE,
        cancel_reason               pk_translation.t_desc_translation,
        cancel_notes                epis_documentation.notes_cancel%TYPE,
        flg_edition_type            epis_documentation.flg_edition_type%TYPE,
        nick_name_prof_create       professional.nick_name%TYPE,
        desc_speciality_prof_create pk_translation.t_desc_translation,
        dt_clinical                 epis_documentation.dt_clinical%TYPE,
        dt_clinical_rep             epis_documentation.dt_clinical%TYPE,
        signature                   VARCHAR2(4000));

    TYPE t_coll_doc_area_register IS TABLE OF t_rec_doc_area_register;
    TYPE t_cur_doc_area_register IS REF CURSOR RETURN t_rec_doc_area_register;

    TYPE t_rec_doc_area_val IS RECORD(
        id_epis_documentation epis_documentation.id_epis_documentation%TYPE,
        PARENT                epis_documentation.id_epis_documentation_parent%TYPE,
        id_documentation      documentation.id_documentation%TYPE,
        id_doc_component      doc_component.id_doc_component%TYPE,
        id_doc_element_crit   doc_element_crit.id_doc_element_crit%TYPE,
        dt_reg                pk_translation.t_desc_translation,
        desc_doc_component    pk_translation.t_desc_translation,
        flg_type              doc_component.flg_type%TYPE,
        desc_element          pk_translation.t_desc_translation,
        desc_element_view     pk_translation.t_desc_translation,
        VALUE                 VARCHAR2(32767),
        flg_type_element      doc_element.flg_type%TYPE,
        id_doc_area           doc_area.id_doc_area%TYPE,
        rank_component        documentation.rank%TYPE,
        rank_element          doc_element.rank%TYPE,
        internal_name         doc_element.internal_name%TYPE,
        desc_quantifier       pk_translation.t_desc_translation,
        desc_quantification   pk_translation.t_desc_translation,
        desc_qualification    pk_translation.t_desc_translation,
        display_format        doc_element.display_format%TYPE,
        separator             doc_element.separator%TYPE,
        flg_table_origin      VARCHAR2(1 CHAR),
        flg_status            epis_documentation.flg_status%TYPE,
        value_id              epis_documentation_det.value%TYPE,
        signature             VARCHAR2(4000));
    TYPE t_coll_doc_area_val IS TABLE OF t_rec_doc_area_val;
    TYPE t_cur_doc_area_val IS REF CURSOR RETURN t_rec_doc_area_val;

    TYPE t_coll_doc_area_inst_soft IS TABLE OF doc_area_inst_soft%ROWTYPE;

    TYPE t_rec_last_elem_val IS RECORD(
        id_doc_element    doc_element.id_doc_element%TYPE,
        internal_name     doc_element.internal_name%TYPE,
        flg_type          doc_element.flg_type%TYPE,
        desc_component    pk_translation.t_desc_translation,
        desc_element      pk_translation.t_desc_translation,
        desc_element_view pk_translation.t_desc_translation,
        VALUE             epis_documentation_det.value%TYPE,
        value_properties  epis_documentation_det.value_properties%TYPE,
        formatted_value   VARCHAR2(32767),
        id_content        doc_element.id_content%TYPE);
    TYPE t_coll_last_elem_val IS TABLE OF t_rec_last_elem_val;

    PROCEDURE open_cur_doc_area_register(i_cursor IN OUT t_cur_doc_area_register);
    PROCEDURE open_cur_doc_area_val(i_cursor IN OUT t_cur_doc_area_val);

    /******************************************************************************************
    * Retrieves a list of default templates 
    *                                                                                                                                          
    * @param i_lang              Language ID                                                                                              
    * @param i_prof              Professional, software and institution ids
    * @param i_episode           Episode identifier
    * @param o_id_doc_template   Default template identifier
    * @param o_desc_doc_template Default template name
    * @param o_error             Error object
    *                                                                                                                                         
    * @return                    true (sucess), false (error)                                                        
    * 
    * @notes                     (only developed for the 'CT' flg_type)
    *                                                                                                                   
    * @author                    Sérgio Santos
    * @version                   2.5                                                                                                     
    * @since                     2009/06/18                                                                                               
    ********************************************************************************************/
    FUNCTION get_default_template
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_id_doc_template   OUT doc_template.id_doc_template%TYPE,
        o_desc_doc_template OUT pk_translation.t_desc_translation,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Indica para uma dada doc_area se se usa interacção o texto liver, ou documentation
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_id_doc_area          id da doc_area
    * @param o_flg_mode             flag com valores possivel D (documentation) ou N (texto livre)
    * @param o_flg_switch_mode      flag com valores possivel Y (Alternancia entre touch option e free text) 
                                                              N (Não há alternância entre touch option e free text)
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       João Eiras
    * @version                      1.0   
    * @since                        23-05-2007
    ********************************************************************************************/
    FUNCTION get_touch_option_mode
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        o_flg_mode        OUT VARCHAR2,
        o_flg_switch_mode OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve a lista de doc_area a que este profissional tem acesso, mediante software e instituição, 
      e os respectivos valores das preferencias do
      metodo de input (documentation ou texto livre)
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_institution          id da instituição de onde se le a preferencia
    * @param i_software             id do software onde é apresentada a doc_area
    * @param o_options              cursor com doc_areas e preferencias
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    *
    * @author                       João Eiras
    * @version                      1.0   
    * @since                        24-05-2007
    **********************************************************************************************/
    FUNCTION get_prof_touch_options_mode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        o_options     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Guarda as preferencias do metodo de input preferido do profissional para um conjunto de doc areas, 
      mediante software e instituição.Utilizado no backoffice do utilizador
    *
    * @param i_lang           id da lingua
    * @param i_prof           objecto com info do utilizador
    * @param i_institution    id da instituição de onde se le a preferencia
    * @param i_software       id do software onde é apresentada a doc_area
    * @param i_doc_areas      table_number com ids das doc_areas
    * @param i_flg_modes      table_varchar com metodo de input preferido para a respectiva doc_area
    * @param o_error          Error message
    *                        
    * @return                 true or false on success or error
    *
    * @author                 João Eiras
    * @version                1.0   
    * @since                  24-05-2007
    **********************************************************************************************/
    FUNCTION set_prof_touch_options_mode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institutions IN table_number,
        i_softwares    IN table_number,
        i_doc_areas    IN table_number,
        i_flg_modes    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Indica se um profissional fez registos numa dada doc_area num dado episódio no caso afirmativo, 
      devolve a ultima documentation
    *
    * @param i_lang                id da lingua
    * @param i_prof                utilizador autenticado
    * @param i_episode             id do episódio 
    * @param i_doc_area            id da doc_area da qual se verificam se foram feitos registos
    * @param o_last_prof_epis_doc  Last documentation episode ID to profissional
    * @param o_date_last_epis      Data do ultimo episódio
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *                        
    * @return                      true or false on success or error
    *
    * @author                      João Eiras
    * @version                     1.0    
    * @since
    **********************************************************************************************/
    FUNCTION get_prof_doc_area_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis     OUT epis_documentation.dt_creation_tstz%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks if a doc area has registers by an episode / patient.
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_episode         episode id 
    * @param i_doc_area        doc area id 
    * @param i_patient         [Optional] patient id (default NULL)
    * @param i_flg_by          [Optional] check by Episode / Patient
    * @param o_flg_data        Y if there are data, F when no date found
    * @param o_error           Error message
    *
    * @value i_flg_by          {*} 'E' - Check by episode (default) {*} 'P' - Check by patient                        
    *
    * @return                  true or false on success or error
    *
    * @author                  Luís Gaspar 
    * @version                 1.0                    
    * @since                   24-05-2007
    *
    * Changes:
    *
    * @author                  Ariel Machado 
    * @version                 2.4.3                    
    * @since                   15-07-2008
    * reason                   Filter by episode/patient. Added i_patient and i_flg_by
    * @Deprecated : get_doc_area_exists (with i_scope_type) should be used instead. 
    **********************************************************************************************/
    FUNCTION get_doc_area_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        i_flg_by   IN VARCHAR2 DEFAULT 'E',
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Checks if at least one of a set of areas has entries according an input scope.
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_doc_area_list List of documentation area IDs
    * @param   i_scope         Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type    Scope type (by episode; by visit; by patient)
    * @param   o_flg_data      There exists entries (Y/N)
    * @param   o_error         Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    * @value o_flg_data {*} (Y) There are entries {*} (N) There are no entries
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   12/6/2010
    */
    FUNCTION get_doc_area_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area_list IN table_number,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2 DEFAULT 'E',
        o_flg_data      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Lists doc_components, doc_elements, doc_element_crits, actions ,relations between them
      in order, doc_element_qualif and doc_qualif_rel to build a screen representing part (doc_area) of a template (doc_template).
    *
    * @param i_lang                      language id
    * @param i_prof                      professional, software and institution ids
    * @param i_patient                   the patient id
    * @param i_episode                   the episode id
    * @param i_doc_area                  doc_area id
    * @param i_doc_template              doc_template id
    * @param o_component                 cursor with the components info
    * @param o_element                   cursor with elements info
    * @param o_element_status            cursor with element status info
    * @param o_element_action            cursor with elements status actions (by criteria)
    * @param o_element_exclusive         cursor with elements relations
    * @param o_element_qualif            cursor with elements qualification
    * @param o_element_qualif_exclusive  cursor with elements qualification relations        
    * @param o_element_domain            cursor with elements domain (case flg_element_domain_type is S-sys_domain or T-element_domain)
    * @param o_element_function_param    cursor with elements function params (case flg_element_domain_type is D has have parameters)
    * @param o_element_related_actions   cursor with actions between elements (by elements)
    * @param o_template_layout           cursor whth XML layout to be applied
    * @param o_template_actions_menu     cursor with Action button menu
    * @param o_vs_info                   cursor with vital sign-related information
    * @param o_element_crit_interval     cursor with value intervals of an element and associated description to be used instead of its description
    * @param o_error                     Error message
    *                        
    * @return                            true or false on success or error
    *
    * @author                            Luís Gaspar e Luís Oliveira, based on pk_documentation.get_component_list
    * @version                           1.0    
    * @since                             26-05-2007
    *
    * @author alter                      Emilia Taborda 
    * @since                             2007/08/29
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/19
    *                             Element domain and function parameters. New fields for component/element fill behavior;
    *
    *                             Ariel Machado
    *                             1.2   
    *                             2009/03/18
    *                             Template layout and actions between elements
    **********************************************************************************************/
    FUNCTION get_component_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_doc_area                 IN doc_area.id_doc_area%TYPE,
        i_doc_template             IN doc_template.id_doc_template%TYPE,
        o_component                OUT pk_types.cursor_type,
        o_component_action         OUT pk_types.cursor_type,
        o_element                  OUT pk_types.cursor_type,
        o_element_status           OUT pk_types.cursor_type,
        o_element_action           OUT pk_types.cursor_type,
        o_element_exclusive        OUT pk_types.cursor_type,
        o_element_qualif           OUT pk_types.cursor_type,
        o_element_qualif_exclusive OUT pk_types.cursor_type,
        o_element_domain           OUT pk_types.cursor_type,
        o_element_function_param   OUT pk_types.cursor_type,
        o_element_related_actions  OUT pk_types.cursor_type,
        o_template_layout          OUT pk_types.cursor_type,
        o_template_actions_menu    OUT pk_types.cursor_type,
        o_vs_info                  OUT pk_types.cursor_type,
        o_element_crit_interval    OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
      Allows for new, edit and agree epis documentation.
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
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Luís Gaspar e Luís Oliveira, based on pk_documentation.set_epis_bartchart
    * @version                            1.0   
    * @since                              26-05-2007
    *
    * @author alter                       Emilia Taborda
    * @since                              2007/08/29
    *
    * @Deprecated : set_epis_documentation (with vital signs support) should be used instead.
    **********************************************************************************************/
    FUNCTION set_epis_documentation
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
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
    Includes support for vital signs.
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
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_error                      Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/29/2011
    */
    FUNCTION set_epis_documentation
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
        i_id_edit_reason        IN table_number,
        i_notes_edit            IN table_clob,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_epis_documentation
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
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /**
      Sets documentation values associated with an area (doc_area) of a template (doc_template). 
      Includes support for vital signs.
      Does not perform COMMIT transaction.
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
      * @param   i_flg_status                 Entry status. Default: (A)ctive
      * @param   i_dt_creation                Creation date. Default: current timestamp
      * @param   i_vs_element_list            List of template's elements ID (id_doc_element) filled with vital signs
      * @param   i_vs_save_mode_list          List of flags to indicate the applicable mode to save each vital signs measurement
      * @param   i_vs_list                    List of vital signs ID (id_vital_sign)
      * @param   i_vs_value_list              List of vital signs values
      * @param   i_vs_uom_list                List of units of measurement (id_unit_measure)
      * @param   i_vs_scales_list             List of scales (id_vs_scales_element)
      * @param   i_vs_date_list               List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
      * @param   i_vs_read_list               List of saved vital sign measurement (id_vital_sign_read)
      * @param   o_epis_documentation         The epis_documentation ID created
      * @param   o_error                      Error message
      *
      * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
      * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION (default) {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
      * @value i_flg_status                  {*} 'A'  Active (default) {*} 'O' Outdated {*} 'C' Cancelled
      * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
      *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/30/2011
    */
    FUNCTION set_epis_document_internal
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
        i_id_epis_complaint     IN epis_complaint.id_epis_complaint%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_flg_status            IN epis_documentation.flg_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_dt_creation           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver os valores registados numa área(doc_area) para um episódio
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_epis_document     the documentation episode id
    * @param o_epis_document     array with values of documentation    
    * @param o_vs_info           cursor with values of vital_sign documentation
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda, based on pk_documentation.get_epis_bartchart
    * @version                   1.0    
    * @since                     2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    *
    *                             Ariel Machado
    *                             1.2 (2.4.3)
    *                             2008/05/30
    *                             Returns dynamics element's domain from functions and sysdomain
    ********************************************************************************************/
    FUNCTION get_epis_documentation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_document   IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_document   OUT pk_types.cursor_type,
        o_element_domain  OUT pk_types.cursor_type,
        o_vs_info         OUT pk_types.cursor_type,
        o_additional_info OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver os valores, registados,associados a uma área(doc_area) e a um template (doc_template) para um episódio. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_epis_document     the documentation episode id
    * @param o_epis_document     array with values of documentation
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda, based on pk_documentation.get_epis_bartchart
    * @version                   1.0    
    * @since                     2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    *
    *                             Ariel Machado
    *                             1.2 (2.4.3)
    *                             2008/05/30
    *                             Returns element's domain from functions and sysdomain
    ********************************************************************************************/
    FUNCTION get_epis_documentation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_document  IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_document  OUT pk_types.cursor_type,
        o_element_domain OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver o profissional que efectou a ultima alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Cursor containing the last update register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0   
    * @since                          2007/05/30
    * @Deprecated : get_epis_document_last_update(with i_scope_type) should be used instead.
    **********************************************************************************************/
    FUNCTION get_epis_document_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Cancelar um episódio documentation 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Indica se deve mostrar a confirmaçãoo de alteração
    * @param i_cancel_reason          Cancel reason ID. Default NULL
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
    **********************************************************************************************/
    FUNCTION cancel_epis_doc_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis_doc   IN epis_documentation.id_epis_documentation%TYPE,
        i_notes         IN VARCHAR2,
        i_test          IN VARCHAR2,
        i_cancel_reason IN epis_documentation.id_cancel_reason%TYPE DEFAULT NULL,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel an episode documentation
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Indica se deve mostrar a confirmação de alteração
    * @param i_cancel_reason          Cancel reason ID. Default NULL
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
    **********************************************************************************************/
    FUNCTION cancel_epis_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis_doc   IN epis_documentation.id_epis_documentation%TYPE,
        i_notes         IN VARCHAR2,
        i_test          IN VARCHAR2,
        i_cancel_reason IN epis_documentation.id_cancel_reason%TYPE DEFAULT NULL,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Cancelar um episódio documentation 
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
    * @author                         Emília Taborda,, based on pk_documentation.sr_cancel_epis_documentation
    * @version                        1.0   
    * @since                          2007/06/01
    * @Deprecated : cancel_epis_documentation (with i_cancel_reason) should be used instead. 
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
    --
    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_document      the documentation episode id
    * @param i_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    ********************************************************************************************/
    FUNCTION get_epis_documentation_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns previous records done in a component for defined scope and filter criteria
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_flg_show          Applied filter for previous records
    * @param i_documentation     Component ID      
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional     
    * @param o_prev_records      Cursor containing info about previous records done 
    * @param o_error             Error message
    *                        
    * @value i_flg_show          {*} 'SA' - Show All previous records {*} 'SL' - Show Last previous record {*} 'SM' - Show My previous records {*} 'SML' - Show My Last previous record
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    ********************************************************************************************/
    FUNCTION get_document_previous_records
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_flg_show      IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Returns all previous records done in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about previous records
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_all
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Returns last previous record done in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about last previous record
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_last
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Returns all previous records done by current professional in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about all previous records done by professional
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_my
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Returns the last previous record done by current professional in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about the last previous record done by professional
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_may_last
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if a advanced directives has registers in an episode.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_doc_area          the doc area id    
    * @param o_advanced          array with info advanced directives
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda
    * @version                   1.0    
    * @since                     2007/07/18
    ********************************************************************************************/
    FUNCTION get_advanced_directives_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_advanced OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the touch option mode type for the given professional and doc area
    *
    * @param i_prof              professional, software and institution ids
    * @param i_doc_area          documentation area
    *
    * @return                    the touch option mode type
    *
    * @author                    Eduardo Lourenco
    * @version                   2.5.0.7.2
    * @since                     2009/11/21
    */
    FUNCTION get_touch_option_type
    (
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param o_templates         A cursor with the doc templates
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Luís Gaspar
    * @version                   1.0
    * @since                     2007/08/31
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/04/03
    *                             Added i_flg_type parameter
    *
    * @deprecated Use get_doc_template_list with id_doc_area argument instead.
    ********************************************************************************************/
    FUNCTION get_doc_template_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN doc_template_context.flg_type%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Sets a new doc template list to the episode. Calls set_epis_doc_templ_no_commit.
    *
    * @param i_lang                   language id
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the episode id
    * @param i_doc_template_in        the new doc templates id selected
    * @param i_epis_doc_template_out  the existing epis doc templates id to cancel
    * @param o_epis_doc_template      The new epis_doc_template ids created
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2007/10/16
    ********************************************************************************************/
    FUNCTION set_epis_doc_template_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_template_in       IN table_number,
        i_epis_doc_template_out IN table_number,
        o_epis_doc_template     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Sets a new doc template list to the episode. Calls set_epis_doc_templ_no_commit.
    *
    * @param i_lang                   language id
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the episode id
    * @param i_doc_template_in        the new doc templates id selected
    * @param i_epis_doc_template_out  the existing epis doc templates id to cancel
    * @param i_doc_area               Doc area identifier
    * @param o_epis_doc_template      The new epis_doc_template ids created
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2007/10/16
    ********************************************************************************************/
    FUNCTION set_epis_doc_template_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_template_in       IN table_number,
        i_epis_doc_template_out IN table_number,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        o_epis_doc_template     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --    
    /********************************************************************************************
    * Sets a new doc template list to the episode.
    *
    * @param i_lang                   language id
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the episode id
    * @param i_doc_template_in        the new doc templates id selected
    * @param i_epis_doc_template_out  the existing epis doc templates id to cancel
    * @param o_epis_doc_template      The new epis_doc_template ids created
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author                         Luís Gaspar
    * @version                        1.0   
    * @since                          2007/08/31
    ********************************************************************************************/
    FUNCTION set_epis_doc_templ_no_commit
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_template_in       IN table_number,
        i_epis_doc_template_out IN table_number,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        o_epis_doc_template     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Sets the default touch option templates. 
    * An episode migth have several default templates, one for each profile_template
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_episode            the episode id
    * @param i_flg_type           type of identifier
    * @param o_epis_doc_templates An array with the touch option templates associated to the episode
    * @param o_error              Error message
    *
    * @value i_flg_type  {*} 'C' Complaint {*} 'I' Intervention {*} 'A' Appointment {*} 'D' Doc area {*} 'S' Specialty {*} 'E' Exam {*} 'T' Schedule event {*} 'M' Medication
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Luís Gaspar
    * @version                    1.0   
    * @since                      2007/08/31
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/04/03
    *                             Added i_flg_type parameter
    ********************************************************************************************/
    FUNCTION set_default_epis_doc_templates
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN doc_template_context.flg_type%TYPE,
        o_epis_doc_templates OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets doc_template for any criteria. 
    * Currently criterias are obtained from i_doc_area and i_episode.
    * When needed new criterias, (name X value) pairs might be added as input parameters.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           the patient id,
    * @param i_episode           the episode id,
    * @param i_doc_area          the doc_area id
    * @param i_context           the context id
    * @param o_doc_template      the doc template id
    *
    *
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Luís Gaspar 
    * @since                     14-Set-2007
    * @version                   1.0
    **********************************************************************************************/
    FUNCTION get_doc_template
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Obter softwares a que o utilizador tem acesso        
    *
    * @param i_lang id da lingua
    * @param i_prof objecto do utilizador
    * @param i_inst id da instituição
    * @param o_list lista de softwares
    * @param o_erro variavel com mensagem de erro
    * @return                    true (sucess), false (error)
    *
    * @author João Eiras, 26-09-2007
    * @since 2.4.0
    * @version 1.0
    */
    FUNCTION get_touch_option_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve a ultima documentation de um episódio
    *
    * @param i_lang                id da lingua
    * @param i_prof                utilizador autenticado
    * @param i_episode             id do episódio
    * @param i_doc_area            id da doc_area da qual se verificam se foram feitos registos
    * @param o_last_epis_doc       Last documentation episode ID 
    * @param o_last_date_epis_doc  Data do ultimo episódio
    * @param o_error               Error message
    *                        
    * @return                      true or false on success or error
    *
    * @autor                       Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/01
    *
    * @deprecated                  Use get_last_doc_area with i_doc_template=NULL instead 
    **********************************************************************************************/
    /*
    FUNCTION get_last_doc_area
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    */
    --
    /********************************************************************************************
    * Returns last documentation for an area, episode and template(optional)
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_doc_area            Area ID where check if registers were done
    * @param i_doc_template        (Optional) Template ID. Null = All templates
    * @param o_last_epis_doc       Last documentation ID 
    * @param o_last_date_epis_doc  Date of last epis documentation
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @autor                       Ariel Machado (based on Emilia Taborda code)
    * @version                     1.0
    * @since                       2009/03/19
    **********************************************************************************************/
    FUNCTION get_last_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets doc_template for any criteria. 
    * Currently criterias are obtained from i_doc_area and i_episode.
    * When needed new criterias, (name X value) pairs might be added as input parameters.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           the patient id,
    * @param i_episode           the episode id,
    * @param i_doc_area          the doc_area id
    * @param i_context           the context id
    *
    * @return                    number
    *
    * @author                    Emilia Taborda 
    * @version                   1.0
    * @since                     2007/10/15
    **********************************************************************************************/
    FUNCTION get_doc_template_internal
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_context  IN doc_template_context.id_context%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Checks if an episode has template
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      José Silva (replacing pk_complaint.get_complaint_template_exists)
    * @version                     1.0
    * @since                       22-10-2007
    **********************************************************************************************/
    FUNCTION get_template_exists
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        o_flg_data              OUT VARCHAR2,
        o_sys_shortcut          OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_default_template   OUT doc_template.id_doc_template%TYPE,
        o_desc_default_template OUT pk_translation.t_desc_translation,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Detalhe de um episódio de documentation num dado contexto.
      Ex de contexto: Intervention; Exam; Analysis; Drugs
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_context       array with id_epis_context
    * @param i_doc_area           documentation area
    * @param o_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/10/23
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/05
    *                             Added i_doc_area parameter
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer
    ********************************************************************************************/
    FUNCTION get_epis_documentation_context
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_context      IN table_number,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detalhe de um episódio de documentation num dado contexto.
      Ex de contexto: Intervention; Exam; Analysis; Drugs
    *
    * @param i_lang               language id
    * @param i_prof_id            professional
    * @param i_prof_inst          institution
    * @param i_prof_soft          software
    * @param i_epis_context       array with id_epis_context
    * @param i_doc_area           documentation area
    * @param o_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Rui Spratley
    * @version                    2.4.1.0   
    * @since                      2007/12/04
    *
    * Changes:
    *                             Ariel Machado
    *                             2.4.3  
    *                             2008/05/05
    *                             Added i_doc_area parameter
    ********************************************************************************************/
    FUNCTION get_epis_doc_context_reports
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN NUMBER,
        i_prof_inst         IN NUMBER,
        i_prof_soft         IN NUMBER,
        i_epis_context      IN table_number,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks if an episode has template
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @i_flg_type                  flg_type 
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Carlos Ferreira 
    * @version                     1.0
    * @since                       15-05-2008
    **********************************************************************************************/
    FUNCTION get_template_exists
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_flg_type              IN doc_area_inst_soft.flg_type%TYPE,
        o_flg_data              OUT VARCHAR2,
        o_sys_shortcut          OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_default_template   OUT doc_template.id_doc_template%TYPE,
        o_desc_default_template OUT pk_translation.t_desc_translation,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets doc_template for any criteria. 
    * Currently criterias are obtained from i_doc_area and i_episode and i_flg_type.
    * When needed new criterias, (name X value) pairs might be added as input parameters.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           the patient id,
    * @param i_episode           the episode id,
    * @param i_doc_area          the doc_area id
    * @param i_context           the context id
    * @param i_flg_type          indica tipo de acesso Touch option
    
    * @param
    * @param o_doc_template      the doc template id
    *
    *
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Carlos Ferreira
    * @since                     14-05-2008
    * @version                   1.0
    **********************************************************************************************/
    FUNCTION get_doc_template
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_flg_type  IN doc_area_inst_soft.flg_type%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list of selected doc templates to an episode.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_flg_type          indica tipo de acesso Touch option
    * @param o_templates         A cursor with the doc templates
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Carlos Ferreira
    * @version                   1.0   
    * @since                     2008/05/15
    ********************************************************************************************/

    FUNCTION get_selected_doc_template_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN doc_template_context.flg_type%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE DEFAULT NULL,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a element domain info about a code_element_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param o_element_domain         Element domain list                                                                                      
    * @param o_error                  Output error                                                                                             
    *                                                                                                                                          
    *                                                                                                                                          
    * @return                         Return false if exist an error and true otherwise                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_element_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_code_element_domain IN doc_element_domain.code_element_domain%TYPE,
        o_element_domain      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a description about a value for code_element_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param i_val                    Element domain value                                                                                      
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_element_desc_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_code_element_domain IN doc_element_domain.code_element_domain%TYPE,
        i_val                 IN doc_element_domain.val%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns concatenate descriptions about a set of values separated by delimiter for code_element_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param i_vals                   Element domain values separated by i_delim_in (e.g. 1|2|3)                                                                                       
    * @param i_delim_in               Input delimiter(e.g. '|')                                                                                       
    * @param i_delim_out              Output delimiter(e.g. ';')                                                                                       
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_element_desc_domain_set
    (
        i_lang                IN language.id_language%TYPE,
        i_code_element_domain IN doc_element_domain.code_element_domain%TYPE,
        i_vals                IN VARCHAR2,
        i_delim_in            IN VARCHAR2 DEFAULT '|',
        i_delim_out           IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a description about a value for a dynamic domain function                                                                                                 
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_doc_function           Function ID (name)                                                                                        
    * @param i_val                    Element domain value                                                                                      
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/20                                                                                               
    ********************************************************************************************/

    FUNCTION get_dynamic_desc_domain
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_function IN doc_function.id_doc_function%TYPE,
        i_val          IN doc_element_domain.val%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns concatenate descriptions about a set of values separated by delimiter for dynamic domain function                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_doc_function           Function ID (name)                                                                                                                                                                                
    * @param i_vals                   Element domain values separated by i_delim_in (e.g. 1|2|3)                                                                                       
    * @param i_delim_in               Input delimiter(e.g. '|')                                                                                       
    * @param i_delim_out              Output delimiter(e.g. ';')                                                                                       
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_dynamic_desc_domain_set
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_function IN doc_function.id_doc_function%TYPE,
        i_vals         IN VARCHAR2,
        i_delim_in     IN VARCHAR2 DEFAULT '|',
        i_delim_out    IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if the elements of a template has translations
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids
    * @param i_doc_area               Doc area
    * @param i_doc_template           Template                                                                                       
    * @param o_is_translated          Output about template translation status
    *                                                                                                                                         
    * @return                         true or false on success or error                                                        
    *                                                                                                                          
    * @value o_is_translated          {*} 'Y'  Has translations {*} 'N' Has no translations  
                   
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/07/25                                                                                               
    ********************************************************************************************/
    FUNCTION get_template_translated
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        o_is_translated OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Extracts the value through the type of element. Example: for element of type numeric with 
    * unit of measure (UOM) it can strip the UOM ID, retuning the numeric value only
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Current profissional
    * @param i_element_type           Element type (Comp. element date, etc.)
    * @param i_element_value          Element value
    * 
    * @return                         Value from element value
    *
    * @author                         Ariel Geraldo Machado
    * @version                        2.5
    * @since                          25/Jun/2009
    **********************************************************************************************/
    FUNCTION get_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_element_type  IN doc_element.flg_type%TYPE,
        i_element_value IN epis_documentation_det.value%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Extracts the properties for value through the type of element, 
    * example: for elements of type date it returns time zone property.
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids
    * @param i_element_type           Element type (Comp. element date, etc. )
    * @param i_element_value          Element value
    * @param i_element                Element ID
    * @param i_element_vs_list        List of elements ID and respective collection of saved vital sign measurement
    *                                                                                                                                         
    * @return                         Value properties from element value                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/01/26                                                                                               
    ********************************************************************************************/
    FUNCTION get_value_properties
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_element_type    IN doc_element.flg_type%TYPE,
        i_element_value   IN epis_documentation_det.value%TYPE,
        i_element         IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_element_vs_list IN pk_touch_option_ti.t_coll_doc_element_vs DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a timestamp that represents the element value
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_doc_element_crit       Element criteria ID
    * @param i_epis_documentation     The documentation episode id
    *
    * @return                         A timestamp value
    *                                                                                                                          
    * @author                         José Silva                                                                              
    * @version                        1.0 (2.5)                                                                                                     
    * @since                          2009/05/06                                                                                               
    ********************************************************************************************/
    FUNCTION get_value_tstz
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_element_crit   IN doc_element_crit.id_doc_element_crit%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /********************************************************************************************
    * Returns the date formats used in Touch-option templates 
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    *                                                                                                                                         
    * @param o_date_formats           Date formats
    * @param o_error                  Error message
    *
    * @return                         True or False on success or error
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/01/26                                                                                               
    ********************************************************************************************/
    FUNCTION get_date_formats
    (
        i_lang         language.id_language%TYPE,
        i_prof         profissional,
        o_date_formats OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the date type stored in the element value
    * 
    * @param i_value                  Element value                                                                                              
    *
    * @return                         Element date type (See pk_touch_option.k_touchoption_date_types)
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/01/26                                                                                               
    ********************************************************************************************/
    FUNCTION get_date_type(i_value IN epis_documentation_det.value%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a formatted string that represents the element value
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_type                   Element type
    * @param i_value                  Element value
    * @param i_properties             Properties for the element value 
    * @param i_input_mask             Input mask used by element to introduce the value
    * @param i_optional_value         Element value may be optional
    * @param i_domain_type            Element domain type
    * @param i_code_element_domain    Element domain code
    * @param i_dt_creation            Timestamp of template's element (Optional)
    * @return                         A formatted string value
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/02                                                                                               
    ********************************************************************************************/
    FUNCTION get_formatted_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_type                IN doc_element.flg_type%TYPE,
        i_value               IN epis_documentation_det.value%TYPE,
        i_properties          IN epis_documentation_det.value_properties%TYPE,
        i_input_mask          IN doc_element.input_mask%TYPE,
        i_optional_value      IN doc_element.flg_optional_value%TYPE,
        i_domain_type         IN doc_element.flg_element_domain_type%TYPE,
        i_code_element_domain IN doc_element.code_element_domain%TYPE,
        i_dt_creation         IN epis_documentation_det.dt_creation_tstz%TYPE := NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a string that represents the date value at institution timezone
    * The i_value and returned string are in Flash/DB interchange format with partial date support
    * ( <date_value>|<date_type>)
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_value                  Element value (<date_value>|<date_type>)
    * @param i_properties             Properties for the element value 
    *
    * @return                         A <date_value>|<date_type> string at timezone institution
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/04                                                                                               
    ********************************************************************************************/
    FUNCTION get_date_value_insttimezone
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN epis_documentation_det.value%TYPE,
        i_properties IN epis_documentation_det.value_properties%TYPE
        
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns available actions info for Action Button" relatated menu 
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_doc_area               Area ID
    * @param i_doc_template           Template ID 
    * @param o_template_actions       Actions info 
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/03/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_template_actions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_doc_template     IN doc_template.id_doc_template%TYPE,
        o_template_actions OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the value of specific elements from last documentation for an area, episode and template
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_doc_area            Area ID where check if registers were done
    * @param i_doc_template        (Optional) Template ID. Null = All templates
    * @param i_table_element_keys  Array of elements keys to retrieve their values
    * @param i_key_type            Type of key (ID, Internal Name, ID Content, etc)
    * @param o_last_epis_doc       Last documentation ID 
    * @param o_last_date_epis_doc  Date of last epis documentation
    * @param o_element_values      Element values
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @value i_key_type  {*} 'K' Element's key (id_doc_element) {*} 'N' Element's internal name 
    *
    * @autor                       Ariel Machado
    * @version                     1.0
    * @since                       2009/03/19
    **********************************************************************************************/
    FUNCTION get_last_doc_area_elem_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        i_table_element_keys IN table_varchar,
        i_key_type           IN VARCHAR2,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_element_values     OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_episode            the documentation episode id
    * @param i_doc_area           the doc_area id
    * @param o_epis_last_template array with the episodes templates    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Teresa Coutinho
    * @version                    1.0   
    * @since                      2009/03/18
    *     
    ********************************************************************************************/
    FUNCTION get_epis_last_templates_doc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_doc_area            IN table_number,
        o_epis_last_templates OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_document      the documentation episode id
    * @param i_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    ********************************************************************************************/
    FUNCTION get_epis_documentation_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document     IN table_number,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************
    * Gets the question concatenated with the actual answer for a specific                    *
    * id_epis_documentation and id_doc_component                                              *                
    *                                                                                         *
    * @param i_lang                       language id                                         *
    * @param i_prof                       professional, software and                          *
    *                                     institution ids                                     *
    * @param i_epis_documentation         epis documentation id                               *
    * @param i_doc_component              doc component id                                    *
    * @param i_is_bold                    should component be bold? (DEFAULT YES)             *
    * @param i_has_title                  should component title be shown (DEFAULT YES)       *
    * @return                         Returns concatenated string                             *
    *                                                                                         *
    * @author                         Gustavo Serrano                                         *
    * @version                        1.0                                                     *
    * @since                          2009/10/14                                              *
    ******************************************************************************************/
    FUNCTION get_epis_doc_component_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_component      IN doc_component.id_doc_component%TYPE,
        i_is_bold            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_has_title          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Updates the list of complaint's templates to be used by episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_episode                   Episode ID
    * @param i_epis_complaint            Epis_Complaint ID (default NULL)
    * @param i_do_commit                 Transaction Commit? (default YES)
    * @param o_error                     Error message
                     
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   27-Oct-09
    **********************************************************************************************/
    FUNCTION update_epis_tmplt_by_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_complaint IN epis_complaint.id_epis_complaint%TYPE DEFAULT NULL,
        i_do_commit      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gives information about the latest update done in a set of doc_areas that use touch-option templates framework to save records.
    * This function lets you set the scope of latest update: per patient, visit or episode.
    *
    * @param i_lang         Language ID
    * @param i_prof         Current professional
    * @param i_scope_type   Scope type (by Patient, by Visit, by Episode)
    * @param i_scope        Scope ID (id_patient, id_visit, id_episode)
    * @param i_doc_area     Array with doc_area IDs
    * @param o_last_update  Cursor containing information about last update
    *
    * @param o_error        Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10
    */
    FUNCTION get_epis_document_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope_type  IN VARCHAR2,
        i_scope       IN NUMBER,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a full phrase associated to an element quantified
    *
    * @param   i_lang         Professional preferred language
    * i_epis_document_det     Documentation detail ID
    *
    * @return  Full phrase associated with the element quantified (example: "Mild pain")
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_epis_doc_quantification
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets a concatenated list of qualifications associated with an element in parentheses
    *
    * @param   i_lang         Professional preferred language
    * i_epis_document_det     Documentation detail ID
    *
    * @return  String with concatenated list of qualifications
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_epis_doc_qualification
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get the quantifier description associated to an element quantified
    *
    * This function is used for compatibility purposes to deal with old descriptions for element's quantifier in templates.
    * In new template's elements that make use of quantifiers this function should return null values, 
    * and the new function get_epis_doc_quantification() return the full description for an element quantified.
    *
    * @param   i_lang         Professional preferred language
    * i_epis_document_det     Documentation detail ID
    *
    * @return  Description associated with the quantifier (example: "mild")
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_epis_doc_quantifier
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get adjective placement rule for input language. 
    * This flag is used to identify the rule that is applied in this language for adjective placement before/after the noun. 
    * Used for compatibility purposes in Touch-option templates in order to define the position of element's quantification. 
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   o_flg_placement Adjective placement rule
    * @param   o_error         Error information
    *
    * @value   o_flg_placement {*} 'B' Quantification is placed before the element {*} 'A' Quantification is placed after the element
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_quantif_placement
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_flg_placement OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a formatted string representing the description of a template's element recorded (description, quantifier, qualifier, value, etc).
    *
    * This function is intended to be used where is necessary to have in an unique string the description 
    * of an element without formatting or special treatments that commonly are used in Flash layer to build the phrase.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_document_det  Documentation detail ID
    * @param   i_use_html_format    Use HTML tags to format output. Default: No
    *
    * @value   i_use_html_format    {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @return  A formatted string representing the description of the element with quantifier, qualifiers, value, etc.
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/12/2010
    */
    FUNCTION get_epis_formatted_element
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE,
        i_use_html_format   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /**
    * Retrieves variables to be applied in queries using scope orientation
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_scope        Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type   Scope type (by episode; by visit; by patient)
    * @param   o_patient      Patient ID
    * @param   o_visit        Visit ID
    * @param   o_episode      Episode ID
    * @param   o_error        Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.2
    * @since   11/5/2010
    */
    FUNCTION get_scope_vars
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR,
        o_patient    OUT patient.id_patient%TYPE,
        o_visit      OUT visit.id_visit%TYPE,
        o_episode    OUT episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves variables to be applied in queries using scope orientation
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_scope        Scope ID (Episode IDs; Visit IDs; Patient IDs)
    * @param   i_scope_type   Scope type (by episode; by visit; by patient)
    * @param   o_patient      Patient IDs
    * @param   o_visit        Visit IDs
    * @param   o_episode      Episode IDs
    * @param   o_error        Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes (based on ARIEL.MACHADO code)
    * @version 2.5
    * @since   21/03/2013
    */
    FUNCTION get_scope_vars_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN table_number,
        i_scope_type IN VARCHAR,
        o_patient    OUT table_number,
        o_visit      OUT table_number,
        o_episode    OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a set of records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled) Default 'AOC'
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    * @param   i_fltr_start_date    Begin date (optional)        
    * @param   i_fltr_end_date      End date (optional)        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor containing information about registers (professional, record date, status, etc.)
    * @param   o_doc_area_val       Cursor containing information about data values saved in registers
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   11/09/2010
    */
    FUNCTION get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_fltr_status        IN VARCHAR2 DEFAULT 'AOC',
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_fltr_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT t_cur_doc_area_register,
        o_doc_area_val       OUT t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the settings of an area according to the institution, market and software.
    *
    * @param   i_doc_area         Area ID
    * @param   i_institution      Institution ID
    * @param   i_market           Market ID
    * @param   i_software         Software ID
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version v2.6.0.4
    * @since   11/19/2010
    */
    FUNCTION tf_doc_area_inst_soft
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_market      IN market.id_market%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN t_coll_doc_area_inst_soft
        PIPELINED;

    /**
    * Returns the settings of an area according to the institution, institution market and software.
    *
    * @param   i_doc_area         Area ID
    * @param   i_institution      Institution ID
    * @param   i_software         Software ID
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version v2.6.0.4
    * @since   11/19/2010
    */
    FUNCTION tf_doc_area_inst_soft
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN t_coll_doc_area_inst_soft
        PIPELINED;

    /**
    * Get the last element of a given list, that was registered in the patient 
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID         
    * @param   i_doc_elements List of elements
    * @param   o_doc_element  Last selected element
    * @param   o_error        Error information
    *
    *
    * @return  True or False on success or error
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_pat_last_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_doc_elements IN table_number,
        o_doc_element  OUT doc_element.id_doc_element%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Return cursor with records for touch option area
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Documentation area ID
    * @param i_epis_doc               Table number with id_epis_documentation
    * @param i_epis_anamn             Table number with id_epis_anamnesis
    * @param i_epis_rev_sys           Table number with id_epis_review_systems
    * @param i_epis_obs               Table number with id_epis_observation
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist
    * @param i_epis_recomend          Table number with id_epis_recomend
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)
    *
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva & Ariel Machado                                  
    * @version                        2.6.0.5                                 
    * @since                          2011/02/17                                
    **************************************************************************/
    FUNCTION get_doc_area_value_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis_doc           IN table_number,
        i_epis_anamn         IN table_number,
        i_epis_rev_sys       IN table_number,
        i_epis_obs           IN table_number,
        i_epis_past_fsh      IN table_number,
        i_epis_recomend      IN table_number,
        i_flg_show_fm        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT NOCOPY t_cur_doc_area_register,
        o_doc_area_val       OUT NOCOPY t_cur_doc_area_val,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Return doc_area value from epis_documentation id
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_epis_doc               Epis Documentation Identifier
    *
    * @param o_doc_area               Doc area identifier
    * @param o_error                  Error message
    *                                                                         
    * @author                         Rui Spratley
    * @version                        2.6.0.5                                 
    * @since                          2011/03/03
    **************************************************************************/
    FUNCTION get_doc_area_from_epis_doc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_doc_area OUT doc_area.id_doc_area%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a list of templates respecting a hierarchical structure of levels according to a subject
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_subject      Subject
    * @param   i_patient      Patient ID
    * @param   i_episode      Episode ID
    * @param   i_doc_area     Documentation area ID
    * @param   i_context      the context id
    * @param   i_flg_type     Access type to touch_option functionality
    * @param   o_templates    List of templates in an hierarchical structure of levels
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  Gustavo Serrano
    * @version 2.6.1
    * @since   2/08/2011
    */
    FUNCTION get_doc_template_extended
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_flg_type  IN doc_area_inst_soft.flg_type%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************
    * Get list of actions for create button for a specified subject.         *
    *                                                                        *
    * @param i_lang                Preferred language ID for this            *
    *                              professional                              *
    * @param i_prof                Object (professional ID,                  *
    *                              institution ID, software ID)              *
    * @param i_subject             Subject                                   *
    * @param i_episode             the episode id                            *
    * @param i_doc_area            the doc_area id                           *
    *                                                                        *
    * @return                      Table with documentation systems info     *
    *                                                                        *
    * @author                      Gustavo Serrano                           *
    * @version                     2.6.1                                     *
    * @since                       03-Mar-2011                               *
    **************************************************************************/
    FUNCTION get_doc_template_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_subject  IN action.subject%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_titles   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns element description
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_flg_type        Element type
    * @param   i_value           Element value
    * @param   i_properties      Properties for the element value 
    * @param   i_element_crit    Element criteria ID
    * @param   i_uom_reference   Unit of measurement used as base/reference
    * @param   i_master_item     ID of an item in a master area that is represented by this element
    * @param   i_code_trans      Code used to retrieve default translation of element
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   20-06-2011
    */
    FUNCTION get_element_description
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN doc_element.flg_type%TYPE,
        i_value         IN epis_documentation_det.value%TYPE,
        i_properties    IN epis_documentation_det.value_properties%TYPE,
        i_element_crit  IN doc_element_crit.id_doc_element_crit%TYPE,
        i_uom_reference IN doc_element.id_unit_measure_reference%TYPE,
        i_master_item   IN doc_element.id_master_item%TYPE,
        i_code_trans    IN translation.code_translation%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Concatenate a list of descriptions using a delimiter that is defined in the cursor itself
    *
    * @param   p_cursor         Cursor with two fields: Description, Delimiter
    *
    * @return  Returns the concatenated list
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   21-06-2011
    */
    FUNCTION concat_element_list(p_cursor IN SYS_REFCURSOR) RETURN VARCHAR2;

    /**
    * Returns a set of IDs records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled) Default 'AOC'
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    * @param   i_fltr_start_date    Begin date (optional)        
    * @param   i_fltr_end_date      End date (optional)        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_coll_epis_doc      Table number with id_epis_documentation        
    * @param   o_coll_epis_anamn    Table number with id_epis_anamnesis        
    * @param   o_coll_epis_rev_sys  Table number with id_epis_review_systems        
    * @param   o_coll_epis_obs      Table number with id_epis_observation        
    * @param   o_coll_epis_past_fsh Table number with id_pat_fam_soc_hist        
    * @param   o_coll_epis_recomend Table number with id_epis_recomend 
    * @param   o_error              Error message 
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.1
    * @since   15/05/2012
    */
    FUNCTION get_doc_area_value_ids
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN table_number,
        i_scope              IN table_number,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_fltr_status        IN VARCHAR2 DEFAULT 'AOC',
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_fltr_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_record_count       OUT NUMBER,
        o_coll_epis_doc      OUT NOCOPY table_number,
        o_coll_epis_anamn    OUT NOCOPY table_number,
        o_coll_epis_rev_sys  OUT NOCOPY table_number,
        o_coll_epis_obs      OUT NOCOPY table_number,
        o_coll_epis_past_fsh OUT NOCOPY table_number,
        o_coll_epis_recomend OUT NOCOPY table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets information about print list job related to Touch-option documentation
    * Used by print list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_print_list_job  Print list job identifier, related to the documentation
    *
    * @return  t_rec_print_list_job Print list job information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/12/2014
    */
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    /**
    * Compares if a print list job context data is similar to the array of print list jobs
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_print_job_context_data       Print list job context data
    * @param   i_print_list_jobs              Array of print list job identifiers
    *
    * @return  table_number                   Arry of print list jobs that are similar
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/12/2014
    */
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number;

    /**
    * Adds documentation entries to the print list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_id_epis_docs       List of epis_documentation identifiers to  be added to the print list
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    List of print list job identifiers
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/12/2014
    */
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_epis_docs    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Removes documentation entry from print list (if exists)
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_epis_documentation Documentation ID
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/12/2014
    */
    FUNCTION remove_print_list_jobs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets print list completion options
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_doc_area              Documentation area ID
    * @param o_options               Documentation completion options
    * @param o_flg_show_popup        Flag that indicates if the pop-up is shown or not. If not, default option is assumed
    * @param o_error                 An error message, set when return=false
    *
    * @value   o_flg_show_popup     {*} 'Y' the pop-up is shown 
    *                               {*} 'N' otherwise
    *    
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/12/2014
    */
    FUNCTION get_completion_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_options        OUT pk_types.cursor_type,
        o_flg_show_popup OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. (Current information details)
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_id_episode         episode id
    * @param i_id_doc_area        doc_area id
    * @param o_epis_document_val  array with detail current information details
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Nuno Alves
    * @version                    1.0   
    * @since                      2015/01/06
    ********************************************************************************************/
    FUNCTION get_epis_docum_det_pn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_area_desc   IN sys_message.desc_message%TYPE,
        o_history     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio.
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_id_episode         episode id
    * @param i_id_doc_area        doc_area id
    * @param o_epis_document_val  array with detail current information details
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Nuno Alves
    * @version                    1.0   
    * @since                      2015/01/06
    ********************************************************************************************/
    FUNCTION get_epis_docum_det_pn_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_history     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_element_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN doc_element.flg_type%TYPE,
        i_value             IN epis_documentation_det.value%TYPE,
        i_id_content        IN doc_element_crit.id_content%TYPE,
        i_mask              IN VARCHAR2 DEFAULT NULL,
        i_doc_element       IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_doc_comp_internal IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_elem_internal IN doc_element.internal_name%TYPE DEFAULT NULL
        
    ) RETURN VARCHAR2;

    PROCEDURE get_dais_cfg_vars
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_summary_page IN summary_page.id_summary_page%TYPE,
        o_market       OUT institution.id_market%TYPE,
        o_inst         OUT institution.id_institution%TYPE,
        o_soft         OUT software.id_software%TYPE
    );

    FUNCTION get_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_type           IN doc_element.flg_type%TYPE,
        i_value              IN epis_documentation_det.value%TYPE,
        i_id_content         IN doc_element_crit.id_content%TYPE,
        i_mask               IN VARCHAR2 DEFAULT NULL,
        i_doc_comp_internal  IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_elem_internal  IN doc_element.internal_name%TYPE DEFAULT NULL,
        i_show_internal      IN VARCHAR2 DEFAULT NULL,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_show_id_content    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_doc_title     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    FUNCTION get_template_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL,
        i_element_int_name   IN VARCHAR2 DEFAULT NULL,
        i_show_internal      IN VARCHAR2 DEFAULT NULL,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_mask               IN VARCHAR2 DEFAULT NULL,
        i_field_type         IN VARCHAR2 DEFAULT NULL,
        i_show_id_content    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_doc_title     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    FUNCTION get_doc_templ_by_epis_doc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN NUMBER;

    FUNCTION check_documentation_has_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************************
    * Gets the question concatenated with the actual answer for a specific                    *
    * id_epis_documentation and id_doc_component                                              *                
    *                                                                                         *
    * @param i_lang                       language id                                         *
    * @param i_prof                       professional, software and                          *
    *                                     institution ids                                     *
    * @param i_epis_documentation         epis documentation id                               *
    * @param i_doc_int_name               doc component internal name                         *
    * @param i_is_bold                    should component be bold?                           *
    * @param i_has_title                  should component title be shown (DEFAULT YES)       *
    *                                                                                         *
    * @return                         Returns concatenated string                             *
    *                                                                                         *
    * @author                         Anna Kurowska                                           *
    * @version                        1.0                                                     *
    * @since                          2018/03/05                                              *
    ******************************************************************************************/
    FUNCTION get_epis_doc_component_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL,
        i_is_bold            IN VARCHAR2 DEFAULT NULL,
        i_has_title          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;
    /**
    * Get epis documentation flg printed
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_epis_doc            the documentation episode id
    *  
    * @return flg_printed             from epis_documentation: P - printed; M - Migrated
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/08/22
    */
    FUNCTION get_epis_doc_flg_printed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_printed OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    /**
    * Set epis documentation flg printed
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_epis_doc            the documentation episode id
    *
    * @return                         Returns boolean    
    *                                                                               
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/08/22
    */
    FUNCTION set_epis_doc_flg_printed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************
    * Check if doc_area has scores                                                            *                
    *                                                                                         *
    * @param i_lang                       language id                                         *
    * @param i_prof                       professional, software and                          *
    *                                     institution ids                                     *
    * @param i_id_doc_area                doc area id                                         *
    *                                                                                         *
    * @return                         Returns boolean                                         *
    *                                                                                         *
    * @author                         Anna Kurowska                                           *
    * @version                        1.0                                                     *
    * @since                          2018/07/25                                              *
    ******************************************************************************************/
    FUNCTION check_score_by_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN BOOLEAN;
    /**
    * Gets doc area info register
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID        
    * @param i_doc_area               Documentation area ID        
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_epis_anamn             Table number with id_epis_anamnesis        
    * @param i_epis_rev_sys           Table number with id_epis_review_systems        
    * @param i_epis_obs               Table number with id_epis_observation        
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist        
    * @param i_epis_recomend          Table number with id_epis_recomend        
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information        
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)        
    * @param o_doc_area_register      Cursor with the doc area info register        
    * @param o_doc_area_val           Cursor containing the completed info for episode        
    * @param o_template_layouts       Cursor containing the layout for each template used        
    * @param o_doc_area_component     Cursor containing the components for each template used        
    * @param o_error                  Error message        
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/07/16
    */
    FUNCTION tf_get_doc_area_register
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_epis_doc      IN table_number,
        i_epis_anamn    IN table_number,
        i_epis_rev_sys  IN table_number,
        i_epis_obs      IN table_number,
        i_epis_past_fsh IN table_number,
        i_epis_recomend IN table_number,
        i_flg_show_fm   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_order         IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN t_tbl_doc_area_register;

    /**
    * Gets doc area info register
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID        
    * @param i_doc_area               Documentation area ID        
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_epis_anamn             Table number with id_epis_anamnesis        
    * @param i_epis_rev_sys           Table number with id_epis_review_systems        
    * @param i_epis_obs               Table number with id_epis_observation        
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist        
    * @param i_epis_recomend          Table number with id_epis_recomend        
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information        
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)        
    * @param o_doc_area_register      Cursor with the doc area info register        
    * @param o_doc_area_val           Cursor containing the completed info for episode        
    * @param o_template_layouts       Cursor containing the layout for each template used        
    * @param o_doc_area_component     Cursor containing the components for each template used        
    * @param o_error                  Error message        
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/07/16
    */

    FUNCTION tf_get_doc_area_val
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_epis_doc    IN table_number,
        i_flg_show_fm IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN t_tbl_doc_area_val;
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_exception EXCEPTION;
    --
    g_yes             CONSTANT VARCHAR2(1) := 'Y';
    g_no              CONSTANT VARCHAR2(1) := 'N';
    g_canceled        CONSTANT VARCHAR2(1) := 'C';
    g_active          CONSTANT VARCHAR2(1) := 'A';
    g_available       CONSTANT VARCHAR2(1) := 'Y';
    g_documentation_n CONSTANT VARCHAR2(1) := 'N';
    g_flg_printed     CONSTANT VARCHAR2(1) := 'P';
    g_flg_migrated    CONSTANT VARCHAR2(1) := 'M';
    --
    g_gender_f CONSTANT VARCHAR2(1) := 'F';
    g_gender_m CONSTANT VARCHAR2(1) := 'M';
    g_gender_i CONSTANT VARCHAR2(1) := 'I';
    --
    g_epis_doc_active  CONSTANT VARCHAR2(1) := 'A';
    g_epis_comp_active CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_a     CONSTANT VARCHAR2(1) := 'A';
    --
    g_position_in  CONSTANT VARCHAR2(20) := 'I';
    g_position_out CONSTANT VARCHAR2(20) := 'O';
    --
    g_epis_bartchart_act         CONSTANT epis_documentation.flg_status%TYPE := 'A';
    g_epis_bartchart_out         CONSTANT epis_documentation.flg_status%TYPE := 'O';
    g_flg_edition_type_new       CONSTANT epis_documentation.flg_edition_type%TYPE := 'N';
    g_flg_edition_type_edit      CONSTANT epis_documentation.flg_edition_type%TYPE := 'E';
    g_flg_edition_type_agree     CONSTANT epis_documentation.flg_edition_type%TYPE := 'A';
    g_flg_edition_type_update    CONSTANT epis_documentation.flg_edition_type%TYPE := 'U';
    g_flg_edition_type_nochanges CONSTANT epis_documentation.flg_edition_type%TYPE := 'O';
    --
    g_domain_epis_doc_flg_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DOCUMENTATION.FLG_STATUS';
    --

    g_touch_option_def_template CONSTANT sys_config.id_sys_config%TYPE := 'DEFAULT_TOUCH_OPTION_TEMPLATE_APPLIES';

    -- Template context criteria
    g_flg_type_complaint_sch_evnt  CONSTANT doc_area_inst_soft.flg_type%TYPE := 'CT'; -- Template by Complaint + Scheduled event (Used in Private-Practice by PK_COMPLAINT)
    g_flg_type_sch_dep_clin_serv   CONSTANT doc_area_inst_soft.flg_type%TYPE := 'SD'; -- Template by Scheduled Department-clinical service
    g_flg_type_appointment         CONSTANT doc_area_inst_soft.flg_type%TYPE := 'A'; -- Template by Appointment
    g_flg_type_doc_area            CONSTANT doc_area_inst_soft.flg_type%TYPE := 'D'; -- Template by Area
    g_flg_type_complaint           CONSTANT doc_area_inst_soft.flg_type%TYPE := 'C'; --  Template by Complaint
    g_flg_type_clin_serv           CONSTANT doc_area_inst_soft.flg_type%TYPE := 'S'; -- Template by Clinical service
    g_flg_type_intervention        CONSTANT doc_area_inst_soft.flg_type%TYPE := 'I'; -- Template by Intervention
    g_flg_type_exam                CONSTANT doc_template_context.flg_type%TYPE := 'E'; -- Template by Exam
    g_flg_type_nursingedis_service CONSTANT doc_area_inst_soft.flg_type%TYPE := 'SN'; -- It isn't a template type. Used by Nursing areas on EDIS to load a specific default template if no template has been parameterized)
    g_flg_type_doc_area_service    CONSTANT doc_area_inst_soft.flg_type%TYPE := 'DS'; -- Template by Area + Clinical service (PLLopes 16/03/2009)
    g_flg_type_doc_area_appointmt  CONSTANT doc_area_inst_soft.flg_type%TYPE := 'DA'; -- Template by Area + Appointment   
    g_flg_type_doc_area_surg_proc  CONSTANT doc_area_inst_soft.flg_type%TYPE := 'SP'; -- Template by Area + Surgical Procedure
    g_flg_type_doc_area_complaint  CONSTANT doc_area_inst_soft.flg_type%TYPE := 'DC'; -- Template by Area + Complaint
    g_flg_type_doc_area_cipe       CONSTANT doc_area_inst_soft.flg_type%TYPE := 'P'; -- Template by Area + Complaint
    g_flg_type_cipe                CONSTANT doc_area_inst_soft.flg_type%TYPE := 'P'; -- Template by CIPE
    g_flg_type_exam_result         CONSTANT doc_template_context.flg_type%TYPE := 'ER'; -- Template by Exam Result
    g_flg_type_communication       CONSTANT doc_area_inst_soft.flg_type%TYPE := 'CO'; -- Template by Communication
    g_flg_type_medical_order       CONSTANT doc_area_inst_soft.flg_type%TYPE := 'MO'; -- Template by Medical order
    --
    g_doc_tmplt_crit_complaint     CONSTANT VARCHAR2(20) := 'COMPLAINT';
    g_doc_tmplt_crit_dep_clin_serv CONSTANT VARCHAR2(20) := 'DEP_CLIN_SERV';
    --
    g_doc_template_nursingedis_def CONSTANT doc_template.id_doc_template%TYPE := 58;
    --
    g_flg_element_domain_template  CONSTANT doc_element.flg_element_domain_type%TYPE := 'T';
    g_flg_element_domain_sysdomain CONSTANT doc_element.flg_element_domain_type%TYPE := 'S';
    g_flg_element_domain_dynamic   CONSTANT doc_element.flg_element_domain_type%TYPE := 'D';
    --
    g_elem_flg_type_mchoice_single CONSTANT doc_element.flg_type%TYPE := 'CO'; --Element type: compound element multichoice singleselect
    g_elem_flg_type_mchoice_multpl CONSTANT doc_element.flg_type%TYPE := 'CM'; --Element type: compound element multichoice multiselect
    g_elem_flg_type_comp_numeric   CONSTANT doc_element.flg_type%TYPE := 'CN'; --Element type: compound element for number
    g_elem_flg_type_comp_date      CONSTANT doc_element.flg_type%TYPE := 'CD'; --Element type: compound element for date
    g_elem_flg_type_comp_text      CONSTANT doc_element.flg_type%TYPE := 'CT'; --Element type: compound element for text
    g_elem_flg_type_comp_ref_value CONSTANT doc_element.flg_type%TYPE := 'CR'; --Element type: compound element for number with reference values
    g_elem_flg_type_vital_sign     CONSTANT doc_element.flg_type%TYPE := 'VS'; --Element type: vital sign
    g_elem_flg_type_touch          CONSTANT doc_element.flg_type%TYPE := 'S'; --Element type: touch button
    g_elem_flg_type_text           CONSTANT doc_element.flg_type%TYPE := 'T'; --Element type: single text
    g_elem_flg_type_text_other     CONSTANT doc_element.flg_type%TYPE := 'O'; --Element type: single text other
    g_elem_flg_type_simple_float   CONSTANT doc_element.flg_type%TYPE := 'F'; --Element type: simple numeric float
    g_elem_flg_type_simple_number  CONSTANT doc_element.flg_type%TYPE := 'N'; --Element type: simple numeric
    g_elem_flg_type_simple_neg     CONSTANT doc_element.flg_type%TYPE := 'G'; --Element type: simple numeric negative

    --
    g_flg_param_type_value         CONSTANT doc_element_function_param.flg_param_type%TYPE := 'V';
    g_flg_param_type_template_elem CONSTANT doc_element_function_param.flg_param_type%TYPE := 'T';
    g_flg_param_type_enviroment    CONSTANT doc_element_function_param.flg_param_type%TYPE := 'E';
    --
    g_flg_value_type_value    CONSTANT doc_element_function_param.flg_param_type%TYPE := 'V';
    g_flg_param_type_criteria CONSTANT doc_element_function_param.flg_param_type%TYPE := 'C';
    g_flg_param_type_number   CONSTANT doc_element_function_param.flg_param_type%TYPE := 'N';
    g_flg_param_type_string   CONSTANT doc_element_function_param.flg_param_type%TYPE := 'S';
    --
    g_datetime_format_timezone CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS TZR';
    --
    g_scfg_decimal_separator CONSTANT sys_config.id_sys_config%TYPE := 'DECIMAL_SYMBOL';
    --
    g_flg_criteria_initial CONSTANT doc_criteria.flg_criteria%TYPE := 'I';
    --
    g_flg_workflow CONSTANT documentation_rel.flg_action%TYPE := 'W';
    --
    g_der_flg_type_exclusive   CONSTANT doc_element_rel.flg_type%TYPE := 'E';
    g_der_flg_type_unique      CONSTANT doc_element_rel.flg_type%TYPE := 'U';
    g_der_flg_type_copy_action CONSTANT doc_element_rel.flg_type%TYPE := 'C';

    g_flg_tab_origin_epis_doc      CONSTANT VARCHAR(1 CHAR) := 'D'; --epis_documentation
    g_flg_tab_origin_epis_anamn    CONSTANT VARCHAR(1 CHAR) := 'A'; --epis_anamnesis
    g_flg_tab_origin_epis_rev_sys  CONSTANT VARCHAR(1 CHAR) := 'S'; --epis_review_systems
    g_flg_tab_origin_epis_obs      CONSTANT VARCHAR(1 CHAR) := 'O'; --epis_observation table
    g_flg_tab_origin_epis_recomend CONSTANT VARCHAR(1 CHAR) := 'R'; --epis_recomend table
    g_flg_tab_origin_epis_past_fsh CONSTANT VARCHAR(1 CHAR) := 'F'; --pat_fam_soc_hist
    g_flg_tab_origin_epis_diags    CONSTANT VARCHAR(1 CHAR) := 'G'; --epis_diagnosis
    g_flg_tab_origin_surg_record   CONSTANT VARCHAR(1 CHAR) := 'U'; --sr_surgery_record
    --
    g_doc_area_pat_belong  CONSTANT doc_area.id_doc_area%TYPE := 6700;
    g_doc_area_dnr         CONSTANT doc_area.id_doc_area%TYPE := 6096;
    g_doc_area_ntiss       CONSTANT doc_area.id_doc_area%TYPE := 36029;
    g_doc_area_routine_pci CONSTANT doc_area.id_doc_area%TYPE := 36032;
    g_doc_area_sick_leave  CONSTANT doc_area.id_doc_area%TYPE := 36052;

    g_null_number  CONSTANT NUMBER := -1;
    g_null_varchar CONSTANT VARCHAR2(6) := '<NULL>';

    g_elem_separator_default CONSTANT doc_element.separator%TYPE := '; ';
    g_elem_separator_none    CONSTANT doc_element.separator%TYPE := '[NONE]';

    --Different date types that can be used in Touch-option templates
    k_touchoption_date_types CONSTANT table_varchar := table_varchar('YYYY',
                                                                     'MM',
                                                                     'YYYYMM',
                                                                     'MMDD',
                                                                     'YYYYMMDD',
                                                                     'HH24MISS',
                                                                     'YYYYMMDDHH24MISS');

    TYPE t_sys_config_value IS TABLE OF sys_config.value%TYPE INDEX BY VARCHAR2(200);
    --A date format cache used to represent different date types by soft/institution
    g_touchoption_date_type_format t_sys_config_value;

    -- CMF
    FUNCTION tf_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_visit   IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN t_tbl_epis_documentation;

END pk_touch_option;
/
