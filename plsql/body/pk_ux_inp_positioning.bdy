/*-- Last Change Revision: $Rev: 2050151 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-14 15:46:21 +0000 (seg, 14 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_inp_positioning IS

    internal_error_exception EXCEPTION;

    -- Author  : GUSTAVO.SERRANO
    -- Created : 13-11-2009 12:23:20
    -- Purpose : API functions for User Interface module

    FUNCTION create_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_id_epis_positioning  IN epis_positioning.id_epis_positioning%TYPE DEFAULT NULL,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_origin               IN VARCHAR2,
        i_id_episode_sr        IN episode.id_episode%TYPE DEFAULT NULL,
        i_filter_tab           IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_inp_positioning.create_epis_positioning(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_episode              => i_episode,
                                                          i_id_rot_interv        => i_id_rot_interv,
                                                          i_id_epis_positioning  => i_id_epis_positioning,
                                                          i_tbl_ds_internal_name => i_tbl_ds_internal_name,
                                                          i_tbl_val              => i_tbl_val,
                                                          i_tbl_real_val         => i_tbl_real_val,
                                                          i_origin               => i_origin,
                                                          i_id_episode_sr        => i_id_episode_sr,
                                                          i_filter_tab           => i_filter_tab,
                                                          o_error                => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPIS_POSITIONING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPIS_POSITIONING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_epis_positioning;

    FUNCTION set_epis_pos_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status       IN epis_positioning.flg_status%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_error VARCHAR2(4000) := NULL;
    BEGIN
        g_error := 'CALL pk_inp_positioning.set_epis_pos_status';
        IF NOT pk_inp_positioning.set_epis_pos_status(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_epis_pos         => i_epis_pos,
                                                      i_flg_status       => i_flg_status,
                                                      i_notes            => i_notes,
                                                      i_id_cancel_reason => i_id_cancel_reason,
                                                      o_msg_error        => l_msg_error,
                                                      o_error            => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_POS_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_POS_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_pos_status;

    FUNCTION get_epis_positioning_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis_pos   IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos_d OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_inp_positioning.get_epis_positioning_det';
        IF NOT pk_inp_positioning.get_epis_positioning_det(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_epis_pos   => i_epis_pos,
                                                           o_epis_pos_d => o_epis_pos_d,
                                                           o_error      => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSITIONING_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSITIONING_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_positioning_det;

    FUNCTION get_epis_posit_plan_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pos      IN epis_positioning.id_epis_positioning%TYPE,
        i_epis_pos_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        o_epis_pos_pdet OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_inp_positioning.get_epis_posit_plan_det';
        IF NOT pk_inp_positioning.get_epis_posit_plan_det(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_epis_pos      => i_epis_pos,
                                                          i_epis_pos_plan => i_epis_pos_plan,
                                                          o_epis_pos_pdet => o_epis_pos_pdet,
                                                          o_error         => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_PLAN_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_PLAN_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_posit_plan_det;

    FUNCTION set_epis_positioning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_pos    IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str IN VARCHAR2,
        i_notes       IN epis_positioning.notes%TYPE,
        i_rot_interv  IN epis_positioning.rot_interval%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_inp_positioning.set_epis_positioning';
        IF NOT pk_inp_positioning.set_epis_positioning(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_epis_pos    => i_epis_pos,
                                                       i_dt_exec_str => i_dt_exec_str,
                                                       i_notes       => i_notes,
                                                       i_rot_interv  => i_rot_interv,
                                                       o_error       => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_POSITIONING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_POSITIONING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_positioning;

    FUNCTION set_epis_pos_execution
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_pos     IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str  IN VARCHAR2,
        i_dt_next_exec IN VARCHAR2 DEFAULT NULL,
        i_notes        IN epis_positioning.notes%TYPE DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_inp_positioning.set_epis_pos_execution';
        IF NOT pk_inp_positioning.set_epis_positioning(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_epis_pos     => i_epis_pos,
                                                       i_dt_exec_str  => i_dt_exec_str,
                                                       i_notes        => i_notes,
                                                       i_dt_next_exec => i_dt_next_exec,
                                                       o_error        => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_POS_EXECUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_POS_EXECUTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_pos_execution;

    FUNCTION get_epis_positioning
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_epis_pos OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_inp_positioning.get_epis_positioning';
        IF NOT pk_inp_positioning.get_epis_positioning(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_episode  => i_episode,
                                                       o_epis_pos => o_epis_pos,
                                                       o_error    => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSITIONING',
                                              o_error);
            pk_types.open_my_cursor(o_epis_pos);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSITIONING',
                                              o_error);
            pk_types.open_my_cursor(o_epis_pos);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_positioning;

    FUNCTION get_epis_posit_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pos      IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos_plan OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_inp_positioning.get_epis_posit_plan';
        IF NOT pk_inp_positioning.get_epis_posit_plan(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_epis_pos      => i_epis_pos,
                                                      o_epis_pos_plan => o_epis_pos_plan,
                                                      o_error         => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_posit_plan;

    /********************************************************************************************
    * set task parameters changed in task edit screens (critical for draft editing)
    *
    * NOTE: this function can be replaced by several functions that update the required values, 
    *       according to current task workflow edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       ...                       specific to each target area
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION edit_epis_positioning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_posit            IN table_number,
        i_rot_interv       IN rotation_interval.interval%TYPE,
        i_id_rot_interv    IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage      IN epis_positioning.flg_massage%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_pos_type         IN positioning_type.id_positioning_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Call to PK_INP_POSITIONING.edit_epis_positioning for id_epis_pos: ' || i_epis_positioning;
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.edit_epis_positioning for id_epis_pos: ' ||
                                                 i_epis_positioning,
                              object_name     => 'PK_UX_INP_POSITIONING',
                              sub_object_name => 'EDIT_EPIS_POSITIONING');
    
        IF NOT pk_inp_positioning.edit_epis_positioning(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_episode          => i_episode,
                                                        i_epis_positioning => i_epis_positioning,
                                                        i_posit            => i_posit,
                                                        i_rot_interv       => i_rot_interv,
                                                        i_id_rot_interv    => i_id_rot_interv,
                                                        i_flg_massage      => i_flg_massage,
                                                        i_notes            => i_notes,
                                                        i_pos_type         => i_pos_type,
                                                        i_flg_type         => pk_inp_positioning.g_epis_posit_d,
                                                        o_error            => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_EPIS_POSITIONING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_EPIS_POSITIONING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END edit_epis_positioning;

    /********************************************************************************************
    * create draft task 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * 
    * @param       param1                    param1
    * @param       param2                    param2
    * @param       param3                    param3
    * ...          ...                       ...
    * @param       paramN                    paramN
    * 
    * @param       o_draft                   list of created drafts
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION create_draft
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_posit         IN table_number,
        i_rot_interv    IN rotation_interval.interval%TYPE,
        i_id_rot_interv IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage   IN epis_positioning.flg_massage%TYPE,
        i_notes         IN epis_positioning.notes%TYPE,
        i_pos_type      IN positioning_type.id_positioning_type%TYPE,
        o_draft         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Call to PK_INP_POSITIONING.CREATE_EPIS_POSITIONING for id_episode: ' || i_episode ||
                   ' with rot_interval: ' || i_rot_interv;
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.CREATE_EPIS_POSITIONING for id_episode: ' ||
                                                 i_episode || ' with rot_interval: ' || i_rot_interv,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'CREATE_EPIS_POSITIONING');
        IF NOT pk_inp_positioning.create_epis_positioning(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_episode       => i_episode,
                                                          i_posit         => i_posit,
                                                          i_rot_interv    => i_rot_interv,
                                                          i_id_rot_interv => i_id_rot_interv,
                                                          i_flg_massage   => i_flg_massage,
                                                          i_notes         => i_notes,
                                                          i_pos_type      => i_pos_type,
                                                          i_flg_type      => pk_inp_positioning.g_epis_posit_d,
                                                          o_rows          => o_draft,
                                                          o_error         => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DRAFT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DRAFT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_draft;

    /********************************************************************************************
    * Get the positioning plan detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_positioning_plan  Epis_positioning_plan Id
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.1
    * @since                          13-Apr-2011
    **********************************************************************************************/
    FUNCTION get_epis_positioning_plan_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        i_flg_screen               IN VARCHAR2,
        o_hist                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_INP_POSITIONING.GET_EPIS_POSITIONING_PLAN_HIST FOR ID_EPIS_POSITIONING_PLAN : ' ||
                   i_id_epis_positioning_plan;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_inp_positioning.get_epis_positioning_plan_hist(i_lang                     => i_lang,
                                                                 i_prof                     => i_prof,
                                                                 i_id_episode               => i_id_episode,
                                                                 i_id_epis_positioning_plan => i_id_epis_positioning_plan,
                                                                 i_flg_screen               => i_flg_screen,
                                                                 o_hist                     => o_hist,
                                                                 o_error                    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_epis_positioning_plan_hist;

    /********************************************************************************************
    * Gets the positionings list for reports with timeframe and scope
    *
    * @param   I_LANG                      Language associated to the professional executing the request
    * @param   I_PROF                      Professional Identification
    * @param   I_SCOPE                     Scope ID
    * @param   I_FLG_SCOPE                 Scope type
    * @param   I_START_DATE                Start date for temporal filtering
    * @param   I_END_DATE                  End date for temporal filtering
    * @param   I_CANCELLED                 Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param   I_CRIT_TYPE                 Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param   I_FLG_REPORT                Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param   O_POS                       Positioning list
    * @param   O_POS_EXEC                  Executions for Positioning list
    * @param   O_ERROR                     Error message
    *
    * @value   I_SCOPE                     {*} 'E' Episode ID {*} 'V' Visit ID {*} 'P' Patient ID
    * @value   I_FLG_SCOPE                 {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value   I_CANCELLED                 {*} 'Y' Yes {*} 'N' No
    * @value   I_CRIT_TYPE                 {*} 'A' All {*} 'E' Executions {*} 'R' requests
    * @value   I_FLG_REPORT                {*} 'Y' Yes {*} 'N' No
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              António Neto
    * @version                             2.5.1.8.1
    * @since                               29-Sep-2011
    **********************************************************************************************/
    FUNCTION get_positioning_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        o_pos        OUT NOCOPY pk_types.cursor_type,
        o_pos_exec   OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_get_positioning_rep EXCEPTION;
    
    BEGIN
        g_error := 'CALL PK_PBL_INP_POSITIONING.GET_POSITIONING_REP';
        IF NOT pk_pbl_inp_positioning.get_positioning_rep(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_scope      => i_scope,
                                                          i_flg_scope  => i_flg_scope,
                                                          i_start_date => i_start_date,
                                                          i_end_date   => i_end_date,
                                                          i_cancelled  => i_cancelled,
                                                          i_crit_type  => i_crit_type,
                                                          i_flg_report => i_flg_report,
                                                          o_pos        => o_pos,
                                                          o_pos_exec   => o_pos_exec,
                                                          o_error      => o_error)
        THEN
            RAISE e_get_positioning_rep;
        END IF;
    
        --                       
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POSITIONING_REP',
                                              o_error);
        
            RETURN FALSE;
    END get_positioning_rep;

    FUNCTION get_epis_posit_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN action.from_state%TYPE,
        id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_ACTION_LIST';
        IF NOT pk_inp_positioning.get_epis_posit_actions(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_subject           => i_subject,
                                                         i_from_state        => i_from_state,
                                                         id_epis_positioning => id_epis_positioning,
                                                         o_actions           => o_actions,
                                                         o_error             => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_epis_posit_actions;

    FUNCTION get_epis_positioning_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_EPIS_POSITIONING_DETAIL';
        l_id_episode    episode.id_episode%TYPE;
    
    BEGIN
    
        SELECT ep.id_episode
          INTO l_id_episode
          FROM epis_positioning ep
         WHERE ep.id_epis_positioning = i_id_epis_positioning;
    
        g_error := 'CALL PK_INP_POSITIONING.GET_EPIS_POSITIONING_DETAIL: ' || i_id_epis_positioning;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_inp_positioning.get_epis_positioning_detail(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_episode          => l_id_episode,
                                                              i_id_epis_positioning => i_id_epis_positioning,
                                                              o_hist                => o_hist,
                                                              o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_positioning_detail;

    FUNCTION get_epis_positioning_detail_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(50 CHAR) := 'GET_EPIS_POSITIONING_DETAIL_HIST';
        l_id_episode    episode.id_episode%TYPE;
    
    BEGIN
    
        SELECT ep.id_episode
          INTO l_id_episode
          FROM epis_positioning ep
         WHERE ep.id_epis_positioning = i_id_epis_positioning;
    
        g_error := 'CALL PK_INP_POSITIONING.GET_EPIS_POSITIONING_DETAIL: ' || i_id_epis_positioning;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_inp_positioning.get_epis_positioning_detail_hist(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => l_id_episode,
                                                                   i_id_epis_positioning => i_id_epis_positioning,
                                                                   o_hist                => o_hist,
                                                                   o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_positioning_detail_hist;

    FUNCTION get_epis_posit_plan_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        i_flg_screen               IN VARCHAR2,
        o_hist                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_EPIS_POSIT_PLAN_DETAIL';
        l_id_episode    episode.id_episode%TYPE;
    
    BEGIN
    
        SELECT ep.id_episode
          INTO l_id_episode
          FROM epis_positioning_plan epp
          JOIN epis_positioning_det epd
            ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
          JOIN epis_positioning ep
            ON ep.id_epis_positioning = epd.id_epis_positioning
         WHERE epp.id_epis_positioning_plan = i_id_epis_positioning_plan;
    
        g_error := 'CALL PK_INP_POSITIONING.GET_EPIS_POSIT_PLAN_DETAIL: ' || i_id_epis_positioning_plan;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_inp_positioning.get_epis_posit_plan_detail(i_lang                     => i_lang,
                                                             i_prof                     => i_prof,
                                                             i_id_episode               => l_id_episode,
                                                             i_id_epis_positioning_plan => i_id_epis_positioning_plan,
                                                             i_flg_screen               => i_flg_screen,
                                                             o_hist                     => o_hist,
                                                             o_error                    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_posit_plan_detail;

    /********************************************************************************************
    * Check if the positioning record will be cancelled or interrupted
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_episode              Episode ID
    * 
    * @param       o_action                  'C' - to be cancelled; 'I' - to be interrupted
    *
    * @author                                Filipe Silva                       
    * @version                               2.6.1                                    
    * @since                                 2011/04/06       
    ********************************************************************************************/
    FUNCTION check_cancel_interrupt_posit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_positioning.id_episode%TYPE,
        o_action     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'CHECK_CANCEL_INTERRUPT_POSIT';
    
    BEGIN
    
        g_error := 'CALL PK_INP_POSITIONING.CHECK_CANCEL_INTERRUPT_POSIT FOR ID_EPISODE: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_positioning.check_cancel_interrupt_posit(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_episode => i_id_episode,
                                                               o_action     => o_action,
                                                               o_error      => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END check_cancel_interrupt_posit;

    FUNCTION get_positioning_rel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_posit_type IN positioning_instit_soft.posit_type%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_POSITIONING_REL';
    
    BEGIN
    
        g_error := 'CALL PK_INP_POSITIONING.GET_POSITIONING_REL';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_inp_positioning.get_positioning_rel(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_posit_type => i_posit_type,
                                                      o_data       => o_data,
                                                      o_error      => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_positioning_rel;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ux_inp_positioning;
/
