/*-- Last Change Revision: $Rev: 2054006 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2023-01-03 11:31:19 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_bmng_core IS

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointment in the given date
    * - i_date is null and i_id_bed is null -> returns all the future bed appointments
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_bed                        Bed identiifcation
    * @param o_next_sch_dt                   Next schedule date
    * @param o_id_patient                    Patient id of the next schedule    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Ricardo Almeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_conflict_sch_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_bed  IN bed.id_bed%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_err t_error_out;
        l_res VARCHAR2(1);
    
    BEGIN
        g_error := 'START FUNCTION With i_id_bed=' || i_id_bed;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_schedule_inp.get_conflict_sch_date(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_bed       => i_id_bed,
                                                     i_epis         => i_episode,
                                                     i_date         => i_date,
                                                     o_has_conflict => l_res,
                                                     o_error        => l_err)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'OPEN CURSOR O_DATA';
        pk_alertlog.log_debug(g_error);
    
        RETURN l_res;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONFLICT_SCH_DATE',
                                              l_err);
            RETURN NULL;
    END get_conflict_sch_date;

    /********************************************************************************************************************************************
    * GET_REASONS              Function that returns all available reasons for a specific action that can be done in a bed/room/ward
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_SUBJECT        SUBJECT string that identifies the reasons for execute a determined action that should be returned to FLASH
    * @param  O_REASONS        information of available reasons for current institution and action (identified by SUBJECT string)
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @value  I_SUBJECT        {*} 'BLOCK_ACTION' {*} 'UPDATE_NCH_ACTION' {*} 'BLOCK_BED_ACTION' {*} 'RESERVE_BED_ACTION'
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   2009/07/17
    *
    *******************************************************************************************************************************************/
    FUNCTION get_reasons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN bmng_reason_type.subject%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_BED_ACTION_REASONS WITH I_SUBJECT ' || i_subject;
        pk_alertlog.log_debug(g_error);
        OPEN o_reasons FOR
            SELECT brt.id_bmng_reason_type id_reason_type,
                   br.id_bmng_reason id_reason,
                   pk_translation.get_translation(i_lang, br.code_bmng_reason) desc_reason,
                   br.flg_realocate_patient flg_realocate_pat,
                   br.rank
              FROM bmng_reason_type brt
             INNER JOIN bmng_reason br
                ON br.id_bmng_reason_type = brt.id_bmng_reason_type
             WHERE brt.subject = i_subject
               AND br.flg_available = pk_alert_constant.g_yes
               AND br.id_institution IN (0, i_prof.institution)
             ORDER BY rank ASC, desc_reason ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REASONS',
                                              o_error);
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END get_reasons;

    /********************************************************************************************************************************************
    * GET_LAST_ACTION_START_DATE        Function that returns start date of the active bed without Edits actions
    *
    * @param  I_ID_BED                  Bed identifier
    *
    * @return                           Returns the start date of the active bed without Edits actions
    *
    * @author                           António Neto
    * @version                          2.6.0.5.1.4
    * @since                            01-Feb-2011
    *******************************************************************************************************************************************/
    FUNCTION get_last_action_start_date(i_id_bed IN bed.id_bed%TYPE) RETURN bmng_action.dt_begin_action%TYPE IS
        l_dt_begin_action bmng_action.dt_begin_action%TYPE;
    BEGIN
        g_error := 'GET THE ACTION BEGIN DATE FOR BED: ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT MAX(ba.dt_begin_action)
              INTO l_dt_begin_action
              FROM bmng_action ba
             WHERE ba.flg_action IN (pk_bmng_constant.g_bmng_flg_origin_ux_b,
                                     pk_bmng_constant.g_bmng_flg_origin_ux_p,
                                     pk_bmng_constant.g_bmng_flg_origin_ux_t)
               AND ba.id_bed IS NOT NULL
               AND ba.id_bed = i_id_bed;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'THERE ARE NOT ACTIVE BMNG_ACTION START DATE ASSOCIATED WITH ID_BED ' || i_id_bed;
                pk_alertlog.log_debug(g_error);
        END;
    
        RETURN l_dt_begin_action;
    END get_last_action_start_date;

    /********************************************************************************************************************************************
    * GET_BMNG_ACTION_DT                Function that returns start and end date of the active bed action
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED                  Bed identifier
    * @param  O_BMNG_ACTION_START_DATE  Bed management action start date
    * @param  O_BMNG_ACTION_END_DATE    Bed management action end date
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author                           Luís Maia
    * @version                          2.6.0.3
    * @since                            26-Oct-2010
    *******************************************************************************************************************************************/
    FUNCTION get_bmng_action_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_bed                 IN bed.id_bed%TYPE,
        o_bmng_action_start_date OUT bmng_action.dt_begin_action%TYPE,
        o_bmng_action_end_date   OUT bmng_action.dt_begin_action%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'GET_BMNG_ACTION_DT';
        l_flg_status     bed.flg_status%TYPE;
        l_internal_error EXCEPTION;
    BEGIN
    
        --If Bed is free doesn't return dates for the bed
        g_error := 'GET BED STATUS:' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT b.flg_status
              INTO l_flg_status
              FROM bed b
             WHERE b.id_bed = i_id_bed;
        
            IF l_flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
            THEN
                RETURN TRUE;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'THERE IS NO BED ASSOCIATED WITH ID_BED ' || i_id_bed;
                pk_alertlog.log_debug(g_error);
                RAISE l_internal_error;
        END;
    
        g_error := 'GET THE ACTION BEGIN AND END DATE FOR BED:' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        BEGIN
            --return the end date for the active action status
            SELECT ba.dt_end_action
              INTO o_bmng_action_end_date
              FROM bmng_action ba
             WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND ba.id_bed IS NOT NULL
               AND ba.id_bed = i_id_bed;
        
            IF o_bmng_action_end_date IS NULL
            THEN
                BEGIN
                    SELECT z.dt_end_action
                      INTO o_bmng_action_end_date
                      FROM (SELECT *
                              FROM bmng_action ba
                             WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_o
                               AND ba.id_bed IS NOT NULL
                               AND ba.id_bed = i_id_bed
                               AND ba.dt_end_action IS NOT NULL
                             ORDER BY ba.dt_begin_action DESC) z
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        o_bmng_action_end_date := NULL;
                END;
            END IF;
        
            --return the start date for the last action in status: Block bed, Allocate patient to temporary bed or Allocate patient to permanent bed
            o_bmng_action_start_date := get_last_action_start_date(i_id_bed => i_id_bed);
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'THERE ARE NOT ACTIVE BMNG_ACTION ASSOCIATED WITH ID_BED ' || i_id_bed;
                pk_alertlog.log_debug(g_error);
                RAISE l_internal_error;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bmng_action_dt;

    /********************************************************************************************************************************************
    * GET_BED_STATUS           Function that returns a specific bed status
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED         Bed identifier
    * @param  O_BED_FLG_STATUS Current bed status
    * @param  O_BED_FLG_STATUS Current bed type
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.7
    * @since   2009/10/02
    *
    *******************************************************************************************************************************************/
    FUNCTION get_bed_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_bed         IN bed.id_bed%TYPE,
        o_bed_flg_status OUT bed.flg_status%TYPE,
        o_bed_flg_type   OUT bed.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_BED_STATUS WITH ID_BED ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT b.flg_status, b.flg_type
              INTO o_bed_flg_status, o_bed_flg_type
              FROM bed b
             WHERE b.id_bed = i_id_bed
               AND b.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
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
                                              'GET_BED_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_bed_status;

    /********************************************************************************************************************************************
    * SET_BED                  Function that update an bed information if that bed exists, otherwise create one new temporary bed
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED         Bed identifier that should be updated or created in this function
    * @param  I_FLG_TYPE       FLG_TYPE for this bed
    * @param  I_FLG_STATUS     FLG_STATUS for this bed
    * @param  I_FLG_AVAIL      FLG_AVAILABILITY for this bed
    * @param  I_DESC_BED       Description associated with this bed
    * @param  I_ID_BED_TYPE    Bed type identifier of this bed
    * @param  I_ID_ROOM        Room identifier where this bed is physically
    * @param  I_NOTES          Notes associated with bed
    * @param  I_DT_CREATION    Date of bed registry creation
    * @param  O_ID_BED         Bed identifier witch was updated or created after execute this function
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE       {*} 'T'- Temporary bed {*} 'P'- Permanent bed
    * @value  I_FLG_STATUS     {*} 'V'- Free bed {*} 'O'- Occupied bed {*} 'D'- Depracated registry/released temporary bed
    * 
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   20-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_bed         IN bed.id_bed%TYPE,
        i_flg_type       IN bed.flg_type%TYPE,
        i_flg_status     IN bed.flg_status%TYPE,
        i_flg_avail      IN bed.flg_available%TYPE,
        i_desc_bed       IN bed.desc_bed%TYPE,
        i_id_bed_type    IN bed.id_bed_type%TYPE,
        i_id_room        IN bed.id_room%TYPE,
        i_notes          IN bed.notes%TYPE,
        i_dt_creation    IN bed.dt_creation%TYPE,
        i_transaction_id IN VARCHAR2,
        o_id_bed         OUT bed.id_bed%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_bed      bed%ROWTYPE;
        l_id_bed   bed.id_bed%TYPE;
        l_code_bed bed.code_bed%TYPE := 'BED.CODE_BED.';
        l_rows     table_varchar := table_varchar();
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := '[PK_BMNG_CORE.SET_BED] i_id_bed=' || i_id_bed || ' i_flg_type=' || i_flg_type || ' i_flg_status=' ||
                   i_flg_status || ' i_flg_avail=' || i_flg_avail || ' i_desc_bed=' || i_desc_bed || ' i_id_bed_type=' ||
                   i_id_bed_type || ' i_id_room=' || i_id_room || ' i_notes=' || i_notes || ' i_dt_creation=' ||
                   CAST(i_dt_creation AS VARCHAR2);
        pk_alertlog.log_debug(g_error);
    
        -- IF i_id_bed IS NULL it is created a new temporary bed, otherwise, update bed information
        IF i_id_bed IS NULL
        THEN
            -- CREATE TEMPORARY BED
            g_error := 'GET TS_BED.NEXT_KEY';
            pk_alertlog.log_debug(g_error);
            l_id_bed := ts_bed.next_key;
        
            -- Create BED.CODE_BED
            l_code_bed := l_code_bed || l_id_bed;
            --
            g_error := 'INSERT TEMPORARY BED: CALL TS_BED.INS WITH ID_BED ' || l_id_bed;
            pk_alertlog.log_debug(g_error);
            ts_bed.ins(id_bed_in        => l_id_bed,
                       code_bed_in      => l_code_bed,
                       id_room_in       => i_id_room,
                       flg_type_in      => i_flg_type,
                       flg_status_in    => i_flg_status,
                       desc_bed_in      => i_desc_bed,
                       notes_in         => i_notes,
                       rank_in          => NULL,
                       flg_available_in => pk_alert_constant.g_yes,
                       id_bed_type_in   => CASE
                                               WHEN i_id_bed_type IS NULL THEN
                                                -1
                                               ELSE
                                                i_id_bed_type
                                           END,
                       dt_creation_in   => i_dt_creation,
                       rows_out         => l_rows);
        
            g_error := 'PROCESS INSERT OF BED WITH ID_BED ' || l_id_bed;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'BED', l_rows, o_error);
        
        ELSE
            -- Get current bed information
            g_error := 'GET BED RECORD INFORMATION OF ID_BED ' || i_id_bed;
            pk_alertlog.log_debug(g_error);
            SELECT b.*
              INTO l_bed
              FROM bed b
             WHERE b.id_bed = i_id_bed;
        
            -- Update BED.ROWTYPE with new values
            l_bed.id_room       := nvl(i_id_room, l_bed.id_room);
            l_bed.flg_status    := nvl(i_flg_status, l_bed.flg_status);
            l_bed.desc_bed      := nvl(i_desc_bed, l_bed.desc_bed);
            l_bed.notes         := nvl(i_notes, l_bed.notes);
            l_bed.id_bed_type   := nvl(i_id_bed_type, l_bed.id_bed_type);
            l_bed.flg_available := nvl(i_flg_avail, l_bed.flg_available);
        
            -- Update BED registry
            g_error := 'CALL TS_BED.UPD WITH ID_BED ' || i_id_bed;
            pk_alertlog.log_debug(g_error);
            ts_bed.upd(id_bed_in        => i_id_bed,
                       code_bed_in      => l_bed.code_bed,
                       id_room_in       => l_bed.id_room,
                       flg_type_in      => l_bed.flg_type,
                       flg_status_in    => l_bed.flg_status,
                       desc_bed_in      => l_bed.desc_bed,
                       notes_in         => l_bed.notes,
                       rank_in          => l_bed.rank,
                       flg_available_in => l_bed.flg_available,
                       id_bed_type_in   => l_bed.id_bed_type,
                       rows_out         => l_rows);
        
            g_error := 'PROCESS UPDATE OF BED WITH ID_BED ' || i_id_bed;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'BED', l_rows, o_error);
        END IF;
    
        -- SUCCESS
        o_id_bed := nvl(l_id_bed, i_id_bed);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_bed;

    /********************************************************************************************************************************************
    * CREATE_BED_DEP_CLIN_SERV          Function that creates one new bed speciality for an bed
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED                  Bed identifier that should be updated or created in this function
    * @param  I_ID_BED_DEP_CLIN_SERV    Speciality (dep_clin_serv) identifier that should be updated or created in this function
    * @param  I_FLG_AVAILABLE           FLG_AVAILABILITY for this bed/speciality association
    * @param  O_ERROR                   If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                {*} 'T'- Temporary bed {*} 'P'- Permanent bed
    * @value  I_FLG_STATUS              {*} 'V'- Free bed {*} 'O'- Occupied bed {*} 'D'- Depracated registry/released temporary bed
    * 
    * @return                           Returns TRUE if success, otherwise returns FALSE
    * @raises                           PL/SQL generic erro "OTHERS"
    *
    * @author                           Luís Maia
    * @version                          2.5.0.5
    * @since                            2009/07/29
    *******************************************************************************************************************************************/
    FUNCTION create_bed_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_bed           IN bed.id_bed%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_available    IN bed_dep_clin_serv.flg_available%TYPE DEFAULT pk_alert_constant.g_yes,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows    table_varchar := table_varchar();
        l_num_reg PLS_INTEGER;
    BEGIN
        --
        -- Get if that bed is already associated with that speciality
        g_error := 'GET BED SPECIALITY ASSOCIATION FOR ID_BED ' || i_id_bed || ' AND ID_DEP_CLIN_SERV ' ||
                   i_id_dep_clin_serv;
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(0)
          INTO l_num_reg
          FROM bed_dep_clin_serv bdcs
         WHERE bdcs.id_bed = i_id_bed
           AND bdcs.id_dep_clin_serv = i_id_dep_clin_serv
           AND bdcs.flg_available = pk_alert_constant.g_yes;
    
        -- Only if this association doesn't exist
        IF l_num_reg = 0
        THEN
            g_error := 'CALL TS_BED_DEP_CLIN_SERV.INS FOR ID_BED ' || i_id_bed || ' AND ID_DEP_CLIN_SERV ' ||
                       i_id_dep_clin_serv;
            pk_alertlog.log_debug(g_error);
            ts_bed_dep_clin_serv.ins(id_bed_in           => i_id_bed,
                                     id_dep_clin_serv_in => i_id_dep_clin_serv,
                                     flg_available_in    => i_flg_available,
                                     rows_out            => l_rows);
        
            g_error := 'PROCESS INSERT FOR ID_BED ' || i_id_bed || ' AND ID_DEP_CLIN_SERV ' || i_id_dep_clin_serv;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'BED_DEP_CLIN_SERV', l_rows, o_error);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_BED_DEP_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_bed_dep_clin_serv;

    /********************************************************************************************************************************************
    * Checks if the discharge schedule date is null or prior the allocation start date. 
    * If so, consider the allocation end date as the start date plus a configured period of time.
    *
    * @param  I_LANG                Language associated to the professional executing the request
    * @param  I_PROF                Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DT_BEGIN            Allocation start date
    * @param  I_DT_END              Discharge Schedule Date
    * @param  O_DT_END              Allocation end date to be send to the scheduler
    * @param  O_ERROR               If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   01-Jul-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION check_allocation_dates
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end   IN bmng_action.dt_end_action%TYPE,
        o_dt_end   OUT bmng_action.dt_end_action%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sch_default_time   sys_config.value%TYPE;
        l_dt_end_start_point bmng_action.dt_end_action%TYPE;
    BEGIN
    
        g_error := 'CHECK_ALLOCATION_DATES i_dt_begin=' || i_dt_begin || ' i_dt_end=' || i_dt_end;
        pk_alertlog.log_debug(g_error);
    
        IF (i_dt_end < i_dt_begin OR i_dt_end IS NULL)
        THEN
            g_error := 'CALL pk_sysconfig.get_config: SCH_DEFAULT_ALLOCATION_TIME_PERIOD';
            pk_alertlog.log_debug(text => g_error);
            l_sch_default_time := pk_sysconfig.get_config(i_code_cf => 'SCH_DEFAULT_ALLOCATION_TIME_PERIOD',
                                                          i_prof    => i_prof);
        
            g_error := 'CHECK_ALLOCATION_DATES l_sch_default_time=' || l_sch_default_time;
            pk_alertlog.log_debug(g_error);
        
            -- in this point the i_dt_end is filled with the discharge schedule date if no allocation end date is specified
            IF (i_dt_end IS NULL OR i_dt_end < i_dt_begin)
            THEN
                -- the discharge schedule date is not filled or is prior to the allocation start date
                l_dt_end_start_point := i_dt_begin;
            END IF;
        
            g_error := 'CALL pk_date_utils.add_days_to_tstz. Nr of days: ' || l_sch_default_time;
            pk_alertlog.log_debug(text => g_error);
            o_dt_end := pk_date_utils.add_days_to_tstz(i_timestamp => l_dt_end_start_point,
                                                       i_days      => l_sch_default_time);
        ELSE
            o_dt_end := i_dt_end;
        END IF;
    
        g_error := 'CHECK_ALLOCATION_DATES o_dt_end=' || o_dt_end;
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_ALLOCATION_DATES',
                                              o_error);
            RETURN FALSE;
    END check_allocation_dates;

    /********************************************************************************************************************************************
    * SET_NOTIFY_SCHEDULER                    Function that sends bed information to scheduler
    *
    * @param  I_LANG                          Language associated to the professional executing the request
    * @param  I_PROF                          Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE                    Episode identifier
    * 
    * @return                                 Returns TRUE if success, otherwise returns FALSE
    * @raises                                 PL/SQL generic erro "OTHERS"
    *
    * @author                                 Luís Maia
    * @version                                2.6.1.2
    * @since                                  20-Sep-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION set_notify_inter_alert
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_bmng_action IN bmng_action.id_bmng_action%TYPE,
        i_allocation     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'SET_NOTIFY_INTER_ALERT';
        --
        l_err EXCEPTION;
    BEGIN
    
        IF i_allocation = pk_alert_constant.g_yes
           AND i_id_episode IS NOT NULL
        THEN
            -- Invoke New INTERALERT API
            g_error := 'CALL TO PK_IA_EVENT_COMMON.PATIENT_BED_ALLOCATION_UPDATE: I_ID_INSTITUTION=' ||
                       i_prof.institution || ' i_id_episode=' || i_id_episode;
            --
            pk_alertlog.log_debug(text => '*** DEBUG: *** ' || g_error);
            pk_ia_event_common.patient_bed_allocation_update(i_id_institution => i_prof.institution,
                                                             i_id_episode     => i_id_episode);
        ELSIF i_allocation = pk_alert_constant.g_no
              AND i_id_bmng_action IS NOT NULL
        THEN
            -- Invoke New INTERALERT API
            g_error := 'CALL TO PK_IA_EVENT_COMMON.PATIENT_BED_ALLOCATION_UPDATE: I_ID_INSTITUTION=' ||
                       i_prof.institution || ' i_id_episode=' || i_id_episode;
            --
            pk_alertlog.log_debug(text => '*** DEBUG: *** ' || g_error);
            pk_ia_event_common.bed_management_status_update(i_id_institution => i_prof.institution,
                                                            i_id_bmng_action => i_id_bmng_action);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN l_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_notify_inter_alert;

    /********************************************************************************************************************************************
    * SET_NOTIFY_SCHEDULER                    Function that sends bed information to scheduler
    *
    * @param  I_LANG                          Language associated to the professional executing the request
    * @param  I_PROF                          Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_FLG_ORIGIN_ACTION_UX          Type of action: FLAG defined in flash layer
    * @param  I_ID_BED                        Bed identifier that should be updated or created in this function
    * @param  I_DT_BEGIN_ACTION               Date in which this action start counting
    * @param  I_DT_END_ACTION                 Date in which this action became outdated
    * @param  I_ID_EPISODE                    Episode identifier
    * @param  I_ID_PATIENT                    Patient identifier
    * @param  I_TRANSACTION_ID                Remote transaction identifier
    * @param  I_ALLOCATION_COMMIT             Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param  O_ERROR                         If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                      {*} 'T'- Temporary bed {*} 'P'- Permanent bed
    * @value  I_FLG_STATUS                    {*} 'V'- Free bed {*} 'O'- Occupied bed {*} 'D'- Depracated registry/released temporary bed
    * @value  I_FLG_ORIGIN_ACTION_UX          {*} 'B'-  BLOCK
    *                                         {*} 'U'-  UNBLOCK
    *                                         {*} 'V'-  FREE
    *                                         {*} 'O'-  OCCUPY (desreservar)
    *                                         {*} 'T'-  OCCUPY TEMPORARY BED (allocate / re-allocate)
    *                                         {*} 'P'-  OCCUPY DEFINITIVE BED (allocate / re-allocate)
    *                                         {*} 'S'-  SCHEDULE
    *                                         {*} 'R'-  RESERVE
    *                                         {*} 'D'-  DIRTY
    *                                         {*} 'C'-  CONTAMINED
    *                                         {*} 'I'-  CLEANING IN PROCESS
    *                                         {*} 'L'-  CLEANING CONCLUDED
    *                                         {*} 'E'-  EDIT BED ASSIGNMENT
    *                                         {*} 'ND'- UPDATE NCH PATIENT (DIRECTLY IN GRID)
    *                                         {*} 'NT'- NCH TOOLS
    *                                         {*} 'BT'- BLOCK TOOLS
    *                                         {*} 'UT'- UNBLOCK TOOLS
    * @value  I_ALLOCATION_COMMIT             {*} 'Y' - Yes {*} 'N' - No
    * 
    * @return                                 Returns TRUE if success, otherwise returns FALSE
    * @raises                                 PL/SQL generic erro "OTHERS"
    *
    * @author                                 Luís Maia
    * @version                                2.5.0.5
    * @since                                  20-Jul-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_notify_scheduler
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_origin_action_ux IN VARCHAR2,
        i_id_bed               IN bed.id_bed%TYPE,
        i_dt_begin_action      IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end_action        IN bmng_action.dt_end_action%TYPE,
        i_id_patient           IN bmng_allocation_bed.id_patient%TYPE,
        i_id_episode           IN bmng_allocation_bed.id_episode%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_allocation_commit    IN VARCHAR2,
        i_id_bmng              IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        i_id_bmng_action       IN bmng_action.id_bmng_action%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_episode_dcs_id     department.id_department%TYPE;
        l_epis_type          episode.id_epis_type%TYPE;
        l_loginfo            VARCHAR2(4000);
        l_func_name          VARCHAR2(200) := 'SET_NOTIFY_SCHEDULER';
        l_dt_end_action      bmng_action.dt_end_action%TYPE;
        l_id_resource        bmng_scheduler_map.id_resource_ext%TYPE;
        i_old_id_bmng_action bmng_action.id_bmng_action%TYPE;
        --
        l_err         EXCEPTION;
        l_id_schedule NUMBER;
    BEGIN
    
        pk_alertlog.log_debug(text => '*** DEBUG: *** Inside function SET_NOTIFY_SCHEDULER CALL PK_BMNG_CORE.SET_NOTIFY_SCHEDULER, i_transaction_id>' ||
                                      i_transaction_id || '<.');
    
        g_error := '[PK_BMNG_CORE.SET_NOTIFY_SCHEDULER] i_flg_origin_action_ux=' || i_flg_origin_action_ux ||
                   ' i_id_bed=' || i_id_bed || ' i_dt_begin_action=' || CAST(i_dt_begin_action AS VARCHAR2) ||
                   ' i_dt_end_action=' || CAST(i_dt_end_action AS VARCHAR2) || ' i_id_patient=' || i_id_patient ||
                   ' i_id_episode=' || i_id_episode || ' i_allocation_commit=' || i_allocation_commit || ' i_id_bmng=' ||
                   i_id_bmng;
        pk_alertlog.log_debug(g_error);
    
        IF i_allocation_commit = pk_alert_constant.g_yes
        THEN
            --
            IF i_id_episode IS NOT NULL --If there is an episode, get it's type
            THEN
                g_error := 'GET EPISODE EPIS_TYPE: ID_EPISODE = ' || i_id_episode;
                pk_alertlog.log_debug(text => g_error);
                BEGIN
                    SELECT e.id_epis_type
                      INTO l_epis_type
                      FROM episode e
                     WHERE e.id_episode = i_id_episode;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                g_error := 'GET EPISODE DEP_CLI_SERV: ID_EPISODE = ' || i_id_episode;
                pk_alertlog.log_debug(text => g_error);
                BEGIN
                    SELECT ei.id_dep_clin_serv
                      INTO l_episode_dcs_id
                      FROM epis_info ei
                     WHERE ei.id_episode = i_id_episode;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            ELSE
                l_epis_type      := NULL;
                l_episode_dcs_id := NULL;
            END IF;
        
            IF i_id_bmng IS NOT NULL
            THEN
                BEGIN
                    SELECT bsm.id_resource_ext
                      INTO l_id_resource
                      FROM bmng_scheduler_map bsm
                     WHERE bsm.id_resource_pfh = i_id_bmng;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_resource := NULL;
                END;
            END IF;
        
            g_error := '[PK_BMNG_CORE.SET_NOTIFY_SCHEDULER] l_epis_type=' || l_epis_type;
            pk_alertlog.log_debug(g_error);
        
            g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.BLOCK_BED i_transaction_id>' || i_transaction_id || '<.';
        
            -- If this is an Inpatient episode, it will notify scheduler 3.0
            IF (l_epis_type = pk_alert_constant.g_epis_type_inpatient)
            THEN
            
                IF i_flg_origin_action_ux IN
                   (pk_bmng_constant.g_bmng_flg_origin_ux_p, pk_bmng_constant.g_bmng_flg_origin_ux_v)
                THEN
                    l_loginfo := 'Function check_allocation_dates. i_dt_begin=' || CAST(i_dt_begin_action AS VARCHAR2) ||
                                 ' i_dt_end=' || CAST(i_dt_end_action AS VARCHAR2);
                    --
                    IF NOT check_allocation_dates(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  i_dt_begin => i_dt_begin_action,
                                                  i_dt_end   => i_dt_end_action,
                                                  o_dt_end   => l_dt_end_action,
                                                  o_error    => o_error)
                    THEN
                        RAISE l_err;
                    END IF;
                
                    g_error := '[PK_BMNG_CORE.SET_NOTIFY_SCHEDULER] l_dt_end_action=' ||
                               CAST(l_dt_end_action AS VARCHAR2);
                    pk_alertlog.log_debug(g_error);
                END IF;
            
                -- Invoke New Scheduler API's
                IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
                THEN
                
                    l_loginfo := 'Function pk_schedule_api_upstream.allocate_bed return false. ID_BED=' || i_id_bed ||
                                 ' START_DATE=' || CAST(i_dt_begin_action AS VARCHAR2) || ' END_DATE=' ||
                                 CAST(l_dt_end_action AS VARCHAR2) || ' ID_PATIENT=' || i_id_patient ||
                                 ' ID_SPECIALITY=' || l_episode_dcs_id;
                    --
                    g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.ALLOCATE_BED';
                    IF NOT pk_schedule_api_upstream.allocate_bed(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_transaction_id => i_transaction_id,
                                                                 i_id_patient     => i_id_patient,
                                                                 i_id_speciality  => l_episode_dcs_id,
                                                                 i_id_bed         => i_id_bed,
                                                                 i_start_date     => i_dt_begin_action,
                                                                 i_end_date       => l_dt_end_action,
                                                                 i_id_bmng        => i_id_bmng,
                                                                 o_error          => o_error)
                    THEN
                        RAISE l_err;
                    END IF;
                    --
                ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_e
                THEN
                    l_loginfo := 'Function pk_schedule_api_upstream.update_allocated_bed return false. ID_BED=' ||
                                 i_id_bed || ' START_DATE=' || CAST(i_dt_begin_action AS VARCHAR2) || ' ID_PATIENT=' ||
                                 i_id_patient || ' NEW_END_DATE=' || CAST(i_dt_end_action AS VARCHAR2);
                    --
                    BEGIN
                        SELECT bsm.id_resource_ext
                          INTO l_id_resource
                          FROM bmng_scheduler_map bsm
                          JOIN bmng_allocation_bed bab
                            ON bab.id_bmng_allocation_bed = bsm.id_resource_pfh
                         WHERE bab.id_episode = i_id_episode;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_resource := NULL;
                        WHEN too_many_rows THEN
                            BEGIN
                                SELECT bsm.id_resource_ext
                                  INTO l_id_resource
                                  FROM bmng_scheduler_map bsm
                                  JOIN bmng_allocation_bed bab
                                    ON bab.id_bmng_allocation_bed = bsm.id_resource_pfh
                                 WHERE bab.id_episode = i_id_episode
                                   AND bab.id_bmng_allocation_bed = i_id_bmng;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_id_resource := NULL;
                            END;
                    END;
                    --
                    g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.UPDATE_ALLOCATED_BED';
                    IF NOT pk_schedule_api_upstream.update_allocated_bed(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_transaction_id => i_transaction_id,
                                                                         i_id_patient     => i_id_patient,
                                                                         i_id_bed         => i_id_bed,
                                                                         i_start_date     => i_dt_begin_action,
                                                                         i_end_date       => NULL,
                                                                         i_new_end_date   => i_dt_end_action,
                                                                         i_id_resource    => l_id_resource,
                                                                         i_id_bmng        => i_id_bmng,
                                                                         o_error          => o_error)
                    THEN
                        RAISE l_err;
                    END IF;
                
                    --
                ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
                THEN
                    g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
                    --
                    l_loginfo := 'Function pk_schedule_api_upstream.deallocate_bed. ID_BED=' || i_id_bed ||
                                 ' START_DATE=' || CAST(i_dt_begin_action AS VARCHAR2) || ' END_DATE=' ||
                                 CAST(l_dt_end_action AS VARCHAR2) || ' ID_PATIENT=' || i_id_patient;
                
                    g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.DEALLOCATE_BED';
                    IF NOT pk_schedule_api_upstream.deallocate_bed(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_transaction_id => i_transaction_id,
                                                                   i_id_patient     => i_id_patient,
                                                                   i_id_bed         => i_id_bed,
                                                                   i_start_date     => i_dt_begin_action,
                                                                   i_end_date       => g_sysdate_tstz,
                                                                   i_id_resource    => l_id_resource,
                                                                   o_error          => o_error)
                    THEN
                        RAISE l_err;
                    END IF;
                    --
                END IF;
            END IF;
        
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
            THEN
                l_loginfo := 'Function pk_schedule_api_upstream.block_bed ID_BED=' || i_id_bed || ' START_DATE=' ||
                             CAST(i_dt_begin_action AS VARCHAR2) || ' END_DATE=' || CAST(i_dt_end_action AS VARCHAR2);
                --
                g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.BLOCK_BED';
                IF NOT pk_schedule_api_upstream.block_bed(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_transaction_id => i_transaction_id,
                                                          i_id_bed         => i_id_bed,
                                                          i_start_date     => i_dt_begin_action,
                                                          i_end_date       => i_dt_end_action,
                                                          i_id_bmng_action => i_id_bmng_action,
                                                          o_error          => o_error)
                THEN
                    RAISE l_err;
                END IF;
                --
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
            THEN
                BEGIN
                    SELECT t.id_bmng_action, t.id_sch_resource
                      INTO i_old_id_bmng_action, l_id_resource
                      FROM (SELECT ba.id_bmng_action,
                                   basm.id_sch_resource,
                                   row_number() over(ORDER BY ba.dt_begin_action DESC) rn
                              FROM bmng_action_sch_map basm
                              JOIN bmng_action ba
                                ON ba.id_bmng_action = basm.id_bmng_action
                             WHERE ba.id_bed = i_id_bed) t
                     WHERE t.rn = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        i_old_id_bmng_action := NULL;
                        l_id_resource        := NULL;
                END;
                l_loginfo := 'Function pk_schedule_api_upstream.unblock_bed ID_BED=' || i_id_bed || ' START_DATE=' ||
                             CAST(i_dt_begin_action AS VARCHAR2) || ' END_DATE=' || CAST(i_dt_end_action AS VARCHAR2);
                --
                g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.UNBLOCK_BED';
                IF NOT pk_schedule_api_upstream.unblock_bed(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_transaction_id => i_transaction_id,
                                                            i_id_bed         => i_id_bed,
                                                            i_start_date     => i_dt_begin_action,
                                                            i_end_date       => i_dt_end_action,
                                                            i_id_bmng_action => i_old_id_bmng_action,
                                                            i_id_resource    => l_id_resource,
                                                            o_error          => o_error)
                THEN
                    RAISE l_err;
                END IF;
            END IF;
        
            pk_alertlog.log_debug(text => '*** DEBUG: *** ' || l_loginfo);
        ELSIF i_allocation_commit = pk_alert_constant.g_no
              AND i_id_bmng IS NOT NULL
              AND i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
        THEN
        
            BEGIN
                SELECT bsm.id_resource_ext
                  INTO l_id_resource
                  FROM bmng_scheduler_map bsm
                  JOIN bmng_allocation_bed bab
                    ON bab.id_bmng_allocation_bed = bsm.id_resource_pfh
                 WHERE bab.id_episode = i_id_episode;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_resource := NULL;
            END;
            IF l_id_resource IS NULL
            THEN
                l_id_schedule := pk_schedule_inp.get_schedule_id(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_episode => i_id_episode);
                IF l_id_schedule IS NOT NULL
                THEN
                    IF NOT pk_schedule_api_downstream.get_schedule_id_resource(i_lang                 => i_lang,
                                                                               i_prof                 => i_prof,
                                                                               i_id_schedule          => l_id_schedule,
                                                                               o_id_schedule_resource => l_id_resource,
                                                                               o_error                => o_error)
                    THEN
                        RAISE l_err;
                    END IF;
                    IF l_id_resource IS NOT NULL
                    THEN
                        ts_bmng_scheduler_map.ins(id_resource_pfh_in => i_id_bmng,
                                                  id_resource_ext_in => l_id_resource,
                                                  dt_created_in      => current_timestamp,
                                                  handle_error_in    => TRUE);
                    END IF;
                END IF;
            END IF;
        END IF;
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN l_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_schedule_api_upstream.do_rollback(i_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_schedule_api_upstream.do_rollback(i_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_notify_scheduler;

    /********************************************************************************************************************************************
    * SET_NOTIFY_SCHEDULER                    Function that sends bed information to scheduler
    *
    * @param  I_LANG                          Language associated to the professional executing the request
    * @param  I_PROF                          Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE                    Episode identifier
    * @param  I_ID_BED                        Bed identifier
    * 
    * @return                                 Returns TRUE if success, otherwise returns FALSE
    * @raises                                 PL/SQL generic erro "OTHERS"
    *
    * @author                                 Luís Maia
    * @version                                2.6.1.2
    * @since                                  20-Sep-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION set_epis_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_bed     IN epis_info.id_bed%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
            --
            g_error := 'CALL TO ts_epis_info.upd: id_episode = ' || i_id_episode || ' i_id_bed = ' || i_id_bed;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in => i_id_episode,
                             id_bed_in     => i_id_bed,
                             id_bed_nin    => FALSE,
                             rows_out      => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rowids, o_error, table_varchar('ID_BED'));
        
            --
            g_error := 'CALL TO set_notify_inter_alert: id_episode = ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT set_notify_inter_alert(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_episode     => i_id_episode,
                                     i_id_bmng_action => NULL,
                                     i_allocation     => CASE
                                                             WHEN i_id_bed IS NULL THEN
                                                              pk_alert_constant.g_no
                                                             ELSE
                                                              pk_alert_constant.g_yes
                                                         END,
                                     o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
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
                                              'SET_EPIS_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_info;

    /********************************************************************************************
    * SET_BMNG_FREE_OCCUP_BEDS        For a provided episode, loads all occupied beds and updates them to free beds.
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_epis              Episode identifier
    * @param IN   i_transaction_id    remote transaction identifier
    * @param OUT  o_error             If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                         Luís Maia
    * @version                        2.5.0.5
    * @since                          2009/08/24
    ********************************************************************************************/
    FUNCTION set_bmng_free_occup_beds
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bmng_act            table_number;
        l_bmng_deps           table_number;
        l_bmng_beds           table_number;
        l_bmng_rooms          table_number;
        l_bmng_patient        table_number;
        l_bmng_allocation_bed table_number;
        --
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        l_bed_allocation         VARCHAR2(1);
        l_exception_info         sys_message.desc_message%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        g_error := 'GET ACTIVE BMNG_ACTIONS FOR ID_EPISODE ' || i_epis || ' (OCCUPIED BEDS)';
        pk_alertlog.log_debug(g_error);
        SELECT ba.id_bmng_action, ba.id_department, bab.id_room, bab.id_bed, bab.id_patient, bab.id_bmng_allocation_bed
          BULK COLLECT
          INTO l_bmng_act, l_bmng_deps, l_bmng_rooms, l_bmng_beds, l_bmng_patient, l_bmng_allocation_bed
          FROM bmng_action ba
         INNER JOIN bmng_allocation_bed bab
            ON bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
         WHERE bab.id_episode = i_epis
           AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
           AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n
           AND bab.flg_outdated = pk_alert_constant.g_no;
    
        -- If there are not active occupations, this function should return
        IF l_bmng_act.count = 0
        THEN
            g_error := 'THERE ARE NOT ACTIVE BED OCCUPATIONS FOR ID_EPISODE ' || i_epis;
            pk_alertlog.log_debug(g_error);
            RETURN TRUE;
        END IF;
    
        FOR i IN l_bmng_act.first .. l_bmng_act.last
        LOOP
            g_error := 'CALL SET_BED_MANAGEMENT WITH ID_BED ' || l_bmng_beds(i) || ' AND ID_EPISODE ' || i_epis;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_bmng_core.set_bed_management(i_lang                   => i_lang,
                                                   i_prof                   => i_prof,
                                                   i_id_bmng_action         => l_bmng_act(i),
                                                   i_id_department          => l_bmng_deps(i),
                                                   i_id_room                => l_bmng_rooms(i),
                                                   i_id_bed                 => l_bmng_beds(i),
                                                   i_id_bmng_reason         => NULL,
                                                   i_id_bmng_allocation_bed => l_bmng_allocation_bed(i),
                                                   i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                                   i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                                   i_nch_capacity           => NULL,
                                                   i_action_notes           => NULL,
                                                   i_dt_begin_action        => current_timestamp,
                                                   i_dt_end_action          => NULL,
                                                   i_id_episode             => i_epis,
                                                   i_id_patient             => l_bmng_patient(i),
                                                   i_nch_hours              => NULL,
                                                   i_flg_allocation_nch     => NULL,
                                                   i_desc_bed               => NULL,
                                                   i_id_bed_type            => NULL,
                                                   i_dt_discharge_schedule  => NULL,
                                                   i_id_bed_dep_clin_serv   => NULL,
                                                   i_flg_origin_action_ux   => pk_bmng_constant.g_bmng_flg_origin_ux_v,
                                                   i_reason_notes           => NULL,
                                                   i_transaction_id         => l_transaction_id,
                                                   i_allocation_commit      => pk_alert_constant.g_yes,
                                                   o_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                   o_id_bed                 => l_id_bed,
                                                   o_bed_allocation         => l_bed_allocation,
                                                   o_exception_info         => l_exception_info,
                                                   o_error                  => o_error)
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END IF;
        END LOOP;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BMNG_FREE_OCCUP_BEDS',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_bmng_free_occup_beds;

    /********************************************************************************************************************************************
    * SET_BMNG_ALLOCATION_BED             Function that update an bed allocation information if that allocation exists, otherwise create one new bed allocation
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BMNG_ALLOCATION_BED    Bed management allocation identifier that should be updated or created in this function
    * @param  I_ID_EPISODE                Episode identifier
    * @param  I_ID_PATIENT                Patient identifier
    * @param  I_ID_BED                    Bed identifier
    * @param  I_ALLOCATION_NOTES          Allocation notes inserted by professional when creating an allocation
    * @param  I_ID_ROOM                   Room identifier
    * @param  I_DT_CREATION               Date in which current registry was created
    * @param  I_DT_RELEASE                Date in which current registry was outdated
    * @param  I_NCH_HOURS                 Number of NCH associated with current allocation
    * @param  I_FLG_ALLOCATION_NCH        Is this NCH information definitive or automatically updated with NCH_LEVEL information
    * @param  I_DT_BEGIN_NCH              Date in which current NCH information starts taking efect
    * @param  I_DT_END_NCH                Date in which current NCH information ends it's validation (if I_FLG_ALLOCATION_NCH = 'U')
    * @param  I_FLG_CREATE_NEW_REG        Indicates if this function should return a new allocation bed registry
    * @param  I_FLG_DISCHARGE_ALLOC       Indicates if this function concerns episode allocation release
    * @param  O_ID_BMNG_ALLOCATION_BED    Allocation bed identifier witch was updated or created after execute this function
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_ALLOCATION_NCH        {*} 'D'- Definitive {*} 'U'- Updatable
    * @value  I_FLG_CREATE_NEW_REGISTRY   {*} 'Y'- Yes {*} 'N'- No
    * @value  I_FLG_DISCHARGE_ALLOC       {*} 'Y'- Yes {*} 'N'- No
    * 
    * @return                             Returns TRUE if success, otherwise returns FALSE
    * @raises                             PL/SQL generic erro "OTHERS"
    *
    * @author                             Luís Maia
    * @version                            2.5.0.5
    * @since                              2009/07/21
    *******************************************************************************************************************************************/
    FUNCTION set_bmng_allocation_bed
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_bmng_allocation_bed IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        i_id_episode             IN bmng_allocation_bed.id_episode%TYPE,
        i_id_patient             IN bmng_allocation_bed.id_patient%TYPE,
        i_id_bed                 IN bmng_allocation_bed.id_bed%TYPE,
        i_allocation_notes       IN bmng_allocation_bed.allocation_notes%TYPE,
        i_id_room                IN bmng_allocation_bed.id_room%TYPE,
        i_dt_creation            IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_release             IN bmng_allocation_bed.dt_release%TYPE,
        i_flg_create_new_reg     IN VARCHAR2,
        i_realocate_patient      IN VARCHAR2,
        i_flg_discharge_alloc    IN VARCHAR2,
        i_id_epis_nch            IN bmng_allocation_bed.id_epis_nch%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_reserved_bed           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_origin_action_ux   IN VARCHAR2 DEFAULT NULL,
        o_id_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_bmng_allocation_bed    bmng_allocation_bed%ROWTYPE;
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_rows                   table_varchar := table_varchar();
        l_epis_info_bed          epis_info.id_bed%TYPE;
        l_epis_info_room         epis_info.id_room%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := '[PK_BMNG_CORE.SET_BMNG_ALLOCATION_BED]  i_id_bmng_allocation_bed=' || i_id_bmng_allocation_bed ||
                   ' i_id_episode=' || i_id_episode || ' i_id_patient=' || i_id_patient || ' i_id_bed=' || i_id_bed ||
                   ' i_allocation_notes=' || i_allocation_notes || ' i_id_room=' || i_id_room || ' i_dt_creation=' ||
                   CAST(i_dt_creation AS VARCHAR2) || ' i_dt_release=' || i_dt_release || ' i_flg_create_new_reg=' ||
                   i_flg_create_new_reg || ' i_realocate_patient=' || i_realocate_patient || ' i_flg_discharge_alloc=' ||
                   i_flg_discharge_alloc || ' i_id_epis_nch=' || i_id_epis_nch;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_realocate_patient = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL SET_BMNG_FREE_OCCUP_BEDS WITH ID_EPISODE ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT set_bmng_free_occup_beds(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_epis           => i_id_episode,
                                            i_transaction_id => l_transaction_id,
                                            o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        --
        IF i_id_bmng_allocation_bed IS NULL
        THEN
            -- CREATE NEW BED ALLOCATION
            g_error := 'CALL TS_BMNG_ALLOCATION_BED.NEXT_KEY';
            pk_alertlog.log_debug(g_error);
            l_id_bmng_allocation_bed := ts_bmng_allocation_bed.next_key;
            --
            g_error := 'INSERT TEMPORARY BED: CALL TS_BMNG_ALLOCATION_BED.INS WITH ID_ALLOCATION_BED ' ||
                       l_id_bmng_allocation_bed;
            pk_alertlog.log_debug(g_error);
            ts_bmng_allocation_bed.ins(id_bmng_allocation_bed_in => l_id_bmng_allocation_bed,
                                       id_episode_in             => i_id_episode,
                                       id_patient_in             => i_id_patient,
                                       id_bed_in                 => i_id_bed,
                                       allocation_notes_in       => i_allocation_notes,
                                       id_room_in                => i_id_room,
                                       id_prof_creation_in       => i_prof.id,
                                       dt_creation_in            => i_dt_creation,
                                       id_prof_release_in        => NULL,
                                       dt_release_in             => NULL,
                                       flg_outdated_in           => pk_alert_constant.g_no,
                                       id_epis_nch_in            => i_id_epis_nch,
                                       rows_out                  => l_rows);
        
            g_error := 'PROCESS INSERT WITH ID_ALLOCATION_BED ' || l_id_bmng_allocation_bed;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'BMNG_ALLOCATION_BED', l_rows, o_error);
            l_rows := table_varchar();
        
            -- UPDATE EPIS_INFO
            g_error := 'CALL TO SET_EPIS_INFO: id_episode = ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_info(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_id_episode => i_id_episode,
                                 i_id_bed     => i_id_bed,
                                 o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSE
            -- --
            -- Update BMNG_ALLOCATION_BED registry to outdated
            -- --
            g_error := 'UPDATE BMNG_ALLOCATION_BED TO OUTDATE: CALL TS_BMNG_ALLOCATION_BED.UPD WITH ID_BMNG_ALLOCATION_BED ' ||
                       i_id_bmng_allocation_bed;
            pk_alertlog.log_debug(g_error);
            ts_bmng_allocation_bed.upd(id_bmng_allocation_bed_in => i_id_bmng_allocation_bed,
                                       flg_outdated_in           => pk_alert_constant.g_yes,
                                       dt_release_in             => i_dt_release,
                                       id_prof_release_in        => i_prof.id,
                                       rows_out                  => l_rows);
        
            g_error := 'PROCESS UPDATE WITH ID_BMNG_ALLOCATION_BED ' || i_id_bmng_allocation_bed;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'BMNG_ALLOCATION_BED', l_rows, o_error);
            l_rows := table_varchar();
        
            IF i_flg_origin_action_ux <> pk_bmng_constant.g_bmng_flg_origin_ux_e
               OR i_flg_origin_action_ux IS NULL
            THEN
            
                -- This code makes possible update EPIS_INFO with other bed that where reserved.
                g_error := 'GET LAST ACTIVE BED ALLOCATION FOR ID_EPISODE ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT allocations.id_bed, allocations.id_room
                      INTO l_epis_info_bed, l_epis_info_room
                      FROM (SELECT bab.id_bed, bab.id_room
                              FROM bmng_allocation_bed bab
                             INNER JOIN bmng_action ba
                                ON (ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed)
                             WHERE (bab.flg_outdated = pk_alert_constant.g_no OR
                                   (bab.flg_outdated = pk_alert_constant.g_yes AND
                                   ba.flg_action = pk_bmng_constant.g_bmng_act_flg_bed_sta_r))
                               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                               AND ba.flg_bed_status IN
                                   (pk_bmng_constant.g_bmng_act_flg_bed_sta_n, pk_bmng_constant.g_bmng_act_flg_bed_sta_r)
                               AND bab.id_episode = i_id_episode
                             ORDER BY ba.flg_bed_status, bab.dt_creation) allocations
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'NO ACTIVE BED ALLOCATION FOR ID_EPISODE ' || i_id_episode;
                        pk_alertlog.log_debug(g_error);
                        l_epis_info_bed := NULL;
                END;
            
                -- UPDATE EPIS_INFO
                g_error := 'CALL SET_EPIS_INFO WITH ID_EPISODE ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF i_flg_discharge_alloc = pk_alert_constant.g_yes
                THEN
                    IF NOT set_epis_info(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_id_episode,
                                         i_id_bed     => NULL,
                                         o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSE
                    IF NOT set_epis_info(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_id_episode,
                                         i_id_bed     => l_epis_info_bed,
                                         o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
            -- --
            -- Create new bmng_allocation_bed registry if applicable
            -- --
            IF i_flg_create_new_reg = pk_alert_constant.g_yes
            THEN
            
                g_error := 'CALL TS_BMNG_ALLOCATION_BED.NEXT_KEY';
                pk_alertlog.log_debug(g_error);
                l_id_bmng_allocation_bed := ts_bmng_allocation_bed.next_key;
            
                -- Get current bmng_allocation_bed information
                g_error := 'GET BMNG_ALLOCATION_BED RECORD FOR ID_BMNG_ALLOCATION_BED ' || i_id_bmng_allocation_bed;
                pk_alertlog.log_debug(g_error);
                SELECT bab.*
                  INTO l_bmng_allocation_bed
                  FROM bmng_allocation_bed bab
                 WHERE bab.id_bmng_allocation_bed = i_id_bmng_allocation_bed;
            
                -- Update BMNG_ALLOCATION_BED.ROWTYPE with new values if applicable
                l_bmng_allocation_bed.id_bmng_allocation_bed := l_id_bmng_allocation_bed;
                l_bmng_allocation_bed.id_episode             := nvl(i_id_episode, l_bmng_allocation_bed.id_episode);
                l_bmng_allocation_bed.id_patient             := nvl(i_id_patient, l_bmng_allocation_bed.id_patient);
                l_bmng_allocation_bed.id_bed                 := nvl(i_id_bed, l_bmng_allocation_bed.id_bed);
                l_bmng_allocation_bed.allocation_notes       := nvl(i_allocation_notes,
                                                                    l_bmng_allocation_bed.allocation_notes);
                l_bmng_allocation_bed.id_room                := nvl(i_id_room, l_bmng_allocation_bed.id_room);
                l_bmng_allocation_bed.flg_outdated           := nvl(i_reserved_bed, pk_alert_constant.g_no);
                l_bmng_allocation_bed.id_epis_nch            := nvl(i_id_epis_nch, l_bmng_allocation_bed.id_epis_nch);
            
                -- Update BED registry
                g_error := 'CALL TS_BMNG_ALLOCATION_BED.INS WITH ID_BMNG_ALLOCATION_BED ' ||
                           l_bmng_allocation_bed.id_bmng_allocation_bed;
                pk_alertlog.log_debug(g_error);
                g_error := 'UPDATE BMNG_ALLOCATION_BED';
                ts_bmng_allocation_bed.ins(id_bmng_allocation_bed_in => l_bmng_allocation_bed.id_bmng_allocation_bed,
                                           id_episode_in             => l_bmng_allocation_bed.id_episode,
                                           id_patient_in             => l_bmng_allocation_bed.id_patient,
                                           id_bed_in                 => l_bmng_allocation_bed.id_bed,
                                           allocation_notes_in       => l_bmng_allocation_bed.allocation_notes,
                                           id_room_in                => l_bmng_allocation_bed.id_room,
                                           id_prof_creation_in       => l_bmng_allocation_bed.id_prof_creation,
                                           dt_creation_in            => l_bmng_allocation_bed.dt_creation,
                                           id_prof_release_in        => NULL,
                                           dt_release_in             => NULL,
                                           flg_outdated_in           => l_bmng_allocation_bed.flg_outdated,
                                           id_epis_nch_in            => l_bmng_allocation_bed.id_epis_nch,
                                           rows_out                  => l_rows);
            
                g_error := 'PROCESS INSERT WITH ID_BMNG_ALLOCATION_BED ' ||
                           l_bmng_allocation_bed.id_bmng_allocation_bed;
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'BMNG_ALLOCATION_BED', l_rows, o_error);
                l_rows := table_varchar();
            
                IF i_flg_origin_action_ux <> pk_bmng_constant.g_bmng_flg_origin_ux_e
                   OR i_flg_origin_action_ux IS NULL
                THEN
                    -- UPDATE EPIS_INFO
                    g_error := 'CALL TO SET_EPIS_INFO: id_episode = ' || i_id_episode;
                    pk_alertlog.log_debug(g_error);
                    IF NOT set_epis_info(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => l_bmng_allocation_bed.id_episode,
                                         i_id_bed     => l_bmng_allocation_bed.id_bed,
                                         o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- SUCCESS
        o_id_bmng_allocation_bed := nvl(l_id_bmng_allocation_bed, i_id_bmng_allocation_bed);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BMNG_ALLOCATION_BED',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_bmng_allocation_bed;

    /********************************************************************************************************************************************
    * SET_BMNG_ACTION                     Function that update an bed allocation information if that allocation exists, otherwise create one new bed allocation
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_DEPARTMENT             Department identifier
    * @param  I_ID_ROOM                   Room identifier
    * @param  I_ID_BED                    Bed identifier
    * @param  I_ID_BMNG_REASON            Reason identifier associated with current action
    * @param  I_ID_BMNG_REASON_TYPE       Reason type identifier associated with current action
    * @param  I_ID_BMNG_ALLOCATION_BED    Bed management allocation identifier that should be updated or created in this function
    * @param  I_FLG_TARGET_ACTION         Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS                Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_FLG_ORIGIN_ACTION         Action origin: (''NB''- NCH Backoffice (institution backoffice); ''NT''- NCH inserted by chiefe nurse (in tools); ''ND''- NCH information inserted in dashboard; ''BT''- Blocking interval inserted by chiefe nurse (in tools); ''BD''- Blocking interval information inserted in dashboard; ''OD''- Other origins)
    * @param  I_FLG_BED_OCUPACITY_STAT    Current bed ocupacity status: (''O''- OCUPIED; ''V''- FREE) (DEFAULT: ''V'')
    * @param  I_FLG_BED_STATUS            Current bed status: (''R''- RESERVED; ''B''- BLOCKED; ''S''- SCHEDULE; ''N''- NORMAL) (DEFAULT: ''N'')
    * @param  I_FLG_BED_CLEANING_STAT     Current bed cleaning status: (''D''- DIRTY; ''C''- CONTAMINED; ''CI''- CLEANING IN PROCESS; ''CC''- CLEANING CONCLUED; ''N''- NORMAL) (DEFAULT: ''N'')
    * @param  I_DT_CREATION               Date in which this registry was created
    * @param  I_NCH_CAPACITY              NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES              Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION           Date in which this action start counting
    * @param  I_DT_END_ACTION             Date in which this action became outdated
    * @param  I_ID_CANCEL_REASON          Cancel reason identifier for current cancelation
    * @param  I_FLG_ACTION                UX action that creates registry
    * @param  i_transaction_id            remote transaction identifier
    * @param  O_ID_BMNG_ACTION            Allocation bed identifier witch was updated or created after execute this function
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TARGET_ACTION         {*} 'S'- Service {*} 'R'- Room {*} 'B'- Bed
    * @value  I_FLG_STATUS                {*} 'A'- Active {*} 'C'- Cancelled {*} 'O'- Outdated
    * @value  I_FLG_STATUS                {*} 'NB'- NCH Backoffice (institution backoffice)
    *                                     {*} 'NT'- NCH inserted by chiefe nurse (in tools)
    *                                     {*} 'ND'- NCH information inserted in dashboard
    *                                     {*} 'BT'- locking interval inserted by chiefe nurse (in tools)
    *                                     {*} 'BD'- Blocking interval information inserted in dashboard
    *                                     {*} 'OD'- Other origins
    * @value  I_FLG_BED_OCUPACITY_STAT    {*} 'O- Ocupied {*} 'V'- Free
    * @value  I_FLG_BED_STATUS            {*} 'R- RESERVED {*} 'B'- BLOCKED {*} 'S'- SCHEDULE {*} 'N'- NORMAL
    * @value  I_FLG_BED_CLEANING_STAT     {*} 'D'- DIRTY
    *                                     {*} 'C'- CONTAMINED
    *                                     {*} 'CI'- CLEANING IN PROCESS
    *                                     {*} 'CC'- CLEANING CONCLUED
    *                                     {*} 'N'- NORMAL
    * @value  I_FLG_ACTION                {*} 'B'- Block bed 
    *                                     {*} 'U'- Unblock bed 
    *                                     {*} 'V'- Free bed 
    *                                     {*} 'O'- Occupy bed (after reserve) 
    *                                     {*} 'T'- Allocate patient to temporary bed 
    *                                     {*} 'P'- Allocate patient to permanent bed 
    *                                     {*} 'S'- Schedule bed 
    *                                     {*} 'R'- Reserve bed 
    *                                     {*} 'D'- Dirty bed 
    *                                     {*} 'C'- Contaminate bed 
    *                                     {*} 'I'- Start bed cleaning 
    *                                     {*} 'L'- Cleaning conclueded 
    *                                     {*} 'E'- Allocation edition 
    *                                     {*} 'ND'- Episode NCH edition 
    *                                     {*} 'NT'- Service NCH edition 
    *                                     {*} 'BT'- Block beds in TOOLS 
    *                                     {*} 'UT'- Unblock beds in TOOLS
    *
    * 
    * @return                             Returns TRUE if success, otherwise returns FALSE
    * @raises                             PL/SQL generic erro "OTHERS"
    *
    * @author                             Luís Maia
    * @version                            2.5.0.5
    * @since                              2009/07/22
    *******************************************************************************************************************************************/
    FUNCTION set_bmng_action
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_bmng_action         IN bmng_action.id_bmng_action%TYPE,
        i_id_department          IN bmng_action.id_department%TYPE,
        i_id_room                IN bmng_action.id_room%TYPE,
        i_id_bed                 IN bmng_action.id_bed%TYPE,
        i_id_bmng_reason         IN bmng_action.id_bmng_reason%TYPE,
        i_id_bmng_reason_type    IN bmng_action.id_bmng_reason_type%TYPE,
        i_id_bmng_allocation_bed IN bmng_action.id_bmng_allocation_bed%TYPE,
        i_flg_target_action      IN bmng_action.flg_target_action%TYPE,
        i_flg_status             IN bmng_action.flg_status%TYPE,
        i_flg_origin_action      IN bmng_action.flg_origin_action%TYPE,
        i_flg_bed_ocupacity_stat IN bmng_action.flg_bed_ocupacity_status%TYPE,
        i_flg_bed_status         IN bmng_action.flg_bed_status%TYPE,
        i_flg_bed_cleaning_stat  IN bmng_action.flg_bed_cleaning_status%TYPE,
        i_dt_creation            IN bmng_action.dt_creation%TYPE,
        i_nch_capacity           IN bmng_action.nch_capacity%TYPE,
        i_action_notes           IN bmng_action.action_notes%TYPE,
        i_dt_begin_action        IN bmng_action.dt_begin_action%TYPE,
        i_dt_end_action          IN bmng_action.dt_end_action%TYPE,
        i_id_cancel_reason       IN bmng_action.id_cancel_reason%TYPE,
        i_flg_action             IN bmng_action.flg_action%TYPE,
        i_insert_into_bmng_act   IN VARCHAR2,
        i_transaction_id         IN VARCHAR2,
        o_id_bmng_action         OUT bmng_action.id_bmng_action%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_bmng_action            bmng_action%ROWTYPE;
        l_id_bmng_action         bmng_action.id_bmng_action%TYPE;
        l_id_bmng_action_old     bmng_action.id_bmng_action%TYPE;
        l_id_bmng_allocation_bed bmng_action.id_bmng_allocation_bed%TYPE;
        l_flg_outdated           bmng_allocation_bed.flg_outdated%TYPE;
        l_bmng_exists            VARCHAR2(1);
        l_rows                   table_varchar := table_varchar();
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- --
        -- Get if there are at least one active BMNG_ACTION for current bed
        -- --
        IF i_id_bmng_action IS NULL
        THEN
            g_error := 'GET IF ID_BED ' || i_id_bed || ' HAVE AT LEAST ONE ACTIVE BMNG_ACTION ASSOCIATED';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT pk_alert_constant.g_yes, ba.id_bmng_action
                  INTO l_bmng_exists, l_id_bmng_action
                  FROM bmng_action ba
                 WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                   AND ba.id_bed = i_id_bed;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'THERE ARE NOT ACTIVE BMNG_ACTION ASSOCIATED WITH ID_BED ' || i_id_bed;
                    pk_alertlog.log_debug(g_error);
                    l_bmng_exists    := pk_alert_constant.g_no;
                    l_id_bmng_action := NULL;
            END;
        END IF;
    
        -- IF allocation is no longer active, this allocation is not inserted into bmng_action
        IF i_id_bmng_allocation_bed IS NOT NULL
        THEN
            BEGIN
                SELECT bab.flg_outdated
                  INTO l_flg_outdated
                  FROM bmng_allocation_bed bab
                 WHERE bab.id_bmng_allocation_bed = i_id_bmng_allocation_bed;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_bmng_allocation_bed := NULL;
            END;
        
            IF l_flg_outdated = pk_alert_constant.g_yes
            THEN
                l_id_bmng_allocation_bed := i_id_bmng_allocation_bed;
            ELSE
                l_id_bmng_allocation_bed := i_id_bmng_allocation_bed;
            END IF;
        ELSE
            l_id_bmng_allocation_bed := i_id_bmng_allocation_bed;
        END IF;
    
        --
        IF i_id_bmng_action IS NULL
           AND l_bmng_exists = pk_alert_constant.g_no
        THEN
            -- CREATE NEW BED MANAGEMENT ACTION
            g_error := 'CALL TO TS_BMNG_ACTION.NEXT_KEY';
            pk_alertlog.log_debug(g_error);
            l_id_bmng_action := ts_bmng_action.next_key;
        
            --
            g_error := 'CALL TS_BMNG_ACTION.INS WITH ID_BMNG_ACTION ' || l_id_bmng_action;
            pk_alertlog.log_debug(g_error);
            ts_bmng_action.ins(id_bmng_action_in           => l_id_bmng_action,
                               id_department_in            => i_id_department,
                               id_room_in                  => i_id_room,
                               id_bed_in                   => i_id_bed,
                               id_bmng_reason_in           => i_id_bmng_reason,
                               id_bmng_reason_type_in      => i_id_bmng_reason_type,
                               id_bmng_allocation_bed_in   => l_id_bmng_allocation_bed,
                               flg_target_action_in        => i_flg_target_action,
                               flg_status_in               => i_flg_status,
                               flg_origin_action_in        => i_flg_origin_action,
                               flg_bed_ocupacity_status_in => i_flg_bed_ocupacity_stat,
                               flg_bed_status_in           => nvl(i_flg_bed_status,
                                                                  pk_bmng_constant.g_bmng_act_flg_bed_sta_n),
                               flg_bed_cleaning_status_in  => i_flg_bed_cleaning_stat,
                               id_prof_creation_in         => i_prof.id,
                               dt_creation_in              => i_dt_creation,
                               nch_capacity_in             => i_nch_capacity,
                               action_notes_in             => i_action_notes,
                               dt_begin_action_in          => i_dt_begin_action,
                               dt_end_action_in            => i_dt_end_action,
                               flg_action_in               => i_flg_action,
                               rows_out                    => l_rows);
        
            g_error := 'PROCESS INSERT WITH ID_BMNG_ACTION ' || l_id_bmng_action;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'BMNG_ACTION', l_rows, o_error);
        
        ELSE
            -- --
            -- Update BMNG_ACTION registry to outdated
            -- --
            g_error := 'CALL TS_BMNG_ACTION.UPD WITH ID_BMNG_ACTION ' || nvl(i_id_bmng_action, l_id_bmng_action);
            pk_alertlog.log_debug(g_error);
            ts_bmng_action.upd(id_bmng_action_in => nvl(i_id_bmng_action, l_id_bmng_action),
                               flg_status_in     => pk_bmng_constant.g_bmng_act_flg_status_o,
                               rows_out          => l_rows);
        
            g_error := 'PROCESS UPDATE WITH ID_BMNG_ACTION ' || nvl(i_id_bmng_action, l_id_bmng_action);
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'BMNG_ACTION', l_rows, o_error);
            l_rows := table_varchar();
        
            -- This records information about outdated BMNG_ACTION
            l_id_bmng_action_old := l_id_bmng_action;
        
            -- --
            -- Create new BMNG_ACTION registry if applicable
            -- --
            IF i_insert_into_bmng_act = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO TS_BMNG_ACTION.NEXT_KEY';
                pk_alertlog.log_debug(g_error);
                l_id_bmng_action := ts_bmng_action.next_key;
            
                -- Get current bmng_allocation_bed information
                g_error := 'GET BMNG_ACTION RECORD FOR ID_BMNG_ACTION ' || nvl(i_id_bmng_action, l_id_bmng_action_old);
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT ba.*
                      INTO l_bmng_action
                      FROM bmng_action ba
                     WHERE ba.id_bmng_action = nvl(i_id_bmng_action, l_id_bmng_action_old);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_bmng_action.id_bmng_action := l_id_bmng_action;
                END;
            
                -- Update BMNG_ACTION.ROWTYPE with new values if applicable
                l_bmng_action.id_bmng_action           := l_id_bmng_action;
                l_bmng_action.id_department            := nvl(i_id_department, l_bmng_action.id_department);
                l_bmng_action.id_room                  := nvl(i_id_room, l_bmng_action.id_room);
                l_bmng_action.id_bed                   := nvl(i_id_bed, l_bmng_action.id_bed);
                l_bmng_action.id_bmng_reason           := i_id_bmng_reason;
                l_bmng_action.id_bmng_reason_type      := i_id_bmng_reason_type;
                l_bmng_action.id_bmng_allocation_bed   := nvl(l_id_bmng_allocation_bed,
                                                              l_bmng_action.id_bmng_allocation_bed);
                l_bmng_action.flg_target_action        := nvl(i_flg_target_action, l_bmng_action.flg_target_action);
                l_bmng_action.flg_status               := nvl(i_flg_status, l_bmng_action.flg_status);
                l_bmng_action.flg_origin_action        := nvl(i_flg_origin_action, l_bmng_action.flg_origin_action);
                l_bmng_action.flg_bed_ocupacity_status := nvl(i_flg_bed_ocupacity_stat,
                                                              l_bmng_action.flg_bed_ocupacity_status);
                l_bmng_action.flg_bed_status           := nvl(i_flg_bed_status, l_bmng_action.flg_bed_status);
                l_bmng_action.flg_bed_cleaning_status  := nvl(i_flg_bed_cleaning_stat,
                                                              l_bmng_action.flg_bed_cleaning_status);
                l_bmng_action.dt_creation              := i_dt_creation;
                l_bmng_action.nch_capacity             := i_nch_capacity;
                l_bmng_action.action_notes             := i_action_notes;
                l_bmng_action.dt_begin_action          := i_dt_begin_action;
                l_bmng_action.dt_end_action            := i_dt_end_action;
                --
                l_bmng_action.id_prof_creation := i_prof.id;
                l_bmng_action.id_cancel_reason := i_id_cancel_reason;
                l_bmng_action.flg_action       := i_flg_action;
            
                -- INSERT BMNG_ACTION REGISTRY
                g_error := 'CALL TS_BMNG_ACTION.INS WITH ID_BMNG_ACTION ' || l_bmng_action.id_bmng_action;
                pk_alertlog.log_debug(g_error);
                ts_bmng_action.ins(id_bmng_action_in           => l_bmng_action.id_bmng_action,
                                   id_department_in            => l_bmng_action.id_department,
                                   id_room_in                  => l_bmng_action.id_room,
                                   id_bed_in                   => l_bmng_action.id_bed,
                                   id_bmng_reason_in           => l_bmng_action.id_bmng_reason,
                                   id_bmng_reason_type_in      => l_bmng_action.id_bmng_reason_type,
                                   id_bmng_allocation_bed_in   => l_bmng_action.id_bmng_allocation_bed,
                                   flg_target_action_in        => l_bmng_action.flg_target_action,
                                   flg_status_in               => l_bmng_action.flg_status,
                                   flg_origin_action_in        => l_bmng_action.flg_origin_action,
                                   flg_bed_ocupacity_status_in => l_bmng_action.flg_bed_ocupacity_status,
                                   flg_bed_status_in           => l_bmng_action.flg_bed_status,
                                   flg_bed_cleaning_status_in  => l_bmng_action.flg_bed_cleaning_status,
                                   id_prof_creation_in         => l_bmng_action.id_prof_creation,
                                   dt_creation_in              => l_bmng_action.dt_creation,
                                   nch_capacity_in             => l_bmng_action.nch_capacity,
                                   action_notes_in             => l_bmng_action.action_notes,
                                   dt_begin_action_in          => l_bmng_action.dt_begin_action,
                                   dt_end_action_in            => l_bmng_action.dt_end_action,
                                   id_cancel_reason_in         => l_bmng_action.id_cancel_reason,
                                   flg_action_in               => l_bmng_action.flg_action,
                                   rows_out                    => l_rows);
            
                g_error := 'PROCESS INSERT WITH ID_BMNG_ACTION ' || l_bmng_action.id_bmng_action;
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'BMNG_ACTION', l_rows, o_error);
            
            END IF;
        END IF;
    
        -- SUCCESS
        o_id_bmng_action := nvl(l_id_bmng_action, i_id_bmng_action);
    
        IF (i_flg_action IN (pk_bmng_constant.g_bmng_flg_action_t, pk_bmng_constant.g_bmng_flg_action_p))
           OR (i_flg_action = pk_bmng_constant.g_bmng_flg_action_v AND l_id_bmng_allocation_bed IS NOT NULL)
        THEN
            g_error := 'CALL TO PK_IA_EVENT_COMMON.PATIENT_BED_OCCUPATION_UPDATE: I_ID_INSTITUTION=' ||
                       i_prof.institution || ' I_ID_BMNG_ACTION=' || i_id_bmng_action;
            pk_alertlog.log_debug(text => '*** DEBUG: *** ' || g_error);
            pk_ia_event_common.patient_bed_occupation_update(i_id_institution => i_prof.institution,
                                                             i_id_bmng_action => o_id_bmng_action);
        ELSE
            g_error := 'CALL TO PK_IA_EVENT_COMMON.PATIENT_BED_STATUS_UPDATE: I_ID_INSTITUTION=' || i_prof.institution ||
                       ' I_ID_BMNG_ACTION=' || i_id_bmng_action;
            pk_alertlog.log_debug(text => '*** DEBUG: *** ' || g_error);
            pk_ia_event_common.patient_bed_status_update(i_id_institution => i_prof.institution,
                                                         i_id_bmng_action => o_id_bmng_action);
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
                                              'SET_BMNG_ACTION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_bmng_action;

    /**********************************************************************************************
    * SET_ACTION_TIMEFRAME                   
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_dep                           Array With departments
    * @param i_begin_dts                     Array With begin dates
    * @param i_end_dts                       Array With end dates
    * @param i_nch                           Array With NCHs
    * @param o_bmng_actions                  Array with new bmng_Actions
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION set_action_timeframe
    (
        i_lang           language.id_language%TYPE,
        i_prof           IN profissional,
        i_dep            IN table_number,
        i_begin_dts      IN table_varchar,
        i_end_dts        IN table_varchar,
        i_nch            IN table_number,
        i_dt_creation    IN bmng_action.dt_creation%TYPE DEFAULT current_timestamp,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_creation       TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_origin_action bmng_action.flg_origin_action%TYPE;
        l_bmna_tmp          bmng_action.id_bmng_action%TYPE;
        --
        l_conf_cursor        pk_types.cursor_type;
        l_conf_bmna_nch      table_number;
        l_conf_bmna_dt_begin table_varchar;
        l_conf_bmna_dt_end   table_varchar;
        l_conf_bmna_dep      table_number;
        l_result             VARCHAR2(1);
        --
        l_dummy1        table_varchar := table_varchar();
        l_conf_bmna_act table_number := table_number(i_begin_dts.count);
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        l_dt_creation := nvl(i_dt_creation, current_timestamp);
        --
        g_error := 'CALL PK_BMNG.CHECK_BMNG_INTERVAL_CONFLICT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng.check_bmng_interval_conflict(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_department     => i_dep,
                                                    i_begin_date     => i_begin_dts,
                                                    i_end_date       => i_end_dts,
                                                    i_nch            => i_nch,
                                                    o_grid           => l_conf_cursor,
                                                    o_conflict_found => l_result,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- There are conflicts
        IF l_result = pk_alert_constant.g_yes
        THEN
            g_error := 'FETCH L_CONF_CURSOR WITH RETURNED CONFLICT INFORMATION';
            pk_alertlog.log_debug(g_error);
            FETCH l_conf_cursor BULK COLLECT
                INTO l_conf_bmna_dep,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     
                     l_conf_bmna_dt_begin,
                     l_conf_bmna_dt_end,
                     l_dummy1,
                     l_dummy1,
                     l_dummy1,
                     l_conf_bmna_nch,
                     l_dummy1,
                     l_dummy1,
                     l_conf_bmna_act;
            --
            CLOSE l_conf_cursor;
        ELSE
            g_error := 'THERE ARE NOT CONFLICTS';
            pk_alertlog.log_debug(g_error);
            l_conf_bmna_dep      := i_dep;
            l_conf_bmna_dt_begin := i_begin_dts;
            l_conf_bmna_dt_end   := i_end_dts;
            l_conf_bmna_nch      := i_nch;
        END IF;
    
        g_error := 'LOOP THROUGH CURSOR WITH CONFLICTS INFORMATION';
        pk_alertlog.log_debug(g_error);
        FOR l_index IN l_conf_bmna_dep.first .. l_conf_bmna_dep.last
        LOOP
            g_error := 'GET L_FLG_ORIGIN_ACTION';
            pk_alertlog.log_debug(g_error);
            l_flg_origin_action := pk_bmng_constant.g_bmng_flg_origin_ux_nt;
        
            g_error := 'CHECK IF OLD BMNG_ACTION RECORD SHOULD BE INSERTED OR ONLY OUTDATED';
            IF l_conf_bmna_dt_begin(l_index) IS NULL
            THEN
                l_result := pk_alert_constant.g_no;
            ELSE
                l_result := pk_alert_constant.g_yes;
            END IF;
        
            g_error := 'CALL SET_BMNG_ACTION WITH ID_BMNG_ACTION ' || l_conf_bmna_act(l_index) ||
                       '  i_dt_begin_Action=' || l_conf_bmna_dt_begin(l_index) || ' i_dt_end_action=' ||
                       l_conf_bmna_dt_end(l_index);
            pk_alertlog.log_debug(g_error);
            IF NOT set_bmng_action(i_lang                   => i_lang,
                                   i_prof                   => i_prof,
                                   i_id_bmng_action         => l_conf_bmna_act(l_index),
                                   i_id_department          => l_conf_bmna_dep(l_index),
                                   i_id_room                => NULL,
                                   i_id_bed                 => NULL,
                                   i_id_bmng_reason         => NULL,
                                   i_id_bmng_reason_type    => 3,
                                   i_id_bmng_allocation_bed => NULL,
                                   i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_s,
                                   i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                   i_flg_origin_action      => l_flg_origin_action,
                                   i_flg_bed_ocupacity_stat => NULL,
                                   i_flg_bed_status         => pk_bmng_constant.g_bmng_act_flg_bed_sta_n,
                                   i_flg_bed_cleaning_stat  => NULL,
                                   i_dt_creation            => l_dt_creation,
                                   i_nch_capacity           => l_conf_bmna_nch(l_index),
                                   i_action_notes           => NULL,
                                   i_dt_begin_action        => to_timestamp(l_conf_bmna_dt_begin(l_index),
                                                                            pk_alert_constant.g_dt_yyyymmddhh24miss),
                                   i_dt_end_action          => to_timestamp(l_conf_bmna_dt_end(l_index),
                                                                            pk_alert_constant.g_dt_yyyymmddhh24miss),
                                   i_id_cancel_reason       => NULL,
                                   i_flg_action             => l_flg_origin_action,
                                   i_insert_into_bmng_act   => l_result,
                                   i_transaction_id         => l_transaction_id,
                                   o_id_bmng_action         => l_bmna_tmp,
                                   o_error                  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ACTION_TIMEFRAME',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_action_timeframe;

    FUNCTION set_service_transfer
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_bed        IN bed.id_bed%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_department_orig    department.id_department%TYPE;
        l_id_dep_clin_serv_dest dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clin_serv_orig     dep_clin_serv.id_clinical_service%TYPE;
        l_id_epis_prof_resp     epis_prof_resp.id_epis_prof_resp%TYPE;
    
    BEGIN
    
        SELECT dcs.id_clinical_service, dcs.id_department
          INTO l_id_clin_serv_orig, l_id_department_orig
          FROM epis_info ei
          JOIN dep_clin_serv dcs
            ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
         WHERE id_episode = i_episode;
    
        BEGIN
            SELECT id_dep_clin_serv
              INTO l_id_dep_clin_serv_dest
              FROM dep_clin_serv dcs
             WHERE dcs.id_department = i_id_department
               AND dcs.id_clinical_service = l_id_clin_serv_orig
               AND dcs.flg_available = pk_alert_constant.g_yes;
        
        EXCEPTION
            WHEN no_data_found THEN
            
                l_id_dep_clin_serv_dest := seq_dep_clin_serv.nextval;
            
                -- insert on dep_clin_serv
                INSERT INTO dep_clin_serv
                    (id_dep_clin_serv, id_clinical_service, id_department, rank, flg_available)
                VALUES
                    (l_id_dep_clin_serv_dest, l_id_clin_serv_orig, i_id_department, 0, pk_alert_constant.g_yes);
            
        END;
    
        g_error := 'CALL PK_HAND_OFF.EXECUTE_TRANSFER_INT FOR EPISODE ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_hand_off.execute_transfer_int(i_lang               => i_lang,
                                                i_id_episode         => i_episode,
                                                i_id_patient         => i_id_patient,
                                                i_prof               => i_prof,
                                                i_id_department_orig => l_id_department_orig,
                                                i_id_department_dest => i_id_department,
                                                i_id_dep_clin_serv   => l_id_dep_clin_serv_dest,
                                                i_trf_reason         => NULL,
                                                i_id_bed             => NULL,
                                                i_dt_transfer        => NULL,
                                                o_id_epis_prof_resp  => l_id_epis_prof_resp,
                                                o_error              => o_error)
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
                                              'SET_ACTION_TIMEFRAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_service_transfer;

    /********************************************************************************************************************************************
    * SET_BED_MANAGEMENT                     Function that update an bed allocation information if that allocation exists, otherwise create one new bed allocation
    *
    * @param  I_LANG                         Language associated to the professional executing the request
    * @param  I_PROF                         Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BMNG_ACTION               Bed management action identifier
    * @param  I_ID_DEPARTMENT                Department identifier
    * @param  I_ID_ROOM                      Room identifier
    * @param  I_ID_BED                       Bed identifier
    * @param  I_ID_BMNG_REASON               Reason identifier associated with current action
    * @param  I_ID_BMNG_ALLOCATION_BED       Bed management allocation identifier that should be updated or created in this function
    * @param  I_FLG_TARGET_ACTION            Target of current action: (''S''- Service/ward; ''R''- Room; ''B''- Bed)
    * @param  I_FLG_STATUS                   Action current state: (''A''- Active; ''C''- Cancelled; ''O''- Outdated) (DEFAULT: ''A'')
    * @param  I_NCH_CAPACITY                 NCH associated (in tools and backoffice) to institution services (only used in service actions)
    * @param  I_ACTION_NOTES                 Notes written by professional when creating current registry
    * @param  I_DT_BEGIN_ACTION              Date in which this action start counting
    * @param  I_DT_END_ACTION                Date in which this action became outdated
    * @param  I_ID_EPISODE                   Episode identifier
    * @param  I_ID_PATIENT                   Patient identifier
    * @param  I_NCH_HOURS                    Number of NCH associated with current allocation
    * @param  I_FLG_ALLOCATION_NCH           Is this NCH information definitive or automatically updated with NCH_LEVEL information (''D''- Definitive; ''U''- Updatable)
    * @param  I_DESC_BED                     Description associated with this bed
    * @param  I_ID_BED_TYPE                  Bed type identifier of this bed
    * @param  I_DT_DICHARGE_SCHEDULE         Episode expected discharge
    * @param  I_FLG_ORIGIN_ACTION_UX         Type of action: FLAG defined in flash layer
    * @param  i_transaction_id               remote transaction identifier
    * @param  i_allocation_commit            Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param  i_flg_allow_bed_alloc_inactive Flag to control the allocation of beds for inactive episodes (Y/N). (Used by interfaces)
    * @param  O_ID_BMNG_ALLOCATION_BED       Return allocation identifier if one patient is allocated to a new bed
    * @param  O_ID_BED                       Return bed identifier
    * @param  O_BED_ALLOCATION               Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param  O_EXCEPTION_INFO               Error message to be displayed to the user.
    * @param  O_ERROR                        If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_TARGET_ACTION            {*} 'S'- Service {*} 'R'- Room {*} 'B'- Bed
    * @value  I_FLG_STATUS                   {*} 'A'- Active {*} 'C'- Cancelled {*} 'O'- Outdated
    * @value  I_FLG_ALLOCATION_NCH           {*} 'D'- Definitive {*} 'U'- Updatable
    * @value  I_FLG_ORIGIN_ACTION_UX         {*} 'B'-  BLOCK
    *                                        {*} 'U'-  UNBLOCK
    *                                        {*} 'V'-  FREE      
    *                                        {*} 'O'-  OCCUPY (desreservar)
    *                                        {*} 'T'-  OCCUPY TEMPORARY BED (allocate / re-allocate)
    *                                        {*} 'P'-  OCCUPY DEFINITIVE BED (allocate / re-allocate)
    *                                        {*} 'S'-  SCHEDULE
    *                                        {*} 'R'-  RESERVE
    *                                        {*} 'D'-  DIRTY
    *                                        {*} 'C'-  CONTAMINED
    *                                        {*} 'I'-  CLEANING IN PROCESS
    *                                        {*} 'L'-  CLEANING CONCLUDED
    *                                        {*} 'E'-  EDIT BED ASSIGNMENT
    *                                        {*} 'ND'- UPDATE NCH PATIENT (DIRECTLY IN GRID)
    *                                        {*} 'NT'- NCH TOOLS
    *                                        {*} 'BT'- BLOCK TOOLS
    *                                        {*} 'UT'- UNBLOCK TOOLS
    * 
    * @return                                Returns TRUE if success, otherwise returns FALSE
    * @raises                                PL/SQL generic erro "OTHERS"
    *
    * @author                                Luís Maia
    * @version                               2.5.0.5
    * @since                                 2009/07/22
    *******************************************************************************************************************************************/
    FUNCTION set_bed_management
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_bmng_action               IN bmng_action.id_bmng_action%TYPE,
        i_id_department                IN bmng_action.id_department%TYPE,
        i_id_room                      IN bmng_action.id_room%TYPE,
        i_id_bed                       IN bmng_action.id_bed%TYPE,
        i_id_bmng_reason               IN bmng_action.id_bmng_reason%TYPE,
        i_id_bmng_allocation_bed       IN bmng_action.id_bmng_allocation_bed%TYPE,
        i_flg_target_action            IN bmng_action.flg_target_action%TYPE,
        i_flg_status                   IN bmng_action.flg_status%TYPE, --10
        i_nch_capacity                 IN bmng_action.nch_capacity%TYPE,
        i_action_notes                 IN bmng_action.action_notes%TYPE,
        i_dt_begin_action              IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end_action                IN bmng_action.dt_end_action%TYPE,
        i_id_episode                   IN bmng_allocation_bed.id_episode%TYPE,
        i_id_patient                   IN bmng_allocation_bed.id_patient%TYPE,
        i_nch_hours                    IN epis_nch.nch_value%TYPE,
        i_flg_allocation_nch           IN epis_nch.flg_type%TYPE,
        i_desc_bed                     IN bed.desc_bed%TYPE,
        i_id_bed_type                  IN bed.id_bed_type%TYPE, --20
        i_dt_discharge_schedule        IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_flg_hour_origin              IN VARCHAR2 DEFAULT 'DH',
        i_id_bed_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_origin_action_ux         IN VARCHAR2,
        i_reason_notes                 IN epis_nch.reason_notes%TYPE,
        i_transaction_id               IN VARCHAR2,
        i_allocation_commit            IN VARCHAR2,
        i_dt_creation                  IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_id_bmng_allocation_bed       OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed                       OUT bed.id_bed%TYPE,
        o_bed_allocation               OUT VARCHAR2, --30
        o_exception_info               OUT sys_message.desc_message%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        --
        l_insert_into_bmng_action    VARCHAR2(1) := pk_alert_constant.g_yes;
        l_insert_into_bmng_alloc_bed VARCHAR2(1) := pk_alert_constant.g_no;
        l_insert_into_bed            VARCHAR2(1) := pk_alert_constant.g_no;
        --
        l_bed_new_status         VARCHAR2(1);
        l_bed_new_type           VARCHAR2(1);
        l_set_id_bed             bed.id_bed%TYPE;
        l_flg_new_alloc_reg_need VARCHAR2(1);
        l_set_id_allocation_bed  bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_set_id_action          bmng_action.id_bmng_action%TYPE;
        --
        l_dt_creation            TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_bed_ocupacity_stat bmng_action.flg_bed_ocupacity_status%TYPE;
        l_flg_bed_status         bmng_action.flg_bed_status%TYPE;
        l_flg_bed_cleaning_stat  bmng_action.flg_bed_cleaning_status%TYPE;
        l_allocation_notes       bmng_allocation_bed.allocation_notes%TYPE := i_action_notes;
        l_bed_notes              bed.notes%TYPE := NULL;
        l_dt_begin_nch           epis_nch.dt_begin%TYPE;
        l_dt_end_nch             epis_nch.dt_end%TYPE;
        l_id_bmng_reason_type    bmng_action.id_bmng_reason_type%TYPE;
        l_flg_origin_action      bmng_action.flg_origin_action%TYPE;
        l_id_discharge_schedule  discharge_schedule.id_discharge_schedule%TYPE;
        l_dt_discharge_schedule  discharge_schedule.dt_discharge_schedule%TYPE;
        l_id_epis_nch            epis_nch.id_epis_nch%TYPE;
        l_flg_type               epis_nch.flg_type%TYPE;
        l_id_nch_level           epis_nch.id_nch_level%TYPE;
        l_nch_value              epis_nch.nch_value%TYPE;
        l_bed_flg_status         bed.flg_status%TYPE;
        l_bed_flg_type           bed.flg_type%TYPE;
        l_bed_new_availability   bed.flg_available%TYPE;
        --
        l_id_cancel_reason    bmng_reason.id_bmng_reason%TYPE;
        l_id_bmng_reason      bmng_reason.id_bmng_reason%TYPE;
        l_realocate_patient   VARCHAR2(1) := pk_alert_constant.g_no;
        l_flg_discharge_alloc VARCHAR2(1) := pk_alert_constant.g_no;
        --
        l_bmng_action_start_date bmng_action.dt_begin_action%TYPE;
        l_bmng_action_end_date   bmng_action.dt_end_action%TYPE;
        l_exception_info         VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T114');
        l_internal_error         EXCEPTION;
        l_bed_unavailable        EXCEPTION;
    
        l_dt_allocation_bed TIMESTAMP WITH LOCAL TIME ZONE;
        l_reserved_bed      VARCHAR2(1) := pk_alert_constant.g_no;
        l_rowids            table_varchar;
    
        l_validate_pat_dept NUMBER;
        l_pat_age           NUMBER;
        l_pat_gender        VARCHAR2(2 CHAR);
    
        l_epis_flg_status episode.flg_status%TYPE;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := '[PK_BMNG_CORE.SET_BED_MANAGEMENT] i_id_episode=' || i_id_episode || ' i_id_bed=' || i_id_bed ||
                   ' i_id_bmng_action=' || i_id_bmng_action || ' i_id_department=' || i_id_department || ' i_id_room=' ||
                   i_id_room || ' i_id_bed=' || i_id_bed || ' i_id_bmng_reason=' || i_id_bmng_reason ||
                   ' i_id_bmng_allocation_bed=' || i_id_bmng_allocation_bed || ' i_flg_target_action=' ||
                   i_flg_target_action || ' i_flg_status=' || i_flg_status || ' i_nch_capacity=' || i_nch_capacity ||
                   ' i_action_notes=' || i_action_notes || ' i_dt_begin_action=' || CAST(i_dt_begin_action AS VARCHAR2) ||
                   ' i_dt_end_action=' || CAST(i_dt_end_action AS VARCHAR2) || ' i_id_episode=' || i_id_episode ||
                   ' i_id_patient=' || i_id_patient || ' i_nch_hours=' || i_nch_hours || ' i_flg_allocation_nch=' ||
                   i_flg_allocation_nch || ' i_desc_bed=' || i_desc_bed || ' i_id_bed_type=' || i_id_bed_type ||
                   ' i_dt_discharge_schedule=' || CAST(i_dt_discharge_schedule AS VARCHAR2) || ' i_flg_hour_origin=' ||
                   i_flg_hour_origin || ' i_id_bed_dep_clin_serv=' || i_id_bed_dep_clin_serv ||
                   ' i_flg_origin_action_ux=' || i_flg_origin_action_ux || ' i_reason_notes=' || i_reason_notes ||
                   ' i_allocation_commit=' || i_allocation_commit || ' i_dt_creation=' || i_dt_creation;
        pk_alertlog.log_debug(g_error);
    
        -- Initialize variable
        o_bed_allocation := pk_alert_constant.g_yes;
        o_exception_info := NULL;
    
        g_sysdate_tstz := current_timestamp;
        l_dt_creation  := nvl(i_dt_creation, g_sysdate_tstz);
    
        --Check if the allocation request has permissions to allocate a bed for an Inactive episode
        --i_flg_allow_bed_alloc_inactive is sent as 'N' when comming from inter_alert, and, when comming from there,
        --it should NOT be possible to allocate a bed for inactive episodes [EMR-3420]
        IF i_flg_allow_bed_alloc_inactive = pk_alert_constant.g_no
        THEN
            g_error := 'EPISODE IS INACTIVE OR CANCELED';
            pk_alertlog.log_debug(g_error);
        
            IF i_flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
            THEN
                SELECT e.flg_status
                  INTO l_epis_flg_status
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                IF l_epis_flg_status IN
                   (pk_alert_constant.g_epis_status_inactive, pk_alert_constant.g_epis_status_cancel)
                THEN
                    o_bed_allocation := pk_alert_constant.g_no;
                    o_exception_info := pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T115');
                    RETURN TRUE;
                END IF;
            END IF;
        END IF;
    
        g_error := 'GET L_DT_DISCHARGE_SCHEDULE';
        BEGIN
            SELECT t.dt_discharge_schedule
              INTO l_dt_discharge_schedule
              FROM (SELECT ds.dt_discharge_schedule,
                           row_number() over(PARTITION BY ds.id_episode ORDER BY ds.create_time DESC) rn
                      FROM discharge_schedule ds
                     WHERE ds.id_episode = i_id_episode
                       AND ds.flg_status = pk_alert_constant.g_yes) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_discharge_schedule := NULL;
        END;
    
        g_error := '[PK_BMNG_CORE.SET_BED_MANAGEMENT] l_dt_creation=' || l_dt_creation || ' l_dt_discharge_schedule=' ||
                   l_dt_discharge_schedule;
        pk_alertlog.log_debug(g_error);
    
        IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
           OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
        THEN
            --get the blocking begin and end date to send to the new scheduler in the unblocking action
            IF NOT get_bmng_action_dt(i_lang                   => i_lang,
                                      i_prof                   => i_prof,
                                      i_id_bed                 => i_id_bed,
                                      o_bmng_action_start_date => l_bmng_action_start_date,
                                      o_bmng_action_end_date   => l_bmng_action_end_date,
                                      o_error                  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_bmng_action_end_date := nvl(nvl(l_bmng_action_end_date, i_dt_discharge_schedule), l_dt_discharge_schedule);
        ELSE
            l_bmng_action_start_date := i_dt_begin_action;
            l_bmng_action_end_date   := nvl(nvl(i_dt_end_action, i_dt_discharge_schedule), l_dt_discharge_schedule);
        END IF;
    
        g_error := '[PK_BMNG_CORE.SET_BED_MANAGEMENT] l_bmng_action_start_date=' ||
                   CAST(l_bmng_action_start_date AS VARCHAR2) || ' l_bmng_action_end_date=' ||
                   CAST(l_bmng_action_end_date AS VARCHAR2);
        pk_alertlog.log_debug(g_error);
    
        IF i_flg_origin_action_ux IN
           (pk_bmng_constant.g_bmng_flg_origin_ux_p, pk_bmng_constant.g_bmng_flg_origin_ux_ps)
        THEN
        
            --Validate that select department can handle with this patient
        
            l_pat_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                i_dt_birth    => NULL,
                                                i_dt_deceased => NULL,
                                                i_age         => NULL,
                                                i_patient     => i_id_patient);
        
            l_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_id_patient);
        
            SELECT COUNT(*)
              INTO l_validate_pat_dept
              FROM department d
             WHERE (d.adm_age_min IS NULL OR (d.adm_age_min IS NOT NULL AND d.adm_age_min <= l_pat_age) OR
                   l_pat_age IS NULL)
               AND (d.adm_age_max IS NULL OR (d.adm_age_max IS NOT NULL AND d.adm_age_max >= l_pat_age) OR
                   l_pat_age IS NULL)
               AND ((d.gender IS NOT NULL AND d.gender <> l_pat_gender) OR d.gender IS NULL)
               AND d.id_department = i_id_department;
        
            IF l_validate_pat_dept = 0
            THEN
                g_error          := 'THIS PATIENT CANNOT ASSIGNED TO THIS DEPARTMENT';
                o_exception_info := pk_message.get_message(i_lang => i_lang, i_code_mess => 'BMNG_M022');
                o_bed_allocation := pk_alert_constant.g_no;
                RETURN FALSE;
            END IF;
        
            -- Validate that selected bed keeps available
            g_error := 'GET BED ' || i_id_bed || ' STATUS AND TYPE';
            pk_alertlog.log_debug(g_error);
            IF NOT get_bed_status(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_id_bed         => i_id_bed,
                                  o_bed_flg_status => l_bed_flg_status,
                                  o_bed_flg_type   => l_bed_flg_type,
                                  o_error          => o_error)
            THEN
                g_error := 'CANNOT CONTINUE SELECTED BED IS UNAVAILABLE';
                RAISE l_bed_unavailable;
            END IF;
        
            g_error := '[PK_BMNG_CORE.SET_BED_MANAGEMENT] l_bed_flg_status=' || l_bed_flg_status || ' l_bed_flg_type=' ||
                       l_bed_flg_type;
            pk_alertlog.log_debug(g_error);
        
            --
            -- Only Permanent Bed's are validated because temporary beds can only be used one time in their life
            IF l_bed_flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
            THEN
                IF l_bed_flg_status = pk_bmng_constant.g_bmng_bed_flg_status_o
                THEN
                    -- Returns because it is not possible allocate current bed
                    g_error := 'SELECTED BED IS ALREADY ALLOCATED (ID_BED = ' || i_id_bed;
                    pk_alertlog.log_debug(g_error);
                    --
                    o_bed_allocation := pk_alert_constant.g_no;
                    o_exception_info := l_exception_info;
                    --
                    RETURN FALSE;
                ELSE
                    g_error := 'SELECTED BED IS AVAILABLE (ID_BED = ' || i_id_bed;
                    pk_alertlog.log_debug(g_error);
                    --
                    o_bed_allocation := pk_alert_constant.g_yes;
                    o_exception_info := NULL;
                END IF;
            END IF;
        
        END IF;
        -- END
    
        --
        g_error := 'INITIALIZE SOME VARIABLES';
        pk_alertlog.log_debug(g_error);
        IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
           OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
           OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
           OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ps
           OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_o
        THEN
            l_insert_into_bmng_alloc_bed := pk_alert_constant.g_yes;
            l_insert_into_bed            := pk_alert_constant.g_yes;
        ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_e
        THEN
            l_insert_into_bmng_alloc_bed := pk_alert_constant.g_yes;
            l_insert_into_bed            := pk_alert_constant.g_no;
        ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
              OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
        THEN
            l_insert_into_bmng_alloc_bed := pk_alert_constant.g_no;
            l_insert_into_bed            := pk_alert_constant.g_yes;
        ELSE
            -- IF i_flg_origin_action_ux with values (O, R, D, C, I, L, NT, BT)
            l_insert_into_bmng_alloc_bed := pk_alert_constant.g_no;
            l_insert_into_bed            := pk_alert_constant.g_no;
        END IF;
    
        g_error := '[PK_BMNG_CORE.SET_BED_MANAGEMENT] l_insert_into_bmng_alloc_bed=' || l_insert_into_bmng_alloc_bed ||
                   ' l_insert_into_bed=' || l_insert_into_bed;
        pk_alertlog.log_debug(g_error);
    
        -- OPERATIONS IN TABLE BED
        g_error := 'START OPERATIONS IN TABLE BED';
        pk_alertlog.log_debug(g_error);
        IF l_insert_into_bed = pk_alert_constant.g_yes
        THEN
            -- Get future bed state
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
            THEN
                -- Get bed type (temporary or definitive)
                BEGIN
                    SELECT b.flg_type
                      INTO l_bed_flg_type
                      FROM bed b
                     WHERE b.id_bed = i_id_bed;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_bed_flg_type := NULL;
                END;
            
                -- If release one temporary bed, this bed should became inactive
                IF l_bed_flg_type = pk_bmng_constant.g_bmng_bed_flg_type_t
                THEN
                    l_bed_new_availability := pk_alert_constant.g_no;
                END IF;
                --
                l_bed_new_status := pk_bmng_constant.g_bmng_bed_flg_status_v;
            
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
            THEN
                l_bed_new_status := pk_bmng_constant.g_bmng_bed_flg_status_o;
                l_bed_new_type   := pk_bmng_constant.g_bmng_bed_flg_type_t;
            ELSE
                l_bed_new_status := pk_bmng_constant.g_bmng_bed_flg_status_o;
                l_bed_new_type   := pk_bmng_constant.g_bmng_bed_flg_type_p;
            END IF;
        
            -- CALL TO SET_BED
            g_error := 'CALL SET_BED WITH ID_BED ' || i_id_bed;
            pk_alertlog.log_debug(g_error);
            IF NOT set_bed(i_lang           => i_lang,
                           i_prof           => i_prof,
                           i_id_bed         => i_id_bed,
                           i_flg_type       => l_bed_new_type,
                           i_flg_status     => l_bed_new_status,
                           i_flg_avail      => l_bed_new_availability,
                           i_desc_bed       => i_desc_bed,
                           i_id_bed_type    => i_id_bed_type,
                           i_id_room        => i_id_room,
                           i_notes          => l_bed_notes,
                           i_dt_creation    => l_dt_creation,
                           i_transaction_id => l_transaction_id,
                           o_id_bed         => l_set_id_bed,
                           o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- This function is only invoked when creating an temporary bed
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
               AND i_id_bed_dep_clin_serv IS NOT NULL
            THEN
                -- Associate dep_clin_serv's to an temporary bed
                g_error := 'CALL CREATE_BED_DEP_CLIN_SERV WITH ID_BED ' || l_set_id_bed || ' AND ID_DEP_CLIN_SERV ' ||
                           i_id_bed_dep_clin_serv;
                pk_alertlog.log_debug(g_error);
                IF NOT create_bed_dep_clin_serv(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_bed           => l_set_id_bed,
                                                i_id_dep_clin_serv => i_id_bed_dep_clin_serv,
                                                i_flg_available    => pk_alert_constant.g_yes,
                                                o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- transfer patient from service
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ps
            THEN
                --          pk_hand_off.execute_transfer_int
                IF NOT pk_bmng_core.set_service_transfer(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_episode       => i_id_episode,
                                                         i_id_patient    => i_id_patient,
                                                         i_id_bed        => l_set_id_bed,
                                                         i_id_department => i_id_department,
                                                         o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
        END IF;
    
        -- OPERATIONS IN TABLE EPIS_NCH
        g_error := 'START OPERATIONS IN TABLE EPIS_NCH';
        pk_alertlog.log_debug(g_error);
        IF l_insert_into_bmng_alloc_bed = pk_alert_constant.g_yes
        THEN
            -- Get type of NCH allocation
            IF i_flg_allocation_nch = pk_bmng_constant.g_bmng_flg_origin_ux_u
            THEN
                l_dt_begin_nch := l_dt_creation;
                l_dt_end_nch   := NULL;
                l_flg_type     := 'T';
            ELSIF i_flg_allocation_nch = pk_bmng_constant.g_bmng_flg_origin_ux_d
            THEN
                l_dt_begin_nch := l_dt_creation;
                l_dt_end_nch   := NULL;
                l_flg_type     := 'D';
            ELSE
                l_dt_begin_nch := l_dt_creation;
                l_dt_end_nch   := NULL;
                l_flg_type     := 'D';
            END IF;
        
            -- Operations inside EPIS_NCH
            IF i_nch_hours IS NOT NULL
            THEN
                -- GET EPIS_NCH INFORMATION
                g_error := 'CALL PK_API_ADM_REQUEST.GET_EPIS_NCH_LEVEL WITH ID_EPISODE ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_nch_pbl.get_epis_nch_level(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_episode   => i_id_episode,
                                                     o_nch_value    => l_nch_value,
                                                     o_id_nch_level => l_id_nch_level,
                                                     o_id_epis_nch  => l_id_epis_nch,
                                                     o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'CALL TO FUNCTION SET_EPIS_NCH WITH ID_EPIS_NCH ' || l_id_epis_nch || ' AND NCH_VALUE ' ||
                           i_nch_hours;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_nch_pbl.set_epis_nch(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_epis_nch  => l_id_epis_nch,
                                               i_id_episode   => i_id_episode,
                                               i_id_patient   => i_id_patient,
                                               i_nch_value    => i_nch_hours,
                                               i_dt_begin     => l_dt_begin_nch,
                                               i_dt_end       => l_dt_end_nch,
                                               i_flg_status   => pk_alert_constant.g_active,
                                               i_flg_type     => l_flg_type,
                                               i_dt_creation  => l_dt_creation,
                                               i_id_nch_level => l_id_nch_level,
                                               i_reason_notes => i_reason_notes,
                                               o_id_epis_nch  => l_id_epis_nch,
                                               o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        -- OPERATIONS IN TABLE BMNG_ALLOCATION_BED
        g_error := 'START OPERATIONS IN TABLE BMNG_ALLOCATION_BED';
        pk_alertlog.log_debug(g_error);
        IF l_insert_into_bmng_alloc_bed = pk_alert_constant.g_yes
        THEN
            -- Get if episode already has an ocuppied bed
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ps
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_o
            THEN
                BEGIN
                    SELECT decode(COUNT(bab.id_bmng_allocation_bed), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
                      INTO l_realocate_patient
                      FROM bmng_allocation_bed bab
                     INNER JOIN bmng_action ba
                        ON (ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed AND
                           ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n AND
                           ba.flg_status = pk_alert_constant.g_active)
                     WHERE bab.id_episode = i_id_episode
                       AND bab.flg_outdated = pk_alert_constant.g_no;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_realocate_patient := pk_alert_constant.g_no;
                END;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_e
            THEN
                BEGIN
                    SELECT decode(COUNT(bab.id_bmng_allocation_bed), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
                      INTO l_reserved_bed
                      FROM bmng_allocation_bed bab
                     INNER JOIN bmng_action ba
                        ON (ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed AND
                           ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_r AND
                           ba.flg_status = pk_alert_constant.g_active)
                     WHERE bab.id_episode = i_id_episode
                       AND bab.flg_outdated = pk_alert_constant.g_yes;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_reserved_bed := pk_alert_constant.g_no;
                END;
            END IF;
        
            -- Get if current action should create a new allocation registry
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ps
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_e
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_nd
            THEN
                l_flg_new_alloc_reg_need := pk_alert_constant.g_yes;
            ELSE
                --i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
                l_flg_new_alloc_reg_need := pk_alert_constant.g_no;
            END IF;
        
            --l_flg_discharge_alloc
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
            THEN
                l_flg_discharge_alloc := pk_alert_constant.g_yes;
            ELSE
                l_flg_discharge_alloc := pk_alert_constant.g_no;
            END IF;
        
            g_error := '[PK_BMNG_CORE.SET_BED_MANAGEMENT] l_realocate_patient=' || l_realocate_patient ||
                       ' l_flg_new_alloc_reg_need=' || l_flg_new_alloc_reg_need || ' l_flg_discharge_alloc=' ||
                       l_flg_discharge_alloc;
            pk_alertlog.log_debug(g_error);
        
            -- CALL TO SET_BMNG_ALLOCATION_BED
            g_error := 'CALL SET_BMNG_ALLOCATION_BED WITH ID_BMNG_ALLOCATION_BED ' || i_id_bmng_allocation_bed;
            pk_alertlog.log_debug(g_error);
            IF NOT set_bmng_allocation_bed(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_id_bmng_allocation_bed => i_id_bmng_allocation_bed,
                                           i_id_episode             => i_id_episode,
                                           i_id_patient             => i_id_patient,
                                           i_id_bed                 => nvl(l_set_id_bed, i_id_bed),
                                           i_allocation_notes       => l_allocation_notes,
                                           i_id_room                => i_id_room,
                                           i_dt_creation            => l_dt_creation,
                                           i_dt_release             => l_dt_creation,
                                           i_flg_create_new_reg     => l_flg_new_alloc_reg_need,
                                           i_realocate_patient      => l_realocate_patient,
                                           i_flg_discharge_alloc    => l_flg_discharge_alloc,
                                           i_id_epis_nch            => l_id_epis_nch,
                                           i_transaction_id         => l_transaction_id,
                                           i_reserved_bed           => l_reserved_bed,
                                           i_flg_origin_action_ux   => CASE i_flg_origin_action_ux
                                                                           WHEN pk_bmng_constant.g_bmng_flg_origin_ux_ps THEN
                                                                            pk_bmng_constant.g_bmng_flg_origin_ux_p
                                                                           ELSE
                                                                            i_flg_origin_action_ux
                                                                       END,
                                           o_id_bmng_allocation_bed => l_set_id_allocation_bed,
                                           o_error                  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            o_id_bmng_allocation_bed := l_set_id_allocation_bed;
            o_id_bed                 := nvl(l_set_id_bed, i_id_bed);
        
        ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_r
        THEN
            IF NOT set_bmng_allocation_bed(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_id_bmng_allocation_bed => i_id_bmng_allocation_bed,
                                           i_id_episode             => i_id_episode,
                                           i_id_patient             => i_id_patient,
                                           i_id_bed                 => nvl(l_set_id_bed, i_id_bed),
                                           i_allocation_notes       => l_allocation_notes,
                                           i_id_room                => i_id_room,
                                           i_dt_creation            => l_dt_creation,
                                           i_dt_release             => l_dt_creation,
                                           i_flg_create_new_reg     => l_flg_new_alloc_reg_need,
                                           i_realocate_patient      => l_realocate_patient,
                                           i_flg_discharge_alloc    => l_flg_discharge_alloc,
                                           i_id_epis_nch            => l_id_epis_nch,
                                           i_transaction_id         => l_transaction_id,
                                           o_id_bmng_allocation_bed => l_set_id_allocation_bed,
                                           o_error                  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF (i_id_episode IS NULL AND i_flg_origin_action_ux IN
           (pk_bmng_constant.g_bmng_flg_origin_ux_o, pk_bmng_constant.g_bmng_flg_origin_ux_r))
        THEN
            g_error := 'It is not possible to execute this action without an id_episode. i_flg_origin_action_ux: ' ||
                       i_flg_origin_action_ux;
            pk_alertlog.log_debug(g_error);
            RAISE l_internal_error;
        END IF;
    
        -- OPERATIONS IN TABLE BMNG_ACTION
        g_error := 'START OPERATIONS IN TABLE BMNG_ACTION';
        pk_alertlog.log_debug(g_error);
        IF l_insert_into_bmng_action = pk_alert_constant.g_yes
        THEN
            --
            g_error := 'GET L_FLG_BED_OCUPACITY_STATUS';
            pk_alertlog.log_debug(g_error);
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
            THEN
                l_flg_bed_ocupacity_stat := pk_bmng_constant.g_bmng_act_flg_ocupaci_v;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_o
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ps
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_r
            THEN
                l_flg_bed_ocupacity_stat := pk_bmng_constant.g_bmng_act_flg_ocupaci_o;
            ELSE
                l_flg_bed_ocupacity_stat := NULL;
            END IF;
        
            --
            g_error := 'GET L_FLG_BED_STATUS';
            pk_alertlog.log_debug(g_error);
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_r
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_s
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
            THEN
                l_flg_bed_status := i_flg_origin_action_ux;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_o
            THEN
                l_flg_bed_status := pk_bmng_constant.g_bmng_act_flg_bed_sta_n;
            ELSE
                l_flg_bed_status := NULL;
            END IF;
        
            --
            g_error := 'GET L_FLG_BED_CLEANING_STAT';
            pk_alertlog.log_debug(g_error);
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_d
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_c
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_i
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_l
            THEN
                l_flg_bed_cleaning_stat := i_flg_origin_action_ux;
            ELSE
                l_flg_bed_cleaning_stat := NULL;
            END IF;
        
            g_error := 'GET L_ID_BMNG_REASON_TYPE';
            pk_alertlog.log_debug(g_error);
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
            THEN
                l_id_bmng_reason_type := 4;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_v
            THEN
                l_id_bmng_reason_type := 5;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_o
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_t
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_p
                  OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ps
            THEN
                l_id_bmng_reason_type := 8;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_r
            THEN
                l_id_bmng_reason_type := 7;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_d
            THEN
                l_id_bmng_reason_type := 9;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_c
            THEN
                l_id_bmng_reason_type := 10;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_i
            THEN
                l_id_bmng_reason_type := 11;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_l
            THEN
                l_id_bmng_reason_type := 12;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_e
            THEN
                l_id_bmng_reason_type := 13;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_nt
            THEN
                l_id_bmng_reason_type := 3;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_bt
            THEN
                l_id_bmng_reason_type := 1;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_nd
            THEN
                l_id_bmng_reason_type := 6;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_ut
            THEN
                l_id_bmng_reason_type := 2;
            END IF;
        
            g_error := 'GET L_FLG_ORIGIN_ACTION';
            pk_alertlog.log_debug(g_error);
            IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_nb
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_nt
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_nd
               OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_bt
            THEN
                l_flg_origin_action := i_flg_origin_action_ux;
            ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
            THEN
                l_flg_origin_action := pk_bmng_constant.g_bmng_act_flg_origin_bd;
            ELSE
                l_flg_origin_action := pk_bmng_constant.g_bmng_act_flg_origin_od;
            END IF;
        
            -- IF new status is canceled, it should registry cancel_reason in ID_CANCEL_REASON column instead of ID_BMNG_REASON
            g_error := 'GET ID_CANCEL_REASON ' || i_id_bmng_reason;
            pk_alertlog.log_debug(g_error);
            IF i_flg_status = pk_bmng_constant.g_bmng_act_flg_status_c
            THEN
                l_id_cancel_reason := i_id_bmng_reason;
                l_id_bmng_reason   := NULL;
            ELSE
                -- Record reason in column ID_BMNG_REASON
                l_id_bmng_reason := i_id_bmng_reason;
            END IF;
        
            --
            -- CALL TO SET_BMNG_ACTION
            IF l_flg_origin_action = i_flg_origin_action_ux
               AND i_id_bmng_action IS NULL
            THEN
                g_error := 'START OPERATIONS WITH TIMEFRAMES';
                pk_alertlog.log_debug(g_error);
                --
                g_error := 'CALL SET_ACTION_TIMEFRAME WITH ID_DEPARTMENT ' || i_id_department;
                pk_alertlog.log_debug(g_error);
                IF NOT set_action_timeframe(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_dep            => table_number(i_id_department),
                                            i_begin_dts      => table_varchar(pk_date_utils.to_char_timezone(i_lang,
                                                                                                             i_dt_begin_action,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss)),
                                            i_end_dts        => table_varchar(pk_date_utils.to_char_timezone(i_lang,
                                                                                                             i_dt_end_action,
                                                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss)),
                                            i_nch            => table_number(i_nch_capacity),
                                            i_dt_creation    => l_dt_creation,
                                            i_transaction_id => l_transaction_id,
                                            o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            ELSE
                --
                g_error := 'CALL TO SET_BMNG_ACTION WITH ID_BMNG_ACTION ' || i_id_bmng_action;
                pk_alertlog.log_debug(g_error);
                IF NOT set_bmng_action(i_lang                   => i_lang,
                                       i_prof                   => i_prof,
                                       i_id_bmng_action         => i_id_bmng_action,
                                       i_id_department          => i_id_department,
                                       i_id_room                => i_id_room,
                                       i_id_bed                 => nvl(i_id_bed, l_set_id_bed),
                                       i_id_bmng_reason         => l_id_bmng_reason,
                                       i_id_bmng_reason_type    => l_id_bmng_reason_type,
                                       i_id_bmng_allocation_bed => nvl(l_set_id_allocation_bed, i_id_bmng_allocation_bed),
                                       i_flg_target_action      => i_flg_target_action,
                                       i_flg_status             => i_flg_status,
                                       i_flg_origin_action      => l_flg_origin_action,
                                       i_flg_bed_ocupacity_stat => l_flg_bed_ocupacity_stat,
                                       i_flg_bed_status         => l_flg_bed_status,
                                       i_flg_bed_cleaning_stat  => l_flg_bed_cleaning_stat,
                                       i_dt_creation            => l_dt_creation,
                                       i_nch_capacity           => i_nch_capacity,
                                       i_action_notes           => i_action_notes,
                                       i_dt_begin_action        => nvl(i_dt_begin_action, l_dt_creation),
                                       i_dt_end_action          => i_dt_end_action,
                                       i_id_cancel_reason       => l_id_cancel_reason,
                                       i_flg_action             => i_flg_origin_action_ux,
                                       i_insert_into_bmng_act   => pk_alert_constant.g_yes,
                                       i_transaction_id         => l_transaction_id,
                                       o_id_bmng_action         => l_set_id_action,
                                       o_error                  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'GET L_FLG_BED_CLEANING_STAT';
                pk_alertlog.log_debug(g_error);
                IF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_d
                   OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_c
                   OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_i
                   OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_l
                  --
                   OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_b
                   OR i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_u
                THEN
                    --
                    g_error := 'CALL TO set_notify_inter_alert: id_episode = ' || i_id_episode;
                    pk_alertlog.log_debug(g_error);
                    IF NOT set_notify_inter_alert(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_episode     => i_id_episode,
                                                  i_id_bmng_action => l_set_id_action,
                                                  i_allocation     => pk_alert_constant.g_no,
                                                  o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSIF i_flg_origin_action_ux = pk_bmng_constant.g_bmng_flg_origin_ux_o
                THEN
                    IF i_id_episode IS NOT NULL
                    THEN
                        --
                        g_error := 'CALL TO ts_epis_info.upd: id_episode = ' || i_id_episode || ' i_id_bed = ' ||
                                   i_id_bed;
                        pk_alertlog.log_debug(g_error);
                        l_rowids := table_varchar();
                        ts_epis_info.upd(id_episode_in => i_id_episode,
                                         id_bed_in     => i_id_bed,
                                         id_bed_nin    => FALSE,
                                         rows_out      => l_rowids);
                    
                        t_data_gov_mnt.process_update(i_lang,
                                                      i_prof,
                                                      'EPIS_INFO',
                                                      l_rowids,
                                                      o_error,
                                                      table_varchar('ID_BED'));
                    END IF;
                END IF;
            
                o_id_bed := nvl(l_set_id_bed, i_id_bed);
            END IF;
        
        END IF;
    
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_dt_begin_action,
                                      i_dt_first_obs        => i_dt_begin_action,
                                      o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (l_bed_flg_type IS NULL)
        THEN
            -- Validate that selected bed keeps available
            g_error := 'GET BED ' || i_id_bed || ' STATUS AND TYPE';
            pk_alertlog.log_debug(g_error);
            IF NOT get_bed_status(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_id_bed         => i_id_bed,
                                  o_bed_flg_status => l_bed_flg_status,
                                  o_bed_flg_type   => l_bed_flg_type,
                                  o_error          => o_error)
            THEN
                NULL;
            END IF;
        END IF;
    
        g_error := 'BEFORE PK_BMNG_CORE.SET_NOTIFY_SCHEDULER with i_allocation_commit = ''' || i_allocation_commit || '''' ||
                   ' i_id_episode=' || i_id_episode || ' i_id_bmng_allocation_bed=' || i_id_bmng_allocation_bed;
        pk_alertlog.log_debug(g_error);
        IF (l_bed_flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p)
        THEN
            l_dt_allocation_bed := l_bmng_action_start_date;
        
            IF l_insert_into_bmng_alloc_bed = pk_alert_constant.g_yes
            THEN
                IF i_id_episode IS NOT NULL
                THEN
                    BEGIN
                        SELECT nvl(s.dt_begin_tstz, bab.dt_creation)
                          INTO l_dt_allocation_bed
                          FROM bmng_allocation_bed bab
                          LEFT JOIN schedule s
                            ON s.id_episode = bab.id_episode
                           AND s.flg_status != pk_alert_constant.g_cancelled
                         WHERE bab.id_episode = i_id_episode
                           AND (bab.id_bmng_allocation_bed = i_id_bmng_allocation_bed OR
                               (i_id_bmng_allocation_bed IS NULL AND bab.flg_outdated = pk_alert_constant.get_no));
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_dt_allocation_bed := l_bmng_action_start_date;
                    END;
                END IF;
            END IF;
        
            -- Invoke function responsable for invoke SCHEDULER API's
            g_error := 'CALL PK_BMNG_CORE.SET_NOTIFY_SCHEDULER';
            pk_alertlog.log_debug(g_error);
            IF NOT set_notify_scheduler(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_flg_origin_action_ux => i_flg_origin_action_ux,
                                        i_id_bed               => i_id_bed,
                                        i_dt_begin_action      => l_dt_allocation_bed,
                                        i_dt_end_action        => l_bmng_action_end_date,
                                        i_id_episode           => i_id_episode,
                                        i_id_patient           => i_id_patient,
                                        i_transaction_id       => l_transaction_id,
                                        i_allocation_commit    => i_allocation_commit,
                                        i_id_bmng              => nvl(l_set_id_allocation_bed, i_id_bmng_allocation_bed),
                                        i_id_bmng_action       => l_set_id_action,
                                        o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'AFTER PK_BMNG_CORE.SET_NOTIFY_SCHEDULER';
        pk_alertlog.log_debug(g_error);
    
        -- UPDATE DISCHAGE_SCHEDULE IF NOT NULL
        g_error := 'START OPERATIONS IN TABLE DISCHARGE_SCHEDULE';
        pk_alertlog.log_debug(g_error);
        IF i_dt_discharge_schedule IS NOT NULL
        THEN
            g_error := 'CALL PK_DISCHARGE.SET_DISCHARGE_SCH_DT WITH ID_EPISODE ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_discharge.set_discharge_sch_dt_int(i_lang                  => i_lang,
                                                         i_episode               => i_id_episode,
                                                         i_patient               => i_id_patient,
                                                         i_prof                  => i_prof,
                                                         i_dt_discharge_schedule => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                i_dt_discharge_schedule,
                                                                                                                i_prof),
                                                         i_flg_hour_origin       => i_flg_hour_origin,
                                                         i_transaction_id        => l_transaction_id,
                                                         i_allocation_commit     => pk_alert_constant.g_no,
                                                         o_id_discharge_schedule => l_id_discharge_schedule,
                                                         o_error                 => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_bed_unavailable THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_MANAGEMENT',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_MANAGEMENT',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_bed_management;

    /********************************************************************************************************************************************
    * CHECK_BED_ACTION                    Checks if all the pre-conditions are fullfiled to perform a given action over a specific bed.                                      
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)    
    * @param  I_ID_BED                    Bed identifier. Mandatory field.     
    * @param  O_BED_ALLOCATION            Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)    
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author                  Sofia Mendes
    * @version                 2.6.1.4
    * @since                   31-Oct-2011
    *******************************************************************************************************************************************/
    FUNCTION check_bed_action
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_bed             IN bed.id_bed%TYPE,
        i_flg_action         IN VARCHAR2,
        o_bed_action_allowed OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(16 CHAR) := 'CHECK_BED_ACTION';
    
        l_flg_bed_ocupacity_status bmng_action.flg_bed_ocupacity_status%TYPE;
        l_flg_bed_status           bmng_action.flg_bed_status%TYPE;
        l_flg_bed_cleaning_status  bmng_action.flg_bed_cleaning_status%TYPE;
    
        l_can_not_block_exc         EXCEPTION;
        l_can_not_unblock_exc       EXCEPTION;
        l_can_not_dirty_cont_exc    EXCEPTION;
        l_can_not_being_cleaned_exc EXCEPTION;
        l_can_not_clean_conc_exc    EXCEPTION;
    
    BEGIN
        o_bed_action_allowed := pk_alert_constant.g_yes;
    
        g_error := 'Get bmng_action data. i_id_bed: ' || i_id_bed;
        BEGIN
            SELECT ba.flg_bed_ocupacity_status, ba.flg_bed_status, ba.flg_bed_cleaning_status
              INTO l_flg_bed_ocupacity_status, l_flg_bed_status, l_flg_bed_cleaning_status
              FROM bmng_action ba
             WHERE ba.id_bed = i_id_bed
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_bed_ocupacity_status := NULL;
                l_flg_bed_status           := NULL;
                l_flg_bed_cleaning_status  := NULL;
        END;
    
        IF (i_flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b)
        THEN
            --check if the bed is blocked or occuppied                    
            IF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o OR
               l_flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b)
            THEN
                o_bed_action_allowed := pk_alert_constant.g_no;
            
                RAISE l_can_not_block_exc;
            END IF;
        ELSIF (i_flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_u)
        THEN
            --check if the bed is not blocked                     
            IF (l_flg_bed_status <> pk_bmng_constant.g_bmng_act_flg_bed_sta_b)
            THEN
                o_bed_action_allowed := pk_alert_constant.g_no;
                RAISE l_can_not_unblock_exc;
            END IF;
        ELSIF (i_flg_action IN (pk_bmng_constant.g_bmng_flg_origin_ux_d, pk_bmng_constant.g_bmng_flg_origin_ux_c))
        THEN
            --check if the dirty, contamined or being cleaned                   
            IF (l_flg_bed_cleaning_status IN (pk_bmng_constant.g_bmng_act_flg_cleani_d,
                                              pk_bmng_constant.g_bmng_act_flg_cleani_c,
                                              pk_bmng_constant.g_bmng_act_flg_cleani_i))
            THEN
                o_bed_action_allowed := pk_alert_constant.g_no;
                RAISE l_can_not_dirty_cont_exc;
            END IF;
        ELSIF (i_flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_i)
        THEN
            --check if it is the dirty or contamined                   
            IF (l_flg_bed_cleaning_status NOT IN
               (pk_bmng_constant.g_bmng_act_flg_cleani_d, pk_bmng_constant.g_bmng_act_flg_cleani_c))
            THEN
                RAISE l_can_not_being_cleaned_exc;
            END IF;
        
        ELSIF (i_flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_l)
        THEN
            --check if it is being cleaned                   
            IF (l_flg_bed_cleaning_status <> pk_bmng_constant.g_bmng_act_flg_cleani_i)
            THEN
                o_bed_action_allowed := pk_alert_constant.g_no;
                RAISE l_can_not_clean_conc_exc;
            END IF;
        END IF;
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_can_not_block_exc THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'It is not possible to block the bed (id_bed: ' || i_id_bed ||
                                              ') because it is already blocked or it is occupied. (l_flg_bed_ocupacity_status: ' ||
                                              l_flg_bed_ocupacity_status || ', l_flg_bed_status: ' || l_flg_bed_status || ')',
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BED_ACTION',
                                              o_error);
            RETURN FALSE;
        WHEN l_can_not_unblock_exc THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'It is not possible to unblock the bed (id_bed: ' || i_id_bed ||
                                              ') because it is not blocked or it is occupied. (l_flg_bed_status: ' ||
                                              l_flg_bed_status || ')',
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BED_ACTION',
                                              o_error);
            RETURN FALSE;
        WHEN l_can_not_dirty_cont_exc THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'It is not possible to set the bed (id_bed: ' || i_id_bed ||
                                              ') as dirty or contamined because it is dirty, contamined or being cleaned. (l_flg_bed_cleaning_status: ' ||
                                              l_flg_bed_cleaning_status || ')',
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BED_ACTION',
                                              o_error);
            RETURN FALSE;
        WHEN l_can_not_being_cleaned_exc THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'It is not possible to set the bed (id_bed: ' || i_id_bed ||
                                              ') as being cleaned because it not in state dirty or contamined. (l_flg_bed_cleaning_status: ' ||
                                              l_flg_bed_cleaning_status || ')',
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BED_ACTION',
                                              o_error);
            RETURN FALSE;
        
        WHEN l_can_not_clean_conc_exc THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'It is not possible to set the bed (id_bed: ' || i_id_bed ||
                                              ') as clened concluded because it not in state being cleaned. (l_flg_bed_cleaning_status: ' ||
                                              l_flg_bed_cleaning_status || ')',
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BED_ACTION',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_BED_ACTION',
                                              o_error);
            RETURN FALSE;
    END check_bed_action;

    /********************************************************************************************************************************************
      * SET_BED_ACTION                      This funciton intends to be an API to the interfaces team to perform the following action over a given bed:
      *                                     - block
      *                                     - unblock
      *                                     - clean
      *                                     - contamine
      *                                     - set as being cleaned
      *                                     - clean concluded    
    *                   - free    
      *
      * @param  I_LANG                      Language associated to the professional executing the request
      * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)    
      * @param  I_ID_BED                    Bed identifier. Mandatory field.
      * @param  I_FLG_ACTION                Type of action: FLAG defined in flash layer
      * @param  I_DT_BEGIN                  Date in which this action start counting. Can be used on block, dirty, contamined action
      * @param  I_DT_END                    Date in which this action became outdated. Can be used on block, dirty, contamined action
      * @param  I_ID_BMNG_REASON            Reason identifier associated with current action. Mandatory for block bed. 
      *                                     It is not shown in application in the other options    
      * @param  I_NOTES                     Notes written by professional when creating current registry . 
      *                                      Can be used on block, dirty, contamined actions 
    * @param  I_ID_EPISODE                     Episode identifier.
    * @param  I_ID_PATIENT                     Patient identifier.
    * @param  I_ID_BMNG_ALLOC_BED                     Bed Management Allocation Bed identifier.
      * @param  O_BED_ALLOCATION            Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)    
      * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
      *
      * @value  I_FLG_ACTION                {*} 'B'-  BLOCK
      *                                     {*} 'U'-  UNBLOCK                                    
      *                                     {*} 'D'-  DIRTY
      *                                     {*} 'C'-  CONTAMINED
      *                                     {*} 'I'-  CLEANING IN PROCESS
      *                                     {*} 'L'-  CLEANING CONCLUDED
    *                                     {*} 'V'-  FREE
      * 
      * @return                  Returns TRUE if success, otherwise returns FALSE
      * @raises                  PL/SQL generic erro "OTHERS"
      *
      * @author                  Sofia Mendes
      * @version                 2.6.1.4
      * @since                   31-Oct-2011
      * @dependencies            INTER-ALERT
      *******************************************************************************************************************************************/
    FUNCTION set_bed_action
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_bed             IN bed.id_bed%TYPE,
        i_flg_action         IN VARCHAR2,
        i_dt_begin           IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end             IN bmng_action.dt_end_action%TYPE,
        i_notes              IN bmng_action.action_notes%TYPE,
        i_id_bmng_reason     IN bmng_action.id_bmng_reason%TYPE,
        i_dt_creation        IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_transaction_id     IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_bmng_alloc_bed  IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_bed_action_allowed OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        --        
        l_internal_error EXCEPTION;
        l_id_department  department.id_department%TYPE;
        l_id_room        room.id_room%TYPE;
        l_id_bed_type    bed_type.id_bed_type%TYPE;
    
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        l_exception_info         sys_message.desc_message%TYPE;
    
        l_check_block_exception EXCEPTION;
        l_check_exception       EXCEPTION;
        l_set_bmng_exc          EXCEPTION;
        l_get_bed_data_exc      EXCEPTION;
        l_invalid_action        EXCEPTION;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF (i_flg_action NOT IN (pk_bmng_constant.g_bmng_flg_origin_ux_b,
                                 pk_bmng_constant.g_bmng_flg_origin_ux_u,
                                 pk_bmng_constant.g_bmng_flg_origin_ux_d,
                                 pk_bmng_constant.g_bmng_flg_origin_ux_c,
                                 pk_bmng_constant.g_bmng_act_flg_cleani_i,
                                 pk_bmng_constant.g_bmng_act_flg_cleani_l,
                                 pk_bmng_constant.g_bmng_flg_origin_ux_v))
        THEN
            RAISE l_invalid_action;
        END IF;
    
        IF (i_flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b AND (i_dt_end IS NULL OR i_id_bmng_reason IS NULL))
        THEN
            RAISE l_check_block_exception;
        END IF;
    
        g_error := 'CALL pk_bed.get_bed_room_and_depart. i_id_bed: ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bed.get_bed_room_and_depart(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_id_bed        => i_id_bed,
                                              o_id_room       => l_id_room,
                                              o_id_department => l_id_department,
                                              o_error         => o_error)
        THEN
            RAISE l_get_bed_data_exc;
        END IF;
    
        g_error := 'Call check_bed_action. i_id_bed: ' || i_id_bed || ' i_flg_action: ' || i_flg_action;
        pk_alertlog.log_debug(g_error);
        IF NOT check_bed_action(i_lang               => i_lang,
                                i_prof               => i_prof,
                                i_id_bed             => i_id_bed,
                                i_flg_action         => i_flg_action,
                                o_bed_action_allowed => o_bed_action_allowed,
                                o_error              => o_error)
        THEN
            RAISE l_check_exception;
        END IF;
    
        IF (o_bed_action_allowed = pk_alert_constant.g_yes)
        THEN
            g_error := 'Call set_bed_management. i_id_bed: ' || i_id_bed || ' l_id_department: ' || l_id_department ||
                       ' l_id_room: ' || l_id_room || ' i_id_bmng_reason: ' || i_id_bmng_reason || ' i_notes: ' ||
                       i_notes || ' i_dt_begin: ' || CAST(i_dt_begin AS VARCHAR2) || 'i_dt_end: ' ||
                       CAST(i_dt_end AS VARCHAR2) || ' i_flg_action: ' || i_flg_action || ' i_dt_creation: ' ||
                       CAST(i_dt_creation AS VARCHAR2);
            pk_alertlog.log_debug(g_error);
            IF NOT set_bed_management(i_lang                   => i_lang,
                                      i_prof                   => i_prof,
                                      i_id_bmng_action         => NULL,
                                      i_id_department          => l_id_department,
                                      i_id_room                => l_id_room, --5
                                      i_id_bed                 => i_id_bed,
                                      i_id_bmng_reason         => i_id_bmng_reason,
                                      i_id_bmng_allocation_bed => i_id_bmng_alloc_bed,
                                      i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                      i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a, --10
                                      i_nch_capacity           => NULL,
                                      i_action_notes           => i_notes,
                                      i_dt_begin_action        => i_dt_begin,
                                      i_dt_end_action          => i_dt_end,
                                      i_id_episode             => i_id_episode,
                                      i_id_patient             => i_id_patient,
                                      i_nch_hours              => NULL,
                                      i_flg_allocation_nch     => NULL, --pk_bmng_constant.g_bmng_bed_ea_flg_nch_d,
                                      i_desc_bed               => NULL,
                                      i_id_bed_type            => NULL, --l_id_bed_type, --20
                                      i_dt_discharge_schedule  => NULL,
                                      i_flg_hour_origin        => NULL,
                                      i_id_bed_dep_clin_serv   => NULL,
                                      i_flg_origin_action_ux   => i_flg_action,
                                      i_reason_notes           => NULL,
                                      i_transaction_id         => l_transaction_id,
                                      i_allocation_commit      => pk_alert_constant.g_yes,
                                      i_dt_creation            => i_dt_creation,
                                      o_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                      o_id_bed                 => l_id_bed,
                                      o_bed_allocation         => o_bed_action_allowed, --30
                                      o_exception_info         => l_exception_info,
                                      o_error                  => o_error)
            THEN
                RAISE l_set_bmng_exc;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_check_block_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Filds i_dt_end and/or i_id_bmng_reason are mandatory when i_flg_action = BLOCK',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_ACTION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_invalid_action THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'The given action (i_flg_action: ' || i_flg_action || ') is not allowed.',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_ACTION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_get_bed_data_exc THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_check_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_set_bmng_exc THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BED_ACTION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_bed_action;

    /********************************************************************************************
    * Returns nch_level for a specific department considering the requested date if not null
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_department   Department ID
    * @param IN   i_dt_requested Request date - should be in the range of a specific BMNG_ACTION
    *                            (if i_dt_requested is null, then uses current information from bmng_department_ea)
    * @param OUT  o_nch_level    NCH hours for a specific department and date
    *                            (if i_dt_requested is null, then uses current information from bmng_department_ea)
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_dt_request IN bmng_action.dt_begin_action%TYPE,
        o_nch_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_request  bmng_action.dt_begin_action%TYPE;
        l_default_nch PLS_INTEGER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_default_nch := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_pat, i_prof);
    
        g_error := 'GET DT_REQUEST';
        pk_alertlog.log_debug(g_error);
        IF i_dt_request IS NULL
        THEN
            l_dt_request := current_timestamp;
        ELSE
            l_dt_request := i_dt_request;
        END IF;
    
        g_error := 'GET NCH_LEVEL With i_department=' || i_department;
        pk_alertlog.log_debug(g_error);
        SELECT SUM(nch_level)
          INTO o_nch_level
          FROM ( -------------------------------------------------
                SELECT CASE
                             WHEN pk_date_utils.add_days_to_tstz(pk_schedule_inp.get_sch_dt_begin(i_lang,
                                                                                                  i_prof,
                                                                                                  bbe.id_episode),
                                                                 nl1.duration) <= l_dt_request THEN
                              decode(nl2.id_nch_level, NULL, nl1.value, nl2.value)
                             ELSE
                              nl1.value
                         END nch_level
                  FROM bmng_bed_ea bbe, room r, nch_level nl1, nch_level nl2
                 WHERE r.id_department = i_department
                   AND bbe.id_room = r.id_room
                   AND bbe.flg_allocation_nch IS NULL
                   AND bbe.id_nch_level = nl1.id_nch_level
                   AND nl1.id_nch_level = nl2.id_previous(+)
                   AND l_dt_request >= bbe.dt_begin
                UNION ALL
                -------------------------------------------------
                SELECT nvl(pk_nch_pbl.get_nch_total(i_lang, i_prof, bbe.id_episode, l_dt_request), l_default_nch) nch_level
                  FROM bmng_bed_ea bbe
                 INNER JOIN room r
                    ON r.id_room = bbe.id_room
                 INNER JOIN bmng_allocation_bed bab
                    ON bbe.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
                
                 WHERE r.id_department = i_department
                   AND bbe.flg_allocation_nch = pk_bmng_constant.g_bmng_allocat_flg_nch_d -- 'D' -- definitivo                   
                   AND bbe.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o
                   AND bbe.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n
                      
                   AND l_dt_request >= bbe.dt_begin
                UNION ALL
                -------------------------------------------------
                SELECT (CASE
                            WHEN pk_date_utils.add_days_to_tstz(pk_schedule_inp.get_sch_dt_begin(i_lang,
                                                                                                 i_prof,
                                                                                                 bbe.id_episode),
                                                                nl1.duration) <= l_dt_request THEN
                             decode(nl2.id_nch_level,
                                    NULL,
                                    nl1.value,
                                    (CASE
                                        WHEN l_dt_request >= en.dt_begin THEN
                                         en.nch_value
                                        ELSE
                                         nl2.value
                                    END))
                            ELSE
                             (CASE
                                 WHEN l_dt_request >= en.dt_begin THEN
                                  en.nch_value
                                 ELSE
                                  nl1.value
                             END)
                        END) nch_level
                  FROM bmng_bed_ea bbe, room r, bmng_allocation_bed bab, nch_level nl1, nch_level nl2, epis_nch en
                 WHERE r.id_department = i_department
                   AND r.id_room = bbe.id_room
                   AND bbe.flg_allocation_nch = pk_bmng_constant.g_bmng_allocat_flg_nch_u -- 'U' -- temporario
                   AND bbe.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
                   AND bbe.id_nch_level = nl1.id_nch_level
                   AND en.id_epis_nch = bab.id_epis_nch
                   AND en.flg_status = pk_alert_constant.g_active
                   AND nl1.id_nch_level = nl2.id_previous(+)
                   AND l_dt_request >= bbe.dt_begin
                -------------------------------------------------
                );
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_SERVICE_LEVEL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_nch_service_level;

    /********************************************************************************************
    * Returns nch_level for a specific department, based on EA tables info.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_department   Department ID
    * @param OUT  o_nch_level    NCH hours for a specific department and date
    *                            
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   RicardoNunoAlmeida
    * @version                  2.5.0.7.5
    * @since                    2009/12/11
    ********************************************************************************************/
    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_nch_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_default_nch PLS_INTEGER;
    BEGIN
        g_error := 'LOAD VARIABLES';
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := current_timestamp;
        l_default_nch  := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_pat, i_prof);
    
        g_error := 'GET TOTAL';
        pk_alertlog.log_debug(g_error);
        SELECT SUM(nvl(pk_nch_pbl.get_nch_total(i_lang, i_prof, bab.id_episode, g_sysdate_tstz), l_default_nch))
          INTO o_nch_level
          FROM bmng_allocation_bed bab
         INNER JOIN room r
            ON bab.id_room = r.id_room
         INNER JOIN bmng_action ba
            ON ba.id_bmng_allocation_bed = bab.id_bmng_allocation_bed
           AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n
         WHERE r.id_department = i_department
           AND bab.flg_outdated = pk_alert_constant.g_no
           AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_SERVICE_LEVEL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_nch_service_level;

    /********************************************************************************************
    * Returns nch_level for a specific department considering the requested date if not null
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_department   Department ID
    * @param IN   i_dt_requested Request date - should be in the range of a specific BMNG_ACTION
    *                            (if i_dt_requested is null, then uses current information from bmng_department_ea)
    *
    * @return  NCH hours for a specific department and date
    *                            (if i_dt_requested is null, then uses current information from bmng_department_ea)
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    21/07/2009
    ********************************************************************************************/
    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_dt_request IN bmng_action.dt_begin_action%TYPE
    ) RETURN NUMBER IS
    
        l_nch_level PLS_INTEGER;
        o_error     t_error_out;
    
    BEGIN
        g_error := 'PK_BMNG_CORE.GET_NCH_SERVICE_LEVEL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng_core.get_nch_service_level(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_department => i_department,
                                                  i_dt_request => i_dt_request,
                                                  o_nch_level  => l_nch_level,
                                                  o_error      => o_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_nch_level;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_SERVICE_LEVEL',
                                              o_error);
            RETURN NULL;
    END;

    /********************************************************************************************
    * Returns nch_level for a specific department, based on EA tables info.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_department   Department ID
    *                            
    *
    * @return  NCH hours for a specific department and date
    *
    * @author                   RicardoNunoAlmeida
    * @version                  2.5.0.7.5
    * @since                    2009/12/11
    ********************************************************************************************/
    FUNCTION get_nch_service_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE
    ) RETURN NUMBER IS
    
        l_nch_level PLS_INTEGER;
        o_error     t_error_out;
    
    BEGIN
        g_error := 'PK_BMNG_CORE.GET_NCH_SERVICE_LEVEL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng_core.get_nch_service_level(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_department => i_department,
                                                  o_nch_level  => l_nch_level,
                                                  o_error      => o_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_nch_level;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_SERVICE_LEVEL',
                                              o_error);
            RETURN NULL;
    END;

    /********************************************************************************************************************************************
    * GET_ALL_CLIN_SERVICES_INT   Function that returns all clinical services for given department
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT        Department ID
    * @param  O_ERROR             If an error occurs, this parameter will have information about the error
    *
    * @return                     Returns a string with all clinical services concatenated for the given department
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_all_clin_services_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE
    ) RETURN VARCHAR2 IS
        l_clin_services VARCHAR2(32767);
    BEGIN
        g_error := 'GET ALL CLIN SERVS With i_department=' || i_department;
        pk_alertlog.log_debug(g_error);
        SELECT pk_utils.concat_table(CAST(MULTISET
                                          (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                             FROM dep_clin_serv dcs
                                             JOIN clinical_service cs
                                               ON cs.id_clinical_service = dcs.id_clinical_service
                                            WHERE dcs.id_department = i_department
                                              AND cs.flg_available = pk_alert_constant.g_yes
                                              AND dcs.flg_available = pk_alert_constant.g_yes) AS table_varchar),
                                     ', ')
          INTO l_clin_services
          FROM dual;
    
        RETURN l_clin_services;
    EXCEPTION
        WHEN no_data_found THEN
            l_clin_services := '';
            RETURN l_clin_services;
    END;

    /********************************************************************************************************************************************
    * get_all_bed_specs_int   Function that returns all clinical services for given bed
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BED                Bed ID
    *
    * @return                     Returns a string with all clinical services concatenated for the given bed
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   30-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_all_bed_specs_int
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2 IS
        l_clin_services VARCHAR2(32767);
    BEGIN
        g_error := 'GET ALL BED SPECS With i_bed=' || i_bed;
        pk_alertlog.log_debug(g_error);
        SELECT pk_utils.concat_table(CAST(MULTISET
                                          (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                             FROM dep_clin_serv dcs
                                             JOIN bed_dep_clin_serv bdcs
                                               ON bdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                             JOIN clinical_service cs
                                               ON cs.id_clinical_service = dcs.id_clinical_service
                                            WHERE bdcs.id_bed = i_bed
                                              AND cs.flg_available = pk_alert_constant.g_yes
                                              AND dcs.flg_available = pk_alert_constant.g_yes
                                              AND bdcs.flg_available = pk_alert_constant.g_yes) AS table_varchar),
                                     ', ')
          INTO l_clin_services
          FROM dual;
    
        RETURN l_clin_services;
    EXCEPTION
        WHEN no_data_found THEN
            l_clin_services := '';
            RETURN l_clin_services;
    END get_all_bed_specs_int;

    /********************************************************************************************************************************************
    * GET_DEPARTMENTS          Function that returns all departments for the current professional institution
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  O_DEPS           Department information cursor
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_departments
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        o_deps    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_age    NUMBER;
        l_gender patient.gender%TYPE;
    
    BEGIN
    
        g_error := 'GET DEPARTMENTS';
        pk_alertlog.log_debug(g_error);
    
        IF i_patient IS NOT NULL
        THEN
            g_error := 'GET PATIENT AGE';
            l_age   := pk_patient.get_pat_age(i_lang        => i_lang,
                                              i_dt_birth    => NULL,
                                              i_dt_deceased => NULL,
                                              i_age         => NULL,
                                              i_patient     => i_patient);
        
            g_error  := 'GET PATIENT GENDER';
            l_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
        END IF;
    
        OPEN o_deps FOR
            SELECT d.id_department,
                   decode(nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)),
                          NULL,
                          pk_translation.get_translation(i_lang, d.code_department),
                          pk_translation.get_translation(i_lang, d.code_department) || ' (' ||
                          nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') desc_service,
                   pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specialties,
                   (bdea.total_avail_nch_hours - pk_bmng_core.get_nch_service_level(i_lang, i_prof, bdea.id_department)) service_available_nch
              FROM department d
             INNER JOIN bmng_department_ea bdea
                ON bdea.id_department = d.id_department
              LEFT JOIN admission_type at
                ON at.id_admission_type = d.id_admission_type
             WHERE d.id_institution = i_prof.institution
               AND (SELECT COUNT(1)
                      FROM room r
                     WHERE r.id_department = d.id_department) > 0
               AND instr(d.flg_type, 'I') > 0
               AND d.flg_available = pk_alert_constant.g_available
               AND (d.adm_age_min IS NULL OR (d.adm_age_min IS NOT NULL AND d.adm_age_min <= l_age) OR l_age IS NULL)
               AND (d.adm_age_max IS NULL OR (d.adm_age_max IS NOT NULL AND d.adm_age_max >= l_age) OR l_age IS NULL)
               AND ((d.gender IS NOT NULL AND d.gender <> l_gender AND l_gender IS NOT NULL) OR d.gender IS NULL OR
                   l_gender IS NULL)
               AND i_prof.software IN (pk_alert_constant.g_soft_inpatient, pk_alert_constant.g_soft_adt)
            UNION ALL
            SELECT d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) desc_service,
                   pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, d.id_department) desc_specialties,
                   NULL service_available_nch
              FROM department d
             WHERE d.id_dept IN (SELECT sd.id_dept
                                   FROM software_dept sd
                                   JOIN dept d
                                     ON d.id_dept = sd.id_dept
                                  INNER JOIN department dep
                                     ON dep.id_dept = d.id_dept
                                  WHERE d.id_institution = i_prof.institution
                                    AND sd.id_software = i_prof.software
                                    AND dep.flg_available = pk_alert_constant.g_available
                                    AND (SELECT COUNT(1)
                                           FROM room r
                                          WHERE r.id_department = dep.id_department) > 0)
               AND instr(d.flg_type, 'I') = 0
               AND d.flg_available = pk_alert_constant.g_available
               AND d.id_institution = i_prof.institution
               AND (d.adm_age_min IS NULL OR (d.adm_age_min IS NOT NULL AND d.adm_age_min <= l_age) OR l_age IS NULL)
               AND (d.adm_age_max IS NULL OR (d.adm_age_max IS NOT NULL AND d.adm_age_max >= l_age) OR l_age IS NULL)
               AND ((d.gender IS NOT NULL AND d.gender <> l_gender AND l_gender IS NOT NULL) OR d.gender IS NULL OR
                   l_gender IS NULL)
               AND EXISTS
             (SELECT 0
                      FROM room r
                      JOIN bed b
                        ON r.id_room = b.id_room
                     WHERE b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                       AND b.flg_available = pk_alert_constant.g_yes
                       AND r.flg_available = pk_alert_constant.g_yes)
               AND (SELECT COUNT(1)
                      FROM room r
                     WHERE r.id_department = d.id_department) > 0
               AND i_prof.software NOT IN (pk_alert_constant.g_soft_inpatient, pk_alert_constant.g_soft_adt)
             ORDER BY desc_service, desc_specialties;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPARTMENTS',
                                              o_error);
            pk_types.open_my_cursor(o_deps);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_departments;

    /********************************************************************************************************************************************
    * GET_ROOMS                Function that returns all rooms for the specified department
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT              Department ID
    * @param  I_FLG_TYPE                Bed type
    * @param  I_SHOW_OCCUPIED_BEDS      Number of beds show in current rooms should count with occupied beds ('Y' - Yes; 'N' - No)
    * @param  O_ROOMS                   Rooms information cursor
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    * @value  I_SHOW_OCCUPIED_BEDS      Y - Yes; N - No
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_rooms              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET ROOMS';
        OPEN o_rooms FOR
            SELECT rooms.id_room,
                   decode(i_show_occupied_beds,
                          pk_alert_constant.g_no,
                          desc_room_name || ' (' || (rooms.t1 - rooms.t2) || ')',
                          desc_room_name || ' (' || rooms.t1 || ')') desc_room,
                   rooms.desc_room_type,
                   rooms.flg_available,
                   rooms.desc_room_name,
                   rooms.t1,
                   rooms.t2
              FROM (SELECT r.id_room,
                           nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) desc_room_type,
                           decode(r.flg_available || rt.flg_available,
                                  pk_alert_constant.g_yes || pk_alert_constant.g_yes,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_available,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room_name,
                           (SELECT COUNT(*)
                              FROM bed b
                             WHERE b.id_room = r.id_room
                               AND (b.flg_type = i_flg_type OR i_flg_type IS NULL)
                               AND b.flg_available = pk_alert_constant.g_yes) t1,
                           (SELECT COUNT(*)
                              FROM bed b
                              LEFT JOIN bmng_bed_ea bbe
                                ON b.id_bed = bbe.id_bed
                             WHERE b.id_room = r.id_room
                               AND ((bbe.id_bmng_action IS NOT NULL AND
                                   bbe.flg_bed_status != pk_bmng_constant.g_bmng_bed_ea_flg_stat_n) OR
                                   b.flg_status != pk_bmng_constant.g_bmng_bed_ea_flg_ocup_v)
                               AND (b.flg_type = i_flg_type OR i_flg_type IS NULL)
                               AND b.flg_available = pk_alert_constant.g_yes) t2
                      FROM room r
                      LEFT JOIN room_type rt
                        ON (rt.id_room_type = r.id_room_type)
                     WHERE r.id_department = i_department
                       AND r.flg_available = pk_alert_constant.g_yes) rooms
             ORDER BY regexp_substr(desc_room, '^\D*') NULLS FIRST, to_number(regexp_substr(desc_room, '\d+'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOMS',
                                              o_error);
            pk_types.open_my_cursor(o_rooms);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rooms;

    /********************************************************************************************************************************************
    * GET_BEDS                 Function that returns all beds for the specified room
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ROOM           Room ID
    * @param  I_FLG_TYPE       Bed type
    * @param  O_BEDS           Beds information cursor
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE       NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   17-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_beds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_room     IN room.id_room%TYPE,
        i_flg_type IN bed.flg_type%TYPE,
        o_beds     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bmng_temporary_bed sys_config.value%TYPE := pk_sysconfig.get_config('BMNG_TEMPORARY_BED', i_prof);
    
    BEGIN
    
        g_error := 'GET BEDS';
        OPEN o_beds FOR
            SELECT b.id_bed,
                   b.id_bed_type,
                   b.bed_desc_name,
                   b.bed_desc_spec,
                   decode(b.bed_desc_spec, NULL, b.bed_desc_name, b.bed_desc_name || ' - ' || b.bed_desc_spec) desc_bed,
                   b.desc_bed_type,
                   b.flg_available,
                   decode(b.flg_bed_cleaning_status,
                          pk_bmng_constant.g_bmng_act_flg_cleani_d,
                          pk_alert_constant.g_no,
                          pk_bmng_constant.g_bmng_act_flg_cleani_i,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_available_clean
              FROM (SELECT b.id_bed,
                           b.id_bed_type,
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_desc_name,
                           pk_bmng_core.get_all_bed_specs_int(i_lang, i_prof, b.id_bed) bed_desc_spec,
                           nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) desc_bed_type,
                           ba.flg_bed_cleaning_status,
                           decode(nvl(bbe.flg_bed_status, pk_bmng_constant.g_bmng_bed_ea_flg_stat_n) ||
                                  nvl(bbe.flg_bed_ocupacity_status, pk_bmng_constant.g_bmng_bed_ea_flg_ocup_v) ||
                                  nvl(b.flg_status, pk_bmng_constant.g_bmng_bed_flg_status_v),
                                  pk_bmng_constant.g_bmng_bed_ea_flg_stat_n || pk_bmng_constant.g_bmng_bed_ea_flg_ocup_v ||
                                  pk_bmng_constant.g_bmng_bed_flg_status_v,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_available,
                           0 rank
                      FROM room r
                      JOIN bed b
                        ON b.id_room = r.id_room
                      LEFT JOIN bed_type bt
                        ON bt.id_bed_type = b.id_bed_type
                      LEFT JOIN bmng_bed_ea bbe
                        ON bbe.id_bed = b.id_bed
                       AND g_sysdate_tstz >= bbe.dt_begin
                      LEFT JOIN bmng_action ba
                        ON (ba.id_bed = b.id_bed AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                           ba.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od)
                     WHERE r.id_room = i_room
                       AND b.flg_available = pk_alert_constant.g_yes
                       AND (b.flg_type = i_flg_type OR i_flg_type IS NULL)
                    UNION ALL
                    SELECT -1 id_bed,
                           NULL id_bed_type,
                           pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T113') bed_desc_name,
                           NULL bed_desc_spec,
                           NULL desc_bed_type,
                           NULL flg_bed_cleaning_status,
                           pk_bmng_constant.g_bmng_bed_flg_type_t flg_available,
                           -1 rank
                      FROM dual
                     WHERE l_bmng_temporary_bed = pk_alert_constant.g_yes) b
             ORDER BY rank DESC,
                      regexp_substr(bed_desc_name, '^\D*') NULLS FIRST,
                      to_number(regexp_substr(bed_desc_name, '\d+'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BEDS',
                                              o_error);
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_beds;

    /********************************************************************************************************************************************
    * GET_ROOMS_BEDS           Function that returns all rooms and beds for the specified department
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT              Department ID
    * @param  I_FLG_TYPE                Bed type
    * @param  I_SHOW_OCCUPIED_BEDS      Number of beds show in current rooms should count with occupied beds ('Y' - Yes; 'N' - No)
    * @param  O_ROOMS                   Rooms information cursor
    * @param  O_BEDS                    Beds information cursor
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    * @value  I_SHOW_OCCUPIED_BEDS      Y - Yes; N - No
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   25-Ago-2009
    *******************************************************************************************************************************************/
    FUNCTION get_rooms_beds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_rooms              OUT pk_types.cursor_type,
        o_beds               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ROOMS_BEDS';
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TO FUNCTION GET_ROOMS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_rooms(i_lang               => i_lang,
                         i_prof               => i_prof,
                         i_department         => i_department,
                         i_flg_type           => i_flg_type,
                         i_show_occupied_beds => i_show_occupied_beds,
                         o_rooms              => o_rooms,
                         o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET BEDS';
        pk_alertlog.log_debug(g_error);
        OPEN o_beds FOR
            SELECT beds.id_bed,
                   beds.id_bed_type,
                   beds.bed_desc_name,
                   beds.bed_desc_spec,
                   decode(beds.bed_desc_spec,
                          NULL,
                          beds.bed_desc_name,
                          beds.bed_desc_name || ' - ' || beds.bed_desc_spec) desc_bed,
                   beds.desc_bed_type,
                   beds.flg_available,
                   decode(beds.flg_bed_cleaning_status,
                          pk_bmng_constant.g_bmng_act_flg_cleani_d,
                          pk_alert_constant.g_no,
                          pk_bmng_constant.g_bmng_act_flg_cleani_i,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_available_clean,
                   beds.id_room
              FROM (SELECT b.id_bed,
                           b.id_bed_type,
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_desc_name,
                           pk_bmng_core.get_all_bed_specs_int(i_lang, i_prof, b.id_bed) bed_desc_spec,
                           nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) desc_bed_type,
                           ba.flg_bed_cleaning_status,
                           decode(nvl(bbe.flg_bed_status, pk_bmng_constant.g_bmng_bed_ea_flg_stat_n) ||
                                  nvl(bbe.flg_bed_ocupacity_status, pk_bmng_constant.g_bmng_bed_ea_flg_ocup_v) ||
                                  nvl(b.flg_status, pk_bmng_constant.g_bmng_bed_flg_status_v),
                                  pk_bmng_constant.g_bmng_bed_ea_flg_stat_n || pk_bmng_constant.g_bmng_bed_ea_flg_ocup_v ||
                                  pk_bmng_constant.g_bmng_bed_flg_status_v,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_available,
                           r.id_room
                      FROM room r
                      JOIN bed b
                        ON b.id_room = r.id_room
                       AND b.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN bed_type bt
                        ON bt.id_bed_type = b.id_bed_type
                      LEFT JOIN bmng_bed_ea bbe
                        ON bbe.id_bed = b.id_bed
                       AND g_sysdate_tstz >= bbe.dt_begin
                      LEFT JOIN bmng_action ba
                        ON (ba.id_bed = b.id_bed AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                           ba.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od)
                     WHERE r.id_department = i_department
                       AND (b.flg_type = i_flg_type OR i_flg_type IS NULL)) beds
             ORDER BY regexp_substr(beds.bed_desc_name, '^\D*') NULLS FIRST,
                      to_number(regexp_substr(beds.bed_desc_name, '\d+'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_rooms);
            pk_types.open_my_cursor(o_beds);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rooms_beds;

    /***************************************************************************************************************
    *
    * Returns the ALERT IDs of the DEP_CLIN_SERVs associated to a bed.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the BED.
    * @param      o_dcs               Array of DEP_CLIN_SERVs
    * @param      o_error
    *
    * @RETURN  BOOLEAN 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_specialties
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_bed   IN bed.id_bed%TYPE,
        o_dcs   OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET SPECIALTIES';
        pk_alertlog.log_debug(g_error);
        SELECT bdcs.id_dep_clin_serv
          BULK COLLECT
          INTO o_dcs
          FROM bed_dep_clin_serv bdcs
         INNER JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = bdcs.id_dep_clin_serv
         WHERE bdcs.id_bed = i_bed
           AND dcs.flg_available = pk_alert_constant.g_yes
           AND bdcs.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_dcs := table_number();
            RETURN TRUE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED_SPECIALTIES',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bed_specialties;

    /***************************************************************************************************************
    *
    * Returns the ALERT IDs of the DEP_CLIN_SERVs associated to a room.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.
    * @param      o_dcs               Array of DEP_CLIN_SERVs
    * @param      o_error
    *
    * @RETURN  BOOLEAN 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_dep_specialties
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_dcs   OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET SPECIALTIES With i_dep=' || i_dep;
        pk_alertlog.log_debug(g_error);
    
        SELECT dcs.id_dep_clin_serv
          BULK COLLECT
          INTO o_dcs
          FROM dep_clin_serv dcs
         WHERE dcs.id_department = i_dep
           AND dcs.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_dcs := table_number();
            RETURN TRUE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEP_SPECIALTIES',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_dep_specialties;

    /***************************************************************************************************************
    *
    * Returns the ALERT IDs of the DEP_CLIN_SERVs associated to a department.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_dep               ID of the department.
    * @param      o_dcs               Array of DEP_CLIN_SERVs
    * @param      o_error
    *
    * @RETURN  BOOLEAN 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_specialties
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_dcs   OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET SPECIALTIES With i_room=' || i_room;
        SELECT dcs.id_dep_clin_serv
          BULK COLLECT
          INTO o_dcs
          FROM room_dep_clin_serv rdcs
         INNER JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = rdcs.id_dep_clin_serv
         WHERE rdcs.id_room = i_room
           AND dcs.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_dcs := table_number();
            RETURN TRUE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOM_SPECIALTIES',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_room_specialties;

    /********************************************************************************************************************************************
    * GET_AVAILABILITY_INT        Function that returns the number of days left to the next bed schedule date
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BED               Bed ID
    *
    * @return                     Returns the number of days left to the next bed schedule date
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   23-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_availability_int
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN NUMBER IS
        l_data pk_types.cursor_type;
        --
        l_id_bed     bed.id_bed%TYPE;
        l_date       TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_patient patient.id_patient%TYPE;
    
        --
        l_error t_error_out;
        --
        l_num_days_diff NUMBER;
    BEGIN
        g_error := 'GET NEXT SCH DATE With i_bed=' || i_bed;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_schedule_inp.get_next_schedule_date(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_bed => i_bed,
                                                      i_date   => current_timestamp,
                                                      o_data   => l_data,
                                                      o_error  => l_error)
        THEN
            RETURN - 1;
        END IF;
    
        LOOP
        
            FETCH l_data
                INTO l_id_bed, l_date, l_id_patient;
            EXIT WHEN l_data%NOTFOUND;
        
            g_error := 'GET TIMESTAMP DIFF WITH l_date=' || l_date;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                    i_timestamp_1 => trunc(l_date),
                                                    i_timestamp_2 => trunc(current_timestamp),
                                                    o_days_diff   => l_num_days_diff,
                                                    o_error       => l_error)
            THEN
                RETURN - 1;
            END IF;
            --Vou sair do ciclo porque só me interessa o 1º registo que contêm o próximo agendamento
            EXIT;
        END LOOP;
    
        CLOSE l_data;
    
        RETURN ceil(l_num_days_diff);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAILABILITY_INT',
                                              l_error);
            RETURN NULL;
    END get_availability_int;

    /********************************************************************************************************************************************
    * TF_GET_BED_STATUS           Table function that returns all the necessary bed status information to be used by flash
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BMNG_ACTION       Bed action identifier
    *
    * @return                     Returns table function with one record with the following information:
    *                             - icon_bed_status         
    *                             - icon_bed_cleaning_status
    *                             - desc_bed_status         
    *                             - desc_cleaning_status    
    *                             - availability            
    *                             - flg_conflict            
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   21-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION tf_get_bed_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_depart_arr      IN table_number DEFAULT NULL,
        i_bmng_action_arr IN table_number DEFAULT NULL
    ) RETURN t_table_bmng_bed_status IS
        l_table t_table_bmng_bed_status;
        --
        l_id_bed                   bmng_bed_ea.id_bed%TYPE;
        l_flg_bed_ocupacity_status bmng_bed_ea.flg_bed_ocupacity_status%TYPE;
        l_flg_bed_status           bmng_bed_ea.flg_bed_status%TYPE;
        l_flg_bed_cleaning_status  bmng_bed_ea.flg_bed_cleaning_status%TYPE;
        l_flg_bed_type             bmng_bed_ea.flg_bed_type%TYPE;
        l_dt_end                   bmng_bed_ea.dt_discharge_schedule%TYPE;
        --
        l_bmng_action               NUMBER(24);
        l_icon_bed_status           VARCHAR2(200);
        l_icon_bed_cleaning_status  VARCHAR2(200);
        l_desc_bed_status           VARCHAR2(200);
        l_desc_cleaning_status      VARCHAR2(200);
        l_availability              NUMBER(24);
        l_desc_availability         VARCHAR2(200);
        l_flg_conflict              VARCHAR2(1) := pk_alert_constant.g_no;
        l_flg_bed_sts_toflash       VARCHAR2(1);
        l_flg_bed_clean_sts_toflash VARCHAR2(1);
        l_id_epis                   episode.id_episode%TYPE;
    
        l_err t_error_out;
        --
        CURSOR c_bed_actions IS
            SELECT DISTINCT bed.id_bed,
                            bbe.id_bmng_action,
                            bbe.flg_bed_ocupacity_status,
                            bbe.flg_bed_status,
                            bbe.flg_bed_cleaning_status,
                            bed.flg_type flg_bed_type,
                            bbe.dt_discharge_schedule,
                            bbe.id_episode
              FROM department dep
             INNER JOIN room r
                ON (r.id_department = dep.id_department AND r.flg_available = pk_alert_constant.g_yes)
             INNER JOIN bed bed
                ON (bed.id_room = r.id_room AND bed.flg_available = pk_alert_constant.g_yes)
              LEFT JOIN bmng_bed_ea bbe
                ON (bbe.id_bed = bed.id_bed)
              LEFT JOIN bmng_action ba
                ON ba.id_bed = bed.id_bed
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
              LEFT JOIN bmng_allocation_bed bab
                ON bab.id_bed = bed.id_bed
               AND bab.flg_outdated = pk_alert_constant.g_no
               AND bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
             WHERE dep.id_institution = i_prof.institution
               AND instr(dep.flg_type, 'I') > 0
               AND dep.flg_available = pk_alert_constant.g_yes
               AND (bed.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p OR
                   bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed)
               AND (dep.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(i_depart_arr) t) OR i_depart_arr IS NULL)
               AND (bbe.id_bmng_action IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(i_bmng_action_arr) t) OR i_bmng_action_arr IS NULL);
    
    BEGIN
        l_table := t_table_bmng_bed_status();
    
        IF ((i_depart_arr IS NULL OR i_depart_arr.count = 0) AND
           (i_bmng_action_arr IS NULL OR i_bmng_action_arr.count = 0))
        THEN
            g_error := 'CREATE NEW t_rec_bmng_bed_status RECORD';
            pk_alertlog.log_debug(g_error);
        
            l_table.extend;
        
            l_table(l_table.count) := t_rec_bmng_bed_status(NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL);
            RETURN l_table;
        END IF;
    
        FOR c_bed_act IN c_bed_actions
        LOOP
            l_table.extend;
        
            BEGIN
                g_error := 'LOG RECORD: bed.id_bed=' || c_bed_act.id_bed || ' 
                   bbe.id_bmng_action=' || c_bed_act.id_bmng_action || '
                   bbe.flg_bed_ocupacity_status=' || c_bed_act.flg_bed_ocupacity_status || '
                   bbe.flg_bed_status=' || c_bed_act.flg_bed_status || '
                   bbe.flg_bed_cleaning_status=' || c_bed_act.flg_bed_cleaning_status || '
                   bed.flg_bed_type=' || c_bed_act.flg_bed_type;
                pk_alertlog.log_debug(g_error);
            
                g_error := 'SET FLAGS';
                pk_alertlog.log_debug(g_error);
                l_id_bed                   := c_bed_act.id_bed;
                l_bmng_action              := c_bed_act.id_bmng_action;
                l_flg_bed_ocupacity_status := nvl(c_bed_act.flg_bed_ocupacity_status,
                                                  pk_bmng_constant.g_bmng_act_flg_ocupaci_v);
                l_flg_bed_status           := nvl(c_bed_act.flg_bed_status, pk_bmng_constant.g_bmng_bed_ea_flg_stat_n);
                l_flg_bed_cleaning_status  := c_bed_act.flg_bed_cleaning_status;
                l_flg_bed_type             := c_bed_act.flg_bed_type;
                l_dt_end                   := c_bed_act.dt_discharge_schedule;
                l_flg_conflict             := pk_alert_constant.g_no;
                l_id_epis                  := c_bed_act.id_episode;
            
                g_error := 'GET DESC CLEANING STATUS';
                pk_alertlog.log_debug(g_error);
                l_desc_cleaning_status := pk_sysdomain.get_domain('BMNG_ACTION.FLG_BED_CLEANING_STATUS',
                                                                  l_flg_bed_cleaning_status,
                                                                  i_lang);
            
                g_error := 'SET CLEANING ICON';
                pk_alertlog.log_debug(g_error);
                IF l_flg_bed_cleaning_status IS NOT NULL
                THEN
                    l_flg_bed_clean_sts_toflash := l_flg_bed_cleaning_status;
                    l_icon_bed_cleaning_status  := pk_sysdomain.get_img(i_lang,
                                                                        'BMNG_ACTION.FLG_BED_CLEANING_STATUS',
                                                                        l_flg_bed_cleaning_status);
                ELSE
                    l_icon_bed_cleaning_status  := '';
                    l_flg_bed_clean_sts_toflash := '';
                END IF;
            
                g_error := 'TEMPORARY BEDS';
                pk_alertlog.log_debug(g_error);
                IF (l_flg_bed_type = pk_bmng_constant.g_bmng_bed_flg_type_t)
                THEN
                    g_error := 'OCCUPIED';
                    IF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                    THEN
                        l_icon_bed_status := 'BedOccupiedOverbookingIcon';
                    
                        IF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_r)
                        THEN
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I003'); --Reserved bed
                            l_flg_bed_sts_toflash := 'R';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_n)
                        THEN
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I002'); --Occupy bed
                            l_flg_bed_sts_toflash := 'O';
                        END IF;
                    
                        l_desc_availability := l_desc_bed_status;
                    END IF;
                    --PERMANENT BEDS
                ELSIF (l_flg_bed_type = pk_bmng_constant.g_bmng_bed_flg_type_p)
                THEN
                    g_error := 'OCCUPIED';
                    pk_alertlog.log_debug(g_error);
                    IF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                    THEN
                        IF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_r)
                        THEN
                            l_icon_bed_status     := 'ReservedBedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I003'); --Reserved bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'R';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_s)
                        THEN
                            l_flg_conflict := pk_alert_constant.g_yes; --SCHEDULED
                        
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_n)
                        THEN
                            l_icon_bed_status     := 'OccupiedBedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I002'); --Occupy bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'O';
                        
                        END IF;
                    
                        --                        
                        l_availability := get_availability_int(i_lang, i_prof, l_id_bed);
                        IF pk_date_utils.diff_timestamp(l_dt_end, current_timestamp) > l_availability
                        THEN
                            l_flg_conflict := pk_alert_constant.g_yes;
                        END IF;
                    
                    ELSIF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v)
                    THEN
                        g_error := 'FREE';
                        pk_alertlog.log_debug(g_error);
                        IF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_b)
                        THEN
                            l_icon_bed_status     := 'FreeBedBlockedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I004'); --Block bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'B';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_s)
                        THEN
                            l_icon_bed_status := 'ScheduleBedIcon';
                            l_desc_bed_status := pk_message.get_message(i_lang, 'BMNG_I020'); --Schedule bed              
                            l_availability    := get_availability_int(i_lang, i_prof, l_id_bed);
                        
                            IF (l_availability = 1)
                            THEN
                                l_desc_availability := to_char(l_availability) ||
                                                       pk_message.get_message(i_lang, 'BMNG_T128');
                            ELSE
                                l_desc_availability := to_char(l_availability) ||
                                                       pk_message.get_message(i_lang, 'BMNG_T129');
                            END IF;
                        
                            l_flg_bed_sts_toflash := 'S';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_n)
                        THEN
                        
                            l_icon_bed_status     := 'FreeBedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I001'); --Free bed                        
                            l_flg_bed_sts_toflash := 'V';
                        
                            l_availability := get_availability_int(i_lang, i_prof, l_id_bed);
                        
                            IF (l_availability IS NULL)
                            THEN
                                l_desc_availability := l_desc_bed_status;
                            ELSE
                                l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I020');
                                l_flg_bed_sts_toflash := 'S';
                                l_icon_bed_status     := 'ScheduleBedIcon';
                            
                                IF (l_availability = 0)
                                THEN
                                    l_desc_availability := pk_message.get_message(i_lang, 'BMNG_M021');
                                ELSIF (l_availability = 1)
                                THEN
                                    l_desc_availability := to_char(l_availability) || ' ' ||
                                                           pk_message.get_message(i_lang, 'BMNG_T128');
                                
                                ELSE
                                    l_desc_availability := to_char(l_availability) || ' ' ||
                                                           pk_message.get_message(i_lang, 'BMNG_T129');
                                
                                END IF;
                                l_desc_bed_status := l_desc_availability;
                            
                            END IF;
                        
                        END IF;
                    END IF;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
            g_error := 'ADD NEW RECORD';
            pk_alertlog.log_debug(g_error);
            l_table(l_table.count) := t_rec_bmng_bed_status(l_id_bed,
                                                            l_bmng_action,
                                                            l_icon_bed_status,
                                                            l_icon_bed_cleaning_status,
                                                            l_desc_bed_status,
                                                            l_desc_cleaning_status,
                                                            l_availability,
                                                            l_desc_availability,
                                                            l_flg_conflict,
                                                            l_flg_bed_sts_toflash,
                                                            l_flg_bed_clean_sts_toflash);
        END LOOP;
    
        RETURN l_table;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_BED_STATUS',
                                              l_err);
            RETURN NULL;
        
    END tf_get_bed_status;

    /********************************************************************************************************************************************
    * TF_GET_ALL_BED_STATUS       Table function that returns all the necessary bed status information to be used by flash
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_BMNG_ACTION       Bed action identifier
    *
    * @return                     Returns table function with one record with the following information:
    *                             - icon_bed_status         
    *                             - icon_bed_cleaning_status
    *                             - desc_bed_status         
    *                             - desc_cleaning_status    
    *                             - availability            
    *                             - flg_conflict            
    * @author  Luís Maia
    * @version 2.5.0.5
    * @since   24-Ago-2009
    *******************************************************************************************************************************************/
    FUNCTION tf_get_all_bed_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_depart_arr      IN table_number DEFAULT NULL,
        i_bmng_action_arr IN table_number DEFAULT NULL
    ) RETURN t_table_bmng_bed_status IS
        l_table t_table_bmng_bed_status;
        --
        l_id_bed                   bmng_bed_ea.id_bed%TYPE;
        l_flg_bed_ocupacity_status bmng_bed_ea.flg_bed_ocupacity_status%TYPE;
        l_flg_bed_status           bmng_bed_ea.flg_bed_status%TYPE;
        l_flg_bed_cleaning_status  bmng_bed_ea.flg_bed_cleaning_status%TYPE;
        l_flg_bed_type             bmng_bed_ea.flg_bed_type%TYPE;
        --
        l_bmng_action               NUMBER(24);
        l_icon_bed_status           VARCHAR2(200);
        l_icon_bed_cleaning_status  VARCHAR2(200);
        l_desc_bed_status           VARCHAR2(200);
        l_desc_cleaning_status      VARCHAR2(200);
        l_availability              NUMBER(24);
        l_desc_availability         VARCHAR2(200);
        l_flg_conflict              VARCHAR2(1) := pk_alert_constant.g_no;
        l_flg_bed_sts_toflash       VARCHAR2(1);
        l_flg_bed_clean_sts_toflash VARCHAR2(1);
        l_err                       t_error_out;
        --
        CURSOR c_bed_actions IS
            SELECT /*+ leading(ba_final) */
            DISTINCT bed.id_bed,
                     ba_final.id_bmng_action,
                     ba_final.flg_bed_ocupacity_status,
                     ba_final.flg_bed_status,
                     ba_final.flg_bed_cleaning_status,
                     bed.flg_type flg_bed_type
              FROM department dep
             INNER JOIN room r
                ON (r.id_department = dep.id_department)
             INNER JOIN bed bed
                ON (bed.id_room = r.id_room)
             INNER JOIN (SELECT ba.id_bmng_action,
                                ba.flg_bed_ocupacity_status,
                                ba.flg_bed_status,
                                ba.flg_bed_cleaning_status,
                                ba.id_bed
                           FROM bmng_action ba
                          INNER JOIN (
                                     -- --
                                     SELECT ba2.id_bmng_allocation_bed, COUNT(1) ba_num
                                       FROM bmng_action ba2
                                      WHERE ba2.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                                        AND ba2.flg_action IN (pk_bmng_constant.g_bmng_flg_origin_ux_p,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_t)
                                        AND ba2.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                                      GROUP BY ba2.id_bmng_allocation_bed
                                     -- --
                                     ) ba_count
                             ON (ba_count.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND ba_count.ba_num = 1)
                          WHERE ba.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                            AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                         --
                         UNION ALL
                         --
                         SELECT ba.id_bmng_action,
                                ba.flg_bed_ocupacity_status,
                                ba.flg_bed_status,
                                ba.flg_bed_cleaning_status,
                                ba.id_bed
                           FROM bmng_action ba
                          INNER JOIN (
                                     -- --
                                     SELECT ba2.id_bmng_allocation_bed, COUNT(1) ba_num
                                       FROM bmng_action ba2
                                      WHERE ba2.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                                        AND ba2.flg_action IN (pk_bmng_constant.g_bmng_flg_origin_ux_o,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_r,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_d,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_c,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_i,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_l,
                                                               pk_bmng_constant.g_bmng_flg_origin_ux_e)
                                        AND ba2.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                                      GROUP BY ba2.id_bmng_allocation_bed
                                     -- --
                                     ) ba_count
                             ON (ba_count.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND ba_count.ba_num = 1)
                          INNER JOIN (
                                     -- --
                                     SELECT ba3.id_bed, ba3.id_bmng_allocation_bed, MAX(ba3.dt_creation) ba_dt
                                       FROM bmng_action ba3
                                      WHERE ba3.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                                        AND NOT ba3.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
                                      GROUP BY ba3.id_bed, ba3.id_bmng_allocation_bed
                                     -- --
                                     ) ba_date
                             ON (ba_date.id_bed = ba.id_bed AND ba_date.ba_dt = ba.dt_creation AND
                                ba_date.id_bmng_allocation_bed = ba.id_bmng_allocation_bed)
                          WHERE ba.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                            AND NOT ba.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
                         
                         --
                         UNION ALL
                         --
                         SELECT ba.id_bmng_action,
                                ba.flg_bed_ocupacity_status,
                                ba.flg_bed_status,
                                ba.flg_bed_cleaning_status,
                                ba.id_bed
                           FROM bmng_action ba
                          INNER JOIN (
                                     -- --
                                     SELECT ba2.id_bmng_allocation_bed, COUNT(1) ba_num
                                       FROM bmng_action ba2
                                      WHERE ba2.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                                        AND ba2.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
                                      GROUP BY ba2.id_bmng_allocation_bed
                                     -- --
                                     ) ba_count
                             ON (ba_count.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND ba_count.ba_num = 1)
                          INNER JOIN (
                                     -- --
                                     SELECT ba3.id_bed, ba3.id_bmng_allocation_bed, MAX(ba3.dt_creation) ba_dt
                                       FROM bmng_action ba3
                                      WHERE ba3.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                                        AND NOT ba3.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v
                                      GROUP BY ba3.id_bed, ba3.id_bmng_allocation_bed
                                     -- --
                                     ) ba_date
                             ON (ba_date.id_bed = ba.id_bed AND ba_date.ba_dt = ba.dt_creation AND
                                ba_date.id_bmng_allocation_bed = ba.id_bmng_allocation_bed)
                          WHERE ba.flg_origin_action = pk_bmng_constant.g_bmng_act_flg_origin_od
                            AND NOT ba.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v) ba_final
                ON (ba_final.id_bed = bed.id_bed)
             WHERE dep.id_institution = i_prof.institution
               AND instr(dep.flg_type, 'I') > 0
               AND (dep.id_department IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(i_depart_arr) t) OR i_depart_arr IS NULL)
               AND (ba_final.id_bmng_action IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                 t.column_value
                                                  FROM TABLE(i_bmng_action_arr) t) OR i_bmng_action_arr IS NULL);
    
    BEGIN
        l_table := t_table_bmng_bed_status();
    
        IF ((i_depart_arr IS NULL OR i_depart_arr.count = 0) AND
           (i_bmng_action_arr IS NULL OR i_bmng_action_arr.count = 0))
        THEN
            l_table.extend;
        
            l_table(l_table.count) := t_rec_bmng_bed_status(NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL);
            RETURN l_table;
        END IF;
    
        FOR c_bed_act IN c_bed_actions
        LOOP
            l_table.extend;
        
            g_error := 'LOG RECORD: bed.id_bed=' || c_bed_act.id_bed || ' 
                   bbe.id_bmng_action=' || c_bed_act.id_bmng_action || '
                   bbe.flg_bed_ocupacity_status=' || c_bed_act.flg_bed_ocupacity_status || '
                   bbe.flg_bed_status=' || c_bed_act.flg_bed_status || '
                   bbe.flg_bed_cleaning_status=' || c_bed_act.flg_bed_cleaning_status || '
                   bed.flg_bed_type=' || c_bed_act.flg_bed_type;
            pk_alertlog.log_debug(g_error);
        
            BEGIN
                g_error := 'SET FLAGS';
                pk_alertlog.log_debug(g_error);
            
                l_id_bed                   := c_bed_act.id_bed;
                l_bmng_action              := c_bed_act.id_bmng_action;
                l_flg_bed_ocupacity_status := nvl(c_bed_act.flg_bed_ocupacity_status,
                                                  pk_bmng_constant.g_bmng_act_flg_ocupaci_v);
                l_flg_bed_status           := nvl(c_bed_act.flg_bed_status, pk_bmng_constant.g_bmng_bed_ea_flg_stat_n);
                l_flg_bed_cleaning_status  := c_bed_act.flg_bed_cleaning_status;
                l_flg_bed_type             := c_bed_act.flg_bed_type;
            
                g_error := 'GET DESC CLEANING STATUS';
                pk_alertlog.log_debug(g_error);
                l_desc_cleaning_status := pk_sysdomain.get_domain('BMNG_ACTION.FLG_BED_CLEANING_STATUS',
                                                                  l_flg_bed_cleaning_status,
                                                                  i_lang);
            
                g_error := 'SET CLEANING ICON';
                pk_alertlog.log_debug(g_error);
                IF l_flg_bed_cleaning_status IS NOT NULL
                THEN
                    l_flg_bed_clean_sts_toflash := l_flg_bed_cleaning_status;
                    l_icon_bed_cleaning_status  := pk_sysdomain.get_img(i_lang,
                                                                        'BMNG_ACTION.FLG_BED_CLEANING_STATUS',
                                                                        l_flg_bed_cleaning_status);
                ELSE
                    l_icon_bed_cleaning_status  := '';
                    l_flg_bed_clean_sts_toflash := '';
                END IF;
            
                g_error := 'TEMPORARY BEDS';
                pk_alertlog.log_debug(g_error);
                IF (l_flg_bed_type = pk_bmng_constant.g_bmng_bed_flg_type_t)
                THEN
                    g_error := 'OCCUPIED';
                    IF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                    THEN
                        l_icon_bed_status := 'BedOccupiedOverbookingIcon';
                    
                        IF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_r)
                        THEN
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I003'); --Reserved bed
                            l_flg_bed_sts_toflash := 'R';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_n)
                        THEN
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I002'); --Occupy bed
                            l_flg_bed_sts_toflash := 'O';
                        END IF;
                    
                        l_desc_availability := l_desc_bed_status;
                    END IF;
                    --PERMANENT BEDS
                ELSIF (l_flg_bed_type = pk_bmng_constant.g_bmng_bed_flg_type_p)
                THEN
                    g_error := 'OCCUPIED';
                    pk_alertlog.log_debug(g_error);
                    IF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                    THEN
                        IF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_r)
                        THEN
                            l_icon_bed_status     := 'ReservedBedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I003'); --Reserved bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'R';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_s)
                        THEN
                            l_flg_conflict := pk_alert_constant.g_yes; --SCHEDULED
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_n)
                        THEN
                            l_icon_bed_status     := 'OccupiedBedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I002'); --Occupy bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'O';
                        END IF;
                        g_error := 'FREE';
                        pk_alertlog.log_debug(g_error);
                    ELSIF (l_flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v)
                    THEN
                        IF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_b)
                        THEN
                            l_icon_bed_status     := 'FreeBedBlockedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I004'); --Block bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'B';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_s)
                        THEN
                            l_icon_bed_status := 'ScheduleBedIcon';
                            l_desc_bed_status := pk_message.get_message(i_lang, 'BMNG_I020'); --Schedule bed              
                            l_availability    := get_availability_int(i_lang, i_prof, l_id_bed);
                        
                            IF (l_availability = 1)
                            THEN
                                l_desc_availability := to_char(l_availability) || ' day';
                            ELSE
                                l_desc_availability := to_char(l_availability) || ' days';
                            END IF;
                        
                            l_flg_bed_sts_toflash := 'S';
                        ELSIF (l_flg_bed_status = pk_bmng_constant.g_bmng_bed_ea_flg_stat_n)
                        THEN
                            l_icon_bed_status     := 'FreeBedIcon';
                            l_desc_bed_status     := pk_message.get_message(i_lang, 'BMNG_I001'); --Free bed
                            l_desc_availability   := l_desc_bed_status;
                            l_flg_bed_sts_toflash := 'V';
                        END IF;
                    END IF;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
            g_error := 'ADD NEW RECORD';
            pk_alertlog.log_debug(g_error);
            l_table(l_table.count) := t_rec_bmng_bed_status(l_id_bed,
                                                            l_bmng_action,
                                                            l_icon_bed_status,
                                                            l_icon_bed_cleaning_status,
                                                            l_desc_bed_status,
                                                            l_desc_cleaning_status,
                                                            l_availability,
                                                            l_desc_availability,
                                                            l_flg_conflict,
                                                            l_flg_bed_sts_toflash,
                                                            l_flg_bed_clean_sts_toflash);
        END LOOP;
    
        RETURN l_table;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ALL_BED_STATUS',
                                              l_err);
            RETURN NULL;
        
    END tf_get_all_bed_status;

    /***************************************************************************************************************
    *
    * Returns the number of active actions in the same bed that have a provided status.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID of the episode.
    * @param      i_flg_bed_status    FLG status to count.
    *
    * @RETURN  NUMBER 
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.5
    * @since   24-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_count_bed_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_bed_status IN bmng_action.flg_status%TYPE
        
    ) RETURN NUMBER IS
        l_err t_error_out;
        l_acc PLS_INTEGER;
    BEGIN
        g_error := 'COUNT';
        pk_alertlog.log_debug(g_error);
        IF i_flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n
        THEN
            SELECT COUNT(ba.id_bmng_action)
              INTO l_acc
              FROM bmng_action ba
             INNER JOIN bmng_allocation_bed bab
                ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND
                   bab.flg_outdated = pk_alert_constant.g_no)
             WHERE bab.id_episode = i_episode
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND (ba.flg_bed_status = i_flg_bed_status OR ba.flg_bed_status IS NULL);
        ELSE
            SELECT COUNT(ba.id_bmng_action)
              INTO l_acc
              FROM bmng_action ba
             INNER JOIN bmng_allocation_bed bab
                ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND
                   bab.flg_outdated = pk_alert_constant.g_no)
             WHERE bab.id_episode = i_episode
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND ba.flg_bed_status = i_flg_bed_status;
        END IF;
    
        RETURN l_acc;
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_count_bed_status',
                                              l_err);
            RETURN 0;
        
    END get_count_bed_status;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_request_type      'A': All, 'P': Past, 'F': Future, 'D': Specific date
    * @param IN   i_request_date      request date when i_request_type = 'D'
    * @param IN   i_origin_action     ['N': 'NB', 'NT', 'ND'], ['B': 'BT', 'BD']
    *
    * @param OUT  o_intervals         Output cursor containing the intervals
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_bmng_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN department.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_request_date      IN bmng_action.dt_begin_action%TYPE,
        i_origin_action     IN bmng_action.flg_origin_action%TYPE,
        o_intervals         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO MAIN FUNCTION WITH i_department=' || i_department || ' i_request_date=' || i_request_date ||
                   ' i_flg_target_action=' || i_flg_target_action;
        IF NOT get_bmng_intervals(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_flg_target_action => i_flg_target_action,
                                  i_department        => i_department,
                                  i_request_type      => i_request_type,
                                  i_begin_date        => i_request_date,
                                  i_end_date          => NULL,
                                  i_origin_action     => i_origin_action,
                                  o_intervals         => o_intervals,
                                  o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_intervals);
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
                                              'GET_BMNG_INTERVALS',
                                              o_error);
            pk_types.open_my_cursor(o_intervals);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_request_type      'A': All, 'P': Past, 'F': Future, 'D': Specific date
    * @param IN   i_begin_date        request begin date when i_request_type = 'D'
    * @param IN   i_end_date          request end date when i_request_type = 'D'
    * @param IN   i_origin_action     ['N': 'NB', 'NT', 'ND'], ['B': 'BT', 'BD']
    *
    * @param OUT  o_intervals         Output cursor containing the intervals
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    20/07/2009
    ********************************************************************************************/
    FUNCTION get_bmng_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN department.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_begin_date        IN bmng_action.dt_begin_action%TYPE,
        i_end_date          IN bmng_action.dt_end_action%TYPE,
        i_origin_action     IN bmng_action.flg_origin_action%TYPE,
        o_intervals         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        bmng_intervals_exception EXCEPTION;
    
        l_num_days_limit PLS_INTEGER := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_config_tools_hist, i_prof) * 30;
        l_num_days_diff  PLS_INTEGER;
    
        CURSOR c_max_dates IS
            SELECT to_date(to_char(MIN(ba.dt_begin_action) - 1, 'YYYYMMDD'), 'YYYYMMDD'),
                   to_date(to_char(MAX(ba.dt_begin_action) + 1, 'YYYYMMDD'), 'YYYYMMDD'),
                   to_date(to_char(MAX(ba.dt_end_action) + 1, 'YYYYMMDD'), 'YYYYMMDD')
              FROM bmng_action ba
             WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a -- 'A': Active
               AND ba.id_department = i_department
               AND ((i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_n AND
                   ba.flg_origin_action IN (pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                              pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                              pk_bmng_constant.g_bmng_act_flg_origin_nd)) OR
                   (i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_b AND
                   ba.flg_origin_action IN
                   (pk_bmng_constant.g_bmng_act_flg_origin_bt, pk_bmng_constant.g_bmng_act_flg_origin_bd)))
               AND decode(ba.flg_target_action,
                          pk_bmng_constant.g_bmng_act_flg_target_s,
                          1,
                          pk_bmng_constant.g_bmng_act_flg_target_r,
                          2,
                          pk_bmng_constant.g_bmng_act_flg_target_b,
                          3) <= decode(i_flg_target_action,
                                       pk_bmng_constant.g_bmng_act_flg_target_s,
                                       1,
                                       pk_bmng_constant.g_bmng_act_flg_target_r,
                                       2,
                                       pk_bmng_constant.g_bmng_act_flg_target_b,
                                       3,
                                       4);
    
        CURSOR c_intervals
        (
            l_dt_begin_request bmng_action.dt_begin_action%TYPE,
            l_dt_end_request   bmng_action.dt_begin_action%TYPE
        ) IS
            SELECT ba.id_bmng_action, ba.nch_capacity, ba.dt_begin_action, ba.dt_end_action
              FROM bmng_action ba
             WHERE l_dt_end_request >= ba.dt_begin_action
               AND (l_dt_begin_request <= ba.dt_end_action OR ba.dt_end_action IS NULL)
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a -- 'A': Active
               AND ba.id_department = i_department
               AND ((i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_n AND
                   ba.flg_origin_action IN (pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                              pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                              pk_bmng_constant.g_bmng_act_flg_origin_nd)) OR
                   (i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_b AND
                   ba.flg_origin_action IN
                   (pk_bmng_constant.g_bmng_act_flg_origin_bt, pk_bmng_constant.g_bmng_act_flg_origin_bd)))
               AND ba.dt_creation =
                   (SELECT MAX(ba2.dt_creation)
                      FROM bmng_action ba2
                     WHERE l_dt_end_request >= ba2.dt_begin_action
                       AND (l_dt_begin_request <= ba2.dt_end_action OR ba2.dt_end_action IS NULL)
                       AND ba2.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                       AND ba2.id_department = i_department
                       AND ((i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_n AND
                           ba2.flg_origin_action IN
                           (pk_bmng_constant.g_bmng_act_flg_origin_nb,
                              pk_bmng_constant.g_bmng_act_flg_origin_nt,
                              pk_bmng_constant.g_bmng_act_flg_origin_nd)) OR
                           (i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_b AND
                           ba2.flg_origin_action IN
                           (pk_bmng_constant.g_bmng_act_flg_origin_bt, pk_bmng_constant.g_bmng_act_flg_origin_bd)))
                       AND decode(ba2.flg_target_action,
                                  pk_bmng_constant.g_bmng_act_flg_target_s,
                                  1,
                                  pk_bmng_constant.g_bmng_act_flg_target_r,
                                  2,
                                  pk_bmng_constant.g_bmng_act_flg_target_b,
                                  3) <= decode(i_flg_target_action,
                                               pk_bmng_constant.g_bmng_act_flg_target_s,
                                               1,
                                               pk_bmng_constant.g_bmng_act_flg_target_r,
                                               2,
                                               pk_bmng_constant.g_bmng_act_flg_target_b,
                                               3,
                                               4));
    
        l_min_begin_date bmng_action.dt_begin_action%TYPE;
        l_max_begin_date bmng_action.dt_begin_action%TYPE;
        l_max_end_date   bmng_action.dt_end_action%TYPE;
    
        l_array_index      PLS_INTEGER;
        l_dt_request       bmng_action.dt_begin_action%TYPE;
        l_dt_begin_request bmng_action.dt_begin_action%TYPE;
        l_dt_end_request   bmng_action.dt_begin_action%TYPE;
        l_ins_dt_request   bmng_action.dt_begin_action%TYPE;
    
        l_bmng_array     table_number := table_number();
        l_nch_array      table_number := table_number();
        l_dt_gegin_array table_date := table_date();
        l_dt_end_array   table_date := table_date();
    
        l_id_bmng_action  bmng_action.id_bmng_action%TYPE;
        l_nch_capacity    bmng_action.nch_capacity%TYPE;
        l_dt_begin_action bmng_action.dt_begin_action%TYPE;
        l_dt_end_action   bmng_action.dt_end_action%TYPE;
    
    BEGIN
        --------------------------------------------------
        -- request_type should be one of the specified
        IF upper(i_request_type) NOT IN (pk_bmng_constant.g_bmng_intervals_req_type_a,
                                         pk_bmng_constant.g_bmng_intervals_req_type_p,
                                         pk_bmng_constant.g_bmng_intervals_req_type_f,
                                         pk_bmng_constant.g_bmng_intervals_req_type_d)
        THEN
            RAISE bmng_intervals_exception;
        END IF;
    
        --------------------------------------------------
        -- obtain min begin_date and max end_date, necessary for interval calculation
        g_error := 'OPEN C_MAX_DATES';
        pk_alertlog.log_debug(g_error);
        OPEN c_max_dates;
        FETCH c_max_dates
            INTO l_min_begin_date, l_max_begin_date, l_max_end_date;
        g_found := c_max_dates%FOUND;
        CLOSE c_max_dates;
        IF NOT g_found -- not found or no dates specified then it's an exception
          --OR l_max_end_date IS NULL
           OR l_min_begin_date IS NULL
        THEN
            RAISE bmng_intervals_exception;
        END IF;
    
        IF l_max_end_date < l_max_begin_date
        THEN
            l_max_end_date := l_max_begin_date;
        END IF;
    
        IF l_max_end_date IS NULL
        THEN
            SELECT to_date(to_char(MAX(ba.dt_end_action) + 1, 'YYYYMMDD'), 'YYYYMMDD')
              INTO l_max_end_date
              FROM bmng_action ba;
        END IF;
    
        IF l_max_end_date IS NULL
        THEN
            l_max_end_date := l_min_begin_date + 365; -- one year
        END IF;
    
        --------------------------------------------------
        -- process dates depending on i_request_type
        IF upper(i_request_type) = pk_bmng_constant.g_bmng_intervals_req_type_a -- all intervals
        THEN
            l_min_begin_date := l_min_begin_date;
            l_max_end_date   := l_max_end_date;
        ELSIF upper(i_request_type) = pk_bmng_constant.g_bmng_intervals_req_type_p -- past intervals
        THEN
            l_min_begin_date := l_min_begin_date;
            l_max_end_date   := trunc(current_timestamp) - 1;
        ELSIF upper(i_request_type) = pk_bmng_constant.g_bmng_intervals_req_type_f -- future intervals
        THEN
            l_min_begin_date := trunc(current_timestamp) + 1;
            l_max_end_date   := l_max_end_date;
        ELSIF upper(i_request_type) = pk_bmng_constant.g_bmng_intervals_req_type_d -- interval for a specific date
        THEN
            -----------------------------
            IF i_begin_date IS NOT NULL
               AND i_end_date IS NOT NULL
            THEN
                IF l_max_end_date > l_min_begin_date
                THEN
                    l_min_begin_date := to_date(to_char(i_begin_date, 'YYYYMMDD'), 'YYYYMMDD');
                    l_max_end_date   := to_date(to_char(i_end_date, 'YYYYMMDD'), 'YYYYMMDD');
                ELSE
                    l_min_begin_date := to_date(to_char(i_end_date, 'YYYYMMDD'), 'YYYYMMDD');
                    l_max_end_date   := to_date(to_char(i_begin_date, 'YYYYMMDD'), 'YYYYMMDD');
                END IF;
                -------------------------
            ELSIF i_begin_date IS NOT NULL
                  AND i_end_date IS NULL
            THEN
                l_min_begin_date := to_date(to_char(i_begin_date, 'YYYYMMDD'), 'YYYYMMDD');
                l_max_end_date   := l_max_end_date;
                -------------------------
            ELSIF i_begin_date IS NULL
                  AND i_end_date IS NOT NULL
            THEN
                l_min_begin_date := l_min_begin_date;
                l_max_end_date   := to_date(to_char(i_end_date, 'YYYYMMDD'), 'YYYYMMDD');
                -------------------------
            ELSE
                /*                l_min_begin_date := l_min_begin_date;
                l_max_end_date   := l_max_end_date;*/
                l_min_begin_date := to_date(to_char(current_timestamp, 'YYYYMMDD'), 'YYYYMMDD');
                l_max_end_date   := to_date(to_char(current_timestamp, 'YYYYMMDD'), 'YYYYMMDD');
            END IF;
            -----------------------------
        END IF;
    
        --------------------------------------------------
        -- calculate days_diff
        g_error := 'GET PK_DATE_UTILS.GET_TIMESTAMP_DIFF';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                i_timestamp_1 => l_max_end_date,
                                                i_timestamp_2 => l_min_begin_date,
                                                o_days_diff   => l_num_days_diff,
                                                o_error       => o_error)
        THEN
            RAISE bmng_intervals_exception;
        END IF;
    
        --------------------------------------------------
        -- if calculated elapsed time if bigger than the max defined then truncate it
        IF l_num_days_diff > l_num_days_limit
        THEN
            l_num_days_diff := l_num_days_limit;
        ELSIF l_num_days_diff <= 1 -- if request_type = 'D' then l_num_days_diff = 0
              AND upper(i_request_type) = pk_bmng_constant.g_bmng_intervals_req_type_d
        THEN
            l_num_days_diff := 1;
        END IF;
    
        --------------------------------------------------
        -- extend arrays to the num of days of elapsed time between dt_begin and dt_end
        l_bmng_array.extend(l_num_days_diff);
        l_nch_array.extend(l_num_days_diff);
        l_dt_gegin_array.extend(l_num_days_diff);
        l_dt_end_array.extend(l_num_days_diff);
        l_array_index := 1;
    
        -------------------------------------------------------------
        -- start LOOP to search for date intervals
        l_dt_request := l_min_begin_date - 1;
    
        g_error := 'LOOP POSSIBLE DATES';
        pk_alertlog.log_debug(g_error);
        LOOP
            g_error := 'OPEN C_INTERVALS / l_array_index: ' || to_char(l_array_index);
            pk_alertlog.log_debug(g_error);
            l_dt_request       := l_dt_request + 1;
            l_dt_begin_request := to_date(to_char(l_dt_request, 'YYYYMMDD') || '000000', 'YYYYMMDDHH24MISS');
            l_dt_end_request   := to_date(to_char(l_dt_request, 'YYYYMMDD') || '235959', 'YYYYMMDDHH24MISS');
        
            IF upper(i_request_type) IN
               (pk_bmng_constant.g_bmng_intervals_req_type_f, pk_bmng_constant.g_bmng_intervals_req_type_p)
               AND ((l_dt_request >= l_max_end_date) OR (l_array_index >= l_num_days_diff + 1))
            THEN
                EXIT;
            END IF;
        
            OPEN c_intervals(l_dt_begin_request, l_dt_end_request);
            FETCH c_intervals
                INTO l_id_bmng_action, l_nch_capacity, l_dt_begin_action, l_dt_end_action;
            g_found := c_intervals%FOUND;
            CLOSE c_intervals;
        
            l_ins_dt_request := l_dt_begin_request; --to_date(to_char(l_dt_request, 'YYYYMMDD') || '000000', 'YYYYMMDDHH24MISS');
        
            IF g_found
            THEN
                IF l_array_index >= 2 -- if next interval is the same than the previous, simply update end_date
                   AND l_id_bmng_action = l_bmng_array(l_array_index - 1)
                THEN
                    l_dt_end_array(l_array_index - 1) := l_ins_dt_request;
                ELSE
                    l_bmng_array(l_array_index) := l_id_bmng_action;
                    l_nch_array(l_array_index) := l_nch_capacity;
                    IF l_array_index = 1 -- if first record, the start date is the record date and not the period of analysis
                    THEN
                        l_dt_gegin_array(l_array_index) := to_date(to_char(l_dt_begin_action, 'YYYYMMDD'), 'YYYYMMDD');
                    ELSE
                        l_dt_gegin_array(l_array_index) := l_ins_dt_request;
                    END IF;
                    l_dt_end_array(l_array_index) := l_ins_dt_request;
                    l_array_index := l_array_index + 1;
                END IF;
            ELSE
                -- calculate blank periods
                IF l_array_index >= 2 -- there must be at least one record for blank periods calculation
                THEN
                    IF l_bmng_array(l_array_index - 1) IS NULL --= -1
                    THEN
                        l_dt_end_array(l_array_index - 1) := l_ins_dt_request;
                    ELSE
                        l_bmng_array(l_array_index) := NULL; ---1;
                        l_nch_array(l_array_index) := NULL;
                        l_dt_gegin_array(l_array_index) := l_ins_dt_request;
                        l_dt_end_array(l_array_index) := l_ins_dt_request;
                        l_array_index := l_array_index + 1;
                    END IF;
                END IF;
            END IF;
        
            EXIT WHEN(l_dt_request >= l_max_end_date) OR(l_array_index >= l_num_days_diff + 1);
        
        END LOOP;
        g_error := 'OUT OF THE LOOP';
        pk_alertlog.log_debug(g_error);
        --------------------------------------------------
        -- last steps to process output cursor: o_intervals
        IF l_array_index > 1
        THEN
            --------------------------------------------------
            -- treatment of the arrays last position to include null end dates
            l_array_index := l_array_index - 1; -- move index to the last position
            IF l_bmng_array(l_array_index) IS NULL
            THEN
                l_dt_end_array(l_array_index) := NULL;
            ELSIF l_dt_end_action IS NULL
            THEN
                l_dt_end_array(l_array_index) := NULL;
            ELSE
                l_dt_end_array(l_array_index) := to_date(to_char(l_dt_end_action, 'YYYYMMDD'), 'YYYYMMDD');
            END IF;
        
            --------------------------------------------------
            -- process output cursor
            g_error := 'OPEN O_INTERVALS';
            pk_alertlog.log_debug(g_error);
            OPEN o_intervals FOR
            
                SELECT a.value id_bmng_action, b.value nch, c.value dt_begin, d.value dt_end
                  FROM (SELECT rownum rnum, column_value VALUE
                          FROM TABLE(l_bmng_array)) a,
                       (SELECT rownum rnum, column_value VALUE
                          FROM TABLE(l_nch_array)) b,
                       (SELECT rownum rnum, column_value VALUE
                          FROM TABLE(l_dt_gegin_array)) c,
                       (SELECT rownum rnum, column_value VALUE
                          FROM TABLE(l_dt_end_array)) d
                 WHERE a.rnum = b.rnum
                   AND b.rnum = c.rnum
                   AND c.rnum = d.rnum
                   AND c.value IS NOT NULL; -- despite id_bmng_action may be null, the star date always exists
        ELSE
            --------------------------------------------------
            -- no records to be processed: then it's an interval with no start or end date
            g_error := 'OPEN NULL O_INTERVALS';
            pk_alertlog.log_debug(g_error);
            OPEN o_intervals FOR
                SELECT NULL id_bmng_action, NULL nch, NULL dt_begin, NULL dt_end
                  FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bmng_intervals_exception THEN
            g_error := 'OPEN NULL O_INTERVALS';
            pk_alertlog.log_debug(g_error);
            OPEN o_intervals FOR
                SELECT NULL id_bmng_action, NULL nch, NULL dt_begin, NULL dt_end
                  FROM dual;
            RETURN TRUE; -- this exception don't mean the functions missworked so it returns TRUE
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BMNG_INTERVALS',
                                              o_error);
            pk_types.open_my_cursor(o_intervals);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns an array of departments (not cursor) belonging to an institution
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_institution  Institution ID
    
    * @param OUT  o_deps         Departments array (table_number)
    *
    * @return  Returns TRUE if success, otherwise returns FALSE
    *
    * @author                   Pedro Teixeira
    * @version 2.5.0.5
    * @since                    27/07/2009
    ********************************************************************************************/
    FUNCTION get_institution_departments
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_deps        OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_institution IS NOT NULL
        THEN
            g_error := 'GET O_DEPS';
            pk_alertlog.log_debug(g_error);
            SELECT d.id_department
              BULK COLLECT
              INTO o_deps
              FROM department d
             WHERE d.id_institution = i_institution
               AND d.flg_available = pk_alert_constant.g_yes;
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
                                              'GET_INSTITUTION_DEPARTMENTS',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************************************************************
    * GET_TIME_FRAME_INT       Function that returns the NCH/day group
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_NCH_CAPACITY   NCH capacity
    *
    * @return                  Returns the NCH/day group
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   24-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_nch_day_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nch_capacity bmng_action.nch_capacity%TYPE
    ) RETURN VARCHAR2 IS
        l_nch_day    PLS_INTEGER;
        l_nch_median PLS_INTEGER;
        l_nch_group  sys_message.desc_message%TYPE;
        l_aux        sys_message.desc_message%TYPE;
        l_err        t_error_out;
    BEGIN
        l_nch_day    := to_number(pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_dep, i_prof));
        l_nch_median := to_number(pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_median, i_prof));
    
        l_nch_group := NULL;
        g_error     := 'BEGIN WITH i_nch_capacity=' || i_nch_capacity;
        pk_alertlog.log_debug(g_error);
        IF (i_nch_capacity IS NOT NULL AND l_nch_day IS NOT NULL)
        THEN
            IF (i_nch_capacity < l_nch_day - l_nch_median)
            THEN
                l_nch_group := REPLACE(pk_message.get_message(i_lang, 'BMNG_T113'),
                                       '@1',
                                       to_char(l_nch_day - l_nch_median));
            ELSIF (i_nch_capacity <= l_nch_day)
            THEN
                l_aux       := pk_message.get_message(i_lang, 'BMNG_T114');
                l_nch_group := REPLACE(REPLACE(l_aux, '@1', to_char(l_nch_day - l_nch_median)),
                                       '@2',
                                       to_char(l_nch_day));
            ELSIF (i_nch_capacity <= l_nch_day + l_nch_median)
            THEN
                l_aux       := pk_message.get_message(i_lang, 'BMNG_T114');
                l_nch_group := REPLACE(REPLACE(l_aux, '@1', to_char(l_nch_day + 1)),
                                       '@2',
                                       to_char(l_nch_day + l_nch_median));
            ELSE
                l_nch_group := REPLACE(pk_message.get_message(i_lang, 'BMNG_T115'),
                                       '@1',
                                       to_char(l_nch_day + l_nch_median));
            END IF;
        ELSE
            l_nch_group := pk_message.get_message(i_lang, 'BMNG_T116');
        END IF;
    
        RETURN l_nch_group;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_DAY_INT',
                                              l_err);
        
            RETURN NULL;
    END get_nch_day_int;

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointment in the given date
    * - i_date is null and i_id_bed is null -> returns all the future bed appointments
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_bed                        Bed identiifcation
    * @param o_next_sch_dt                   Next schedule date
    * @param o_id_patient                    Patient id of the next schedule    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Ricardo Almeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_next_schedule_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE DEFAULT NULL,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_err   t_error_out;
        l_cur   pk_types.cursor_type;
        l_ret   schedule.dt_schedule_tstz%TYPE;
        l_dummy VARCHAR2(4000);
    BEGIN
        g_error := 'START FUNCTION With i_id_bed=' || i_id_bed;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_schedule_inp.get_next_schedule_date(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_bed => i_id_bed,
                                                      i_date   => i_date,
                                                      o_data   => l_cur,
                                                      o_error  => l_err)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'OPEN CURSOR O_DATA';
        pk_alertlog.log_debug(g_error);
    
        LOOP
            FETCH l_cur
                INTO l_dummy, l_ret, l_dummy;
            EXIT WHEN l_cur%NOTFOUND;
        
        END LOOP;
    
        CLOSE l_cur;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_SCH_DATE',
                                              l_err);
            RETURN NULL;
    END get_next_schedule_date;

    /********************************************************************************************
    * Returns BMNG intervals - regardless of being free ou with active NCH 
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_flg_target_action If its Bed, Room or Service level action
    * @param IN   i_department        Department ID
    * @param IN   i_request_type      'A': All, 'P': Past, 'F': Future, 'D': Specific date, 'C': Cancelled
    * @param IN   i_request_date      request date when i_request_type = 'D'
    * @param IN   i_origin_action     ['N': 'NB', 'NT', 'ND'], ['B': 'BT', 'BD']
    *
    * @return  Returns table containing the intervals
    *
    * @author                   Alexandre Santos
    * @version 2.5.0.5
    * @since                    27/07/2009
    ********************************************************************************************/
    FUNCTION tf_get_bmng_intervals
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_target_action IN bmng_action.flg_target_action%TYPE,
        i_department        IN bmng_action.id_department%TYPE,
        i_request_type      IN VARCHAR2,
        i_request_date      IN bmng_action.dt_begin_action%TYPE,
        i_origin_action     IN bmng_action.flg_origin_action%TYPE
    ) RETURN t_table_bmng_interval IS
        l_table t_table_bmng_interval := t_table_bmng_interval();
        --
        l_intervals pk_types.cursor_type;
    
        l_err t_error_out;
    
        l_num_days_limit   PLS_INTEGER := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_config_tools_hist, i_prof) * 30;
        l_sysdate_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_request bmng_action.dt_begin_action%TYPE;
        l_dt_end_request   bmng_action.dt_end_action%TYPE;
    
        CURSOR c_intervals
        (
            l_dt_begin_request bmng_action.dt_begin_action%TYPE,
            l_dt_end_request   bmng_action.dt_begin_action%TYPE
        ) IS
            SELECT ba.id_bmng_action, ba.nch_capacity, ba.dt_begin_action, ba.dt_end_action
              FROM bmng_action ba
             WHERE ba.dt_begin_action >= l_dt_begin_request
               AND (ba.dt_end_action <= l_dt_end_request OR ba.dt_end_action IS NULL)
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_c -- 'C': Cancelled
               AND ba.id_department = i_department
               AND ((i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_n AND
                   ba.flg_origin_action IN (pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                              pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                              pk_bmng_constant.g_bmng_act_flg_origin_nd)) OR
                   (i_origin_action = pk_bmng_constant.g_bmng_intervals_orig_act_b AND
                   ba.flg_origin_action IN
                   (pk_bmng_constant.g_bmng_act_flg_origin_bt, pk_bmng_constant.g_bmng_act_flg_origin_bd)))
               AND decode(ba.flg_target_action,
                          pk_bmng_constant.g_bmng_act_flg_target_s,
                          1,
                          pk_bmng_constant.g_bmng_act_flg_target_r,
                          2,
                          pk_bmng_constant.g_bmng_act_flg_target_b,
                          3) <= decode(i_flg_target_action,
                                       pk_bmng_constant.g_bmng_act_flg_target_s,
                                       1,
                                       pk_bmng_constant.g_bmng_act_flg_target_r,
                                       2,
                                       pk_bmng_constant.g_bmng_act_flg_target_b,
                                       3,
                                       4);
        --
        l_error t_error_out;
        --
        l_id_bmng_action bmng_action.id_bmng_action%TYPE;
        l_nch            bmng_action.nch_capacity%TYPE;
        l_dt_begin       DATE;
        l_dt_end         DATE;
    BEGIN
        IF i_request_type != pk_bmng_constant.g_bmng_intervals_req_type_c
        THEN
            g_error := 'CALL GET_BMNG_INTERVALS';
            --no need to specify variables, done in the function
            pk_alertlog.log_debug(g_error);
            IF pk_bmng_core.get_bmng_intervals(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_flg_target_action => i_flg_target_action,
                                               i_department        => i_department,
                                               i_request_type      => i_request_type,
                                               i_request_date      => i_request_date,
                                               i_origin_action     => i_origin_action,
                                               o_intervals         => l_intervals,
                                               o_error             => l_error)
            THEN
                IF l_intervals IS NOT NULL
                THEN
                    LOOP
                        FETCH l_intervals
                            INTO l_id_bmng_action, l_nch, l_dt_begin, l_dt_end;
                        EXIT WHEN l_intervals%NOTFOUND;
                    
                        l_table.extend;
                        l_table(l_table.count) := t_rec_bmng_interval(i_department,
                                                                      l_id_bmng_action,
                                                                      l_nch,
                                                                      l_dt_begin,
                                                                      l_dt_end);
                    END LOOP;
                
                    CLOSE l_intervals;
                END IF;
            END IF;
        END IF;
    
        IF i_request_type = pk_bmng_constant.g_bmng_intervals_req_type_c
           OR i_request_type = pk_bmng_constant.g_bmng_intervals_req_type_a
        THEN
            l_sysdate_tstz     := current_timestamp;
            l_dt_begin_request := to_date(to_char(l_sysdate_tstz - l_num_days_limit, 'YYYYMMDD') || '000000',
                                          'YYYYMMDDHH24MISS');
            l_dt_end_request   := to_date(to_char(l_sysdate_tstz + l_num_days_limit, 'YYYYMMDD') || '235959',
                                          'YYYYMMDDHH24MISS');
        
            g_error := 'OPEN C_INTERVALS With l_dt_begin_request=' || l_dt_begin_request || ' l_dt_end_request=' ||
                       l_dt_end_request;
            pk_alertlog.log_debug(g_error);
            OPEN c_intervals(l_dt_begin_request, l_dt_end_request);
            LOOP
                FETCH c_intervals
                    INTO l_id_bmng_action, l_nch, l_dt_begin, l_dt_end;
                EXIT WHEN c_intervals%NOTFOUND;
            
                l_table.extend;
                l_table(l_table.count) := t_rec_bmng_interval(i_department,
                                                              l_id_bmng_action,
                                                              l_nch,
                                                              l_dt_begin,
                                                              l_dt_end);
            END LOOP;
            CLOSE c_intervals;
        END IF;
    
        IF (i_request_type != pk_bmng_constant.g_bmng_intervals_req_type_c AND l_table.count = 0)
        THEN
            g_error := 'IF l_table.COUNT=0';
            pk_alertlog.log_debug(g_error);
            l_table.extend;
            l_table(l_table.count) := t_rec_bmng_interval(i_department, NULL, NULL, NULL, NULL);
        END IF;
    
        RETURN l_table;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_BMNG_INTERVALS',
                                              l_err);
        
            RETURN NULL;
        
    END tf_get_bmng_intervals;

    /**********************************************************************************************
    * Returns the needed nch in a given day( nr of the day in the scheduling interval) 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule identifier
    * @param o_id_bed                        Bed identifier    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_schedule_bed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
        
    ) RETURN NUMBER IS
        l_rez bed.id_bed%TYPE;
        l_err t_error_out;
    BEGIN
        g_error := 'CALL MAIN FUNCTION With i_id_schedule=' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_schedule_inp.get_schedule_bed(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_schedule => i_id_schedule,
                                                o_id_bed      => l_rez,
                                                o_error       => l_err)
        THEN
            RETURN NULL;
        ELSE
            RETURN l_rez;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCHEDULE_BED',
                                              l_err);
            RETURN NULL;
        
    END get_schedule_bed;

    FUNCTION get_schedule_bed_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
        
    ) RETURN NUMBER IS
        l_rez department.id_department%TYPE;
        l_err t_error_out;
    BEGIN
        g_error := 'CALL MAIN FUNCTION With i_id_epis=' || i_id_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_schedule_inp.get_schedule_bed_service(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_id_epis => i_id_epis,
                                                        o_id_dep  => l_rez,
                                                        o_error   => l_err)
        THEN
            RETURN NULL;
        ELSE
            RETURN l_rez;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCHEDULE_BED_SERVICE',
                                              l_err);
            RETURN NULL;
        
    END get_schedule_bed_service;

    /**********************************************************************************************
    * SET_MATCH_BMNG                          updates table: bmng_allocation_bed and epis_info
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION set_match_bmng
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_temp   IN episode.id_episode%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_patient_temp   IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids  table_varchar;
        l_bed_def bed.id_bed%TYPE;
        l_bed_tmp bed.id_bed%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        g_error := 'CHECK i_episode=' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT ei.id_bed
          INTO l_bed_def
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        g_error := 'CHECK i_episode_temp=' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT ei.id_bed
          INTO l_bed_tmp
          FROM epis_info ei
         WHERE ei.id_episode = i_episode_temp;
    
        IF l_bed_def IS NOT NULL
        THEN
            g_error := 'DEF EP HAS BED ALLOCATION, FREE TEMP ';
            pk_alertlog.log_debug(g_error);
            IF l_bed_tmp IS NOT NULL
            THEN
                -- Free tmp allocated bed
                IF NOT set_bmng_free_occup_beds(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_epis           => i_episode_temp,
                                                i_transaction_id => l_transaction_id,
                                                o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- Outdate past allocations
            g_error := 'OUTDATE BMNG_ALLOCATION_BED WITH i_episode_temp=' || i_episode_temp;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_bmng_allocation_bed.upd(id_episode_in    => i_episode,
                                       id_episode_nin   => FALSE,
                                       id_patient_in    => i_patient,
                                       id_patient_nin   => FALSE,
                                       flg_outdated_in  => pk_alert_constant.g_yes,
                                       flg_outdated_nin => FALSE,
                                       where_in         => 'id_episode = ' || i_episode_temp,
                                       rows_out         => l_rowids);
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'BMNG_ALLOCATION_BED',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_EPISODE', 'ID_PATIENT', 'FLG_OUTDATED'));
        
            g_error := 'OUTDATE EPIS_NCH';
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_epis_nch.upd(id_episode_in  => i_episode,
                            id_episode_nin => FALSE,
                            id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            flg_status_in  => 'O',
                            flg_status_nin => FALSE,
                            where_in       => 'id_episode = ' || i_episode_temp,
                            rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_NCH',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_EPISODE', 'ID_PATIENT', 'FLG_STATUS'));
        
        ELSE
            g_error := 'DEF EP HAS NO BED ALLOCATION';
            pk_alertlog.log_debug(g_error);
        
            g_error := 'BMNG_ALLOCATION_BED WITH i_episode_temp=' || i_episode_temp;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_bmng_allocation_bed.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'BMNG_ALLOCATION_BED',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_EPISODE', 'ID_PATIENT'));
        
            g_error := 'EPIS_NCH';
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_epis_nch.upd(id_episode_in  => i_episode,
                            id_episode_nin => FALSE,
                            id_patient_in  => i_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_episode = ' || i_episode_temp,
                            rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_NCH',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_EPISODE', 'ID_PATIENT'));
        
            -- UPDATE EPIS_INFO
            g_error := 'CALL TO SET_EPIS_INFO: id_episode = ' || i_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_info(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_id_episode => i_episode,
                                 i_id_bed     => l_bed_tmp,
                                 o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
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
                                              'SET_MATCH_BMNG',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_bmng;

    /********************************************************************************************************************************************
    * GET_BMNG_ACTION           Function that returns the bmng_action and bmng_allocation_bed associated to the given episode.
    *
    * @param  I_LANG                     Language associated to the professional executing the request
    * @param  I_PROF                     Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE               Episode identifier
    * @param  O_BMNG_ACTION              Current bmng action identifier
    * @param  O_BMG_ALLOCATION_BED       Current bmng allocation bed identifier
    * @param  O_ERROR                    If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   2009/10/21
    *
    *******************************************************************************************************************************************/
    FUNCTION get_bmng_action
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_bmng_action         OUT bmng_action.id_bmng_action%TYPE,
        o_bmng_allocation_bed OUT bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_id_bed              OUT bmng_allocation_bed.id_bed%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_BMNG_ACTION WITH ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT ba.id_bmng_action, bab.id_bmng_allocation_bed, bab.id_bed
              INTO o_bmng_action, o_bmng_allocation_bed, o_id_bed
              FROM bmng_action ba
             INNER JOIN bmng_allocation_bed bab
                ON bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed
             WHERE bab.id_episode = i_id_episode
               AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
               AND bab.flg_outdated = pk_alert_constant.g_no;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
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
                                              'GET_BMNG_ACTION',
                                              o_error);
            RETURN FALSE;
    END get_bmng_action;

    /********************************************************************************************************************************************
    * get_episode_clin_servs   Function that returns the clinical services associated to an episode
    *
    * @param  I_LANG              Language associated to the professional executing the request
    * @param  I_PROF              Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPSIODE        Episode identifier
    *
    * @return                     Returns a string with then clinical service
    *
    * @author  Sofia Mendes
    * @version 2.5.0.7.2
    * @since    16-Nov-2009
    *******************************************************************************************************************************************/
    FUNCTION get_episode_clin_serv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_clin_service VARCHAR2(32767);
    BEGIN
        g_error := 'GET EPISOODE clinical service i_episode=' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
          INTO l_clin_service
          FROM epis_info ei
          JOIN dep_clin_serv dcs
            ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN clinical_service cs
            ON dcs.id_clinical_service = cs.id_clinical_service
         WHERE ei.id_episode = i_id_episode;
    
        RETURN l_clin_service;
    EXCEPTION
        WHEN no_data_found THEN
            l_clin_service := '';
            RETURN l_clin_service;
    END get_episode_clin_serv;

    /********************************************************************************************************************************************
    * BMNG_RESET                        Cleans all data regarding beds and related info for the episodes provided. 
    *
    * @param      i_prof                RESET professional
    * @param      i_episodes            ID of the episodes to be freed
    * @param      i_allocation_commit   Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param      o_error               If an error accurs, this parameter will have information about the error
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7.6.1
    * @since   11-FEB-2010
    *******************************************************************************************************************************************/
    FUNCTION bmng_reset
    (
        i_prof              IN profissional,
        i_episodes          IN table_number,
        i_allocation_commit IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang            language.id_language%TYPE := 1;
        l_transaction_id  VARCHAR2(4000);
        l_internal_error  EXCEPTION;
        tb_allocation_bed table_number := table_number();
        tb_action_bed     table_number := table_number();
        l_rowids          table_varchar := table_varchar();
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        FOR lista IN (SELECT column_value id_episode
                        FROM TABLE(i_episodes) t)
        LOOP
            --Release Bed
            IF NOT pk_bmng.set_episode_bed_status_vacant(i_lang              => l_lang,
                                                         i_prof              => i_prof,
                                                         i_id_episode        => lista.id_episode,
                                                         i_transaction_id    => l_transaction_id,
                                                         i_allocation_commit => i_allocation_commit,
                                                         o_error             => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        END LOOP;
    
        SELECT b.id_bmng_allocation_bed
          BULK COLLECT
          INTO tb_allocation_bed
          FROM bmng_allocation_bed b
         WHERE b.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                 column_value
                                  FROM TABLE(i_episodes) t);
    
        SELECT ba.id_bmng_action
          BULK COLLECT
          INTO tb_action_bed
          FROM bmng_action ba
         WHERE ba.id_bmng_allocation_bed IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              column_value
                                               FROM TABLE(tb_allocation_bed) t);
    
        g_error := 'DELETE SCH_ALLOCATION';
        pk_alertlog.log_debug(g_error);
        DELETE FROM sch_allocation a
         WHERE a.id_bmng_allocation_bed IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             column_value
                                              FROM TABLE(tb_allocation_bed) t);
    
        g_error := 'DELETE BMNG_SCHEDULER_MAP';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_bmng_scheduler_map.del_by(where_clause_in => 'id_resource_pfh in (' ||
                                                        pk_utils.concat_table(i_tab   => tb_allocation_bed,
                                                                              i_delim => ',') || ')',
                                     rows_out        => l_rowids);
    
        g_error := 'DELETE BMNG_ACTION_SCH_MAP';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_bmng_bed_ea.del_by(where_clause_in => 'id_bmng_action in (' ||
                                                 pk_utils.concat_table(i_tab => tb_action_bed, i_delim => ',') || ')',
                              rows_out        => l_rowids);
    
        g_error := 'DELETE BMNG_BED_EA';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_bmng_bed_ea.del_by(where_clause_in => 'id_bmng_allocation_bed in (' ||
                                                 pk_utils.concat_table(i_tab => tb_allocation_bed, i_delim => ',') || ')',
                              rows_out        => l_rowids);
    
        g_error := 'DELETE BMNG_ACTION';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_bmng_action.del_by(where_clause_in => 'id_bmng_allocation_bed in (' ||
                                                 pk_utils.concat_table(i_tab => tb_allocation_bed, i_delim => ',') || ')',
                              rows_out        => l_rowids);
    
        t_data_gov_mnt.process_delete(i_lang       => l_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BMNG_ACTION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'DELETE BMNG_ALLOCATION_BED';
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_bmng_allocation_bed.del_by(where_clause_in => 'id_bmng_allocation_bed in (' ||
                                                         pk_utils.concat_table(i_tab   => tb_allocation_bed,
                                                                               i_delim => ',') || ')',
                                      rows_out        => l_rowids);
    
        t_data_gov_mnt.process_delete(i_lang       => l_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'BMNG_ALLOCATION_BED',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id);
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'BMNG_RESET',
                                              o_error);
            RETURN FALSE;
    END bmng_reset;

    /********************************************************************************************************************************************
    * Overload para ser possivel usar em queries
    *
    * @param  I_LANG                Language associated to the professional executing the request
    * @param  I_PROF                Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DT_BEGIN            Allocation start date
    * @param  I_DT_END              Discharge Schedule Date
    * @param  O_DT_END              Allocation end date to be send to the scheduler
    * @param  O_ERROR               If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author  Telmo 
    * @version 2.6.1.3.1
    * @since   12-10-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION check_allocation_dates
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end   IN bmng_action.dt_end_action%TYPE
    ) RETURN bmng_action.dt_end_action%TYPE IS
    
        l_res  BOOLEAN;
        l_date bmng_action.dt_end_action%TYPE;
    
        o_error t_error_out;
    
    BEGIN
    
        l_res := check_allocation_dates(i_lang     => i_lang,
                                        i_prof     => i_prof,
                                        i_dt_begin => i_dt_begin,
                                        i_dt_end   => i_dt_end,
                                        o_dt_end   => l_date,
                                        o_error    => o_error);
    
        RETURN l_date;
    
    END check_allocation_dates;

    FUNCTION get_room_beds_qty
    (
        i_id_room IN bed.id_room%TYPE,
        i_prof    IN profissional
    ) RETURN INTEGER IS
    
        l_ret             INTEGER;
        l_count_temp_beds sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_code_cf => 'BMNG_COUNT_TEMP_BEDS',
                                                                               i_prof    => i_prof),
                                                       pk_alert_constant.g_yes);
    BEGIN
    
        g_error := g_package_name || '.GET_ROOM_BEDS_QTY validate i_id_room';
        IF i_id_room IS NULL
        THEN
            raise_application_error(-20000, 'i_id_room is null');
        END IF;
    
        g_error := g_package_name || '.GET_ROOM_BEDS_QTY do select';
        SELECT COUNT(*)
          INTO l_ret
          FROM bed b
         WHERE b.id_room = i_id_room
           AND b.flg_available = pk_alert_constant.g_yes
           AND ((l_count_temp_beds = pk_alert_constant.g_no AND b.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p) OR
               l_count_temp_beds = pk_alert_constant.g_yes);
    
        RETURN l_ret;
    
    END get_room_beds_qty;

    /* 
    *
    */
    FUNCTION get_room_avail_beds_qty(i_id_room IN bed.id_room%TYPE) RETURN INTEGER IS
        l_ret INTEGER;
    BEGIN
        g_error := g_package_name || '.GET_ROOM_AVAIL_BEDS_QTY validate i_id_room';
        IF i_id_room IS NULL
        THEN
            raise_application_error(-20000, 'i_id_room is null');
        END IF;
    
        g_error := g_package_name || '.GET_ROOM_AVAIL_BEDS_QTY do select';
        SELECT COUNT(*)
          INTO l_ret
          FROM bmng_action ba
         INNER JOIN bed b1
            ON (b1.id_bed = ba.id_bed AND b1.flg_available = pk_alert_constant.g_yes)
         INNER JOIN room r1
            ON (r1.id_room = b1.id_room AND r1.flg_available = pk_alert_constant.g_yes)
         WHERE b1.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
           AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
           AND ba.flg_bed_ocupacity_status <> pk_bmng_constant.g_bmng_act_flg_ocupaci_o
           AND ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n
           AND r1.id_room = i_id_room;
    
        RETURN l_ret;
    END get_room_avail_beds_qty;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_bmng_core;
/
