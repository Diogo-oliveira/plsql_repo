/*-- Last Change Revision: $Rev: 2027018 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_bmng IS

    /**
    * GET DATA ROWID's
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_table_name         Name of the Data Governance table.
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param o_rowids             List of ROWIDs belonging to the changed records.
    *
    * @author Luís Maia
    * @version 2.4.5.5
    * @since 2009/07/29
    */
    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
        l_error_out t_error_out;
    BEGIN
    
        IF i_table_name = 'BMNG_ALLOCATION_BED'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT /*+ opt_estimate(table bab rows=1) */
                     bab.id_bmng_allocation_bed
                      FROM bmng_allocation_bed bab
                     WHERE bab.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          column_value
                                           FROM TABLE(i_rowids) t));
        
        ELSIF i_table_name = 'BMNG_ACTION'
        THEN
            o_rowids := i_rowids;
        
        ELSIF i_table_name = 'DISCHARGE_SCHEDULE'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_episode IN (SELECT /*+ opt_estimate(table ds rows=1) */
                                             ds.id_episode
                                              FROM discharge_schedule ds
                                             WHERE ds.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                 column_value
                                                                  FROM TABLE(i_rowids) t)));
        ELSIF i_table_name = 'EPIS_NCH'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_epis_nch IN (SELECT /*+ opt_estimate(table en rows=1) */
                                              en.id_epis_nch
                                               FROM epis_nch en
                                              WHERE en.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                  column_value
                                                                   FROM TABLE(i_rowids) t)));
        ELSIF i_table_name = 'BED'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_bed IN (SELECT /*+ opt_estimate(table b rows=1) */
                                         b.id_bed
                                          FROM bed b
                                         WHERE b.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                            column_value
                                                             FROM TABLE(i_rowids) t)));
        ELSIF i_table_name = 'ROOM'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_room IN (SELECT /*+ opt_estimate(table r rows=1) */
                                          r.id_room
                                           FROM room r
                                          WHERE r.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                             column_value
                                                              FROM TABLE(i_rowids) t)));
        ELSIF i_table_name = 'ADM_REQUEST'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_episode IN (SELECT /*+ opt_estimate(table ar rows=1) */
                                             ar.id_dest_episode
                                              FROM adm_request ar
                                             WHERE ar.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                 column_value
                                                                  FROM TABLE(i_rowids) t)));
        ELSIF i_table_name = 'ADM_INDICATION'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_episode IN (SELECT 
                                             ar.id_dest_episode
                                              FROM adm_request ar
                                             WHERE ar.id_adm_indication IN
                                                   (SELECT  /*+ opt_estimate(table ai rows=1) */ 
												   ai.id_adm_indication
                                                      FROM adm_indication ai
                                                     WHERE ai.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                         column_value
                                                                          FROM TABLE(i_rowids) t))));
        ELSIF i_table_name = 'NCH_LEVEL'
        THEN
            SELECT ba.rowid
              BULK COLLECT
              INTO o_rowids
              FROM bmng_action ba
             WHERE ba.id_bmng_allocation_bed IN
                   (SELECT b.id_bmng_allocation_bed
                      FROM bmng_allocation_bed b
                     WHERE b.id_episode IN
                           (SELECT ar.id_dest_episode
                              FROM adm_request ar
                             WHERE ar.id_adm_indication IN
                                   (SELECT ai.id_adm_indication
                                      FROM adm_indication ai
                                     WHERE ai.id_nch_level IN
                                           (SELECT /*+ opt_estimate(table nl rows=1) */
                                             nl.id_previous
                                              FROM nch_level nl
                                             WHERE nl.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                 column_value
                                                                  FROM TABLE(i_rowids) t)))));
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_ROWID',
                                              l_error_out);
        
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid;

    /**
    * GET DATA ROWID's
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_department         Department identifier.
    * @param i_flg_bed_status     Bed status
    * @param i_flg_bed_type       Bed type
    * @param i_dep_nch            Department NCH
    * @param i_event_into_ea      Type of registry event ('I'- INSERT; 'U'- UPDATE; 'D'- DELETE)
    * @param i_process            Type of action
    *
    * @author Luís Maia
    * @version 2.4.5.5
    * @since 2009/07/30
    */
    FUNCTION set_department_ea
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_department     IN department.id_department%TYPE,
        i_flg_bed_status IN bmng_action.flg_bed_status%TYPE,
        i_flg_bed_type   IN bed.flg_type%TYPE,
        i_dep_nch        IN bmng_action.nch_capacity%TYPE,
        i_event_into_ea  IN VARCHAR2,
        i_process        IN VARCHAR2
    ) RETURN BOOLEAN IS
        --
        CURSOR c_department_ea IS
            SELECT bde.*
              FROM bmng_department_ea bde
             WHERE bde.id_department = i_department;
    
        r_department_ea bmng_department_ea%ROWTYPE;
        --
        l_total_unavailable_beds NUMBER(24);
        l_beds_blocked           NUMBER(24);
        l_beds_reserved          NUMBER(24);
        l_beds_ocuppied          NUMBER(24);
        l_total_available_beds   NUMBER(24);
        l_tot_avail_hours        NUMBER(24);
        --
        o_rowids    table_varchar;
        l_error_out t_error_out;
    BEGIN
    
        g_error := 'OPEN CURSOR c_department_ea';
        OPEN c_department_ea;
        FETCH c_department_ea
            INTO r_department_ea;
        CLOSE c_department_ea;
    
        --
        l_total_unavailable_beds := r_department_ea.total_unavailable_beds;
        l_beds_blocked           := r_department_ea.beds_blocked;
        l_beds_reserved          := r_department_ea.beds_reserved;
        l_beds_ocuppied          := r_department_ea.beds_ocuppied;
        l_total_available_beds   := r_department_ea.total_available_beds;
        --
        l_tot_avail_hours := r_department_ea.total_avail_nch_hours;
        --
        IF i_process = 'B' --Block
        THEN
            l_beds_blocked           := l_beds_blocked + 1;
            l_total_unavailable_beds := l_total_unavailable_beds + 1;
            l_total_available_beds   := l_total_available_beds - 1;
        ELSIF i_process = 'U' --Unblock
        THEN
            l_beds_blocked           := l_beds_blocked - 1;
            l_total_unavailable_beds := l_total_unavailable_beds - 1;
            l_total_available_beds   := l_total_available_beds + 1;
        ELSIF i_process = 'O' --Ocupy (after reserve)
        THEN
            l_beds_reserved := l_beds_reserved - 1;
            l_beds_ocuppied := l_beds_ocuppied + 1;
        ELSIF i_process = 'T' --Ocupy temporary bed
        THEN
            l_beds_ocuppied          := l_beds_ocuppied + 1;
            l_total_unavailable_beds := l_total_unavailable_beds + 1;
        ELSIF i_process = 'P' --Ocupy permanent bed
        THEN
            l_beds_ocuppied          := l_beds_ocuppied + 1;
            l_total_unavailable_beds := l_total_unavailable_beds + 1;
            l_total_available_beds   := l_total_available_beds - 1;
        ELSIF i_process = 'V' --Free bed
        THEN
            l_total_unavailable_beds := l_total_unavailable_beds - 1;
        
            -- Only if bed is permanent
            IF i_flg_bed_type = 'P'
            THEN
                l_total_available_beds := l_total_available_beds + 1;
            END IF;
        
            -- Bed could be reserved or ocuppied
            IF i_flg_bed_status = 'R'
            THEN
                l_beds_reserved := l_beds_reserved - 1;
            ELSIF i_flg_bed_status = 'N'
            THEN
                l_beds_ocuppied := l_beds_ocuppied - 1;
            END IF;
        ELSIF i_process = 'R' --Reserve bed
        THEN
            l_beds_reserved := l_beds_reserved + 1;
            l_beds_ocuppied := l_beds_ocuppied - 1;
            --
            --
            -- TOOLS
        ELSIF i_process = 'NT' --NCH edition in TOOLS for a Service
              AND i_dep_nch IS NOT NULL
              AND i_dep_nch > 0
        THEN
            l_tot_avail_hours := i_dep_nch;

        END IF;
    
        g_error := 'TS_BMNG_DEPARTMENT_EA.UPD';
        ts_bmng_department_ea.upd(id_department_in => i_department,
                                  --
                                  total_unavailable_beds_in    => l_total_unavailable_beds,
                                  total_unavailable_beds_nin   => FALSE,
                                  total_available_beds_in      => l_total_available_beds,
                                  total_available_beds_nin     => FALSE,
                                  beds_blocked_in              => l_beds_blocked,
                                  beds_blocked_nin             => FALSE,
                                  beds_reserved_in             => l_beds_reserved,
                                  beds_reserved_nin            => FALSE,
                                  beds_ocuppied_in             => l_beds_ocuppied,
                                  beds_ocuppied_nin            => FALSE,
                                  total_ocuppied_nch_hours_in  => 0,
                                  total_ocuppied_nch_hours_nin => FALSE,
                                  total_avail_nch_hours_in     => l_tot_avail_hours,
                                  total_avail_nch_hours_nin    => TRUE,
                                  rows_out                     => o_rowids);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEP_EA_NEW_VALUES',
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_department_ea;

    /*******************************************************************************************************************************************
    * Name:                           SET_BMNG_BED
    * Description:                    Function that updates bed action information in the BED Management Easy Access table (BMNG_BED_EA)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/29
    *******************************************************************************************************************************************/
    PROCEDURE set_bmng_bed
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row      bmng_bed_ea%ROWTYPE;
        l_func_proc_name   VARCHAR2(30) := 'SET_BMNG_BED';
        l_name_table_ea    VARCHAR2(30) := 'BMNG_BED_EA';
        l_process_name     VARCHAR2(30);
        l_rowids           table_varchar;
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_action_flg       bmng_action.flg_status%TYPE;
        l_dep_nch_capacity NUMBER(24);
        l_flg_action       VARCHAR2(2);
        l_flg_bab_outdated VARCHAR2(1);
        l_dt_end           bmng_bed_ea.dt_end%TYPE;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        l_rows_out         table_varchar := table_varchar();
        --    
        l_rowid VARCHAR2(1000 CHAR);
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET BMNG_ACTION ROWIDS';
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                --DELETE FROM tbl_temp;
                --insert_tbl_temp(i_vc_1 => l_rowids);
            
                FOR r_cur IN (SELECT /*+ opt_estimate(table ba rows=1) */
                               ba.id_bmng_action,
                               bed.id_bed,
                               ba.dt_begin_action dt_begin,
                               ba.dt_end_action dt_end,
                               ba.id_bmng_reason_type,
                               ba.id_bmng_reason,
                               bab.id_episode,
                               bab.id_patient,
                               roo.id_room,
                               dep.id_admission_type,
                               roo.id_room_type,
                               bab.id_bmng_allocation_bed,
                               bed.id_bed_type,
                               dep.id_department,
                               ds.dt_discharge_schedule,
                               nvl(en.flg_type,
                                   decode(nl.id_nch_level, NULL, NULL, pk_bmng_constant.g_bmng_bed_ea_flg_nch_u)) flg_type,
                               ai.id_nch_level,
                               nvl(ba.flg_bed_ocupacity_status, bed.flg_status) flg_bed_ocupacity_status,
                               ba.flg_bed_status,
                               ba.flg_bed_cleaning_status,
                               bed.flg_type flg_bed_type,
                               decode(ba.action_notes, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) has_notes,
                               ba.flg_status,
                               ba.nch_capacity,
                               ba.flg_action,
                               bab.flg_outdated flg_bab_outdated
                                FROM bmng_action ba
                                LEFT JOIN bmng_allocation_bed bab
                                  ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed)
                                LEFT JOIN epis_nch en
                                  ON (en.id_epis_nch = bab.id_epis_nch AND en.flg_status = pk_alert_constant.g_active)
                                LEFT JOIN bed bed
                                  ON (ba.id_bed = bed.id_bed)
                                LEFT JOIN room roo
                                  ON (roo.id_room = bed.id_room AND roo.flg_available = pk_alert_constant.g_yes)
                               INNER JOIN department dep
                                  ON (dep.id_department = roo.id_department AND
                                     dep.flg_available = pk_alert_constant.g_yes)
                                LEFT JOIN discharge_schedule ds
                                  ON (ds.id_episode = bab.id_episode AND ds.flg_status = pk_alert_constant.g_yes)
                                LEFT JOIN adm_request ar
                                  ON (ar.id_dest_episode = bab.id_episode)
                                LEFT JOIN adm_indication ai
                                  ON (ai.id_adm_indication = ar.id_adm_indication)
                                LEFT JOIN nch_level nl
                                  ON nl.id_previous = ai.id_nch_level
                               WHERE ba.rowid IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                   column_value
                                                    FROM TABLE(l_rowids) t))
                
                LOOP
                
                    IF r_cur.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b
                       OR r_cur.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_u
                       OR r_cur.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_bt
                       OR r_cur.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_ut
                    THEN
                        l_dt_end := r_cur.dt_end;
                    ELSE
                        l_dt_end := NULL;
                    END IF;
                
                    g_error                         := 'DEFINE NEW RECORD FOR BMNG_BED_EA';
                    l_new_rec_row.id_bmng_action    := r_cur.id_bmng_action;
                    l_new_rec_row.id_bed            := r_cur.id_bed;
                    l_new_rec_row.dt_begin          := r_cur.dt_begin;
                    l_new_rec_row.dt_end            := l_dt_end;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_bmng_reason_type    := r_cur.id_bmng_reason_type;
                    l_new_rec_row.id_bmng_reason         := r_cur.id_bmng_reason;
                    l_new_rec_row.id_episode             := r_cur.id_episode;
                    l_new_rec_row.id_patient             := r_cur.id_patient;
                    l_new_rec_row.id_room                := r_cur.id_room;
                    l_new_rec_row.id_admission_type      := r_cur.id_admission_type;
                    l_new_rec_row.id_room_type           := r_cur.id_room_type;
                    l_new_rec_row.id_bmng_allocation_bed := r_cur.id_bmng_allocation_bed;
                    l_new_rec_row.id_bed_type            := r_cur.id_bed_type;
                    l_new_rec_row.id_department          := r_cur.id_department;
                    l_new_rec_row.dt_discharge_schedule  := r_cur.dt_discharge_schedule;
                    --
                    l_new_rec_row.flg_allocation_nch       := r_cur.flg_type;
                    l_new_rec_row.id_nch_level             := r_cur.id_nch_level;
                    l_new_rec_row.flg_bed_ocupacity_status := r_cur.flg_bed_ocupacity_status;
                    l_new_rec_row.flg_bed_status           := r_cur.flg_bed_status;
                    l_new_rec_row.flg_bed_cleaning_status  := r_cur.flg_bed_cleaning_status;
                    l_new_rec_row.flg_bed_type             := r_cur.flg_bed_type;
                    l_new_rec_row.has_notes                := r_cur.has_notes;
                    --
                    l_action_flg       := r_cur.flg_status;
                    l_dep_nch_capacity := r_cur.nch_capacity;
                    l_flg_action       := r_cur.flg_action;
                    l_flg_bab_outdated := r_cur.flg_bab_outdated;
                    --
                    /*
                    BEGIN
                        SELECT b.flg_bed_status
                          INTO l_last_flg_bed_status
                          FROM bmng_bed_ea b
                         WHERE b.id_bmng_allocation_bed = r_cur.id_bmng_allocation_bed;
                    EXCEPTION
                        WHEN no_data_found THEN
                            RAISE value_error;
                    END;
                    */
                
                    --
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    --
                    -- Events in BMNG_BED_EA table is dependent of l_action_flg variable
                    IF l_action_flg = pk_bmng_constant.g_bmng_act_flg_status_a -- Active
                    --AND (l_flg_bab_outdated = pk_alert_constant.g_no OR l_flg_bab_outdated IS NULL)
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM bmng_bed_ea bbe
                         WHERE bbe.id_bmng_action = l_new_rec_row.id_bmng_action;
                    
                        -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := t_data_gov_mnt.g_event_update;
                        ELSE
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := t_data_gov_mnt.g_event_insert;
                        END IF;
                    ELSE
                        --IF l_action_flg = pk_bmng_constant.g_bmng_act_flg_status_c -- Cancelled
                        --OR l_action_flg = pk_bmng_constant.g_bmng_act_flg_status_o -- Outdated
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := t_data_gov_mnt.g_event_delete;
                    END IF;
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_BMNG_BED_EA.INS';
                        ts_bmng_bed_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_BMNG_BED_EA.DEL_BY';
                        ts_bmng_bed_ea.del_by(where_clause_in => 'id_bmng_action = ' || l_new_rec_row.id_bmng_action,
                                              rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_BMNG_BED_EA.UPD';
                        ts_bmng_bed_ea.upd(id_bmng_action_in => l_new_rec_row.id_bmng_action,
                                           --
                                           id_bed_in                    => l_new_rec_row.id_bed,
                                           id_bed_nin                   => TRUE,
                                           dt_begin_in                  => l_new_rec_row.dt_begin,
                                           dt_begin_nin                 => FALSE, --TRUE,
                                           dt_end_in                    => l_new_rec_row.dt_end,
                                           dt_end_nin                   => TRUE,
                                           id_bmng_reason_type_in       => l_new_rec_row.id_bmng_reason_type,
                                           id_bmng_reason_type_nin      => FALSE, --TRUE,
                                           id_bmng_reason_in            => l_new_rec_row.id_bmng_reason,
                                           id_bmng_reason_nin           => TRUE,
                                           id_episode_in                => l_new_rec_row.id_episode,
                                           id_episode_nin               => TRUE,
                                           id_patient_in                => l_new_rec_row.id_patient,
                                           id_patient_nin               => TRUE,
                                           id_room_in                   => l_new_rec_row.id_room,
                                           id_room_nin                  => TRUE,
                                           id_admission_type_in         => l_new_rec_row.id_admission_type,
                                           id_admission_type_nin        => TRUE,
                                           id_room_type_in              => l_new_rec_row.id_room_type,
                                           id_room_type_nin             => TRUE,
                                           id_bmng_allocation_bed_in    => l_new_rec_row.id_bmng_allocation_bed,
                                           id_bmng_allocation_bed_nin   => TRUE,
                                           id_bed_type_in               => l_new_rec_row.id_bed_type,
                                           id_bed_type_nin              => TRUE,
                                           dt_discharge_schedule_in     => l_new_rec_row.dt_discharge_schedule,
                                           dt_discharge_schedule_nin    => TRUE,
                                           flg_allocation_nch_in        => l_new_rec_row.flg_allocation_nch,
                                           flg_allocation_nch_nin       => TRUE,
                                           id_nch_level_in              => l_new_rec_row.id_nch_level,
                                           id_nch_level_nin             => TRUE,
                                           flg_bed_ocupacity_status_in  => l_new_rec_row.flg_bed_ocupacity_status,
                                           flg_bed_ocupacity_status_nin => TRUE,
                                           flg_bed_status_in            => l_new_rec_row.flg_bed_status,
                                           flg_bed_status_nin           => TRUE,
                                           flg_bed_cleaning_status_in   => l_new_rec_row.flg_bed_cleaning_status,
                                           flg_bed_cleaning_status_nin  => TRUE,
                                           has_notes_in                 => l_new_rec_row.has_notes,
                                           has_notes_nin                => FALSE, --TRUE
                                           flg_bed_type_in              => l_new_rec_row.flg_bed_type,
                                           flg_bed_type_nin             => TRUE,
                                           id_department_in             => l_new_rec_row.id_department,
                                           id_department_nin            => FALSE, --TRUE
                                           rows_out                     => o_rowids);
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                    --get rowid for department
                    BEGIN
                        SELECT ROWID
                          INTO l_rowid
                          FROM department dep
                         WHERE dep.id_department = l_new_rec_row.id_department;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_rowid := NULL;
                    END;
                
                    IF l_rowid IS NOT NULL
                    THEN
                        l_rows_out.extend;
                        l_rows_out(l_rows_out.count) := l_rowid;
                    END IF;
                
                END LOOP;
            
                g_error := 'call t_data_gov_mnt.process_update for DEPARTMENT';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'DEPARTMENT',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error_out);
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BMNG_BED',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_bmng_bed;

    /**
    * Process insert/update events on EPIS_DIET_REQ into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               paulo teixeira
    * @version               2.6.3
    * @since                2013/04/30
    */
    PROCEDURE set_bmng_department_ea
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_BMNG_DEPARTMENT_EA';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'BMNG_DEPARTMENT_EA';
        l_id_department            bmng_department_ea.id_department%TYPE;
        l_flg_available            department.flg_available%TYPE;
        l_total_ocuppied_nch_hours bmng_department_ea.total_ocuppied_nch_hours%TYPE;
        l_beds_blocked             bmng_department_ea.beds_blocked%TYPE;
        l_beds_reserved            bmng_department_ea.beds_reserved%TYPE;
        l_beds_ocuppied            bmng_department_ea.beds_ocuppied%TYPE;
        l_total_avail_nch_hours    bmng_department_ea.total_avail_nch_hours%TYPE;
        l_total_available_beds     bmng_department_ea.total_available_beds%TYPE;
        l_total_unavailable_beds   bmng_department_ea.total_unavailable_beds%TYPE;
        o_rowids                   table_varchar;
        l_rows                     table_varchar := table_varchar();
        l_error                    t_error_out;
        l_current_timestamp        TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_count                    NUMBER(12);
        l_count_temp_beds          sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_code_cf => 'BMNG_COUNT_TEMP_BEDS',
                                                                                        i_prof    => i_prof),
                                                                pk_alert_constant.g_yes);
    
        CURSOR c_dept IS
            SELECT 
                   /*+ opt_estimate(table dep1 rows=1) */ 
                   dep1.id_department id_department,
                   dep1.flg_available,
                   nvl(nch_numbers.num_total_ocupied_nch_hours, 0) total_ocuppied_nch_hours,
                   nvl(beds_numbers.num_beds_blocked, 0) beds_blocked,
                   nvl(beds_numbers.num_beds_reserved, 0) beds_reserved,
                   nvl(beds_numbers.num_beds_occupied, 0) beds_ocuppied,
                   nch_numbers.num_total_avail_nch_hours total_avail_nch_hours,
                   nvl(beds_avail.num_avail_beds , 0) total_available_beds,
                   nvl((beds_occup.num_occup_beds + beds_numbers.num_beds_reserved),
                       nvl(beds_numbers.num_beds_reserved, 0)) total_unavailable_beds
              FROM department dep1
              LEFT JOIN (SELECT dep.id_department,
                                nvl(COUNT(ba_blocked.flg_bed_status), 0) num_beds_blocked,
                                COUNT(ba_reserved.flg_bed_status) num_beds_reserved,
                                COUNT(ba_ocupied.flg_bed_status) num_beds_occupied
                           FROM department dep
                          INNER JOIN room roo
                             ON (roo.id_department = dep.id_department AND roo.flg_available = pk_alert_constant.g_yes)
                          INNER JOIN bed bed
                             ON (bed.id_room = roo.id_room AND bed.flg_available = pk_alert_constant.g_yes)
                           LEFT JOIN bmng_allocation_bed bab
                             ON (bab.id_bed = bed.id_bed AND bab.flg_outdated = pk_alert_constant.g_no)
                           LEFT JOIN bmng_action ba_blocked
                             ON (ba_blocked.id_bed = bed.id_bed AND ba_blocked.id_room = roo.id_room AND
                                ba_blocked.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba_blocked.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b AND
                                ba_blocked.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v)
                           LEFT JOIN (SELECT a.id_bmng_allocation_bed,
                                            a.id_bed,
                                            row_number() over(PARTITION BY a.id_bed ORDER BY a.dt_creation DESC, a.dt_release desc) rn
                                       FROM bmng_allocation_bed a
                                      WHERE a.flg_outdated = pk_alert_constant.g_yes
                                      ) bab_rvd
                             ON bab_rvd.id_bed = bed.id_bed
                            AND bab_rvd.rn = 1
                           LEFT JOIN bmng_action ba_reserved
                             ON (ba_reserved.id_bed = bed.id_bed AND
                                ba_reserved.id_bmng_allocation_bed = bab_rvd.id_bmng_allocation_bed AND
                                ba_reserved.id_room = roo.id_room AND
                                ba_reserved.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba_reserved.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_r AND
                                ba_reserved.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                           LEFT JOIN bmng_action ba_ocupied
                             ON (ba_ocupied.id_bed = bed.id_bed AND
                                ba_ocupied.id_bmng_allocation_bed = bab.id_bmng_allocation_bed AND
                                ba_ocupied.id_room = roo.id_room AND
                                ba_ocupied.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba_ocupied.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n AND
                                ba_ocupied.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                          WHERE dep.flg_available = pk_alert_constant.g_yes
                            AND ((l_count_temp_beds = pk_alert_constant.g_no AND
                                bed.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p) OR
                                l_count_temp_beds = pk_alert_constant.g_yes)
                          GROUP BY dep.id_department) beds_numbers
                ON (beds_numbers.id_department = dep1.id_department)
              LEFT JOIN (
                         
                         SELECT data.id_department,
                                 data.num_total_ocupied_nch_hours,
                                 SUM(data.nch_capacity) num_total_avail_nch_hours
                           FROM (SELECT dep2.id_department,
                                         pk_bmng_core.get_nch_service_level(i_lang, i_prof, dep2.id_department) num_total_ocupied_nch_hours,
                                         
                                         ba_avail_nch.nch_capacity
                                    FROM department dep2
                                   INNER JOIN bmng_action ba_avail_nch
                                      ON (ba_avail_nch.id_department = dep2.id_department AND
                                         ba_avail_nch.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_s AND
                                         ba_avail_nch.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                         ba_avail_nch.flg_origin_action IN
                                         (pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                           pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                           pk_bmng_constant.g_bmng_act_flg_origin_nd))
                                     AND ba_avail_nch.dt_begin_action <= l_current_timestamp
                                     AND (ba_avail_nch.dt_end_action >= l_current_timestamp OR
                                         ba_avail_nch.dt_end_action IS NULL)
                                   WHERE dep2.flg_available = pk_alert_constant.g_yes) data
                          GROUP BY data.id_department, data.num_total_ocupied_nch_hours) nch_numbers
                ON (nch_numbers.id_department = dep1.id_department)
              LEFT JOIN (SELECT COUNT(b1.id_bed) num_avail_beds, r1.id_department
                           FROM bed b1
                           LEFT JOIN bmng_action ba
                             ON (b1.id_bed = ba.id_bed AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba.flg_bed_ocupacity_status <> pk_bmng_constant.g_bmng_act_flg_ocupaci_o AND
                                ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n)
                          INNER JOIN room r1
                             ON (r1.id_room = b1.id_room AND r1.flg_available = pk_alert_constant.g_yes)
                          WHERE b1.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
                            AND b1.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                            AND b1.flg_available = pk_alert_constant.g_yes
                          GROUP BY r1.id_department) beds_avail
                ON (beds_avail.id_department = dep1.id_department)
              LEFT JOIN (SELECT COUNT(b2.id_bed) num_occup_beds, r2.id_department
                           FROM bmng_action ba
                          INNER JOIN bed b2
                             ON (b2.id_bed = ba.id_bed AND b2.flg_available = pk_alert_constant.g_yes)
                          INNER JOIN room r2
                             ON (r2.id_room = b2.id_room AND r2.flg_available = pk_alert_constant.g_yes)
                           LEFT JOIN bmng_allocation_bed bab
                             ON (bab.id_bed = b2.id_bed AND bab.flg_outdated = pk_alert_constant.g_no)
                          WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                            AND ((ba.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o AND
                                bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed) OR
                                ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b)
                            AND ((l_count_temp_beds = pk_alert_constant.g_no AND
                                b2.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p) OR
                                l_count_temp_beds = pk_alert_constant.g_yes)
                          GROUP BY r2.id_department) beds_occup
                ON (beds_occup.id_department = dep1.id_department)
             WHERE dep1.rowid IN (SELECT  /*+ opt_estimate(table t rows=1) */ 
                                   t.column_value row_id
                                    FROM TABLE(i_rowids) t)
               AND instr(dep1.flg_type, 'I') > 0;
    
    BEGIN
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => i_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        -- debug event
        g_error := 'processing insert or update event on ' || i_src_table || ' into ' || l_ea_table;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        -- get diet data from rowids
        g_error := 'OPEN c_diet';
        OPEN c_dept;
        LOOP
            g_error := ' FETCH c_dept';
            FETCH c_dept
                INTO l_id_department,
                     l_flg_available,
                     l_total_ocuppied_nch_hours,
                     l_beds_blocked,
                     l_beds_reserved,
                     l_beds_ocuppied,
                     l_total_avail_nch_hours,
                     l_total_available_beds,
                     l_total_unavailable_beds;
            EXIT WHEN c_dept%NOTFOUND;
        
            g_error := 'SELECT COUNT(1) INTO l_count';
            SELECT COUNT(1)
              INTO l_count
              FROM bmng_department_ea a
             WHERE a.id_department = l_id_department;
        
            IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
               AND l_flg_available = pk_alert_constant.g_yes
            THEN
                IF l_count = 0
                THEN
                    g_error := 'ts_bmng_department_ea.ins';
                    ts_bmng_department_ea.ins(id_department_in            => l_id_department,
                                              total_ocuppied_nch_hours_in => l_total_ocuppied_nch_hours,
                                              beds_blocked_in             => l_beds_blocked,
                                              beds_reserved_in            => l_beds_reserved,
                                              beds_ocuppied_in            => l_beds_ocuppied,
                                              total_avail_nch_hours_in    => l_total_avail_nch_hours,
                                              total_available_beds_in     => l_total_available_beds,
                                              total_unavailable_beds_in   => l_total_unavailable_beds,
                                              dt_dg_last_update_in        => l_current_timestamp,
                                              rows_out                    => l_rows);
                ELSE
                    g_error := 'ts_bmng_department_ea.upd';
                    ts_bmng_department_ea.upd(id_department_in             => l_id_department,
                                              total_ocuppied_nch_hours_in  => l_total_ocuppied_nch_hours,
                                              total_ocuppied_nch_hours_nin => FALSE,
                                              beds_blocked_in              => l_beds_blocked,
                                              beds_blocked_nin             => FALSE,
                                              beds_reserved_in             => l_beds_reserved,
                                              beds_reserved_nin            => FALSE,
                                              beds_ocuppied_in             => l_beds_ocuppied,
                                              beds_ocuppied_nin            => FALSE,
                                              total_avail_nch_hours_in     => l_total_avail_nch_hours,
                                              total_avail_nch_hours_nin    => FALSE,
                                              total_available_beds_in      => l_total_available_beds,
                                              total_available_beds_nin     => FALSE,
                                              total_unavailable_beds_in    => l_total_unavailable_beds,
                                              total_unavailable_beds_nin   => FALSE,
                                              dt_dg_last_update_in         => l_current_timestamp,
                                              rows_out                     => l_rows);
                END IF;
            
            ELSE
                g_error := 'ts_bmng_department_ea.del';
                ts_bmng_department_ea.del(id_department_in => l_id_department);
            
                g_error := 'TS_BMNG_BED_EA.DEL_BY';
                ts_bmng_bed_ea.del_by(where_clause_in => 'id_department = ' || l_id_department, rows_out => o_rowids);
            
            END IF;
        
        END LOOP;
        CLOSE c_dept;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END set_bmng_department_ea;

    PROCEDURE set_bmng_department_bed_ea
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_BMNG_DEPARTMENT_BED_EA';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'BMNG_DEPARTMENT_EA';
        l_id_department            bmng_department_ea.id_department%TYPE;
        l_flg_available            department.flg_available%TYPE;
        l_total_ocuppied_nch_hours bmng_department_ea.total_ocuppied_nch_hours%TYPE;
        l_beds_blocked             bmng_department_ea.beds_blocked%TYPE;
        l_beds_reserved            bmng_department_ea.beds_reserved%TYPE;
        l_beds_ocuppied            bmng_department_ea.beds_ocuppied%TYPE;
        l_total_avail_nch_hours    bmng_department_ea.total_avail_nch_hours%TYPE;
        l_total_available_beds     bmng_department_ea.total_available_beds%TYPE;
        l_total_unavailable_beds   bmng_department_ea.total_unavailable_beds%TYPE;
        o_rowids                   table_varchar;
        l_rows                     table_varchar := table_varchar();
        l_error                    t_error_out;
        l_current_timestamp        TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_count                    NUMBER(12);
        l_count_temp_beds          sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_code_cf => 'BMNG_COUNT_TEMP_BEDS',
                                                                                        i_prof    => i_prof),
                                                                pk_alert_constant.g_yes);
    
        l_rowsid table_varchar;
        CURSOR c_dept IS
            SELECT /*+ opt_estimate(table dep1 rows=1) */ 
                   dep1.id_department id_department,
                   dep1.flg_available,
                   nvl(nch_numbers.num_total_ocupied_nch_hours, 0) total_ocuppied_nch_hours,
                   nvl(beds_numbers.num_beds_blocked, 0) beds_blocked,
                   nvl(beds_numbers.num_beds_reserved, 0) beds_reserved,
                   nvl(beds_numbers.num_beds_occupied, 0) beds_ocuppied,
                   nch_numbers.num_total_avail_nch_hours total_avail_nch_hours,
                   nvl(beds_avail.num_avail_beds, 0) total_available_beds,
                   nvl((beds_occup.num_occup_beds + beds_numbers.num_beds_reserved),
                       nvl(beds_numbers.num_beds_reserved, 0)) total_unavailable_beds
              FROM department dep1
              LEFT JOIN (SELECT dep.id_department,
                                nvl(COUNT(ba_blocked.flg_bed_status), 0) num_beds_blocked,
                                COUNT(ba_reserved.flg_bed_status) num_beds_reserved,
                                COUNT(ba_ocupied.flg_bed_status) num_beds_occupied
                           FROM department dep
                          INNER JOIN room roo
                             ON (roo.id_department = dep.id_department AND roo.flg_available = pk_alert_constant.g_yes)
                          INNER JOIN bed bed
                             ON (bed.id_room = roo.id_room AND bed.flg_available = pk_alert_constant.g_yes)
                           LEFT JOIN bmng_allocation_bed bab
                             ON (bab.id_bed = bed.id_bed AND bab.flg_outdated = pk_alert_constant.g_no)
                           LEFT JOIN bmng_action ba_blocked
                             ON (ba_blocked.id_bed = bed.id_bed AND ba_blocked.id_room = roo.id_room AND
                                ba_blocked.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba_blocked.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b AND
                                ba_blocked.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_v)
                           LEFT JOIN (SELECT a.id_bmng_allocation_bed,
                                            a.id_bed,
                                            row_number() over(PARTITION BY a.id_bed ORDER BY a.dt_creation DESC, a.dt_release desc) rn
                                       FROM bmng_allocation_bed a
                                      WHERE a.flg_outdated = pk_alert_constant.g_yes
                                      ) bab_rvd
                             ON bab_rvd.id_bed = bed.id_bed
                            AND bab_rvd.rn = 1
                           LEFT JOIN bmng_action ba_reserved
                             ON (ba_reserved.id_bed = bed.id_bed AND
                                ba_reserved.id_bmng_allocation_bed = bab_rvd.id_bmng_allocation_bed AND
                                ba_reserved.id_room = roo.id_room AND
                                ba_reserved.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba_reserved.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_r AND
                                ba_reserved.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                           LEFT JOIN bmng_action ba_ocupied
                             ON (ba_ocupied.id_bed = bed.id_bed AND
                                ba_ocupied.id_bmng_allocation_bed = bab.id_bmng_allocation_bed AND
                                ba_ocupied.id_room = roo.id_room AND
                                ba_ocupied.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba_ocupied.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n AND
                                ba_ocupied.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o)
                          WHERE dep.flg_available = pk_alert_constant.g_yes
                            AND ((l_count_temp_beds = pk_alert_constant.g_no AND
                                bed.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p) OR
                                l_count_temp_beds = pk_alert_constant.g_yes)
                          GROUP BY dep.id_department) beds_numbers
                ON (beds_numbers.id_department = dep1.id_department)
              LEFT JOIN (
                         
                         SELECT data.id_department,
                                 data.num_total_ocupied_nch_hours,
                                 SUM(data.nch_capacity) num_total_avail_nch_hours
                           FROM (SELECT dep2.id_department,
                                         pk_bmng_core.get_nch_service_level(i_lang, i_prof, dep2.id_department) num_total_ocupied_nch_hours,
                                         
                                         ba_avail_nch.nch_capacity
                                    FROM department dep2
                                   INNER JOIN bmng_action ba_avail_nch
                                      ON (ba_avail_nch.id_department = dep2.id_department AND
                                         ba_avail_nch.flg_target_action = pk_bmng_constant.g_bmng_act_flg_target_s AND
                                         ba_avail_nch.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                         ba_avail_nch.flg_origin_action IN
                                         (pk_bmng_constant.g_bmng_act_flg_origin_nb,
                                           pk_bmng_constant.g_bmng_act_flg_origin_nt,
                                           pk_bmng_constant.g_bmng_act_flg_origin_nd))
                                     AND ba_avail_nch.dt_begin_action <= l_current_timestamp
                                     AND (ba_avail_nch.dt_end_action >= l_current_timestamp OR
                                         ba_avail_nch.dt_end_action IS NULL)
                                   WHERE dep2.flg_available = pk_alert_constant.g_yes) data
                          GROUP BY data.id_department, data.num_total_ocupied_nch_hours) nch_numbers
                ON (nch_numbers.id_department = dep1.id_department)
              LEFT JOIN (SELECT COUNT(b1.id_bed) num_avail_beds, r1.id_department
                           FROM bed b1
                           LEFT JOIN bmng_action ba
                             ON (b1.id_bed = ba.id_bed AND ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a AND
                                ba.flg_bed_ocupacity_status <> pk_bmng_constant.g_bmng_act_flg_ocupaci_o AND
                                ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_n)
                          INNER JOIN room r1
                             ON (r1.id_room = b1.id_room AND r1.flg_available = pk_alert_constant.g_yes)
                          WHERE b1.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p
                            AND b1.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                            AND b1.flg_available = pk_alert_constant.g_yes
                          GROUP BY r1.id_department) beds_avail
                ON (beds_avail.id_department = dep1.id_department)
              LEFT JOIN (SELECT COUNT(b2.id_bed) num_occup_beds, r2.id_department
                           FROM bmng_action ba
                          INNER JOIN bed b2
                             ON (b2.id_bed = ba.id_bed AND b2.flg_available = pk_alert_constant.g_yes)
                          INNER JOIN room r2
                             ON (r2.id_room = b2.id_room AND r2.flg_available = pk_alert_constant.g_yes)
                           LEFT JOIN bmng_allocation_bed bab
                             ON (bab.id_bed = b2.id_bed AND bab.flg_outdated = pk_alert_constant.g_no)
                          WHERE ba.flg_status = pk_bmng_constant.g_bmng_act_flg_status_a
                            AND ((ba.flg_bed_ocupacity_status = pk_bmng_constant.g_bmng_act_flg_ocupaci_o AND
                                bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed) OR
                                ba.flg_bed_status = pk_bmng_constant.g_bmng_act_flg_bed_sta_b)
                            AND ((l_count_temp_beds = pk_alert_constant.g_no AND
                                b2.flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p) OR
                                l_count_temp_beds = pk_alert_constant.g_yes)
                          GROUP BY r2.id_department) beds_occup
                ON (beds_occup.id_department = dep1.id_department)
             WHERE dep1.rowid IN (SELECT /*+ opt_estimate(table t rows=1) */ 
                                   t.column_value row_id
                                    FROM TABLE(l_rowsid) t)
               AND instr(dep1.flg_type, 'I') > 0;
    
    BEGIN
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => i_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_delete)
        THEN
            -- debug event
            g_error := 'processing insert or update event on ' || i_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            SELECT d.rowid
              BULK COLLECT
              INTO l_rowsid
              FROM department d
              JOIN room r
                ON d.id_department = r.id_department
              JOIN bed b
                ON r.id_room = b.id_room
             WHERE b.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                t.column_value row_id
                                 FROM TABLE(i_rowids) t)
               AND instr(d.flg_type, 'I') > 0;
        
            -- get departmment data from rowids
            g_error := 'OPEN c_dept';
            OPEN c_dept;
            LOOP
                g_error := ' FETCH c_dept';
                FETCH c_dept
                    INTO l_id_department,
                         l_flg_available,
                         l_total_ocuppied_nch_hours,
                         l_beds_blocked,
                         l_beds_reserved,
                         l_beds_ocuppied,
                         l_total_avail_nch_hours,
                         l_total_available_beds,
                         l_total_unavailable_beds;
                EXIT WHEN c_dept%NOTFOUND;
            
                g_error := 'SELECT COUNT(1) INTO l_count';
                SELECT COUNT(1)
                  INTO l_count
                  FROM bmng_department_ea a
                 WHERE a.id_department = l_id_department;
            
                IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_delete)
                   AND l_flg_available = pk_alert_constant.g_yes
                THEN
                    IF l_count = 0
                    THEN
                        g_error := 'ts_bmng_department_ea.ins';
                        ts_bmng_department_ea.ins(id_department_in            => l_id_department,
                                                  total_ocuppied_nch_hours_in => l_total_ocuppied_nch_hours,
                                                  beds_blocked_in             => l_beds_blocked,
                                                  beds_reserved_in            => l_beds_reserved,
                                                  beds_ocuppied_in            => l_beds_ocuppied,
                                                  total_avail_nch_hours_in    => l_total_avail_nch_hours,
                                                  total_available_beds_in     => l_total_available_beds,
                                                  total_unavailable_beds_in   => l_total_unavailable_beds,
                                                  dt_dg_last_update_in        => l_current_timestamp,
                                                  rows_out                    => l_rows);
                    ELSE
                        g_error := 'ts_bmng_department_ea.upd';
                        ts_bmng_department_ea.upd(id_department_in             => l_id_department,
                                                  total_ocuppied_nch_hours_in  => l_total_ocuppied_nch_hours,
                                                  total_ocuppied_nch_hours_nin => FALSE,
                                                  beds_blocked_in              => l_beds_blocked,
                                                  beds_blocked_nin             => FALSE,
                                                  beds_reserved_in             => l_beds_reserved,
                                                  beds_reserved_nin            => FALSE,
                                                  beds_ocuppied_in             => l_beds_ocuppied,
                                                  beds_ocuppied_nin            => FALSE,
                                                  total_avail_nch_hours_in     => l_total_avail_nch_hours,
                                                  total_avail_nch_hours_nin    => FALSE,
                                                  total_available_beds_in      => l_total_available_beds,
                                                  total_available_beds_nin     => FALSE,
                                                  total_unavailable_beds_in    => l_total_unavailable_beds,
                                                  total_unavailable_beds_nin   => FALSE,
                                                  dt_dg_last_update_in         => l_current_timestamp,
                                                  rows_out                     => l_rows);
                    END IF;
                
                ELSE
                    g_error := 'ts_bmng_department_ea.del';
                    ts_bmng_department_ea.del(id_department_in => l_id_department);
                
                    g_error := 'TS_BMNG_BED_EA.DEL_BY';
                    ts_bmng_bed_ea.del_by(where_clause_in => 'id_department = ' || l_id_department,
                                          rows_out        => o_rowids);
                
                END IF;
            
            END LOOP;
            CLOSE c_dept;
        END IF;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END set_bmng_department_bed_ea;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_ea_logic_bmng;
/
