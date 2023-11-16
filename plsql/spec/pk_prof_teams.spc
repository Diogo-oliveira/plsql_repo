/*-- Last Change Revision: $Rev: 2028886 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prof_teams IS

    -- Created : 25-02-2009
    -- Purpose : Medical teams development

    g_error VARCHAR2(4000);
    g_available CONSTANT VARCHAR2(1) := 'Y';
    g_yes       CONSTANT VARCHAR2(1) := 'Y';
    g_no        CONSTANT VARCHAR2(1) := 'N';
    g_active    CONSTANT VARCHAR2(1) := 'A';
    g_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_integrity_type_p CONSTANT VARCHAR2(1) := 'P';
    g_integrity_type_t CONSTANT VARCHAR2(1) := 'T';

    g_bed_permanent CONSTANT bed.flg_type%TYPE := 'P';

    g_status_team_room_i CONSTANT prof_team_room.flg_status%TYPE := 'I';
    g_status_team_room_a CONSTANT prof_team_room.flg_status%TYPE := 'A';

    g_flg_leader CONSTANT prof_team_det.flg_leader%TYPE := 'Y';

    g_dpt_outp CONSTANT department.flg_type%TYPE := 'C';
    g_dpt_edis CONSTANT department.flg_type%TYPE := 'U';

    /********************************************************************************************
    * Returns the domain associated with a team status
    *
    * @param  i_lang           language id
    * @param  i_val            status value
    *                    
    * @return                  domain description
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_prof_team_domain
    (
        i_lang IN language.id_language%TYPE,
        i_val  IN prof_team.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the '(With notes)' label
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_notes          team notes
    * @param  i_notes_cancel   team cancellation notes
    *                    
    * @return                  domain description
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_notes_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_notes        IN prof_team.notes%TYPE,
        i_notes_cancel IN prof_team.notes_cancel%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Creates a team of professionals
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_team_dt_begin  date of team shift beginning,
    * @param  i_team_dt_end    date of team shift ending,
    * @param  i_notes          team notes,
    * @param  i_professional   list of allocated professionals,
    * @param  i_prof_dt_begin  date of professional shift beginning,
    * @param  i_prof_dt_end    date of professional shift ending,
    * @param  i_prof_notes     professional notes,
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION create_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_department       IN department.id_department%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_team_dt_begin    IN VARCHAR2,
        i_team_dt_end      IN VARCHAR2,
        i_notes            IN prof_team.notes%TYPE,
        i_professional     IN table_number,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        i_team_type        IN team_type.id_team_type%TYPE DEFAULT NULL,
        i_prof_team_leader IN prof_team.id_prof_team_leader%TYPE DEFAULT NULL,
        o_id_prof_team     OUT prof_team.id_prof_team%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a team of professionals
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_team_dt_begin  date of team shift beginning,
    * @param  i_team_dt_end    date of team shift ending,
    * @param  i_notes          team notes,
    * @param  i_professional   list of allocated professionals,
    * @param  i_prof_dt_begin  date of professional shift beginning,
    * @param  i_prof_dt_end    date of professional shift ending,
    * @param  i_prof_notes     professional notes,
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   25-02-2009
    **********************************************************************************************/
    FUNCTION create_prof_team_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_department       IN department.id_department%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_team_dt_begin    IN VARCHAR2,
        i_team_dt_end      IN VARCHAR2,
        i_notes            IN prof_team.notes%TYPE,
        i_professional     IN table_number,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        i_team_type        IN team_type.id_team_type%TYPE DEFAULT NULL,
        i_prof_team_leader IN prof_team.id_prof_team_leader%TYPE DEFAULT NULL,
        i_id_episode       IN episode.id_episode%TYPE,
        o_id_prof_team     OUT prof_team.id_prof_team%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the information of a team of professionals
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_prof_team      team id
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_team_dt_begin  date of team shift beginning,
    * @param  i_team_dt_end    date of team shift ending,
    * @param  i_notes          team notes,
    * @param  i_professional   list of allocated professionals,
    * @param  i_prof_dt_begin  date of professional shift beginning,
    * @param  i_prof_dt_end    date of professional shift ending,
    * @param  i_prof_notes     professional notes,
    * @param  i_team_type      id team type,
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION set_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_team        IN prof_team.id_prof_team%TYPE,
        i_department       IN department.id_department%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_team_dt_begin    IN VARCHAR2,
        i_team_dt_end      IN VARCHAR2,
        i_notes            IN prof_team.notes%TYPE,
        i_professional     IN table_number,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        i_team_type        IN team_type.id_team_type%TYPE DEFAULT NULL,
        i_prof_team_leader IN prof_team.id_prof_team_leader%TYPE DEFAULT NULL,
        
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels a team of professionals
    *
    * @param  i_lang             language id
    * @param  i_prof             professional, software and institution ids
    * @param  i_prof_team        team id
    * @param  i_id_cancel_reason Cancellation reason ID
    * @param  i_notes            Cancel Notes
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION cancel_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_team        IN prof_team.id_prof_team%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the active teams for the next 24 hours
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_active_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the active teams for the next 24 hours (for a specific professional)
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_my_active_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all the teams for for a specific institution
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_archive_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the team responsible for the episode
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID associated with the episode
    * @param i_epis_software   software ID
    * @param i_prof_doc        doctor responsible for the episode
    * @param i_prof_nurse      nurse responsible for the episode
    *                    
    * @return                  current team responsible for the episode
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_prof_current_team
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_department    IN department.id_department%TYPE,
        i_epis_software IN software.id_software%TYPE,
        i_prof_doc      IN professional.id_professional%TYPE,
        i_prof_nurse    IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if the professional has permission to team creation
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_flg_permission  Permission to create teams: Y - yes, N - No
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   02-03-2009
    **********************************************************************************************/
    FUNCTION get_team_create_permission
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_flg_permission OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the detail of a specific team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_team       team id
    * @param o_team_reg        List of team records
    * @param o_team_val        List of team values
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   02-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_team_reg  OUT pk_types.cursor_type,
        o_team_val  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the professional list for a specific department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param o_prof            list of professionals
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   03-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_create_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the group of professionals of a team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param i_prof_team       team ID
    * @param o_prof            list of professionals
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   04-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_edit_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_prof_team  IN prof_team.id_prof_team%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the current dept is the default one
    *
    * @param i_prof            professional, software and institution ids
    * @param i_dept            department list
    *                    
    * @return                  Default dept: Y - yes; N - No
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   02-11-2009
    **********************************************************************************************/
    FUNCTION get_default_dept
    (
        i_prof IN profissional,
        i_dept IN dept.id_dept%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the list of departments
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param o_dept            department list
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_dept_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dept  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of team departments
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param o_department      department list
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all teams inside a given department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_department_teams
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_teams      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all rooms inside a given department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param i_prof_team       team ID
    *
    * @param o_rooms           List of rooms
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_prof_team  IN prof_team.id_prof_team%TYPE,
        o_rooms      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all rooms inside a given department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param i_prof_team       team ID
    *
    * @param o_rooms           List of rooms
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_bed_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_room           IN room.id_room%TYPE,
        i_prof_team_room IN prof_team_room.id_prof_team_room%TYPE,
        o_beds           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Allocates rooms and beds to a team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_team       list of teams
    * @param i_rooms           list of rooms
    * @param i_room_changes    indicates if a room has bed changes    
    * @param i_beds            list of beds
    * 
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION create_prof_rooms
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_team    IN table_number,
        i_rooms        IN table_table_number,
        i_room_changes IN table_table_varchar,
        i_beds         IN table_table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all rooms associated with a team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_team       team ID
    *                    
    * @return                  rooms description
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_prof_rooms
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the list of teams that were assigned to an episode
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    * @param i_episode         episode ID
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_team
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_teams   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * list of team professionals. This is already present in function get_prof_team_det but it also
    * does other stuff. Just needed a simple list of a team professional ids
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    * @param i_id_prof_team    team ID
    *
    * @param o_profs           output list
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  Telmo
    * @version                 2.5.0.4 
    * @since                   19-06-2009
    **********************************************************************************************/
    FUNCTION get_prof_team_profs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_team IN prof_team.id_prof_team%TYPE,
        o_profs        OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Gets the department type
    *
    * @param i_flg_type        department type
    *                    
    * @return                  Department type: C - Outpatient, U - EDIS
    *
    * @author                  José Silva
    * @version                 1.0
    * @since                   02-11-2009
    **********************************************************************************************/
    FUNCTION get_department_type(i_flg_type IN department.flg_type%TYPE) RETURN VARCHAR2;

    FUNCTION get_dept_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dept       IN dept.id_dept%TYPE,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * list of type of teams. 
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    *
    * @param o_team_type       List of type of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  Rita Lopes
    * @version                 2.5.0.4 
    * @since                   03-07-2009
    **********************************************************************************************/
    FUNCTION get_team_types
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_team_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Gets the professional leader. 
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    * @param id_prof_team      id team    
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  Rita Lopes
    * @version                 2.5.0.4 
    * @since                   05-07-2009
    **********************************************************************************************/
    FUNCTION get_professional_leader
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        id_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_team_categories
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_team_professionals
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_professional        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN t_coll_team_prof_det;

    FUNCTION get_id_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    --this function is used on reports
    FUNCTION get_prof_team_det_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_id_req      IN table_number,
        i_flg_report      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_report_hist IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_team_val        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_team_hist IN prof_team_det_hist.id_prof_team_hist%TYPE
    ) RETURN t_coll_team_prof_det;

    FUNCTION get_id_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_tbl_inst     IN table_number,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_inst  IN table_number,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN t_coll_team_prof_det;

    --get category of professional - hhc
    FUNCTION get_hhc_prof_category
    (
        i_lang            IN language.id_language%TYPE,
        i_id_profissional IN prof_profile_template.id_professional%TYPE,
        i_id_institution  IN prof_profile_template.id_institution%TYPE
    ) RETURN sys_message.desc_message%TYPE;
	
    FUNCTION set_team_end_of_activity
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_hhc_req IN NUMBER,
        i_dt_end  IN prof_team.dt_end_tstz%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
	
END pk_prof_teams;
/
