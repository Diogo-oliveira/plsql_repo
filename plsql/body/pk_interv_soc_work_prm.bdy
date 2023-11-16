/*-- Last Change Revision: $Rev: 1904917 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 08:23:49 +0100 (qui, 06 jun 2019) $*/
CREATE OR REPLACE PACKAGE BODY pk_interv_soc_work_prm IS
    -- Package info
    g_package_owner t_low_char := '[OWNER]';
    g_package_name  t_low_char := 'pk_interv_soc_work_prm';

    g_table_name t_med_char;
    pos_soft     NUMBER := 1;
    -- Private Methods

    -- content loader method
    /********************************************************************************************
    * Set Default Interv Plan content Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_level_num NUMBER := 0;
        l_res       NUMBER := 0;
        l_temp_res  NUMBER := 0;
        l_exception EXCEPTION;
        l_code_tbl VARCHAR2(1000) := 'INTERV_PLAN.CODE_INTERV_PLAN.';
    BEGIN
        g_func_name := upper('set_intervplan_def');
        g_error     := 'GET TABLE LEVELS';
        SELECT MAX(LEVEL)
          INTO l_level_num
          FROM alert_default.diet def_d
        CONNECT BY PRIOR def_d.id_diet_parent = def_d.id_diet;
    
        FOR lv IN 1 .. l_level_num
        LOOP
            g_error := 'INSERT INTERV PLAN CONTENT IN LEVEL ' || lv;
            INSERT INTO interv_plan
                (id_interv_plan, code_interv_plan, flg_available, id_parent, id_content)
                SELECT seq_interv_plan.nextval,
                       l_code_tbl || seq_interv_plan.currval,
                       g_flg_available,
                       def_data.id_parent,
                       def_data.id_content
                  FROM (SELECT temp_data.id_content,
                               temp_data.id_parent,
                               row_number() over(PARTITION BY temp_data.id_content ORDER BY temp_data.l_row) records_count
                          FROM (SELECT def_tbl.rowid l_row,
                                       def_tbl.id_content,
                                       decode(def_tbl.id_parent,
                                              NULL,
                                              NULL,
                                              nvl((SELECT ext_ip.id_interv_plan
                                                    FROM interv_plan ext_ip
                                                   INNER JOIN alert_default.interv_plan def_ip
                                                      ON (def_ip.id_content = ext_ip.id_content AND
                                                         def_ip.flg_available = g_flg_available)
                                                   WHERE ext_ip.flg_available = g_flg_available
                                                     AND def_ip.id_interv_plan = def_tbl.id_interv_plan),
                                                  0)) id_parent
                                  FROM alert_default.interv_plan def_tbl
                                 WHERE def_tbl.flg_available = g_flg_available
                                   AND LEVEL = lv
                                CONNECT BY PRIOR def_tbl.id_parent = def_tbl.id_interv_plan) temp_data
                         WHERE (temp_data.id_parent > 0 OR temp_data.id_parent IS NULL)) def_data
                 WHERE def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                          FROM interv_plan dest_tbl
                         WHERE dest_tbl.id_content = def_data.id_content);
        
            l_temp_res := SQL%ROWCOUNT;
            l_res      := l_res + l_temp_res;
        END LOOP;
    
        o_result_tbl := l_res;
        RETURN TRUE;
    EXCEPTION
    
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_intervplan_def;
    /********************************************************************************************
    * Set Default Interv Plan content Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_taksgoal_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_max_id   NUMBER := 0;
        l_code_tbl VARCHAR2(1000) := 'TASK_GOAL.CODE_TASK_GOAL.';
        l_exception EXCEPTION;
    BEGIN
        g_func_name := upper('set_taksgoal_def');
        g_error     := 'GET MAX ID FROM DEST TABLE';
        SELECT nvl((SELECT MAX(id_task_goal)
                     FROM task_goal),
                   0)
          INTO l_max_id
          FROM dual;
        g_error := 'INSERT TASK GOAL CONTENT ';
        INSERT INTO task_goal
            (id_task_goal, code_task_goal, desc_task_goal, id_content)
            SELECT l_max_id + rownum, l_code_tbl || (l_max_id + rownum), def_tbl.desc_task_goal, def_tbl.id_content
              FROM alert_default.task_goal def_tbl
             WHERE NOT EXISTS (SELECT 0
                      FROM task_goal dest_tbl
                     WHERE dest_tbl.id_content = def_tbl.id_content);
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_taksgoal_def;
    -- searcheable loader method
    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_taskgoaltask_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_max_id NUMBER := 0;
    BEGIN
        g_func_name := upper('set_taskgoaltask_search');
        g_error     := 'GET MAX ID FROM DEST TABLE';
        SELECT nvl((SELECT MAX(t.id_task_goal_task)
                     FROM task_goal_task t),
                   0)
          INTO l_max_id
          FROM dual;
        g_error := 'SET TASK GOAL TASK CONFIGURATION';
        INSERT INTO task_goal_task
            (id_task_goal_task, id_interv_plan, id_task_goal, id_software, id_institution, flg_available)
            SELECT l_max_id + rownum,
                   def_data.id_interv_plan,
                   def_data.id_task_goal,
                   def_data.id_software,
                   i_institution,
                   g_flg_available
              FROM (SELECT temp_data.id_interv_plan,
                           temp_data.id_task_goal,
                           i_software(pos_soft) id_software,
                           row_number() over(PARTITION BY temp_data.id_interv_plan, temp_data.id_task_goal, temp_data.id_software ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_ip.id_interv_plan
                                         FROM interv_plan ext_ip
                                        INNER JOIN alert_default.interv_plan def_ip
                                           ON (def_ip.id_content = ext_ip.id_content)
                                        WHERE ext_ip.flg_available = g_flg_available
                                          AND def_ip.flg_available = g_flg_available
                                          AND def_ip.id_interv_plan = def_tbl.id_interv_plan),
                                       0) id_interv_plan,
                                   nvl((SELECT ext_tg.id_task_goal
                                         FROM task_goal ext_tg
                                        INNER JOIN alert_default.task_goal def_tg
                                           ON (def_tg.id_content = ext_tg.id_content)
                                        WHERE def_tg.id_task_goal = def_tbl.id_task_goal),
                                       0) id_task_goal,
                                   def_tbl.id_software,
                                   def_tbl.id_market,
                                   def_tbl.version
                              FROM alert_default.task_goal_task def_tbl
                             WHERE def_tbl.flg_available = g_flg_available
                               AND def_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND def_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND def_tbl.version IN (SELECT /*+ dynamic_sampling(2) */
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_interv_plan > 0
                       AND temp_data.id_task_goal > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM task_goal_task dest_tbl
                     WHERE dest_tbl.id_interv_plan = def_data.id_interv_plan
                       AND dest_tbl.id_task_goal = def_data.id_task_goal
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_institution = i_institution);
    
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_taskgoaltask_search;

    FUNCTION del_taskgoaltask_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete task_goal_task';
        g_func_name := upper('del_taskgoaltask_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM task_goal_task tgt
             WHERE tgt.id_institution = i_institution
               AND tgt.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM task_goal_task tgt
             WHERE tgt.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_taskgoaltask_search;

    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_intervplan_search');
        g_error     := 'SET INTERV PLAN SEARCH CONFIGURATION';
        INSERT INTO interv_plan_dep_clin_serv
            (id_interv_plan, id_software, id_institution, flg_available, flg_type, id_interv_plan_dep_clin_serv)
            SELECT def_data.id_interv_plan,
                   def_data.id_software,
                   i_institution,
                   g_flg_available,
                   def_data.flg_type,
                   seq_interv_plan_dep_clin_serv.nextval
              FROM (SELECT i_software(pos_soft) id_software,
                           temp_data.id_interv_plan,
                           temp_data.flg_type,
                           row_number() over(PARTITION BY temp_data.id_software, temp_data.id_interv_plan, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_ip.id_interv_plan
                                         FROM interv_plan ext_ip
                                        INNER JOIN alert_default.interv_plan def_ip
                                           ON (def_ip.id_content = ext_ip.id_content)
                                        WHERE ext_ip.flg_available = g_flg_available
                                          AND def_ip.flg_available = g_flg_available
                                          AND def_ip.id_interv_plan = def_tbl.id_interv_plan),
                                       0) id_interv_plan,
                                   def_tbl.flg_type,
                                   def_tbl.id_software,
                                   def_tbl.id_market,
                                   def_tbl.version
                              FROM alert_default.interv_plan_dep_clin_serv def_tbl
                             WHERE def_tbl.flg_available = g_flg_available
                               AND def_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND def_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND def_tbl.version IN (SELECT /*+ dynamic_sampling(2) */
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_interv_plan > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM interv_plan_dep_clin_serv dest_tbl
                     WHERE dest_tbl.id_interv_plan = def_data.id_interv_plan
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_institution = i_institution
                       AND dest_tbl.flg_type = def_data.flg_type);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_intervplan_search;

    FUNCTION del_intervplan_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete interv_plan_dep_clin_serv';
        g_func_name := upper('del_intervplan_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM interv_plan_dep_clin_serv ipdcs
             WHERE ipdcs.id_institution = i_institution
               AND ipdcs.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM interv_plan_dep_clin_serv ipdcs
             WHERE ipdcs.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_intervplan_search;

    -- frequent loader method
    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_intervplan_freq');
        g_error     := 'SET INTERV PLAN SEARCH CONFIGURATION';
        INSERT INTO interv_plan_dep_clin_serv
            (id_interv_plan,
             id_software,
             id_dep_clin_serv,
             flg_available,
             flg_type,
             id_interv_plan_dep_clin_serv,
             id_institution)
            SELECT def_data.id_interv_plan,
                   def_data.id_software,
                   i_dep_clin_serv_out,
                   g_flg_available,
                   def_data.flg_type,
                   seq_interv_plan_dep_clin_serv.nextval,
                   i_institution
              FROM (SELECT i_software(pos_soft) id_software,
                           temp_data.id_interv_plan,
                           temp_data.flg_type,
                           row_number() over(PARTITION BY temp_data.id_software, temp_data.id_interv_plan, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_ip.id_interv_plan
                                         FROM interv_plan ext_ip
                                        INNER JOIN alert_default.interv_plan def_ip
                                           ON (def_ip.id_content = ext_ip.id_content)
                                        WHERE ext_ip.flg_available = g_flg_available
                                          AND def_ip.flg_available = g_flg_available
                                          AND def_ip.id_interv_plan = def_tbl.id_interv_plan),
                                       0) id_interv_plan,
                                   def_tbl.flg_type,
                                   def_tbl.id_software,
                                   def_tbl.id_market,
                                   def_tbl.version
                              FROM alert_default.interv_plan_dep_clin_serv def_tbl
                             WHERE def_tbl.flg_available = g_flg_available
                               AND def_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND def_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND def_tbl.version IN (SELECT /*+ dynamic_sampling(2) */
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND def_tbl.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_interv_plan > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM interv_plan_dep_clin_serv dest_tbl
                     WHERE dest_tbl.id_interv_plan = def_data.id_interv_plan
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_dep_clin_serv = i_dep_clin_serv_out
                       AND dest_tbl.flg_type = def_data.flg_type
                       AND dest_tbl.id_institution = i_institution);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_intervplan_freq;
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_interv_soc_work_prm;
/