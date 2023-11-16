/*-- Last Change Revision: $Rev: 1337953 $*/
/*-- Last Change by: $Author: tiago.silva $*/
/*-- Date of last change: $Date: 2012-07-02 17:00:54 +0100 (seg, 02 jul 2012) $*/

CREATE OR REPLACE PACKAGE pk_api_guidelines IS

    -- Author  : Carlos Loureiro
    -- Purpose : API for guidelines

    -- types used by PK_API_GUIDELINES.GET_APPLIED_GUIDELINES_LIST function
    TYPE t_rec_applied_guidelines IS RECORD(
        guideline_title      guideline.guideline_desc%TYPE,
        guideline_type       VARCHAR2(1000 CHAR),
        guideline_date       guideline_batch.dt_guideline_batch%TYPE,
        id_professional      guideline_process.id_professional%TYPE,
        id_guideline_process guideline_process.id_guideline_process%TYPE,
        dt_last_update       guideline_process.dt_status%TYPE);

    TYPE t_cur_applied_guidelines IS REF CURSOR RETURN t_rec_applied_guidelines;
    TYPE t_tbl_applied_guidelines IS TABLE OF t_rec_applied_guidelines;

    /*******************************************************************************************************************************************
    * Get get_guidprot_progress_notes
    *                                                                                                                                          *
    * @param LANG                     Id language                                                                                              *
    * @param I_PROF                   Profissional, institution and software identifiers                                                        *
    * @param i_patient                Id Patient    
    * @param I_EPISODE                Episode identifier                                                                                       * 
    * @param o_guidprot               Returns array with info of Guidelines and Protocols                                                      *
    *                                                                                                                                          *                                                                                                             *
    * @return                         Return false if any error ocurred and return true otherwise                                              *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Teresa Coutinho                                                                                           *
    * @version                         1.0                                                                                                     *
    * @since                          2009/03/27                                                                                              *
    *******************************************************************************************************************************************/
    FUNCTION get_guidprot_progress_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_guidprot OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all guidelines applied to a patient within an episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 patient ID
    * @param       i_episode                 episode ID
    * @param       i_flg_status              guideline process status
    * @param       o_guidelines_list         list of guidelines 
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2011/02/11
    ********************************************************************************************/
    FUNCTION get_applied_guidelines_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_status      IN guideline_process.flg_status%TYPE,
        o_guidelines_list OUT t_cur_applied_guidelines,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get frequent guidelines by institution
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_guidelines_frequent     cursor with all guidelines information (id_guideline, pathology_desc, guideline_desc, type_desc, flg_missing_data, flg_status, array(id_software, flg_type, type_desc))
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/20
    ********************************************************************************************/
    FUNCTION get_guidelines_frequent
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_guidelines_frequent   OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set guideline as frequent or non frequent
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_id_guideline            guideline id
    * @param       i_id_institution          institution id
    * @param       i_id_software             software id to wich the guideline frequentness will be updated
    * @param       i_flg_status              turn on/off frequent status for given guideline id
    * @param       o_error                   error message
    *
    * @value       i_flg_status              {*} F frequent (activate frequent) {*} S searchable (deactivate frequent)
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/02
    ********************************************************************************************/
    FUNCTION set_guideline_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_flg_status     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * copy or duplicate guideline
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_target_id_institution   target institution id
    * @param       i_id_guideline            source guideline id
    * @param       o_guideline               new guideline id
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/25
    ********************************************************************************************/
    FUNCTION copy_guideline
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline             OUT guideline.id_guideline%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel guideline / mark as deleted
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_id_guideline            guideline id to cancel
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/25
    ********************************************************************************************/
    FUNCTION cancel_guideline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get guideline main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      o_guideline_main             guideline main attributes cursor
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/23
    ********************************************************************************************/
    FUNCTION get_guideline_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_main        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get software list to wich guidelines are available
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_id_software             cursor with all softwares used by guidelines in target institution
    * @param       o_error                   error message
    *
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/18
    ********************************************************************************************/
    FUNCTION get_guidelines_software_list
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
    * @param      o_guideline_gender           cursor with all genders
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    *********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_criteria_type    IN guideline_criteria.criteria_type%TYPE,
        o_guideline_gender OUT pk_types.cursor_type,
        o_error            OUT t_error_out
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
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for guideline types
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_type             cursor with all guideline types
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for environment
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_environment      cursor with all environment availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION get_guideline_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_environment OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for professional
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_professional     cursor with all professional categories availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for ebm (evidence based medicine)
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_ebm              cursor with all ebm values availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_ebm_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        o_guideline_ebm OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for type of media
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_guideline_tm               cursor with all types of media
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_type_media_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_guideline_tm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for professionals that will be able to edit guidelines
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_professional     cursor with all professional categories availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_edit_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for types of guideline recommendation
    *
    * @param      i_lang                  preferred language id for this professional
    * @param      i_prof                  object (id of professional, id of institution, id of software)
    * @param      o_guideline_rec_mode    cursor with types of recommendation
    * @param      o_error                 error message
    *
    * @return     boolean                 true or false on success or error
    *
    * @author                             Carlos Loureiro
    * @version                            1.0
    * @since                              2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_type_rec_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_guideline_type_rec OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get guideline criteria
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      i_criteria_type              criteria type: inclusion / exclusion
    * @param      o_guideline_criteria         cursor for guideline criteria
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_criteria
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        i_criteria_type         IN guideline_criteria.criteria_type%TYPE,
        o_guideline_criteria    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get guideline task
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      o_guideline_task             cursor for guideline tasks
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_task
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_task        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get guideline context
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      o_guideline_context          cursor for guideline context
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_context
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_context     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get list of images for a specific guideline
    *
    * @param      i_lang                        preferred language id for this professional
    * @param      i_prof                        object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution       target institution id
    * @param      i_id_guideline_context_image  id of guideline image
    * @param      i_id_guideline                id of guideline
    * @param      o_context_images              images
    * @param      o_error                       error message
    *
    * @return     boolean                       true or false on success or error
    *
    * @author                                   Carlos Loureiro
    * @version                                  1.0
    * @since                                    2009/02/26
    ********************************************************************************************/
    FUNCTION get_context_images
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_target_id_institution      IN institution.id_institution%TYPE,
        i_id_guideline_context_image IN guideline_context_image.id_guideline_context_image%TYPE,
        i_id_guideline               IN guideline_context_image.id_guideline%TYPE,
        o_context_images             OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get multichoice for specialty
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      i_prof                      object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution     target institution id
    * @param      i_id_guideline              id of guideline.
    * @param      o_guideline_specialty       cursor with all specialty available
    * @param      o_error                     error
    *
    * @return     boolean                     true or false on success or error
    *
    * @author                                 Carlos Loureiro
    * @version                                1.0
    * @since                                  2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_specialty_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_specialty   OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set specific guideline main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      i_guideline_desc             guideline description       
    * @param      i_id_guideline_type          guideline type id list
    * @param      i_link_environment           guideline environment link list
    * @param      i_link_specialty             guideline specialty link list
    * @param      i_link_professional          guideline professional link list
    * @param      i_link_edit_prof             guideline edit professional link list
    * @param      i_type_recommendation        guideline type of recommendation
    * @param      o_id_guideline               guideline id associated with the new version
    * @param      o_error                      error message
    *
    * @value      i_type_recommendation        sys_domain where code_domain='GUIDELINE.FLG_TYPE_RECOMMENDATION'
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION set_guideline_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        i_guideline_desc        IN guideline.guideline_desc%TYPE,
        i_link_type             IN table_number,
        i_link_environment      IN table_number,
        i_link_specialty        IN table_number,
        i_link_professional     IN table_number,
        i_link_edit_prof        IN table_number,
        i_type_recommendation   IN guideline.flg_type_recommendation%TYPE,
        o_id_guideline          OUT guideline.id_guideline%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get available guideline items to be shown
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
    * @since                                    2009/02/27
    ********************************************************************************************/
    FUNCTION get_guideline_items
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_items                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get guideline missing flag status for backoffice use (internal use only)
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
    FUNCTION get_guideline_bo_status
    (
        i_id_guideline          IN guideline.id_guideline%TYPE,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_sw_list               IN table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * clear particular guideline processes or clear all guidelines processes related with
    * a list of patients or guidelines
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patients                patients array
    * @param       i_guidelines              guidelines array    
    * @param       i_guideline_processes     guideline processes array        
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Tiago Silva
    * @since                                 2010/11/02
    ********************************************************************************************/
    FUNCTION clear_guideline_processes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patients            IN table_number DEFAULT NULL,
        i_guidelines          IN table_number DEFAULT NULL,
        i_guideline_processes IN table_number DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete a list of guidelines and its processes
    *
    * @param       i_lang         preferred language id for this professional
    * @param       i_prof         professional id structure
    * @param       i_guidelines   guideline IDs
    * @param       o_error        error message
    *        
    * @return      boolean        true on success, otherwise false    
    *   
    * @author                     Tiago Silva
    * @since                      2010/11/02
    ********************************************************************************************/
    FUNCTION delete_guidelines
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_guidelines IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get guideline/task process details for a given patient
    * API for REPORTS
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      o_guideline_process          cursor with guideline process main information / context
    * @param      o_guideline_process_detail   cursor with all process tasks help information / context
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   12-Nov-2010
    ********************************************************************************************/
    FUNCTION get_guideline_process_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN guideline_process.id_patient%TYPE,
        o_guideline_process        OUT pk_types.cursor_type,
        o_guideline_process_detail OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
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
    g_guideline_enable_sysdomain CONSTANT VARCHAR2(30) := 'BACKOFFICE_GUIDELINE_PROTOCOL';

    -- guideline flag status (D means id_institution=0)
    g_default_flag     CONSTANT VARCHAR2(1) := 'D';
    g_cancelled_flag   CONSTANT VARCHAR2(1) := 'C';
    g_normal_flag      CONSTANT VARCHAR2(1) := 'N';
    g_recommended_flag CONSTANT VARCHAR2(1) := 'R';
    -- default values
    g_def_guideline_frequent_rank CONSTANT guideline_frequent.rank%TYPE := 0;
    g_duplicate_flag              CONSTANT VARCHAR2(1) := 'Y';
    g_new_version_flag            CONSTANT VARCHAR2(1) := 'N';

    -- Error message handling
    g_message_error    sys_message.code_message%TYPE := 'COMMON_M001';
    g_error            VARCHAR2(2000);
    g_log_object_name  VARCHAR2(50);
    g_log_object_owner VARCHAR2(50);

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
    g_batch_all   CONSTANT VARCHAR2(1 CHAR) := 'A'; -- all guidelines / all patients
    g_batch_1p_ag CONSTANT VARCHAR2(1 CHAR) := 'P'; -- one user /all guidelines
    g_batch_1p_1g CONSTANT VARCHAR2(1 CHAR) := 'O'; -- one user /one guidelines
    g_batch_ap_1g CONSTANT VARCHAR2(1 CHAR) := 'G'; -- all users /one guidelines    

END pk_api_guidelines;
/
