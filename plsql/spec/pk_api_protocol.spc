/*-- Last Change Revision: $Rev: 1337953 $*/
/*-- Last Change by: $Author: tiago.silva $*/
/*-- Date of last change: $Date: 2012-07-02 17:00:54 +0100 (seg, 02 jul 2012) $*/

CREATE OR REPLACE PACKAGE pk_api_protocol IS

    -- Author  : Carlos Loureiro
    -- Purpose : API for protocols

    -- types used by PK_API_PROTOCOL.GET_APPLIED_PROTOCOLS_LIST function
    TYPE t_rec_applied_protocols IS RECORD(
        protocol_title      protocol.protocol_desc%TYPE,
        protocol_type       VARCHAR2(1000 CHAR),
        protocol_date       protocol_batch.dt_protocol_batch%TYPE,
        id_professional     guideline_process.id_professional%TYPE,
        id_protocol_process protocol_process.id_protocol_process%TYPE,
        dt_last_update      protocol_process.dt_status%TYPE);

    TYPE t_cur_applied_protocols IS REF CURSOR RETURN t_rec_applied_protocols;
    TYPE t_tbl_applied_protocols IS TABLE OF t_rec_applied_protocols;

    /********************************************************************************************
    * get all protocols applied to a patient within an episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 patient ID
    * @param       i_episode                 episode ID
    * @param       i_flg_status              protocol process status
    * @param       o_protocols_list          list of protocols
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2011/02/11
    ********************************************************************************************/
    FUNCTION get_applied_protocols_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status     IN guideline_process.flg_status%TYPE,
        o_protocols_list OUT t_cur_applied_protocols,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get frequent protocols by institution
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_protocols_frequent      cursor with all protocols information (id_protocols, pathology_desc, protocol_desc, type_desc, flg_missing_data, flg_status, array(id_software, flg_type, type_desc))
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocols_frequent
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_protocols_frequent    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set protocol as frequent or non frequent
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_id_protocol             protocol id
    * @param       i_id_institution          institution id
    * @param       i_id_software             software id to wich the protocol frequentness will be updated
    * @param       i_flg_status              turn on/off frequent status for given protocol id
    * @param       o_error                   error message
    *
    * @value       i_flg_status              {*} F frequent (activate frequent) {*} S searchable (deactivate frequent)
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION set_protocol_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    IN protocol.id_protocol%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_flg_status     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * copy or duplicate protocol
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_target_id_institution   target institution id
    * @param       i_id_protocol             source protocol id
    * @param       o_protocol                new protocol id
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION copy_protocol
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol              OUT protocol.id_protocol%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel protocol / mark as deleted
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_id_protocol             protocol id to cancel
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION cancel_protocol
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get protocol main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      o_protocol_main              protocol main attributes cursor
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_main         OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get software list to wich protocols are available
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_id_software             cursor with all softwares used by protocols in target institution
    * @param       o_error                   error message
    *
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocols_software_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_id_software           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for gender
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_criteria_type              criteria type
    * @param      o_protocol_gender            cursor with all genders
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    *********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_criteria_type   IN protocol_criteria.criteria_type%TYPE,
        o_protocol_gender OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for languages
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_languages                  cursor with all languages
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for protocol types
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol        
    * @param      o_protocol_type              cursor with all protocol types
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for environment
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                id of the protocol        
    * @param      o_protocol_environment       cursor with all environment availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION get_protocol_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_environment  OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for professional
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol
    * @param      o_protocol_professional      cursor with all professional categories availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for ebm (evidence based medicine)
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol         
    * @param      o_protocol_ebm               cursor with all ebm values availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_ebm_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_protocol  IN protocol.id_protocol%TYPE,
        o_protocol_ebm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for type of media
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_protocol_tm                cursor with all types of media
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_type_media_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_protocol_tm OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for professionals that will be able to edit protocols
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol        
    * @param      o_protocol_professional      cursor with all professional categories availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_edit_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for types of protocol recommendation
    *
    * @param      i_lang                  preferred language id for this professional
    * @param      i_prof                  object (id of professional, id of institution, id of software)
    * @param      o_protocol_rec_mode     cursor with types of recommendation
    * @param      o_error                 error message
    *
    * @return     boolean                 true or false on success or error
    *
    * @author                             Carlos Loureiro
    * @version                            1.0
    * @since                              2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_type_rec_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_protocol_type_rec OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get protocol criteria
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      i_criteria_type              criteria type: inclusion / exclusion
    * @param      o_protocol_criteria          cursor for protocol criteria
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_criteria
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        i_criteria_type         IN protocol_criteria.criteria_type%TYPE,
        o_protocol_criteria     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get protocol context
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      o_protocol_context           cursor for protocol context
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_context
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_context      OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get list of images for a specific protocol
    *
    * @param      i_lang                        preferred language id for this professional
    * @param      i_prof                        object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution       target institution id
    * @param      i_id_protocol_context_image   id of protocol image
    * @param      i_id_protocol                 id of protocol
    * @param      o_context_images              images
    * @param      o_error                       error message
    *
    * @return     boolean                       true or false on success or error
    *
    * @author                                   Carlos Loureiro
    * @version                                  1.0
    * @since                                    2009/03/03
    ********************************************************************************************/
    FUNCTION get_context_images
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_target_id_institution     IN institution.id_institution%TYPE,
        i_id_protocol_context_image IN protocol_context_image.id_protocol_context_image%TYPE,
        i_id_protocol               IN protocol_context_image.id_protocol%TYPE,
        o_context_images            OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for specialty
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      i_prof                      object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution     target institution id
    * @param      i_id_protocol               id of the protocol
    * @param      o_protocol_specialty        cursor with all specialty available
    * @param      o_error                     error
    *
    * @return     boolean                     true or false on success or error
    *
    * @author                                 Carlos Loureiro
    * @version                                1.0
    * @since                                  2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_specialty_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_specialty    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set specific protocol main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      i_protocol_desc              protocol description       
    * @param      i_id_protocol_type           protocol type id list
    * @param      i_link_environment           protocol environment link list
    * @param      i_link_specialty             protocol specialty link list
    * @param      i_link_professional          protocol professional link list
    * @param      i_link_edit_prof             protocol edit professional link list
    * @param      i_type_recommendation        protocol type of recommendation
    * @param      o_id_protocol                protocol id associated with the new version
    * @param      o_error                      error message
    *
    * @value      i_type_recommendation        sys_domain where code_domain='PROTOCOL.FLG_TYPE_RECOMMENDATION'
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION set_protocol_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        i_protocol_desc         IN protocol.protocol_desc%TYPE,
        i_link_type             IN table_number,
        i_link_environment      IN table_number,
        i_link_specialty        IN table_number,
        i_link_professional     IN table_number,
        i_link_edit_prof        IN table_number,
        i_type_recommendation   IN protocol.flg_type_recommendation%TYPE,
        o_id_protocol           OUT protocol.id_protocol%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get available protocol items to be shown
    *
    * @param      i_lang                        preferred language id for this professional
    * @param      i_prof                        object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution       target institution id
    * @param      o_items                       list of items to be shown
    * @param      o_error                       error message
    *
    * @return     boolean                       true or false on success or error
    *
    * @author                                   Carlos Loureiro
    * @version                                  1.0
    * @since                                    2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_items
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_items                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get protocol diagram structure
    *
    * @param      i_lang                       prefered language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                protocol id
    * @param      o_protocol_elements          cursor for protocol elements
    * @param      o_protocol_details           cursor for protocol elements details as tasks
    * @param      o_protocol_relation          cursor for protocol relations    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_diagram
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol              IN protocol.id_protocol%TYPE,
        o_protocol_elements        OUT pk_types.cursor_type,
        o_protocol_element_details OUT pk_types.cursor_type,
        o_protocol_relations       OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get protocol missing flag status for backoffice use (internal use only)
    *
    * @param      i_id_guideline               guideline id
    * @param      i_target_id_institution      target institution id
    * @param      i_sw_list                    list of allowed softwares  
    *
    * @return     varchar2                     backoffice missing flag status
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/05
    ********************************************************************************************/
    FUNCTION get_protocol_bo_status
    (
        i_id_protocol           IN protocol.id_protocol%TYPE,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_sw_list               IN table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * clear particular protocol processes or clear all protocols processes related with
    * a list of patients or protocols
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patients                patients array
    * @param       i_protocols               protocols array    
    * @param       i_protocol_processes      protocol processes array         
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Tiago Silva
    * @since                                 2010/11/02
    ********************************************************************************************/
    FUNCTION clear_protocol_processes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patients           IN table_number DEFAULT NULL,
        i_protocols          IN table_number DEFAULT NULL,
        i_protocol_processes IN table_number DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete a list of protocols and its processes
    *
    * @param       i_lang        preferred language id for this professional
    * @param       i_prof        professional id structure
    * @param       i_protocols   protocol IDs
    * @param       o_error       error message
    *        
    * @return      boolean       true on success, otherwise false    
    *   
    * @author                    Tiago Silva
    * @since                     2010/11/02
    ********************************************************************************************/
    FUNCTION delete_protocols
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_protocols IN table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get protocol process details for a given patient
    * API for REPORTS
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      o_protocol_process           cursor with protocol process main information / context
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   12-Mar-2011
    ********************************************************************************************/
    FUNCTION get_protocol_process_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN protocol_process.id_patient%TYPE,
        o_protocol_process OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- separators
    g_separator_link_str   CONSTANT VARCHAR2(2) := ', ';
    g_separator_collection CONSTANT VARCHAR2(1) := ',';

    -- frequent flag (active/inactive)
    g_searcheable CONSTANT VARCHAR2(1) := 'S';
    g_frequent    CONSTANT VARCHAR2(1) := 'F';
    g_undefined   CONSTANT VARCHAR2(1) := 'U';

    -- frequent action status flag (active/inactive)
    g_activate   CONSTANT VARCHAR2(1) := 'F';
    g_deactivate CONSTANT VARCHAR2(1) := 'S';

    -- searchable/frequent/disable flag sys domain code
    g_protocol_enable_sysdomain CONSTANT VARCHAR2(30) := 'BACKOFFICE_GUIDELINE_PROTOCOL';

    -- protocol flag status (D means id_institution=0)
    g_default_flag   CONSTANT VARCHAR2(1) := 'D';
    g_cancelled_flag CONSTANT VARCHAR2(1) := 'C';
    g_normal_flag    CONSTANT VARCHAR2(1) := 'N';

    -- default values
    g_def_protocol_frequent_rank CONSTANT protocol_frequent.rank%TYPE := 0;
    g_duplicate_flag             CONSTANT VARCHAR2(1) := 'Y';
    g_new_version_flag           CONSTANT VARCHAR2(2) := 'N';

    -- log mechanism
    g_error            VARCHAR2(2000);
    g_log_object_owner VARCHAR2(50);
    g_log_object_name  VARCHAR2(50);

    -- constant flags for mni and viewer (to filter records from sw list)
    g_mni_flg    CONSTANT VARCHAR2(1) := 'Y';
    g_viewer_flg CONSTANT VARCHAR2(1) := 'N';

    -- other status
    g_professional_active    CONSTANT VARCHAR2(1) := 'A';
    g_professional_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_professional_suspended CONSTANT VARCHAR2(1) := 'A';
    g_available              CONSTANT VARCHAR2(1) := 'Y';
    g_unavailable            CONSTANT VARCHAR2(1) := 'N';

    -- return status
    g_missing_flg_no  CONSTANT VARCHAR2(1) := 'N';
    g_missing_flg_yes CONSTANT VARCHAR2(1) := 'Y';

    -- Batch types
    g_batch_all   CONSTANT VARCHAR2(1 CHAR) := 'A'; -- all protocol / all patients
    g_batch_1p_ag CONSTANT VARCHAR2(1 CHAR) := 'P'; -- one user /all protocol
    g_batch_1p_1g CONSTANT VARCHAR2(1 CHAR) := 'O'; -- one user /one protocol
    g_batch_ap_1g CONSTANT VARCHAR2(1 CHAR) := 'G'; -- all users /one protocol

END pk_api_protocol;
/
