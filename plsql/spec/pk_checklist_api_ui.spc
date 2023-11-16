/*-- Last Change Revision: $Rev: 2028557 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_checklist_api_ui IS

    -- Author  : ARIEL.MACHADO
    -- Created : 17-May-10 11:18:21 AM
    -- Purpose : Checklists: User interface methods
    -- JIRA issue: ALERT-14485

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Gets a list of checklists for patient and where professional has authorization to visualize and/or fill them
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID 
    * @param   i_episode      Episode ID
    * @param   o_list         Checklist list
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of available checklists for professional
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_filter_speciality Filter the list to only those checklist for specialties in which the professional is allocated
    * @param   o_list              Checklist list
    * @param   o_error             Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_prof_checklist_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_filter_speciality IN VARCHAR2 DEFAULT 'N',
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
        * Associates a list of specific versions of checklists to patient
        *
        * @param   i_lang                   Professional preferred language
        * @param   i_prof                   Professional identification and its context (institution and software)
        * @param   i_tab_cnt_creator        List of Checklist content creator 
        * @param   i_tab_checklist_version  List of Checklist version ID to associate
        * @param   i_patient                Patient ID 
        * @param   i_episode                Episode ID
        * @param   i_test                   Tests attempt to associate a checklist already associated (Y/N)
        * @param   o_tab_pat_checklist      List of created record IDs 
        * @param   o_flg_show               Set if a message is displayed or not
        * @param   o_msg_title              Message title
        * @param   o_msg                    Message body
        * @param   o_error                  Error information
        *
        * @return  True or False on success or error
        *
    * @author  ARIEL.MACHADO
        * @version 2.6.0.5
        * @since   2/11/2011
        */
    FUNCTION set_pat_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tab_cnt_creator       IN table_varchar,
        i_tab_checklist_version IN table_number,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_test                  IN VARCHAR2,
        o_tab_pat_checklist     OUT table_number,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a previous association of checklist to patient
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_pat_checklist  Association ID to cancel
    * @param   i_cancel_reason  Cancel reason ID
    * @param   i_cancel_notes   Cancelation notes
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION cancel_pat_checklist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE,
        i_cancel_reason IN pat_checklist.id_cancel_reason%TYPE,
        i_cancel_notes  IN pat_checklist.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info about an associated checklist to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_pat_checklist          Association ID 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_pat_checklist_info     Information related to the association between checklist and patient (requested by,status,cancel info,etc.)
    * @param   o_answer_data            Answers given
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_checklist        IN pat_checklist.id_pat_checklist%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_pat_checklist_info   OUT pk_types.cursor_type,
        o_answer_data          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Saves answers given in an associated checklist to patient
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_pat_checklist  Association ID 
    * @param   i_episode        Episode ID
    * @param   i_tab_item       List of cheklist item ID
    * @param   i_tab_answer     List of answers given
    * @param   i_tab_notes      List of observations in answers given
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION set_pat_checklist_answer
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_tab_item      IN table_number,
        i_tab_answer    IN table_varchar,
        i_tab_notes     IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets detailed information about an associated checklist to patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_pat_checklist      Association ID
    * @param   i_detail_level       Detail level 
    * @param   o_checklist_info     Checklist information (name,type,author,etc..)
    * @param   o_profile_list       Authorized profiles for checklist
    * @param   o_clin_service_list  Specialties where checklist is applicable
    * @param   o_item_list          Checklist items
    * @param   o_pat_checklist_info Information related to the association between checklist and patient(requested by,status,cancel info,etc.)
    * @param   o_answer_data        Answers given
    * @param   o_error              Error information
    *
    * @value   i_detail_level {*} 'G' General {*} 'H' History
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   11-Jun-10
    */
    FUNCTION get_pat_checklist_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_checklist      IN pat_checklist.id_pat_checklist%TYPE,
        i_detail_level       IN VARCHAR2,
        o_checklist_info     OUT pk_types.cursor_type,
        o_profile_list       OUT pk_types.cursor_type,
        o_clin_service_list  OUT pk_types.cursor_type,
        o_item_list          OUT pk_types.cursor_type,
        o_pat_checklist_info OUT pk_types.cursor_type,
        o_answer_data        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
		
    /**************************************************************************
    * Saves answers given in an associated checklist to patient               *
    *                                                                         *
    * @param   i_lang               Professional preferred language           *
    * @param   i_prof               Professional identification and its       *
    *                               context (institution and software)        *
    * @param   i_pat_checklist      Association ID                            *
    * @param   i_episode            Episode ID                                *
    * @param   i_tab_item           List of cheklist item ID                  *
    * @param   i_tab_answer         List of answers given                     *
    * @param   i_tab_notes          List of observations in answers given     *
    * @param   i_cnt_creator        List of Checklist content creator         *
    * @param   i_checklist_version  List of Checklist version ID to associate *
    * @param   i_patient            Patient ID                                *
    * @param   o_tab_pat_checklist  List of created record IDs                *
    * @param   o_error              Error information                         *
    *                                                                         *
    * @return  True or False on success or error                              *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.0.3                                                        *
    * @since   15-Fev-11                                                      *
    **************************************************************************/
    FUNCTION set_pat_checklist_answer
    (
        i_lang              IN language.id_language%TYPE
       ,i_prof              IN profissional
       ,i_pat_checklist     IN pat_checklist.id_pat_checklist%TYPE
       ,i_episode           IN episode.id_episode%TYPE
       ,i_tab_item          IN table_number
       ,i_tab_answer        IN table_varchar
       ,i_tab_notes         IN table_varchar
       ,i_cnt_creator       IN pat_checklist.flg_content_creator%TYPE
       ,i_checklist_version IN pat_checklist.id_checklist_version%TYPE
       ,i_patient           IN patient.id_patient%TYPE
       ,o_tab_pat_checklist OUT table_number
       ,o_error             OUT t_error_out
    ) RETURN BOOLEAN;		
	
    /**
    * Gets a specific checklist version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_checklist_version      Checklist version ID
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_error                  Error information
    *
    * @value   i_content_creator    {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   17-Fev-11
    */
    FUNCTION get_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist_version.flg_content_creator%TYPE,
        i_checklist_version    IN checklist_version.id_checklist_version%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

END pk_checklist_api_ui;
/
