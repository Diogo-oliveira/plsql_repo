/*-- Last Change Revision: $Rev: 1899666 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2019-04-08 17:17:50 +0100 (seg, 08 abr 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_diet IS

    g_exception EXCEPTION;

    /**********************************************************************************************
    * Gets the list of active diets for kitchen(Used on Reports - kitchen)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_department         ID department
    * @param i_id_dep_serv           ID of department service
    *
    * @param o_diet                  Cursor with all active diets 
    * @param o_diet_totals           Cursor with the totals of diets
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_active_diet_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN dept.id_dept%TYPE,
        i_id_dep_serv   IN department.id_department%TYPE,
        o_diet          OUT pk_types.cursor_type,
        o_diet_totals   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('GET_ACTIVE_DIET_LIST PARAMS[:i_id_department' || i_id_department || ']',
                              g_package_name,
                              'GET_ACTIVE_DIET_LIST');
    
        g_error := 'CALL PK_DIET.GET_ACTIVE_DIET_LIST';
        RETURN pk_diet.get_active_diet_list(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_department => i_id_department,
                                            i_id_dep_serv   => i_id_dep_serv,
                                            o_diet          => o_diet,
                                            o_diet_totals   => o_diet_totals,
                                            o_error         => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIVE_DIET_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_totals);
            RETURN FALSE;
        
    END get_active_diet_list;

    /**********************************************************************************************
    * Gets the last active diet of a episode(Used on Reports - hand-off)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @param o_diet                  Cursor with the last active diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/09/01
    **********************************************************************************************/
    FUNCTION get_last_active_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diet       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL GET_LAST_ACTIVE_DIET';
        RETURN pk_diet.get_last_active_diet(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            o_diet       => o_diet,
                                            o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_ACTIVE_DIET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            RETURN FALSE;
        
    END get_last_active_diet;

    /**********************************************************************************************
    * Gets the active diets as string for handoff
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @param o_diet                  Cursor with the last active diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Anna Kurowska
    * @version                       2.7.1
    * @since                         2017/04/03
    **********************************************************************************************/
    FUNCTION get_active_diets_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_diets   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_active_diets table_varchar;
        l_diet_desc    CLOB;
    BEGIN
        g_error := 'CALL GET_DOMAIN';
    
        g_error := 'CALL GET_ACTIVE_DIETS';
        SELECT pk_utils.concat_table(i_tab   => table_varchar(d.diet_type, d.diet_name, d.dt_initial_str),
                                     i_delim => ', ') diet_desc
          BULK COLLECT
          INTO l_active_diets
          FROM (SELECT b.diet_type, b.diet_name, b.dt_initial_str
                  FROM (SELECT a.diet_type,
                               a.diet_name,
                               nvl2(a.dt_initial_str, '(' || a.dt_initial_str || ')', '') dt_initial_str
                          FROM TABLE(pk_diet.get_active_diets(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient)) a) b) d;
    
        l_diet_desc := pk_utils.concat_table(i_tab => l_active_diets, i_delim => '; ');
    
        OPEN o_diets FOR
            SELECT nvl2(l_diet_desc, (upper(pk_message.get_message(i_lang, 'DIET_T096')) || ':'), '') title,
                   l_diet_desc VALUE
              FROM dual;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIVE_DIETS_DESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diets);
            RETURN FALSE;
        
    END get_active_diets_desc;

    /********************************************************************************************
    * Creates or updates a Diet request
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  Professional id, software and institution
    * @param   i_episode               Episode ID
    * @param   i_id_epis_diet_req      Id_epis_diet_req (NULL for new records)
    * @param   i_id_diet_type          Diet type: 1 - Facility diet (Default Value) 
                                                  2 - Personalized diet
                                                  3 - Most frequent personalized diet
    * @param   i_desc_diet             Diet description, used for free text. (Free text records => Diet type 2)
    * @param   i_id_content            Array of ID_CONTENT
    * @param   i_quantity              Array of quantities
    * @param   i_id_unit               Array of quantity units
    * @param   i_notes_diet            Array of diet notes
    * @param   i_id_diet_schedule      Array of diet_schedule: [MANDATORY]
                                        1 - Breakfast
                                        2 - Lunch
                                        3 - Snack
                                        4 - Dinner
                                        5 - Supper
                                        6 - Light meal
                                        7 - Diet (To be used at least once on every diet)
    * @param   i_dt_hour                Array of execution dates/time of each diet
    * @param   i_dt_begin_str           Request start date 
    * @param   i_dt_end_str             Request end date
    * @param   i_notes                  Request notes        
    *
    * @RETURN  o_id_epis_diet_req
    * @RETURN  o_error              
    **********************************************************************************************/
    FUNCTION create_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type     IN diet_type.id_diet_type%TYPE,
        i_desc_diet        IN epis_diet_req.desc_diet%TYPE,
        i_id_content       IN table_varchar,
        i_quantity         IN table_number,
        i_id_unit          IN table_number,
        i_notes_diet       IN table_varchar,
        i_id_diet_schedule IN table_number,
        i_dt_hour          IN table_varchar,
        i_dt_begin_str     IN VARCHAR2,
        i_dt_end_str       IN VARCHAR2,
        i_notes            IN epis_diet_req.notes%TYPE,
        o_id_epis_diet_req OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient patient.id_patient%TYPE;
    
        l_task_list         pk_types.cursor_type;
        l_flg_warning_type  VARCHAR2(1);
        l_msg_title         VARCHAR2(1000);
        l_msg_body          VARCHAR2(1000);
        l_proc_start        VARCHAR2(1000);
        l_proc_end          VARCHAR2(1000);
        l_proc_refresh      VARCHAR2(1000);
        l_proc_next_start   VARCHAR2(1000);
        l_proc_next_end     VARCHAR2(1000);
        l_proc_next_refresh VARCHAR2(1000);
    
        l_cpoe_process cpoe_process.id_cpoe_process%TYPE;
    
        l_id_diet_type diet_type.id_diet_type%TYPE;
    
        l_id_diet_schedule table_number := table_number();
    
        l_id_diet table_number := table_number();
    
        l_msg_warning VARCHAR2(1000 CHAR);
    
    BEGIN
        --CHECK IF CPOE IS VALID
        IF NOT pk_cpoe.check_tasks_creation(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_episode           => i_episode,
                                            i_task_type         => table_number(pk_alert_constant.g_task_type_diet_inst),
                                            i_dt_start          => table_varchar(i_dt_begin_str),
                                            i_dt_end            => table_varchar(i_dt_end_str),
                                            i_task_id           => table_varchar(-1),
                                            i_tab_type          => NULL,
                                            o_task_list         => l_task_list,
                                            o_flg_warning_type  => l_flg_warning_type,
                                            o_msg_title         => l_msg_title,
                                            o_msg_body          => l_msg_body,
                                            o_proc_start        => l_proc_start,
                                            o_proc_end          => l_proc_end,
                                            o_proc_refresh      => l_proc_refresh,
                                            o_proc_next_start   => l_proc_next_start,
                                            o_proc_next_end     => l_proc_next_end,
                                            o_proc_next_refresh => l_proc_next_refresh,
                                            o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.check_tasks_creation function';
            RAISE g_exception;
        END IF;
    
        dbms_output.put_line(l_msg_title);
        dbms_output.put_line(l_msg_body);
    
        --CREATE CPOE PROCESS IF NEEDED  
        IF l_flg_warning_type = pk_cpoe.g_flg_warning_new_cpoe
        THEN
        
            IF NOT pk_cpoe.create_cpoe(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_episode           => i_episode,
                                       i_proc_start        => l_proc_start,
                                       i_proc_end          => l_proc_end,
                                       i_proc_next_start   => l_proc_next_start,
                                       i_proc_next_end     => l_proc_next_end,
                                       i_proc_next_refresh => l_proc_next_refresh,
                                       i_proc_type         => 'P',
                                       i_proc_refresh      => l_proc_refresh,
                                       o_cpoe_process      => l_cpoe_process,
                                       o_error             => o_error)
            THEN
                g_error := 'error found while calling pk_cpoe.create_cpoe function';
                RAISE g_exception;
            END IF;
        
        END IF;
    
        g_error := 'Error found while getting id_patient.';
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF i_id_diet_type IS NULL
        THEN
            l_id_diet_type := 1;
        ELSE
            l_id_diet_type := i_id_diet_type;
        END IF;
    
        FOR i IN i_id_diet_schedule.first .. i_id_diet_schedule.last
        LOOP
            l_id_diet_schedule.extend();
        
            IF i_id_diet_schedule(i) IS NULL
            THEN
                l_id_diet_schedule(i) := pk_diet.g_diet_title;
            ELSE
                l_id_diet_schedule(i) := i_id_diet_schedule(i);
            END IF;
        END LOOP;
    
        FOR i IN i_id_content.first .. i_id_content.last
        LOOP
        
            l_id_diet.extend;
        
            SELECT d.id_diet
              INTO l_id_diet(i)
              FROM diet d
             WHERE d.id_content = i_id_content(i)
               AND d.flg_available = 'Y'
               AND rownum = 1;
        
        END LOOP;
    
        IF NOT pk_diet.create_diet(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_patient            => l_patient,
                                   i_episode            => i_episode,
                                   i_id_epis_diet       => i_id_epis_diet_req,
                                   i_id_diet_type       => l_id_diet_type,
                                   i_desc_diet          => i_desc_diet,
                                   i_dt_begin_str       => i_dt_begin_str,
                                   i_dt_end_str         => i_dt_end_str,
                                   i_food_plan          => NULL,
                                   i_flg_help           => NULL,
                                   i_notes              => i_notes,
                                   i_id_diet_predefined => NULL,
                                   i_id_diet_schedule   => l_id_diet_schedule,
                                   i_id_diet            => l_id_diet,
                                   i_quantity           => i_quantity,
                                   i_id_unit            => i_id_unit,
                                   i_notes_diet         => i_notes_diet,
                                   i_dt_hour            => i_dt_hour,
                                   i_flg_institution    => NULL,
                                   i_flg_share          => NULL,
                                   i_commit             => 'N',
                                   o_id_epis_diet       => o_id_epis_diet_req,
                                   o_msg_warning        => l_msg_warning,
                                   o_error              => o_error)
        THEN
            g_error := 'Error found while creating diet.';
            RAISE g_exception;
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
                                              'CREATE_DIET',
                                              o_error);
        
            RETURN FALSE;
    END create_diet;

    /********************************************************************************************
    * Cancels a Diet request
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  Professional id, software and institution
    * @param   i_id_epis_diet_req      Id_epis_diet_req
    * @param   i_cancel_reason         ID of cancelation reason
    * @param   i_cancel_notes          Cancelation notes       
    *
    * @RETURN  o_error              
    **********************************************************************************************/
    FUNCTION cancel_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_cancel_reason    IN epis_diet_req.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_diet_req.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_diet.cancel_diet_internal(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_id_diet => i_id_epis_diet_req,
                                            i_notes   => i_cancel_notes,
                                            i_reason  => i_cancel_reason,
                                            o_error   => o_error)
        THEN
            g_error := 'Error found while canceling diet.';
            RAISE g_exception;
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
                                              'CANCEL_DIET',
                                              o_error);
        
            RETURN FALSE;
        
    END cancel_diet;

    /**********************************************************************************************
    * Suspend a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional id, software and institution    
    * @param i_id_epis_diet_req      ID_diet_req to be suspended
    * @param i_suspension_reason     ID Reason for suspend
    * @param i_suspension_notes      Suspend Notes 
    * @param i_dt_initial            Initial date for suspend
    * @param i_dt_end                End date for suspend
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    **********************************************************************************************/
    FUNCTION suspend_diet
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diet_req  IN epis_diet_req.id_epis_diet_req%TYPE,
        i_suspension_reason IN epis_diet_req.id_cancel_reason%TYPE,
        i_suspension_notes  IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str    IN VARCHAR2,
        i_dt_end_str        IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_diet.suspend_diet(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_diet        => i_id_epis_diet_req,
                                    i_notes          => i_suspension_notes,
                                    i_reason         => i_suspension_reason,
                                    i_dt_initial_str => i_dt_initial_str,
                                    i_dt_end_str     => i_dt_end_str,
                                    i_commit         => 'N',
                                    o_error          => o_error)
        THEN
            g_error := 'Error found while suspending diet.';
            RAISE g_exception;
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
                                              'SUSPEND_DIET',
                                              o_error);
        
            RETURN FALSE;
        
    END suspend_diet;

    /**********************************************************************************************
    * Resume a diet 
    *
    * @param i_lang                  Language associated to the professional
    * @param i_prof                  Professional id, software and institution
    * @param i_id_epis_diet_req      ID_diet_req to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    **********************************************************************************************/
    FUNCTION resume_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes            IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str   IN VARCHAR2,
        i_dt_end_str       IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        SELECT edr.id_episode
          INTO l_id_episode
          FROM epis_diet_req edr
         WHERE id_epis_diet_req = i_id_epis_diet_req;
    
        IF NOT pk_diet.resume_diet(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => l_id_episode,
                                   i_id_diet        => i_id_epis_diet_req,
                                   i_notes          => i_notes,
                                   i_dt_initial_str => i_dt_initial_str,
                                   i_dt_end_str     => i_dt_end_str,
                                   i_commit         => 'N',
                                   o_error          => o_error)
        THEN
            g_error := 'Error found while resuming diet.';
            RAISE g_exception;
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
                                              'RESUM_DIET',
                                              o_error);
        
            RETURN FALSE;
        
    END resume_diet;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_diet;
/
