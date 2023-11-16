/*-- Last Change Revision: $Rev: 2028912 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_orig_reg AS

    /**
    * Lists all tasks related to p1 by doctor
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ext_req        Referral identifier
    * @param   o_tasks          Array of tasks for schedule
    * @param   o_info           Array of tasks for appointment
    * @param   o_notes          Notes related to each task
    * @param   o_editable       Check if referral is editable     
    * @param   o_error          An error message, set when return=false
    *
    * @value   o_editable       {*} 'Y' - referral is editable {*} 'N' - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION get_tasks_done
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN profissional,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        o_tasks    OUT pk_types.cursor_type,
        o_info     OUT pk_types.cursor_type,
        o_notes    OUT pk_types.cursor_type,
        o_editable OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update status of tasks for the request (replaces UPD_TASKS_DONE)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ext_req        Referral identifier
    * @param   I_ID_TASKS array of tasks ids
    * @param   I_FLG_STATUS_INI array tasks initial status
    * @param   I_FLG_STATUS_FIN array tasks final status
    * @param   i_notes notes     
    * @param   i_date           Operation date
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION update_tasks_done
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_tasks       IN table_number,
        i_flg_status_ini IN table_varchar,
        i_flg_status_fin IN table_varchar,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_orig_reg;
/
