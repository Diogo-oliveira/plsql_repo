/*-- Last Change Revision: $Rev: 2055402 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:44:22 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_task_groups IS

    -- Purpose : Task groups database package

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    /********************************************************************************************
    * initialize parameters for task groups list filter (auto-generated code)
    *
    * @author       Tiago Silva
    * @since        2013/05/20   
    ********************************************************************************************/
    PROCEDURE init_params_groups_list_filter
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    BEGIN
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            
        END CASE;
    END init_params_groups_list_filter;

    /********************************************************************************************
    * create a new task group
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_name                 task group name
    * @param       i_author               task group author
    * @param       i_flg_status           task group status
    * @param       i_notes                task group notes
    * @param       o_new_group_task_id    created task group id
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group       
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION create_task_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_name              IN VARCHAR2,
        i_author            IN VARCHAR2,
        i_flg_status        IN VARCHAR2,
        i_notes             IN VARCHAR2,
        o_new_group_task_id OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_task_group      task_group.code_task_group%TYPE;
        l_code_task_group_hist task_group.code_task_group%TYPE;
        l_rank                 task_group.rank%TYPE;
    BEGIN
    
        g_error := 'insert new task group';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        INSERT INTO task_group
            (id_task_group, author, flg_status, notes, dt_group_tstz, id_institution, id_professional)
        VALUES
            (seq_task_group.nextval, i_author, i_flg_status, i_notes, current_timestamp, i_prof.institution, i_prof.id)
        RETURNING id_task_group, code_task_group, rank INTO o_new_group_task_id, l_code_task_group, l_rank;
    
        g_error := 'insert new task group name';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        pk_translation.insert_translation_trs(i_lang, l_code_task_group, i_name, g_module);
    
        g_error := 'insert task group history record';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        INSERT INTO task_group_hist
            (id_task_group_hist,
             id_task_group,
             author,
             flg_status,
             notes,
             rank,
             dt_group_tstz,
             id_institution,
             id_professional)
        VALUES
            (seq_task_group.nextval,
             o_new_group_task_id,
             i_author,
             i_flg_status,
             i_notes,
             l_rank,
             current_timestamp,
             i_prof.institution,
             i_prof.id)
        RETURNING code_task_group INTO l_code_task_group_hist;
    
        g_error := 'insert new task group name';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        pk_translation.insert_translation_trs(i_lang, l_code_task_group_hist, i_name, g_module);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_TASK_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_task_group;

    /********************************************************************************************
    * update/edit a task group
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_group           id of the task group to edit
    * @param       i_name                 new task group name
    * @param       i_author               new task group author
    * @param       i_flg_status           new task group status
    * @param       i_notes                new task group notes
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group      
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION update_task_group
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_group IN NUMBER,
        i_name          IN VARCHAR2,
        i_author        IN VARCHAR2,
        i_flg_status    IN VARCHAR2,
        i_notes         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_task_group      task_group.code_task_group%TYPE;
        l_code_task_group_hist task_group.code_task_group%TYPE;
        l_rank                 task_group.rank%TYPE;
    BEGIN
    
        g_error := 'update task group';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE task_group tg
           SET tg.author          = i_author,
               tg.flg_status      = i_flg_status,
               tg.notes           = i_notes,
               tg.dt_group_tstz   = current_timestamp,
               tg.id_institution  = i_prof.institution,
               tg.id_professional = i_prof.id
         WHERE tg.id_task_group = i_id_task_group RETURN code_task_group, rank INTO l_code_task_group, l_rank;
    
        g_error := 'update task group name';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        pk_translation.insert_translation_trs(i_lang, l_code_task_group, i_name, g_module);
    
        g_error := 'insert task group history record';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        INSERT INTO task_group_hist
            (id_task_group_hist,
             id_task_group,
             author,
             flg_status,
             notes,
             rank,
             dt_group_tstz,
             id_institution,
             id_professional)
        VALUES
            (seq_task_group.nextval,
             i_id_task_group,
             i_author,
             i_flg_status,
             i_notes,
             l_rank,
             current_timestamp,
             i_prof.institution,
             i_prof.id)
        RETURNING code_task_group INTO l_code_task_group_hist;
    
        g_error := 'insert task group history name';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        pk_translation.insert_translation_trs(i_lang, l_code_task_group_hist, i_name, g_module);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TASK_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_task_group;

    /********************************************************************************************
    * set task groups status internal
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_groups          list of task groups to set status
    * @param       i_flg_status           new task group status
    * @param       i_id_cancel_reason     reason to cancel the task groups (if applicable)
    * @param       i_cancel_notes         cancel notes (if applicable)
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group          
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION set_task_groups_status_intern
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_groups      IN table_number,
        i_flg_status       IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN task_group.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_group_name           table_varchar;
        l_tbl_code_task_group_hist table_varchar;
    
        TYPE t_task_group IS TABLE OF task_group%ROWTYPE INDEX BY PLS_INTEGER;
        ibt_task_group t_task_group;
    
        error_undefined_status EXCEPTION;
    BEGIN
    
        g_error := 'update task groups';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE task_group tg
           SET tg.flg_status       = i_flg_status,
               tg.id_institution   = i_prof.institution,
               tg.id_professional  = i_prof.id,
               tg.id_cancel_reason = i_id_cancel_reason,
               tg.cancel_notes     = i_cancel_notes
         WHERE tg.id_task_group IN (SELECT /*+opt_estimate(table odst_tsk_ids rows=1)*/
                                     column_value
                                      FROM TABLE(i_task_groups))
           AND tg.flg_status != i_flg_status;
    
        IF (SQL%ROWCOUNT != i_task_groups.count)
        THEN
            RAISE error_undefined_status;
        END IF;
    
        g_error := 'get data from task groups that were updated';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT tg.*
          BULK COLLECT
          INTO ibt_task_group
          FROM task_group tg
         WHERE tg.id_task_group IN (SELECT /*+opt_estimate(table odst_tsk_ids rows=1)*/
                                     column_value
                                      FROM TABLE(i_task_groups));
    
        g_error := 'insert task group history record';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN ibt_task_group.first .. ibt_task_group.last
            INSERT INTO task_group_hist
                (id_task_group_hist,
                 id_task_group,
                 author,
                 flg_status,
                 notes,
                 rank,
                 dt_group_tstz,
                 id_institution,
                 id_professional,
                 id_cancel_reason,
                 cancel_notes)
            VALUES
                (seq_task_group.nextval,
                 ibt_task_group(i).id_task_group,
                 ibt_task_group(i).author,
                 ibt_task_group(i).flg_status,
                 ibt_task_group(i).notes,
                 ibt_task_group(i).rank,
                 current_timestamp,
                 i_prof.institution,
                 i_prof.id,
                 ibt_task_group(i).id_cancel_reason,
                 ibt_task_group(i).cancel_notes)
            RETURNING code_task_group, pk_translation.get_translation_trs
                ('TASK_GROUP.CODE_TASK_GROUP.' || id_task_group) BULK COLLECT INTO l_tbl_code_task_group_hist, l_tbl_group_name;
    
        g_error := 'insert task groups history names';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR i IN 1 .. l_tbl_group_name.count
        LOOP
            pk_translation.insert_translation_trs(i_lang, l_tbl_code_task_group_hist(i), l_tbl_group_name(i), g_module);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN error_undefined_status THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / UNDEFINED STATE FOR SOME TASK GROUP',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_GROUPS_STATUS_INTERN',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_GROUP_STATUS_INTERN',
                                              o_error);
            RETURN FALSE;
    END set_task_groups_status_intern;

    /********************************************************************************************
    * cancel task group
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_group           task group to cancel
    * @param       i_id_cancel_reason     reason to cancel the task groups
    * @param       i_cancel_notes         cancel notes
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION cancel_task_group
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_group       IN task_group.id_task_group%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN task_group.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'cancel task groups';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT set_task_groups_status_intern(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_task_groups      => table_number(i_task_group),
                                             i_flg_status       => g_flg_canceled,
                                             i_id_cancel_reason => i_id_cancel_reason,
                                             i_cancel_notes     => i_cancel_notes,
                                             o_error            => o_error)
        THEN
            g_error := g_error || ' error found while calling pk_task_groups.set_task_groups_status_intern';
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_TASK_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_task_group;

    /********************************************************************************************
    * set task groups status
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_groups          list of task groups to set status
    * @param       i_flg_status           new task group status
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group          
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION set_task_groups_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_task_groups IN table_number,
        i_flg_status  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'set task groups status';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT set_task_groups_status_intern(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_task_groups      => i_task_groups,
                                             i_flg_status       => i_flg_status,
                                             i_id_cancel_reason => NULL,
                                             i_cancel_notes     => NULL,
                                             o_error            => o_error)
        THEN
            g_error := g_error || ' error found while calling pk_task_groups.set_task_groups_status_intern';
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_GROUPS_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_task_groups_status;

    /********************************************************************************************
    * get task group data
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_group           id of the task group
    * @param       o_task_group_data      cursor with all task group data
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION get_task_group_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_group   IN NUMBER,
        o_task_group_data OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'get cursor with all task group data';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_group_data FOR
            SELECT tg.id_task_group AS id_task_group,
                   pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(tg.code_task_group)) AS name,
                   tg.author AS author,
                   pk_sysdomain.get_domain('TASK_GROUP.FLG_STATUS', tg.flg_status, i_lang) AS desc_status,
                   tg.flg_status AS flg_status,
                   tg.notes
              FROM task_group tg
             WHERE tg.id_task_group = i_id_task_group;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_GROUP_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_task_group_data);
            RETURN FALSE;
    END get_task_group_data;

    /********************************************************************************************
    * set task groups ranks
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_groups          list of task groups to set rank
    * @param       i_ranks                list of ranks   
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2013/05/24
    ********************************************************************************************/
    FUNCTION set_task_groups_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_task_groups IN table_number,
        i_ranks       IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_group_name           table_varchar;
        l_tbl_code_task_group_hist table_varchar;
    
        TYPE t_task_group IS TABLE OF task_group%ROWTYPE INDEX BY PLS_INTEGER;
        ibt_task_group t_task_group;
    
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'set task groups ranks';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN 1 .. i_task_groups.last
            UPDATE task_group tg
               SET tg.rank = i_ranks(i)
             WHERE tg.id_task_group = i_task_groups(i);
    
        g_error := 'get data from task groups that were updated';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT tg.*
          BULK COLLECT
          INTO ibt_task_group
          FROM task_group tg
         WHERE tg.id_task_group IN (SELECT /*+opt_estimate(table odst_tsk_ids rows=1)*/
                                     column_value
                                      FROM TABLE(i_task_groups));
    
        g_error := 'insert task group history record';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FORALL i IN ibt_task_group.first .. ibt_task_group.last
            INSERT INTO task_group_hist
                (id_task_group_hist,
                 id_task_group,
                 author,
                 flg_status,
                 notes,
                 rank,
                 dt_group_tstz,
                 id_institution,
                 id_professional,
                 id_cancel_reason,
                 cancel_notes)
            VALUES
                (seq_task_group.nextval,
                 ibt_task_group(i).id_task_group,
                 ibt_task_group(i).author,
                 ibt_task_group(i).flg_status,
                 ibt_task_group(i).notes,
                 ibt_task_group(i).rank,
                 current_timestamp,
                 i_prof.institution,
                 i_prof.id,
                 ibt_task_group(i).id_cancel_reason,
                 ibt_task_group(i).cancel_notes)
            RETURNING code_task_group, pk_translation.get_translation_trs
                ('ALERT.TASK_GROUP.CODE_TASK_GROUP.' || id_task_group) BULK COLLECT INTO l_tbl_code_task_group_hist, l_tbl_group_name;
    
        g_error := 'insert task groups history names';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR i IN 1 .. l_tbl_group_name.count
        LOOP
            pk_translation.insert_translation_trs(i_lang, l_tbl_code_task_group_hist(i), l_tbl_group_name(i), g_module);
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_GROUPS_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_task_groups_rank;

    /********************************************************************************************
    * get ranks list to assign to the task groups
    *
    * @param       i_lang            preferred language id for this professional
    * @param       i_prof            professional id structure
    * @param       o_ranks_list      cursor with the list of ranks
    * @param       o_error           error message    
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Tiago Silva
    * @since                         2013/05/24
    ********************************************************************************************/
    FUNCTION get_ranks_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_ranks_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institutions table_number;
    
        l_ranks_list table_number := table_number();
        l_max_rank   task_group.rank%TYPE;
    
        l_num_groups     NUMBER;
        l_max_group_rank task_group.rank%TYPE;
    BEGIN
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        -- get number of task groups and the maximum rank defined for those groups
        SELECT COUNT(1) AS num_groups, MAX(tg.rank) AS max_group_rank
          INTO l_num_groups, l_max_group_rank
          FROM task_group tg
         WHERE tg.flg_status IN (g_flg_active, g_flg_inactive)
           AND tg.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                      column_value
                                       FROM TABLE(l_institutions) inst);
    
        -- get max rank that must be presented to the user
        IF l_num_groups >= l_max_group_rank
        THEN
            l_max_rank := l_num_groups;
        ELSE
            l_max_rank := l_max_group_rank;
        END IF;
    
        -- extends ranks collection according to max rank, in order to generate the ranks list
        l_ranks_list.extend(l_max_rank);
    
        g_error := 'get ranks list';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_ranks_list FOR
            SELECT rownum AS val_rank, rownum AS desc_rank
              FROM TABLE(l_ranks_list)
             ORDER BY desc_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RANKS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_ranks_list);
            RETURN FALSE;
    END get_ranks_list;

    FUNCTION create_task_group
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_tbl_id_pk            IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_flg_update           IN VARCHAR2,
        o_group_task_id        OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_task_group      task_group.code_task_group%TYPE;
        l_code_task_group_hist task_group.code_task_group%TYPE;
        l_rank                 task_group.rank%TYPE;
    
        l_name       VARCHAR2(4000 CHAR);
        l_author     VARCHAR2(4000 CHAR);
        l_flg_status VARCHAR2(4000 CHAR);
        l_notes      VARCHAR2(4000 CHAR);
    BEGIN
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_order_set_group_name
            THEN
                l_name := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_order_set_author
            THEN
                l_author := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_order_set_group_status
            THEN
                l_flg_status := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_notes
            THEN
                l_notes := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
    
        IF i_flg_update = pk_alert_constant.g_no
        THEN
            g_error := 'insert new task group';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            INSERT INTO task_group
                (id_task_group, author, flg_status, notes, dt_group_tstz, id_institution, id_professional)
            VALUES
                (seq_task_group.nextval,
                 l_author,
                 l_flg_status,
                 l_notes,
                 current_timestamp,
                 i_prof.institution,
                 i_prof.id)
            RETURNING id_task_group, code_task_group, rank INTO o_group_task_id, l_code_task_group, l_rank;
        
            g_error := 'insert new task group name';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            pk_translation.insert_translation_trs(i_lang, l_code_task_group, l_name, g_module);
        
            g_error := 'insert task group history record';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            INSERT INTO task_group_hist
                (id_task_group_hist,
                 id_task_group,
                 author,
                 flg_status,
                 notes,
                 rank,
                 dt_group_tstz,
                 id_institution,
                 id_professional)
            VALUES
                (seq_task_group.nextval,
                 o_group_task_id,
                 l_author,
                 l_flg_status,
                 l_notes,
                 l_rank,
                 current_timestamp,
                 i_prof.institution,
                 i_prof.id)
            RETURNING code_task_group INTO l_code_task_group_hist;
        
            g_error := 'insert new task group name';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            pk_translation.insert_translation_trs(i_lang, l_code_task_group_hist, l_name, g_module);
        
            RETURN TRUE;
        
        ELSE
            o_group_task_id := i_tbl_id_pk(1);
        
            RETURN pk_task_groups.update_task_group(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_task_group => i_tbl_id_pk(1),
                                                    i_name          => l_name,
                                                    i_author        => l_author,
                                                    i_flg_status    => l_flg_status,
                                                    i_notes         => l_notes,
                                                    o_error         => o_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_TASK_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_task_group;

    FUNCTION get_task_group_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TASK_GROUP_FORM_VALUES';
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        l_name        VARCHAR2(4000 CHAR);
        l_author      VARCHAR2(4000 CHAR);
        l_desc_status VARCHAR2(4000 CHAR);
        l_flg_status  VARCHAR2(1 CHAR);
        l_notes       VARCHAR2(4000 CHAR);
    
        --Return variable
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    BEGIN
    
        IF i_action = pk_task_groups.g_task_group_edit
        THEN
        
            SELECT pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(tg.code_task_group)),
                   tg.author,
                   pk_sysdomain.get_domain('TASK_GROUP.FLG_STATUS', tg.flg_status, i_lang),
                   tg.flg_status,
                   tg.notes
              INTO l_name, l_author, l_desc_status, l_flg_status, l_notes
              FROM task_group tg
             WHERE tg.id_task_group = i_tbl_id_pk(1);
        
            g_error := 'SELECT INTO TBL_RESULT';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE t.internal_name_child
                                                                 WHEN pk_orders_constant.g_ds_order_set_group_name THEN
                                                                  l_name
                                                                 WHEN pk_orders_constant.g_ds_order_set_author THEN
                                                                  l_author
                                                                 WHEN pk_orders_constant.g_ds_order_set_group_status THEN
                                                                  l_flg_status
                                                                 WHEN pk_orders_constant.g_ds_notes THEN
                                                                  l_notes
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE t.internal_name_child
                                                                 WHEN pk_orders_constant.g_ds_order_set_group_name THEN
                                                                  l_name
                                                                 WHEN pk_orders_constant.g_ds_order_set_author THEN
                                                                  l_author
                                                                 WHEN pk_orders_constant.g_ds_order_set_group_status THEN
                                                                  l_desc_status
                                                                 WHEN pk_orders_constant.g_ds_notes THEN
                                                                  l_notes
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => def.flg_event_type,
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN (pk_orders_constant.g_ds_order_set_group_name,
                                       pk_orders_constant.g_ds_order_set_author,
                                       pk_orders_constant.g_ds_order_set_group_status,
                                       pk_orders_constant.g_ds_notes)
             ORDER BY t.rn;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_task_group_form_values;

    FUNCTION get_task_group_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_group IN NUMBER,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tab_dd_block_data  t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_block_tasks t_tab_dd_block_data := t_tab_dd_block_data();
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
    BEGIN
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT NULL title,
                                       pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(tg.code_task_group)) AS name,
                                       tg.author AS author,
                                       pk_sysdomain.get_domain('TASK_GROUP.FLG_STATUS', tg.flg_status, i_lang) AS status,
                                       tg.notes,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, tg.id_professional) ||
                                       decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               tg.id_professional,
                                                                               tg.dt_group_tstz,
                                                                               NULL),
                                              NULL,
                                              '; ',
                                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                       i_prof,
                                                                                       tg.id_professional,
                                                                                       tg.dt_group_tstz,
                                                                                       NULL) || '); ') ||
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   tg.dt_group_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software) registry
                                  FROM task_group tg
                                 WHERE tg.id_task_group = i_id_task_group) unpivot include NULLS(data_source_val FOR data_source IN(title,
                                                                                                                                    name,
                                                                                                                                    author,
                                                                                                                                    status,
                                                                                                                                    notes,
                                                                                                                                    registry)))) dd
          JOIN dd_block ddb
            ON ddb.area = pk_dynamic_detail.g_order_set_group
           AND ddb.id_dd_block = 1
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_order_set_group
                   AND ddc.id_dd_block = 1
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1')))
         ORDER BY id_dd_block, rnk, rank;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || CASE
                                     WHEN d.flg_type = 'LP' THEN
                                      ' '
                                     ELSE
                                      ': '
                                 END
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_GROUP_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_task_group_detail;
    /********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);
END pk_task_groups;
/
