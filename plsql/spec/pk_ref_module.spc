/*-- Last Change Revision: $Rev: 2028910 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_module AS

    /**
    * Gets referral detail according to module circle
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_prof_data              Professional info: profile_template, category and functionality     
    * @param   i_ref_row                P1_EXTERNAL_REQUEST rowtype    
    * @param   o_notes_status           Status info: status, timestamp and professional
    * @param   o_notes_status_det       Status info detail    
    * @param   o_error                  An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-11-2009    
    */
    FUNCTION get_referral_circle
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_data        IN t_rec_prof_data,
        i_ref_row          IN p1_external_request%ROWTYPE,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status after scheduling according to module circle
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_ref_row        P1_EXTERNAL_REQUEST rowtype    
    * @param   i_schedule       Schedule identifier to be associated to the referral
    * @param   i_episode        Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date           Status change date
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2009    
    */
    FUNCTION set_ref_scheduled_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_schedule       IN p1_external_request.id_schedule%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status after scheduling according to module generic
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_prof_data      Profile_template, functionality, and category ids   
    * @param   i_ref_row        P1_EXTERNAL_REQUEST rowtype    
    * @param   i_dcs            Department and service schedule
    * @param   i_schedule       Schedule identifier to be associated to the referral    
    * @param   i_date           Status change date
    * @param   o_track          Array of ID_TRACKING transitions 
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009    
    */
    FUNCTION set_ref_scheduled_generic
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_schedule       IN p1_external_request.id_schedule%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track          OUT table_number,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a previous appointment according to module circle
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids   
    * @param   i_ref_row        Referral info 
    * @param   i_schedule       Schedule identifier   
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2009
    */
    FUNCTION set_ref_cancel_sch_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Notifies the patient about the schedule
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids   
    * @param   i_ref_row        Referral info    
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-12-2009
    */
    FUNCTION set_ref_mailed_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the effectivation of the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids   
    * @param   i_ref_row        Referral info    
    * @param   o_flg_status_new New referral flag status. If NULL the referral does not need  to change status.
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-12-2009
    */
    FUNCTION set_ref_efectv_circle
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_row        IN p1_external_request%ROWTYPE,
        o_flg_status_new OUT p1_external_request.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral detail according to generic module
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_prof_data              Professional info: profile_template, category and functionality     
    * @param   i_ref_row                P1_EXTERNAL_REQUEST rowtype    
    * @param   i_can_view_clin_data     Indicates if this professional can view clinical data {Y} can view clinical data {N} otherwise
    * @param   o_notes_status           Status info: status, timestamp and professional
    * @param   o_notes_status_det       Status info detail
    * @param   o_error                  An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-11-2009    
    */
    FUNCTION get_referral_generic
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_data          IN t_rec_prof_data,
        i_ref_row            IN p1_external_request%ROWTYPE,
        i_can_view_clin_data IN VARCHAR2,
        o_notes_status       OUT pk_types.cursor_type,
        o_notes_status_det   OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral id associated to given schedule id
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_schedule            Schedule Id 
    * @param   o_id_external_request    Referral Id    
    * @param   o_error                  An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author Joana Barroso
    * @version 1.0
    * @since   14-12-2009    
    */

    FUNCTION get_ref_sch_to_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral id associated to given schedule id
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_schedule            Schedule Id 
    * @param   o_id_external_request    Referral Id    
    * @param   o_num_req                Referral num req
    * @param   o_error                  An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author Joana Barroso
    * @version 1.0
    * @since   14-12-2009    
    */
    FUNCTION get_ref_sch
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_num_req             OUT p1_external_request.num_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral active schedule identifier associated to GENERIC module
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-12-2009    
    */
    FUNCTION get_ref_sch_generic
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN schedule.id_schedule%TYPE;

    /**
    * Gets referral active schedule date associated to GENERIC module
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-01-2010    
    */
    FUNCTION get_ref_sch_dt_generic
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN schedule.dt_begin_tstz%TYPE;

    /**
    * Checks if referral is associated to the schedule identifier. 
    * If it is, then return i_id_schedule, otherwise return null
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    * @param   i_id_schedule            Schedule identifier   
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-12-2009
    */
    FUNCTION check_ref_sch_circle
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN schedule.id_schedule%TYPE;

    /**
    * Gets referral external schedule identifier
    *
    * @param   i_lang                   Language identifier
    * @param   i_prof                   Professional, institution and software ids     
    * @param   i_id_ref                 Referral identifier
    *    
    * @RETURN  Referral external schedule identifier 
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-11-2010    
    */

    FUNCTION get_ref_sch_ext
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_sch  IN schedule.id_schedule%TYPE
    ) RETURN sch_api_map_ids.id_schedule_ext%TYPE;

    /**
    * Gets labels to be shown in referral detail
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional, institution and software ids     
    * @param   i_module         Referral module
    * @param   o_label_spec     Referral speciality label
    * @param   o_label_sub_spec Referral sub-speciality label (when creating the referral)
    * @param   o_label_cs       Referral clinical service label 
    * @param   o_error          An error message, set when return=false
    *    
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2012-05-25
    */
    FUNCTION get_label_specialities
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_module         IN sys_config.value%TYPE,
        o_label_spec     OUT sys_message.code_message%TYPE,
        o_label_sub_spec OUT sys_message.code_message%TYPE,
        o_label_cs       OUT sys_message.code_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_module;
/
