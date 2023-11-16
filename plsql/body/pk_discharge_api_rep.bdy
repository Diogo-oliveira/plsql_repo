/*-- Last Change Revision: $Rev: 2026972 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_discharge_api_rep IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;

    -- Function and procedure implementations

    /********************************************************************************************
    * Get the administrative discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_admin_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_invalid_arguments EXCEPTION;
    BEGIN
    
        g_error := 'ANALYSING SCOPE - ID_EPISODE';
        IF i_episode IS NULL
        THEN
            RAISE l_invalid_arguments;
        END IF;
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --
        RETURN pk_discharge_core.get_admin_discharge(i_lang            => i_lang,
                                                     i_episode         => i_episode,
                                                     i_prof            => i_prof,
                                                     i_fltr_start_date => l_fltr_start_date,
                                                     i_fltr_end_date   => l_fltr_end_date,
                                                     o_disch           => o_disch,
                                                     o_error           => o_error);
        --
    EXCEPTION
        WHEN l_invalid_arguments THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'INVALID ARGUMENTS i_lang: ' || i_lang || ' i_episode: ' || i_episode ||
                                              ' i_prof.id: ' || i_prof.id || ' i_prof.software: ' || i_prof.software ||
                                              ' i_prof.institutiton: ' || i_prof.institution || ' i_fltr_start_date: ' ||
                                              i_fltr_start_date || ' i_fltr_end_date: ' || i_fltr_end_date,
                                              g_owner,
                                              g_package,
                                              'GET_ADMIN_DISCHARGE.INVALID_ARGUMENTS',
                                              o_error);
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADMIN_DISCHARGE',
                                              o_error);
            pk_types.open_my_cursor(o_disch);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_admin_discharge;

    /**********************************************************************************************
    * Get all discharge notes (medical or administrative).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param i_flg_type           (A) Administrative or (D) Medical discharge notes
    * @param o_notes              The notes
    * @param o_error              Error message
    *
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    **********************************************************************************************/
    FUNCTION get_disch_prof_notes
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_discharge    IN discharge.id_discharge%TYPE,
        i_flg_type        IN VARCHAR2,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_notes           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_prof_notes(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_episode      => i_id_episode,
                                                      i_id_discharge    => i_id_discharge,
                                                      i_flg_type        => i_flg_type,
                                                      i_fltr_start_date => l_fltr_start_date,
                                                      i_fltr_end_date   => l_fltr_end_date,
                                                      o_notes           => o_notes,
                                                      o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_PROF_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_prof_notes;

    /********************************************************************************************
    * Retrieves a discharge record history of operations, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_hist_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_disch           IN discharge.id_discharge%TYPE,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_hist            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_hist_amb(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_disch           => i_disch,
                                                    i_fltr_start_date => l_fltr_start_date,
                                                    i_fltr_end_date   => l_fltr_end_date,
                                                    o_hist            => o_hist,
                                                    o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_HIST_AMB',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_disch_hist_amb;

    /********************************************************************************************
    * Retrieve discharges, in ambulatory products. Adapted from GET_DISCHARGE.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_discharges_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_discharges_amb(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_episode         => i_episode,
                                                    i_fltr_start_date => l_fltr_start_date,
                                                    i_fltr_end_date   => l_fltr_end_date,
                                                    o_disch           => o_disch,
                                                    o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGES_AMB',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_disch);
            RETURN FALSE;
    END get_discharges_amb;

    /********************************************************************************************
    * Returns discharge detail (admission)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_admit
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail_admit(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_discharge    => i_id_discharge,
                                                        i_fltr_start_date => l_fltr_start_date,
                                                        i_fltr_end_date   => l_fltr_end_date,
                                                        o_sql             => o_sql,
                                                        o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_ADMIT',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_admit;

    /********************************************************************************************
    * Returns discharge detail (transfer)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_transf
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail_transf(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_discharge    => i_id_discharge,
                                                         i_fltr_start_date => l_fltr_start_date,
                                                         i_fltr_end_date   => l_fltr_end_date,
                                                         o_sql             => o_sql,
                                                         o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_TRANSF',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_transf;

    /********************************************************************************************
    * Returns discharge detail (expired)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_expir
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail_expir(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_discharge    => i_id_discharge,
                                                        i_fltr_start_date => l_fltr_start_date,
                                                        i_fltr_end_date   => l_fltr_end_date,
                                                        o_sql             => o_sql,
                                                        o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_EXPIR',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_expir;

    /********************************************************************************************
    * Returns discharge detail (against medical advice)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_ama
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail_ama(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_discharge    => i_id_discharge,
                                                      i_fltr_start_date => l_fltr_start_date,
                                                      i_fltr_end_date   => l_fltr_end_date,
                                                      o_sql             => o_sql,
                                                      o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_AMA',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_ama;
    --
    /**********************************************************************************************
    * Devolve o detalhe da alta
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    **********************************************************************************************/
    FUNCTION get_disch_detail_disch
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail_disch(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_discharge    => i_id_discharge,
                                                        i_fltr_start_date => l_fltr_start_date,
                                                        i_fltr_end_date   => l_fltr_end_date,
                                                        o_sql             => o_sql,
                                                        o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_DISCH',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_disch;

    /********************************************************************************************
    * Returns discharge detail (left without being seen)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_lwbs
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail_lwbs(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_discharge    => i_id_discharge,
                                                       i_fltr_start_date => l_fltr_start_date,
                                                       i_fltr_end_date   => l_fltr_end_date,
                                                       o_sql             => o_sql,
                                                       o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL_LWBS',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail_lwbs;
    -- 
    /********************************************************************************************
    * Returns discharge detail
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_invalid_arguments EXCEPTION;
    BEGIN
        g_error := 'ANALYSING SCOPE - ID EPISODE';
        IF i_id_discharge IS NULL
        THEN
            RAISE l_invalid_arguments;
        END IF;
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN pk_discharge_core.get_disch_detail(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_discharge    => i_id_discharge,
                                                  i_fltr_start_date => l_fltr_start_date,
                                                  i_fltr_end_date   => l_fltr_end_date,
                                                  o_sql             => o_sql,
                                                  o_error           => o_error);
    EXCEPTION
        WHEN l_invalid_arguments THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'INVALID ARGUMENTS i_lang: ' || i_lang || ' i_id_discharge: ' ||
                                              i_id_discharge || ' i_prof.id: ' || i_prof.id || ' i_prof.software: ' ||
                                              i_prof.software || ' i_prof.institutiton: ' || i_prof.institution ||
                                              ' i_fltr_start_date: ' || i_fltr_start_date || ' i_fltr_end_date: ' ||
                                              i_fltr_end_date,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL.INVALID_ARGUMENTS',
                                              o_error);
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCH_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_disch_detail;

    /********************************************************************************************
    * Get the episode discharge records
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    * @param   i_category_type       Professional category/discharge type
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_category_type   IN category.flg_type%TYPE,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_invalid_arguments EXCEPTION;
    
    BEGIN
    
        g_error := 'ANALYSING SCOPE';
        IF i_episode IS NULL
        THEN
            RAISE l_invalid_arguments;
        END IF;
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --
        RETURN pk_discharge_core.get_discharge(i_lang            => i_lang,
                                               i_episode         => i_episode,
                                               i_prof            => i_prof,
                                               i_category_type   => i_category_type,
                                               i_fltr_start_date => l_fltr_start_date,
                                               i_fltr_end_date   => l_fltr_end_date,
                                               o_disch           => o_disch,
                                               o_error           => o_error);
        --
    EXCEPTION
        WHEN l_invalid_arguments THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'INVALID ARGUMENTS i_lang: ' || i_lang || ' i_episode: ' || i_episode ||
                                              ' i_prof.id: ' || i_prof.id || ' i_prof.software: ' || i_prof.software ||
                                              ' i_prof.institutiton: ' || i_prof.institution || ' i_category_type: ' ||
                                              i_category_type || ' i_fltr_start_date: ' || i_fltr_start_date ||
                                              ' i_fltr_end_date: ' || i_fltr_end_date,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGE.INVALID_ARGUMENTS',
                                              o_error);
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGE',
                                              o_error);
            pk_types.open_my_cursor(o_disch);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_discharge;

    /********************************************************************************************
    * Get the detail of a discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_disch               discharge ID
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge record
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_discharge_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_disch           IN discharge.id_discharge%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fltr_start_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_fltr_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        IF i_fltr_start_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_start_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_fltr_end_date IS NOT NULL
        THEN
            g_error := 'CALL get_string_tstz (i_fltr_end_date_str)';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_fltr_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_fltr_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --
        RETURN pk_discharge_core.get_discharge_detail(i_lang            => i_lang,
                                                      i_disch           => i_disch,
                                                      i_prof            => i_prof,
                                                      i_fltr_start_date => l_fltr_start_date,
                                                      i_fltr_end_date   => l_fltr_end_date,
                                                      o_disch           => o_disch,
                                                      o_error           => o_error);
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DISCHARGE_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_disch);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_discharge_detail;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_discharge_api_rep;
/
