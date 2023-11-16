/*-- Last Change Revision: $Rev: 2028558 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_checklist_core IS

    -- Author  : ARIEL.MACHADO
    -- Created : 17-May-10 11:01:17 AM
    -- Purpose : Checklists: Core methods
    -- JIRA issue: ALERT-14485

    -- Public type declarations
    TYPE t_rec_unanswered_item IS RECORD(
        flg_content_creator checklist_item.flg_content_creator%TYPE,
        id_checklist_item   checklist_item.id_checklist_item%TYPE);

    TYPE t_coll_tab_unanswered_item IS TABLE OF t_rec_unanswered_item;

    -- Public constant declarations

    --Content creator: Checklist created by (A)LERT, Checklist created by (I)nstitution
    g_chklst_flg_creator_alert CONSTANT checklist.flg_content_creator%TYPE := 'A';
    g_chklst_flg_creator_inst  CONSTANT checklist.flg_content_creator%TYPE := 'I';

    --Checklist state: (A)ctive, (C) ancelled
    g_chklst_flg_status_active    CONSTANT checklist.flg_status%TYPE := 'A';
    g_chklst_flg_status_cancelled CONSTANT checklist.flg_status%TYPE := 'C';

    -- Checklist status in this institution: (A)ctive, (I)nactive
    g_chki_flg_status_active   CONSTANT checklist_inst.flg_status%TYPE := 'A';
    g_chki_flg_status_inactive CONSTANT checklist_inst.flg_status%TYPE := 'I';

    --Type of checklist: Checklist for (G)roup - same checklist for all professionals, (I)ndividual checklist - one checklist by professional
    g_chkv_flg_type_group      CONSTANT checklist_version.flg_type%TYPE := 'G';
    g_chkv_flg_type_individual CONSTANT checklist_version.flg_type%TYPE := 'I';

    --Checklist status: (A)ctive, (I)nterrupted, (C)ancelled
    g_pchk_flg_status_active      CONSTANT pat_checklist.flg_status%TYPE := 'A';
    g_pchk_flg_status_interrupted CONSTANT pat_checklist.flg_status%TYPE := 'I';
    g_pchk_flg_status_cancelled   CONSTANT pat_checklist.flg_status%TYPE := 'C';

    --Checklist progress status: (E)mpty, (P)artially filled, (C)ompletely filled
    g_pchk_flg_prg_status_empty    CONSTANT pat_checklist.flg_progress_status%TYPE := 'E';
    g_pchk_flg_prg_status_partial  CONSTANT pat_checklist.flg_progress_status%TYPE := 'P';
    g_pchk_flg_prg_status_complete CONSTANT pat_checklist.flg_progress_status%TYPE := 'C';
    g_pchk_flg_prg_status_new      CONSTANT pat_checklist.flg_progress_status%TYPE := 'N';

    --Answer given to a checklist item: (Y)es, (N)o, Not (A)pplicable
    g_pchkd_flg_answer_yes CONSTANT pat_checklist_det.flg_answer%TYPE := 'Y';
    g_pchkd_flg_answer_no  CONSTANT pat_checklist_det.flg_answer%TYPE := 'N';
    g_pchkd_flg_answer_na  CONSTANT pat_checklist_det.flg_answer%TYPE := 'A';

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Returns a list of unanswered items of a patient's checklist
    *
    * @param   i_pat_checklist Association ID (patient's checklist instance)
    *
    * @return  Collection of unanswered items (Pipelined function)
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   13-Jul-10
    */
    FUNCTION get_unanswered_items(i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE) RETURN t_coll_tab_unanswered_item
        PIPELINED;

    /**
    * Returns if exists a checklist identified by content creator & internal name
    *
    * @param   i_content_creator   Content creator
    * @param   i_internal_name     Checklist internal name
    *
    * @value   i_content_creator   {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    * @return  True or False on exists or not a checklist
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   01-Jun-10
    */
    FUNCTION exist_checklist
    (
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE
    ) RETURN BOOLEAN;

    /**
    * Returns if exists a checklist identified by content creator & checklist ID
    *
    * @param   i_content_creator   Content creator
    * @param   i_checklist         Checklist ID
    *
    * @value   i_content_creator   {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    * @return  True or False on exists or not a checklist
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   01-Jun-10
    */
    FUNCTION exist_checklist
    (
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_checklist       IN checklist.id_checklist%TYPE
    ) RETURN BOOLEAN;

    /**
    * Creates a new checklist
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_content                Content ID
    * @param   i_name                   Checklist name
    * @param   i_flg_type               Type of checklist
    * @param   i_profile_list           Authorized profiles for checklist
    * @param   i_clin_service_list      Specialties where checklist is applicable
    * @param   i_item_list              Checklist items
    * @param   i_item_profile_list      Authorized profiles for checklist items
    * @param   i_item_dependence_list   Dependences between checklist items
    * @param   o_checklist              Generated ID for checklist
    * @param   o_checklist_version      Generated ID for checklist version
    * @param   o_error                  Error information
    *
    * @value   i_flg_type               {*} 'G' Checklist for Group - same checklist for all professionals {*} 'I' Individual checklist - one checklist by professional
    * @value   i_content_creator        {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-May-10
    */
    FUNCTION create_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist.flg_content_creator%TYPE,
        i_internal_name        IN checklist.internal_name%TYPE,
        i_content              IN checklist.id_content%TYPE,
        i_name                 IN checklist_version.name%TYPE,
        i_flg_type             IN checklist_version.flg_type%TYPE,
        i_profile_list         IN table_table_varchar,
        i_clin_service_list    IN table_number,
        i_item_list            IN table_varchar,
        i_item_profile_list    IN table_table_number,
        i_item_dependence_list IN table_table_varchar,
        o_checklist            OUT checklist.id_checklist%TYPE,
        o_checklist_version    OUT checklist_version.id_checklist_version%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates definitions of a checklist (identified by content creator and internal name) creating a new version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_name                   Checklist name
    * @param   i_flg_type               Type of checklist
    * @param   i_profile_list           Authorized profiles for checklist
    * @param   i_clin_service_list      Specialties where checklist is applicable
    * @param   i_item_list              Checklist items
    * @param   i_item_profile_list      Authorized profiles for checklist items
    * @param   i_item_dependence_list   Dependences between checklist items
    * @param   o_checklist_version      Generated ID for new checklist version
    * @param   o_error                  Error information
    *
    * @value   i_flg_type               {*} 'G' Checklist for Group - same checklist for all professionals {*} 'I' Individual checklist - one checklist by professional
    * @value   i_content_creator        {*} 'A' ALERT {*} 'I' Institution
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION update_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_content_creator       IN checklist.flg_content_creator%TYPE,
        i_internal_name         IN checklist.internal_name%TYPE,
        i_name                  IN checklist_version.name%TYPE,
        i_flg_type              IN checklist_version.flg_type%TYPE,
        i_profile_list          IN table_table_varchar,
        i_clin_service_list     IN table_number,
        i_item_list             IN table_varchar,
        i_item_profile_list     IN table_table_number,
        i_item_dependence_list  IN table_table_varchar,
        o_new_checklist_version OUT checklist_version.id_checklist_version%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a checklist
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_content_creator    Checklist content creator
    * @param   i_internal_name      Checklist internal name
    * @param   i_cancel_reason      Cancel reason ID
    * @param   i_cancel_notes       Cancelation notes
    * @param   o_error              Error information
    *
    * @value   i_content_creator    {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION cancel_checklist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE,
        i_cancel_reason   IN checklist.id_cancel_reason%TYPE,
        i_cancel_notes    IN checklist.cancel_notes%TYPE,
        o_error           OUT t_error_out
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
    * @param   o_clin_service_list      Specialties where checklist is applicable
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
    * @since   04-Jun-10
    */
    FUNCTION get_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist_version.flg_content_creator%TYPE,
        i_checklist_version    IN checklist_version.id_checklist_version%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a specific checklist version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_version                Version number (is not an ID)
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
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
    * @since   04-Jun-10
    */
    FUNCTION get_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist_version.flg_content_creator%TYPE,
        i_internal_name        IN checklist_version.internal_name%TYPE,
        i_version              IN checklist_version.version%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
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
    * Gets a list of checklists for patient and where professional has authorization to visualize and/or fill them
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_patient        Patient ID 
    * @param   i_episode        Episode ID
    * @param   i_ignore_profile Ignore profissional's profile and returns all checklists for patient
    * @param   o_list           Checklist list
    * @param   o_error          Error information
    *
    * @value   i_ignore_profile {*} 'N' checklists where profissional's profile has authorization to visualize and/or fill (Default) {*} 'Y' ignore profissional's profile and return all checklists
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_ignore_profile IN VARCHAR2 DEFAULT 'N',
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
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
    * @value   i_filter_speciality    {*} 'Y' filter by specialities  {*} 'N' Unfiltered
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
        i_filter_speciality IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info about an associated checklist to patient, including info about association itself
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_pat_checklist          Association ID 
    * @param   o_checklist_info         Checklist information (name,type,author,etc.)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
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
    * @since   25-Jun-10
    */
    FUNCTION get_pat_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_checklist        IN pat_checklist.id_pat_checklist%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
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
    * @since   11-Jun-10
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
    * Checks if within the active checklists that are associated to patient exists checklists indicated as input argument
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_patient                Patient ID 
    * @param   i_episode                Episode ID
    * @param   i_tab_cnt_creator        List of Checklist content creator 
    * @param   i_tab_checklist_version  List of Checklist version ID
    * @param   o_exists                 There is at least a checklist in the input list that is associated to patient(Y/N)
    * @param   o_list                   List of checklist's name that are already associated to patient
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   2/11/2011
    */
    FUNCTION exist_pat_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_tab_cnt_creator       IN table_varchar,
        i_tab_checklist_version IN table_number,
        o_exists                OUT VARCHAR2,
        o_list                  OUT table_varchar,
        o_error                 OUT t_error_out
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
    * @version 2.6.0.5                                                        *
    * @since   15-Fev-11                                                      *
    **************************************************************************/
    FUNCTION set_pat_checklist_answer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat_checklist     IN pat_checklist.id_pat_checklist%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_tab_item          IN table_number,
        i_tab_answer        IN table_varchar,
        i_tab_notes         IN table_varchar,
        i_cnt_creator       IN pat_checklist.flg_content_creator%TYPE,
        i_checklist_version IN pat_checklist.id_checklist_version%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        o_tab_pat_checklist OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * For a specific checklist cancels all empty & active instances that are associated to patients
     Used when a checklist have been inactivated/canceled in the BackOffice
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_inst                   Institution/facility where checklist is used. Default: NULL (All facilities)
    * @param   o_error                  Error information
    *
    * @value   i_content_creator        {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.1
    * @since   30-May-11
    */
    FUNCTION cancel_pat_checklist_empty
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE,
        i_inst            IN institution.id_institution%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

END pk_checklist_core;
/
