/*-- Last Change Revision: $Rev: 2028710 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hand_off_core IS

    -- Author  : JOSE.BRITO
    -- Created : 12-10-2009 11:58:08
    -- Purpose : Hand-off internal functions

    -- Public constant declarations
    g_empr_flg_resp_type_o     CONSTANT epis_multi_prof_resp.flg_resp_type%TYPE := 'O'; --Overrall
    g_empr_flg_resp_type_e     CONSTANT epis_multi_prof_resp.flg_resp_type%TYPE := 'E'; --Episode
    g_cur_resp_grid_flg_show_a CONSTANT VARCHAR2(1) := 'A'; --Current Resp Grid Show all (Physicians and nurses)
    g_resp_type_m              CONSTANT VARCHAR2(1) := 'M'; --Main responsability
    g_resp_type_o              CONSTANT VARCHAR2(1) := 'O'; --Overrall responsability
    g_resp_type_e              CONSTANT VARCHAR2(1) := 'E'; --Episode responsability
    g_msg_type_b               CONSTANT VARCHAR2(1) := 'B'; --Responsability begin
    g_msg_type_t               CONSTANT VARCHAR2(1) := 'T'; --Responsability transfer
    g_msg_type_s               CONSTANT VARCHAR2(1) := 'S'; --Responsability switch
    g_overall_tab_oncall       CONSTANT VARCHAR2(1) := 'O'; --On call physicians
    g_overall_tab_dbc          CONSTANT VARCHAR2(1) := 'D'; --DBC owners
    g_overall_tab_prev         CONSTANT VARCHAR2(1) := 'P'; --Previous responsibles
    g_overall_tab_spec         CONSTANT VARCHAR2(1) := 'S'; --All specialties

    g_prof_type_req CONSTANT VARCHAR2(1) := 'R'; -- PROF_REQ
    g_prof_type_to  CONSTANT VARCHAR2(1) := 'T'; -- PROF_TO OR PROF_COMP

    g_flg_status_a CONSTANT VARCHAR2(1 CHAR) := 'A'; --FLG_STATUS ACTIVE
    -- Public variable declarations
    g_resp_type_exception EXCEPTION;

    /**
    * Gets config show overall_resp
    *
    * @param   i_prof      professional, institution and software ids
    * @param   i_prof_cat  Professional category
    *
    * @return              'Y' if is to include overall responsibles, otherwise 'N'
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_show_overall_resp
    (
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN sys_config.value%TYPE;

    /********************************************************************************************
    * Assign the configured hand-off type to a given variable.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   io_hand_off_type       configured hand-off type
    *                        
    * @return  The configured hand-off type.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    PROCEDURE get_hand_off_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        io_hand_off_type IN OUT sys_config.value%TYPE
    );

    /********************************************************************************************
    * Get the maximum episode responsability request date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    * @param   i_flg_type             episode responsability type: (N)urse or (P)hysician
    * @param   i_flg_profile          profile type: S - specialist, R - resident, I - intern
    *                        
    * @return  Maximum request date
    * 
    * @author                         Jose Silva
    * @version                        2.5
    * @since                          12-10-2010
    **********************************************************************************************/
    FUNCTION get_max_dt_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_hand_off_type IN VARCHAR2
    ) RETURN epis_prof_resp.dt_request_tstz%TYPE;

    /********************************************************************************************
    * Cancel a given hand-off request if was destinated to the current professional's department.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_cs_dest              destination clinical service
    * @param   i_dpt_dest             destination department
    * @param   i_id_epis_prof_resp    hand-off request ID
    * @param   i_flg_profile          type of profile
    * @param   i_hand_off_type        type of hand-off mechanism
    * @param   i_id_speciality        Speciality for the current transfer
    * @param   i_flg_resp_type        Type of responsability: (E) Episode (O) Overall
    * @param   o_error                error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          02-10-2009
    **********************************************************************************************/
    FUNCTION cancel_dpt_hand_off_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cs_dest           IN clinical_service.id_clinical_service%TYPE,
        i_dpt_dest          IN department.id_department%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_resp_type     IN epis_multi_prof_resp.flg_resp_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks responsability over the episode, when accessing the patient's EHR.
    * Allows to retrieve all the necessary data to configure the responsability message boxes.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   o_show_msg_box             Show message box?
    *                                          (N) No, don't show any
    *                                          (E) Episode responsability message box, only
    *                                          (O) Overall responsability message box, only
    *                                          (A) All, show both episode and overall responsability message boxes
    * @param   o_flg_hand_off_type        Type of hand-off: (N) Normal (M) Multiple
    * @param   o_responsibles             List of ALL responsabiles for this episode
    * @param   o_episode_resp_box         Data for the EPISODE message box
    * @param   o_overall_resp_box         Data for the OVERALL message box
    * @param   o_episode_resp_options     Options for the EPISODE message box
    * @param   o_overall_resp_options     Options for the OVERALL message box
    * @param   o_labels_grid              Grid labels
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION check_prof_resp
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN epis_info.id_episode%TYPE,
        o_show_msg_box         OUT VARCHAR2,
        o_flg_hand_off_type    OUT VARCHAR2,
        o_responsibles         OUT pk_types.cursor_type,
        o_overall_resp_box     OUT pk_types.cursor_type,
        o_episode_resp_options OUT pk_types.cursor_type,
        o_labels_grid          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the type of profile template.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_profile_template     profile template ID
    * @param   o_flg_profile          type of profile
    * @param   o_error                error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          02-10-2009
    **********************************************************************************************/
    FUNCTION get_flg_profile
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        o_flg_profile      OUT profile_template.flg_profile%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the type of profile template.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_profile_template     profile template ID
    *                        
    * @return  type of profile
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          02-10-2009
    **********************************************************************************************/
    FUNCTION get_flg_profile
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the ID's of the profiles for which the current professional 
    * can make a hand-off request. Can be used for both normal and multiple hand-off mechanisms.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_profile_templ_req     Profile template ID of the current professional
    * @param   i_flg_type                 type of category (D) Physician (N) Nurse
    * @param   i_flg_resp_type            (E - default) Episode or (O) Overall responsability
    * @param   o_profiles                 Profile template ID's
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          09-10-2009
    **********************************************************************************************/
    FUNCTION get_allowed_profiles
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_profile_templ_req IN profile_template.id_profile_template%TYPE,
        i_flg_type             IN category.flg_type%TYPE,
        i_flg_resp_type        IN handoff_permission_inst.flg_resp_type%TYPE DEFAULT 'E',
        o_profiles             OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the type of profiles (specialists, residents, interns, nurses...)
    * for which the current professional can make a hand-off request.
    *
    * IMPORTANT!! Currently this function only is supported by the MULTIPLE
    *             hand-off mechanism.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_profile_templ_req     Profile template ID of the current professional
    * @param   i_flg_type                 type of category (D) Physician (N) Nurse
    * @param   i_flg_resp_type            (E - default) Episode or (O) Overall responsability
    * @param   o_flg_profiles             Profile types
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          09-10-2009
    **********************************************************************************************/
    FUNCTION get_allowed_profile_types
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_profile_templ_req IN profile_template.id_profile_template%TYPE,
        i_flg_type             IN category.flg_type%TYPE,
        i_flg_resp_type        IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        o_flg_profiles         OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    * @param   i_only_main_overall        In multiple hand-off, for specialists, set as 'Y' (default) to check for MAIN OVERALL.
                                           Set as 'N', to check for all overall responsibles (Main included).
    * @param   o_epis_status              Episode status (active, inactive, cancelled, etc.)
    * @param   o_id_prof_resp             ID of the responsible professional (physician OR nurse)
    * @param   o_prof_name                Name of the responsible professional
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof_cat          IN category.flg_type%TYPE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_flg_resp_type     IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_only_main_overall IN VARCHAR2 DEFAULT 'Y',
        o_epis_status       OUT episode.flg_status%TYPE,
        o_id_prof_resp      OUT professional.id_professional%TYPE,
        o_prof_name         OUT professional.name%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns the episode status, and the responsible professionals for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    * @param   i_only_main_overall        In multiple hand-off, for specialists, set as 'Y' (default) to check for MAIN OVERALL.
                                           Set as 'N', to check for all overall responsibles (Main included).
    * @param   o_epis_status              Episode status (active, inactive, cancelled, etc.)
    * @param   o_id_prof_resp             ID of professionals responsible for episode (physician OR nurse)
    * @param   o_prof_name                Name of the responsibles professionals
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    **********************************************************************************************/

    FUNCTION get_prof_resp_by_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof_cat          IN category.flg_type%TYPE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_flg_resp_type     IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_only_main_overall IN VARCHAR2 DEFAULT 'Y',
        o_epis_status       OUT episode.flg_status%TYPE,
        o_id_prof_resp      OUT table_number,
        o_prof_name         OUT table_varchar,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    * @param   o_epis_status              Episode status (active, inactive, cancelled, etc.)
    * @param   o_id_prof_resp             ID of the responsible professional (physician OR nurse)
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality IN epis_multi_prof_resp.id_speciality%TYPE,
        o_epis_status   OUT episode.flg_status%TYPE,
        o_id_prof_resp  OUT professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the episode status, and the responsible professional for the episode, according
    * to the professional category and the hand-off type (normal or multiple).
    * IMPORTANT: Database internal function.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_profile              Type of profile (S) Specialist (R) Resident (I) Intern (N) Nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_resp_type            Type of responsability (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability speciality
    *                        
    * @return  Professional ID
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          03-11-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp_by_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_id_speciality IN epis_multi_prof_resp.id_speciality%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Checks the ID_EPISODE of a requested hand-off transfer.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Hand-off request ID
    * @param   i_hand_off_type            Hand-off mechanism (N)ormal (M)ultiple
    * @param   i_flg_profile              Type of profile (S)pecialist (R)esident (I)ntern (N)urse
    * @param   i_flg_transf_type          Type of transfer (E)pisode (O)verall
    * @param   o_epis_prof_resp           Hand-off request complete record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_existing_handoff_req_by_id
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type     IN sys_config.value%TYPE,
        i_flg_profile       IN profile_template.flg_profile%TYPE,
        i_flg_transf_type   IN epis_prof_resp.flg_transf_type%TYPE,
        o_id_episode        OUT episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if exists a requested hand-off transfer.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_req_status               Hand-off request status
    * @param   i_transf_type              Hand-off request transfer type (e.g. Individual)
    * @param   i_flg_type                 Hand-off request to physician (D) or nurse (N)
    * @param   i_flg_profile              Type of profile (S)pecialist (R)esident (I)ntern (N)urse
    * @param   i_hand_off_type            Hand-off mechanism (N)ormal (M)ultiple
    * @param   i_id_speciality            Responsability speciality
    * @param   o_epis_prof_resp           Hand-off request complete record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          12-10-2009
    **********************************************************************************************/
    FUNCTION get_existing_handoff_req
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_req_status      IN epis_prof_resp.flg_status%TYPE,
        i_transf_type     IN epis_prof_resp.flg_transf_type%TYPE,
        i_flg_type        IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile     IN profile_template.flg_profile%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        i_id_speciality   IN epis_multi_prof_resp.id_speciality%TYPE,
        i_id_professional IN epis_prof_resp.id_prof_comp%TYPE DEFAULT NULL,
        o_epis_prof_resp  OUT epis_prof_resp%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if an episode has a responsible specialist physician.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_hand_off_type            Type of hand-off mechanism (N)ormal (M)ultiple
    * @param   o_has_specialist           (Y) has a responsible specialist (N) doesn't have a responsible specialist
    * @param   o_specialist_name          Specialist name
    * @param   o_speciality               Speciality description
    * @param   o_profile_desc             Profile type description for specialist physicians
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION has_responsible_specialist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        o_has_specialist  OUT VARCHAR2,
        o_specialist_name OUT professional.name%TYPE,
        o_speciality      OUT VARCHAR2,
        o_profile_desc    OUT sys_domain.desc_val%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a string with the responsible TEAM, formatted according to the hand-off type.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_dept                     Department ID
    * @param   i_soft                     Software ID
    * @param   i_prof_resp_doc            Responsible physician
    * @param   i_prof_resp_nurse          Responsible nurse
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_team_str                 Team name (if available)
    *                        
    * @return  Formatted string
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_team_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dept            IN department.id_department%TYPE,
        i_soft            IN software.id_software%TYPE,
        i_prof_resp_doc   IN professional.id_professional%TYPE,
        i_prof_resp_nurse IN professional.id_professional%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        i_team_str        IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a string with the responsible professionals, FOR A CERTAIN TYPE/CATEGORY
    * formatted according to the place where it will be displayed (grids, tooltips).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_flg_profile              Type of profile
    * @param   i_format                   Format text to show in (G) Grids (T) Tooltips
    *                        
    * @return  Formatted string
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.5
    * @since                          27-JAN-2011
    **********************************************************************************************/
    FUNCTION get_resp_by_type_grid_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_profile   IN epis_multi_prof_resp.flg_profile%TYPE,
        i_format        IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a string with the responsible professionals, formatted according to the place
    * where it will be displayed (grids, tooltips).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_prof_cat                 Professional category
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Main responsible professional ID (specialist physician or nurse)
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_format                   Format text to show in (G) Grids (T) Tooltips
    * @param   i_only_show_epis_resp      Is to only show the episode responsibles in the grids? Y - Yes; N - Otherwise;
    *                        
    * @return  Formatted string
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_cat            IN category.flg_type%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_hand_off_type       IN sys_config.value%TYPE,
        i_format              IN VARCHAR2,
        i_only_show_epis_resp IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_my_patients              Called from a 'My patients' grid: (Y) Yes (N) No - default
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN table_number;

    /********************************************************************************************
    * Verifies the permission to activate the OK and CANCEL buttons in the hand-off requests list
    * for the episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_button                   Button to validate (O) OK (C) CANCEL
    * @param   i_flg_status_req           Status of the request
    * @param   i_prof_req                 Professional who made the request
    * @param   i_prof_to                  Destination professional
    * @param   i_prof_comp                Professional who accepted the request
    * @param   i_flg_profile_req          Type of profile of the request (S)/(R)/(I)/(N)
    * @param   i_flg_profile_prof         Type of profile of the current professional
    * @param   i_flg_type                 Hand-off category (D)/(N)
    * @param   i_prof_cat                 Professional category
    * @param   i_hand_off_type            Type of hand-off mechanism (N) Normal (M) Multiple
    * @param   i_speciality_req           Hand-off request speciality
    * @param   i_speciality_prof          Speciality of the current professional
    * @param   i_episode                  Episode id
    * @param   i_flg_main_responsible     Professional is main overall responsible (Y)/(N)
    *                        
    * @return  (Y) to activate button (N) to inactivate
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          23-10-2009
    **********************************************************************************************/
    FUNCTION get_button_permission
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_button               IN VARCHAR2,
        i_flg_status_req       IN epis_prof_resp.flg_status%TYPE,
        i_prof_req             IN epis_prof_resp.id_prof_req%TYPE,
        i_prof_to              IN epis_prof_resp.id_prof_to%TYPE,
        i_prof_comp            IN epis_prof_resp.id_prof_comp%TYPE,
        i_flg_profile_req      IN epis_multi_prof_resp.flg_profile%TYPE,
        i_flg_profile_prof     IN profile_template.flg_profile%TYPE,
        i_flg_type             IN epis_prof_resp.flg_type%TYPE,
        i_prof_cat             IN category.flg_type%TYPE,
        i_hand_off_type        IN sys_config.value%TYPE,
        i_speciality_req       IN epis_multi_prof_resp.id_speciality%TYPE,
        i_speciality_prof      IN epis_multi_prof_resp.id_speciality%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_main_responsible IN epis_multi_prof_resp.flg_main_responsible%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Manages the possibility to make hand-off requests (episode or overall) according
    * to the permissions set to the current profile, and current state of the episode responsability.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_profile_templ_req     Profile of the current professional
    * @param   i_prof_cat_req             Category of the current professional
    * @param   i_flg_type                 Type of request: nurse or physician hand-off request
    * @param   i_flg_resp_type            Responsability type: (E) Episode (O) Overall
    * @param   i_flg_profile              Type of profile of the current professional
    * @param   i_hand_off_type            Type of hand-off: (N) Normal (M) Multiple
    * @param   i_id_speciality            Speciality ID of the current professional
    * @param   o_full_permission          Current professional has permission to make hand-off requests? Y/N
    * @param   o_req_to_self              Current professional can make a request to him/herself? Y/N
    * @param   o_req_to_other             Current professional can make a request to other professional? Y/N
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          18-10-2010
    **********************************************************************************************/
    FUNCTION check_request_permission
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_profile_templ_req IN profile_template.id_profile_template%TYPE,
        i_prof_cat_req         IN category.flg_type%TYPE,
        i_flg_type             IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp_type        IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_flg_profile          IN profile_template.flg_profile%TYPE,
        i_hand_off_type        IN sys_config.value%TYPE,
        i_id_speciality        IN epis_multi_prof_resp.id_speciality%TYPE,
        o_full_permission      OUT VARCHAR2,
        o_req_to_self          OUT VARCHAR2,
        o_req_to_other         OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the options to display in the hand-off internal button, 
    * for the ACTIONS/VIEWS buttons.
    *
    * This method is not intended to set permissions for each option. Insted this will be managed
    * by Flash according to the values of flags embedded in the cursors returned by GET_EPIS_PROF_RESP_ALL.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_flg_type                 Context of hand-off: physician or nurse hand-off
    * @param   o_id_epis_multi_prof_resp  New multiple hand-off record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          18-10-2010
    **********************************************************************************************/
    FUNCTION get_hand_off_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_prof_resp.flg_type%TYPE,
        o_actions  OUT pk_types.cursor_type,
        o_views    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Manages the multiple hand-off mechanism data. This function must be called when
    * a responsible for a patient is changed.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             New responsible for the patient
    * @param   i_flg_profile              Type of profile
    * @param   i_id_epis_prof_resp        Hand-off transfer request ID
    * @param   i_flg_status               Hand-off transfer request new status
    * @param   i_sysdate                  Current date
    * @param   i_hand_off_type            Type of hand-off mechanism (N)ormal (M)ultiple
    * @param   i_flg_main_responsible     Is main overall responsible? (Y) Yes (N) No - default.    
    * @param   i_id_speciality            Physician speciality. Null value for nurses.
    * @param   i_flg_resp_type            Responsability type: (E) Episode (O) Overall
    * @param   o_id_epis_multi_prof_resp  New multiple hand-off record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          13-10-2009
    **********************************************************************************************/
    FUNCTION set_multi_prof_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN professional.id_professional%TYPE,
        i_flg_profile             IN epis_multi_prof_resp.flg_profile%TYPE,
        i_id_epis_prof_resp       IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_status              IN epis_prof_resp.flg_status%TYPE,
        i_sysdate                 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_hand_off_type           IN sys_config.value%TYPE,
        i_flg_main_responsible    IN epis_multi_prof_resp.flg_main_responsible%TYPE DEFAULT 'N',
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_resp_type           IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_priority                IN NUMBER DEFAULT NULL,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets history for the multiple hand-off responsability.
    *
    * @param   i_lang                           Language ID
    * @param   i_prof                           Professional data
    * @param   i_epis_multi_rec                 EPIS_MULTI_PROF_RESP row
    * @param   o_id_epis_multi_profresp_hist    History ID
    * @param   o_error                          Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          15-10-2010
    **********************************************************************************************/
    FUNCTION set_multi_prof_resp_hist
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_epis_multi_rec              IN epis_multi_prof_resp%ROWTYPE,
        o_id_epis_multi_profresp_hist OUT epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets history for the multiple hand-off responsability, using rowids.
    *
    * @param   i_lang                           Language ID
    * @param   i_prof                           Professional data
    * @param   i_rowids                         Array with rowids
    * @param   o_ids                            Array with created history record ID's
    * @param   o_error                          Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          15-10-2010
    **********************************************************************************************/
    FUNCTION set_multi_prof_resp_hist_rows
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar,
        o_ids    OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get responsability type
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_professional    id_professional to verify responsability
    * @param   i_handoff_type    Hand-off type
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   o_type            Responsability type
    * @param   o_error           Error information
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @value   o_type         {*} 'M' Main responsability
    *                         {*} 'O' Overrall responsiblility
    *                         {*} 'E' Episode responsability
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_professional   IN professional.id_professional%TYPE DEFAULT NULL,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        i_hand_off_type  IN sys_config.value%TYPE DEFAULT NULL,
        o_type           OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get responsability type
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_professional    id_professional to verify responsability
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   i_handoff_type    Hand-off type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_professional   IN professional.id_professional%TYPE DEFAULT NULL,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE DEFAULT NULL,
        i_hand_off_type  IN sys_config.value%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Get responsability icons
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_handoff_type Hand-off type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 Array with the responsability icons
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_icons
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_handoff_type IN sys_config.value%TYPE
    ) RETURN table_varchar;

    /**
    * Get responsability type description
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   i_handoff_type    Hand-off type
    *
    * @return                 Responsability type description
    *
    * @raises                 g_resp_type_exception Error when getting responsability type for the episode/i_prof
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_type_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_handoff_type   IN sys_config.value%TYPE
    ) RETURN sys_message.desc_message%TYPE;

    /**
    * Get current responsability grid
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_flg_show        Professional category type to be returned
    * @param   o_grid            Current Responsability grid
    * @param   o_has_responsible 'Y' if o_grid cursor has values otherwise 'N'
    * @param   o_error           Error information
    *
    * @value   i_flg_show     {*} 'A' All
    *                         {*} 'P' Only physicians
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_current_resp_grid
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_show        IN VARCHAR2 DEFAULT 'A',
        o_grid            OUT pk_types.cursor_type,
        o_has_responsible OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get current responsability grid
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_flg_show        Professional category type to be returned
    * @param   o_grid            Current Responsability grid
    * @param   o_error           Error information
    *
    * @value   i_flg_show     {*} 'A' All
    *                         {*} 'P' Only physicians
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_hist_resp_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_show IN VARCHAR2 DEFAULT 'A',
        o_grid     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets previous responsible professional
    *
    * @param   i_episode              Episode id
    * @param   i_curr_epis_prof_resp  Current id_epis_prof_resp
    * @param   i_curr_dt_comp         Current dt_comp_tstz
    * @param   i_curr_flg_type        Current flg_type
    * @param   i_flg_profile          Multi_Prof flg_profile
    * @param   i_hand_off_type        Hand off type
    *
    * @return                 Previous id_epis_prof_resp
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_prev_resp
    (
        i_episode             IN episode.id_episode%TYPE,
        i_curr_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_curr_dt_comp        IN epis_prof_resp.dt_comp_tstz%TYPE,
        i_curr_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile         IN epis_multi_prof_resp.flg_profile%TYPE,
        i_hand_off_type       IN sys_config.value%TYPE
    ) RETURN epis_prof_resp.id_epis_prof_resp%TYPE;

    /**
    * Get message type (Used on history grid)
    *
    * @param   i_prof_prev    Previous responsible professional
    * @param   i_prof_comp    Current responsible professional
    * @param   i_dt_request   Request date
    * @param   i_flg_transfer Transfer?
    *
    * @return                 Previous id_epis_prof_resp
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_msg_type
    (
        i_prof_prev    IN epis_prof_resp.id_prof_prev%TYPE,
        i_prof_comp    IN epis_prof_resp.id_prof_comp%TYPE,
        i_dt_request   IN epis_prof_resp.dt_request_tstz%TYPE,
        i_flg_transfer IN epis_prof_resp.flg_transfer%TYPE,
        i_flg_status   in varchar2 default null
    ) RETURN VARCHAR2;

    /**
    * Gets responsability history
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   o_resp_hist       Responsability history grid
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_epis_prof_resp_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_resp_hist      OUT pk_types.cursor_type,
        o_sbar_note      OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if current episode has and needs a overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   o_flg_show_error  Is or isn't to show error message
    * @param   o_error_title     Error title
    * @param   o_error_message   Error message
    * @param   o_error           Error information
    *
    * @value   o_flg_show_error  {*} 'Y' Yes
    *                            {*} 'N' No
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION check_overall_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_flg_show_error OUT VARCHAR2,
        o_error_title    OUT sys_message.desc_message%TYPE,
        o_error_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the available tabs when selecting the overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_patient         Patient id
    * @param   o_tabs            Available tabs
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_overall_resp_tabs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_tabs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_all
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get start event (Internal function used to obtain the description of start event in the responsability grid)
    *
    * @param   i_lang                 Language id
    * @param   i_flg_transfer         Flag transfer
    * @param   i_prof_prev            Previous responsible professional id
    *
    * @return                         Event description
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_start_evt
    (
        i_lang         IN language.id_language%TYPE,
        i_flg_transfer IN epis_prof_resp.flg_transfer%TYPE,
        i_prof_prev    IN epis_prof_resp.id_prof_prev%TYPE
    ) RETURN sys_message.desc_message%TYPE;

    /**********************************************************************************************
    * Get end event (Internal function used to obtain the description of end event in the responsability grid)
    *
    * @param   i_lang                 Language id
    * @param   i_dt_end_transfer_tstz End of resp.
    * @param   i_flg_status           Status flag
    *
    * @return                         Event description
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_end_evt
    (
        i_lang                 IN language.id_language%TYPE,
        i_dt_end_transfer_tstz IN epis_prof_resp.dt_end_transfer_tstz%TYPE,
        i_flg_status           IN epis_prof_resp.flg_status%TYPE
    ) RETURN sys_message.desc_message%TYPE;

    /********************************************************************************************
    * Set main overall responsability for a patient.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_new_resp              New main overall responsible ID
    * @param   i_id_epis_prof_resp        Hand-off request ID
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION call_set_main_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_new_resp       IN professional.id_professional%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Terminate responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Responsability transfer request ID
    * @param   i_flg_type                 Type of hand-off: Physician / Nurse
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION call_set_terminate_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type          IN epis_prof_resp.flg_type%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION call_set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        i_dt_reg                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set the end date for a responsability record.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Responsability ID
    * @param   i_id_epis_multi_prof_resp  Multiple responsability ID
    * @param   i_hand_off_type            Type of hand-off
    * @param   i_dt_end_transfer          Responsability end date
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          10-11-2010
    **********************************************************************************************/
    FUNCTION call_set_end_responsability
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_prof_resp       IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_id_epis_multi_prof_resp IN epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        i_hand_off_type           IN sys_config.value%TYPE,
        i_dt_end_transfer         IN epis_prof_resp.dt_end_transfer_tstz%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if current professional has any type of responsability over the episode, whether
    * its OVERALL or EPISODE responsability.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_prof_resp             Professional ID to check
    * @param   i_prof_cat                 Professional category
    * @param   i_id_episode               Episode ID
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    *                        
    * @return  (Y) Yes, it's responsible. (N) No, it's not.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_prof_responsible
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_prof_resp  IN professional.id_professional%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_hand_off_type IN sys_config.value%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if professional 'i_prof.id' has any type of responsability over the episode, whether
    * its OVERALL or EPISODE responsability.
    * NOTE: Function called in MCDT packages: pk_analysis, pk_exam, pk_exam_core.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    *                        
    * @return  Value of 'I_PROF.ID' if is responsible; Value '-1' if is not.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_prof_responsible_current
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Checks if professional is a DBC owner.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_prof                  Professional ID
    *                        
    * @return  NULL: error. 0: Not a DBC owner. Other: is a DBC owner.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_dbc_owner
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Checks if professional is a on-call physician.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_prof                  Professional ID
    * @param   i_on_call_list             List of on-call physicians ID
    *                        
    * @return  NULL: error. 0: Not a on-call physician. Other: is a on-call physician.
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION is_on_call
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof      IN professional.id_professional%TYPE,
        i_on_call_list IN table_number
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Lista serviços clinicos, ou departamentos, para filtrar profissionais para os quais o profissional 
      actual pode transferir a responsabilidade de pacientes seus
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               tipo de transferência: D - médico, N - enfermeiro
    * @param i_flg_resp_type          Type of responsability: (E) Episode (O) Overall
    * @param o_dests_header           cabeçalho da coluna dos destinos
    * @param o_profs_header           cabeçalho da coluna dos profissionais
    * @param o_dests                  cursor with types departament or clinical service
    * @param o_handoff_type           type of hand-off configured in the institution
    * @param o_handoff_nurse          configuration for nurse hand-off (clinical service or department)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/06/05
    *
    * @alter                          Jos?Brito
    * @version                        2.6.0.4 
    * @since                          2010/10/19
    **********************************************************************************************/
    FUNCTION get_handoff_dest
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN category.flg_type%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        o_dests_header  OUT VARCHAR2,
        o_profs_header  OUT VARCHAR2,
        o_dests         OUT pk_types.cursor_type,
        o_handoff_type  OUT sys_config.value%TYPE,
        o_handoff_nurse OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the profile types (Specialist, Resident, Intern, Nurse, etc.)
    * to which the professional can make a hand-off request.
    *
    * NOTE: Used only for EPISODE responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_flg_type               type of category (D) Physician (N) Nurse
    * @param o_profiles               list of profile types
    * @param o_error                  error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profiles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN category.flg_type%TYPE,
        o_profiles   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the destination professionals for the current responsability transfer, filtered
    * according to the destination clinical service/department/speciality.
    *
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_dest                   ID of the destination clinical service/department/speciality
    * @param i_episode                Episode ID
    * @param i_flg_type               Type of category (D) Physician (N) Nurse
    * @param i_handoff_type           Type of hand-off: (N) Normal (M) Multiple
    * @param i_handoff_nurse          Configuration for nurse hand-off (clinical service or department)
    * @param i_flg_profile            Type of profile (specialist, resident, intern, nurse)
    * @param i_flg_resp_type          Type of responsability (E) Episode (O) Overall
    * @param i_flg_assign_supervisor  Flag that indicates if this is a supervisor assignment
    * @param o_profs                  List of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    *
    * @alter                          Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profs
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_dest                  IN dep_clin_serv.id_clinical_service%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_type              IN category.flg_type%TYPE,
        i_handoff_type          IN VARCHAR2,
        i_handoff_nurse         IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE,
        i_flg_resp_type         IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E',
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        o_profs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of DBC owners to display in the overall responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_profs                  List of DBC owners
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dbc_profs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_profs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the number of available on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    *
    * @return                         Number of available on-call physicians
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns all data relative to on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_profs                  List of on-call physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_profs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get all episodes where i_profs are responsible (Used on search criteria)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_prof_cat        Professional category    
    * @param   i_hand_off_type   Type of hand-off (N) Normal (M) Multiple
    * @param   i_profs           Array with id_prof's
    *
    * @return                 Array with id_episode's
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_prof_episodes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_profs         IN table_number
    ) RETURN table_number;

    /**
    * Get patient previous professionals
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_patient                Patient id
    * @param i_prof_cat               Professional category
    * @param i_handoff_type           Handoff type
    *
    * @return                 Array with professionals
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_pat_profs_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_prof_cat     IN category.flg_type%TYPE,
        i_handoff_type IN sys_config.value%TYPE
    ) RETURN table_number;

    /**
    * Get patient previous responsibles
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param o_profs                  List of on-call physicians ID's
    * @param o_error                  Error message
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_previous_responsibles
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get clin_serv or department or speciality label
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_clin_serv              Clinical service id
    * @param i_department             Department id
    * @param i_speciality             Speciality id
    * @param i_handoff_type           Handoff type
    * @param i_prof_cat               Professional category
    *
    * @return                 corresponding label
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_cs_dep_spec_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_department   IN department.id_department%TYPE,
        i_speciality   IN speciality.id_speciality%TYPE,
        i_handoff_type IN sys_config.value%TYPE DEFAULT NULL,
        i_prof_cat     IN category.flg_type%TYPE DEFAULT NULL
    ) RETURN sys_message.desc_message%TYPE;

    /**
    * Get clin_serv or department or speciality description
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_clin_serv              Clinical service id
    * @param i_department             Department id
    * @param i_speciality             Speciality id
    *
    * @return                         Description
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_cs_dep_spec_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_clin_serv  IN clinical_service.id_clinical_service%TYPE,
        i_department IN department.id_department%TYPE,
        i_speciality IN speciality.id_speciality%TYPE
    ) RETURN sys_message.desc_message%TYPE;

    /********************************************************************************************
    * Get category description of given professional
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_handoff_type              Hand off type
    * @param i_prof_id                   Professional who made the record
    * @param i_prof_type                 Professional type
    * @param i_flg_profile               Epis_multi_prof_resp flag profile
    * @param i_flg_type                  Epis_prof_resp flag type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @value   i_prof_type    {*} 'R' Request
    *                         {*} 'T' To
    *
    * @return                            Category description
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_desc_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_handoff_type IN sys_config.value%TYPE,
        i_prof_id      IN professional.id_professional%TYPE,
        i_prof_type    IN VARCHAR2,
        i_flg_profile  IN epis_multi_prof_resp.flg_profile%TYPE,
        i_flg_type     IN epis_prof_resp.flg_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get hand off configuration vars
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_flg_type               Transf. type
    * @param o_label                  Speciality or Clinical Service or Department
    * @param o_handoff_type           Hand off type
    * @param o_error                  Error message
    *
    * @value   i_flg_type     {*} 'D' Physician
    *                         {*} 'N' Nurse
    *
    * @value   o_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_hand_off_vars
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN category.flg_type%TYPE,
        o_label        OUT sys_message.code_message%TYPE,
        o_handoff_type OUT sys_config.value%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set the responsible professionals in EPIS_INFO.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Professional ID
    * @param   i_id_professional_nin      Ignore NULL values: TRUE/FALSE
    * @param   i_prof_cat                 Professional category
    * @param   i_flg_resp_type            Type of responsability
    * @param   o_error                    Error message
    *
    * @value   i_flg_resp_type            {*} E - Episode responsability
    *                                     {*} O - Overall responsability
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          17-12-2010
    **********************************************************************************************/
    FUNCTION call_set_epis_info_resp
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_professional_nin IN BOOLEAN,
        i_prof_cat            IN category.flg_type%TYPE,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set all responsible professionals in EPIS_INFO.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Professional ID
    * @param   i_id_professional_nin      Ignore NULL values: TRUE/FALSE
    * @param   i_prof_cat                 Professional category of 'i_id_professional'
    * @param   i_id_prof_nurse            Nurse professional ID
    * @param   i_id_prof_nurse_nin        Ignore NULL values: TRUE/FALSE
    * @param   i_flg_resp_type            Type of responsability
    * @param   o_error                    Error message
    *
    * @value   i_flg_resp_type            {*} E - Episode responsability
    *                                     {*} O - Overall responsability
    *
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          17-12-2010
    **********************************************************************************************/
    FUNCTION call_set_epis_info_resp_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_professional_nin IN BOOLEAN,
        i_prof_cat            IN category.flg_type%TYPE,
        i_id_prof_nurse       IN professional.id_professional%TYPE,
        i_id_prof_nurse_nin   IN BOOLEAN,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the most recent responsability record ID and responsible professional ID
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_flg_transf_type          Type of responsability: (E) Episode (O) Overall
    * @param   i_id_speciality            Responsability Speciality ID
    * @param   i_flg_profile              Type of profile: (S)Specialist (R)Resident (I)Intern (N)Nurse
    * @param   i_hand_off_type            Type of hand-off: (N) Normal (M) Multiple
    * @param   o_id_epis_prof_resp        Responsability ID
    * @param   o_id_prof_resp             Responsible professional ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.4
    * @since                          17-12-2010
    **********************************************************************************************/
    FUNCTION get_current_epis_prof_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_type          IN epis_prof_resp.flg_type%TYPE,
        i_flg_transf_type   IN epis_prof_resp.flg_transf_type%TYPE,
        i_id_speciality     IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_profile       IN epis_multi_prof_resp.flg_profile%TYPE,
        i_hand_off_type     IN VARCHAR2,
        o_id_epis_prof_resp OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_prof_resp      OUT epis_prof_resp.id_prof_comp%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that matches to episodes responsibles physicians/nurses records
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 17-12-2010
    ********************************************************************************************/
    FUNCTION set_resp_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that checks the episode responsible in EPIS_INFO.
    * Used mostly for OUTPATIENT hand-off logic.
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_episode            Episode ID
    * @param i_prof_cat              Professional category
    * @param o_id_professional       Responsible professional ID
    * @param o_error                 Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Jos?Brito
    * @version               2.6
    * @since                 12-01-2011
    ********************************************************************************************/
    FUNCTION get_epis_info_resp
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_prof_cat        IN category.flg_type%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE DEFAULT NULL,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a SPECIALIST PHYSICIAN responsability record that is in "finalized" state.
    * Used by INTER-
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_professional         Specialist physician ID
    * @param i_notes                   Cancellation notes
    * @param i_id_cancel_reason        Cancel reason ID
    * @param i_dt_cancel               Cancellation date
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           13-Jul-2011
    *
    **********************************************************************************************/
    FUNCTION cancel_responsability_spec
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a responsability record that is in "finalized" state.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1
    * @since                          07-06-2011
    **********************************************************************************************/
    FUNCTION cancel_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a responsability record that is in "finalized" state.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param i_dt_cancel               Cancellation date
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1
    * @since                          07-06-2011
    **********************************************************************************************/
    FUNCTION call_cancel_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list of professionals assigned to the specified clinical service.
    * Used to select the responsible physician when admitting a patient to another software.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_institution              Destination institution ID
    * @param   i_software                 Destination software ID
    * @param   i_dest_service             Destination clinical service ID
    * @param   o_prof_list                List of professionals 
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Jos?Brito
    * @version                        2.6.1
    * @since                          07-07-2011
    **********************************************************************************************/
    FUNCTION get_admission_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_dest_service IN clinical_service.id_clinical_service%TYPE,
        o_prof_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if current software is an ambulatory product.
    *
    * @param i_software                Software ID
    * 
    * @return                          1 if TRUE, 0 if FALSE.
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           15-Nov-2011
    *
    **********************************************************************************************/
    FUNCTION is_ambulatory_product(i_software IN software.id_software%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   i_flg_epis_respons         Flag that indicates if the professional also takes episode responsability 
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.10
    * @since                          20-Set-2012
    **********************************************************************************************/
    FUNCTION call_set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        i_dt_reg                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_epis_respons        IN VARCHAR2,
        i_flg_update_resp         IN VARCHAR2 DEFAULT 'N',
        i_flg_main_responsible    IN VARCHAR2 DEFAULT NULL,
        i_priority                IN NUMBER DEFAULT NULL,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode/overall responsability, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_my_patients              Called from a 'My patients' grid: (Y) Yes (N) No - default
    * @param   i_resp_type                Responsability type
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.10
    * @since                          20-Set-2012
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Returns an array with the all responsible professionals for the episode, 
    * for a configured professional category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Table number with all id episodes
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.15
    * @since                          04-04-2014
    **********************************************************************************************/
    FUNCTION get_all_responsibles_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode_table IN table_number
    ) RETURN t_resp_professional_cda;

    /*********************************************************************************************************************
    * Assigns main/overall responsible of an episode.
    * This function overrides regular responsabilty rules and should only be used in exceptions to the normal workflow
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    *
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Sergio Dias
    * @version                        2.6.3.8.2
    * @since                          7-Oct-2013
    **********************************************************************************************************************/
    FUNCTION override_main_responsible
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_prof_resp IN epis_multi_prof_resp.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_first_nurse_resp         Episode first nurse responsible
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_resp_doctor_nurse
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT professional.id_professional%TYPE,
        o_first_nurse_resp OUT professional.id_professional%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_resp_doctor_spec         Responsible physician speciality
    * @param   o_resp_nurse               Episode responsible nurse
    * @param   o_error                    Error message
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_epis_responsibles
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT VARCHAR,
        o_resp_doctor_spec OUT VARCHAR,
        o_resp_nurse       OUT VARCHAR,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF FUNCTION GET_EPIS_PROF_RESP_ALL BUT ALSO CHECKS IN EPIS_INFO FOR OUTP
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Sergio Dias
    * @version v2.6.3.8.3
    * @since   17-Oct-2013
    **********************************************************************************************/
    FUNCTION get_responsibles
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the professional responsible for admission
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_episode                  Episode identifier
    *                        
    * @return  professional name and speciality
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.7.1.0
    * @since                          26/04/2017
    **********************************************************************************************/
    FUNCTION get_admission_prof_resp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the list of professional responsible for admission (doctors)
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_episode                  Episode identifier
    * @param   o_prof_resp                List od professional responsible for episode                   
    * @return  true/faslse
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.7.1.0
    * @since                          28/04/2017
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_prof_resp OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_handoff_actions_sp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_resp_outdated
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE,
        i_prof_list     IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the maximum episode responsability confirm date on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Maximum comfirm request date
    *
    * @author                         Amanda Lee
    * @version                        2.7.2
    * @since                          25-12-2017
    **********************************************************************************************/
    FUNCTION get_last_trans_service_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_prof_resp.dt_end_transfer_tstz%TYPE;

    /********************************************************************************************
    * Get the last transfer out clinical service.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Last transfer out clinical service
    *
    * @author                         Lillian Lu
    * @version                        2.7.3
    * @since                          16-01-2018
    **********************************************************************************************/
    FUNCTION get_last_transf_cs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Get Attending physicians list on an episode.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   i_episode              episode ID
    *
    * @return  Attending physicians on an episode
    *
    * @author                         Amanda Lee
    * @version                        2.7.3
    * @since                          19-01-2018
    **********************************************************************************************/
    FUNCTION get_attending_physicians
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    -- 
    /**
    * Get profile template description
    *
    * @param   i_lang            Professional preferred language
    * @param   i_profile_template            Profile template
    *
    * @return                 Profile template description
    *
    *
    * @author  Ana Moita
    * @version v2.8.0.2
    * @since   30-09-2020
    */
    FUNCTION get_profile_template_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN sys_message.desc_message%TYPE;

    FUNCTION get_epis_prof_resp_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************
    * Get registered signature for detail 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               professional, institution and software ids
    * @param   i_id_epis_prof_resp  and-off request ID
    *
    * @return                  Professional signature 
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.8.2.4
    * @since                          26/03/2021
    **********************************************************************************************/

    FUNCTION get_epis_prof_resp_signature
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_detail            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_epis_multi_hist IN epis_multi_profresp_hist.id_epis_multi_profresp_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_epis_prof_resp_clob
    (
        i_field             IN dd_content.internal_name%TYPE,
        i_value             IN VARCHAR2
    ) RETURN CLOB;
    
    FUNCTION get_prof_resp_status
    (
        i_lang           IN language.id_language%TYPE,
        i_flg_status     IN epis_prof_resp.flg_status%TYPE,
        i_flg_status_old IN epis_prof_resp.flg_status%TYPE,
        i_flg_status_epr IN epis_prof_resp.flg_status%TYPE
    ) RETURN VARCHAR2;
    
    FUNCTION get_epis_prof_resp_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    -----

    FUNCTION get_responsibles_str_to_sort
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_cat            IN category.flg_type%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_hand_off_type       IN sys_config.value%TYPE,
        i_format              IN VARCHAR2,
        i_only_show_epis_resp IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    g_package_name VARCHAR2(32);
    g_error        VARCHAR2(4000);

    g_epis_active CONSTANT episode.flg_status%TYPE := 'A';

    g_cat_prof CONSTANT category.flg_prof%TYPE := 'Y';

    g_profile_type_intern CONSTANT profile_template.flg_type%TYPE := 'I';

    g_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_onhold   CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_outdated CONSTANT VARCHAR2(1 CHAR) := 'O';

    g_specialist CONSTANT sys_domain.val%TYPE := 'S';
    g_resident   CONSTANT sys_domain.val%TYPE := 'R';
    g_intern     CONSTANT sys_domain.val%TYPE := 'I';
    g_nurse      CONSTANT sys_domain.val%TYPE := 'N';
    g_student    CONSTANT sys_domain.val%TYPE := 'T';

    g_button_cancel CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_button_ok     CONSTANT VARCHAR2(1 CHAR) := 'O';

    g_resp_episode CONSTANT epis_multi_prof_resp.flg_resp_type%TYPE := 'E';
    g_resp_overall CONSTANT epis_multi_prof_resp.flg_resp_type%TYPE := 'O';

    g_action_create   CONSTANT sys_domain.val%TYPE := 'C';
    g_action_indicate CONSTANT sys_domain.val%TYPE := 'I';
    g_action_nothing  CONSTANT sys_domain.val%TYPE := 'N';

    g_config_show_only_epis_resp CONSTANT sys_config.id_sys_config%TYPE := 'EDIS_GRIS_ONLY_SHOW_EPISODE_RESPONSIBLE';
    g_prof_id_category_physician CONSTANT NUMBER := 1;
    g_prof_id_category_midwife   CONSTANT NUMBER := 34;

    g_id_profile_resp_therap CONSTANT NUMBER := 411;

    g_trans_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';

    FUNCTION get_hand_off_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_hand_off_type IN sys_config.value%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_tab_dd_block_data_m01
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type  IN VARCHAR2,
        i_flg_profile    IN VARCHAR2
    ) RETURN t_tab_dd_block_data;

	function get_tab_dd_block_data_n01
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type  IN VARCHAR2,
        i_flg_profile    IN VARCHAR2
    ) RETURN t_tab_dd_block_data;
	
    FUNCTION get_tab_dd_block_data_m02
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_hand_off_type  IN VARCHAR2,
        i_flg_profile    IN VARCHAR2
    ) RETURN t_tab_dd_block_data;

    PROCEDURE ins_epis_prof_resp_h(i_row IN epis_prof_resp%ROWTYPE);
    
    FUNCTION set_epis_prof_resp_h(i_id IN NUMBER) RETURN epis_prof_resp%ROWTYPE;

    FUNCTION get_count_new_history(i_epis_prof_resp IN NUMBER) RETURN NUMBER;

    FUNCTION get_dt_signature
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_dt_request  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_comp     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_decline  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_transfer IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_cancel   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_detail      IN VARCHAR2
    ) RETURN VARCHAR2;

END pk_hand_off_core;
/
