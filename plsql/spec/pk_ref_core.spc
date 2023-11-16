/*-- Last Change Revision: $Rev: 2028905 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_core AS

    -- type used in get_actions_available
    TYPE options_rec IS RECORD(
        id_workflow  NUMBER(24),
        status_begin VARCHAR2(1 CHAR),
        status_end   VARCHAR2(1 CHAR),
        icon         VARCHAR2(200 CHAR),
        label        VARCHAR2(1000 CHAR),
        rank         NUMBER(6),
        action       VARCHAR2(200 CHAR));

    TYPE options_cur IS REF CURSOR RETURN options_rec;

    -- ALERT-14479 GP PORTAL
    TYPE ref_detail_rec IS RECORD(
        id_patient            NUMBER(24),
        pat_name              VARCHAR2(4000 CHAR),
        dt_birth              VARCHAR2(200 CHAR),
        num_health_plan       NUMBER(24),
        desc_health_plan      VARCHAR2(4000 CHAR),
        run_number            VARCHAR2(800 CHAR),
        id_external_request   NUMBER(24),
        num_req               VARCHAR2(200 CHAR),
        flg_type              VARCHAR2(1 CHAR),
        desc_referral_type    VARCHAR2(800 CHAR),
        priority              VARCHAR2(800 CHAR),
        decision_urg_level    VARCHAR2(800 CHAR),
        dt_request            VARCHAR2(200 CHAR),
        dt_requested          TIMESTAMP(6) WITH LOCAL TIME ZONE,
        dt_request_date       VARCHAR2(200 CHAR),
        dt_emited             VARCHAR2(800 CHAR),
        dt_emited_tstz        TIMESTAMP(6) WITH LOCAL TIME ZONE,
        hour_emited           VARCHAR2(800 CHAR),
        id_prof_requested     NUMBER(24),
        prof_requested_name   VARCHAR2(200 CHAR),
        id_inst_orig          NUMBER(24),
        inst_orig_name        VARCHAR2(4000 CHAR),
        location_orig         VARCHAR2(800 CHAR),
        id_inst_dest          NUMBER(24),
        inst_dest_name        VARCHAR2(1000 CHAR),
        location_dest         VARCHAR2(800 CHAR),
        id_speciality         NUMBER(24),
        spec_name             VARCHAR2(1000 CHAR),
        id_dep_clin_serv      NUMBER(24),
        id_department         NUMBER(24),
        desc_department       VARCHAR2(4000 CHAR),
        id_clinical_service   NUMBER(24),
        desc_clinical_service VARCHAR2(4000 CHAR),
        id_content            VARCHAR2(200 CHAR),
        dt_sch_tstz           TIMESTAMP(6) WITH LOCAL TIME ZONE,
        id_prof_sch           NUMBER(24),
        pror_sch_name         VARCHAR2(1000 CHAR),
        sub_spec_name         VARCHAR2(1000 CHAR),
        label_sub_spec        VARCHAR2(1000 CHAR),
        label_spec            VARCHAR2(1000 CHAR));

    TYPE ref_detail_cur IS REF CURSOR RETURN ref_detail_rec;

    --JB 2011-05-12
    TYPE t_row_detail_rec IS RECORD(
        id_external_request p1_external_request.id_external_request%TYPE,
        id_p1               p1_external_request.num_req%TYPE,
        flg_type            p1_external_request.flg_type%TYPE,
        num_req             p1_external_request.num_req%TYPE,
        id_workflow         p1_external_request.id_workflow%TYPE,
        id_episode          p1_external_request.id_episode%TYPE,
        dt_p1               VARCHAR2(200 CHAR),
        status_icon         VARCHAR2(200 CHAR),
        flg_status          p1_external_request.flg_status%TYPE,
        status_colors       VARCHAR2(200 CHAR),
        desc_status         pk_translation.t_desc_translation,
        priority_info       VARCHAR2(200 CHAR), --
        priority_icon       VARCHAR2(200 CHAR),
        desc_priority       VARCHAR2(1000 CHAR), --
        dt_elapsed          VARCHAR2(200 CHAR),
        id_prof_requested   NUMBER(24),
        prof_name_request   VARCHAR2(200 CHAR),
        prof_spec_request   VARCHAR2(200 CHAR),
        --desc_priority           VARCHAR2(200 CHAR),--
        id_dep_clin_serv          p1_external_request.id_dep_clin_serv%TYPE,
        desc_clinical_service     VARCHAR2(200 CHAR),
        id_department             department.id_department%TYPE,
        desc_department           VARCHAR2(200 CHAR),
        id_speciality             p1_external_request.id_speciality%TYPE,
        id_inst_orig              p1_external_request.id_inst_orig%TYPE,
        inst_orig_clues           VARCHAR2(200 CHAR), --
        inst_orig_abbrev          VARCHAR2(200 CHAR),
        inst_orig_name            VARCHAR2(200 CHAR),
        id_institution            p1_external_request.id_inst_dest%TYPE,
        inst_abbrev               VARCHAR2(200 CHAR),
        inst_name                 VARCHAR2(200 CHAR),
        dep_name                  VARCHAR2(200 CHAR),
        spec_name                 VARCHAR2(200 CHAR),
        dt_schedule               VARCHAR2(200 CHAR),
        dt_probl_begin            VARCHAR2(200 CHAR),
        dt_probl_begin_ts         VARCHAR2(200 CHAR),
        field_name                VARCHAR2(200 CHAR),
        flg_priority              p1_external_request.flg_priority%TYPE,
        flg_home                  p1_external_request.flg_home%TYPE,
        prof_redirected           VARCHAR2(200 CHAR),
        dt_last_interaction       VARCHAR2(200 CHAR),
        label_institution         sys_message.desc_message%TYPE,
        label_clinical_service    sys_message.desc_message%TYPE,
        label_department          sys_message.desc_message%TYPE,
        label_priority            sys_message.desc_message%TYPE,
        label_home                sys_message.desc_message%TYPE,
        desc_home                 VARCHAR2(200 CHAR),
        label_status              sys_message.desc_message%TYPE,
        label_dt_probl_begin      sys_message.desc_message%TYPE,
        decision_urg_level        p1_external_request.decision_urg_level%TYPE,
        desc_decision_urg_level   VARCHAR2(200 CHAR),
        id_external_sys           p1_external_request.id_external_sys%TYPE,
        id_schedule_ext           p1_external_request.id_schedule%TYPE,
        id_prof_schedule          professional.id_professional%TYPE,
        reason_desc               VARCHAR2(200 CHAR),
        reason_text               VARCHAR2(200 CHAR),
        title_notes               VARCHAR2(200 CHAR),
        title_text                VARCHAR2(200 CHAR),
        sub_spec_name             VARCHAR2(200 CHAR),
        label_sub_spec            sys_message.desc_message%TYPE,
        label_spec                sys_message.desc_message%TYPE,
        wait_days                 VARCHAR2(200 CHAR),
        ref_line                  VARCHAR2(200 CHAR),
        type_ins                  VARCHAR2(200 CHAR),
        inside_ref_area           VARCHAR2(200 CHAR),
        inst_type_label           VARCHAR2(200 CHAR),
        ref_line_label            VARCHAR2(200 CHAR),
        wait_days_label           VARCHAR2(200 CHAR),
        id_sub_speciality         p1_external_request.id_dep_clin_serv%TYPE,
        id_content                VARCHAR2(200 CHAR),
        flg_type_desc             VARCHAR2(200 CHAR),
        location_dest             VARCHAR2(200 CHAR),
        dt_issued                 VARCHAR2(200 CHAR),
        prof_cert                 VARCHAR2(30 CHAR),
        prof_name                 VARCHAR2(200 CHAR),
        prof_surname              VARCHAR2(200 CHAR),
        prof_phone                VARCHAR2(30 CHAR),
        id_fam_rel                family_relationship.id_family_relationship%TYPE,
        desc_fr                   VARCHAR(100 CHAR),
        name_first_rel            VARCHAR2(100 CHAR),
        name_middle_rel           VARCHAR2(300 CHAR),
        name_last_rel             VARCHAR2(100 CHAR),
        consent                   VARCHAR2(1 CHAR),
        desc_consent              VARCHAR2(200 CHAR),
        label_referral_number     sys_message.desc_message%TYPE,
        flg_create_comment        VARCHAR2(1 CHAR),
        family_relationship_notes VARCHAR2(1000 CHAR));

    TYPE row_detail_cur IS REF CURSOR RETURN t_row_detail_rec;

    /**
    * Initializes table_varchar as input of workflow transition function
    *
    * @param   i_lang                    Language associated to the professional 
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_ext_req                 Referral identifier    
    * @param   i_id_patient              Referral patient identifier
    * @param   i_id_inst_orig            Referral institution origin
    * @param   i_id_inst_dest            Referral institution dest
    * @param   i_id_dep_clin_serv        Referral dep_clin_serv
    * @param   i_id_speciality           Referral speciality (origin)
    * @param   i_flg_type                Referral type
    * @param   i_decision_urg_level      Decision urgency level assigned when triaging referral
    * @param   i_id_prof_requested       Professional that requested referral   
    * @param   i_id_prof_redirected      Professional to whom the referral was forwarded to   
    * @param   i_id_prof_status          Professional that changed referral status
    * @param   i_external_sys            Referral external system where the referral was created
    * @param   i_location                Referral location
    * @param   i_completed               Flag indicating if referral has been completed   
    * @param   i_flg_status              Referral status
    * @param   i_flg_prof_dcs            Flag indicating if professional is related to this id_dep_clin_serv (used for the registrar)
    * @param   i_prof_clin_dir           Flag indicating if professional is clinical director in this institution
    *   
    * @value   i_flg_type                {*} 'C' - Appointments
    *                                    {*} 'A' - Lab tests
    *                                    {*} 'I' - Imaging exams
    *                                    {*} 'E' - Other exams
    *                                    {*} 'P' - Procedures
    *                                    {*} 'F' - Physical Medicine and Rehabilitation
    * @value   o_location                {*} 'G' - grid {*} 'D' - detail
    * @value   o_completed               {*} 'Y' - referral completed {*} 'N' - otherwise
    *
    */
    FUNCTION init_param_tab
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ext_req            IN p1_external_request.id_external_request%TYPE,
        i_id_patient         IN p1_external_request.id_patient%TYPE DEFAULT NULL,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE DEFAULT NULL,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE DEFAULT NULL,
        i_flg_type           IN p1_external_request.flg_type%TYPE DEFAULT NULL,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE DEFAULT NULL,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE DEFAULT NULL,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE DEFAULT NULL,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE DEFAULT NULL,
        i_location           IN VARCHAR2 DEFAULT pk_ref_constant.g_location_detail,
        i_completed          IN VARCHAR2 DEFAULT pk_ref_constant.g_no,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_flg_prof_dcs       IN VARCHAR2 DEFAULT NULL,
        i_prof_clin_dir      IN VARCHAR2 DEFAULT NULL
    ) RETURN table_varchar;

    /**
    * Process automatic referral status change
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_prof_data     Professional data    
    * @param   i_ref_row       P1_EXTERNAL_REQUEST row info
    * @param   i_status_end    Status end of this transition
    * @param   i_date          Status change date   
    * @param   i_flg_completed Flag indicating if referral is completed or not. Used in action='NEW'    
    * @param   i_notes         Referral notes related to the status change
    * @param   i_reason_code   Refuse reason code
    * @param   i_schedule      Schedule identification    
    * @param   i_diagnosis     Referral diagnosis id (referral answer)
    * @param   i_diag_desc     Referral diagnosis description (referral answer)
    * @param   i_answer        Referral answer details
    * @param   i_episode       Episode identifier (used by scheduler when scheduling ORIS/INP referral)   
    * @param   io_param        Parameters for framework workflows evaluation    
    * @param   io_track        Array of ID_TRACKING transitions    
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-10-2010
    */
    FUNCTION process_auto_transition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mode           IN VARCHAR2 DEFAULT NULL,
        i_flg_completed  IN VARCHAR2 DEFAULT NULL,
        i_notes          IN p1_detail.text%TYPE DEFAULT NULL,
        i_reason_code    IN p1_tracking.id_reason_code%TYPE DEFAULT NULL,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_level          IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_prof_dest      IN professional.id_professional%TYPE DEFAULT NULL,
        i_subtype        IN p1_tracking.flg_type%TYPE DEFAULT NULL,
        i_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        i_schedule       IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_diagnosis      IN table_number DEFAULT NULL,
        i_diag_desc      IN table_varchar DEFAULT NULL,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_answer         IN table_table_varchar DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        io_param         IN OUT NOCOPY table_varchar,
        io_track         IN OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Process referral status change 
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_prof_data     Professional data    
    * @param   i_ref_row       P1_EXTERNAL_REQUEST row info
    * @param   i_action        Action to process to change status
    * @param   i_status_end    Status end of this transition
    * @param   i_date          Status change date       
    * @param   i_notes         Referral notes related to the status change
    * @param   i_reason_code   Refuse reason code
    * @param   i_schedule      Schedule identification    
    * @param   i_diagnosis     Referral diagnosis id (referral answer)
    * @param   i_diag_desc     Referral diagnosis description (referral answer)
    * @param   i_answer        Referral answer details
    * @param   i_episode       Episode identifier (used by scheduler when scheduling ORIS/INP referral)   
    * @param   io_param        Parameters for framework workflows evaluation
    * @param   io_track        Array of ID_TRACKING transitions    
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2009
    */
    FUNCTION process_transition2
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_data        IN t_rec_prof_data,
        i_ref_row          IN p1_external_request%ROWTYPE,
        i_action           IN VARCHAR2,
        i_status_end       IN p1_external_request.flg_status%TYPE,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mode             IN VARCHAR2 DEFAULT NULL,
        i_notes            IN p1_detail.text%TYPE DEFAULT NULL,
        i_reason_code      IN p1_tracking.id_reason_code%TYPE DEFAULT NULL,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_level            IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_prof_dest        IN professional.id_professional%TYPE DEFAULT NULL,
        i_subtype          IN p1_tracking.flg_type%TYPE DEFAULT NULL,
        i_inst_dest        IN institution.id_institution%TYPE DEFAULT NULL,
        i_schedule         IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_diagnosis        IN table_number DEFAULT NULL,
        i_diag_desc        IN table_varchar DEFAULT NULL,
        i_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_answer           IN table_table_varchar DEFAULT NULL,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        io_param           IN OUT NOCOPY table_varchar,
        io_track           IN OUT table_number,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets professional functionality
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_dcs           department clinical service
    *
    * @RETURN  professional functionality
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION get_prof_func
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN NUMBER;

    /**
    * Gets professional functionality not related to id_dep_clin_serv 
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    *
    * @RETURN  professional functionality
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-12-2012
    */
    FUNCTION get_prof_func_inst
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;

    /**
    * Gets professional functionality related to id_dep_clin_serv 
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_dcs        Department and service identifier
    *
    * @RETURN  professional functionality
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-12-2012
    */
    FUNCTION get_prof_func_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN table_number;

    /**
    * Gets professional profile template and functionality
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof           Professional, institution and software ids
    * @param   i_dcs           department clinical service
    * @param   o_prof_data     Professional data: profile template, functionality and category
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2009
    */
    FUNCTION get_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof_data OUT t_rec_prof_data,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status.
    *
    * @param   I_LANG                Language associated to the professional executing the request
    * @param   I_PROF                Professional, institution and software ids
    * @param   i_ext_req             Referral identification
    * @param   i_status_begin        Begin Transition status. This parameter will be ignored.
    * @param   i_status_end          End Transition status. This parameter will be ignored.
    * @param   i_action              Action to process    
    * @param   i_level               Referral decision urgency level    
    * @param   i_prof_dest           Dest professional id (when forwarding or scheduling the request)   
    * @param   i_dcs                 Service id, used when changing clinical service
    * @param   i_notes               Notes related to transition
    * @param   i_dt_modified         Last modified date as provided by get_referral
    * @param   i_mode                (V)alidate date modified or do(N)t
    * @param   i_reason_code         Decline or refuse reason code 
    * @param   i_subtype             Flag used to mark refusals made by the interface
    * @param   i_inst_dest           Id of new institution, used when changing institution    
    * @param   i_date                Operation date
    * @param   o_track               Array of ID_TRACKING transitions
    * @param   o_flg_show            Flag indicating if o_msg is shown
    * @param   o_msg                 Message indicating that referral has been changed
    * @param   o_msg_title           Message title
    * @param   o_button              Button type    
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.1
    * @since   23-06-2009
    */
    FUNCTION set_status2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_status_begin   IN p1_external_request.flg_status%TYPE, -- deprecated (ignored)
        i_status_end     IN p1_external_request.flg_status%TYPE, -- deprecated (ignored)
        i_action         IN wf_workflow_action.internal_name%TYPE, -- new parameter
        i_level          IN p1_external_request.decision_urg_level%TYPE,
        i_prof_dest      IN professional.id_professional%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_dt_modified    IN VARCHAR2,
        i_mode           IN VARCHAR2,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE,
        i_subtype        IN p1_tracking.flg_subtype%TYPE,
        i_inst_dest      IN institution.id_institution%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_track          OUT table_number,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function used in grids to return referral priority information
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional id, institution and software    
    * @param   I_EXT_REQ            Referral identifier    
    * @param   I_FLG_PRIORITY       Professional functionality   
    *
    * @RETURN  icon|priority_color|l_text_color|l_val|rank|l_priority|l_desc_priority
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-10-2012
    */
    FUNCTION get_ref_priority_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_priority IN p1_external_request.flg_priority%TYPE
    ) RETURN VARCHAR2;

    /**
    * Function used in grids to return referral priority description
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software        
    * @param   i_flg_priority       Professional functionality   
    *
    * @RETURN  Priority description
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-10-2013
    */
    FUNCTION get_ref_priority_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_priority IN p1_external_request.flg_priority%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returuns value to show in observations column in referral grids 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_prof_profile          Professional profile template
    * @param   i_id_ref                Referral identifier    
    * @param   i_flg_status            Referral status       
    * @param   i_id_prof_status        Professional that changed the referral status
    * @param   i_dt_schedule           Referral schedule timestamp
    * @param   i_view_clin_data        If professional can view clinical data
    * @param   i_id_prof_triage        Professional that has triaged the referral
    * @param   i_id_prof_sch_sugg      Scheduled professional suggested by triage physician
    *
    * @value   i_view_clin_data        {*} 'Y' - can view clinical data {*} 'N' - otherwise
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-03-2011
    */
    FUNCTION get_ref_observations
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_profile     IN profile_template.id_profile_template%TYPE,
        i_id_ref           IN referral_ea.id_external_request%TYPE,
        i_flg_status       IN referral_ea.flg_status%TYPE,
        i_id_prof_status   IN referral_ea.id_prof_status%TYPE,
        i_dt_schedule      IN referral_ea.dt_schedule%TYPE,
        i_view_clin_data   IN VARCHAR2,
        i_id_prof_triage   IN referral_ea.id_prof_triage%TYPE,
        i_id_prof_sch_sugg IN referral_ea.id_prof_sch_sugg%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get referral obs.
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_id_external_request     Referral identifier
    * @param   i_flg_status              Referral status          
    * @param   i_view_clin_data          Clinical data can be viewed? {*} Y - yes, {*} N - no
    *
    * @RETURN  referral obs.
    * @author  Filipe Sousa
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_view_clin_data      IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get referral obs. text
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_id_external_request     Referral identifier
    * @param   i_flg_status              Referral status     
    * @param   i_view_clin_data          Clinical data can be viewed? {*} Y - yes, {*} N - no
    *
    * @RETURN  referral obs. text
    * @author  Filipe Sousa
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_obs_text
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_view_clin_data      IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Checks if the referral can be canceled
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_ref                     Referral identifier
    * @param   i_flg_status              Referral status
    * @param   i_id_workflow             Referral workflow identifier
    * @param   i_id_profile_template     Professional profile template that is requesting cancelation
    * @param   i_id_functionality        Professional functionality that is requesting cancelation
    * @param   i_id_category             Professional category that is requesting cancelation   
    * @param   i_id_patient              Referral patient identifier
    * @param   i_id_inst_orig            Referral institution origin
    * @param   i_id_inst_dest            Referral institution dest
    * @param   i_id_dep_clin_serv        Referral dep_clin_serv
    * @param   i_id_speciality           Referral speciality (origin)
    * @param   i_flg_type                Referral type
    * @param   i_id_prof_requested       Professional that requested referral   
    * @param   i_id_prof_redirected      Professional to whom the referral was forwarded to   
    * @param   i_decision_urg_level      Urgency level used in triage
    *
    * @value   i_completed               {*} 'Y' - Yes {*} 'N' - No   
    * @value   i_flg_type                {*} 'C' - Appointments
    *                                    {*} 'A' - Lab tests
    *                                    {*} 'I' - Imaging exams
    *                                    {*} 'E' - Other exams
    *                                    {*} 'P' - Procedures
    *                                    {*} 'F' - Physical Medicine and Rehabilitation
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   16-09-2009
    */
    FUNCTION can_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref                 IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        -- workflow data
        i_id_patient         IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if the referral can be scheduled
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software
    * @param   i_ref                     Referral identifier
    * @param   i_flg_status              Referral status
    * @param   i_id_workflow             Referral workflow identifier
    * @param   i_id_profile_template     Professional profile template that is requesting cancelation
    * @param   i_id_functionality        Professional functionality that is requesting cancelation
    * @param   i_id_category             Professional category that is requesting cancelation   
    * @param   i_id_patient              Referral patient identifier
    * @param   i_id_inst_orig            Referral institution origin
    * @param   i_id_inst_dest            Referral institution dest
    * @param   i_id_dep_clin_serv        Referral dep_clin_serv
    * @param   i_id_speciality           Referral speciality (origin)
    * @param   i_flg_type                Referral type
    * @param   i_id_prof_requested       Professional that requested referral   
    * @param   i_id_prof_redirected      Professional to whom the referral was forwarded to   
    * @param   i_decision_urg_level      Urgency level used in triage
    *
    * @value   i_completed               {*} 'Y' - Yes {*} 'N' - No   
    * @value   i_flg_type                {*} 'C' - Appointments
    *                                    {*} 'A' - Lab tests
    *                                    {*} 'I' - Imaging exams
    *                                    {*} 'E' - Other exams
    *                                    {*} 'P' - Procedures
    *                                    {*} 'F' - Physical Medicine and Rehabilitation
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-05-2011
    */
    FUNCTION can_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref                 IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        -- workflow data
        i_id_patient         IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE
    ) RETURN VARCHAR2;

    /**
    * check if the referral can be approved 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ref  referral id
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-05-2012
    */
    FUNCTION can_approve
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref                 IN p1_external_request.id_external_request%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        -- workflow data
        i_id_patient         IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets referral detail
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_ext_req        Referral identifier
    * @param   i_status_detail     Detail status returned    
    * @param   o_patient           Patient general data
    * @param   o_detail            Referral general data
    * @param   o_text              Referral information detail
    * @param   o_problem           Patient problems
    * @param   o_diagnosis         Patient diagnosis
    * @param   o_mcdt              MCDTs information
    * @param   o_needs             Additional needs for scheduling
    * @param   o_info              Additional needs for the appointment
    * @param   o_notes_status      Referral historical data
    * @param   o_notes_status_det  Referral historical data detail
    * @param   o_answer            Referral answer information
    * @param   o_title_status      Deprecated
    * @param   o_can_cancel        'Y' if the request can be canceled, 'N' otherwise
    * @param   o_ref_orig_data     Referral orig data   
    * @param   o_fields_rank       Cursor with field names and ranks
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_status_detail     {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @value   o_can_cancel        {*} 'Y' if the request can be canceled {*} 'N' otherwise   
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   03-11-2006
    */
    FUNCTION get_referral
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_status_detail IN p1_detail.flg_status%TYPE,
        o_patient       OUT pk_types.cursor_type,
        --o_detail           OUT pk_ref_core.row_detail_cur,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_title_status     OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_orig_data    OUT pk_types.cursor_type,
        o_ref_comments     OUT pk_types.cursor_type,
        o_fields_rank      OUT pk_types.cursor_type,
        o_med_dest_data    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral cancellation request data to be shown in the brief screen
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional id, institution and software
    * @param   I_ID_REF         Referral identifier
    * @param   I_ID_ACTION      Action identifier. This Parameter will be used to return o_c_req_answ
    * @param   O_REF_DATA       Referral data nedded for the cancellation request brief screen
    * @param   O_C_REQ_DATA     Cancellation request data
    * @param   O_C_REQ_ANSW     Cancellation request answer
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-09-2010
    */
    FUNCTION get_referral_req_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_id_action  IN wf_action.id_action%TYPE,
        o_ref_data   OUT pk_types.cursor_type,
        o_c_req_data OUT pk_types.cursor_type,
        o_c_req_answ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert, Update or/and Cancel p1 detail records
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_ext_req       Request ID
    * @param   i_prof          Professional, institution and software ids
    * @param   i_detail        P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_ext_req_track Tracking ID
    * @param   i_date          Operation date   
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   06-01-2009
    * Notes:   - id_detail null, text not null, flg=I: inserts an active detail record
    *          - id_detail not null, flg=C: cancels detail record id_detail
    *          - id_detail null, flg=C: inserts a canceled detail record
    *          - id_detail not null, flg=O: updates detail_record id_detail (Outdated)
    *          - id_detail null, flg=O: inserts an outdated detail record   
    *          - id_detail not null, flg=D: deletes detail record id_detail from db (in case text is null)
    *          - id_detail not null, text not null, flg=U: updates detail_record id_detail (updates text and dt_insert_tstz only)     
    */
    FUNCTION set_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_prof          IN profissional,
        i_detail        IN table_table_varchar,
        i_ext_req_track IN p1_tracking.id_tracking%TYPE,
        i_date          IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verificar se os dados obrigat½rios do utente est’o preenchidos
    *
    * @param I_LANG         Lingua registada como preferencia do profissional
    * @param I_PROF         Profissional q regista
    * @param I_PAT          Id do paciente
    * @param O_ERROR        Erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    */
    FUNCTION check_mandatory_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_pat    IN patient.id_patient%TYPE,
        i_id_ref IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doctor_test
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_doc   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_sched_test
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_doc     IN professional.id_professional%TYPE,
        i_date    IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_efectiv_test
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets number of available dcs for the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_count number of available dcs    
    * @param   o_id dcs id, when there's only one.
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets value from p1_worflow_config
    * 
    * @param   i_prof professional, institution and software ids
    * @param   i_code_param name of the parameter (column p1_speciality.code_workflow_config)
    * @param   i_speciality p1 speciality for which the parameter applies
    * @param   i_inst_orig  id of referral origin institution for which the parameter applies
    * @param   i_inst_dest  id of referral destination institution for which the parameter applies        
    * @param   i_workflow id of referral workflow
    *
    * @RETURN  
    * @author  Joao Sa
    * @version 1.0
    * @since   06-05-2008
    */
    FUNCTION get_workflow_config
    (
        i_prof       IN profissional,
        i_code_param IN p1_workflow_config.code_workflow_config%TYPE,
        i_speciality IN p1_speciality.id_speciality%TYPE,
        i_inst_dest  IN institution.id_institution%TYPE,
        i_inst_orig  IN institution.id_institution%TYPE,
        i_workflow   IN wf_workflow.id_workflow%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the value list from p1_worflow_config
    * 
    * @param   i_prof professional, institution and software ids
    * @param   i_code_param name of the parameter (column p1_speciality.code_workflow_config)
    * @param   i_speciality p1 speciality for which the parameter applies
    * @param   i_inst_orig  id of referral origin institution for which the parameter applies
    * @param   i_inst_dest  id of referral destination institution for which the parameter applies     
    * @param   i_workflow id of referral workflow       
    *
    * @RETURN  List of values
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION get_workflow_config_list
    (
        i_prof       IN profissional,
        i_code_param IN p1_workflow_config.code_workflow_config%TYPE,
        i_speciality IN p1_speciality.id_speciality%TYPE,
        i_inst_dest  IN institution.id_institution%TYPE,
        i_inst_orig  IN institution.id_institution%TYPE,
        i_workflow   IN wf_workflow.id_workflow%TYPE
    ) RETURN table_varchar;

    /**
    * Gets the default dep_clin_serv for this institution/speciality 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_exr_row             Referral data (uses only id_speciality, id_inst_dest and id_external_sys)
    * @param   o_dcs                 Deaprtment and service identifier   
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   30-04-2008
    */
    FUNCTION get_default_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_exr_row IN p1_external_request%ROWTYPE,
        o_dcs     OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the default dep_clin_serv for this institution/speciality 
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_ref              Referral identifier
    * @param   i_id_speciality       Referral speciality identifier
    * @param   i_id_inst_dest        Dest institution identifier
    * @param   i_id_ext_sys          External system identifier   
    * @param   o_dcs                 Deaprtment and service identifier   
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-10-2012
    */
    FUNCTION get_default_dcs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        i_id_speciality IN p1_external_request.id_speciality%TYPE,
        i_id_inst_dest  IN p1_external_request.id_inst_dest%TYPE,
        i_id_ext_sys    IN p1_external_request.id_external_sys%TYPE,
        o_dcs           OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return sequential_number for the request
    *
    * This function is used by the servlet of the report interface to confirm that the
    * request comes from a reliable source.
    *
    * @param   i_ext_req request id
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo’o S
    * @version 1.0
    * @since   17-02-2007
    *
    FUNCTION get_ref_data
    (
        i_prof    IN profissional,
        i_lang    IN language.id_language%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /**
    * Get descriptions for provided tables and ids.
    * Used by the interface to get Alert description of mapped ids.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_key  table names and ids, third field used only for sys_domain. (TABLE_NAME, ID[VAL], [CODE_DOMAIN])
    * @param   o_id   result id  description. (ID[VAL])
    * @param   o_desc result description. (Description)    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   28-10-2008
    */
    FUNCTION get_description
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_key   IN table_table_varchar, -- (TABELA, ID[VAL], [CODE_DOMAIN])
        o_id    OUT table_varchar,
        o_desc  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient age and gender
    *
    * @param   i_dt_birth  Patient birth date
    * @param   i_age       Patient age (in table patient)
    *
    * @RETURN  Patient age
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-06-2013
    */
    FUNCTION get_pat_age
    (
        i_dt_birth IN patient.dt_birth%TYPE,
        i_age      IN patient.age%TYPE
    ) RETURN patient.age%TYPE;

    /**
    * Get patient age and gender
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_patient  patient id (to get age and gender)
    * @param   o_info  output
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   18-11-2008
    */
    FUNCTION get_pat_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient age and gender
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Professional id, institution and software
    * @param   i_patient  Patient identifier
    * @param   o_gender   Patient gender
    * @param   o_age      Patient age in years
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-07-2013
    */
    FUNCTION get_pat_age_gender
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient sns health plan
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_patient  patient identifier
    * @param   i_active If set to 'Y' only returns the Patient's SNS number if defaluled 
    *             (check_sns_active_epis returns 'Y')    
    * @param   i_epis   episode id
    * @param   o_info  output
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    *
    * @odified by: Ricardo Patrocínio
    * @modified in: 2009-11-05
    * @change reason: [ALERT-54754]
    */
    FUNCTION get_pat_sns
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_epis    IN episode.id_episode%TYPE,
        i_active  IN VARCHAR2 DEFAULT pk_ref_constant.g_no, -- ALERT-50017: Only return SNS if FLG_DEFAULT is 'Y'
        o_num_sns OUT pat_health_plan.num_health_plan%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if the referral is editable.
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_ext_req       Referral id
    *
    * @RETURN  Y if editable, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION is_editable
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2;

    /**
    * Validates if the referral is editable.
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_ext_row       Referral info
    * @param   i_prof_data     Professional data
    *
    * @RETURN  Y if editable, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION is_editable
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ext_row   IN p1_external_request%ROWTYPE
    ) RETURN VARCHAR2;

    /**
    * Validates if dest institution is inside orig institution ref area
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_inst_orig     Origin institution identifier
    * @param   i_inst_dest     Dest institution identifier
    * @param   i_ref_type      Referral type
    * @param   i_id_spec       Speciality identifier
    *
    * @value   i_ref_type      {*} 'C' consultation {*} 'A' analisys {*} 'E' exam {*} 'I' intervention {*} 'P' procedures {*} 'F' mfr
    *
    * @RETURN  Y if inside ref area, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-07-2009
    */
    FUNCTION get_inside_ref_area
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        i_inst_dest IN p1_dest_institution.id_inst_dest%TYPE,
        i_ref_type  IN p1_dest_institution.flg_type%TYPE,
        i_id_spec   IN ref_dest_institution_spec.id_speciality%TYPE
    ) RETURN VARCHAR2;

    /**
    * Inserts notes into p1_detail 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_detail_row notes   
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   07-05-2008
    */
    FUNCTION set_ref_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_detail_row IN p1_detail%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if is Clinical Director
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-10-2009
    */

    FUNCTION is_clinical_director
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
        
    ) RETURN BOOLEAN;

    /**
    * Validate if the professional is a clinical director or not. Function used for grid
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   5-5-2010
    */

    FUNCTION validate_clin_dir
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
        
    ) RETURN VARCHAR2;

    /**
    * Gets the institution to be shown
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_flg_status     referral status
    * @param   i_id_institution   Institution ID
    * @param   i_code_institution Institution Code
    * @param   i_inst_abbrev      Institution Abbreviation
    */
    FUNCTION get_inst_name
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN p1_external_request.flg_status%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_code_institution IN institution.code_institution%TYPE,
        i_inst_abbrev      IN institution.abbreviation%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns origin instituion name
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_inst_orig            Origin institution identifier
    * @param   i_inst_name_roda          External institution name (in case of WF=4)
    * @param   i_inst_parent_name        Name of the parent institution
    *
    * @RETURN  Origin institution name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-09-2013
    */
    FUNCTION get_inst_orig_name
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_inst_orig     IN p1_external_request.id_inst_orig%TYPE,
        i_inst_name_roda   IN ref_orig_data.institution_name%TYPE,
        i_inst_parent_name IN pk_translation.t_desc_translation DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Returns origin instituion name to be shown in referral detail
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_inst_orig            Origin institution identifier
    * @param   i_inst_name_roda          External institution name (in case fo WF=4)
    * @param   i_id_inst_orig_parent     Parent of the origin institution identifier
    *
    * @RETURN  Origin institution name
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-10-2012
    */
    FUNCTION get_inst_orig_name_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_inst_orig        IN p1_external_request.id_inst_orig%TYPE,
        i_inst_name_roda      IN ref_orig_data.institution_name%TYPE,
        i_id_inst_orig_parent IN institution.id_parent%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets referral error description
    *
    * @param   i_lang             Language
    * @param   i_id_ref_error     Referral error code
    *
    * @return  professional interface
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION get_ref_error_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_id_ref_error IN ref_error.id_ref_error%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if this institution is private or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_inst       Institution identifier   
    * @param   o_flg_result    Flag indicating if this institution is private or not
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION check_private_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_inst    IN institution.id_institution%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get run_number
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_external_request 
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2010 
    */
    FUNCTION get_run_curp_number
    (
        i_id_patient patient.id_patient%TYPE,
        i_id_market  market.id_market%TYPE
        
    ) RETURN VARCHAR;

    /**
    * Get the master profile
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_profile 
    * @param   o_master_prof
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_profile_owner
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_profile     IN profile_template.id_profile_template%TYPE,
        o_master_prof OUT profile_template.id_profile_template%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the master profile identifier
    *
    * @param   i_profile      Professional profile identifier
    *
    * @RETURN  the master profile identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-03-2013 
    */
    FUNCTION get_profile_owner(i_profile IN profile_template.id_profile_template%TYPE)
        RETURN profile_template.id_profile_template%TYPE;

    /**
    * Get the Ref type for prof
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_clinical_service 
    * @param   i_id_institution 
    * @param   i_id_software 
    * @param   o_prof
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_ref_flg_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_requested IN table_varchar,
        o_flg_type          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets Referral Status F description
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_ID_REF       Referral identifier
    * @param   I_SUBJECT      Subject for grouping of actions   
    * @param   I_FROM_STATE   Begin action state     
    * @param   O_ACTIONS      Referral actions
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   27-09-2010
    */
    FUNCTION get_ref_f_information
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_professional     IN professional.id_professional%TYPE DEFAULT NULL,
        i_id_external_request IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        i_id_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        o_cursor              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get professionals available for schedule
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_spec              P1_SPECIALITY Id
    * @param   i_inst_dest         Institution Id
    * @param   o_sql               List of professionals 
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-10-2010
    */
    FUNCTION get_prof_to_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_spec      IN p1_speciality.id_speciality%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        o_sql       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if prof is a GP physican
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   o_error
    *
    * @RETURN  VARCHAR2
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-10-2010
    */
    FUNCTION check_prof_phy
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN VARCHAR2;

    /**
     * Get id content just for p1_external_request.flg_type = 'C'
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   i_dcs      Values to populate multichoice
    
    *    
    * @RETURN  Id Content 
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-01-2010
    */
    FUNCTION get_content
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        id_prof_sch IN professional.id_professional%TYPE
    ) RETURN appointment.id_appointment%TYPE;

    /**
    * Get Id Prof destination
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_id_ref         Referral Id
    * @param   i_status         referral status
    *    
    * @RETURN  id_professional
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-04-2010
    */

    FUNCTION get_prof_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_status IN p1_external_request.flg_status%TYPE
    ) RETURN professional.id_professional%TYPE;

    FUNCTION get_no_show_id_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_p1_reason_code IN p1_reason_code.id_reason_code%TYPE,
        o_value          OUT cancel_reason.id_cancel_reason%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_no_show_id_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_p1_reason_code OUT p1_reason_code.id_reason_code%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral status that are considered active (emited and not closed) 
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    * @param   o_active_status     Active status not considering dt_status
    * @param   o_active_status_dt  Active status considering dt_status
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  table_varchar referral status
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2011
    */
    FUNCTION get_pat_active_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_active_status    OUT NOCOPY table_varchar,
        o_active_status_dt OUT NOCOPY table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral status that are considered closed 
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    *
    * @RETURN  table_varchar referral status
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-01-2012
    */
    FUNCTION get_pat_closed_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar;

    /**
    * Get MCDT's Nature 
    *
    * @param   i_mcdt              Id MCDT
    * @param   i_type              MCDT type: {*} 'A' Analysis
                                              {*} 'I' Image
                                              {*} 'E' Other exams
                                              {*} 'P' intervetions
                                              {*} 'F' MFR                                                                                           
    * @RETURN  Varchar 
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-08-2011
    **/

    FUNCTION get_mcdt_nature
    (
        i_mcdt IN mcdt_nature.id_mcdt%TYPE,
        i_type IN mcdt_nature.flg_mcdt%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_mcdt_nature_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_nature IN VARCHAR2
    ) RETURN VARCHAR;
    /**
    * Get MCDT's nisencao
    * apensar de um paciente ser isento pode no ser por mcdt 
    *
    * @param   i_mcdt              Id MCDT
    * @param   i_type              MCDT type: {*} 'A' Analysis
                                              {*} 'I' Image
                                              {*} 'E' Other exams
                                              {*} 'P' intervetions
                                              {*} 'F' MFR                                                                                           
    * @RETURN  Varchar 
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-08-2011
    **/
    FUNCTION get_mcdt_nisencao
    (
        i_mcdt IN mcdt_nature.id_mcdt%TYPE,
        i_type IN mcdt_nature.flg_mcdt%TYPE
    ) RETURN VARCHAR2;

    /* Check if referral home is active
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_type         Referral type: {*} (C)onsultation 
                                             {*} (A)nalysis 
                                             {*} (I)mage 
                                             {*} (E)xam 
                                             {*} (P)rocedure 
                                             {*} (M)fr 
    * @param   o_home_active  Return :       {*} (Y)es if home is active
                                             {*} (N)o if home is inactive
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-09-2011
    */

    FUNCTION check_referral_home
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN p1_external_request.flg_type%TYPE,
        o_home_active OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* Check if referral reason is mandatory
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional, institution and software ids
    * @param   i_type       Referral type: {*} (C)onsultation 
                                           {*} (A)nalysis 
                                           {*} (I)mage 
                                           {*} (E)xam 
                                           {*} (P)rocedure 
                                           {*} (M)fr
    * @param   i_home        Array with all flg_home
    * @param   i_priority    Array with all flg_prioritys
    * @param   o_reason_mandatory Return : {*} (Y)es if home is active
                                           {*} (N)o if home is inactive
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-09-2011
    */
    FUNCTION check_referral_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_type             IN p1_external_request.flg_type%TYPE,
        i_home             IN table_varchar,
        i_priority         IN table_varchar,
        o_reason_mandatory OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if Referral diagnosis is mandatory
    *
    * @param   I_LANG             language associated to the professional executing the request
    * @param   I_PROF             professional, institution and software ids
    * @param   o_diag_mandatory   Referral Diagnosis: {*} 'Y' Mandatory {*} 'N' Not mandatory    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-08-2013 
    */
    FUNCTION check_referral_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_diag_mandatory OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get BDNP title
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_ref               Referral identifier
    * @param   i_id_prof_requested Professional that requested the referral
    * @param   i_flg_event         Event identifier           
    * @param   i_id_prof_requested Professional identifier that requested the referral
    *   
    * @RETURN  BDNP title
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-11-2011
    */
    FUNCTION get_bdnp_title
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ref               IN p1_external_request.id_external_request%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_flg_event         IN bdnp_presc_tracking.flg_event_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Validates if the professional can create referrals and returns labels showing the type of referrals that can be created
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer
    * @param   i_id_patient   Patient identififer
    * @param   i_external_sys External system identifier
    * @param   o_cursor       Labels showing the type of referrals that can be created  
    * @param   o_error        An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-10-2012
    */
    FUNCTION check_ref_creation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cursor       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns sibling institutions that has the same parent of type 'H'
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer  
    * @param   i_flg_slef     Flag indicating if returns self instituion or not
    *
    * @return  TRUE array of sibling institutions    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2012
    */
    FUNCTION get_sibling_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_slef IN VARCHAR2 DEFAULT pk_ref_constant.g_no
    ) RETURN table_number;

    /**
    * Returns sibling institutions that has the same parent of type 'H'
    * Returns self instituion if i_flg_slef is set to 'Y'
    *
    * @param   i_id_institution  Institution identififer  
    * @param   i_flg_slef        Flag indicating if returns self instituion or not
    *
    * @return  TRUE array of sibling institutions    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2012
    */
    FUNCTION get_sibling_inst
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_slef       IN VARCHAR2 DEFAULT pk_ref_constant.g_no
    ) RETURN table_number;

    /**
    * Returns child institutions 
    *
    * @param   i_id_institution  Institution identififer  
    * @param   i_flg_slef        Flag indicating if returns self instituion or not
    *
    * @return  TRUE array of sibling institutions    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-05-2013
    */
    FUNCTION get_child_inst(i_id_institution IN institution.id_institution%TYPE) RETURN table_number;

    /**
    * Get last referral active detail for a given type
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional id, institution and software
    * @param   I_PAT            Patient identifier
    * @param   I_FLG_TYPE       Detail type
    * @param   O_DETAIL_TEXT    Detail description 
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   13-02-2013
    **/

    FUNCTION get_ref_last_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_flg_type    IN table_varchar,
        o_detail_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the last comment read of a given professional
    * If professional not specified, returns the last comment read of any professional.
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    * @param   i_ref       Referral identifier
    * @param   i_id_prof   Professional identifier that is being checked. If null, returns the last comment read of any professional.
    * @param   i_flg_type  Referral comments type
    *
    * @value   i_flg_type  {*} 'A'- administrative type {*} 'C'- clinical type
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2013
    */
    FUNCTION get_last_comment_read
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ref      IN p1_external_request.id_external_request%TYPE,
        i_id_prof  IN professional.id_professional%TYPE,
        i_flg_type IN ref_comments.flg_type%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**
    * Checks if the referral can be re-sent to BDNP
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    * @param   i_ref             Referral identifier
    * @param   i_flg_status      Referral status
    * @param   i_flg_migrated    Referral migrated status
    * @param   i_bdnp_available  Flag indicating if BDNP is available
    *
    * @RETURN  'Y' if sucess, 'N' otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-11-2011
    */
    FUNCTION can_sent
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref            IN p1_external_request.id_external_request%TYPE,
        i_flg_status     IN p1_external_request.flg_status%TYPE,
        i_flg_migrated   IN p1_external_request.flg_migrated%TYPE,
        i_bdnp_available IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Crate new Referral comment
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_dt_comment     Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION create_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_dt_comment     IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_cancel      Cancel Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION cancel_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_cancel      IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Edit Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_edit        Edit comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION edit_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_edit        IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets Referral comments info
    * Function used by pagination grids
    *
    * @param   i_lang                       Language associated to the professional executing the request
    * @param   i_prof                       Professional id, institution and software
    * @param   i_prof_data                  Professional id_profile_template, id_functionality, id_category, flg_category, id_market
    * @param   i_ref                        Referral identifier
    * @param   i_id_workflow                Referral workflow identifier
    * @param   i_id_prof_requested          Professional identifier that is responsible for the referral
    * @param   i_id_inst_orig               Referral orig institution identifier
    * @param   i_id_inst_dest               Referral dest institution identifier
    * @param   i_id_dcs                     Referral dep_clin_serv identifier
    * @param   i_dt_last_comment            Last comment date
    * @param   i_comment_count              Number of comments
    * @param   i_prof_comment               Professional that created the last comment    
    * @param   i_inst_comment               Institution where the last comment was created
    *
    * @RETURN  t_rec_ref_comments_info
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    */
    FUNCTION get_ref_comments_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_prof_data         IN t_rec_prof_data,
        i_ref               IN p1_external_request.id_external_request%TYPE,
        i_id_workflow       IN p1_external_request.id_workflow%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest      IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_dt_last_comment   IN ref_comments.dt_comment%TYPE,
        i_comment_count     IN NUMBER,
        i_prof_comment      IN ref_comments.id_professional%TYPE,
        i_inst_comment      IN ref_comments.id_institution%TYPE
    ) RETURN t_rec_ref_comments_info;

    /**
    * Checks if the professional is one of the comment receivers
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software
    * @param   i_id_cat             Professional category identifier
    * @param   i_id_workflow        Referral identifier
    * @param   i_id_prof_requested  Professional that is responsible for the referral   
    * @param   i_id_inst_orig       Referral orig institution identifier
    * @param   i_id_inst_dest       Referral dest institution identifier    
    * @param   i_id_dcs             Referral dep_clin_serv identifier
    * @param   i_flg_type_comm      Referral comment type
    * @param   i_id_inst_comm       Institution identifier where the comment was done   
    *
    * @value   i_flg_type_comm      'C'- clinical, 'A'- administrative
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-01-2014
    */
    FUNCTION check_comm_receiver
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cat            IN prof_cat.id_category%TYPE,
        i_id_workflow       IN p1_external_request.id_workflow%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig      IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest      IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_type_comm     IN ref_comments.flg_type%TYPE,
        i_id_inst_comm      IN ref_comments.id_institution%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if the professional can create the comment
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software
    * @param   i_id_cat             Professional category identifier
    * @param   i_id_workflow        Referral identifier
    * @param   i_id_prof_requested  Professional that is responsible for the referral
    * @param   i_id_inst_orig       Referral orig institution identifier
    * @param   i_id_inst_dest       Referral dest institution identifier    
    * @param   i_id_dcs             Referral dep_clin_serv identifier   
    * @param   i_flg_comm_available Flag indicating if comments funcionality is available at both institutions (orig and dest)
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-01-2014
    */
    FUNCTION check_comm_create
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_cat             IN prof_cat.id_category%TYPE,
        i_id_workflow        IN p1_external_request.id_workflow%TYPE,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE,
        i_id_dcs             IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_comm_available IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Checks if comments funcionality is enabled in both institution: orig and dest
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_inst_orig   Referral orig institution identifier
    * @param   i_id_inst_dest   Referral dest institution identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  'Y'- config is enabled, 'N' - otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2012-01-13
    */
    FUNCTION check_comm_enabled
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE
    ) RETURN VARCHAR2;

    /**
    * Decodes sys_config 'REF_REASON_NOT_MANDATORY': returns 'Y' if reason is mandatory, 'N' otherwise
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   i_flg_type  Referral type
    *
    * @value   i_flg_type  {*} (C)onsultation {*} (A)nalysis {*} (I)mage {*} (E)xam {*} (P)rocedure {*} M(F)r
    *
    * @RETURN  'Y' if reason is mandatory, 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-09-2013
    */
    FUNCTION check_reason_mandatory_cfg
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN p1_external_request.flg_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets shortcut to clinical documents
    *
    * @param   i_lang                       Language associated to the professional executing the request
    * @param   i_prof                       Professional id, institution and software
    *
    * @RETURN  Shortcut id 
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/
    FUNCTION get_documents_shortcut
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_family_relat OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_core;
/
