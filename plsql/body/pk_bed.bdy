/*-- Last Change Revision: $Rev: 2054006 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2023-01-03 11:31:19 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_bed IS

    /***************************************************************************************************************
    *
    * Creates a new record in Bed table and then proceeds to create a new bed allocation for the provided episode.
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_id_episode       ID_EPISODE that is having a bed allocation.
    * @param      i_id_room          ID_ROOM of the room where the new temporary bed is located. 
    * @param      i_desc_bed         Description of the temporary bed.
    * @param      i_notes            Notes regarding the new bed. 
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14-10-2009
    *
    ****************************************************************************************************/
    FUNCTION create_tmp_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_room    IN room.id_room%TYPE,
        i_desc_bed   IN bed.desc_bed%TYPE,
        i_notes      IN bed.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        error_allocated_bed EXCEPTION;
        l_id_bab            bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_dep            department.id_department%TYPE;
        l_id_pat            patient.id_patient%TYPE;
        l_id_bed            bed.id_bed%TYPE;
        --
        l_bed_allocation VARCHAR2(1);
        l_exception_info sys_message.desc_message%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
    
        l_current_date VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'GET INFO';
        pk_alertlog.log_debug(g_error);
        SELECT r.id_department, ep.id_patient
          INTO l_id_dep, l_id_pat
          FROM room r, episode ep
         WHERE r.id_room = i_id_room
           AND ep.id_episode = i_id_episode;
    
        g_error := 'GET CURRENT DATE';
        pk_alertlog.log_debug(g_error);
        l_current_date := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        g_error := 'INSERT TEMPORARY BED ALLOCATION';
        pk_alertlog.log_debug(g_error);
        g_ret := pk_bmng.set_bed_management(i_lang                   => i_lang,
                                            i_prof                   => i_prof,
                                            i_id_bmng_action         => table_number(NULL),
                                            i_id_department          => table_number(l_id_dep),
                                            i_id_room                => table_number(i_id_room),
                                            i_id_bed                 => table_number(NULL),
                                            i_id_bmng_reason         => table_number(NULL),
                                            i_id_bmng_allocation_bed => table_number(NULL),
                                            i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                            i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                            i_nch_capacity           => table_number(NULL),
                                            i_action_notes           => table_varchar(i_notes),
                                            i_dt_begin_action        => table_varchar(l_current_date),
                                            i_dt_end_action          => table_varchar(l_current_date),
                                            i_id_episode             => table_number(i_id_episode),
                                            i_id_patient             => table_number(l_id_pat),
                                            i_nch_hours              => NULL,
                                            i_flg_allocation_nch     => NULL,
                                            i_desc_bed               => i_desc_bed,
                                            i_id_bed_type            => table_number(NULL),
                                            i_dt_discharge_schedule  => NULL,
                                            i_id_bed_dep_clin_serv   => NULL,
                                            i_flg_origin_action_ux   => pk_bmng_constant.g_bmng_flg_origin_ux_t,
                                            i_reason_notes           => NULL,
                                            i_transaction_id         => l_transaction_id,
                                            o_id_bmng_allocation_bed => l_id_bab,
                                            o_id_bed                 => l_id_bed,
                                            o_bed_allocation         => l_bed_allocation,
                                            o_exception_info         => l_exception_info,
                                            o_error                  => o_error);
    
        g_error := 'EVALUATE RESULT';
        IF g_ret = FALSE
        THEN
            RAISE error_allocated_bed;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN error_allocated_bed THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'ERROR_ALLOCATED_BED');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_ALLOCATED_BED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CREATE_TMP_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'U');
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure of function_dummy 
                pk_utils.undo_changes;
            
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_TMP_BED',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_tmp_bed;

    -- ###############################################################################

    /***************************************************************************************************************
    *
    * Creates a new new bed allocation for the provided episode.
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_id_episode       ID_EPISODE that is having a bed allocation.
    * @param      i_id_bed           ID_BED to which the episode should be allocated. 
    * @param      o_bed_allocation   ID of the allocation.
    * @param      o_exception_info   Error message to be displayed to the user. 
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14-10-2009
    *
    ****************************************************************************************************/
    FUNCTION allocate_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_bed         IN bed.id_bed%TYPE,
        o_bed_allocation OUT VARCHAR2,
        o_exception_info OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bed_flg_status bed.flg_status%TYPE;
        l_bed_flg_type   bed.flg_type%TYPE;
        l_id_bab         bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_desc_bed       pk_translation.t_desc_translation;
        l_id_room        room.id_room%TYPE;
        l_notes_bed      bmng_allocation_bed.allocation_notes%TYPE;
        l_id_dep         department.id_department%TYPE;
        l_id_pat         patient.id_patient%TYPE;
        l_id_bed_type    bed_type.id_bed_type%TYPE;
        l_id_bed         bed.id_bed%TYPE;
        l_transaction_id VARCHAR2(4000);
    
        error_get_allocated         EXCEPTION;
        error_bed_status_vacant     EXCEPTION;
        error_upd_allocation_bed    EXCEPTION;
        error_set_bed_filled        EXCEPTION;
        error_ins_allocation_bed    EXCEPTION;
        error_bed_already_allocated EXCEPTION;
    
        l_current_date VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := '[PK_BED.ALLOCATE_BED] i_id_episode=' || i_id_episode || ' i_id_bed=' || i_id_bed;
        pk_alertlog.log_debug(g_error);
    
        -- INPATIENT LMAIA 02-02-2009
        g_error := 'SELECTED BED IS ALREADY ALLOCATED';
        pk_alertlog.log_debug(g_error);
        SELECT b.flg_status, b.flg_type
          INTO l_bed_flg_status, l_bed_flg_type
          FROM bed b
         WHERE b.id_bed = i_id_bed;
    
        g_error := '[PK_BED.ALLOCATE_BED] l_bed_flg_status=' || l_bed_flg_status || ' l_bed_flg_type=' ||
                   l_bed_flg_type;
        pk_alertlog.log_debug(g_error);
        --
        IF l_bed_flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p -- INP LMAIA 05-03-2009 Added condition to verify only Permanent Bed's
        THEN
            IF l_bed_flg_status = pk_bmng_constant.g_bmng_bed_flg_status_o
            THEN
                -- INP LMAIA 13-05-2009 It is not possible allocate current bed
                o_bed_allocation := pk_alert_constant.g_no;
                o_exception_info := pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T114');
                --
                -- LMAIA 19-05-2009 Commented exception to show user error information.
                --RAISE error_bed_already_allocated;
                RETURN TRUE;
            END IF;
        END IF;
        -- END
    
        -- INP LMAIA 13-05-2009 It is possible allocate current bed
        o_bed_allocation := pk_alert_constant.g_yes;
        o_exception_info := NULL;
    
        g_error := 'GET INFO FOR ID_EPISODE:' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        SELECT nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)),
               b.id_room,
               notes,
               r.id_department,
               ep.id_patient,
               b.id_bed_type
          INTO l_desc_bed, l_id_room, l_notes_bed, l_id_dep, l_id_pat, l_id_bed_type
          FROM episode ep, bed b
         INNER JOIN room r
            ON r.id_room = b.id_room
         WHERE b.id_bed = i_id_bed
           AND ep.id_episode = i_id_episode;
    
        g_error := 'GET CURRENT DATE';
        pk_alertlog.log_debug(g_error);
        l_current_date := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        g_error := '[PK_BED.ALLOCATE_BED] l_current_date=' || l_current_date;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'INS ALLOCATION BED:' || i_id_bed || ' ID_EPISODE:' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_bmng_pbl.set_bed_management(i_lang                   => i_lang,
                                              i_prof                   => i_prof,
                                              i_id_bmng_action         => table_number(NULL), --New Action
                                              i_id_department          => table_number(l_id_dep),
                                              i_id_room                => table_number(l_id_room),
                                              i_id_bed                 => table_number(i_id_bed),
                                              i_id_bmng_reason         => table_number(NULL),
                                              i_id_bmng_allocation_bed => table_number(NULL), --New Allocation
                                              i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                              i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                              i_nch_capacity           => table_number(NULL),
                                              i_action_notes           => table_varchar(l_notes_bed),
                                              i_dt_begin_action        => table_varchar(l_current_date),
                                              i_dt_end_action          => table_varchar(l_current_date),
                                              i_id_episode             => table_number(i_id_episode),
                                              i_id_patient             => table_number(l_id_pat),
                                              i_nch_hours              => NULL,
                                              i_flg_allocation_nch     => NULL,
                                              i_desc_bed               => NULL,
                                              i_id_bed_type            => table_number(l_id_bed_type),
                                              i_dt_discharge_schedule  => NULL,
                                              i_bed_dep_clin_serv      => NULL,
                                              i_flg_origin_action_ux   => pk_bmng_constant.g_bmng_flg_origin_ux_p,
                                              i_reason_notes           => NULL,
                                              i_transaction_id         => l_transaction_id,
                                              o_id_bmng_allocation_bed => l_id_bab,
                                              o_id_bed                 => l_id_bed,
                                              o_bed_allocation         => o_bed_allocation,
                                              o_exception_info         => o_exception_info,
                                              o_error                  => o_error)
        THEN
            RAISE error_ins_allocation_bed;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN error_bed_already_allocated THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T114');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_BED_ALREADY_ALLOCATED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'ALLOCATE_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'U');
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN error_bed_status_vacant THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_BED_STATUS_VACANT',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'ALLOCATE_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'S');
                -- execute error processing 
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN error_upd_allocation_bed THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_UPD_ALLOCATION_BED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'ALLOCATE_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'S');
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN error_set_bed_filled THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_SET_BED_FILLED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'ALLOCATE_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'S');
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN error_ins_allocation_bed THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_INS_ALLOCATION_BED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'ALLOCATE_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'S');
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                pk_utils.undo_changes;
            
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN error_get_allocated THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_GET_ALLOCATED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'ALLOCATE_BED');
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                l_error_in.set_action(l_error_message, 'S');
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ALLOCATE_BED',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END allocate_bed;

    -- ############################################################################

    /******************************************************************************
    NAME: GET_AVAILABLE_ALLOCATION
    CREATION INFO: CARLOS FERREIRA 2006/09/25
    GOAL: RETURNS, DEPENDING OF I_TYPE VALUE, AVAILABLE BEDS FROM ROOMS AND SERVICE
    
    PARAMETERS:
    -----------------------------------------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION                                            |
    -----------------------------------------------------------------------------------------------------------------
    I_LANG             | NUMBER                 | IN  | ID OF LANGUAGE                                              |
    I_TYPE             | VARCHAR2               | IN  | IDENTIFIES WHICH SET TO RETURN: S-SERVICES; R-ROOMS; B-BEDS |
    I_ID               | NUMBER                 | IN  | ID OF SERVICE, ROOM, OR BED CHOSEN BY USER. CAN BE NULL     |
    O_SQL              | PK_TYPES.CURSOR_TYPE   | OUT | CURSOR OF SERVICES, ROOMS OR BEDS REQUESTED BY USER         |
    O_ERROR            | VARCHAR2               | OUT | RETURNS ERROR MESSAGE, IF EXISTS                            |
    -----------------------------------------------------------------------------------------------------------------
    OBS: FUNCTION CREATED FOR THE "ALLOCATING BED" FUNCTIONALITY. DEPENDING OF I_TYPE, THE FUNCTION RETURNS A CURSOR
         OF SERVICES, ROOMS OR BEDS AVAILABLE.
    *********************************************************************************/
    FUNCTION get_available_allocation
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        i_id    IN NUMBER,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_dept IS
            SELECT sd.id_dept
              FROM software_dept sd
              JOIN dept d
                ON d.id_dept = sd.id_dept
             INNER JOIN department dep
                ON dep.id_dept = d.id_dept
             WHERE d.id_institution = i_prof.institution
               AND sd.id_software IN (i_prof.software, 0)
               AND dep.flg_available = g_flg_available
               AND (SELECT COUNT(1)
                      FROM room r
                     WHERE r.id_department = dep.id_department) > 0;
    
        l_type_service VARCHAR2(0050) := 'S';
        l_type_room    VARCHAR2(0050) := 'R';
        l_type_bed     VARCHAR2(0050) := 'B';
    
        l_id_dept table_number;
    
        l_bmng_temporary_bed sys_config.value%TYPE := pk_sysconfig.get_config('BMNG_TEMPORARY_BED', i_prof);
    
    BEGIN
    
        IF i_prof.software = pk_alert_constant.g_soft_inpatient
        THEN
            --JOSE SILVA 09-03-2007 novo select no union all para adicionar cama temporária
        
            g_error := 'TYPE:' || i_type || ' ID:' || i_id;
            /* returns services of inpatient, first is the curent of patient */
            OPEN o_sql FOR
                SELECT -1 data,
                       pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T113') label,
                       -1 rank,
                       NULL desc_room,
                       NULL desc_bed
                  FROM dual
                 WHERE l_type_bed = i_type
                   AND l_bmng_temporary_bed = pk_alert_constant.g_yes
                UNION ALL
                SELECT d.id_department data,
                       decode(nvl(d.id_admission_type, 0),
                              0,
                              pk_translation.get_translation(i_lang, d.code_department),
                              pk_translation.get_translation(i_lang, d.code_department) || ' (' ||
                              nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) || ')') label,
                       d.rank,
                       NULL desc_room,
                       NULL desc_bed
                  FROM department d
                  LEFT JOIN admission_type at
                    ON at.id_admission_type = d.id_admission_type
                 WHERE instr(d.flg_type, 'I') > 0
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND l_type_service = i_type
                   AND d.id_institution = i_prof.institution
                UNION ALL
                /* returns all rooms from selected service */
                SELECT r.id_room data,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) label,
                       0 rank,
                       NULL desc_room,
                       NULL desc_bed
                  FROM room r
                 WHERE r.id_department = i_id
                   AND l_type_room = i_type
                   AND r.flg_available = pk_alert_constant.g_yes
                 GROUP BY r.id_room, r.desc_room, r.code_room
                UNION ALL
                /* returns bed from select room */
                SELECT bed.id_bed data,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) || ' - ' ||
                       nvl(bed.desc_bed, pk_translation.get_translation(i_lang, bed.code_bed)) label,
                       0 rank,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                       nvl(bed.desc_bed, pk_translation.get_translation(i_lang, bed.code_bed)) desc_bed
                  FROM department d, room r, bed
                 WHERE l_type_bed = i_type
                   AND d.id_department = i_id
                   AND r.id_department = d.id_department
                   AND d.id_institution = i_prof.institution
                   AND bed.id_room = r.id_room
                   AND bed.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                   AND bed.flg_available = pk_alert_constant.g_yes
                 ORDER BY rank DESC, desc_room, label, data;
        
        ELSE
        
            IF i_type = l_type_service
            THEN
                g_error := 'GET ID_DEPT';
                OPEN c_dept;
                FETCH c_dept BULK COLLECT
                    INTO l_id_dept;
                CLOSE c_dept;
            
                g_error := 'OPEN o_sql service';
                OPEN o_sql FOR
                    SELECT d.id_department data,
                           pk_translation.get_translation(i_lang, d.code_department) label,
                           d.rank,
                           NULL desc_room,
                           NULL desc_bed
                      FROM department d
                     WHERE d.id_dept IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                          t.*
                                           FROM TABLE(l_id_dept) t)
                       AND d.flg_available = g_flg_available
                       AND d.id_institution = i_prof.institution
                       AND EXISTS (SELECT 0
                              FROM room r
                              JOIN bed b
                                ON r.id_room = b.id_room
                             WHERE b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                               AND b.flg_available = pk_alert_constant.g_yes
                               AND r.flg_available = pk_alert_constant.g_yes)
                          -- This AND guarantee that only departments with rooms are presented
                       AND (SELECT COUNT(1)
                              FROM room r
                             WHERE r.id_department = d.id_department) > 0
                     ORDER BY rank DESC, desc_room, label, data;
            
            ELSIF i_type = l_type_bed
            THEN
                g_error := 'OPEN o_sql bed';
                OPEN o_sql FOR
                    SELECT -1 data,
                           pk_message.get_message(i_lang, 'INP_BED_ALLOCATION_T113') label,
                           -1 rank,
                           NULL desc_room,
                           NULL desc_bed
                      FROM dual
                     WHERE l_bmng_temporary_bed = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT b.id_bed data,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) || ' - ' ||
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) label,
                           0 rank,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed
                      FROM department d
                      JOIN room r
                        ON r.id_department = d.id_department
                      JOIN bed b
                        ON b.id_room = r.id_room
                     WHERE d.id_department = i_id
                       AND d.id_institution = i_prof.institution
                       AND b.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                       AND b.flg_available = pk_alert_constant.g_yes
                     ORDER BY rank DESC, desc_room, label, data;
            
            ELSIF i_type = l_type_room
            THEN
                g_error := 'OPEN o_sql room';
                OPEN o_sql FOR
                    SELECT r.id_room data,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) label,
                           0 rank,
                           NULL desc_room,
                           NULL desc_bed
                      FROM room r
                     WHERE r.id_department = i_id
                       AND r.flg_available = g_flg_available
                     ORDER BY rank DESC, desc_room, label, data;
            
            ELSE
                pk_types.open_my_cursor(o_sql);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_AVAILABLE_ALLOCATION',
                                                       o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_available_allocation;

    -- ##########################################################################################
    /******************************************************************************
    NAME: GET_EPIS_BED_HISTORY
    CREATION INFO: JOSE SILVA 2007/03/06
    GOAL: RETURNS THE BED HISTORY OF EPISODE I_ID_EPISODE
    
    PARAMETERS:
    -----------------------------------------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION                                            |
    -----------------------------------------------------------------------------------------------------------------
    I_LANG             | NUMBER                 | IN  | ID OF LANGUAGE                                              |
    I_PROF             | PROFISSIONAL     | IN  | ID OF PROFESSIONAL, INSTITUTION, SOFTWARE                   |
    I_ID_EPISODE       | NUMBER                 | IN  | ID OF EPISODE                                               |
    O_SQL              | PK_TYPES.CURSOR_TYPE   | OUT | CURSOR OF SERVICES, ROOMS OR BEDS REQUESTED BY USER         |
    O_ERROR            | VARCHAR2               | OUT | RETURNS ERROR MESSAGE, IF EXISTS                            |
    -----------------------------------------------------------------------------------------------------------------
    OBS:
    *********************************************************************************/
    FUNCTION get_epis_bed_history_jose
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        --JOSE SILVA 08-03-2007 nova variavel local
    
        l_max_bmng_alloc bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
    BEGIN
        BEGIN
            g_error := 'GET BMNG BED HISTORY FROM EPISODE:' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT id_bmng_allocation_bed
              INTO l_max_bmng_alloc
              FROM (SELECT MAX(ab.id_bmng_allocation_bed) id_bmng_allocation_bed,
                           row_number() over(PARTITION BY ab.id_episode ORDER BY ab.dt_creation DESC) rn
                      FROM bmng_allocation_bed ab
                     WHERE ab.id_episode = i_id_episode
                       AND ab.id_room IS NOT NULL
                     GROUP BY ab.id_episode, ab.dt_creation) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_max_bmng_alloc := 0;
        END;
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_sql FOR
            SELECT t.id_allocation_bed,
                   t.id_department,
                   t.desc_service,
                   t.id_room,
                   t.desc_room,
                   t.id_bed,
                   t.desc_bed,
                   t.date_alocation,
                   t.name_professional,
                   t.notes,
                   t.has_detail,
                   t.is_last,
                   t.flg_outdated
              FROM (SELECT bab.id_bmng_allocation_bed id_allocation_bed,
                           dpt.id_department id_department,
                           pk_translation.get_translation(i_lang, dpt.code_department) desc_service,
                           roo.id_room id_room,
                           nvl(roo.desc_room, pk_translation.get_translation(i_lang, roo.code_room)) desc_room,
                           bab.id_bed id_bed,
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                           pk_date_utils.date_char_tsz(i_lang, bab.dt_creation, i_prof.institution, i_prof.software) date_alocation,
                           pro.nick_name name_professional,
                           bab.allocation_notes notes,
                           decode(nvl(b.flg_type, pk_bmng_constant.g_bmng_bed_flg_type_t),
                                  pk_bmng_constant.g_bmng_bed_flg_type_t,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) has_detail,
                           decode(bab.id_bmng_allocation_bed,
                                  l_max_bmng_alloc,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) is_last,
                           bab.dt_creation,
                           bab.flg_outdated
                      FROM bmng_allocation_bed bab, bed b, room roo, department dpt, professional pro
                     WHERE bab.id_episode = i_id_episode
                       AND bab.id_bed = b.id_bed(+)
                       AND pro.id_professional = bab.id_prof_creation
                       AND bab.id_room = roo.id_room
                       AND roo.id_department = dpt.id_department
                       AND dpt.id_institution = i_prof.institution) t
             ORDER BY t.dt_creation DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_AVAILABLE_ALLOCATION',
                                                       o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_epis_bed_history_jose;

    /********************************************************************************************
    * get_bed_desc                     Gets the bed description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_clinical_service     Clinical service ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           28-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_bed_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_bed_desc pk_translation.t_desc_translation;
        l_error    t_error_out;
    BEGIN
        g_error := 'GET bed desc. i_id_bed: ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        SELECT nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))
          INTO l_bed_desc
          FROM bed b
         WHERE b.id_bed = i_id_bed;
    
        RETURN l_bed_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED_DESC',
                                              l_error);
            RETURN NULL;
    END get_bed_desc;

    /********************************************************************************************
    * get_bed_desc                     Gets the bed description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_clinical_service     Clinical service ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.4
    * @since                           31-Oct-2011
    *
    **********************************************************************************************/
    FUNCTION get_bed_room_and_depart
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_bed        IN bed.id_bed%TYPE,
        o_id_room       OUT room.id_room%TYPE,
        o_id_department OUT department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Get bed room and department. i_id_bed: ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        SELECT r.id_department, r.id_room
          INTO o_id_department, o_id_room
          FROM bed b
          JOIN room r
            ON r.id_room = b.id_room
         WHERE b.id_bed = i_id_bed;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED_ROOM_AND_DEPART',
                                              o_error);
            RETURN FALSE;
    END get_bed_room_and_depart;

    -- CMF
    FUNCTION get_last_allocation(i_id_episode IN NUMBER) RETURN NUMBER IS
        l_return NUMBER := 0;
        tbl_id   table_number;
    BEGIN
    
        g_error := 'GET BMNG BED HISTORY FROM EPISODE:' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        SELECT id_bmng_allocation_bed
          BULK COLLECT
          INTO tbl_id
          FROM bmng_allocation_bed ab
         WHERE ab.id_episode = i_id_episode
           AND ab.id_room IS NOT NULL -- 
         ORDER BY dt_creation DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_last_allocation;

    FUNCTION get_epis_bed_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        --JOSE SILVA 08-03-2007 nova variavel local
    
        l_max_bmng_alloc bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
    
    BEGIN
    
        l_max_bmng_alloc := get_last_allocation(i_id_episode);
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_sql FOR
            SELECT t.id_allocation_bed,
                   t.id_department,
                   t.desc_service,
                   t.id_room,
                   t.desc_room,
                   t.room_type,
                   t.id_bed,
                   t.desc_bed,
                   t.date_alocation,
                   t.name_professional,
                   t.notes,
                   t.has_detail,
                   t.is_last,
                   t.flg_outdated,
                   t.flg_bed_type,
                   t.bed_desc_type,
                   t.desc_specs,
                   t.bed_status,
                   t.signature
              FROM (SELECT bab.id_bmng_allocation_bed id_allocation_bed,
                           dpt.id_department id_department,
                           pk_translation.get_translation(i_lang, dpt.code_department) desc_service,
                           roo.id_room id_room,
                           coalesce(roo.desc_room, pk_translation.get_translation(i_lang, roo.code_room)) desc_room,
                           pk_translation.get_translation(i_lang, rt.code_room_type) room_type,
                           bab.id_bed id_bed,
                           coalesce(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                           pk_date_utils.date_char_tsz(i_lang, bab.dt_creation, i_prof.institution, i_prof.software) date_alocation,
                           pro.nick_name name_professional,
                           bab.allocation_notes notes,
                           decode(coalesce(b.flg_type, pk_bmng_constant.g_bmng_bed_flg_type_t),
                                  pk_bmng_constant.g_bmng_bed_flg_type_t,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) has_detail,
                           decode(bab.id_bmng_allocation_bed,
                                  l_max_bmng_alloc,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) is_last,
                           bab.dt_creation,
                           bab.flg_outdated,
                           b.flg_type flg_bed_type,
                           bbe.flg_bed_ocupacity_status,
                           CASE
                                WHEN bt.id_bed_type = -1 THEN
                                 NULL
                                ELSE
                                 nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type))
                            END bed_desc_type,
                           pk_bmng_core.get_all_clin_services_int(i_lang, i_prof, dpt.id_department) desc_specs,
                           pk_sysdomain.get_domain('BMNG_ACTION.FLG_BED_STATUS', ba.flg_bed_status, i_lang) bed_status,
                           pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_episode          => i_id_episode,
                                                              i_date_last_change    => ba.dt_creation,
                                                              i_id_prof_last_change => ba.id_prof_creation) signature
                      FROM bmng_allocation_bed bab
                      JOIN room roo
                        ON bab.id_room = roo.id_room
                      LEFT JOIN room_type rt
                        ON rt.id_room_type = roo.id_room_type
                      JOIN department dpt
                        ON roo.id_department = dpt.id_department
                      JOIN professional pro
                        ON pro.id_professional = bab.id_prof_creation
                      LEFT JOIN bed b
                        ON b.id_bed = bab.id_bed
                      LEFT JOIN bmng_bed_ea bbe
                        ON bbe.id_bed = b.id_bed
                      LEFT JOIN bed_type bt
                        ON bt.id_bed_type = b.id_bed_type
                      LEFT JOIN bmng_action ba
                        ON ba.id_bed = b.id_bed
                       AND ba.id_room = b.id_room
                       AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                       AND ba.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_b
                     WHERE bab.id_episode = i_id_episode
                       AND dpt.id_institution = i_prof.institution) t
             ORDER BY t.dt_creation DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_AVAILABLE_ALLOCATION',
                                                       o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_epis_bed_history;

-- ##########################################################################################
-- ********************************************************************************
-- ************************************ CONSTRUCTOR *******************************
-- ********************************************************************************
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_software_intern_name := 'INP';
    g_flg_available        := 'Y';

    g_cat_flg_available := 'Y';
    g_cat_flg_prof      := 'Y';

    g_pat_allergy_cancel := 'C';
    g_pat_blood_active   := 'A';
    g_pat_habit_cancel   := 'C';
    g_pat_problem_cancel := 'C';
    g_pat_notes_cancel   := 'C';

    g_epis_stat_inactive := 'I';

    g_episode_flg_status_active   := 'A';
    g_episode_flg_status_temp     := 'T';
    g_episode_flg_status_canceled := 'C';
    g_episode_flg_status_inactive := 'I';

END;
/
