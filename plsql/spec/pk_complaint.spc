/*-- Last Change Revision: $Rev: 2028570 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_complaint IS

    TYPE epis_complaint_rec IS RECORD(
        id                       epis_complaint.id_epis_complaint%TYPE,
        id_epis_complaint        epis_complaint.id_epis_complaint%TYPE,
        desc_complaint           pk_translation.t_desc_translation,
        patient_complaint        epis_complaint.patient_complaint%TYPE,
        patient_complaint_full   CLOB,
        desc_template            pk_translation.t_desc_translation,
        dt_register              epis_complaint.adw_last_update_tstz%TYPE,
        id_prof_register         epis_complaint.id_professional%TYPE,
        reg_type                 VARCHAR2(10),
        patient_complaint_arabic epis_complaint.patient_complaint_arabic%TYPE);

    TYPE epis_complaint_cur IS REF CURSOR RETURN epis_complaint_rec;

    /********************************************************************************************
    * Devolve a lista de queixa possiveis, que se podem associar ao episódio.
      Esta lista é devolvida em 2 contextos: registo de nova queixa e alteração
      de queixa anterior. No segundo caso, apresenta-se ao utilizador qual a queixa
      registada anteriormente. Para se discriminar o 1º cenário do 2º, o parametro
      i_epis_complaint tem valor NULL, ou o id da queixa que se quer alterar, respectivamente
    *
    * @param i_lang                id da lingua
    * @param i_prof                objecto com info do utilizador
    * @param i_episode             id do episódio, para discriminação de template, dado um serviço clinico.
    *                              este parametro pode ser ignorado em certos casos (quais?)
    * @param i_epis_complaint      id da queixa que se quer alterar, ou NULL em caso de novo registo
    * @param o_complaints          cursor com queixas
    
    * @param o_error               Error message
    
    * @return                      true (sucess), false (error)
    * @author                      João Eiras
    * @since                       24-05-2007
    **********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        o_complaints     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if an episode has complaint template
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_flg_data            Y if there are data, F when no date found
    
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    
    * @author                      Luís Gaspar
    * @since                       24-05-2007
    **********************************************************************************************/
    FUNCTION get_complaint_template_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Registers an episode complaint. 
    *  It is allowed to register complaints only in active episodes.
    *  When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_patient_complaint       the patient complaint
    * @param i_flg_type                type of edition 
    * @param i_epis_complaint_parent   the patient complaint
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                    true (sucess), false (error)
    * @author                    Luís Gaspar & Luís Oliveira, based on pk_documentation.set_epis_complaint
    * @since                     26-05-2007
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    **********************************************************************************************/
    FUNCTION set_epis_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_epis                     IN episode.id_episode%TYPE,
        i_complaint                IN complaint.id_complaint%TYPE,
        i_patient_complaint        IN epis_complaint.patient_complaint%TYPE,
        i_patient_complaint_arabic IN epis_complaint.patient_complaint_arabic%TYPE DEFAULT NULL,
        i_flg_reported_by          IN epis_complaint.flg_reported_by%TYPE DEFAULT NULL,
        i_flg_type                 IN VARCHAR2,
        i_epis_complaint_parent    IN epis_complaint.id_epis_complaint%TYPE,
        o_id_epis_complaint        OUT epis_complaint.id_epis_complaint%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Registers an episode set of complaints.
    * It is allowed to register complaints only in active episodes.
    * When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the array of complaint ids
    * @param i_patient_complaint       the array of patient complaints
    * @param i_flg_type                array of types of edition
    * @param i_epis_complaint_parent   array of ids for the complaint parents
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                          true (sucess), false (error)
    **********************************************************************************************/
    FUNCTION set_epis_complaints
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_epis                     IN episode.id_episode%TYPE,
        i_complaint                IN table_number,
        i_patient_complaint        IN table_varchar,
        i_patient_complaint_arabic IN table_varchar DEFAULT NULL,
        i_flg_type                 IN table_varchar,
        i_epis_complaint_parent    IN table_number,
        o_id_epis_complaint        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets doc_template from the complaint. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_complaint         the complaint id
    * @param o_doc_template      the doc template id
    
    
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    
    * @author                    Luís Gaspar & Luís Oliveira, based on pk_documentation.set_epis_complaint
    * @since                     26-05-2007
    **********************************************************************************************/
    FUNCTION get_complaint_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_doc_template OUT doc_template.id_doc_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**************************************************************************************************************************************************************************************
    * Devolver a queixas selecionadas para o episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the id episode
    * @param o_complaint_register     cursor with the complaint info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/05/29
    **********************************************************************************************/
    FUNCTION get_summ_page_complaint_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************************************************************************************************************************
    * Devolver a queixas selecionadas pelos episódios
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the id episode table number
    * @param o_complaint_register     cursor with the complaint info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/09/25
    **********************************************************************************************/
    FUNCTION get_all_complaint_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN table_number,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************************************************************************************************************************
    * Devolver a queixas selecionadas para o episódio para os reports
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param i_episode                the id episode
    * @param i_flg_scope              Scope(P-Patient, E-Episode)
    * @param o_complaint_register     cursor with the complaint info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/05/29
    **********************************************************************************************/
    FUNCTION get_complaint_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Containing the ID of last update register
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION get_summ_pg_comp_value_reports
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_prof_inst          IN institution.id_institution%TYPE,
        i_prof_sw            IN software.id_software%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof_id                professional ID
    * @param i_prof_inst              institution ID, 
    * @param i_prof_sw                software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Containing the ID of last update register
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Spratley
    * @since                          2007/10/12
    **********************************************************************************************/
    FUNCTION get_epis_complaint_last_update
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
    * Get the complaint description associated to an episode complaint record
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_scope_complaint     Scope of the chief complaint
    * @param i_chief_complaint     Chief/Patient complaint
    * @param i_flg_hide_scope      Chief complaint can replace the scope in the description: (Y)es, (N)o
    *
    * @return                      complaint description
    *     
    * @author                      José Silva
    * @version                     2.5.1.2
    * @since                       2010/10/26
    **********************************************************************************************/
    FUNCTION get_epis_complaint_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope_complaint IN VARCHAR2,
        i_chief_complaint IN epis_complaint.patient_complaint%TYPE,
        i_flg_hide_scope  IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;

    FUNCTION get_epis_complaint_desc_full
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope_complaint IN VARCHAR2,
        i_chief_complaint IN CLOB,
        i_flg_hide_scope  IN VARCHAR2 DEFAULT 'Y'
    ) RETURN CLOB;
    --
    FUNCTION get_epis_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_docum     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint OUT epis_complaint_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver a queixa activa do episódio
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_epis_docum          epis_documentation id   
    * @param i_flg_only_scope      Returns only the scope of chief complaint: Y - yes, N - No
    * @param i_flg_single_row      Returns only the first row
    * @param o_epis_complaint      array with values of complaint episode            
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *     
    * @author                      Emília Taborda
    * @version                     1.0
    * @since                       2007/06/04
    **********************************************************************************************/
    FUNCTION get_epis_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_docum     IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_only_scope IN VARCHAR2,
        i_flg_single_row IN VARCHAR2 DEFAULT 'Y',
        o_epis_complaint OUT epis_complaint_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
      Allows for new, edit and agree epis documentation.
    *
    * @param i_lang                        language id
    * @param i_prof                        professional, software and institution ids
    * @param i_prof_cat_type               professional category
    * @param i_doc_area                    doc_area id
    * @param i_doc_template                doc_template id
    * @param i_epis_documentation          epis documentation id
    * @param i_flg_type                    A Agree, E edit, N - new 
    * @param i_id_documentation            array with id documentation,
    * @param i_id_doc_element              array with doc elements
    * @param i_id_doc_element_crit         array with doc elements crit
    * @param i_value                       array with values,
    * @param i_notes                       note
    * @param i_id_doc_element_qualif       array with doc elements qualif
    * @param i_vs_element_list             List of template's elements ID (id_doc_element) filled with vital signs
    * @param i_vs_save_mode_list           List of flags to indicate the applicable mode to save each vital signs measurement
    * @param i_vs_list                     List of vital signs ID (id_vital_sign)
    * @param i_vs_value_list               List of vital signs values
    * @param i_vs_uom_list                 List of units of measurement (id_unit_measure)
    * @param i_vs_scales_list              List of scales (id_vs_scales_element)
    * @param i_vs_date_list                List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param i_vs_read_list                List of saved vital sign measurement (id_vital_sign_read)    
    * @param o_error                       Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *                        
    * @return                              true or false on success or error
    *
    * @author                              Luís Gaspar & Luís Oliveira, based on pk_documentation.set_epis_bartchart
                                           Emilia Taborda
    * @version                             1.0                                       
    * @since                               26-05-2007
                                           2007/08/27
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
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    
    --
    /********************************************************************************************
    * Detalhe de uma queixa de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_complaint     the complaint episode id
    * @param i_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/06/15
    ********************************************************************************************/
    FUNCTION get_epis_complaint_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_complaint      IN epis_complaint.id_epis_complaint%TYPE,
        o_epis_compl_register OUT pk_types.cursor_type,
        o_epis_complaint_val  OUT pk_types.cursor_type,
       o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou uma queixa no episódio pretendido
    *
    * @param i_lang            id da lingua
    * @param i_prof            utilizador autenticado
    * @param i_episode         id do episódio
    * @param o_epis_complaint  id do registo da queixa. Se não houver registos este parametro vale null
    * @param o_date_last_epis      Data do último episódio
    * @param o_flg_data        Y if there are data, F when no date found    
    * @param o_error           Error message
    *                        
    * @return                  true or false on success or error
    *
    * @author                  João Eiras
    * @version                 1.0    
    * @since
    **********************************************************************************************/
    FUNCTION get_prof_compl_templ_exists
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_epis_complaint OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis OUT epis_complaint.adw_last_update_tstz%TYPE,
        o_flg_data       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /********************************************************************************************
    * Returns the active episode complaint. If there is no active complaint null is returned.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_id_complaint        The complaint id   
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Gaspar
    * @since                       17-Set-2007
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_epis_act_complaint
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_id_complaint OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve a última queixa e respectiva data de um episódio
    *
    * @param i_lang                  id da lingua
    * @param i_prof                  utilizador autenticado
    * @param i_episode               id do episódio 
    * @param o_last_epis_compl       Last complaint episode ID 
    * @param o_last_date_epis_compl  Data do último episódio
    * @param o_error                 Error message
    *                        
    * @return                        true or false on success or error
    *
    * @autor                         Emilia Taborda
    * @version                       1.0
    * @since                         2007/10/01
    **********************************************************************************************/
    FUNCTION get_last_complaint_templ
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        o_last_epis_compl      OUT epis_complaint.id_epis_complaint%TYPE,
        o_last_date_epis_compl OUT epis_complaint.adw_last_update_tstz%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * GETS THE COMPLAINT(S) ASSOCIATED TO THE REASON FOR VISIT. 
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_patient             patient ID
    * @param i_flg_type            register type: E - edit, N - new
    * @param i_dep_clin_serv       selected dep_clin_serv for complaint filter    
    * @param o_complaints          complaints cursor
    * @param o_compl_template      complaint associated with the chosen template
    * @param o_compl_root          epis_complaint ID containing the main info
    * @param o_doc_template        previous selected templates
    * @param o_appoint_type        Appointment type
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva (based on get_complaint_list)
    * @version                     1.0
    * @since                       09-10-2007
    **********************************************************************************************/
    FUNCTION get_reason_complaint_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_flg_type       IN VARCHAR2,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_complaints     OUT pk_types.cursor_type,
        o_compl_template OUT pk_types.cursor_type,
        o_compl_root     OUT epis_complaint.id_epis_complaint%TYPE,
        o_doc_template   OUT pk_types.cursor_type,
        o_appoint_type   OUT pk_types.cursor_type,
        o_flg_dcs_filter OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************
    * get list of complaints for an episode. This code was transferred from get_reason_complaint_list_all because 
    * it is needed elsewhere. Now the get_reason_complaint_list_all calls this function to fill it's own o_complaints
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_flg_type            register type: E - edit, N - new
    * @param o_complaints          complaints cursor
    * @param o_dcs_list            needed in get_reason_complaint_list_all
    * @param o_id_event            needed in get_reason_complaint_list_all
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Telmo Castro
    * @version                     2.4.3
    * @date                        02-09-2008
    */
    FUNCTION get_reason_complaint_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_dcs_list   OUT table_number,
        o_id_event   OUT sch_event.id_sch_event%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GETS THE COMPLAINT(S) ASSOCIATED TO THE REASON FOR VISIT. 
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_patient             patient ID
    * @param i_flg_type            register type: E - edit, N - new  
    * @param o_complaints          complaints cursor
    * @param o_compl_template      complaint associated with the chosen template
    * @param o_compl_root          epis_complaint ID containing the main info
    * @param o_doc_template        previous selected templates
    * @param o_appoint_type        Appointment type
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Sérgio Santos (based on get_reason_complaint_list)
    * @version                     1.0
    * @since                       09-10-2007
    **********************************************************************************************/
    FUNCTION get_reason_complaint_list_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_flg_type       IN VARCHAR2,
        o_complaints     OUT pk_types.cursor_type,
        o_compl_template OUT pk_types.cursor_type,
        o_compl_root     OUT epis_complaint.id_epis_complaint%TYPE,
        o_doc_template   OUT pk_types.cursor_type,
        o_appoint_type   OUT pk_types.cursor_type,
        o_flg_dcs_filter OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Registers complaints for episode. Internal function (does not commit).
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_pat_complaint           the patient complaint
    * @param i_flg_type                register type: E - edit, N - new 
    * @param i_flg_reported_by         who reported the complaint
    * @param i_dep_clin_serv           chosen appointment type to be associated with the scheduled episode    
    * @param i_parent                  the complaint id root from the group of complaints
    * @param o_epis_complaint          created record identifer
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Pedro Carneiro
    * @version                          2.5.0.7.5
    * @since                           2009-12-15 
    **********************************************************************************************/
    FUNCTION set_reason_epis_complaint_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_complaint       IN table_number,
        i_pat_complaint   IN epis_complaint.patient_complaint%TYPE,
        i_flg_type        IN epis_complaint.flg_edition_type%TYPE,
        i_flg_reported_by IN epis_complaint.flg_reported_by%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_parent          IN epis_complaint.id_epis_complaint_parent%TYPE,
        o_epis_complaint  OUT epis_complaint.id_epis_complaint%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    *  Registers a reason for visit and related complaints. 
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_patient_complaint       the patient complaint
    * @param i_flg_type                register type: E - edit, N - new 
    * @param i_flg_reported_by         who reported the complaint
    * @param i_template_chosen         chosen template to be used on the episode documentation
    * @param i_dep_clin_serv           chosen appointment type to be associated with the scheduled episode    
    * @param i_epis_complaint_parent   the complaint id root from the group of complaints
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          José Silva
    * @version                         1.0
    * @since                           09-10-2007
    **********************************************************************************************/
    FUNCTION set_reason_epis_complaint
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_complaint             IN table_number,
        i_patient_complaint     IN epis_complaint.patient_complaint%TYPE,
        i_flg_type              IN VARCHAR2,
        i_flg_reported_by       IN epis_complaint.flg_reported_by%TYPE,
        i_template_chosen       IN table_number,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_complaint_parent IN epis_complaint.id_epis_complaint%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_template_by_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN doc_template_context.flg_type%TYPE,
        i_search_name   IN VARCHAR2,
        o_doc_templates OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Registers a reason for visit and related complaints. 
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_patient_complaint       the patient complaint
    * @param i_flg_type                register type: E - edit, N - new 
    * @param i_flg_reported_by         who reported the complaint
    * @param i_template_chosen         chosen template to be used on the episode documentation
    * @param i_dep_clin_serv           chosen appointment type to be associated with the scheduled episode    
    * @param i_epis_complaint_parent   the complaint id root from the group of complaints
    * @param i_dt_init                 data de início de consulta
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Teresa Coutinho
    * @version                         1.0
    * @since                           09-05-2008
    **********************************************************************************************/
    FUNCTION set_reason_epis_complaint
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_complaint             IN table_number,
        i_patient_complaint     IN epis_complaint.patient_complaint%TYPE,
        i_flg_type              IN VARCHAR2,
        i_flg_reported_by       IN epis_complaint.flg_reported_by%TYPE,
        i_template_chosen       IN table_number,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_complaint_parent IN epis_complaint.id_epis_complaint%TYPE,
        i_dt_init               IN VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * gets the list of all complaints that can be used in the hospital group environment
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_filters                    cursor with all comnplaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   02-Dec-2010
    ********************************************************************************************/
    FUNCTION get_all_complaints_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --            
    /********************************************************************************************
    * Devolve a descrição do motivo de consulta (usado nas grelhas)
    *
    * @param i_lang                id da lingua
    * @param i_prof                objecto com info do utilizador
    * @param i_episode             id do episódio
    * @param i_episode             id do agendamento
    *
    * @return                      razao da consulta
    **********************************************************************************************/
    FUNCTION get_reason_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * gets the actions available in chief complaint
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_epis_complaint          epis complaint ID
    * @param      i_id_epis_anamnesis          epis anamnesis ID
    * @param      o_actions                    cursor with all actions
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Sofia Mendes
    * @since                                   21-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * gets the actions available in chief complaint
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_pn_epis_reason                    ID
    * @param      o_actions                    cursor with all actions
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Sofia Mendes
    * @since                                   21-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions_epis_reason
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_pn_epis_reason IN pn_epis_reason.id_pn_epis_reason%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get complaint for CDA section: Chief Complaint and Reason for Visit
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_complaint             Cursor with all complaints for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2013/12/23 
    ***********************************************************************************************/
    FUNCTION get_epis_complaint_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        o_complaint  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get_complaint_detail_hist
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Paulo Teixeira
    * @version                       2.6.3
    * @since                         2014/07/02 
    ***********************************************************************************************/
    FUNCTION get_complaint_detail_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get_complaint_detail
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Paulo Teixeira
    * @version                       2.6.3
    * @since                         2014/07/02 
    ***********************************************************************************************/
    FUNCTION get_complaint_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Cancel epis_complaint
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_epis_complaint     Epis Complaint ID
    * @param i_id_cancel_reason      Cancel Reason ID
    * @param i_notes_cancel          Notes cancel
    *
    * @param o_error                 error information
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-07-2014
    ***********************************************************************************************/
    FUNCTION cancel_compaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        i_id_cancel_reason  IN cancel_info_det.id_cancel_info_det%TYPE,
        i_notes_cancel      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel cancel_anamnesis
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param id_epis_anamnesis       Epis Anamnesis ID
    * @param i_id_cancel_reason      Cancel Reason ID
    * @param i_notes_cancel          Notes cancel
    *
    * @param o_error                 error information
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-07-2014
    ***********************************************************************************************/
    FUNCTION cancel_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_cancel_reason  IN cancel_info_det.id_cancel_info_det%TYPE,
        i_notes_cancel      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get complaint status.
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       Professional ID
    * @param      i_id_epis_complaint          Epis_complaint ID
    * @param      o_status                     Complaint status
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Vanessa Barsottelli
    * @version                                 2.6.4
    * @since                                   09-07-2014
    ********************************************************************************************/
    FUNCTION get_complaint_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        o_status            OUT epis_complaint.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get anamnesis status.
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       Professional ID
    * @param      i_id_epis_anamnesis          Epis_anamnesis ID
    * @param      o_status                     Complaint status
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Vanessa Barsottelli
    * @version                                 2.6.4
    * @since                                   09-07-2014
    ********************************************************************************************/
    FUNCTION get_anamnesis_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_status            OUT epis_complaint.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the active episode complaint. If there is no active complaint null is returned.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_error               Error message
    *
    * @return                      Episode complaint
    *
    * @author                      Sergio Dias
    * @since                       17/07/2014
    * @version                     2.6.4.1
    **********************************************************************************************/
    FUNCTION get_epis_act_complaint
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Returns a structured description of a chief complaint. 
    * Used in the Outpatient Single Page (Physician Progress Notes).
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_description         Description
    * @param o_error               Error message
    *
    * @return boolean              true or false on success or error
    *
    * @author                      Vanessa Barsotelli
    * @since                       31/07/2014
    * @version                     2.6.4.1
    **********************************************************************************************/
    FUNCTION get_complaint_amb_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_description OUT CLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_reported_by values
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param o_list                cursor values out
    * @param o_error               Error message
    *
    * @return boolean              true or false on success or error
    *
    * @author                      Paulo Teixeira
    * @since                       14/7/2016
    * @version                     2.6.5
    **********************************************************************************************/
    FUNCTION get_reported_by
    (
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_arabic_complaint
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_id_epis_complaint   i_id_epis_complaint
    *
    * @author                      Vítor Sá
    * @since                       23/04/2019
    * @version                     2.7.5.3
    **********************************************************************************************/
    FUNCTION get_arabic_complaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.patient_complaint_arabic%TYPE
    ) RETURN VARCHAR2;

    /**
    * Initialize parameters to be used in the grid query of complaints
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Elisabete Bugalho
    * @version              2.8.2.0
    * @since                2020/07/22
    */
    PROCEDURE init_params_complaint
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

    FUNCTION get_id_department
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Registers an episode set of complaints.
    * It is allowed to register complaints only in active episodes.
    * When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the array of complaint ids
    * @param i_patient_complaint       the array of patient complaints
    * @param i_flg_type                array of types of edition
    * @param i_id_epis_complaint_root  array of ids for the complaint parents
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                          true (sucess), false (error)
    **********************************************************************************************/
    FUNCTION set_epis_chief_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_complaint                IN table_number,
        i_complaint_alias          IN table_number,
        i_patient_complaint        IN VARCHAR2,
        i_patient_complaint_arabic IN VARCHAR2,
        i_flg_reported_by          IN epis_complaint.flg_reported_by%TYPE,
        i_flg_type                 IN VARCHAR2,
        i_id_epis_complaint_root   IN epis_complaint.id_epis_complaint_root%TYPE,
        o_id_epis_complaint        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_previous_complaints
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_episode                  IN episode.id_episode%TYPE,
        i_id_epis_complaint        IN epis_complaint.id_epis_complaint%TYPE,
        o_complaint_list           OUT pk_types.cursor_type,
        o_patient_complaint        OUT epis_complaint.patient_complaint%TYPE,
        o_patient_complaint_arabic OUT epis_complaint.patient_complaint_arabic%TYPE,
        o_flg_reported_by          OUT epis_complaint.flg_reported_by%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_complaint_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    FUNCTION get_complaint_description
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_complaint          IN complaint.id_complaint%TYPE,
        code_complaint       IN complaint.code_complaint%TYPE,
        i_complaint_alias    IN complaint_alias.id_complaint_alias%TYPE,
        code_complaint_alias IN complaint_alias.code_complaint_alias%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_complaint_search
    (
        i_lang   IN language.id_language%TYPE,
        i_search IN VARCHAR2
    ) RETURN table_t_search;

    FUNCTION get_multi_complaint_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint_root%TYPE,
        i_sep               IN VARCHAR2 DEFAULT ', '
    ) RETURN VARCHAR2;

    FUNCTION get_complaint_desc_sp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE
    ) RETURN CLOB;

    FUNCTION get_complaint_header
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_sep            IN VARCHAR2 DEFAULT ', ',
        o_last_complaint OUT VARCHAR2,
        o_complaints     OUT VARCHAR2,
        o_professional   OUT NUMBER,
        o_dt_register    OUT epis_complaint.adw_last_update_tstz%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_complaint_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    
  FUNCTION get_prof_signature
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_sign IN epis_hhc_req_det_h.id_prof_creation%TYPE,
        i_date         IN epis_hhc_req_det_h.dt_creation%TYPE
    ) RETURN VARCHAR2;
   
      FUNCTION tf_epis_complaint_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE
        
    ) RETURN t_tbl_complaints_hist ;     
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error VARCHAR2(32767);
    g_exception EXCEPTION;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    --
    g_comp_filter_prf CONSTANT VARCHAR2(4000) := 'PROFILE_TEMPLATE';
    g_comp_filter_dcs CONSTANT VARCHAR2(4000) := 'DEP_CLIN_SERV';
    --
    g_selected CONSTANT VARCHAR2(1) := 'S';
    g_yes      CONSTANT VARCHAR2(1) := 'Y';
    g_no       CONSTANT VARCHAR2(1) := 'N';
    g_canceled CONSTANT VARCHAR2(1) := 'C';
    --
    g_available CONSTANT VARCHAR2(1) := 'Y';
    g_active    CONSTANT VARCHAR2(1) := 'A';
    g_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_outdated  CONSTANT VARCHAR2(1) := 'O';
    --
    g_gender_f CONSTANT VARCHAR2(1) := 'F';
    g_gender_m CONSTANT VARCHAR2(1) := 'M';
    g_gender_i CONSTANT VARCHAR2(1) := 'I';
    --
    g_complaint_inact VARCHAR2(1) := 'I';
    g_complaint_act   VARCHAR2(1) := 'A';
    g_complaint_out   VARCHAR2(1) := 'O';
    --
    g_doc_area_complaint CONSTANT doc_area.id_doc_area%TYPE := 20;
    --
    g_flg_type_c  CONSTANT doc_template_context.flg_type%TYPE := 'C';
    g_flg_type_i  CONSTANT doc_template_context.flg_type%TYPE := 'I';
    g_flg_type_ct CONSTANT doc_template_context.flg_type%TYPE := 'CT';
    g_flg_type_dc CONSTANT doc_template_context.flg_type%TYPE := 'DC';
    --
    g_flg_temp_d           CONSTANT epis_anamnesis.flg_temp%TYPE := 'D';
    g_flg_temp_t           CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_flg_temp_h           CONSTANT epis_anamnesis.flg_temp%TYPE := 'H';
    g_epis_anam_flg_type_c CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    --
    g_flg_edit                   CONSTANT VARCHAR2(1) := 'E';
    g_flg_new                    CONSTANT VARCHAR2(1) := 'N';
    g_flg_edition_type_new       CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'N';
    g_flg_edition_type_edit      CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'E';
    g_flg_edition_type_agree     CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'A';
    g_flg_edition_type_update    CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'U';
    g_flg_edition_type_nochanges CONSTANT epis_anamnesis.flg_edition_type%TYPE := 'O';
    /*Multiple template allowed*/
    g_sys_cfg_multiple_template CONSTANT sys_config.id_sys_config%TYPE := 'MULTIPLE_TEMPLATE';

    g_scfg_complaint_cs_filter CONSTANT sys_config.id_sys_config%TYPE := 'COMPLAINT_CS_FILTER';
    g_comp_filter_e            CONSTANT VARCHAR2(2 CHAR) := 'E'; -- episode clinical service
    g_comp_filter_pp           CONSTANT VARCHAR2(2 CHAR) := 'PP'; -- professional preferencial 
    g_comp_filter_pa           CONSTANT VARCHAR2(2 CHAR) := 'PA'; -- professional alocation
    --Action Ids
    g_action_edit      CONSTANT PLS_INTEGER := 1;
    g_action_copy_edit CONSTANT PLS_INTEGER := 2;
    g_action_copy      CONSTANT PLS_INTEGER := 3;
    g_action_cancel    CONSTANT PLS_INTEGER := 4;

    g_report_p CONSTANT VARCHAR2(1) := 'P';
    g_report_e CONSTANT VARCHAR2(1) := 'E';

    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    /* Message stack for storing multiple warning/error messages. */
    g_msg_stack table_varchar;
    --
    g_touch_option CONSTANT VARCHAR2(1) := 'D';
    g_free_text    CONSTANT VARCHAR2(1) := 'N';

    g_reg_type_anamnesis      CONSTANT VARCHAR2(10 CHAR) := 'ANAMNESIS';
    g_reg_type_complaint      CONSTANT VARCHAR2(10 CHAR) := 'COMPLAINT';
    g_complaint_status_domain CONSTANT VARCHAR2(30 CHAR) := 'EPIS_COMPLAINT.FLG_STATUS';
    g_epis_complaint          CONSTANT VARCHAR2(30 CHAR) := 'EPIS_COMPLAINT';
    g_epis_anamnesis          CONSTANT VARCHAR2(30 CHAR) := 'EPIS_ANAMNESIS';

    g_long_notes CONSTANT cancel_info_det.flg_notes_cancel_type%TYPE := 'L';

    g_complaint_search_term CONSTANT VARCHAR2(200 CHAR) := 'COMPLAINT.CODE_COMPLAINT OR COMPLAINT_ALIAS.CODE_COMPLAINT_ALIAS';
END pk_complaint;
/
