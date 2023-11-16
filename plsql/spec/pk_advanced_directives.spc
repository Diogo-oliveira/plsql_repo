/*-- Last Change Revision: $Rev: 2028443 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_advanced_directives IS

    /**
    Package for the Advanced Directives functionality
    **/

    /********************************************************************************************
    * Gets the type of advance directive for a patient or a record
    * 
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, software and institution ids
    * @param   I_PATIENT             patient id
    * @param   I_EPIS_DOCUMENTATION  documentation ID assoiciated with the advance directive
    *
    * @param   o_desc_pat_adv_dir    advance directive description (for a record)
    * @param   o_pat_adv_dir         advance directive descriptions (for a patient)
    *
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-04-2010
    **********************************************************************************************/
    FUNCTION get_adv_dir_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_desc_pat_adv_dir   OUT VARCHAR2,
        o_pat_adv_dir        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function tels if a patient has any advanced directives
    *
    * @param i_lang language id
    * @param i_prof user object
    * @param i_patient patient id
    * @param i_episode episode id
    * @param o_has_adv_directives Y if patient has advanced directives, N otherwise
    * @param o_adv_directive_sh advanced directives shortcut to jump to when accessing it from the header
    * @param o_error error message, in case of error
    * @return true (all ok), false (error)
    *
    * @author  José Silva
    * @version 2.0
    * @since   23-02-2009   
    */
    FUNCTION get_adv_directives_for_header
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_has_adv_directives OUT VARCHAR2,
        o_adv_directive_sh   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets an advance directive record
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
    * @param i_epis_context               episode context id (Ex: id_interv_presc_det,...)  
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              11-02-2009
    **********************************************************************************************/
    FUNCTION set_advance_directive
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
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets a new advance directive document
    * 
    * @param   i_id_doc              id do documento a fechar
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_EXT_REQ             external request id
    * @param   I_DOC_TYPE            tipo documento
    * @param   I_DESC_DOC_TYPE       descriçao manual do tipo documento
    * @param   i_num_doc             numero do documento original
    * @param   i_dt_doc              data emissao do doc. original
    * @param   i_dt_expire           validade do doc. original
    * @param   i_dest                destination id
    * @param   i_desc_dest           descriçao manual da destination
    * @param   i_ori_type            doc_ori_type id
    * @param   i_desc_ori_doc_type   descriçao manual do ori_type
    * @param   i_original            doc_original id
    * @param   i_desc_original       descriçao manual do original
    * @param   i_btn                 contexto
    * @param   i_title               descritivo manual do doc.
    * @param   i_flg_sent_by         info sobre o carrier do doc
    * @param   i_flg_received        indica se recebeu o documento    
    * @param   i_prof_perf_by        id do profissional escolhido no performed by
    * @param   i_desc_perf_by        descrição manual do performed by
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2008
    **********************************************************************************************/
    FUNCTION set_advance_directive_doc
    (
        i_id_doc            IN doc_external.id_doc_external%TYPE,
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_patient           IN doc_external.id_patient%TYPE,
        i_episode           IN doc_external.id_episode%TYPE,
        i_ext_req           IN doc_external.id_external_request%TYPE,
        i_doc_type          IN doc_external.id_doc_type%TYPE,
        i_desc_doc_type     IN doc_external.desc_doc_type%TYPE,
        i_num_doc           IN doc_external.num_doc%TYPE,
        i_dt_doc            IN doc_external.dt_emited%TYPE,
        i_dt_expire         IN doc_external.dt_expire%TYPE,
        i_dest              IN doc_external.id_doc_destination%TYPE,
        i_desc_dest         IN doc_external.desc_doc_destination%TYPE,
        i_ori_doc_type      IN doc_external.id_doc_ori_type%TYPE,
        i_desc_ori_doc_type IN doc_external.desc_doc_ori_type%TYPE,
        i_original          IN doc_external.id_doc_original%TYPE,
        i_desc_original     IN doc_external.desc_doc_original%TYPE,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_flg_sent_by       IN doc_external.flg_sent_by%TYPE,
        i_flg_received      IN doc_external.flg_received%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        i_notes             IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Associates a new document with an advance directive record
    * 
    * @param   i_id_doc              list of documents to associate
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_DOC_TYPE            list of document types
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2009
    **********************************************************************************************/
    FUNCTION set_adv_dir_associated_doc
    (
        i_id_doc   IN table_number,
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_patient  IN doc_external.id_patient%TYPE,
        i_doc_type IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Associates a new document with an advance directive record
    * 
    * @param   i_id_doc              id do documento a fechar
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_PATIENT             patient id
    * @param   I_EPISODE             episode id
    * @param   I_DOC_TYPE            tipo documento
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   15-02-2008
    **********************************************************************************************/
    FUNCTION set_adv_dir_associated_doc_int
    (
        i_id_doc   IN doc_external.id_doc_external%TYPE,
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_patient  IN doc_external.id_patient%TYPE,
        i_doc_type IN doc_external.id_doc_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates all adv. directives DNAR recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    Patient id
    * @param i_new_episode                Episode id
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1  
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION set_recurr_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_new_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates all adv. directives DNAR recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_adv_dir                Pat advance directive id
    * @param i_new_episode                Episode id
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1  
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION set_recurr_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_adv_dir IN pat_advance_directive.id_pat_advance_directive%TYPE,
        i_new_episode IN episode.id_episode%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels all adv. directives recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    Patient id
    * @param i_episode                    Episode id
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1  
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION cancel_adv_dir_recurr_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels all adv. directives recurrence plans
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_adv_dir                Pat advance directive id
    * @param i_episode                    Episode id
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Alexandre Santos
    * @version                            2.6.1.1  
    * @since                              31-05-2011
    **********************************************************************************************/
    FUNCTION cancel_adv_dir_recurr_plans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_adv_dir IN pat_advance_directive.id_pat_advance_directive%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates a new advance directive document
    *
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                professional, institution and software ids
    * @param   I_ID_DOC              document ID
    * @param   I_DOC_TYPE            document type
    * @param   I_DESC_DOC_TYPE       manual description
    * @param   i_num_doc             document number
    * @param   i_dt_doc              emission date
    * @param   i_dt_expire           expiration date
    * @param   i_dest                destination id
    * @param   i_desc_dest           destination description
    * @param   i_ori_type            document origin type
    * @param   i_desc_ori_doc_type   document origin manual description
    * @param   i_original            doc_original id
    * @param   i_desc_original       original manual description
    * @param   i_btn                 context area
    * @param   i_title               document title
    * @param   i_flg_sent_by         document carrier
    * @param   i_flg_received        document was received?
    * @param   i_prof_perf_by        "performed by" field
    * @param   i_desc_perf_by        "performed by" manual description
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   08-04-2009
    **********************************************************************************************/
    FUNCTION update_adv_dir_doc
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_doc            IN NUMBER,
        i_doc_type          IN NUMBER,
        i_desc_doc_type     IN VARCHAR2,
        i_num_doc           IN VARCHAR2,
        i_dt_doc            IN DATE,
        i_dt_expire         IN DATE,
        i_orig_dest         IN NUMBER,
        i_desc_ori_dest     IN VARCHAR2,
        i_orig_type         IN NUMBER,
        i_desc_ori_doc_type IN VARCHAR2,
        i_notes             IN VARCHAR2,
        i_sent_by           IN doc_external.flg_sent_by%TYPE,
        i_received          IN doc_external.flg_received%TYPE,
        i_original          IN NUMBER,
        i_desc_original     IN VARCHAR2,
        i_btn               IN sys_button_prop.id_sys_button_prop%TYPE,
        i_title             IN doc_external.title%TYPE,
        i_prof_perf_by      IN doc_external.id_prof_perf_by%TYPE,
        i_desc_perf_by      IN doc_external.desc_perf_by%TYPE,
        i_notes_upd         IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Advance directive document list
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   I_EXT_REQ referral id        
    * @param   I_BTN     sys_button used to allow diferent behaviours depending on the button being used.
    * @param   O_LIST    output list
    * @param   o_error   Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          15-02-2009
    **********************************************************************************************/
    FUNCTION get_adv_dir_doc_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of documents to import (from the "Documents" deepnav)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_pat                    Patient ID    
    * @param i_btn                    context
    * @param o_list                   list of documents
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          15-02-2009
    **********************************************************************************************/
    FUNCTION get_adv_dir_doc_import
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_pat     IN patient.id_patient%TYPE,
        i_btn     IN sys_button_prop.id_sys_button_prop%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels an advance directive record (documentation or attached document)
    * 
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_type                   Cancellation type: E - epis_documentation, D - document
    * @param i_id_doc                 document ID to be cancelled
    * @param i_id_epis_doc            the documentation episode ID to be cancelled
    * @param i_id_cancel_reason       Cancellation reason ID
    * @param i_notes                  Cancel Notes
    * @param o_error                  Error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 1.0
    * @since   16-02-2009
    **********************************************************************************************/
    FUNCTION cancel_advance_directive
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_type             IN VARCHAR2,
        i_id_doc           IN doc_external.id_doc_external%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the cancelation information to place in the detail screen
    *
    * @param   I_LANG     language associated to the professional executing the request
    * @param   I_PROF     professional, institution and software ids
    * @param   I_EPIS_DOC documentation record (touch-option ID)
    * @param   i_id_doc   document ID
    * @param   o_det      detail information
    * @param   o_reviews  record review information
    * @param   o_error    Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          26-02-2009
    **********************************************************************************************/
    FUNCTION get_advance_directive_det
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_id_doc   IN doc_external.id_doc_external%TYPE,
        o_det      OUT pk_types.cursor_type,
        o_reviews  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the advance directive review information
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_epis_doc       documentation record (touch-option ID)
    * @param   i_review_notes   revision notes
    * @param   i_episode        Episode id
    * @param   o_error          Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          27-10-2009
    **********************************************************************************************/
    FUNCTION set_adv_dir_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_doc     IN epis_documentation.id_epis_documentation%TYPE,
        i_review_notes IN review_detail.review_notes%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets all episose advance directives as reviewed
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_summary_page   Summary page id
    * @param   i_pat               Patient ID
    * @param   i_episode           Episode ID
    * @param   o_error             Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION set_adv_dir_review_all
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the sections within a summary page
    *
    * @param   i_lang             language associated to the professional executing the request
    * @param   i_prof             professional, institution and software ids
    * @param   i_id_summary_page  Summary page ID
    * @param   i_pat              Patient ID
    * @param   i_episode           Episode ID
    * @param   o_sections         Cursor containing the sections info                                          
    * @param   o_epis_review      Cursor containing the episode review info                                          
    * @param   o_error            Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_epis_review     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_episode           Episode ID
    * @param   i_pat               Patient ID
    * @param   i_doc_area          Doc area ID
    * @param   o_doc_area_register Doc area data
    * @param   o_doc_area_val      Documentation data for the patient's episodes
    * @param   o_template_layouts  Cursor containing the layout for each template used
    * @param   o_error             Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns documentation data for a given patient (This function is used in reports)
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_episode           Episode ID
    * @param   i_pat               Patient ID
    * @param   i_doc_area          Doc area ID
    * @param   i_flg_scope         Scope
    * @param   o_doc_area_register Doc area data
    * @param   o_doc_area_val      Documentation data for the patient's episodes
    * @param   o_template_layouts  Cursor containing the layout for each template used
    * @param   o_error             Error message
    *                        
    * @value   i_flg_scope         E - Adv. Directives inserted/edited or validated in the current episode
    *                              V - Adv. Directives inserted/edited or validated in the current visit
    *                              P - All Patient Adv. Directives
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the advance directive review information
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_episode        Episode ID
    *                        
    * @return  Advanced directive icon
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_header_icon
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Sets the advance directive review information
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_episode        Episode ID
    * @param   o_txt_dnar       When applicable return DNAR
    * @param   o_text           Message "Advance directives"/"Patient"/"Physician"
    * @param   o_error          Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_header_text
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_text    OUT table_varchar2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the scope of doc.
    *   --if current epis_document episode 
    *   --   - is equal to current episode then set scope as episode
    *   --   - was inserted in the same visit then set scope as visit
    *   --   - otherwise set scope as patient
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_epis_documentation   Episode documentation ID
    * @param   i_episode              Episode ID
    * @param   i_flg_scope            Scope
    * @param   o_scope                Epis Documentation Scope
    * @param   o_error                Error message
    *                        
    * @values  o_scope   E - Episode
    *                    V - Visit                       
    *                    P - Patient                       
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_flg_scope
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_episode            IN epis_documentation.id_episode%TYPE,
        o_scope              OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get report header scope
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_episode        Episode ID
    * @param   i_flg_scope      Scope
    * @param   o_scope          DNAR Physician or DNAR Patient or Normal Adv. Dir. or NULL (related with the given episode)
    * @param   o_error          Error message
    *                        
    * @value   i_flg_scope         E - Adv. Directives inserted/edited or validated in the current episode
    *                              V - Adv. Directives inserted/edited or validated in the current visit
    *                              P - All Patient Adv. Directives
    *                        
    * @values  o_scope   DPH  - DNAR Physician
    *                    DP   - DNAR Patient                       
    *                    N    - Has advance directives                       
    *                    NULL - Doesn't have advance directives                       
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1
    * @since   29-03-2011
    **********************************************************************************************/
    FUNCTION get_report_hea_scope
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        o_scope     OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if DNAR popup is to be shown
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           episode id
    * @param   o_adv_dir_short_yes Shortcut ID when the user aswers Yes to the question
    * @param   o_adv_dir_short_no  Shortcut ID when the user aswers No to the question
    * @param   o_flg_show          If a message should or should not be shown to the user
    * @param   o_msg_title         Message title
    * @param   o_msg               Message body
    * @param   o_flg_show          If a message should or should not be shown to the user
    * @param   o_msg_title         Message title
    * @param   o_msg               Message body
    * @param   o_btn_cfg           Buttons configurations
    * @param   o_btn_desc_yes      Description of YES button
    * @param   o_btn_desc_no       Description of NO button
    * @param   o_error             Error message
    *                        
    * @value   o_flg_show          Y - Show message
    *                              N - Don't show
    *                        
    * @value   o_btn_cfg           YN - Yes/No buttons
    *                              GD - Go to DNAR button
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION check_adv_dir_dnar_review
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_adv_dir_short_yes OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_adv_dir_short_no  OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_btn_cfg           OUT VARCHAR2,
        o_btn_desc_yes      OUT VARCHAR2,
        o_btn_desc_no       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get list of actions for a specified subject and state.
    * Based on get_actions function.
    *
    * @param   i_lang              Preferred language ID for this professional
    * @param   i_prof              Object (professional ID, institution ID, software ID)
    * @param   i_subject           Subject
    * @param   i_from_state        State     
    * @param   o_actions           Cursor with actions
    * @param   o_error             Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adv_dir_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves the last profile_template review for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    * (Based on get_group_reviews_by_id)
    * (Used by reports team)
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  group of record ids
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  Alexandre Santos
    * @since                   2011-05-31
    * @version                 2.6.1.1
    * @reason                  ALERT-41412
    */
    FUNCTION get_greviews_by_pt_last_dt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN table_number,
        o_reviews        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Is to review DNAR area for the given patient
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           Episode ID
    *                        
    * @return  'Y' - if is to review
    *          'N' - otherwise
    * 
    * @author  Alexandre Santos
    * @version 2.6.1.1
    * @since   23-05-2011
    **********************************************************************************************/
    FUNCTION is_to_review_dnar
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if DNAR is to be reviwed
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_prof              professional, institution and software ids
    * @param   i_patient           Patient ID
    * @param   i_episode           Episode ID
    * @param   i_profile_template  Profile template ID
    *                        
    *                        
    * @return  Y - Is to review; N - Was already reviewed
    * 
    * @author  Alexandre Santos
    * @version 2.6.3
    * @since   04-09-2013
    **********************************************************************************************/
    FUNCTION is_to_review_dnar
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_profile_template      IN profile_template.id_profile_template%TYPE,
        i_pat_advance_directive IN pat_advance_directive.id_pat_advance_directive%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************************** 
    * Check if a patient is on patient Alerts 
    * 
    * @param i_lang         language identifier 
    * @param i_prof         logged professional structure 
    * @param i_id_patient   PATIENT ID 
    * @param o_flg_show     Y - if on patient alerts N - Not on  patient alerts 
    * @param o_title        modalWindows title 
    * @param o_warning      alerts cursor 
    * @param o_shortcut     id shortcut to  patient alerts 
    * @param o_error        error 
    * 
    * @return               false if errors occur, true otherwise 
    * 
    * @author              Jorge Silva 
    * @version              2.6.1 
    * @since                2012/07/23 
    **********************************************************************************************/
    FUNCTION get_active_patient_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_warning    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_shortcut   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- EMR-463
    FUNCTION get_header_icon_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get configured patient alert for header
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient     Patient ID
    * @param   i_episode        Episode ID
    * @param   o_has_pat_alerts           If paitent has patient alert or not
    * @param   o_error          Error message
    *
    * @value o_has_pat_alerts     {*} 'Y' Has patient alert  {*] 'N' no patient alert
    *
    * @return  true or false on success or error
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-06-27
    */
    FUNCTION get_pat_alerts_for_header
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_has_pat_alerts OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get configured patient alert tooltip
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param   i_patient     Patient ID
    * @param   i_episode        Episode ID
    * @param   o_pat_alerts_tooltip           Patient alert tooltip
    * @param   o_error          Error message
    *
    * @return  true or false on success or error
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-06-27
    */
    FUNCTION get_pat_alerts_tooltip
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_pat_alerts_tooltip OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_types
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        i_doc_ori_type IN doc_ori_type.id_doc_ori_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it can register more than one template by doc_area
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param  i_id_doc_area     doc_area ID
    * @param   o_error          Error message
    *
    * @return  {'Y'} Yes or {'N'} No
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-07-24
    */
    FUNCTION is_to_register_more
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    /**
    * Check if it needs to set alert by doc_area
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof           professional, institution and software ids
    * @param  i_id_doc_area     doc_area ID
    * @param   o_error          Error message
    *
    * @return  {'Y'} Yes or {'N'} No
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.6
    * @since                2018-07-24
    */
    FUNCTION is_to_show_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    /*
    Globais
    */
    g_error VARCHAR2(1000);

    /* Stores the package name. */
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_epis_bartchart_act CONSTANT epis_documentation.flg_status%TYPE := 'A';
    g_epis_bartchart_out CONSTANT epis_documentation.flg_status%TYPE := 'O';

    g_adv_status_active CONSTANT pat_advance_directive.flg_status%TYPE := 'A';
    g_adv_status_out    CONSTANT pat_advance_directive.flg_status%TYPE := 'O';
    g_adv_status_cancel CONSTANT pat_advance_directive.flg_status%TYPE := 'C';

    g_doc_status_active   CONSTANT pat_adv_directive_doc.flg_status%TYPE := 'A';
    g_doc_status_inactive CONSTANT pat_adv_directive_doc.flg_status%TYPE := 'I';
    g_doc_status_cancel   CONSTANT pat_adv_directive_doc.flg_status%TYPE := 'C';

    g_doc_ori_type_adv_dir CONSTANT doc_ori_type.id_doc_ori_type%TYPE := 11;

    g_flg_adv_type_h CONSTANT advance_directive.flg_type%TYPE := 'H'; --healthcare proxy
    g_flg_adv_type_l CONSTANT advance_directive.flg_type%TYPE := 'L'; --Legal proxy
    g_flg_adv_type_w CONSTANT advance_directive.flg_type%TYPE := 'W'; --Living will
    g_flg_adv_type_d CONSTANT advance_directive.flg_type%TYPE := 'D'; --DNAR decision
    g_flg_adv_type_e CONSTANT advance_directive.flg_type%TYPE := 'E'; --End of life care
    g_flg_adv_type_c CONSTANT advance_directive.flg_type%TYPE := 'C'; --Cardiac resuscitation
    g_flg_adv_type_a CONSTANT advance_directive.flg_type%TYPE := 'A'; --Alert patient

    g_adv_dir_icon_type_dp  CONSTANT VARCHAR2(3) := 'DP'; -- Dnar Patient 
    g_adv_dir_icon_type_dph CONSTANT VARCHAR2(3) := 'DPH'; -- Dnar Physician 
    g_adv_dir_icon_type_n   CONSTANT VARCHAR2(3) := 'N'; -- Has Advance directive 
    g_adv_dir_icon_type_a   CONSTANT VARCHAR2(3) := 'A'; -- Alert patient 

    g_has_adv_unk CONSTANT pat_advance_directive.flg_has_adv_directive%TYPE := 'U';

    g_summ_page_adv_dir CONSTANT summary_page.id_summary_page%TYPE := 32;

    g_sum_page_doc_area_e CONSTANT VARCHAR2(1) := 'E'; --E - Adv. Directives inserted/edited or validated in the current episode
    g_sum_page_doc_area_v CONSTANT VARCHAR2(1) := 'V'; --V - Adv. Directives inserted/edited or validated in the current visit
    g_sum_page_doc_area_p CONSTANT VARCHAR2(1) := 'P'; --P - All Patient Adv. Directives
    g_sum_page_doc_area_f CONSTANT VARCHAR2(1) := 'F'; --F - Flash funtion

    /* 
    Patient Alert 
    */
    -- doc Area 
    g_patient_alerts_doc_area CONSTANT doc_area.id_doc_area%TYPE := 6860;
    g_dnar_doc_area           CONSTANT doc_area.id_doc_area%TYPE := 6096;
    g_end_of_life_doc_area    CONSTANT doc_area.id_doc_area%TYPE := 6097;

END pk_advanced_directives;
/
