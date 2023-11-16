/*-- Last Change Revision: $Rev: 2028915 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_status AS

    TYPE t_ibt_status_n IS TABLE OF wf_status.id_status%TYPE INDEX BY VARCHAR2(1);
    TYPE t_ibt_status_v IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;

    /**
    * Is the referral already answered?
    *
    * @param   I_LANG              Language associated to the professional executing the request
    * @param   I_PROF              Professional, institution and software ids
    * @param   I_EPISODE           Id episode 
    * @param   O_ID_EXT_REQ        External Request Identifier 
    * @param   O_WORKFLOW          workflow of the external request
    * @param   O_STATUS_DETAIL     status_detail , null by default
    * @param   O_NEEDS_ANSWER      Does the referral need answer?
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   22-07-2010
    */

    FUNCTION check_ref_answered
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN p1_external_request.id_episode%TYPE,
        o_id_ext_req    OUT p1_external_request.id_external_request%TYPE,
        o_workflow      OUT p1_external_request.id_workflow%TYPE,
        o_status_detail OUT p1_detail.flg_status%TYPE,
        o_needs_answer  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if referral can change to the new workflow identifier
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_wf_old           Id episode 
    * @param   i_id_wf_new         Referral new workflow identifier 
    * @param   i_flg_status        Referral flag status
    * @param   O_STATUS_DETAIL     status_detail , null by default
    * @param   O_NEEDS_ANSWER      Does the referral need answer?
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-05-2013
    */
    FUNCTION check_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_wf_old  IN p1_external_request.id_workflow%TYPE,
        i_id_wf_new  IN p1_external_request.id_workflow%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        o_can_change OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets dep_clin_serv available for issuing the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_ref_row        Referral rowtype
    * @param   i_dcs            Dep_clin_Serv identifier
    * @param   i_mode           Mode: change (S)ame or (O)ther Institution
    * @param   o_dcs_count      dep_clin_serv count
    * @param   o_track_dcs      Dep_clin_Serv default
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-08-2010
    */
    FUNCTION get_dcs_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mode      IN VARCHAR2 DEFAULT NULL,
        o_dcs_count OUT NUMBER,
        o_track_dcs OUT p1_tracking.id_dep_clin_serv%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Converts referral status varchar into a number
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Referral status to be converted
    */
    /*
    FUNCTION convert_status_n
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN p1_external_request.flg_status%TYPE
    ) RETURN NUMBER;
    */

    /**
    * Converts referral status number into a varchar
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Referral status to be converted
    */
    /*
    FUNCTION convert_status_v
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN wf_status.id_status%TYPE
    ) RETURN VARCHAR2;
    */

    /**
    * Converts referral status varchar into a number
    *
    * @param   i_status        Referral status to be converted
    */
    FUNCTION convert_status_n(i_status IN p1_external_request.flg_status%TYPE) RETURN NUMBER;

    /**
    * Converts referral status number into a varchar
    *
    * @param   i_status        Referral status to be converted
    */
    FUNCTION convert_status_v(i_status IN wf_status.id_status%TYPE) RETURN VARCHAR2;

    /**
    * Returns next status when processing this action.
    * Only possible for ID_WORKFLOW/ID_STATUS_BEGIN/ID_ACTION with only one ID_STATUS_END.
    *
    * @param   I_LANG                     Language associated to the professional executing the request
    * @param   I_PROF                     Professional, institution and software ids
    * @param   I_PROF_DATA                Professional info: profile template, category and functionality
    * @param   I_ID_WORKFLOW              Workflow identifier
    * @param   I_FLG_STATUS               Referral current status
    * @param   I_ACTION_NAME              Action internal name
    * @param   IO_PARAM                   Workflows general parameter (for function evaluation)   
    * @param   i_flg_auto_transition      Indicates whether we want automatic transitions.    
    * @param   O_FLG_STATUS               Next referral status
    * @param   O_ERROR                    An error message, set when return=false
    *
    * @value   i_flg_auto_transition      {*} Y - automatic transitions returned
    *                                     {*} N - non-autiomatic transitions returned
    *                                     {*} <null>  - all transitions returned (automatic or not)   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-10-2010
    */
    FUNCTION get_next_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_data           IN t_rec_prof_data,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_action_name         IN wf_workflow_action.internal_name%TYPE,
        i_flg_auto_transition IN VARCHAR2,
        io_param              IN OUT NOCOPY table_varchar,
        o_flg_status          OUT p1_external_request.flg_status%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns next available action to be proced.
    * Only possible when there only one action availabe for processing
    *
    * @param   I_LANG                     Language associated to the professional executing the request
    * @param   I_PROF                     Professional, institution and software ids
    * @param   I_PROF_DATA                Professional info: profile template, category and functionality
    * @param   I_ID_WORKFLOW              Workflow identifier
    * @param   i_flg_status               Current referral status
    * @param   IO_PARAM                   Workflows general parameter (for function evaluation)      
    * @param   O_ACTION_NAME              Action internal name
    * @param   O_FLG_STATUS               Referral end status
    * @param   O_ERROR                    An error message, set when return=false
    *
    * @value   i_flg_auto_transition     {*} Y - automatic transitions returned
    *                                    {*} N - non-autiomatic transitions returned
    *                                    {*} <null>  - all transitions returned (automatic or not)   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-10-2010
    */
    FUNCTION get_next_action
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_id_workflow IN p1_external_request.id_workflow%TYPE,
        i_flg_status  IN p1_external_request.flg_status%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_action_name OUT wf_workflow_action.internal_name%TYPE,
        o_flg_status  OUT p1_external_request.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if tracking date is correct.
    * Cannot register a status change date lower than the last status change date.
    * Cannot register a referral update date lower than MAX(last update, last status change, last transf resp) date
    * Cannot register a referral transf resp date lower than MAX(last update, last status change, last transf resp) date
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_flg_type           Tracking type
    * @param   io_dt_tracking_date  Tracking date to be validated
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_type           {*} 'S' Status change, {*} 'C' Forward to another clinical service, {*} 'P' Forward to triage
    *                               {*} 'R' Read by professional, {*} 'T' Hand off, {*} 'U' Data update
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION validate_tracking_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_ref            IN p1_external_request.id_external_request%TYPE,
        i_flg_type          IN p1_tracking.flg_type%TYPE,
        io_dt_tracking_date IN OUT p1_tracking.dt_tracking_tstz%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates request status and/or register changes in p1_tracking.
    * Only this function can update the request status.
    *
    * @param i_lang          professional language id
    * @param i_prof          professional, institution and software ids
    * @param i_track_row     p1_tracking rowtype. Includes all data to record the referral change. 
    * @param i_dt_requested  Referral date requested (if not null)
    * @param io_param        Array used in framework workflows    
    * @param o_track         Array of ID_TRACKING transitions
    * @param o_error         an error message, set when return=false
    *
    * @value i_status        {*} 'N' New {*} 'I' Issued {*} 'C' Canceled {*} 'B' Bureaucratic Decline {*} 'T' Triage {*} 'A' Accepted 
    *                        {*} 'R' Redirected {*} 'S' Scheduled {*} 'D' Declined {*} 'M' Mailed {*} 'E' Executed {*} 'O' Saved (Under construction) 
    *                        {*} 'X' Refused {*} 'F' Failed {*} 'W' Ans(w)ered {*} 'K' Answer A(k)nowledge   {*} 'P' Printed and delivered to (P)atient
    * @return true if success, false otherwise
    *
    * @author  Joao Sa
    * @version 1.0
    * @since   15-04-2008
    */
    FUNCTION update_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_track_row    IN p1_tracking%ROWTYPE,
        i_dt_requested IN p1_external_request.dt_requested%TYPE DEFAULT NULL,
        io_param       IN OUT NOCOPY table_varchar,
        o_track        OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Registering referral reading
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_EXT_ROW        Referral info 
    * @param   I_DATE           Read date
    * @param   io_param         Array used in framework workflows
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION set_ref_read
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param    IN OUT NOCOPY table_varchar,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates round_id 
    *
    * @param   i_lang              Language associated to the professional 
    * @param   i_prof              Professional, institution and software ids
    * @param   i_flg_status_prev   Previous referral flag status    
    * @param   i_track_row         P1_TRACKING row info
    * @param   o_round_id          The resulting round id
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2009
    */
    FUNCTION get_round
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status_prev IN p1_external_request.flg_status%TYPE,
        i_track_row       IN p1_tracking%ROWTYPE,
        o_round_id        OUT p1_tracking.round_id%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets transition configuration depending on software, institution, category, profile and professional functionality
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *   
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   09-02-2011
    */
    FUNCTION get_wf_transition
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if can change referral to another institution
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION can_change_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is clinical director
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-03-2012
    */
    FUNCTION check_clinical_director
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is clinical director and can decline the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-07-2012
    */
    FUNCTION check_can_decline_cd
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional can decline the referral to the registrar
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-08-2012
    */
    FUNCTION check_can_decline_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional can triage the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-01-2012
    */
    FUNCTION check_can_triage
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional can send the referral to triage
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2013
    */
    FUNCTION check_can_send_triage
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if can request a referral cancellation
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2012
    */
    FUNCTION check_request_cancellation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if can cancel request cancellation
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2012
    */
    FUNCTION check_cancel_r_cancellation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if functionality 'Request referral cancellation' is enabled
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2012
    */
    FUNCTION check_req_c_enabled
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is associated to referral dep_clin_serv
    * Note: Returns (A)llow if no dep_clin_serv defined for the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-05-2011
    */
    FUNCTION check_tasks_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is associated to referral dep_clin_serv
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Clinical service triage physician"
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv_te
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Triage physician"
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv_t
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Consulting physician"
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION check_dep_clin_serv_c
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional is associated to referral dep_clin_serv as "Clinical service triage physician" or if 
    * professional the one to whom the referral was forwarded
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-10-2013
    */
    FUNCTION check_dcs_triage
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Checks if referral can be marked as no show
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *   
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-05-2012
    */
    FUNCTION check_no_show
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Checks if professional is associated to the dep_clin_serv and if the referral can be marked as no show
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *   
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-05-2012
    */
    FUNCTION check_dcs_no_show
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if professional can cancel the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  VARCHAR2 'A' - transition allowed 'D' - transition denied
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-07-2012
    */
    FUNCTION check_can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Gets status configuration depending on software, institution, profile and professional functionality
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids   
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identification        
    * @param   i_func               Functionality identification
    * @param   i_status_info        Status information configured in table WF_STATUS_CONFIG
    * @param   i_param              Referral information
    *
    * @value   i_param              i_param(1)=id_external_request, i_param(2)=id_patient, i_param(3)=id_inst_orig, 
    *                               i_param(4)=id_inst_dest, i_param(5)=id_dep_clin_serv, i_param(6)=id_speciality, 
    *                               i_param(7)=flg_type, i_param(8)=decision_urg_level, i_param(9)=id_prof_requested, 
    *                               i_param(10)=id_prof_redirected, i_param(11)=id_prof_status, i_param(12)=id_external_sys, 
    *                               i_param(13)=location, i_param(14)=flg_completed, i_param(15)=action_name
    *
    * @RETURN  status info
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   09-02-2011
    */
    FUNCTION get_wf_status_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_category    IN wf_status_config.id_category%TYPE,
        i_profile     IN wf_status_config.id_profile_template%TYPE,
        i_func        IN wf_status_config.id_functionality%TYPE,
        i_status_info IN t_rec_wf_status_info,
        i_param       IN table_varchar
    ) RETURN t_rec_wf_status_info;

    /**
    * Changes referral status to the previous status (undo the last status change)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action to be processed
    * @param   I_STATUS_END     End status of this transition
    * @param   I_NOTES_DESC     Status change notes    
    * @param   I_NOTES_TYPE     Status change notes type    
    * @param   I_OP_DATE        Status change date      
    * @param   io_param         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2010
    */
    FUNCTION set_ref_prev_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_notes_desc IN p1_detail.text%TYPE DEFAULT NULL,
        i_notes_type IN p1_detail.flg_type%TYPE DEFAULT NULL,
        i_op_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status. This is a base function. 
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action to be processed
    * @param   I_STATUS_END     End status of this transition
    * @param   I_FLG_TYPE       Type of change.   
    * @param   I_REASON_CODE    Status change reason code
    * @param   I_DCS            Dep_clin_Serv identifier
    * @param   I_ID_PROF_DEST   Professional destination identifier
    * @param   I_FLG_SUBTYPE    FLG_SUBTYPE
    * @param   I_ID_SCHEDULE    Schedule identifier
    * @param   I_FLG_RESCHEDULE Flag indicating it is not the first schedule    
    * @param   I_LEVEL          Deciion urgency level   
    * @param   I_ID_INST_DEST   Institution dest indentifier   
    * @param   I_ID_SPECIALITY  Referral speciality indentifier
    * @param   I_DT_REQUESTED   Referral date requested (if not null)
    * @param   I_NOTES_DESC     Status change notes    
    * @param   I_NOTES_TYPE     Status change notes type     
    * @param   I_OP_DATE        Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation   
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_FLG_STATUS     Referral status after update    
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2010
    */
    FUNCTION set_ref_base
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_action         IN wf_workflow_action.internal_name%TYPE,
        i_status_end     IN p1_external_request.flg_status%TYPE,
        i_flg_type       IN p1_tracking.flg_type%TYPE,
        i_reason_code    IN p1_tracking.id_reason_code%TYPE DEFAULT NULL,
        i_dcs            IN p1_tracking.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_prof_dest   IN p1_tracking.id_prof_dest%TYPE DEFAULT NULL,
        i_flg_subtype    IN p1_tracking.flg_subtype%TYPE DEFAULT NULL,
        i_id_schedule    IN p1_tracking.id_schedule%TYPE DEFAULT NULL,
        i_flg_reschedule IN p1_tracking.flg_reschedule%TYPE DEFAULT NULL,
        i_level          IN p1_tracking.decision_urg_level%TYPE DEFAULT NULL,
        i_id_inst_dest   IN p1_tracking.id_inst_dest%TYPE DEFAULT NULL,
        i_id_speciality  IN p1_tracking.id_speciality%TYPE DEFAULT NULL,
        i_dt_requested   IN p1_external_request.dt_requested%TYPE DEFAULT NULL,
        i_notes_desc     IN p1_detail.text%TYPE DEFAULT NULL,
        i_notes_type     IN p1_detail.flg_type%TYPE DEFAULT NULL,
        i_op_date        IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        io_param         IN OUT NOCOPY table_varchar,
        o_track          OUT table_number,
        o_flg_status     OUT p1_tracking.ext_req_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Issues request, changes referral status to I
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date
    * @param   I_MODE           Change (S)ame or (O)ther Institution
    * @param   I_DCS            Dep_clin_serv id
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro / Joana Barroso
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION set_ref_issued2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_mode       IN VARCHAR2 DEFAULT pk_ref_constant.g_issue_mode_s,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral destination institution
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action          
    * @param   I_STATUS_END     End status
    * @param   I_INST_DEST      New Institution id        
    * @param   I_DCS            Dep_clin_serv id  
    * @param   I_NOTES          Status change notes  
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false         
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-06-2009
    */
    FUNCTION set_ref_dest_inst2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_inst_dest  IN institution.id_institution%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes status referral to (T)riage
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids 
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Reason code id
    * @param   I_DCS            Dep_clin_serv id
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION set_ref_sent_triage
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes       IN VARCHAR2,
        i_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral clinical service
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DCS            Dep_clin_serv id    
    * @param   I_SUBTYPE                
    * @param   I_NOTES          Status change notes
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_cs2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_subtype    IN VARCHAR2,
        i_notes      IN p1_detail.text%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes status referral to (A)ccepted
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action         
    * @param   I_STATUS_END     End status
    * @param   I_PROF_DEST      Appointment professional id
    * @param   I_DCS            Dep_clin_serv id
    * @param   I_LEVEL          Triage decision urgency       
    * @param   I_NOTES          Status change notes
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   28-06-2009
    */
    FUNCTION set_ref_triaged2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_prof_dest  IN professional.id_professional%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_level      IN p1_external_request.decision_urg_level%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status after scheduling
    * (based on PK_P1_EXT_SYS.set_status_scheduled)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Profile_template, functionality, and category ids   
    * @param   i_ref_row        Referral info   
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   i_date           Status change date  
    * @param   i_schedule       Schedule identifier to be associated to the referral
    * @param   i_episode        Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009
    */
    FUNCTION set_ref_scheduled2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        i_schedule   IN p1_external_request.id_schedule%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes status referral to (M)ailed
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date    
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions  
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION set_ref_mailed2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status to "E" (efectivation)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION set_ref_efectv2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_action         IN wf_workflow_action.internal_name%TYPE,
        i_status_end     IN p1_external_request.flg_status%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE,
        i_transaction_id IN VARCHAR2,
        io_param         IN OUT NOCOPY table_varchar,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Medical decline
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Decline reason code
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_decline2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Medical decline
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Decline reason code
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   28-03-2011
    */
    FUNCTION set_ref_decline_cd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Forwards referral
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   i_prof_dest      Professional id to which referral is being forwarded    
    * @param   i_subtype            
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_forward2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_prof_dest  IN professional.id_professional%TYPE,
        i_subtype    IN VARCHAR2,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Medical refuse
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date      
    * @param   I_NOTES          Status change notes
    * @param   I_REASON_CODE    Refuse reason code    
    * @param   i_subtype        
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2009
    */
    FUNCTION set_ref_refuse2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_subtype     IN VARCHAR2,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel referral
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date
    * @param   I_NOTES          Status change notes    
    * @param   I_REASON_CODE    Cancelation reason code
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-06-2009
    */
    FUNCTION set_ref_cancel2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert consultation doctor 
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_PROF_DATA        Profile_template, functionality, and category ids   
    * @param   I_REF_ROW          Referral info 
    * @param   I_ACTION           Action
    * @param   I_STATUS_END       End status
    * @param   I_DATE             Status change date      
    * @param   I_DIAGNOSIS        Selected diagnosis
    * @param   I_DIAG_DESC        Diagnosis description, when entered in text mode
    * @param   I_ANSWER           Observation, Therapy, Exam and Conclusion
    * @param   IO_PARAM           Parameters for framework workflows evaluation
    * @param   I_HEALTH_PROB      Select Health Problem 
    * @param   I_HEALTH_PROB_DESC Health Problem description, when entered in text mode        
    * @param   O_TRACK            Array of ID_TRACKING transitions
    * @param   O_ERROR            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-06-2009
    */
    FUNCTION set_ref_answer2
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_data        IN t_rec_prof_data,
        i_ref_row          IN p1_external_request%ROWTYPE,
        i_action           IN wf_workflow_action.internal_name%TYPE,
        i_status_end       IN p1_external_request.flg_status%TYPE,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE,
        i_diagnosis        IN table_number,
        i_diag_desc        IN table_varchar,
        i_answer           IN table_table_varchar,
        io_param           IN OUT NOCOPY table_varchar,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_track            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates referral status to "N"
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_DCS            Department and service identifier (in case FLG_VISIBLE=Y)
    * @param   I_STATUS_END     End status
    * @param   I_DATE           Status change date
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION set_ref_new2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_dcs        IN p1_external_request.id_dep_clin_serv%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a previous appointment
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info 
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_SCHEDULE       Schedule identifier   
    * @param   I_NOTES          Status change notes
    * @param   I_DATE           Status change date  
    * @param   i_reason_code    Referral reason code                    
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2009
    */
    FUNCTION set_ref_cancel_sch2
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_ref_row     IN p1_external_request%ROWTYPE,
        i_action      IN wf_workflow_action.internal_name%TYPE,
        i_status_end  IN p1_external_request.flg_status%TYPE,
        i_schedule    IN schedule.id_schedule%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        io_param      IN OUT NOCOPY table_varchar,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status to "V". Means that the referral was approved by clinical director and needs informed consent.
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info     
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_NOTES          Status change notes   
    * @param   I_DATE           Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-03-01
    */
    FUNCTION set_ref_approved2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_data  IN t_rec_prof_data,
        i_ref_row    IN p1_external_request%ROWTYPE,
        i_action     IN wf_workflow_action.internal_name%TYPE,
        i_status_end IN p1_external_request.flg_status%TYPE,
        i_notes      IN p1_detail.text%TYPE,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE,
        io_param     IN OUT NOCOPY table_varchar,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status to "F". Means that the Patient no show
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_PROF_DATA      Profile_template, functionality, and category ids   
    * @param   I_REF_ROW        Referral info     
    * @param   I_ACTION         Action
    * @param   I_STATUS_END     End status
    * @param   I_NOTES          Status change notes   
    * @param   I_DATE           Status change date      
    * @param   IO_PARAM         Parameters for framework workflows evaluation
    * @param   O_TRACK          Array of ID_TRACKING transitions
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   2010-03-01
    */
    FUNCTION set_ref_noshow
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_action         IN wf_workflow_action.internal_name%TYPE,
        i_status_end     IN p1_external_request.flg_status%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason_code    IN p1_tracking.id_reason_code%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE,
        i_transaction_id IN VARCHAR2,
        io_param         IN OUT NOCOPY table_varchar,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if funcionality is enabled
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   I_CONFIG         Configuration to be validated
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  'Y'- config is enabled, 'N' - otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2012-01-13
    */
    FUNCTION check_config_enabled
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_config IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Function used in grids to return referral status icon, color, rank, flg_update and a column used to order by. 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_rec_status            Status data       
    * @param   i_dt_status_tstz        Date of last status change
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-02-2013
    */
    FUNCTION get_flash_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_rec_status     IN t_rec_wf_status_info,
        i_dt_status_tstz IN p1_external_request.dt_status_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * Function used in grids to return referral status icon, color, rank, flg_update and a column used to order by. 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_sts_icon              Status icon    
    * @param   i_sts_color             Status color
    * @param   i_sts_rank              Status rank
    * @param   i_sts_flg_update        Flag indicating if the referral can be update in this status       
    * @param   i_dt_status_tstz        Date of last status change
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-08-2009
    */
    FUNCTION get_flash_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sts_icon       IN wf_status.icon%TYPE,
        i_sts_color      IN wf_status.color%TYPE,
        i_sts_rank       IN wf_status.rank%TYPE,
        i_sts_flg_update IN wf_status_config.flg_update%TYPE,
        i_dt_status_tstz IN p1_external_request.dt_status_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * Function used in grids to return referral status icon, color, rank, flg_update and a column used to order by. 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_ext_req               Referral identifier    
    * @param   i_id_prof_templ         Professional profile_template identifier
    * @param   i_id_category           Professional category identifier
    * @param   i_id_func               Professional functionality identifier       
    * @param   i_workflow              Referral workflow
    * @param   i_flg_status            Referral status       
    * @param   i_dt_status_tstz        Last status change date   
    * @param   i_location              Referral location
    * @param   i_id_patient            Referral patient identifier
    * @param   i_id_inst_orig          Referral institution origin
    * @param   i_id_inst_dest          Referral institution dest
    * @param   i_id_dep_clin_serv      Referral dep_clin_serv
    * @param   i_decision_urg_level    Decision urgency level assigned when triaging referral
    * @param   i_id_prof_requested     Professional that requested referral   
    * @param   i_id_prof_redirected    Professional to whom the referral was forwarded to
    * @param   i_id_speciality         Referral specialty
    * @param   i_flg_type              Referral type
    * @param   i_id_prof_status        Professional that changed the referral status
    * @param   i_external_sys          External system that created the referral
    *
    * @RETURN  Referral status info  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-08-2009
    */
    FUNCTION get_flash_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_prof_templ  IN profile_template.id_profile_template%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_func        IN sys_functionality.id_functionality%TYPE,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_flg_status     IN p1_external_request.flg_status%TYPE,
        i_dt_status_tstz IN p1_external_request.dt_status_tstz%TYPE,
        -- workflow data
        i_location           IN VARCHAR2 DEFAULT pk_ref_constant.g_location_detail,
        i_id_patient         IN p1_external_request.id_patient%TYPE DEFAULT NULL,
        i_id_inst_orig       IN p1_external_request.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest       IN p1_external_request.id_inst_dest%TYPE DEFAULT NULL,
        i_id_dep_clin_serv   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_id_prof_requested  IN p1_external_request.id_prof_requested%TYPE DEFAULT NULL,
        i_id_prof_redirected IN p1_external_request.id_prof_redirected%TYPE DEFAULT NULL,
        i_id_speciality      IN p1_external_request.id_speciality%TYPE DEFAULT NULL,
        i_flg_type           IN p1_external_request.flg_type%TYPE DEFAULT NULL,
        i_id_prof_status     IN p1_external_request.id_prof_status%TYPE DEFAULT NULL,
        i_external_sys       IN p1_external_request.id_external_sys%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Function used in grids to return status sort column 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_color                 Color icon
    * @param   i_rank                  Rank icon
    *
    * @RETURN  Status sort column 
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   05-04-2011
    */
    FUNCTION get_flash_status_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_color          IN VARCHAR2,
        i_rank           IN VARCHAR2,
        i_dt_status_tstz IN referral_ea.dt_status%TYPE
    ) RETURN VARCHAR2;

    /**
    * Function used in grids to return status sort column 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional id, institution and software    
    * @param   i_rec_status            Status data
    * @param   i_dt_status_tstz        Last status date
    *
    * @RETURN  Status sort column 
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   21-02-2013
    */
    FUNCTION get_flash_status_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_rec_status     IN t_rec_wf_status_info,
        i_dt_status_tstz IN referral_ea.dt_status%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get the referral status string used in grids 
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Professional id, institution and software   
    * @param   i_ref_row              Referral row data
    * @param   o_sts_prof_resp        Status string visible to the professional that is responsible for the referral
    * @param   o_sts_orig_phy_cs_dc   Status string visible to the orig clinical director (profile_template=300)    
    * @param   o_sts_orig_phy_hs_dc   Status string visible to the orig clinical director (profile_template=330)
    * @param   o_sts_orig_phy_cs      Status string visible to the orig physician (profile_template=300)
    * @param   o_sts_orig_phy_hs      Status string visible to the orig physician (profile_template=330)
    * @param   o_sts_orig_reg_cs      Status string visible to the orig registrar (profile_template=310)
    * @param   o_sts_orig_reg_hs      Status string visible to the orig registrar (profile_template=320)
    * @param   o_sts_dest_reg         Status string visible to the dest registrar (profile_template=320)
    * @param   o_sts_dest_phy_te      Status string visible to the dest physician: clinical service triage physician (profile_template=330)
    * @param   o_sts_dest_phy_t       Status string visible to the dest physician: triage physician (profile_template=330)
    * @param   o_sts_dest_phy_mc      Status string visible to the dest physician: consulting physician (profile_template=330)
    * @param   o_sts_dest_phy_t_me       Status string visible to the dest physician: I am the triage physician (profile_template=330)
    *
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   04-04-2013
    */
    PROCEDURE get_status_string_ea
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ref_row            IN p1_external_request%ROWTYPE,
        o_sts_prof_resp      OUT referral_ea.sts_prof_resp%TYPE,
        o_sts_orig_phy_cs_dc OUT referral_ea.sts_orig_phy_cs_dc%TYPE,
        o_sts_orig_phy_hs_dc OUT referral_ea.sts_orig_phy_hs_dc%TYPE,
        o_sts_orig_phy_cs    OUT referral_ea.sts_orig_phy_cs%TYPE,
        o_sts_orig_phy_hs    OUT referral_ea.sts_orig_phy_hs%TYPE,
        o_sts_orig_reg_cs    OUT referral_ea.sts_orig_reg_cs%TYPE,
        o_sts_orig_reg_hs    OUT referral_ea.sts_orig_reg_hs%TYPE,
        o_sts_dest_reg       OUT referral_ea.sts_dest_reg%TYPE,
        o_sts_dest_phy_te    OUT referral_ea.sts_dest_phy_te%TYPE,
        o_sts_dest_phy_t     OUT referral_ea.sts_dest_phy_t%TYPE,
        o_sts_dest_phy_mc    OUT referral_ea.sts_dest_phy_mc%TYPE,
        o_sts_dest_phy_t_me  OUT referral_ea.sts_dest_phy_t_me%TYPE
    );

    /**
    * Checks if the referral has already been issued (at least once)
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier 
    *   
    * @RETURN  BOOLEAN              {*} Y- the referral has already been issued once {*} N- the referral has never been issued
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   11-04-2014
    */
    FUNCTION check_ref_issued_once
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2;

    g_validate_changes VARCHAR2(1 CHAR) := 'V';
    g_simulation       VARCHAR2(1 CHAR) := 'S';

END pk_ref_status;
/
